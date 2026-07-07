# Requirements

These are the **solution-specific** prerequisites for operationalizing Security Command Center
(SCC). They build on the shared **Global Requirements — Google Cloud Platform (GCP)**
(`global-requirements-gcp.md`): a Google Cloud **Organization** linked to Cloud Identity /
Workspace, Organization-level administrative access, an active Cloud **Billing** account, the
`gcloud` / Python toolchain with API-enablement rights, a resource-hierarchy & naming design,
and engaged security/network/governance stakeholders. Verify those first; the items below are
what SCC additionally needs.

Each prerequisite lists **Description / Why required / How to verify / How to implement if
missing**.

---

## 1. A confirmed SCC edition (and knowledge of what it includes)

- **Description:** An **active Security Command Center edition/tier** on the Organization, and a
  documented list of which **posture services, vulnerability scanners, and threat detectors** that
  edition actually includes.
- **Why required:** SCC capability is **edition-gated and version-dependent** — the detectors and
  services this solution tunes must exist in your edition. Configuring a service you do not have
  wastes cycles and creates false confidence.
- **How to verify:** In the Console, open **Security Command Center → Settings** and note the
  active edition and enabled services; cross-check against Google's **current** SCC editions
  documentation (`cloud.google.com/security-command-center/docs`). With the API:
  `gcloud scc settings services describe --organization=ORG_ID` (verify exact command/flags for
  your edition — API surface varies by tier). **Do not assume a detector exists** because it is
  named in this guide.
- **How to implement if missing:** Activate or upgrade the desired SCC edition at the Organization
  (an Org-admin / billing-admin action in **Security Command Center → Settings**), then re-inventory
  the included services. Where an edition change alters billing, route it through the billing/FinOps
  owner.

## 2. SCC administrative IAM roles (least privilege)

- **Description:** The identities operating SCC hold the appropriate **SCC roles at the
  Organization** — e.g. `roles/securitycenter.admin` for configuration, and read/finding-editor
  roles (`roles/securitycenter.adminViewer`, `roles/securitycenter.findingsEditor`) for triagers —
  rather than blanket Owner.
- **Why required:** Enabling services, creating notification configs, and muting findings are
  privileged org-level operations; triagers need to edit finding state without broad rights.
  Least-privilege limits blast radius.
- **How to verify:** `gcloud organizations get-iam-policy ORG_ID` and confirm the SCC roles are
  bound to the intended groups (not individuals). Confirm the exact role names against current SCC
  IAM docs — role catalogs evolve.
- **How to implement if missing:** Have an Organization Administrator grant the SCC roles to
  purpose-named groups under change control (e.g. a `grp-scc-admins` and `grp-scc-triage` group).

## 3. Required APIs enabled

- **Description:** The APIs SCC and this solution depend on are **enabled** on the appropriate
  project(s): the **Security Command Center API** (`securitycenter.googleapis.com`), **Pub/Sub**
  (`pubsub.googleapis.com`), and, if used, **Cloud Functions / Cloud Run** and **BigQuery** for
  downstream processing/export.
- **Why required:** The notification config, export topic, and automation call these APIs; a
  disabled API blocks the corresponding step.
- **How to verify:** `gcloud services list --enabled --project=PROJECT_ID` and confirm the API IDs
  above are present.
- **How to implement if missing:** `gcloud services enable securitycenter.googleapis.com
  pubsub.googleapis.com --project=PROJECT_ID` (add functions/bigquery as needed).

## 4. A SecOps project for exports and notifications

- **Description:** A dedicated **project to host the Pub/Sub export topic**, subscription(s), and
  any export/processing resources — kept separate from workload projects (the
  **Finding Export Topic – SecOps – v1** lives here).
- **Why required:** Centralizing the export/notification plumbing in one governed project keeps IAM
  tight, avoids coupling security tooling to workload lifecycles, and gives SecOps clear ownership.
- **How to verify:** Confirm a SecOps/security project exists in the hierarchy, linked to billing,
  with the SecOps group as owner.
- **How to implement if missing:** Create the project under the security/shared folder, link
  billing, enable the APIs from §3, and grant the SecOps group appropriate roles.

## 5. A SIEM / notification destination and its ingestion contract

- **Description:** A confirmed **downstream destination** for findings — a SIEM (via a Pub/Sub
  pull/push subscription or the SIEM's Google Cloud connector), a ticketing webhook, and/or
  BigQuery — with the **ingestion method, credentials model, and field mapping** agreed with the
  SecOps/SIEM owner.
- **Why required:** The notification/export config is only useful if something consumes it; the
  push/pull method and the SIEM's expected schema must be known before wiring.
- **How to verify:** Confirm with the SIEM owner the ingestion mechanism (pull subscription, push
  endpoint, or vendor connector) and that a service account / credential path exists for it. Verify
  the SIEM's SCC/Pub/Sub connector requirements against the **SIEM vendor's current docs** (these
  change).
- **How to implement if missing:** Stand up the subscription/connector with the SIEM owner; provision
  a least-privilege service account for the consumer (no exported keys committed to disk — use
  workload identity / ADC where possible).

## 6. A finding-triage operating model (ownership + SLAs)

- **Description:** An agreed **ownership matrix** (which team owns findings by project / service /
  category) and a **severity → remediation-SLA table** (e.g. Critical / High / Medium / Low target
  times), captured as **Triage Runbook – SecOps – v1**.
- **Why required:** Findings only reduce risk if someone owns them and works them to a deadline;
  without an operating model, SCC becomes an ignored dashboard.
- **How to verify:** Confirm the ownership matrix and SLA table are documented and signed off by the
  security and application owners.
- **How to implement if missing:** Facilitate a working session with SecOps and application owners
  to define ownership by scope and set severity-based SLAs; record them in the runbook (this guide's
  Implementation section produces it).

## 7. A named pilot scope

- **Description:** A specific **folder or set of projects** — **Pilot Scope – Prod-Ready – v1** — on
  which the SCC configuration, notifications, export, and triage cycle are validated before org-wide
  expansion.
- **Why required:** The house deployment model is pilot-first with pass/fail gates; a bounded pilot
  proves the end-to-end flow and lets you tune noise before it hits every team.
- **How to verify:** Confirm the pilot folder/projects with the platform owners; ensure they contain
  realistic-enough resources to generate representative findings.
- **How to implement if missing:** Select a representative non-critical folder/project set and record
  it as the pilot scope; if none exists, the Landing Zone solution defines the hierarchy first.
