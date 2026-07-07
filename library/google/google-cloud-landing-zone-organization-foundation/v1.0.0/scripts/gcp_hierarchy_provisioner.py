#!/usr/bin/env python3
# gcp_hierarchy_provisioner.py — create the landing-zone folder/project hierarchy from a plan.
#
# PURPOSE: Read a hierarchy plan (folders + foundation projects) and provision it via gcloud,
#          linking billing. DRY-RUN BY DEFAULT — prints the plan and changes NOTHING unless
#          --apply is passed. Writes a change log so a rollback owner has the prior state.
# HOW TO RUN: python gcp_hierarchy_provisioner.py --organization ORG_ID
#             --billing-account ACCT [--plan hierarchy-plan.json] [--apply]
#             (Python 3.10+, gcloud authenticated / ADC; see --help)
# EXPECTED RESULTS: Dry-run: an ordered list of the create/link actions. --apply: each action
#          executed, with a change-log JSON recording what was created for rollback.

import argparse
import json
import shutil
import subprocess
import sys
from datetime import datetime, timezone

# Default plan mirrors the Overview reference design. Names use "<Purpose> - <Scope> - <Stage>";
# project IDs are the lowercase/hyphen form gcloud requires.
DEFAULT_PLAN = {
    "folders": ["Common", "Production", "Non-Production", "Bootstrap"],
    "projects": [
        {"name": "Logging - Common - Prod", "id": "logging-common-prod", "folder": "Common"},
        {"name": "Billing-Export - Common - Prod", "id": "billing-export-common-prod",
         "folder": "Common"},
        {"name": "Networking-Host - Shared-VPC - Prod", "id": "networking-host-shared-vpc-prod",
         "folder": "Common"},
        {"name": "Bootstrap - Seed - Prod", "id": "bootstrap-seed-prod", "folder": "Bootstrap"},
    ],
}


def gcloud_bin():
    g = shutil.which("gcloud")
    if not g:
        sys.exit("ERROR: gcloud CLI not found on PATH. Install the Google Cloud SDK first.")
    return g


def run(args, apply):
    """Print the action; execute only when apply=True. Returns stdout (or '' in dry-run)."""
    printable = "gcloud " + " ".join(args)
    if not apply:
        print(f"  [DRY-RUN] {printable}")
        return ""
    print(f"  [APPLY]   {printable}")
    res = subprocess.run([gcloud_bin()] + args, capture_output=True, text=True)
    if res.returncode != 0:
        print(f"    ERROR: {res.stderr.strip()}", file=sys.stderr)
        raise SystemExit(f"Aborting: command failed -> {printable}")
    return res.stdout.strip()


def load_plan(path):
    if not path:
        return DEFAULT_PLAN
    with open(path, encoding="utf-8") as fh:
        return json.load(fh)


def existing_folder_id(org_id, display_name):
    g = gcloud_bin()
    res = subprocess.run(
        [g, "resource-manager", "folders", "list", f"--organization={org_id}",
         f"--filter=displayName={display_name}", "--format=value(name)"],
        capture_output=True, text=True)
    out = res.stdout.strip()
    return out.split("/")[-1] if out else None


def main():
    ap = argparse.ArgumentParser(
        description="Provision the landing-zone hierarchy (dry-run by default).")
    ap.add_argument("--organization", required=True, help="Numeric Organization ID.")
    ap.add_argument("--billing-account", required=True,
                    help="Billing account ID (XXXXXX-XXXXXX-XXXXXX).")
    ap.add_argument("--plan", help="Path to a hierarchy plan JSON (defaults to the reference design).")
    ap.add_argument("--apply", action="store_true",
                    help="Actually create resources. Omit for a safe dry-run.")
    ap.add_argument("--change-log", default="hierarchy-change-log.json",
                    help="Where to record what was created (for rollback).")
    args = ap.parse_args()

    plan = load_plan(args.plan)
    mode = "APPLY" if args.apply else "DRY-RUN"
    print(f"== Hierarchy provisioner ({mode}) — org {args.organization} ==\n")

    change_log = {"generated": datetime.now(timezone.utc).isoformat(),
                  "organization": args.organization, "created_folders": [],
                  "created_projects": []}
    folder_ids = {}

    print("Folders:")
    for name in plan["folders"]:
        existing = existing_folder_id(args.organization, name) if args.apply else None
        if existing:
            print(f"  [SKIP]    folder '{name}' already exists ({existing})")
            folder_ids[name] = existing
            continue
        run(["resource-manager", "folders", "create", f"--display-name={name}",
             f"--organization={args.organization}"], args.apply)
        if args.apply:
            fid = existing_folder_id(args.organization, name)
            folder_ids[name] = fid
            change_log["created_folders"].append({"name": name, "id": fid})

    print("\nProjects:")
    for proj in plan["projects"]:
        parent = folder_ids.get(proj["folder"], f"<{proj['folder']}-folder-id>")
        run(["projects", "create", proj["id"],
             f"--name={proj['name']}", f"--folder={parent}"], args.apply)
        run(["billing", "projects", "link", proj["id"],
             f"--billing-account={args.billing_account}"], args.apply)
        if args.apply:
            change_log["created_projects"].append(proj)

    if args.apply:
        with open(args.change_log, "w", encoding="utf-8") as fh:
            json.dump(change_log, fh, indent=2)
        print(f"\nChange log written to {args.change_log} (use for rollback).")
    else:
        print("\nDry-run complete. Re-run with --apply to create these resources.")


if __name__ == "__main__":
    main()
