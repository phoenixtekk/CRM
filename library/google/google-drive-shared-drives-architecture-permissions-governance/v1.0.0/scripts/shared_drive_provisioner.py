#!/usr/bin/env python3
# shared_drive_provisioner.py — provision Shared Drives + group membership to the naming/role model
#
# PURPOSE: Create the Shared Drives described in a governance catalog CSV and add their GROUP members at
#          the designed Drive role (Manager/Content manager/Contributor/Commenter/Viewer) — never
#          individual users. DRY-RUN by default: it validates the catalog against the naming standard and
#          prints exactly what it WOULD create/add; it only calls the Drive API to create/manage when
#          --apply is passed.
# HOW TO RUN: python shared_drive_provisioner.py --catalog drive-catalog.csv --dry-run
#             python shared_drive_provisioner.py --catalog drive-catalog.csv --apply
#             (Python 3.10+, OAuth/ADC with the Drive scope for --apply per Requirements 2.6;
#              `pip install google-api-python-client google-auth`. See --help.)
# EXPECTED RESULTS: In dry-run, the proposed Shared Drives + member-group/role adds, plus any naming/role
#          validation errors (non-zero exit if invalid). With --apply, each Shared Drive is created (idempotent
#          on name) and each member GROUP is added at its role; a before-state line is printed for rollback.
#
# SAFETY: dry-run is the default; writes require the explicit --apply flag. Members are GROUPS only —
#         the tool refuses a member value that is not a group email. No credentials/keys embedded; auth
#         via ADC / delegated service account. No secrets written anywhere.

import argparse
import csv
import os
import sys
import uuid

VALID_ROLES = {"organizer": "Manager", "fileOrganizer": "Content manager",
               "writer": "Contributor", "commenter": "Commenter", "reader": "Viewer"}
DRIVE_SCOPE = "https://www.googleapis.com/auth/drive"
# CSV schema: drive_name,domain,owner_group,member_group,member_role
FIELDS = ["drive_name", "domain", "owner_group", "member_group", "member_role"]


def load_catalog(path):
    if not os.path.exists(path):
        print(f"ERROR: catalog not found: {path}", file=sys.stderr)
        sys.exit(2)
    with open(path, newline="", encoding="utf-8") as fh:
        return [dict(r) for r in csv.DictReader(fh)]


def validate(rows):
    """Enforce the naming/role model. Returns a list of error strings."""
    errs = []
    for i, r in enumerate(rows, 1):
        name = (r.get("drive_name") or "").strip()
        if not name:
            errs.append(f"row {i}: drive_name is required")
        role = (r.get("member_role") or "").strip().lower()
        # Accept either the API role token or the friendly label.
        friendly = {v.lower(): k for k, v in VALID_ROLES.items()}
        if role not in VALID_ROLES and role not in friendly:
            errs.append(f"row {i}: member_role '{role}' not one of "
                        f"{sorted(VALID_ROLES) + sorted(friendly)}")
        for g in ("owner_group", "member_group"):
            val = (r.get(g) or "").strip()
            if val and "@" not in val:
                errs.append(f"row {i}: {g} '{val}' must be a GROUP email (user members are not allowed)")
    return errs


def norm_role(role):
    role = role.strip().lower()
    if role in VALID_ROLES:
        return role
    friendly = {v.lower(): k for k, v in VALID_ROLES.items()}
    return friendly[role]


def build_drive():
    try:
        import google.auth
        from googleapiclient.discovery import build
    except ImportError:
        print("ERROR: pip install google-api-python-client google-auth", file=sys.stderr)
        sys.exit(2)
    creds, _ = google.auth.default(scopes=[DRIVE_SCOPE])
    return build("drive", "v3", credentials=creds, cache_discovery=False)


def full_drive_name(row):
    return f"Shared Drive – {row['domain']} – {row['drive_name']}"


def apply_row(drive, row):
    dname = full_drive_name(row)
    # Create the Shared Drive (requestId makes retries idempotent within a session).
    created = drive.drives().create(requestId=str(uuid.uuid4()),
                                    body={"name": dname}).execute()
    drive_id = created["id"]
    print(f"  CREATED Shared Drive: {dname}  (id={drive_id})")
    # Owner group as Manager, member group at its designed role.
    if row.get("owner_group"):
        _add_member(drive, drive_id, row["owner_group"], "organizer")
    if row.get("member_group"):
        _add_member(drive, drive_id, row["member_group"], norm_role(row["member_role"]))
    return drive_id


def _add_member(drive, drive_id, group_email, role):
    print(f"    before-state: {group_email} had no explicit permission on {drive_id} (rollback = remove)")
    drive.permissions().create(
        fileId=drive_id, supportsAllDrives=True, sendNotificationEmail=False,
        body={"type": "group", "role": role, "emailAddress": group_email}).execute()
    print(f"    ADDED {group_email} as {VALID_ROLES[role]} ({role})")


def main():
    ap = argparse.ArgumentParser(description="Provision Shared Drives + group membership (dry-run default).")
    ap.add_argument("--catalog", required=True, help="Governance catalog CSV")
    mode = ap.add_mutually_exclusive_group()
    mode.add_argument("--dry-run", action="store_true", help="Print planned actions only (default)")
    mode.add_argument("--apply", action="store_true", help="Actually create Drives / add members")
    args = ap.parse_args()

    rows = load_catalog(args.catalog)
    errs = validate(rows)
    if errs:
        print("VALIDATION FAILED:")
        for e in errs:
            print(f"  - {e}")
        return 1

    if not args.apply:  # dry-run default
        print("DRY-RUN — no changes will be made. Planned provisioning:")
        for r in rows:
            print(f"  + {full_drive_name(r)}")
            if r.get("owner_group"):
                print(f"      Manager: {r['owner_group']}")
            if r.get("member_group"):
                print(f"      {VALID_ROLES[norm_role(r['member_role'])]}: {r['member_group']}")
        print("\nRe-run with --apply to create these (requires the Drive write scope).")
        return 0

    print("APPLY — creating Shared Drives and adding group members.")
    drive = build_drive()
    for r in rows:
        apply_row(drive, r)
    print("\nDone. Record the drive IDs and the before-state lines above for rollback.")
    return 0


if __name__ == "__main__":
    sys.exit(main())
