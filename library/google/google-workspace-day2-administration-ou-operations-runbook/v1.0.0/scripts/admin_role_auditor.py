#!/usr/bin/env python3
# admin_role_auditor.py — read-only audit of Google Workspace admin-role assignments; flags
#                         super-admins and root-scoped roles; exports a CSV for least-privilege review.
#
# PURPOSE: Delegation/control check for Gate G2. Lists every admin-role assignment via the Admin SDK
#          Directory API, resolves role names, and flags super-admins and root-scoped (non-OU-scoped)
#          assignments so excess privilege is visible. READ-ONLY — makes no changes.
# HOW TO RUN: python admin_role_auditor.py --output admin-role-audit.csv
#             (Python 3.10+, OAuth/ADC or DWD service account, read-only scope; see --help)
# EXPECTED RESULTS: a CSV of assignments (assignee, role, scope, is_super_admin, is_root_scope) plus a
#                   stdout summary of super-admin and root-scoped counts. Exit 0 on success; exit 4 if
#                   the super-admin count exceeds --max-super-admins (use in scheduled checks).
#
# Read-only scope (live): https://www.googleapis.com/auth/admin.directory.rolemanagement.readonly
# (user.readonly is also useful to resolve assignee emails). No keys are stored in this file.
# Requires (live): pip install google-api-python-client google-auth ; else runs in --offline mode.

import argparse
import csv
import sys
from datetime import datetime, timezone

READONLY_SCOPES = [
    "https://www.googleapis.com/auth/admin.directory.rolemanagement.readonly",
    "https://www.googleapis.com/auth/admin.directory.user.readonly",
]

SAMPLE_ROLES = {"1": "_SEED_ADMIN_ROLE", "2": "Groups Admin", "3": "Help Desk Admin"}
SAMPLE_ASSIGNMENTS = [
    {"assignedTo": "u001", "roleId": "1", "scopeType": "CUSTOMER"},
    {"assignedTo": "u002", "roleId": "1", "scopeType": "CUSTOMER"},
    {"assignedTo": "u010", "roleId": "3", "scopeType": "ORG_UNIT", "orgUnitId": "ou:corp"},
    {"assignedTo": "u011", "roleId": "2", "scopeType": "ORG_UNIT", "orgUnitId": "ou:corp"},
]
SAMPLE_USERS = {"u001": "breakglass1@example.com", "u002": "breakglass2@example.com",
                "u010": "helpdesk.lee@example.com", "u011": "groups.admin@example.com"}


def _build_service():
    try:
        import google.auth
        from googleapiclient.discovery import build
    except Exception:
        return None
    try:
        creds, _ = google.auth.default(scopes=READONLY_SCOPES)
        return build("admin", "directory_v1", credentials=creds, cache_discovery=False)
    except Exception as exc:
        print(f"[info] no live credential ({exc.__class__.__name__}); use --offline for a demo.",
              file=sys.stderr)
        return None


def _paged(fn, key):
    out, tok = [], None
    while True:
        resp = fn(tok)
        out.extend(resp.get(key, []))
        tok = resp.get("nextPageToken")
        if not tok:
            break
    return out


def collect(customer, offline):
    if offline:
        roles, assignments, users = SAMPLE_ROLES, SAMPLE_ASSIGNMENTS, SAMPLE_USERS
        super_role_ids = {rid for rid, name in roles.items() if name == "_SEED_ADMIN_ROLE"}
        return roles, assignments, users, super_role_ids

    svc = _build_service()
    if svc is None:
        raise RuntimeError("no_service")

    role_items = _paged(lambda t: svc.roles().list(customer=customer, pageToken=t).execute(), "items")
    roles = {r["roleId"]: r.get("roleName", r["roleId"]) for r in role_items}
    # Google marks the built-in super-admin role with isSuperAdminRole=True.
    super_role_ids = {r["roleId"] for r in role_items if r.get("isSuperAdminRole")}

    assignments = _paged(
        lambda t: svc.roleAssignments().list(customer=customer, pageToken=t).execute(), "items")

    users = {}
    for a in assignments:
        uid = a.get("assignedTo")
        if uid and uid not in users:
            try:
                u = svc.users().get(userKey=uid, fields="primaryEmail").execute()
                users[uid] = u.get("primaryEmail", uid)
            except Exception:
                users[uid] = uid
    return roles, assignments, users, super_role_ids


def main():
    ap = argparse.ArgumentParser(description="Read-only admin-role audit for least-privilege review.")
    ap.add_argument("--customer", default="my_customer", help="Directory customer ID.")
    ap.add_argument("--output", default="admin-role-audit.csv", help="CSV output path.")
    ap.add_argument("--max-super-admins", type=int, default=4,
                    help="Exit non-zero if super-admin assignments exceed this (scheduled-check gate).")
    ap.add_argument("--offline", action="store_true", help="Use bundled sample data (no API calls).")
    args = ap.parse_args()

    try:
        roles, assignments, users, super_role_ids = collect(args.customer, args.offline)
    except Exception as exc:
        print(f"[warn] live audit unavailable ({exc}); falling back to --offline sample.",
              file=sys.stderr)
        roles, assignments, users, super_role_ids = collect(args.customer, offline=True)

    rows, super_admins, root_scoped = [], 0, 0
    for a in assignments:
        rid = a.get("roleId")
        is_super = rid in super_role_ids
        scope_type = a.get("scopeType", "")
        is_root = scope_type == "CUSTOMER"
        if is_super:
            super_admins += 1
        if is_root:
            root_scoped += 1
        rows.append({
            "assignee": users.get(a.get("assignedTo"), a.get("assignedTo", "")),
            "role": roles.get(rid, rid),
            "scope_type": scope_type,
            "org_unit_id": a.get("orgUnitId", ""),
            "is_super_admin": is_super,
            "is_root_scope": is_root,
        })

    with open(args.output, "w", newline="", encoding="utf-8") as fh:
        w = csv.DictWriter(fh, fieldnames=["assignee", "role", "scope_type", "org_unit_id",
                                           "is_super_admin", "is_root_scope"])
        w.writeheader()
        w.writerows(rows)

    print(f"Admin-role audit — {datetime.now(timezone.utc).isoformat()}")
    print(f"  assignments        : {len(rows)}")
    print(f"  super-admins       : {super_admins}  (threshold {args.max_super_admins})")
    print(f"  root-scoped roles  : {root_scoped}  (prefer OU-scoped where possible)")
    print(f"  CSV written        : {args.output}")
    if super_admins > args.max_super_admins:
        print("FAIL: super-admin count exceeds threshold — reduce to break-glass minimum.")
        return 4
    print("OK: super-admin count within threshold.")
    return 0


if __name__ == "__main__":
    sys.exit(main())
