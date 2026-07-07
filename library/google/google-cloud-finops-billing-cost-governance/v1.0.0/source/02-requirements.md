# Requirements

This solution assumes the **shared Google Cloud Platform foundation** described in
`global-requirements-gcp.md` — a GCP Organization linked to Cloud Identity/Workspace,
organization-level administrative access, a Cloud Billing account, the `gcloud`/Python toolchain
with API enablement, a resource-hierarchy/naming/labeling design with a named pilot scope, and
engaged security/network/governance/FinOps stakeholders. Verify those first.

The prerequisites below are the ones **specific to FinOps, billing export, and cost governance**.
Each lists what it is, why it is required, how to verify it, and how to implement it if missing.

## 1. Billing Account Administrator (or Costs Manager) access

- **Description:** An identity holding **`roles/billing.admin`** on the target Cloud Billing account
  (or, for scoped work, **`roles/billing.costsManager`** to manage budgets and **`roles/billing.viewer`**
  to read cost). Enabling the export and creating budgets operate at the billing-account level, not
  the project level.
- **Why required:** Billing export configuration and budget creation are billing-account resources.
  Project-level Owner/Editor is not sufficient; the operator must be authorized on the billing account.
- **How to verify:** `gcloud billing accounts get-iam-policy BILLING_ACCOUNT_ID` and confirm the
  operator's principal holds `roles/billing.admin` (or `costsManager`). `gcloud billing accounts list`
  must show the account as `OPEN`.
- **How to implement if missing:** A billing-account admin grants the role under change control:
  `gcloud billing accounts add-iam-policy-binding BILLING_ACCOUNT_ID --member=user:EMAIL --role=roles/billing.admin`.
  Keep this access audited and MFA-protected.

## 2. A dedicated project and BigQuery dataset for the billing export

- **Description:** A dedicated GCP project (e.g. `finops-billing-prod`) hosting the BigQuery dataset
  **`FinOps – Billing Export – Prod`** that will receive the detailed usage cost export, with the
  **BigQuery API** (`bigquery.googleapis.com`) enabled and the project **linked to a billing account**.
- **Why required:** The detailed usage cost export writes to a BigQuery dataset; a dedicated project
  isolates the FinOps data, its IAM, and its own (small) query cost from workload projects.
- **How to verify:** `gcloud services list --enabled --project FINOPS_PROJECT` shows
  `bigquery.googleapis.com`; `bq ls --project_id FINOPS_PROJECT` shows the dataset (once created).
- **How to implement if missing:** Create the project, link billing, enable the API
  (`gcloud services enable bigquery.googleapis.com --project FINOPS_PROJECT`), and create the dataset
  (`bq --location=US mk --dataset FINOPS_PROJECT:finops_billing_export`) in the region the org's data
  policy allows. Choose the dataset location deliberately — it cannot be changed after export begins.

## 3. A standardized labeling convention with measurable coverage

- **Description:** An agreed set of **billing/resource labels** — at minimum `cost-center`, `team`,
  `environment`, and `app` — applied to projects and (where supported) resources, plus a target
  labeling-coverage threshold (e.g. ">= 95% of spend attributable").
- **Why required:** Attribution and showback are only as good as labeling coverage. Cost that carries
  no `team`/`cost-center` label cannot be rolled up to an owner and becomes "unattributed" spend.
- **How to verify:** Query the billing export for the share of cost whose `labels`/`project.labels`
  contain the required keys (the report generator tool reports exactly this "unattributed %").
- **How to implement if missing:** Define the label keys and allowed values, apply project-level
  labels (`gcloud projects update PROJECT_ID --update-labels team=...,cost-center=...`), and set
  labels on billable resources at creation. Consider an org policy / Terraform standard so new
  resources are labeled by default. Note: **billing export reflects labels going forward** — relabeling
  does not rewrite historical rows.

## 4. Recommender API enabled for optimization analysis

- **Description:** The **Recommender API** (`recommender.googleapis.com`) enabled on the projects to be
  analyzed, so the tooling can read **rightsizing** (machine-type), **idle-resource**, and
  **committed-use-discount (CUD)** recommendations. Read access requires
  **`roles/recommender.viewer`** (or the specific recommender viewer roles).
- **Why required:** The savings analysis reads recommendations from this API. Without it enabled and
  readable, the CUD/rightsizing analyzer has no source data.
- **How to verify:** `gcloud services list --enabled --project PROJECT` shows
  `recommender.googleapis.com`; `gcloud recommender recommendations list --project=PROJECT
  --location=REGION --recommender=google.compute.instance.MachineTypeRecommender` returns without a
  permission error.
- **How to implement if missing:** `gcloud services enable recommender.googleapis.com --project PROJECT`
  and grant `roles/recommender.viewer`. Note that recommender availability and specific recommender
  IDs are **version-dependent** — confirm the current recommender IDs for CUD and rightsizing in the
  Google Cloud Recommender documentation for your organization.

## 5. A notification channel for budget alerts

- **Description:** A destination for budget alerts — **billing-account admins/users by email** and/or
  a dedicated **Pub/Sub topic** (`FinOps – Budget Alerts – Prod`) for programmatic handling
  (routing to chat, ticketing, or automation). Cloud Monitoring notification channels may also be used
  for downstream alerting.
- **Why required:** A budget with no notification target is invisible. Alerts must reach an accountable
  owner (email) and, for automation, a machine-readable channel (Pub/Sub).
- **How to verify:** Confirm the email recipients on the budget's alert rule, and (if used)
  `gcloud pubsub topics describe FinOps-Budget-Alerts-Prod` succeeds with the billing service account
  granted `roles/pubsub.publisher` on the topic.
- **How to implement if missing:** Create the topic
  (`gcloud pubsub topics create FinOps-Budget-Alerts-Prod`), grant the Cloud Billing budget service
  agent publish rights, and reference it in the budget's `notificationsRule`. Email recipients are set
  by billing role or explicitly on the budget.

## 6. A named pilot scope and a FinOps operating owner

- **Description:** A designated **pilot scope** (`FinOps – Pilot – v1`: one folder or a small set of
  projects) to validate the model on before org-wide rollout, and a named **FinOps owner** (a person
  or the cloud-governance/FinOps function) who owns the budget policy, the showback cadence, and the
  savings backlog.
- **Why required:** The deployment model is pilot-first; org-wide budgets/alerts must not be the first
  test. FinOps is an ongoing practice, so it needs a standing owner — not just a one-time setup.
- **How to verify:** Confirm the pilot folder/projects and the named owner with the platform and
  finance stakeholders.
- **How to implement if missing:** Nominate the pilot scope and the FinOps owner during Assess/Design,
  before any budget or export change is applied org-wide.
