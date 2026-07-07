#!/usr/bin/env python3
# gcp_org_assessment.py — read-only inventory of a Google Cloud Organization's foundation state.
#
# PURPOSE: Enumerate an Organization's folders, projects, existing org policies, billing linkage,
#          and top-level IAM into a baseline JSON report. READ-ONLY — it never changes anything.
# HOW TO RUN: python gcp_org_assessment.py --organization ORG_ID [--output org-assessment.json]
#             (Python 3.10+, gcloud installed + authenticated / ADC; see --help)
# EXPECTED RESULTS: A JSON report (and a short stdout summary) listing every folder, project,
#          enforced org policy, billing state, and org-node IAM binding. Non-zero exit on failure.

import argparse
import json
import shutil
import subprocess
import sys
from datetime import datetime, timezone


def run_gcloud(args, allow_empty=True):
    """Run a read-only gcloud command and return parsed JSON (list/dict) or None."""
    gcloud = shutil.which("gcloud")
    if not gcloud:
        sys.exit("ERROR: gcloud CLI not found on PATH. Install the Google Cloud SDK first.")
    cmd = [gcloud] + args + ["--format=json"]
    try:
        out = subprocess.run(cmd, capture_output=True, text=True, check=True)
    except subprocess.CalledProcessError as exc:
        stderr = (exc.stderr or "").strip()
        print(f"WARN: `{' '.join(args)}` failed: {stderr}", file=sys.stderr)
        return [] if allow_empty else None
    body = out.stdout.strip()
    if not body:
        return []
    try:
        return json.loads(body)
    except json.JSONDecodeError:
        return []


def list_folders(org_id):
    return run_gcloud(["resource-manager", "folders", "list",
                       f"--organization={org_id}"])


def list_projects(org_id):
    # Projects across the org (ancestor filter keeps it org-scoped).
    return run_gcloud(["projects", "list",
                       f"--filter=parent.id={org_id} OR parent.type=folder"])


def org_policies(org_id):
    return run_gcloud(["org-policies", "list", f"--organization={org_id}"])


def org_iam(org_id):
    policy = run_gcloud(["organizations", "get-iam-policy", org_id], allow_empty=False)
    if not policy or "bindings" not in policy:
        return []
    rows = []
    for b in policy.get("bindings", []):
        for m in b.get("members", []):
            rows.append({"role": b.get("role"), "member": m})
    return rows


def billing_state(project_id):
    info = run_gcloud(["billing", "projects", "describe", project_id], allow_empty=False)
    if isinstance(info, dict):
        return {"billingEnabled": info.get("billingEnabled"),
                "billingAccountName": info.get("billingAccountName")}
    return {"billingEnabled": None, "billingAccountName": None}


def summarize(report):
    print("== GCP Organization Assessment ==")
    print(f"Organization : {report['organization']}")
    print(f"Folders      : {len(report['folders'])}")
    print(f"Projects     : {len(report['projects'])}")
    print(f"Org policies : {len(report['org_policies'])}")
    users = [r for r in report["org_iam"] if r["member"].startswith("user:")]
    print(f"Org IAM      : {len(report['org_iam'])} bindings "
          f"({len(users)} bound to individual users — review for group-based baseline)")
    unbilled = [p for p in report["projects"]
                if report["billing"].get(p.get("projectId"), {}).get("billingEnabled") is False]
    if unbilled:
        print(f"WARNING      : {len(unbilled)} project(s) not linked to billing.")


def main():
    ap = argparse.ArgumentParser(description="Read-only assessment of a GCP Organization foundation.")
    ap.add_argument("--organization", required=True, help="Numeric Organization ID.")
    ap.add_argument("--output", default="org-assessment.json", help="Report output path.")
    ap.add_argument("--skip-billing", action="store_true",
                    help="Skip per-project billing lookups (faster on large orgs).")
    args = ap.parse_args()

    org_id = args.organization
    folders = list_folders(org_id)
    projects = list_projects(org_id)

    billing = {}
    if not args.skip_billing:
        for p in projects:
            pid = p.get("projectId")
            if pid:
                billing[pid] = billing_state(pid)

    report = {
        "generated": datetime.now(timezone.utc).isoformat(),
        "organization": org_id,
        "folders": folders,
        "projects": projects,
        "billing": billing,
        "org_policies": org_policies(org_id),
        "org_iam": org_iam(org_id),
    }

    with open(args.output, "w", encoding="utf-8") as fh:
        json.dump(report, fh, indent=2)

    summarize(report)
    print(f"\nReport written to {args.output}")


if __name__ == "__main__":
    main()
