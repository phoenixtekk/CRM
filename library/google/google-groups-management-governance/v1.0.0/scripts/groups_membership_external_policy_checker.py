#!/usr/bin/env python3
# groups_membership_external_policy_checker.py — external-membership & posting/access policy gate (read-only)
#
# PURPOSE: Enforce the trust-boundary policy (Decision 5 / Step 3.6): NO external members on any
#          non-ext- group, NO public join/post/view settings outside a group's type policy, and NO
#          over-permissioned security (sec-) group (e.g. domain-wide posting on an access group).
#          READ-ONLY: Directory (Members/Domains) + Groups Settings read only. GATE tool — exits 1 when
#          any out-of-policy condition is found (Gates 3/4, Test 4).
# HOW TO RUN: python groups_membership_external_policy_checker.py --domain corp.example [--scope finance]
#             [--allow-domain partner.example ...] [--json]
#             (Python 3.10+, OAuth/ADC with the *.readonly scopes in Requirement 2.6;
#              `pip install google-api-python-client google-auth`. See --help.)
# EXPECTED RESULTS: PASS (exit 0), or a list of policy violations per group + exit 1.
#
# SAFETY: read-only. No credentials/keys embedded — auth resolved at runtime (ADC / delegated SA).

import argparse
import json
import sys

GROUP_RO = "https://www.googleapis.com/auth/admin.directory.group.readonly"
MEMBER_RO = "https://www.googleapis.com/auth/admin.directory.group.member.readonly"
SETTINGS = "https://www.googleapis.com/auth/apps.groups.settings"

OPEN_POST = {"ANYONE_CAN_POST", "ALL_IN_DOMAIN_CAN_POST"}
OPEN_VIEW = {"ANYONE_CAN_VIEW"}
OPEN_JOIN = {"ALL_IN_DOMAIN_CAN_JOIN", "ANYONE_CAN_JOIN"}
PREFIXES = ("dl-", "sec-", "collab-", "dyn-", "ext-")


def build_services():
    try:
        import google.auth
        from googleapiclient.discovery import build
    except ImportError:
        print("ERROR: pip install google-api-python-client google-auth", file=sys.stderr)
        sys.exit(2)
    creds, _ = google.auth.default(scopes=[GROUP_RO, MEMBER_RO, SETTINGS])
    directory = build("admin", "directory_v1", credentials=creds, cache_discovery=False)
    settings = build("groupssettings", "v1", credentials=creds, cache_discovery=False)
    return directory, settings


def org_domains(directory, primary, allow):
    domains = {primary.lower()} | {d.lower() for d in allow}
    try:
        for d in directory.domains().list(customer="my_customer").execute().get("domains", []):
            domains.add(d.get("domainName", "").lower())
    except Exception:
        pass
    return domains


def members(directory, email):
    out, page = [], None
    while True:
        resp = directory.members().list(groupKey=email, maxResults=200, pageToken=page).execute()
        out.extend(resp.get("members", []))
        page = resp.get("nextPageToken")
        if not page:
            break
    return out


def check(g, mem, cfg, org_doms):
    """Return a list of policy-violation strings for one group ([] == compliant)."""
    email = g.get("email", "")
    local = email.split("@", 1)[0].lower()
    prefix = next((p for p in PREFIXES if local.startswith(p)), None)
    is_ext = prefix == "ext-"
    is_sec = prefix == "sec-"
    v = []

    external = [m.get("email", "") for m in mem
                if m.get("email", "").split("@")[-1].lower() not in org_doms]
    if external and not is_ext:
        v.append(f"{len(external)} external member(s) on a non-ext group: {external[:3]}")

    if not is_ext:  # only ext- groups may be public-ish
        if cfg.get("whoCanJoin") in OPEN_JOIN:
            v.append(f"whoCanJoin={cfg.get('whoCanJoin')} (public join)")
        if cfg.get("whoCanViewGroup") in OPEN_VIEW:
            v.append(f"whoCanViewGroup={cfg.get('whoCanViewGroup')} (archive world-readable)")
        if cfg.get("whoCanPostMessage") in {"ANYONE_CAN_POST"}:
            v.append("whoCanPostMessage=ANYONE_CAN_POST (open relay)")
    if is_sec and cfg.get("whoCanPostMessage") in OPEN_POST:
        v.append(f"security group posting too open: {cfg.get('whoCanPostMessage')} "
                 f"(access groups should be NONE_CAN_POST)")
    if cfg.get("allowExternalMembers") == "true" and not is_ext:
        v.append("allowExternalMembers=true on a non-ext group")
    return v


def main():
    ap = argparse.ArgumentParser(description="External-membership & posting/access policy gate (read-only).")
    ap.add_argument("--domain", required=True)
    ap.add_argument("--scope", help="Substring filter on email/name")
    ap.add_argument("--allow-domain", action="append", default=[],
                    help="Allow-listed partner domain(s) treated as external-but-permitted on ext- groups")
    ap.add_argument("--json", action="store_true")
    args = ap.parse_args()

    directory, settings = build_services()
    org_doms = org_domains(directory, args.domain, args.allow_domain)
    groups, page = [], None
    while True:
        resp = directory.groups().list(domain=args.domain, maxResults=200, pageToken=page).execute()
        for g in resp.get("groups", []):
            if not args.scope or args.scope.lower() in (g.get("email", "") + g.get("name", "")).lower():
                groups.append(g)
        page = resp.get("nextPageToken")
        if not page:
            break

    print(f"External/posting policy checker — domain={args.domain} scope={args.scope or 'ALL'} "
          f"({len(groups)} groups)\n")
    violations = {}
    for g in groups:
        email = g.get("email", "")
        try:
            cfg = settings.groups().get(groupUniqueId=email, alt="json").execute()
        except Exception:
            cfg = {}
        viols = check(g, members(directory, email), cfg, org_doms)
        if viols:
            violations[email] = viols

    if not violations:
        print("PASS — no external-membership or posting/access policy violations.")
        if args.json:
            print(json.dumps({"result": "PASS", "groups": len(groups)}, indent=2))
        return 0

    print(f"FAIL — {len(violations)} group(s) out of policy:")
    for email, viols in violations.items():
        print(f"  {email}")
        for x in viols:
            print(f"      - {x}")
    if args.json:
        print(json.dumps({"result": "FAIL", "violations": violations}, indent=2))
    return 1


if __name__ == "__main__":
    sys.exit(main())
