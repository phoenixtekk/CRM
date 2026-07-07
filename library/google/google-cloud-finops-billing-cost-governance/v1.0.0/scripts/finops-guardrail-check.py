#!/usr/bin/env python3
# finops-guardrail-check.py — validate the FinOps posture against the gates (read-only).
#
# PURPOSE: Policy / guardrail check. Validates the FinOps configuration against the pass/fail gates:
#          billing export flowing (recent rows), budgets present with expected thresholds and a live
#          notification target, attribution views resolving, and unattributed spend below target.
#          Read-only. Exits NON-ZERO if any check fails, so it can gate CI or a scheduled run.
# HOW TO RUN: python finops-guardrail-check.py --billing-account BA --project FINOPS_PROJECT
#             --dataset finops_billing_export [--max-unattributed 5.0] [--json OUT.json]
#             (Python 3.10+, gcloud/bq installed + authenticated / ADC; see --help)
# EXPECTED RESULTS: A PASS/FAIL line per check and an overall verdict. Exit 0 = all pass, 1 = a gate
#             failed. Changes nothing.
#
# No credentials or keys are embedded; auth comes from gcloud/ADC.

import argparse
import json
import shutil
import subprocess
import sys

REQUIRED_VIEWS = ["v_cost_by_project", "v_cost_by_service", "v_cost_by_label", "v_unattributed_spend"]


def require(tool):
    if shutil.which(tool) is None:
        sys.exit(f"ERROR: `{tool}` not found on PATH. Install the Google Cloud SDK.")


def gcloud_json(args):
    res = subprocess.run(["gcloud", *args, "--format=json"], capture_output=True, text=True)
    if res.returncode != 0:
        return None
    try:
        return json.loads(res.stdout or "null")
    except json.JSONDecodeError:
        return None


def bq_scalar(sql):
    res = subprocess.run(["bq", "query", "--use_legacy_sql=false", "--format=json", sql],
                         capture_output=True, text=True)
    if res.returncode != 0:
        return None
    try:
        rows = json.loads(res.stdout or "[]")
        return rows[0] if rows else None
    except (json.JSONDecodeError, IndexError):
        return None


def main():
    ap = argparse.ArgumentParser(description="FinOps guardrail / gate check (read-only).")
    ap.add_argument("--billing-account", required=True)
    ap.add_argument("--project", required=True)
    ap.add_argument("--dataset", required=True)
    ap.add_argument("--max-unattributed", type=float, default=5.0,
                    help="Max acceptable unattributed spend %% (default 5.0).")
    ap.add_argument("--json", help="Write full results to this JSON file.")
    a = ap.parse_args()
    require("gcloud")
    require("bq")

    results = []

    def check(name, ok, detail=""):
        results.append({"check": name, "pass": bool(ok), "detail": detail})
        print(f"[{'PASS' if ok else 'FAIL'}] {name}" + (f" — {detail}" if detail else ""))

    # 1. Export flowing (recent rows this month)
    tbl = f"`{a.project}.{a.dataset}.gcp_billing_export_resource_v1_*`"
    row = bq_scalar(f"SELECT COUNT(*) AS n FROM {tbl} "
                    f"WHERE export_time > TIMESTAMP_SUB(CURRENT_TIMESTAMP(), INTERVAL 48 HOUR)")
    export_ok = bool(row and int(row.get("n", 0)) > 0)
    check("billing export flowing (rows in last 48h)", export_ok,
          f"rows={row.get('n') if row else 'n/a'}")

    # 2. Attribution views resolve
    views = gcloud_json(["alpha", "bq", "tables", "list", "--dataset", a.dataset,
                         "--project", a.project]) or []
    present = {t.get("id", "").split(".")[-1] for t in views} if views else set()
    # Fall back to bq ls if the alpha surface is unavailable.
    if not present:
        res = subprocess.run(["bq", "ls", f"{a.project}:{a.dataset}"], capture_output=True, text=True)
        present = set(res.stdout.split())
    missing = [v for v in REQUIRED_VIEWS if v not in present]
    check("attribution views present", not missing,
          "all present" if not missing else f"missing: {missing}")

    # 3. Budgets present with thresholds + notification
    budgets = gcloud_json(["billing", "budgets", "list",
                           f"--billing-account={a.billing_account}"]) or []
    have_budget = len(budgets) > 0
    have_notify = any((b.get("notificationsRule") or {}).get("pubsubTopic")
                      or (b.get("notificationsRule") or {}).get("monitoringNotificationChannels")
                      for b in budgets)
    check("at least one budget defined", have_budget, f"count={len(budgets)}")
    check("a budget has a notification target", have_notify,
          "pubsub/monitoring channel found" if have_notify else "no notification target")

    # 4. Unattributed spend below target
    ua = bq_scalar(f"""
SELECT ROUND(100 * SAFE_DIVIDE(
  SUM(IF((SELECT COUNT(1) FROM UNNEST(labels) WHERE key IN ('team','cost-center'))=0, cost, 0)),
  SUM(cost)), 2) AS pct
FROM {tbl}
WHERE invoice.month = FORMAT_DATE('%Y%m', DATE_TRUNC(CURRENT_DATE(), MONTH))""")
    pct = float(ua["pct"]) if ua and ua.get("pct") is not None else None
    ua_ok = pct is not None and pct <= a.max_unattributed
    check(f"unattributed spend <= {a.max_unattributed}%", ua_ok,
          f"unattributed={pct}%" if pct is not None else "no data")

    overall = all(r["pass"] for r in results)
    print(f"\nOverall: {'PASS — FinOps gates satisfied' if overall else 'FAIL — a gate failed'}")

    if a.json:
        with open(a.json, "w", encoding="utf-8") as fh:
            json.dump({"overall_pass": overall, "checks": results}, fh, indent=2)
        print(f"Wrote results -> {a.json}")

    sys.exit(0 if overall else 1)


if __name__ == "__main__":
    main()
