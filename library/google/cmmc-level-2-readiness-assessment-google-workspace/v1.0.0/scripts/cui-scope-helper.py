#!/usr/bin/env python3
# cui-scope-helper.py — plan/scaffold the CUI boundary OU, pilot group, and named control artifacts.
#
# PURPOSE: Scope/config helper. DRY-RUN by default: reads a CUI-inventory CSV and prints the plan of
#          named artifacts (boundary OU, pilot group, DLP/sharing/CAA/retention/export names) plus the
#          user->OU move list, so the operator can review before touching the tenant. With --apply it
#          performs ONLY the low-risk, reversible scaffolding it is explicitly scoped to (create the OU
#          and pilot group, and move listed users into the boundary OU) — never DLP/sharing/CAA
#          enforcement, which stay manual/piloted per the implementation guide.
# HOW TO RUN: python cui-scope-helper.py --inventory cui-inventory.csv            # dry-run plan
#             python cui-scope-helper.py --inventory cui-inventory.csv --apply --credentials sa.json
#             (Python 3.10+, OAuth/ADC; write scopes only needed with --apply; see --help)
# EXPECTED RESULTS: Dry-run prints the artifact plan + move list and exits. --apply creates OU+group and
#                   moves users, printing each action; enforcing controls are intentionally NOT automated.
#
# pip install google-api-python-client google-auth
#
# BOUNDARY: This scaffolds scope only. It does NOT decide what is CUI (compliance/assessor) and does NOT
# apply enforcing controls (piloted manually). Safe-by-default (dry-run); no credentials/keys in code.

import argparse
import csv
import sys

# Write scopes are requested ONLY when --apply is used, and only for OU + user-move + group create.
WRITE_SCOPES = [
    "https://www.googleapis.com/auth/admin.directory.orgunit",
    "https://www.googleapis.com/auth/admin.directory.user",
    "https://www.googleapis.com/auth/admin.directory.group",
]

# The named control artifacts this solution standardizes on (planned here, applied per implementation guide).
ARTIFACT_PLAN = {
    "boundary_ou": "/CUI – Boundary – Org",
    "enclave_ou": "/CUI – Boundary – Org/CUI – Enclave – Org",
    "pilot_group": "CUI – Pilot – Org",
    "dlp_monitor": "DLP – CUI – Monitor",
    "dlp_enforce": "DLP – CUI – Enforce",
    "sharing_policy": "Sharing – CUI Boundary – Restricted",
    "caa_level": "CAA – CUI Boundary – Enforce",
    "retention_rule": "Retention – CUI – Org",
    "audit_export": "AuditExport – CUI – Org",
}


def build_directory(subject, credentials_file):
    from google.oauth2 import service_account
    from googleapiclient.discovery import build
    creds = service_account.Credentials.from_service_account_file(credentials_file, scopes=WRITE_SCOPES)
    if subject:
        creds = creds.with_subject(subject)
    return build("admin", "directory_v1", credentials=creds, cache_discovery=False)


def read_inventory(path):
    """CUI inventory CSV: expects a 'user' column (email) and optional 'enclave' flag."""
    with open(path, newline="", encoding="utf-8") as fh:
        rows = list(csv.DictReader(fh))
    users = [r for r in rows if r.get("user")]
    return users


def print_plan(users):
    print("=== CUI scope plan (named artifacts) ===")
    for k, v in ARTIFACT_PLAN.items():
        print(f"  {k:14} : {v}")
    print(f"\n=== Boundary user moves ({len(users)}) ===")
    for u in users:
        target = ARTIFACT_PLAN["enclave_ou"] if str(u.get("enclave", "")).lower() in ("1", "true", "yes") \
            else ARTIFACT_PLAN["boundary_ou"]
        print(f"  move {u['user']:40} -> {target}")
    print("\nEnforcing controls (DLP/sharing/CAA/retention/export) are NOT automated here —")
    print("apply them pilot-first per 03-implementation.md, using the names above.")


def apply(users, directory):
    ou = ARTIFACT_PLAN["boundary_ou"]
    # Create boundary OU (idempotent-ish: ignore 'already exists').
    _safe(lambda: directory.orgunits().insert(customer="my_customer", body={
        "name": "CUI – Boundary – Org", "parentOrgUnitPath": "/"}).execute(), f"create OU {ou}")
    # Create pilot group.
    _safe(lambda: directory.groups().insert(body={
        "email": None, "name": ARTIFACT_PLAN["pilot_group"]}).execute(),
        f"create group {ARTIFACT_PLAN['pilot_group']} (set email in tenant)")
    # Move users into the boundary OU.
    for u in users:
        target = ARTIFACT_PLAN["enclave_ou"] if str(u.get("enclave", "")).lower() in ("1", "true", "yes") else ou
        _safe(lambda em=u["user"], t=target: directory.users().update(
            userKey=em, body={"orgUnitPath": t}).execute(), f"move {u['user']} -> {target}")


def _safe(fn, label):
    try:
        fn()
        print(f"  OK: {label}")
    except Exception as e:  # noqa: BLE001
        print(f"  SKIP/ERR: {label} ({e.__class__.__name__}) — verify manually")


def main():
    p = argparse.ArgumentParser(description="Plan/scaffold the CUI boundary scope (dry-run by default).")
    p.add_argument("--inventory", required=True, help="CUI inventory CSV with a 'user' column")
    p.add_argument("--credentials", help="path to a delegated service-account file (never commit it); needed with --apply")
    p.add_argument("--subject", help="admin user to impersonate for domain-wide delegation")
    p.add_argument("--apply", action="store_true", help="perform OU/group create + user moves (write). Default is dry-run.")
    args = p.parse_args()

    try:
        users = read_inventory(args.inventory)
    except FileNotFoundError:
        print(f"ERROR: inventory not found: {args.inventory}", file=sys.stderr)
        sys.exit(2)

    if not args.apply:
        print("[dry-run] No changes will be made. Review the plan, then re-run with --apply.\n")
        print_plan(users)
        return

    if not args.credentials:
        print("ERROR: --apply requires --credentials (write scopes).", file=sys.stderr)
        sys.exit(2)
    print("APPLY: creating boundary OU + pilot group and moving users. Enforcing controls remain manual.\n")
    directory = build_directory(args.subject, args.credentials)
    apply(users, directory)
    print("\nDone. Next: apply DLP/sharing/CAA pilot-first per 03-implementation.md; then evidence.")


if __name__ == "__main__":
    main()
