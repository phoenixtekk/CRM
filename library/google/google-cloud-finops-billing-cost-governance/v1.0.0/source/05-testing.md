# Testing & Validation

Each procedure states what to run, the expected result, and the explicit **PASS/FAIL** signal. Run
the pilot tests (T1–T6) before expanding org-wide; re-run T2–T8 after Expand. The artifact names are
the same ones created in Implementation.

## T1 — Billing account and access

- **Run:** `gcloud billing accounts describe "$BILLING"` and
  `gcloud billing accounts get-iam-policy "$BILLING"`.
- **Expected:** the account shows `open: true`; the operator principal holds `roles/billing.admin`
  (or `costsManager` + `viewer`).
- **PASS:** account OPEN and operator authorized. **FAIL:** account closed or operator lacks billing
  role — resolve access before any other test.

## T2 — Detailed billing export is flowing

- **Run:** `bq ls "$FINOPS_PROJECT:$DATASET"` then a freshness query:
  ```
  bq query --use_legacy_sql=false \
  'SELECT MAX(export_time) AS last_export, COUNT(*) AS rows_24h
   FROM `finops-billing-prod.finops_billing_export.gcp_billing_export_resource_v1_*`
   WHERE export_time > TIMESTAMP_SUB(CURRENT_TIMESTAMP(), INTERVAL 24 HOUR)'
  ```
- **Expected:** a `gcp_billing_export_*` table exists and `rows_24h > 0` with a recent `last_export`.
- **PASS:** recent rows present. **FAIL:** no table or no recent rows — export is not enabled or is
  still initializing (allow up to ~24h after first enablement); see Troubleshooting.

## T3 — Discovery baseline matches reality

- **Run:** `python finops-discovery.py --billing-account "$BILLING" --json baseline.json`.
- **Expected:** the tool reports the billing status, the export as configured, existing budgets, the
  hierarchy, and label keys — matching what the console shows.
- **PASS:** report reconciles with the console (billing export = configured, budgets listed).
  **FAIL:** discrepancies — investigate before trusting downstream tools.

## T4 — Attribution views resolve and cost rolls up

- **Run:** query the cost-by-project and cost-by-label views for the last full month, e.g.
  ```
  bq query --use_legacy_sql=false \
  'SELECT * FROM `finops-billing-prod.finops_billing_export.v_cost_by_project`
   ORDER BY cost DESC LIMIT 20'
  ```
- **Expected:** cost aggregates per project and per label key; the total reconciles (within
  credit/rounding timing) to the console cost report for the same period.
- **PASS:** views return data and totals reconcile. **FAIL:** views error or totals diverge materially
  — re-emit views with `finops-report.py --emit-views --apply` and recheck the export table name.

## T5 — Unattributed spend is measured and within target

- **Run:** `python finops-report.py --project "$FINOPS_PROJECT" --dataset "$DATASET" --unattributed`.
- **Expected:** a single "unattributed %" figure plus the top unattributed projects/services.
- **PASS:** unattributed % <= the target set in Design (e.g. <= 5%). **FAIL:** above target — drive
  labeling remediation on the listed projects, then re-run.

## T6 — Pilot budget exists and alerts correctly

- **Run:** `python finops-guardrail-check.py --billing-account "$BILLING" --project "$FINOPS_PROJECT"
  --dataset "$DATASET" --json pilot-guardrail.json`, then perform the safe proof-alert (temporarily
  lower `FinOps – Budget – Pilot – v1` so the 50% threshold fires; confirm email/Pub/Sub receipt;
  restore the amount with `--apply`).
- **Expected:** the guardrail check reports the pilot budget present with the expected thresholds and a
  live notification target; the proof alert is received.
- **PASS:** budget present, thresholds correct, alert delivered, amount restored. **FAIL:** budget
  missing, wrong thresholds, or no alert delivered — see Troubleshooting (notification path).

## T7 — Savings analysis is read-only and produces a backlog

- **Run:** `python finops-savings-analyzer.py --projects PILOT_PROJECT_1 --regions REGION
  --json pilot-savings.json`.
- **Expected:** a backlog of rightsizing/idle/CUD recommendations with estimated monthly savings and
  an owner per item; the tool makes **no changes** (read-only).
- **PASS:** backlog produced, nothing modified. **FAIL:** permission error (grant
  `roles/recommender.viewer` / enable `recommender.googleapis.com`) or the tool attempts a write
  (it must not).

## T8 — Guardrail check passes org-wide (post-Expand)

- **Run:** `python finops-guardrail-check.py --billing-account "$BILLING" --project "$FINOPS_PROJECT"
  --dataset "$DATASET" --scope org --json org-guardrail.json`.
- **Expected:** export flowing, org budgets (`FinOps – Budget – Org – v1`) present with correct
  thresholds and notification, attribution views resolve, org-wide unattributed % <= target.
- **PASS:** every check green. **FAIL:** any check red — the org is not fully governed; remediate the
  failing check and re-run before declaring the rollout complete.

## T9 — Rollback is clean

- **Run:** on a throwaway test budget, `python finops-budget-provisioner.py --delete --name
  "FinOps – Budget – Test – v1" --billing-account "$BILLING" --apply`, then confirm it is gone with
  `gcloud billing budgets list --billing-account "$BILLING"`.
- **Expected:** only the named budget is removed; no other budget, view, or resource is touched; no
  spend changes.
- **PASS:** targeted budget deleted, everything else intact. **FAIL:** wrong budget removed or a view
  disappeared — restore from `finops-report.py --emit-views` and review the provisioner invocation.
