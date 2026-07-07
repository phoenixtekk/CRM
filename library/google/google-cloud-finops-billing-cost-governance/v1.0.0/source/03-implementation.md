# Implementation

Follow the house model — **Assess → Design → Configure → Pilot → Validate → Expand** — pilot-first,
with explicit pass/fail gates and a documented rollback for every org-wide change. Every artifact is
named with the `<Purpose> – <Scope> – <Stage>` convention and that exact name is reused in testing,
troubleshooting, and the scripts.

Artifacts created in this solution (names are reused verbatim later):

| Artifact | Name |
| --- | --- |
| FinOps host project | `finops-billing-prod` |
| Billing export dataset | `FinOps – Billing Export – Prod` (BigQuery dataset id `finops_billing_export`) |
| Attribution views | `FinOps – Attribution Views – v1` |
| Pilot budget | `FinOps – Budget – Pilot – v1` |
| Org-wide budgets | `FinOps – Budget – Org – v1` |
| Budget alert topic | `FinOps – Budget Alerts – Prod` (Pub/Sub `FinOps-Budget-Alerts-Prod`) |
| Savings backlog | `FinOps – Savings Backlog – v1` |
| Showback dashboard | `FinOps – Showback – v1` |
| Pilot scope | `FinOps – Pilot – v1` |

> Set once and reuse in every command below:
> `BILLING=<BILLING_ACCOUNT_ID>` · `FINOPS_PROJECT=finops-billing-prod` ·
> `DATASET=finops_billing_export`.

---

## Phase 1 — Assess (read-only)

1. **Inventory the billing baseline.** Run the discovery tool to capture the current state without
   changing anything:
   ```
   python finops-discovery.py --billing-account "$BILLING" --json baseline.json
   ```
   It reports: billing account status and linked projects, whether a detailed export is already
   configured, existing budgets and their thresholds, the resource hierarchy (org → folders →
   projects), and the labeling keys present on projects. This is the **Assess evidence**.

2. **Review labeling coverage and hierarchy.** Confirm the required label keys (`cost-center`,
   `team`, `environment`, `app`) exist on projects and note the gaps. Confirm the folder structure
   the org will attribute along.

3. **Record what already exists.** Note any pre-existing export or budgets so Configure is additive
   and idempotent — never delete an existing budget you did not create.

**Assess gate:** you have a written baseline (billing status, export state, existing budgets,
hierarchy, labeling coverage). Do not proceed until the baseline is captured.

---

## Phase 2 — Design

4. **Design the attribution model.** Decide the roll-ups: by `project.id`, by folder (resource
   ancestry), and by each label key. Decide how "unattributed" is defined (missing `team` or
   `cost-center`). Record the target coverage (e.g. >= 95% of spend attributable).

5. **Design the budget policy.** For the pilot and then the org: which scope gets a budget (all
   projects, a folder, a label, a service), the monthly amount or a last-period-based amount, and the
   alert thresholds (e.g. **50%, 90%, 100% of actual**, plus a **forecasted-spend** rule). Decide
   notification: email recipients and/or the `FinOps – Budget Alerts – Prod` Pub/Sub topic.

6. **Design the showback cadence.** Who receives the showback report, at what interval (e.g. monthly),
   and in what form (BigQuery table + Looker Studio dashboard `FinOps – Showback – v1`).

**Design gate:** attribution model, budget policy, and showback cadence are written down and approved
by the FinOps owner and finance stakeholder.

---

## Phase 3 — Configure

### 3a. Enable detailed billing export to BigQuery

7. **Create the FinOps project and dataset** (if not already present from Requirements):
   ```
   gcloud projects create "$FINOPS_PROJECT"
   gcloud billing projects link "$FINOPS_PROJECT" --billing-account "$BILLING"
   gcloud services enable bigquery.googleapis.com --project "$FINOPS_PROJECT"
   bq --location=US mk --dataset "$FINOPS_PROJECT:$DATASET"
   ```
   Choose the dataset location per the org's data-residency policy — **it cannot be changed later.**

8. **Enable the detailed usage cost export.** In the Cloud Console go to **Billing → Billing export
   → BigQuery export**, and under **Detailed usage cost** click **Edit settings**, select the
   `finops-billing-prod` project and the `finops_billing_export` dataset, and **Save**. (Enabling
   billing export is a console/API action on the billing account; confirm the exact panel labels in
   the current Cloud Billing documentation for your organization — the export type names are
   version-stable but the panel layout evolves.)
   - Optionally also enable **Pricing** export into the same dataset for unit-price analysis.
   - Export is **not retroactive** — data accrues from enablement forward. The
     `gcp_billing_export_resource_v1_<BILLING_ACCOUNT_ID>` table appears within a few hours and
     populates over the next day.

9. **Confirm the export table appears:**
   ```
   bq ls "$FINOPS_PROJECT:$DATASET"
   ```
   Wait until a `gcp_billing_export_*` table exists and has rows before building views.

### 3b. Build attribution views

10. **Create the attribution views** (`FinOps – Attribution Views – v1`). Use the report generator to
    emit the SQL and, with `--apply`, create the views in the dataset:
    ```
    python finops-report.py --project "$FINOPS_PROJECT" --dataset "$DATASET" \
        --emit-views --out views.sql            # dry-run: writes SQL, creates nothing
    python finops-report.py --project "$FINOPS_PROJECT" --dataset "$DATASET" \
        --emit-views --apply                     # creates the views
    ```
    The views include: **cost-by-project**, **cost-by-label** (per required key), **cost-by-service**,
    and **unattributed-spend** (rows missing `team`/`cost-center`). Views read the export table so
    they always reflect the latest data.

### 3c. Provision budgets and alerts (pilot first — see Phase 4)

11. **Create the budget alert topic** (`FinOps – Budget Alerts – Prod`) if using Pub/Sub:
    ```
    gcloud pubsub topics create FinOps-Budget-Alerts-Prod --project "$FINOPS_PROJECT"
    ```
    Grant the Cloud Billing budget service agent `roles/pubsub.publisher` on the topic (see the
    Cloud Billing budgets-notifications documentation for the exact service-agent principal).

12. **Provision the pilot budget with the provisioner (dry-run by default):**
    ```
    python finops-budget-provisioner.py --billing-account "$BILLING" \
        --name "FinOps – Budget – Pilot – v1" \
        --scope-projects PILOT_PROJECT_1,PILOT_PROJECT_2 \
        --amount 5000 --currency USD \
        --thresholds 0.5,0.9,1.0 --forecast-threshold 1.0 \
        --pubsub-topic FinOps-Budget-Alerts-Prod --dry-run       # prints the plan, creates nothing
    ```
    Review the printed plan, then re-run with `--apply` to create the budget.

### 3d. Stand up the showback dashboard

13. **Build the showback dashboard** (`FinOps – Showback – v1`). Point **Looker Studio** at the
    `finops_billing_export` dataset (or a showback summary table produced by `finops-report.py`),
    with one page per audience (per team / per cost-center) and a trend + top-services breakdown.
    (Dashboard construction is a Looker Studio task; the tool provides the underlying query/table.)

---

## Phase 4 — Pilot (`FinOps – Pilot – v1`)

14. **Confirm the pilot is scoped, not org-wide.** The pilot budget `FinOps – Budget – Pilot – v1`
    covers only `FinOps – Pilot – v1` (one folder or a few projects). No org-wide budget exists yet.

15. **Run the guardrail check** against the pilot to confirm the FinOps configuration is sound:
    ```
    python finops-guardrail-check.py --billing-account "$BILLING" \
        --project "$FINOPS_PROJECT" --dataset "$DATASET" --json pilot-guardrail.json
    ```
    It verifies: export is flowing (recent rows), the pilot budget exists with the expected
    thresholds and a live notification target, attribution views resolve, and unattributed spend for
    the pilot scope is below the target. All must pass.

16. **Trigger a proof alert (optional, safe).** Set a deliberately low pilot budget amount so the 50%
    threshold fires, confirm the alert reaches email/Pub/Sub, then restore the real amount with the
    provisioner `--apply`. This proves the notification path end to end.

17. **Identify pilot savings:**
    ```
    python finops-savings-analyzer.py --projects PILOT_PROJECT_1,PILOT_PROJECT_2 \
        --regions REGION --json pilot-savings.json
    ```
    Read-only. Produces the `FinOps – Savings Backlog – v1` for the pilot: rightsizing, idle
    resources, and CUD opportunities with an estimated monthly saving and an owner per item.

**Pilot gate (all must pass):**
- Billing export has recent rows for the pilot scope.
- Pilot spend is attributable (unattributed % <= target).
- The pilot budget alerts correctly to its notification target.
- A savings backlog was produced.

If any gate fails, **do not expand.** Fix and re-run the guardrail check.

---

## Phase 5 — Validate

18. **Validate against the gates for real data.** Re-run `finops-guardrail-check.py` and confirm every
    check passes for the pilot. Confirm the showback dashboard renders the pilot teams' spend and that
    the numbers reconcile to the console's cost report for the same period (within rounding/credit
    timing).

19. **Review the savings backlog with owners.** Each item in `FinOps – Savings Backlog – v1` gets an
    owner and a decision (act / defer / reject). **CUD purchases are commitments and money movement —
    they are approved and executed by a human, never by the tooling.**

**Validate gate:** guardrail check fully passes, dashboard reconciles, savings backlog is owned.

---

## Phase 6 — Expand (org-wide)

20. **Create the org-wide budgets** (`FinOps – Budget – Org – v1`) with the provisioner, scoped as the
    budget policy defined (all-projects and/or per-folder/per-label budgets), dry-run first:
    ```
    python finops-budget-provisioner.py --billing-account "$BILLING" \
        --name "FinOps – Budget – Org – v1" --scope-all-projects \
        --amount 250000 --currency USD --thresholds 0.5,0.9,1.0 \
        --forecast-threshold 1.0 --pubsub-topic FinOps-Budget-Alerts-Prod --dry-run
    ```
    Review the plan; re-run with `--apply`.

21. **Expand attribution + showback org-wide.** The attribution views already cover the whole export;
    extend the showback dashboard to all teams/cost-centers and set the recurring showback cadence.

22. **Run the org-wide guardrail check** and confirm unattributed spend is below target across the
    organization. Where it is not, drive labeling remediation (the report tool lists the biggest
    unattributed projects/services).

23. **Establish the operating rhythm.** Schedule: monthly showback delivery, monthly savings-backlog
    review, and budget-alert triage as alerts fire. Assign these to the named FinOps owner.

---

## Rollback (org-wide changes)

Every org-wide change is reversible:

- **Budgets:** delete a budget you created with
  `python finops-budget-provisioner.py --delete --name "FinOps – Budget – Org – v1" --billing-account "$BILLING" --apply`
  (or `gcloud billing budgets delete`). Budgets are non-destructive — deleting one only stops alerts;
  it changes no spend and no resource. Never delete a budget you did not create.
- **Attribution views:** `bq rm -f "$FINOPS_PROJECT:$DATASET.<view>"` removes a view; views are
  derived and safely re-creatable from `finops-report.py --emit-views`.
- **Billing export:** turn the export off in **Billing → Billing export** to stop new writes. The
  historical dataset is retained; disabling only stops forward capture.
- **Savings backlog / dashboards:** these are read-only artifacts — no rollback needed; discard the
  report file.

Because budgets and views are non-destructive and the analysis tools are read-only, the only truly
irreversible FinOps action — **purchasing a committed-use discount** — is deliberately kept out of the
tooling and left to an explicit, approved human decision.
