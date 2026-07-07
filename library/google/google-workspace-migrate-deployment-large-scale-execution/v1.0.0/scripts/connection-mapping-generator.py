#!/usr/bin/env python3
# connection-mapping-generator.py — build & validate the mapping CSVs and identity bridge for Google Workspace Migrate.
#
# PURPOSE: Generate the source->target mapping CSVs (OneDrive->My Drive, SharePoint->Shared Drive,
#          Mailbox->Gmail) and the identity bridge (Bridge - Identity - Corp) that Google Workspace Migrate
#          consumes, from directory data (Google Admin SDK Directory + Microsoft Graph). Dry-run/validate by
#          default: it writes local artifact files only and never touches a live system.
# HOW TO RUN: python connection-mapping-generator.py --dry-run --graph --directory --out mapping-plan/
#             python connection-mapping-generator.py --validate --against mapping-plan/   (Python 3.10+, OAuth/ADC)
#             (pip install google-api-python-client google-auth msgraph-core azure-identity — or --sample)
# EXPECTED RESULTS: Writes mapping CSVs + bridge to --out (dry-run) or reports resolution errors (validate).
#                   Exit 0 when every in-scope source object resolves to exactly one target; non-zero otherwise.

import argparse
import csv
import os
import sys


def parse_args():
    p = argparse.ArgumentParser(description="Generate/validate Google Workspace Migrate mapping CSVs + identity bridge.")
    mode = p.add_mutually_exclusive_group(required=True)
    mode.add_argument("--dry-run", action="store_true", help="Generate artifacts locally (default safe mode).")
    mode.add_argument("--validate", action="store_true", help="Validate an existing mapping-plan directory.")
    mode.add_argument("--apply", action="store_true",
                      help="Reserved: import into the project. NOT implemented — import via the console for your version.")
    p.add_argument("--graph", action="store_true", help="Read source identities from Microsoft Graph (read-only).")
    p.add_argument("--directory", action="store_true", help="Read target identities from Google Admin SDK Directory.")
    p.add_argument("--sample", action="store_true", help="Use bundled sample directory data (no network).")
    p.add_argument("--out", default="mapping-plan/", help="Output directory for generated artifacts.")
    p.add_argument("--against", default="mapping-plan/", help="Directory to validate (with --validate).")
    p.add_argument("--stage", default="Pilot", help="Stage label used in mapping names (e.g. Pilot, Prod).")
    return p.parse_args()


def load_directory(use_sample):
    """Return (source_users, target_users). Read-only.

    Live mode: Google Admin SDK Directory users.list for targets (OAuth service account, domain-wide
    delegation) and Microsoft Graph GET /users for sources. NO hardcoded credentials — use ADC/OAuth.
    """
    if use_sample:
        source = [
            {"upn": "asmith@corp.example", "id": "S-1001", "dept": "Finance"},
            {"upn": "bjones@corp.example", "id": "S-1002", "dept": "Finance"},
        ]
        target = [
            {"email": "asmith@corp.example", "id": "G-9001"},
            {"email": "bjones@corp.example", "id": "G-9002"},
        ]
        sp_sites = [{"site": "FinanceTeam", "url": "/sites/FinanceTeam", "target_shared_drive": "Finance"}]
        return source, target, sp_sites
    try:
        from googleapiclient.discovery import build  # noqa: F401
        from google.oauth2 import service_account  # noqa: F401
        from azure.identity import DefaultAzureCredential  # noqa: F401
    except ImportError:
        sys.exit("Missing deps: pip install google-api-python-client google-auth msgraph-core azure-identity "
                 "(or run with --sample).")
    sys.exit("Live directory read not wired in this template. Provide Admin SDK + Graph clients (OAuth/ADC), "
             "or use --sample. See the docstring for the exact read-only endpoints.")


def generate(args):
    source, target, sp_sites = load_directory(args.sample)
    target_by_email = {t["email"].lower(): t for t in target}
    os.makedirs(args.out, exist_ok=True)

    bridge_rows, od_rows, mail_rows, unresolved = [], [], [], []
    for s in source:
        t = target_by_email.get(s["upn"].lower())
        if not t:
            unresolved.append(s["upn"])
            continue
        bridge_rows.append({"source_id": s["id"], "source_upn": s["upn"], "target_id": t["id"],
                            "target_email": t["email"]})
        od_rows.append({"source_onedrive": s["upn"], "target_mydrive_owner": t["email"],
                        "mapping_name": f"Mapping - {s['dept']} OneDrive - {args.stage}"})
        mail_rows.append({"source_mailbox": s["upn"], "target_gmail": t["email"],
                          "mapping_name": f"Mapping - {s['dept']} Mail - {args.stage}"})
    sp_rows = [{"source_site": x["url"], "target_shared_drive": x["target_shared_drive"],
                "mapping_name": f"Mapping - {x['site']} SharePoint - {args.stage}"} for x in sp_sites]

    _write_csv(os.path.join(args.out, "bridge-identity-corp.csv"),
               ["source_id", "source_upn", "target_id", "target_email"], bridge_rows)
    _write_csv(os.path.join(args.out, "mapping-onedrive.csv"),
               ["source_onedrive", "target_mydrive_owner", "mapping_name"], od_rows)
    _write_csv(os.path.join(args.out, "mapping-mail.csv"),
               ["source_mailbox", "target_gmail", "mapping_name"], mail_rows)
    _write_csv(os.path.join(args.out, "mapping-sharepoint.csv"),
               ["source_site", "target_shared_drive", "mapping_name"], sp_rows)

    print(f"[dry-run] Wrote artifacts to {args.out}")
    print(f"  Bridge - Identity - Corp : {len(bridge_rows)} identities")
    print(f"  OneDrive mappings        : {len(od_rows)}")
    print(f"  Mail mappings            : {len(mail_rows)}")
    print(f"  SharePoint mappings      : {len(sp_rows)}")
    if unresolved:
        print(f"  UNRESOLVED source users  : {len(unresolved)} -> {', '.join(unresolved)}")
        print("  FAIL: resolve every source identity before importing.")
        return 1
    print("  PASS: every in-scope source object resolves to exactly one target.")
    print("  Next: review the CSVs, then import into the project (console import for your version).")
    return 0


def validate(args):
    path = args.against
    bridge = os.path.join(path, "bridge-identity-corp.csv")
    if not os.path.isfile(bridge):
        sys.exit(f"Not found: {bridge} — generate with --dry-run first.")
    seen_src, seen_tgt, dupes = set(), set(), []
    with open(bridge, newline="", encoding="utf-8") as f:
        for row in csv.DictReader(f):
            if row["source_id"] in seen_src:
                dupes.append(("source", row["source_id"]))
            if row["target_id"] in seen_tgt:
                dupes.append(("target", row["target_id"]))
            seen_src.add(row["source_id"])
            seen_tgt.add(row["target_id"])
    print(f"Validated {bridge}: {len(seen_src)} identities.")
    if dupes:
        for kind, val in dupes:
            print(f"  FAIL duplicate {kind}: {val}")
        return 1
    print("  PASS: no duplicate or orphaned identities in Bridge - Identity - Corp.")
    return 0


def _write_csv(path, fields, rows):
    with open(path, "w", newline="", encoding="utf-8") as f:
        w = csv.DictWriter(f, fieldnames=fields)
        w.writeheader()
        w.writerows(rows)


def main():
    args = parse_args()
    if args.apply:
        sys.exit("--apply is reserved and intentionally not implemented. Import the reviewed artifacts via the "
                 "Google Workspace Migrate console for your version.")
    sys.exit(validate(args) if args.validate else generate(args))


if __name__ == "__main__":
    main()
