#!/usr/bin/env python3
# catalog_config_helper.py — append a correctly-shaped app row to the catalog + emit its checklist
#
# PURPOSE: Keep `App Catalog - Federated SaaS - v1` consistent: validate the catalog's schema, and add
#          a new app as a correctly-shaped row (with the standard assignment-group name and NameID),
#          emitting the onboarding checklist reference. DRY-RUN by default — it prints the proposed row
#          and writes to the catalog CSV only when --apply is passed.
# HOW TO RUN: python catalog_config_helper.py --catalog catalog.csv --new-app "Zoom" --type saml \
#               --owner jane@corp.example --provisioning scim [--cert-expiry 2027-01-15] [--apply]
#             (Python 3.10+; local file tool — no Google auth required. See --help.)
# EXPECTED RESULTS: The proposed catalog row printed and validated; with --apply the row is appended
#          (a .bak backup of the catalog is written first). Refuses duplicates. Exit 0 on success.
#
# Catalog schema (created if the file does not exist):
#   app,type,name_id,assignment_target,assignment_group,provisioning,owner,cert_expiry,status
#
# SAFETY: dry-run default; --apply writes ONLY the local catalog CSV (after a .bak backup). No Google
#         API calls, no credentials, no secrets. Tenant configuration is never changed by this tool.

import argparse
import csv
import datetime as dt
import os
import shutil
import sys

FIELDS = ["app", "type", "name_id", "assignment_target", "assignment_group",
          "provisioning", "owner", "cert_expiry", "status"]
STANDARD_NAMEID = "Basic Information > Primary email"
VALID_TYPES = {"saml", "oidc"}
VALID_PROVISIONING = {"auto", "scim", "jit", "manual"}


def assignment_group_name(app):
    return f"Assignment Group - {app} - Users"


def read_catalog(path):
    if not os.path.exists(path):
        return []
    with open(path, newline="", encoding="utf-8") as fh:
        return [dict(r) for r in csv.DictReader(fh)]


def validate_new(app, app_type, provisioning, cert_expiry):
    errs = []
    if not app.strip():
        errs.append("--new-app is required")
    if app_type not in VALID_TYPES:
        errs.append(f"--type must be one of {sorted(VALID_TYPES)}")
    if provisioning not in VALID_PROVISIONING:
        errs.append(f"--provisioning must be one of {sorted(VALID_PROVISIONING)}")
    if cert_expiry:
        try:
            dt.date.fromisoformat(cert_expiry)
        except ValueError:
            errs.append("--cert-expiry must be ISO YYYY-MM-DD")
    return errs


def build_row(args):
    return {
        "app": args.new_app.strip(),
        "type": args.type,
        "name_id": STANDARD_NAMEID,
        "assignment_target": "group",
        "assignment_group": assignment_group_name(args.new_app.strip()),
        "provisioning": args.provisioning,
        "owner": (args.owner or "").strip(),
        "cert_expiry": (args.cert_expiry or "").strip(),
        "status": "onboarding",
    }


def write_catalog(path, rows):
    if os.path.exists(path):
        shutil.copyfile(path, path + ".bak")
    with open(path, "w", newline="", encoding="utf-8") as fh:
        writer = csv.DictWriter(fh, fieldnames=FIELDS)
        writer.writeheader()
        for r in rows:
            writer.writerow({k: r.get(k, "") for k in FIELDS})


def main(argv=None):
    ap = argparse.ArgumentParser(description="Append a standardized app row to the catalog (dry-run).")
    ap.add_argument("--catalog", required=True, help="path to the app catalog CSV (created if absent)")
    ap.add_argument("--new-app", required=True, help="app display name to add")
    ap.add_argument("--type", choices=sorted(VALID_TYPES), default="saml")
    ap.add_argument("--provisioning", choices=sorted(VALID_PROVISIONING), default="manual")
    ap.add_argument("--owner", help="business owner (email)")
    ap.add_argument("--cert-expiry", help="Google IdP signing cert expiry, ISO YYYY-MM-DD")
    ap.add_argument("--apply", action="store_true", help="write the row to the catalog (after .bak)")
    args = ap.parse_args(argv)

    errs = validate_new(args.new_app, args.type, args.provisioning, args.cert_expiry)
    if errs:
        for e in errs:
            print(f"[x] {e}", file=sys.stderr)
        return 2

    existing = read_catalog(args.catalog)
    names = {(r.get("app") or "").strip().lower() for r in existing}
    if args.new_app.strip().lower() in names:
        print(f"[x] '{args.new_app}' is already in the catalog — refusing to duplicate.",
              file=sys.stderr)
        return 2

    row = build_row(args)
    print("\nProposed catalog row (App Catalog - Federated SaaS - v1):\n" + "-" * 60)
    for k in FIELDS:
        print(f"  {k:<18}: {row[k] or '(blank)'}")
    print("-" * 60)
    print("Onboarding: run `SSO Onboarding Pattern - SaaS - v1` "
          f"(see saml_app_onboarding_helper.py --app \"{row['app']}\" --type {row['type']}).")
    if row["provisioning"] == "manual":
        print("[note] provisioning=manual -> add this app to the leaver offboarding checklist.")
    if not row["cert_expiry"]:
        print("[note] no cert_expiry set -> record it once the app is created so rotation is tracked.")

    if not args.apply:
        print("\n[dry-run] Catalog NOT modified. Re-run with --apply to append this row.")
        return 0

    write_catalog(args.catalog, existing + [row])
    print(f"\n[applied] appended '{row['app']}' to {args.catalog} "
          f"(backup at {args.catalog}.bak). Tenant unchanged.")
    return 0


if __name__ == "__main__":
    sys.exit(main())
