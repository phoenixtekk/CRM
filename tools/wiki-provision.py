#!/usr/bin/env python3
"""
wiki-provision.py — purchase/subscription -> Wiki.js doc-access automation.

Runs ON linuxg5 (store DB + Wiki.js API both reachable). Reconciles, idempotently:
  - active subscribers          -> Wiki.js group "Subscribers"        (all solution docs)
  - one-time solution purchasers-> Wiki.js group "Purchasers: <slug>" (that solution's docs)
Provisions a Local Wiki.js account (welcome email -> set password) for each eligible customer,
adds them to the right group(s), and REMOVES anyone no longer eligible (refund / membership lapse).

Eligibility is read live from the Bagisto DB; the solution slug is taken from the product url_key
(<slug>-commercial / <slug>-nonprofit / <slug>-government) so no registry file is needed on the server.

Env:
  DB creds   from /home/workplace/public_html/.env  (DB_HOST/DB_USERNAME/DB_PASSWORD/DB_DATABASE)
  Wiki creds from /home/workplace/.wikijs.env        (WIKIJS_URL / WIKIJS_TOKEN)

Usage (on linuxg5, as the workplace user):
  sudo -u workplace python3 wiki-provision.py            # DRY-RUN (no writes, no emails)
  sudo -u workplace python3 wiki-provision.py --apply    # provision + reconcile for real
"""
import os, re, sys, json, subprocess, argparse
from urllib import request as urlreq, error as urlerr

UA = ("Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 "
      "(KHTML, like Gecko) Chrome/124.0 Safari/537.36")
ENV_DB = "/home/workplace/public_html/.env"
ENV_WIKI = "/home/workplace/.wikijs.env"
ACTIVE_SUB = "('active','trialing')"
PAID_ORDER = "('completed','processing')"


def load_env(path):
    d = {}
    if os.path.exists(path):
        for line in open(path, encoding="utf-8"):
            line = line.strip()
            if line and not line.startswith("#") and "=" in line:
                k, v = line.split("=", 1)
                d[k.strip()] = v.strip().strip('"').strip("'")
    return d


def mysql(db, query):
    """Run a query via the mysql CLI, return list of rows (tab-split), no header."""
    cmd = ["mysql", "-h", db["DB_HOST"], "-u", db["DB_USERNAME"],
           "-p" + db["DB_PASSWORD"], db["DB_DATABASE"], "-N", "-B", "-e", query]
    out = subprocess.run(cmd, capture_output=True, text=True)
    if out.returncode != 0:
        sys.exit("MySQL error: " + out.stderr[:300])
    return [r.split("\t") for r in out.stdout.splitlines() if r.strip()]


def gql(url, token, query, variables=None, tolerate=None):
    body = json.dumps({"query": query, "variables": variables or {}}).encode()
    req = urlreq.Request(url.rstrip("/") + "/graphql", data=body, method="POST")
    req.add_header("Content-Type", "application/json")
    req.add_header("Authorization", "Bearer " + token)
    req.add_header("User-Agent", UA)
    try:
        d = json.loads(urlreq.urlopen(req, timeout=30).read())
    except urlerr.HTTPError as e:
        sys.exit(f"Wiki.js HTTP {e.code}: {e.read().decode('utf-8','replace')[:300]}")
    if d.get("errors"):
        codes = {(e.get("extensions") or {}).get("code") for e in d["errors"]}
        if tolerate and codes <= set(tolerate):
            return None
        sys.exit("Wiki.js GraphQL errors: " + json.dumps(d["errors"])[:500])
    return d["data"]


def slug_from_urlkey(url_key):
    return re.sub(r"-(commercial|nonprofit|government)$", "", url_key or "")


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("--apply", action="store_true", help="perform writes (default: dry-run)")
    args = ap.parse_args()
    mode = "APPLY" if args.apply else "DRY-RUN"

    db = load_env(ENV_DB)
    wiki = load_env(ENV_WIKI)
    URL, TOKEN = wiki.get("WIKIJS_URL"), wiki.get("WIKIJS_TOKEN")
    if not URL or not TOKEN:
        sys.exit("Missing WIKIJS_URL/WIKIJS_TOKEN in " + ENV_WIKI)

    # ---- eligibility from the store DB ----
    subs = {e[0].strip().lower() for e in mysql(db,
        f"SELECT c.email FROM pt_sub_subscriptions s JOIN customers c ON c.id=s.customer_id "
        f"WHERE s.status IN {ACTIVE_SUB} AND s.current_period_end > NOW();") if e and e[0]}
    purch = {}  # slug -> set(emails)
    for row in mysql(db,
        f"SELECT LOWER(o.customer_email), pf.url_key FROM order_items oi "
        f"JOIN orders o ON o.id=oi.order_id JOIN product_flat pf ON pf.product_id=oi.product_id "
        f"WHERE o.status IN {PAID_ORDER} AND pf.url_key IS NOT NULL AND o.customer_email IS NOT NULL;"):
        if len(row) < 2 or not row[0]:
            continue
        slug = slug_from_urlkey(row[1])
        if slug:
            purch.setdefault(slug, set()).add(row[0])

    total = len(subs | {e for v in purch.values() for e in v})
    print(f"[{mode}] eligibility: {len(subs)} subscriber(s), "
          f"{sum(len(v) for v in purch.values())} purchase-grants across {len(purch)} solution(s); "
          f"{total} unique customer(s)")
    if total == 0:
        print("  (no active subscriptions or paid orders yet — nothing to provision)")

    # ---- desired group membership per email ----
    want = {}  # email -> set(group_name)
    for e in subs:
        want.setdefault(e, set()).add("Subscribers")
    for slug, emails in purch.items():
        for e in emails:
            want.setdefault(e, set()).add(f"Purchasers: {slug}")

    # ---- Wiki.js groups (name -> id), only the managed ones ----
    groups = {g["name"]: g["id"] for g in gql(URL, TOKEN, "{ groups { list { id name } } }")["groups"]["list"]}
    managed = {n: i for n, i in groups.items() if n == "Subscribers" or n.startswith("Purchasers: ")}

    # ---- reconcile each managed group's membership ----
    USER_SEARCH = "query($q:String!){ users { search(query:$q){ id email } } }"
    USER_SINGLE = "query($id:Int!){ users { single(id:$id){ id email groups{ id } } } }"
    USER_CREATE = ("mutation($e:String!,$n:String!,$g:[Int]!){ users { create(email:$e,name:$n,"
                   "passwordRaw:null,providerKey:\"local\",groups:$g,mustChangePassword:true,"
                   "sendWelcomeEmail:true){ responseResult{ succeeded message } user{ id } } } }")
    USER_UPDATE = ("mutation($id:Int!,$g:[Int]!){ users { update(id:$id,groups:$g){ "
                   "responseResult{ succeeded message } } } }")

    def find_user(email):
        for u in gql(URL, TOKEN, USER_SEARCH, {"q": email})["users"]["search"]:
            if u["email"].lower() == email:
                return u
        return None

    # current members of managed groups (to compute revocations)
    # We iterate eligible users for grants, then scan managed-group members for revokes.
    changes = 0

    # 1) grant: ensure each eligible user exists and is in its desired managed groups
    for email, gnames in want.items():
        want_ids = sorted(managed[n] for n in gnames if n in managed)
        missing = [n for n in gnames if n not in managed]
        if missing:
            print(f"  WARN group(s) not found for {email}: {missing} (publish that solution first)")
        u = find_user(email)
        if u:
            cur = {int(x["id"]) for x in gql(URL, TOKEN, USER_SINGLE, {"id": int(u["id"])})["users"]["single"]["groups"]}
            # keep non-managed groups, set managed ones to desired
            keep = {gid for gid in cur if gid not in managed.values()}
            newset = sorted(keep | set(want_ids))
            if newset != sorted(cur):
                print(f"  {'UPDATE' if args.apply else 'WOULD UPDATE'} {email} groups -> {newset}")
                if args.apply:
                    gql(URL, TOKEN, USER_UPDATE, {"id": int(u["id"]), "g": newset}); changes += 1
        else:
            print(f"  {'CREATE' if args.apply else 'WOULD CREATE'} {email} (+welcome email) groups {want_ids}")
            if args.apply:
                r = gql(URL, TOKEN, USER_CREATE, {"e": email, "n": email.split('@')[0], "g": want_ids})
                ok = r["users"]["create"]["responseResult"]["succeeded"]; changes += 1
                if not ok:
                    print("    FAIL:", r["users"]["create"]["responseResult"]["message"])

    # 2) revoke: anyone in a managed group who is NOT eligible for it
    admin_gid = groups.get("Administrators")
    all_users = gql(URL, TOKEN, "{ users { list { id email } } }")["users"]["list"]
    mid_to_name = {i: n for n, i in managed.items()}
    for u in all_users:
        email = u["email"].lower()
        cur = {int(x["id"]) for x in gql(URL, TOKEN, USER_SINGLE, {"id": int(u["id"])})["users"]["single"]["groups"]}
        if admin_gid in cur:   # never touch staff/admin memberships
            continue
        desired_managed = {managed[n] for n in want.get(email, set()) if n in managed}
        revoke = {gid for gid in cur if gid in mid_to_name and gid not in desired_managed}
        if revoke:
            newset = sorted(cur - revoke)
            print(f"  {'REVOKE' if args.apply else 'WOULD REVOKE'} {email} from {[mid_to_name[g] for g in revoke]}")
            if args.apply:
                gql(URL, TOKEN, USER_UPDATE, {"id": int(u["id"]), "g": newset}); changes += 1

    print(f"[{mode}] done. {changes} change(s)" + ("" if args.apply else " (dry-run, nothing written)"))


if __name__ == "__main__":
    main()
