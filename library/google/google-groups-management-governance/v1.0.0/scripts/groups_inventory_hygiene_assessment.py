#!/usr/bin/env python3
# groups_inventory_hygiene_assessment.py — read-only Groups estate + hygiene baseline (Stage 0)
#
# PURPOSE: Enumerate every Google Group in the domain and classify each into hygiene buckets before any
#          change: ORPHANED (no live owner), STALE (empty / no members), EXTERNAL-EXPOSED (members
#          outside the org OR public settings), OVER-PERMISSIONED (access/security group with open
#          settings), and NAMING-NONCONFORMANT (name/email off the naming standard). READ-ONLY: it only
#          calls Directory (Groups/Members/Users) + Groups Settings read endpoints; it never writes.
# HOW TO RUN: python groups_inventory_hygiene_assessment.py --domain corp.example [--scope finance]
#             [--max 5000] [--json]
#             (Python 3.10+, OAuth/ADC or a delegated service account with the *.readonly scopes in
#              Requirement 2.6; needs `pip install google-api-python-client google-auth`. See --help.)
# EXPECTED RESULTS: A printed baseline with a count per hygiene bucket and a sample of offending groups.
#          Exit 0 always (assessment, not a gate — the gates are the validator/checker tools).
#
# SAFETY: read-only. No credentials or keys are embedded — auth is resolved at runtime from ADC / an
#         authorized OAuth client / a delegated service account. Nothing is written to the tenant.

import argparse
import json
import sys

GROUP_RO = "https://www.googleapis.com/auth/admin.directory.group.readonly"
MEMBER_RO = "https://www.googleapis.com/auth/admin.directory.group.member.readonly"
USER_RO = "https://www.googleapis.com/auth/admin.directory.user.readonly"
SETTINGS = "https://www.googleapis.com/auth/apps.groups.settings"

# Email-prefix → canonical type, per the naming standard (Section 1 / Step 1.2).
PREFIX_TYPE = {"dl-": "distribution", "sec-": "security", "collab-": "collaboration",
               "dyn-": "dynamic", "ext-": "external"}
# Settings values considered "public"/open for the exposure + over-permissioned checks.
OPEN_POST = {"ANYONE_CAN_POST", "ALL_IN_DOMAIN_CAN_POST"}
OPEN_VIEW = {"ANYONE_CAN_VIEW"}


def build_services():
    """Build read-only Directory + Groups Settings services (no secrets in code)."""
    try:
        import google.auth
        from googleapiclient.discovery import build
    except ImportError:
        print("ERROR: pip install google-api-python-client google-auth", file=sys.stderr)
        sys.exit(2)
    creds, _ = google.auth.default(scopes=[GROUP_RO, MEMBER_RO, USER_RO, SETTINGS])
    directory = build("admin", "directory_v1", credentials=creds, cache_discovery=False)
    settings = build("groupssettings", "v1", credentials=creds, cache_discovery=False)
    return directory, settings


def org_domains(directory, primary):
    """Return the set of domains owned by this org (for external-member detection)."""
    domains = {primary.lower()}
    try:
        resp = directory.domains().list(customer="my_customer").execute()
        for d in resp.get("domains", []):
            domains.add(d.get("domainName", "").lower())
    except Exception:
        pass  # fall back to the primary domain only
    return domains


def list_groups(directory, domain, scope, limit):
    groups, page = [], None
    while len(groups) < limit:
        resp = directory.groups().list(domain=domain, maxResults=200, pageToken=page).execute()
        for g in resp.get("groups", []):
            if scope and scope.lower() not in (g.get("email", "").lower() + g.get("name", "").lower()):
                continue
            groups.append(g)
        page = resp.get("nextPageToken")
        if not page:
            break
    return groups[:limit]


def group_members(directory, email):
    members, page = [], None
    while True:
        resp = directory.members().list(groupKey=email, maxResults=200, pageToken=page).execute()
        members.extend(resp.get("members", []))
        page = resp.get("nextPageToken")
        if not page:
            break
    return members


def group_settings(settings, email):
    try:
        return settings.groups().get(groupUniqueId=email, alt="json").execute()
    except Exception:
        return {}


def classify(g, members, cfg, org_doms, findings):
    email = g.get("email", "")
    local = email.split("@", 1)[0].lower()
    owners = [m for m in members if m.get("role") == "OWNER" and m.get("status") != "SUSPENDED"]
    external = [m for m in members if m.get("email", "").split("@")[-1].lower() not in org_doms]
    prefix = next((p for p in PREFIX_TYPE if local.startswith(p)), None)
    gtype = PREFIX_TYPE.get(prefix)

    if not owners:
        findings["ORPHANED"].append(email)
    if len(members) == 0:
        findings["STALE"].append(email)
    public = cfg.get("whoCanViewGroup") in OPEN_VIEW or cfg.get("whoCanPostMessage") in OPEN_POST
    if external and prefix != "ext-":
        findings["EXTERNAL-EXPOSED"].append(f"{email} ({len(external)} external)")
    elif public and prefix != "ext-":
        findings["EXTERNAL-EXPOSED"].append(f"{email} (public settings)")
    if gtype == "security" and cfg.get("whoCanPostMessage") in OPEN_POST:
        findings["OVER-PERMISSIONED"].append(email)
    if prefix is None:
        findings["NAMING-NONCONFORMANT"].append(email)


def main():
    ap = argparse.ArgumentParser(description="Read-only Google Groups estate + hygiene baseline.")
    ap.add_argument("--domain", required=True, help="Primary domain, e.g. corp.example")
    ap.add_argument("--scope", help="Substring filter on email/name (e.g. a function like 'finance')")
    ap.add_argument("--max", type=int, default=5000, help="Max groups to scan (default 5000)")
    ap.add_argument("--json", action="store_true", help="Also print a JSON summary")
    args = ap.parse_args()

    print(f"Groups inventory + hygiene assessment (READ-ONLY) — domain={args.domain} "
          f"scope={args.scope or 'ALL'}\n")
    directory, settings = build_services()
    org_doms = org_domains(directory, args.domain)
    groups = list_groups(directory, args.domain, args.scope, args.max)
    print(f"  groups in scope: {len(groups)}   org domains: {sorted(org_doms)}")

    buckets = ["ORPHANED", "STALE", "EXTERNAL-EXPOSED", "OVER-PERMISSIONED", "NAMING-NONCONFORMANT"]
    findings = {b: [] for b in buckets}
    for g in groups:
        email = g.get("email", "")
        try:
            classify(g, group_members(directory, email), group_settings(settings, email),
                     org_doms, findings)
        except Exception as e:  # never abort the whole sweep on one group
            print(f"  ! skipped {email}: {e}", file=sys.stderr)

    print(f"\n== Hygiene summary (scanned {len(groups)} groups) ==")
    for b in buckets:
        items = findings[b]
        print(f"  {b:<22} {len(items)}")
        for name in items[:5]:
            print(f"      - {name}")
        if len(items) > 5:
            print(f"      … +{len(items) - 5} more")

    if args.json:
        print("\nJSON:\n" + json.dumps(
            {"domain": args.domain, "scope": args.scope, "scanned": len(groups),
             "counts": {b: len(findings[b]) for b in buckets}, "findings": findings}, indent=2))
    return 0  # assessment always exits 0


if __name__ == "__main__":
    sys.exit(main())
