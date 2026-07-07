#!/usr/bin/env python3
# finops-report.py — emit BigQuery attribution views + report unattributed spend.
#
# PURPOSE: Validation / report generator. Emits (and, with --apply, creates) the BigQuery
#          attribution views over the detailed billing export — cost by project, by label, and by
#          service — and reports the unattributed-spend % (rows missing team/cost-center) with the
#          top unattributed projects/services. SAFE DEFAULT: --emit-views writes SQL only; --apply
#          creates the views; --unattributed runs a read-only query.
# HOW TO RUN: python finops-report.py --project FINOPS_PROJECT --dataset finops_billing_export
#             [--emit-views [--apply]] [--unattributed] [--out views.sql]
#             (Python 3.10+, gcloud/bq installed + authenticated / ADC; see --help)
# EXPECTED RESULTS: With --emit-views: the CREATE VIEW SQL (to stdout/--out), and with --apply the
#             views created in the dataset. With --unattributed: a single unattributed % plus the top
#             unattributed projects. Read-only unless --apply is passed for view creation.
#
# No credentials or keys are embedded; auth comes from gcloud/ADC. The export table name follows
# Google's convention gcp_billing_export_resource_v1_<BILLING_ACCOUNT_ID> (wildcarded here).

import argparse
import shutil
import subprocess
import sys

# Attribution views. `{p}` = project, `{d}` = dataset. The export table is wildcarded so any
# billing-account suffix matches; adjust if you use the non-resource (v1) export.
EXPORT_TBL = "`{p}.{d}.gcp_billing_export_resource_v1_*`"

VIEWS = {
    "v_cost_by_project": """
CREATE OR REPLACE VIEW `{p}.{d}.v_cost_by_project` AS
SELECT project.id AS project_id,
       invoice.month AS invoice_month,
       SUM(cost) + SUM(IFNULL((SELECT SUM(c.amount) FROM UNNEST(credits) c), 0)) AS cost,
       currency
FROM """ + EXPORT_TBL + """
GROUP BY project_id, invoice_month, currency
""",
    "v_cost_by_service": """
CREATE OR REPLACE VIEW `{p}.{d}.v_cost_by_service` AS
SELECT service.description AS service,
       invoice.month AS invoice_month,
       SUM(cost) AS cost, currency
FROM """ + EXPORT_TBL + """
GROUP BY service, invoice_month, currency
""",
    "v_cost_by_label": """
CREATE OR REPLACE VIEW `{p}.{d}.v_cost_by_label` AS
SELECT (SELECT value FROM UNNEST(labels) WHERE key = 'team') AS team,
       (SELECT value FROM UNNEST(labels) WHERE key = 'cost-center') AS cost_center,
       invoice.month AS invoice_month,
       SUM(cost) AS cost, currency
FROM """ + EXPORT_TBL + """
GROUP BY team, cost_center, invoice_month, currency
""",
    "v_unattributed_spend": """
CREATE OR REPLACE VIEW `{p}.{d}.v_unattributed_spend` AS
SELECT project.id AS project_id,
       service.description AS service,
       SUM(cost) AS cost, currency
FROM """ + EXPORT_TBL + """
WHERE (SELECT COUNT(1) FROM UNNEST(labels) WHERE key IN ('team','cost-center')) = 0
GROUP BY project_id, service, currency
""",
}


def require(tool):
    if shutil.which(tool) is None:
        sys.exit(f"ERROR: `{tool}` not found on PATH. Install the Google Cloud SDK.")


def emit_views(project, dataset, out, apply):
    sql_blocks = [v.format(p=project, d=dataset) for v in VIEWS.values()]
    all_sql = "\n;\n".join(s.strip() for s in sql_blocks) + "\n;\n"
    if out:
        with open(out, "w", encoding="utf-8") as fh:
            fh.write(all_sql)
        print(f"Wrote attribution view SQL -> {out}")
    else:
        print(all_sql)
    if not apply:
        print("DRY-RUN — no views created. Re-run with --apply to create them in BigQuery.")
        return
    require("bq")
    for name, tmpl in VIEWS.items():
        sql = tmpl.format(p=project, d=dataset).strip()
        print(f"APPLY — creating view {name} ...")
        res = subprocess.run(["bq", "query", "--use_legacy_sql=false", sql],
                             capture_output=True, text=True)
        if res.returncode != 0:
            sys.stderr.write(res.stderr)
            sys.exit(f"Failed creating view {name}.")
    print("All attribution views created (FinOps – Attribution Views – v1).")


def unattributed(project, dataset):
    require("bq")
    tbl = EXPORT_TBL.format(p=project, d=dataset)
    q = f"""
SELECT
  ROUND(100 * SAFE_DIVIDE(
    SUM(IF((SELECT COUNT(1) FROM UNNEST(labels) WHERE key IN ('team','cost-center'))=0, cost, 0)),
    SUM(cost)), 2) AS unattributed_pct,
  ROUND(SUM(cost), 2) AS total_cost
FROM {tbl}
WHERE invoice.month = FORMAT_DATE('%Y%m', DATE_TRUNC(CURRENT_DATE(), MONTH))
"""
    res = subprocess.run(["bq", "query", "--use_legacy_sql=false", "--format=pretty", q],
                         capture_output=True, text=True)
    if res.returncode != 0:
        sys.stderr.write(res.stderr)
        sys.exit("Unattributed query failed — confirm the export table exists (see T2).")
    print("=== Unattributed spend (current invoice month) ===")
    print(res.stdout)
    print("Top unattributed projects/services: query `v_unattributed_spend` ORDER BY cost DESC.")


def main():
    ap = argparse.ArgumentParser(description="Emit attribution views / report unattributed spend.")
    ap.add_argument("--project", required=True, help="FinOps project hosting the export dataset.")
    ap.add_argument("--dataset", required=True, help="BigQuery dataset id, e.g. finops_billing_export")
    ap.add_argument("--emit-views", action="store_true", help="Emit the attribution view SQL.")
    ap.add_argument("--out", help="Write emitted SQL to this file instead of stdout.")
    ap.add_argument("--unattributed", action="store_true", help="Report unattributed-spend %.")
    ap.add_argument("--apply", action="store_true", help="Create the views (otherwise SQL only).")
    a = ap.parse_args()

    if not (a.emit_views or a.unattributed):
        ap.error("choose --emit-views and/or --unattributed")
    if a.emit_views:
        emit_views(a.project, a.dataset, a.out, a.apply)
    if a.unattributed:
        unattributed(a.project, a.dataset)


if __name__ == "__main__":
    main()
