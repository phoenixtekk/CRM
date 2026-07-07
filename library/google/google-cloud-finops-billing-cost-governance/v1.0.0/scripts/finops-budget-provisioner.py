#!/usr/bin/env python3
# finops-budget-provisioner.py — create/delete Cloud Billing budgets + alerts (dry-run by default).
#
# PURPOSE: Configuration helper. Provisions a Cloud Billing budget with alert threshold rules and a
#          Pub/Sub (and/or email) notification target, scoped to specific projects, a label, or all
#          projects. SAFE DEFAULT: prints the plan and changes NOTHING unless --apply is passed.
#          --delete removes only the named budget (also dry-run unless --apply).
# HOW TO RUN: python finops-budget-provisioner.py --billing-account BA --name "FinOps – Budget – Pilot – v1"
#             --amount 5000 --thresholds 0.5,0.9,1.0 [--scope-all-projects | --scope-projects a,b |
#             --filter-label team=payments] [--pubsub-topic T] [--apply]
#             (Python 3.10+, gcloud installed + authenticated / ADC; see --help)
# EXPECTED RESULTS: Dry-run prints the exact gcloud command it WOULD run. With --apply it creates
#             (or deletes) the budget and prints the result. Requires roles/billing.admin or
#             roles/billing.costsManager on the billing account.
#
# No credentials or keys are embedded; auth comes from gcloud/ADC. Budgets ALERT, they do not cap
# spend — this tool never modifies a resource, only the budget object.

import argparse
import shutil
import subprocess
import sys


def require_gcloud():
    if shutil.which("gcloud") is None:
        sys.exit("ERROR: gcloud CLI not found on PATH. Install the Google Cloud SDK.")


def run(cmd, apply):
    printable = " ".join(f'"{c}"' if " " in c else c for c in cmd)
    if not apply:
        print("DRY-RUN — would run:")
        print(f"  {printable}")
        print("Re-run with --apply to execute.")
        return 0
    print(f"APPLY — running:\n  {printable}")
    try:
        res = subprocess.run(cmd, capture_output=True, text=True, check=True)
        print(res.stdout.strip() or "OK")
        return 0
    except subprocess.CalledProcessError as exc:
        sys.stderr.write(exc.stderr or "")
        return exc.returncode or 1


def build_create_cmd(a):
    thresholds = [t.strip() for t in a.thresholds.split(",") if t.strip()]
    cmd = [
        "gcloud", "billing", "budgets", "create",
        f"--billing-account={a.billing_account}",
        f"--display-name={a.name}",
        f"--budget-amount={a.amount}{a.currency}",
    ]
    for t in thresholds:
        cmd.append(f"--threshold-rule=percent={t}")
    if a.forecast_threshold:
        cmd.append(f"--threshold-rule=percent={a.forecast_threshold},basis=forecasted-spend")
    # Scope
    if a.scope_projects:
        for pid in a.scope_projects.split(","):
            cmd.append(f"--filter-projects=projects/{pid.strip()}")
    if a.filter_label:
        cmd.append(f"--filter-labels={a.filter_label}")
    # else: no project/label filter => applies to all projects on the billing account
    if a.pubsub_topic:
        cmd.append(f"--all-updates-rule-pubsub-topic="
                   f"projects/{a.notify_project or 'PROJECT'}/topics/{a.pubsub_topic}")
    return cmd


def find_budget_name(a):
    """Resolve the internal budget resource name from its display name (read-only)."""
    import json
    out = subprocess.run(
        ["gcloud", "billing", "budgets", "list",
         f"--billing-account={a.billing_account}", "--format=json"],
        capture_output=True, text=True)
    try:
        for b in json.loads(out.stdout or "[]"):
            if (b.get("displayName") or "") == a.name:
                return b.get("name")
    except json.JSONDecodeError:
        pass
    return None


def main():
    ap = argparse.ArgumentParser(description="Provision Cloud Billing budgets + alerts (dry-run default).")
    ap.add_argument("--billing-account", required=True)
    ap.add_argument("--name", required=True, help="Budget display name, e.g. 'FinOps – Budget – Pilot – v1'")
    ap.add_argument("--amount", help="Budget amount (number), required for create.")
    ap.add_argument("--currency", default="USD")
    ap.add_argument("--thresholds", default="0.5,0.9,1.0",
                    help="Comma list of actual-spend percents, e.g. 0.5,0.9,1.0")
    ap.add_argument("--forecast-threshold", help="Optional forecasted-spend percent, e.g. 1.0")
    scope = ap.add_mutually_exclusive_group()
    scope.add_argument("--scope-all-projects", action="store_true",
                       help="Budget covers all projects on the billing account (no filter).")
    scope.add_argument("--scope-projects", help="Comma list of project ids to scope the budget to.")
    ap.add_argument("--filter-label", help="Label filter, e.g. team=payments")
    ap.add_argument("--pubsub-topic", help="Pub/Sub topic short name for programmatic alerts.")
    ap.add_argument("--notify-project", help="Project that hosts the Pub/Sub topic.")
    ap.add_argument("--delete", action="store_true", help="Delete the named budget instead of creating.")
    ap.add_argument("--apply", action="store_true", help="Execute (otherwise dry-run).")
    a = ap.parse_args()

    require_gcloud()

    if a.delete:
        resource = find_budget_name(a)
        if not resource:
            sys.exit(f"No budget found with display name '{a.name}' — nothing to delete.")
        cmd = ["gcloud", "billing", "budgets", "delete", resource,
               f"--billing-account={a.billing_account}", "--quiet"]
        return sys.exit(run(cmd, a.apply))

    if not a.amount:
        sys.exit("ERROR: --amount is required for create.")
    if not (a.scope_all_projects or a.scope_projects or a.filter_label):
        sys.exit("ERROR: choose a scope: --scope-all-projects, --scope-projects, or --filter-label.")
    cmd = build_create_cmd(a)
    sys.exit(run(cmd, a.apply))


if __name__ == "__main__":
    main()
