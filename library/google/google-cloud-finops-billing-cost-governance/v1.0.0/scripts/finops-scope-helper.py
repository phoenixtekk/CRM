#!/usr/bin/env python3
# finops-scope-helper.py — resolve & validate the FinOps scope into a reusable config (read-only).
#
# PURPOSE: Scope / config helper. Resolves and validates the FinOps scope once — the billing account,
#          the export project/dataset, the pilot vs. org project sets (from the resource hierarchy or
#          an explicit list), and the required label keys — and writes a normalized finops-scope.json
#          the other tools consume, so the scope is defined once and used consistently. Read-only.
# HOW TO RUN: python finops-scope-helper.py --billing-account BA --finops-project finops-billing-prod
#             --dataset finops_billing_export [--pilot-folder FOLDER_ID | --pilot-projects a,b]
#             [--out finops-scope.json]
#             (Python 3.10+, gcloud installed + authenticated / ADC; see --help)
# EXPECTED RESULTS: A validated scope printed and written to finops-scope.json, plus warnings for any
#             element that could not be confirmed (e.g. project not linked, folder empty). Non-zero
#             exit only on a hard validation failure. Changes nothing.
#
# No credentials or keys are embedded; auth comes from gcloud/ADC.

import argparse
import json
import shutil
import subprocess
import sys
from datetime import datetime, timezone

REQUIRED_LABEL_KEYS = ["cost-center", "team", "environment", "app"]


def gcloud_json(args):
    if shutil.which("gcloud") is None:
        sys.exit("ERROR: gcloud CLI not found on PATH. Install the Google Cloud SDK.")
    res = subprocess.run(["gcloud", *args, "--format=json"], capture_output=True, text=True)
    if res.returncode != 0:
        return None
    try:
        return json.loads(res.stdout or "null")
    except json.JSONDecodeError:
        return None


def projects_in_folder(folder_id):
    data = gcloud_json(["projects", "list", f"--filter=parent.id={folder_id}"]) or []
    return [p.get("projectId") for p in data]


def main():
    ap = argparse.ArgumentParser(description="Resolve & validate the FinOps scope (read-only).")
    ap.add_argument("--billing-account", required=True)
    ap.add_argument("--finops-project", required=True, help="Project hosting the export dataset.")
    ap.add_argument("--dataset", required=True, help="BigQuery dataset id for the billing export.")
    pilot = ap.add_mutually_exclusive_group()
    pilot.add_argument("--pilot-folder", help="Folder id whose projects form the pilot scope.")
    pilot.add_argument("--pilot-projects", help="Comma list of project ids for the pilot scope.")
    ap.add_argument("--label-keys", help="Override required label keys (comma list).")
    ap.add_argument("--out", default="finops-scope.json", help="Output scope file.")
    a = ap.parse_args()

    warnings = []

    # Validate billing account
    acct = gcloud_json(["billing", "accounts", "describe", a.billing_account])
    if not acct:
        sys.exit(f"ERROR: cannot describe billing account {a.billing_account} (access/typo?).")
    if not acct.get("open"):
        warnings.append("Billing account is not OPEN.")

    # Validate FinOps project is linked to the billing account
    binfo = gcloud_json(["billing", "projects", "describe", a.finops_project])
    if not binfo or not binfo.get("billingEnabled"):
        warnings.append(f"FinOps project {a.finops_project} is not linked to a billing account.")

    # Resolve pilot scope
    if a.pilot_folder:
        pilot_projects = projects_in_folder(a.pilot_folder)
        if not pilot_projects:
            warnings.append(f"Pilot folder {a.pilot_folder} contains no visible projects.")
    elif a.pilot_projects:
        pilot_projects = [p.strip() for p in a.pilot_projects.split(",") if p.strip()]
    else:
        pilot_projects = []
        warnings.append("No pilot scope provided (--pilot-folder or --pilot-projects).")

    # Org project set = all projects linked to the billing account
    linked = gcloud_json(["billing", "projects", "list",
                          f"--billing-account={a.billing_account}"]) or []
    org_projects = [p.get("projectId") for p in linked if p.get("billingEnabled")]

    label_keys = ([k.strip() for k in a.label_keys.split(",")]
                  if a.label_keys else REQUIRED_LABEL_KEYS)

    scope = {
        "generated": datetime.now(timezone.utc).isoformat(),
        "billing_account": a.billing_account,
        "finops_project": a.finops_project,
        "dataset": a.dataset,
        "export_table_wildcard":
            f"{a.finops_project}.{a.dataset}.gcp_billing_export_resource_v1_*",
        "pilot_projects": pilot_projects,
        "org_projects": org_projects,
        "required_label_keys": label_keys,
        "warnings": warnings,
    }

    print("=== FinOps scope (validated, read-only) ===")
    print(f"Billing account : {a.billing_account} ({'OPEN' if acct.get('open') else 'NOT OPEN'})")
    print(f"FinOps project  : {a.finops_project}   dataset: {a.dataset}")
    print(f"Pilot projects  : {pilot_projects or '(none)'}")
    print(f"Org projects    : {len(org_projects)} linked")
    print(f"Label keys      : {label_keys}")
    if warnings:
        print("Warnings:")
        for w in warnings:
            print(f"  ! {w}")

    with open(a.out, "w", encoding="utf-8") as fh:
        json.dump(scope, fh, indent=2)
    print(f"\nWrote scope -> {a.out}")

    # Hard-fail only if the essentials are unusable.
    if not acct or not org_projects:
        sys.exit(1)


if __name__ == "__main__":
    main()
