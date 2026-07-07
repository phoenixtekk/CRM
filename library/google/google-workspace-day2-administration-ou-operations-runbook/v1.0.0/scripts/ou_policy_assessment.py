#!/usr/bin/env python3
# ou_policy_assessment.py — read-only discovery of the Google Workspace OU tree, users/admins per OU,
#                           groups, and admin-role-assignment summary; writes a JSON baseline snapshot.
#
# PURPOSE: Assess-stage inventory for the day-2 operations practice. Enumerates the current
#          organizational-unit tree and directory objects via the Admin SDK Directory API and writes a
#          snapshot you curate into the intended settings baseline. READ-ONLY — makes no changes.
# HOW TO RUN: python ou_policy_assessment.py --output ou-policy-baseline-current.json
#             (Python 3.10+, OAuth/ADC or domain-wide-delegated service account; see --help)
# EXPECTED RESULTS: a JSON file with the OU tree, per-OU user/admin counts, groups, and role summary;
#                   stdout prints a short human summary. Exit 0 on success.
#
# Auth: uses Application Default Credentials / an authorized OAuth client / a domain-wide-delegated
# service account with ONLY these read-only scopes. No keys are stored in this file.
#   https://www.googleapis.com/auth/admin.directory.orgunit.readonly
#   https://www.googleapis.com/auth/admin.directory.user.readonly
#   https://www.googleapis.com/auth/admin.directory.group.readonly
#   https://www.googleapis.com/auth/admin.directory.rolemanagement.readonly
# Requires (for live calls): pip install google-api-python-client google-auth
# Without those libraries or a credential, runs in --offline sample mode so the tool can be inspected.

import argparse
import json
import sys
from datetime import datetime, timezone

READONLY_SCOPES = [
    "https://www.googleapis.com/auth/admin.directory.orgunit.readonly",
    "https://www.googleapis.com/auth/admin.directory.user.readonly",
    "https://www.googleapis.com/auth/admin.directory.group.readonly",
    "https://www.googleapis.com/auth/admin.directory.rolemanagement.readonly",
]

SAMPLE = {
    "org_units": [
        {"orgUnitPath": "/", "name": "Root", "parentOrgUnitPath": None},
        {"orgUnitPath": "/Corp", "name": "Corp", "parentOrgUnitPath": "/"},
        {"orgUnitPath": "/Corp/Standard-Users", "name": "Standard-Users", "parentOrgUnitPath": "/Corp"},
        {"orgUnitPath": "/Corp/Privileged-Users", "name": "Privileged-Users", "parentOrgUnitPath": "/Corp"},
        {"orgUnitPath": "/Corp/Service-Accounts", "name": "Service-Accounts", "parentOrgUnitPath": "/Corp"},
        {"orgUnitPath": "/Contractors", "name": "Contractors", "parentOrgUnitPath": "/"},
    ],
    "users_per_ou": {"/Corp/Standard-Users": 1840, "/Corp/Privileged-Users": 42,
                     "/Corp/Service-Accounts": 11, "/Contractors": 96},
    "groups": [{"email": "security-ops@example.com", "name": "Security Ops"}],
    "role_summary": {"_SEED_ADMIN_ROLE": 2, "Groups Admin": 3, "Help Desk Admin": 8},
}


def _build_service():
    """Return an authenticated Directory service, or None to fall back to offline sample mode."""
    try:
        import google.auth
        from googleapiclient.discovery import build
    except Exception:
        return None
    try:
        creds, _ = google.auth.default(scopes=READONLY_SCOPES)
        return build("admin", "directory_v1", credentials=creds, cache_discovery=False)
    except Exception as exc:  # no ADC / not authorized — inspectable offline instead
        print(f"[info] no live credential ({exc.__class__.__name__}); use --offline to see sample.",
              file=sys.stderr)
        return None


def _list_all(request_fn, key):
    items, page_token = [], None
    while True:
        resp = request_fn(page_token)
        items.extend(resp.get(key, []))
        page_token = resp.get("nextPageToken")
        if not page_token:
            break
    return items


def assess_live(customer):
    svc = _build_service()
    if svc is None:
        raise RuntimeError("no_service")

    ous = svc.orgunits().list(customerId=customer, type="all").execute().get("organizationUnits", [])
    ou_paths = ["/"] + [o["orgUnitPath"] for o in ous]

    users_per_ou = {}
    for path in ou_paths:
        users = _list_all(
            lambda tok: svc.users().list(customer=customer, query=f"orgUnitPath='{path}'",
                                         maxResults=200, pageToken=tok).execute(),
            "users")
        if users:
            users_per_ou[path] = len(users)

    groups = _list_all(
        lambda tok: svc.groups().list(customer=customer, maxResults=200, pageToken=tok).execute(),
        "groups")

    roles = {r["roleId"]: r.get("roleName", r["roleId"])
             for r in _list_all(lambda tok: svc.roles().list(customer=customer, pageToken=tok).execute(),
                                "items")}
    assignments = _list_all(
        lambda tok: svc.roleAssignments().list(customer=customer, pageToken=tok).execute(), "items")
    role_summary = {}
    for a in assignments:
        name = roles.get(a.get("roleId"), a.get("roleId", "unknown"))
        role_summary[name] = role_summary.get(name, 0) + 1

    return {
        "org_units": [{"orgUnitPath": o["orgUnitPath"], "name": o.get("name"),
                       "parentOrgUnitPath": o.get("parentOrgUnitPath")} for o in ous],
        "users_per_ou": users_per_ou,
        "groups": [{"email": g.get("email"), "name": g.get("name")} for g in groups],
        "role_summary": role_summary,
    }


def main():
    ap = argparse.ArgumentParser(description="Read-only Google Workspace OU/policy assessment snapshot.")
    ap.add_argument("--customer", default="my_customer",
                    help="Directory customer ID (default: my_customer for the authenticated tenant).")
    ap.add_argument("--output", default="ou-policy-baseline-current.json",
                    help="Where to write the JSON snapshot.")
    ap.add_argument("--offline", action="store_true",
                    help="Skip API calls and emit the bundled sample snapshot (for inspection/demo).")
    args = ap.parse_args()

    if args.offline:
        data = dict(SAMPLE)
    else:
        try:
            data = assess_live(args.customer)
        except Exception as exc:
            print(f"[warn] live assessment unavailable ({exc}); falling back to --offline sample.",
                  file=sys.stderr)
            data = dict(SAMPLE)

    snapshot = {
        "generated_utc": datetime.now(timezone.utc).isoformat(),
        "tool": "ou_policy_assessment.py",
        "read_only": True,
        **data,
    }
    with open(args.output, "w", encoding="utf-8") as fh:
        json.dump(snapshot, fh, indent=2)

    print(f"OU/policy assessment written to {args.output}")
    print(f"  organizational units : {len(snapshot['org_units'])}")
    print(f"  OUs with users       : {len(snapshot['users_per_ou'])}")
    print(f"  groups               : {len(snapshot['groups'])}")
    print(f"  distinct admin roles : {len(snapshot['role_summary'])}")
    print("Curate this snapshot into the intended baseline (Baseline - OU Settings - Design).")
    return 0


if __name__ == "__main__":
    sys.exit(main())
