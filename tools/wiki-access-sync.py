#!/usr/bin/env python3
"""
wiki-access-sync.py — Phoenixtekk factory: gate the Wiki.js solution docs and sync who may read them.

Gating model (decided 2026-06-15):
  - Published solution pages live at  solutions/<category_slug>/<slug>  (see publish-wiki.py).
  - "Subscribers" group  -> ALLOW read on  solutions/**            (active members see everything)
  - "Purchasers: <slug>" -> ALLOW read on  solutions/<cat>/<slug>  (one-time buyers see their guide)
  - Guests + Public Users -> DENY read on  solutions/**            (closes public exposure)
  Administrators keep full access (unchanged). Other (non-solutions) wiki content is untouched.

Two phases:
  1. STRUCTURE  — ensure the deny rules + the Subscribers/per-solution groups exist.
  2. USER SYNC  — for each eligible customer, ensure a Local Wiki.js account (sendWelcomeEmail) and
                  reconcile group membership; eligibility comes from --eligibility-file (JSON):
                    { "subscribers": ["a@x.com", ...],
                      "purchasers": { "<slug>": ["b@y.com", ...] } }
                  (Generated from the store DB; with no orders/subs yet this is simply empty.)

Auth/env:  WIKIJS_URL, WIKIJS_TOKEN  (same as publish-wiki.py).
Safe by default: DRY-RUN unless --apply is given. Nothing is written (and no welcome emails are
sent) without --apply.

Usage:
  python tools/wiki-access-sync.py --registry library/_index/registry.json            # dry-run structure
  python tools/wiki-access-sync.py --registry ... --apply                             # apply structure
  python tools/wiki-access-sync.py --registry ... --eligibility-file elig.json --apply # + users
"""
import argparse, json, os, sys
from urllib import request as urlrequest, error as urlerror

DENY_ROLES = ["read:pages", "read:assets", "read:comments"]
# Internal top-level folders that must NOT be anonymously readable (deny on Guests).
# Public tier is only: home + KB knowledge areas (Intune/Microsoft/JamfPro); solutions/ is gated.
INTERNAL_DENY = ["agent-output", "SystemDocs", "marketing", "Marketplace", "Workplace",
                 "Phoenixtekk", "txtya", "aigartha", "OpenClaw", "Analytikul", "analytikul",
                 "TekkDomains", "LibreChat"]
READ_PERMS = ["read:pages", "read:assets", "read:comments"]
SOLUTIONS_ROOT = "solutions"
UA = ("Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 "
      "(KHTML, like Gecko) Chrome/124.0 Safari/537.36")


def gql(query, variables=None, tolerate=None):
    url, token = os.environ.get("WIKIJS_URL"), os.environ.get("WIKIJS_TOKEN")
    if not url or not token:
        sys.exit("Set WIKIJS_URL and WIKIJS_TOKEN in the environment.")
    body = json.dumps({"query": query, "variables": variables or {}}).encode("utf-8")
    req = urlrequest.Request(url.rstrip("/") + "/graphql", data=body, method="POST")
    req.add_header("Content-Type", "application/json")
    req.add_header("Authorization", f"Bearer {token}")
    req.add_header("User-Agent", UA)
    try:
        with urlrequest.urlopen(req, timeout=30) as resp:
            data = json.loads(resp.read().decode("utf-8"))
    except urlerror.HTTPError as e:
        sys.exit(f"Wiki.js HTTP {e.code}: {e.read().decode('utf-8','replace')[:400]}")
    if data.get("errors"):
        codes = {(e.get("extensions") or {}).get("code") for e in data["errors"]}
        if tolerate and codes <= set(tolerate):
            return None
        sys.exit("Wiki.js GraphQL errors: " + json.dumps(data["errors"])[:600])
    return data["data"]


def short_id(seed):  # deterministic short rule id (no Math.random needed)
    h = 0
    for ch in seed:
        h = (h * 31 + ord(ch)) & 0xFFFFFFFF
    return f"ptk{h:08x}"


def load_solutions(registry_path):
    reg = json.loads(open(registry_path, encoding="utf-8").read())
    items = reg if isinstance(reg, list) else reg.get("solutions", reg.get("items", []))
    out, seen = [], set()
    for s in items:
        slug = s.get("slug")
        if not slug or slug in seen:
            continue
        seen.add(slug)
        out.append({"slug": slug, "category_slug": s.get("category_slug", "intune-solutions")})
    return out


GROUP_LIST = "{ groups { list { id name } } }"
GROUP_SINGLE = ("query($id:Int!){ groups { single(id:$id){ id name redirectOnLogin "
                "permissions pageRules{ id deny match roles path locales } } } }")
GROUP_CREATE = ("mutation($name:String!){ groups { create(name:$name){ "
                "responseResult{succeeded message} group{ id name } } } }")
GROUP_UPDATE = ("mutation($id:Int!,$name:String!,$redirectOnLogin:String!,$permissions:[String]!,"
                "$pageRules:[PageRuleInput]!){ groups { update(id:$id,name:$name,"
                "redirectOnLogin:$redirectOnLogin,permissions:$permissions,pageRules:$pageRules){ "
                "responseResult{succeeded message} } } }")


def groups_by_name():
    return {g["name"]: g["id"] for g in gql(GROUP_LIST)["groups"]["list"]}


def ensure_group(name, by_name, apply):
    if name in by_name:
        return by_name[name]
    if not apply:
        print(f"  WOULD CREATE group '{name}'")
        return None
    r = gql(GROUP_CREATE, {"name": name})["groups"]["create"]
    if not r["responseResult"]["succeeded"]:
        sys.exit(f"create group '{name}' failed: {r['responseResult']['message']}")
    gid = r["group"]["id"]
    by_name[name] = gid
    print(f"  CREATED group '{name}' (id {gid})")
    return gid


def set_rule(gid, want_rule, ensure_perms, apply):
    """APPEND a page rule (matched by path+deny) to a group, preserving its other rules.
    Used for the Guests DENY (Guests must keep its existing allow-"" rule for the rest of the wiki)."""
    g = gql(GROUP_SINGLE, {"id": gid})["groups"]["single"]
    rules = g["pageRules"] or []
    exists = any(r["path"] == want_rule["path"] and r["deny"] == want_rule["deny"]
                 and r["match"] == want_rule["match"] for r in rules)
    perms = sorted(set(g["permissions"]) | set(ensure_perms)) if ensure_perms else g["permissions"]
    if exists and set(ensure_perms or []) <= set(g["permissions"]):
        print(f"  ok    group {g['id']} '{g['name']}' already has rule {want_rule['deny'] and 'DENY' or 'ALLOW'} {want_rule['path']}")
        return
    if not apply:
        print(f"  WOULD SET group {g['id']} '{g['name']}': "
              f"{'DENY' if want_rule['deny'] else 'ALLOW'} {want_rule['path']}")
        return
    new_rules = rules + ([] if exists else [want_rule])
    r = gql(GROUP_UPDATE, {"id": gid, "name": g["name"],
                           "redirectOnLogin": g.get("redirectOnLogin") or "/",
                           "permissions": perms, "pageRules": new_rules})["groups"]["update"]
    if not r["responseResult"]["succeeded"]:
        sys.exit(f"update group {g['id']} failed: {r['responseResult']['message']}")
    print(f"  SET   group {g['id']} '{g['name']}': "
          f"{'DENY' if want_rule['deny'] else 'ALLOW'} {want_rule['path']}")


def set_access_rule(gid, path, apply):
    """Set an access group's page rules to EXACTLY one ALLOW on `path` (START), with read perms.
    Wiki.js seeds every NEW group with a default ALLOW on path "" (the whole wiki) — if left in
    place, a Subscribers/Purchasers member could read ALL pages, defeating gating. So we REPLACE
    the rule set (drop the default allow-"" and any stale path) rather than append."""
    g = gql(GROUP_SINGLE, {"id": gid})["groups"]["single"]
    desired = [rule(path, False, READ_PERMS)]
    cur = g["pageRules"] or []
    already = (len(cur) == 1 and cur[0]["path"] == path and not cur[0]["deny"]
               and cur[0]["match"] == "START" and set(READ_PERMS) <= set(g["permissions"]))
    if already:
        print(f"  ok    group {g['id']} '{g['name']}' = ALLOW {path} (exclusive)")
        return
    if not apply:
        print(f"  WOULD SET group {g['id']} '{g['name']}' = ALLOW {path} (exclusive; drops default allow-all)")
        return
    perms = sorted(set(g["permissions"]) | set(READ_PERMS))
    r = gql(GROUP_UPDATE, {"id": gid, "name": g["name"],
                           "redirectOnLogin": g.get("redirectOnLogin") or "/",
                           "permissions": perms, "pageRules": desired})["groups"]["update"]
    if not r["responseResult"]["succeeded"]:
        sys.exit(f"update group {g['id']} failed: {r['responseResult']['message']}")
    print(f"  SET   group {g['id']} '{g['name']}' = ALLOW {path} (exclusive)")


def rule(path, deny, roles):
    return {"id": short_id(f"{path}{deny}"), "deny": deny, "match": "START",
            "roles": roles, "path": path, "locales": []}


# ---- user sync ----
USER_SEARCH = "query($q:String!){ users { search(query:$q){ id email } } }"
USER_CREATE = ("mutation($email:String!,$name:String!,$groups:[Int]!){ users { "
               "create(email:$email,name:$name,passwordRaw:null,providerKey:\"local\","
               "groups:$groups,mustChangePassword:true,sendWelcomeEmail:true){ "
               "responseResult{succeeded message} user{ id } } } }")
USER_UPDATE = ("mutation($id:Int!,$groups:[Int]!){ users { update(id:$id,groups:$groups){ "
               "responseResult{succeeded message} } } }")


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("--registry", default="library/_index/registry.json")
    ap.add_argument("--eligibility-file", help="JSON: {subscribers:[], purchasers:{slug:[]}}")
    ap.add_argument("--apply", action="store_true", help="perform writes (default: dry-run)")
    args = ap.parse_args()

    mode = "APPLY" if args.apply else "DRY-RUN"
    sols = load_solutions(args.registry)
    print(f"[{mode}] {len(sols)} solutions; Wiki gating under '{SOLUTIONS_ROOT}/'\n")

    by_name = groups_by_name()

    print("Phase 1 — structure")
    # 1a. deny anonymous access to solutions/. ONLY the Guests group gets the deny:
    # Guests is the only group with a broad allow (path ""). Adding the same deny to a group a
    # logged-in customer might also belong to (e.g. Public Users) would TIE with the Subscribers
    # 'solutions' allow, and Wiki.js breaks allow/deny ties in favor of DENY — which would lock
    # out paying customers. Public Users has no solutions allow, so it needs no deny.
    if "Guests" in by_name:
        set_rule(by_name["Guests"], rule(SOLUTIONS_ROOT, True, DENY_ROLES), None, args.apply)
        # deny anonymous access to internal (non-public) folders too
        for folder in INTERNAL_DENY:
            set_rule(by_name["Guests"], rule(folder, True, DENY_ROLES), None, args.apply)
    # 1b. subscribers (all solutions) — exclusive ALLOW on solutions/
    sub_gid = ensure_group("Subscribers", by_name, args.apply)
    if sub_gid:
        set_access_rule(sub_gid, SOLUTIONS_ROOT, args.apply)
    # 1c. per-solution purchaser groups — exclusive ALLOW on that solution's path only
    purch_gid = {}
    for s in sols:
        gname = f"Purchasers: {s['slug']}"
        gid = ensure_group(gname, by_name, args.apply)
        purch_gid[s["slug"]] = gid
        if gid:
            path = f"{SOLUTIONS_ROOT}/{s['category_slug']}/{s['slug']}"
            set_access_rule(gid, path, args.apply)

    # Phase 2 — users
    elig = {"subscribers": [], "purchasers": {}}
    if args.eligibility_file:
        elig = json.loads(open(args.eligibility_file, encoding="utf-8").read())
    subs = elig.get("subscribers", [])
    purch = elig.get("purchasers", {})
    total_users = len(set(subs) | {e for v in purch.values() for e in v})
    print(f"\nPhase 2 — user sync ({total_users} eligible customer(s))")
    if total_users == 0:
        print("  (no orders/subscriptions yet — nothing to provision)")
    else:
        # desired group membership per email
        want = {}
        for e in subs:
            want.setdefault(e, set()).add(sub_gid)
        for slug, emails in purch.items():
            for e in emails:
                if purch_gid.get(slug):
                    want.setdefault(e, set()).add(purch_gid[slug])
        for email, gids in want.items():
            gids = sorted(g for g in gids if g)
            found = gql(USER_SEARCH, {"q": email})["users"]["search"]
            match = next((u for u in found if u["email"].lower() == email.lower()), None)
            if not args.apply:
                print(f"  WOULD {'UPDATE' if match else 'CREATE'} {email} -> groups {gids}")
                continue
            if match:
                gql(USER_UPDATE, {"id": int(match["id"]), "groups": gids})
                print(f"  UPDATE {email} -> groups {gids}")
            else:
                r = gql(USER_CREATE, {"email": email, "name": email.split("@")[0],
                                      "groups": gids})["users"]["create"]
                ok = r["responseResult"]["succeeded"]
                print(f"  {'CREATE' if ok else 'FAIL  '} {email} -> groups {gids}"
                      f"{'' if ok else ' :: '+r['responseResult']['message']}")

    print(f"\n[{mode}] done.")


if __name__ == "__main__":
    main()
