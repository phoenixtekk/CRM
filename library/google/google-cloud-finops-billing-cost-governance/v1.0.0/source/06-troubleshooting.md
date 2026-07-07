# Troubleshooting

Common failure modes when standing up and running FinOps on Google Cloud, with the resolution for
each. Artifact names match those created in Implementation.

## The billing export table never appears in BigQuery

- **Symptoms:** `bq ls "$FINOPS_PROJECT:$DATASET"` shows no `gcp_billing_export_*` table hours after
  enabling export; T2 fails.
- **Causes & fixes:**
  - **Export was not actually saved.** Re-open **Billing → Billing export → BigQuery export**,
    confirm **Detailed usage cost** shows the `finops-billing-prod` project and `finops_billing_export`
    dataset, and **Save** again.
  - **Not enough time.** The first export table can take **up to ~24 hours** to appear and populate.
    Wait, then recheck. Export is **not retroactive** — no historical rows appear.
  - **Dataset in an incompatible location / project not billing-linked.** Confirm the dataset exists
    (`bq ls`) and the FinOps project is linked to a billing account.
  - **Permissions.** Enabling export requires billing-admin on the billing account; confirm with
    `gcloud billing accounts get-iam-policy "$BILLING"`.

## Attribution views error or totals do not reconcile

- **Symptoms:** T4 fails — a view errors, or the view total diverges materially from the console cost
  report.
- **Causes & fixes:**
  - **Wrong export table name.** The views wildcard `gcp_billing_export_resource_v1_*`. If you enabled
    only the **standard** (non-resource) export, the table is `gcp_billing_export_v1_*` — adjust the
    view SQL (edit `EXPORT_TBL` in `finops-report.py`) and re-run `--emit-views --apply`.
  - **Credits/rounding/timing.** Console reports and the export can differ slightly by credit
    application and export lag; reconcile on a **closed** invoice month, not the in-progress one.
  - **Views not created.** Run `python finops-report.py --project "$FINOPS_PROJECT" --dataset "$DATASET"
    --emit-views --apply` and confirm with `bq ls`.

## Unattributed spend is high

- **Symptoms:** T5 reports unattributed % above target; showback has a large "unattributed" bucket.
- **Cause:** projects/resources lack the `team`/`cost-center` labels.
- **Fix:** query `v_unattributed_spend` (ORDER BY cost DESC) for the biggest offenders, apply the
  labels (`gcloud projects update PROJECT_ID --update-labels team=...,cost-center=...`), and enforce
  labels at creation (org policy / Terraform default). Remember relabeling is **not retroactive** —
  the number improves from the next export forward, not historically.

## Budget alerts do not fire

- **Symptoms:** T6 proof alert never arrives by email or Pub/Sub.
- **Causes & fixes:**
  - **No notification target.** `finops-guardrail-check.py` reports "a budget has a notification
    target" as FAIL. Add email recipients (by billing role or explicit) and/or set the Pub/Sub topic
    on the budget (`finops-budget-provisioner.py ... --pubsub-topic FinOps-Budget-Alerts-Prod --apply`).
  - **Pub/Sub publish permission missing.** The **Cloud Billing budget service agent** must hold
    `roles/pubsub.publisher` on `FinOps-Budget-Alerts-Prod`. Grant it (see the Cloud Billing
    budgets-notifications docs for the exact service-agent principal).
  - **Threshold not crossed / forecast only.** Actual-spend alerts fire only when spend crosses the
    percent; for early warning add a **forecasted-spend** rule (`--forecast-threshold`).
  - **Budgets alert, they do not cap.** If you expected spend to *stop*, that is by design — a budget
    never blocks spend.

## Budget provisioner: "PERMISSION_DENIED" or nothing happens

- **Symptoms:** `finops-budget-provisioner.py --apply` errors with permission denied, or the dry-run
  printed a command but nothing was created.
- **Causes & fixes:**
  - **Missing role.** Budget create/delete needs `roles/billing.admin` or `roles/billing.costsManager`
    on the billing account. Grant it and retry.
  - **You did not pass `--apply`.** By design the tool is dry-run and prints the command it *would*
    run; add `--apply` to execute.
  - **Notify project not set.** If using `--pubsub-topic`, also pass `--notify-project` so the topic
    path resolves.

## Savings analyzer returns nothing or a permission error

- **Symptoms:** T7 — `finops-savings-analyzer.py` prints "(skip)" lines or an empty backlog.
- **Causes & fixes:**
  - **Recommender API disabled.** `gcloud services enable recommender.googleapis.com --project PROJECT`.
  - **Missing role.** Grant `roles/recommender.viewer` (or the specific recommender viewer role).
  - **Wrong location.** Rightsizing/idle recommenders are **regional/zonal** — pass the actual
    `--regions` where the VMs run; a project with no matching resources legitimately returns nothing.
  - **Recommender ID changed.** Recommender IDs are **version-dependent**; verify the current IDs in
    the Google Cloud Recommender docs and pass them via `--recommenders`.

## Guardrail check fails in CI but the console looks fine

- **Symptoms:** `finops-guardrail-check.py` exits non-zero though the console appears healthy.
- **Causes & fixes:**
  - **Export freshness window.** The check counts rows in the last 48h; a delayed export can trip it.
    Confirm with T2's freshness query; if export genuinely lags, treat it as a real export issue.
  - **Views listed via an unavailable surface.** The check falls back to `bq ls`; ensure `bq` is on
    PATH and the dataset is readable.
  - **Unattributed above `--max-unattributed`.** This is a *real* governance failure, not a tooling
    bug — remediate labeling and re-run.

## Authentication / ADC problems

- **Symptoms:** any tool errors with default-credentials-not-found or 401/403.
- **Fix:** authenticate with `gcloud auth login` and, for the Cloud Client Libraries path,
  `gcloud auth application-default login`. **Never** create or commit a service-account key to work
  around this — use ADC or an attached/workload-identity service account, and confirm the principal
  holds the least-privilege roles the Requirements list.
