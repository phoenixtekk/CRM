# Requirements

The **shared category prerequisites** for every Google Cloud foundation solution are defined in
`global-requirements-gcp.md` (in this `source/` folder): (1) a GCP Organization linked to Cloud
Identity/Workspace, (2) Organization-level administrative access, (3) a Cloud Billing account,
(4) the `gcloud`/IaC toolchain and API enablement, (5) a resource-hierarchy/naming/environment
design, and (6) security/network/governance stakeholders and policy. **Read and satisfy those
first.** This solution *is* the one that builds much of #5 — so it treats the hierarchy/naming design
as an output, not an assumption.

Below are the **solution-specific** prerequisites this landing-zone build adds on top of the shared
set. Each lists what it is, why it's required, how to verify it, and how to implement it if missing.

---

## R1. A bootstrap/seed project and a CI/automation identity

- **Description:** A dedicated **seed project** (`Project: Bootstrap – Seed – Prod`) that holds the
  automation's state (e.g. the Terraform/Cloud Foundation Toolkit state bucket) and a **CI service
  account** or (preferred) a **Workload Identity Federation** identity that the pipeline uses to
  build the rest of the hierarchy. Nothing else runs here.
- **Why required:** The landing zone must be built by a controlled, auditable identity — not a
  human's personal credentials — and its IaC state must live somewhere stable *before* the folders
  it manages exist. Separating the seed avoids a circular dependency.
- **How to verify:** `gcloud projects describe <seed-project-id>`; confirm a state bucket exists
  (`gcloud storage buckets list --project <seed-project-id>`) and the CI identity is a member with
  only the roles it needs (`gcloud projects get-iam-policy <seed-project-id>`).
- **How to implement if missing:** Create the seed project under a bootstrap folder, grant the CI
  identity org-level roles scoped to what it provisions (e.g. `roles/resourcemanager.folderAdmin`,
  `roles/resourcemanager.projectCreator`, `roles/orgpolicy.policyAdmin`, `roles/billing.user`), and
  prefer **Workload Identity Federation** over a downloaded service-account key. **Never** commit or
  store an exported service-account key.

## R2. Organization ID, billing account ID, and Cloud Identity domain confirmed

- **Description:** The exact **Organization ID** (numeric), the **billing account ID**
  (`XXXXXX-XXXXXX-XXXXXX`), and the **Cloud Identity / Workspace primary domain** the Organization is
  bound to, captured and agreed with the platform owners.
- **Why required:** Every provisioning step and every tool in this solution keys off these three
  identifiers. Domain-restricted sharing (`iam.allowedPolicyMemberDomains`) needs the customer ID of
  the domain.
- **How to verify:** `gcloud organizations list`, `gcloud billing accounts list`, and (for the
  domain customer ID) `gcloud organizations describe <ORG_ID> --format="value(owner.directoryCustomerId)"`.
- **How to implement if missing:** Stand up Cloud Identity/Workspace for the domain (per shared
  requirement #1) so the Organization and its customer ID exist, and create/associate an OPEN
  billing account.

## R3. The agreed resource-hierarchy and naming/labeling design (this solution's design gate)

- **Description:** A written, approved **hierarchy design** (which folders, which environments, which
  foundation projects) and a **naming + labeling standard** (`<Purpose> – <Scope> – <Stage>` for
  names; a fixed label key set such as `env`, `owner`, `cost-center`, `data-class`).
- **Why required:** Org policy inheritance, IAM scoping, network attachment, and cost attribution all
  depend on the shape being decided *before* it is built. Rebuilding a hierarchy after workloads
  land is expensive and disruptive.
- **How to verify:** The design document is signed off by platform, security, network, and FinOps
  owners; the naming/labeling helper tool in this solution validates candidate names/labels against
  it.
- **How to implement if missing:** Run the Design step of this solution — use the naming/label config
  helper to draft the convention, review with stakeholders, and record it as the approved standard.

## R4. Cloud Identity groups for the IAM baseline

- **Description:** A set of **Google groups** in the Google Admin console / Cloud Identity that the
  IAM baseline binds roles to — e.g. `gcp-organization-admins`, `gcp-billing-admins`,
  `gcp-network-admins`, `gcp-security-admins`, `gcp-logging-viewers`, plus per-environment
  `gcp-<env>-developers` groups. Membership is managed in the directory (ideally provisioned from the
  enterprise HR/IdP source), not in GCP.
- **Why required:** Least-privilege IAM at enterprise scale is only maintainable if access is granted
  to *groups by role*. Binding roles to individuals produces thousands of unauditable bindings.
- **How to verify:** In the Google Admin console (admin.google.com → Directory → Groups) or via the
  Cloud Identity / Admin SDK Directory API, confirm the groups exist and are owned by the platform
  team.
- **How to implement if missing:** Create the groups in the Admin console (or Admin SDK), align them
  to your role model, and — for an 80k–150k-user enterprise — connect group membership to the
  authoritative identity source so joiner/mover/leaver flows update access automatically.

## R5. Required Google Cloud APIs enabled on the foundation projects

- **Description:** The APIs the landing zone itself depends on: **Resource Manager**
  (`cloudresourcemanager.googleapis.com`), **Organization Policy** (`orgpolicy.googleapis.com`),
  **Cloud Billing** (`cloudbilling.googleapis.com`), **Service Usage** (`serviceusage.googleapis.com`),
  **Compute** (`compute.googleapis.com`, for Shared VPC), **Cloud Logging**
  (`logging.googleapis.com`), **BigQuery** (`bigquery.googleapis.com`, for billing/log export), and
  the **Admin SDK / Cloud Identity Groups** APIs where group automation is used.
- **Why required:** Each provisioning action calls the corresponding API; a disabled API produces a
  `SERVICE_DISABLED` / `PERMISSION_DENIED` failure.
- **How to verify:** `gcloud services list --enabled --project <project-id>` on each foundation
  project.
- **How to implement if missing:** `gcloud services enable <api> --project <project-id>` for each,
  ideally as a managed step in the seed/CI pipeline. Enabling some APIs is itself governed by org
  policy — verify no `serviceuser`/`gcp.restrictServiceUsage`-style constraint blocks them.

## R6. A named pilot scope with a defined rollback owner

- **Description:** A single **pilot folder and/or project** (`Landing Zone – Pilot`) designated as the
  first place guardrails, IAM, logging, and network attachment are applied — plus a named **rollback
  owner** authorized to revert org-wide changes.
- **Why required:** The house model is pilot-first. Org-policy and IAM changes at the Organization
  node are high-blast-radius; proving them on a contained pilot with a ready rollback is mandatory
  before Expand.
- **How to verify:** The pilot folder/project exists and is agreed; the rollback runbook names an
  owner and the exact revert commands (see Implementation §Rollback).
- **How to implement if missing:** Create `Landing Zone – Pilot` as a folder with one throwaway
  project, and document the rollback owner and procedure before applying any org-wide guardrail.
