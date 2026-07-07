#!/usr/bin/env python3
# drive_governance_config_helper.py — build/validate the Shared Drives governance catalog (local only)
#
# PURPOSE: Keep the governance catalog consistent with the taxonomy/naming/role model: validate the
#          catalog's schema and the "<Domain> – <Team> – <Purpose>" naming + role rules, and add a new
#          Shared Drive as a correctly-shaped row (group-based membership, least-privilege role, a named
#          owner group). DRY-RUN by default — it prints the proposed row and writes to the local catalog
#          CSV only when --apply is passed. It makes NO Google API calls and changes NO tenant setting.
# HOW TO RUN: python drive_governance_config_helper.py --catalog drive-catalog.csv \
#               --new-drive "AP Records" --domain Finance \
#               --owner-group grp-finance-drive-owners@corp.example \
#               --member-group grp-finance-ap@corp.example --member-role contributor \
#               [--allowed-domains "acmelegal.example;partner.example"] [--apply]
#             (Python 3.10+; LOCAL FILE TOOL — no Google auth required. See --help.)
# EXPECTED RESULTS: The proposed catalog row printed and validated against the naming/role model; with
#          --apply the row is appended (a .bak backup is written first). Refuses duplicates and invalid
#          roles/members. Exit 0 on success, non-zero on validation failure.
#
# SAFETY: dry-run default; --apply writes ONLY the local catalog CSV (after a .bak backup). No Google API
#         calls, no credentials, no secrets. The tenant is never touched by this helper.

import argparse
import csv
import os
import shutil
import sys

FIELDS = ["drive_name", "domain", "owner_group", "member_group", "member_role", "allowed_domains"]
ROLES = {"organizer": "Manager", "fileOrganizer": "Content manager", "writer": "Contributor",
         "commenter": "Commenter", "reader": "Viewer"}
FRIENDLY = {v.lower(): k for k, v in ROLES.items()}


def read_catalog(path):
    if not os.path.exists(path):
        return []
    with open(path, newline="", encoding="utf-8") as fh:
        return [dict(r) for r in csv.DictReader(fh)]


def norm_role(role):
    role = (role or "").strip().lower()
    if role in ROLES:
        return role
    return FRIENDLY.get(role)


def validate(new, existing):
    errs = []
    if not new["drive_name"].strip():
        errs.append("--new-drive is required")
    if not new["domain"].strip():
        errs.append("--domain is required (top-level taxonomy domain)")
    if norm_role(new["member_role"]) is None:
        errs.append(f"--member-role must be one of {sorted(ROLES) + sorted(FRIENDLY)}")
    for key in ("owner_group", "member_group"):
        val = new[key].strip()
        if not val:
            errs.append(f"--{key.replace('_', '-')} is required (membership must be group-based)")
        elif "@" not in val:
            errs.append(f"--{key.replace('_', '-')} '{val}' must be a GROUP email, not a user")
    # Least-privilege guard: warn if a member group is given Manager (should be the owner group only).
    if norm_role(new["member_role"]) == "organizer":
        errs.append("member_role 'Manager' is reserved for the owner group; pick a lesser role for members")
    # Duplicate check on the full composed name.
    full = compose_name(new)
    if any(compose_name(r) == full for r in existing):
        errs.append(f"duplicate: '{full}' already exists in the catalog")
    return errs


def compose_name(row):
    return f"Shared Drive – {row['domain'].strip()} – {row['drive_name'].strip()}"


def main():
    ap = argparse.ArgumentParser(description="Validate/append a governed Shared Drive row (local only).")
    ap.add_argument("--catalog", required=True, help="Catalog CSV (created if absent)")
    ap.add_argument("--new-drive", required=True, help="Purpose part of the name, e.g. 'AP Records'")
    ap.add_argument("--domain", required=True, help="Taxonomy domain, e.g. Finance")
    ap.add_argument("--owner-group", required=True, help="Manager group email (grp-...-drive-owners@...)")
    ap.add_argument("--member-group", required=True, help="Member group email (grp-...@...)")
    ap.add_argument("--member-role", required=True, help="Contributor/Viewer/Commenter/Content manager")
    ap.add_argument("--allowed-domains", default="", help="';'-separated partner domains for this Drive")
    mode = ap.add_mutually_exclusive_group()
    mode.add_argument("--dry-run", action="store_true", help="Print the proposed row only (default)")
    mode.add_argument("--apply", action="store_true", help="Append the row to the catalog")
    args = ap.parse_args()

    new = {"drive_name": args.new_drive, "domain": args.domain,
           "owner_group": args.owner_group, "member_group": args.member_group,
           "member_role": args.member_role, "allowed_domains": args.allowed_domains}
    existing = read_catalog(args.catalog)
    errs = validate(new, existing)

    full = compose_name(new)
    print(f"Proposed Shared Drive: {full}")
    print(f"  Manager (owner) group: {new['owner_group']}")
    print(f"  Member group / role  : {new['member_group']} / {ROLES[norm_role(new['member_role'])]}")
    print(f"  Allowed partner domains: {new['allowed_domains'] or '(internal-only)'}")

    if errs:
        print("\nVALIDATION FAILED:")
        for e in errs:
            print(f"  - {e}")
        return 1

    if not args.apply:  # dry-run default
        print("\nDRY-RUN — valid. Re-run with --apply to append this row to the catalog.")
        return 0

    row = dict(new)
    row["member_role"] = norm_role(new["member_role"])
    write_header = not os.path.exists(args.catalog)
    if not write_header:
        shutil.copy2(args.catalog, args.catalog + ".bak")
        print(f"  backup written: {args.catalog}.bak")
    with open(args.catalog, "a", newline="", encoding="utf-8") as fh:
        w = csv.DictWriter(fh, fieldnames=FIELDS)
        if write_header:
            w.writeheader()
        w.writerow(row)
    print(f"  APPENDED to {args.catalog}")
    return 0


if __name__ == "__main__":
    sys.exit(main())
