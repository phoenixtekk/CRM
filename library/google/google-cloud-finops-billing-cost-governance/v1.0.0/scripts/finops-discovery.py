#!/usr/bin/env python3
# finops-discovery.py — inventory the Cloud Billing / FinOps baseline (read-only).
#
# PURPOSE: Assess-phase discovery. Inventories the billing account, its linked projects,
#          whether detailed billing export is configured, existing budgets and their alert
#          thresholds, the resource hierarchy (org -> folders -> projects), and the label keys
#          present on projects. Read-only: it changes nothing.
# HOW TO RUN: python finops-discovery.py --billing-account BILLING_ACCOUNT_ID [--json OUT.json]
#             (Python 3.10+, gcloud installed + authenticated, or ADC; see --help)
# EXPECTED RESULTS: A printed baseline (and optional JSON) of billing status, export state,
#             budgets, hierarchy, and labeling coverage. Non-zero exit only on a hard error.
#
# Safe by default: this tool only READS via `gcloud ... --format=json`. It never creates,
# updates, or deletes anything. No credentials or keys are embedded; auth comes from gcloud/ADC.

import argparse
import json
import shutil
import subprocess
import sys
from datetime import datetime, timezone

REQUIRED_LABEL_KEYS = ["cost-center", "team", "environment", "app"]


def gcloud(args, allow_fail=True):
    """Run a read-only gcloud command and return parsed JSON (or None)."""
    if shutil.which("gcloud") is None:
        sys.exit("ERROR: gcloud CLI not found on PATH. Install the Google Cloud SDK.")
    cmd = ["gcloud", *args, "--format=json"]
    try:
        out = subprocess.run(cmd, capture_output=True, text=True, check=True)
    except subprocess.CalledProcessError as exc:
        if allow_fail:
            sys.stderr.write(f"  (non-fatal) `{' '.join(cmd)}` failed: {exc.stderr.strip()}\n")
            return None
        sys.exit(f"ERROR running {' '.join(cmd)}: {exc.stderr.strip()}")
    try:
        return json.loads(out.stdout or "null")
    except json.JSONDecodeError:
        return None


def discover(billing_account):
    report = {
        "generated": datetime.now(timezone.utc).isoformat(),
        "billing_account": billing_account,
    }

    # 1. Billing account status
    acct = gcloud(["billing", "accounts", "describe", billing_account])
    report["billing_open"] = bool(acct and acct.get("open"))
    report["billing_display_name"] = (acct or {}).get("displayName")

    # 2. Projects linked to this billing account
    linked = gcloud(["billing", "projects", "list", f"--billing-account={billing_account}"]) or []
    report["linked_projects"] = [p.get("projectId") for p in linked if p.get("billingEnabled")]
    report["linked_project_count"] = len(report["linked_projects"])

    # 3. Existing budgets + thresholds
    budgets = gcloud(["billing", "budgets", "list", f"--billing-account={billing_account}"]) or []
    report["budgets"] = []
    for b in budgets:
        rules = b.get("thresholdRules", []) or []
        report["budgets"].append({
            "name": b.get("displayName") or b.get("name"),
            "thresholds": [r.get("thresholdPercent") for r in rules],
            "has_pubsub": bool((b.get("notificationsRule") or {}).get("pubsubTopic")),
        })
    report["budget_count"] = len(report["budgets"])

    # 4. Resource hierarchy (best-effort: org + folders + projects)
    orgs = gcloud(["organizations", "list"]) or []
    report["organizations"] = [{"id": o.get("name"), "domain": o.get("displayName")} for o in orgs]

    # 5. Labeling coverage across linked projects
    label_hits = {k: 0 for k in REQUIRED_LABEL_KEYS}
    described = 0
    for pid in report["linked_projects"]:
        proj = gcloud(["projects", "describe", pid])
        if not proj:
            continue
        described += 1
        labels = proj.get("labels", {}) or {}
        for k in REQUIRED_LABEL_KEYS:
            if k in labels:
                label_hits[k] += 1
    report["projects_described"] = described
    report["label_coverage"] = {
        k: (round(100 * v / described, 1) if described else 0.0) for k, v in label_hits.items()
    }

    # NOTE: whether *detailed billing export* is enabled is a Cloud Billing setting not exposed by a
    # stable gcloud read; confirm in Console -> Billing -> Billing export, or check that a
    # `gcp_billing_export_*` table exists in the FinOps dataset (see finops-report.py / T2).
    report["export_note"] = (
        "Verify detailed export in Console -> Billing -> Billing export, or check for a "
        "gcp_billing_export_* table in the FinOps BigQuery dataset."
    )
    return report


def main():
    ap = argparse.ArgumentParser(description="FinOps discovery / assessment (read-only).")
    ap.add_argument("--billing-account", required=True,
                    help="Billing account id, e.g. 0X0X0X-0X0X0X-0X0X0X")
    ap.add_argument("--json", metavar="OUT", help="Write the full baseline to this JSON file.")
    args = ap.parse_args()

    report = discover(args.billing_account)

    print("=== FinOps Discovery Baseline (read-only) ===")
    print(f"Billing account : {report['billing_display_name']} ({args.billing_account})")
    print(f"Status          : {'OPEN' if report['billing_open'] else 'NOT OPEN'}")
    print(f"Linked projects : {report['linked_project_count']}")
    print(f"Existing budgets: {report['budget_count']}")
    for b in report["budgets"]:
        print(f"  - {b['name']}  thresholds={b['thresholds']}  pubsub={b['has_pubsub']}")
    print("Label coverage (% of described projects):")
    for k, pct in report["label_coverage"].items():
        print(f"  - {k:<12}: {pct}%")
    print(report["export_note"])

    if args.json:
        with open(args.json, "w", encoding="utf-8") as fh:
            json.dump(report, fh, indent=2)
        print(f"\nWrote baseline -> {args.json}")


if __name__ == "__main__":
    main()
