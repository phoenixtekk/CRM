# Best Practices

Durable practices for running FinOps on Google Cloud after the initial rollout. These keep the
model accurate, keep spend owned, and keep the optimization loop turning.

## Make the BigQuery export the single source of truth

- **Query the detailed export, not the console screenshots.** The console cost report is for quick
  looks; every number that goes into showback, chargeback, or a savings decision should trace to a
  BigQuery query on `FinOps – Billing Export – Prod`.
- **Never change the export dataset's location or delete its table.** Location is fixed at creation
  and the export is not retroactive — losing the table loses history you cannot rebuild.
- **Version your attribution SQL.** Keep the `FinOps – Attribution Views – v1` SQL in source control
  so a view change is reviewed and reproducible (`finops-report.py --emit-views` regenerates it).

## Treat labeling as the foundation of attribution

- **Attribution quality == labeling coverage.** Track "unattributed %" as a first-class KPI and drive
  it down; an attribution model on top of poor labels is precision on top of noise.
- **Enforce labels at creation.** Prefer org policy / Terraform defaults so new projects and resources
  are labeled with `cost-center`, `team`, `environment`, and `app` from day one, rather than chasing
  labels after the fact.
- **Remember relabeling is not retroactive.** The export reflects labels going forward; fix the label
  now, but historical rows keep the label they were exported with.

## Design budgets to inform, not to block

- **Budgets alert; they do not cap.** A Cloud Billing budget does not stop spend — it notifies. Use
  it as an early-warning system, and if hard enforcement is needed, wire the Pub/Sub alert to your own
  automation deliberately (and carefully — capping can break production).
- **Always include a forecasted-spend rule.** A forecast threshold warns you *before* actual spend
  crosses the line, which is the whole point of a budget.
- **Scope budgets to owners.** Per-folder, per-project, or per-label budgets put the alert in front of
  the team that can act, instead of a single org budget that pages everyone and no one.

## Keep the tooling safe-by-default

- **Read-only and dry-run first.** Run discovery, reporting, savings analysis, and guardrail checks
  freely (they never change anything). The provisioner only writes with `--apply` — review the
  dry-run plan every time.
- **Use ADC / the environment for auth — never keys in code.** Authenticate with
  `gcloud auth application-default login` or a workload-identity/attached service account. Do not
  create, download, or commit service-account keys, and never put a billing account id or secret in a
  script.
- **Grant least privilege.** `roles/billing.viewer` + `roles/recommender.viewer` are enough for the
  read-only tools; only budget provisioning needs `costsManager`/`billing.admin`. Don't run FinOps
  tooling as Owner.

## Keep optimization a governed loop, not a one-off

- **Rightsizing/idle first, commitments second.** Act on idle and oversized resources (reversible)
  before buying commitments (not reversible for the term).
- **CUD purchases are money movement — human-approved, never automated.** The analyzer *identifies*
  commitment opportunities and their estimated savings; the purchase decision belongs to finance/FinOps
  under change control. Model the commitment against a stable baseline, not a spike.
- **Re-run the savings analysis on a cadence.** New workloads create new waste; a monthly savings
  review keeps the `FinOps – Savings Backlog – v1` current and owned.

## Run FinOps as an operating rhythm

- **Monthly showback, monthly savings review, alert triage as it fires.** Put these on the named
  FinOps owner's calendar. FinOps decays without a rhythm.
- **Reconcile periodically.** Spot-check that the dashboard/showback totals reconcile to the console
  cost report for the same period, accounting for credit and export timing.
- **Extend the same discipline to Workspace and Gemini licensing.** Once GCP spend is attributed by
  owner, bring subscription/licensing cost into the same showback so total Google spend — not just
  infrastructure — has an owner.

## Respect the boundaries

- **Defer financial and contractual decisions to finance/FinOps.** You provide the technical method
  and the evidence (attribution, budgets, savings); chargeback policy and commitment purchases are
  business decisions.
- **Flag preview/version-dependent surfaces.** Recommender IDs, export schema fields, and budget API
  fields evolve — verify them against current Google Cloud documentation for your organization rather
  than assuming this document's exact strings persist.
