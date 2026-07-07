# Requirements

These are the **solution-specific** prerequisites for OAuth & third-party app-access governance.
They build on the shared **Global Requirements — Google Workspace & Gemini Solutions**
(`global-requirements-google.md`), which already cover the Workspace/Cloud Identity tenant with a
super-admin, the identity source of truth, a pilot OU/group and change control, and
security/compliance stakeholders. Do **not** re-establish those here; verify them, then confirm the
additional items below.

Each requirement lists **Description / Why required / How to verify / How to implement if missing.**

---

## 1. Super-admin (or delegated admin with API-controls privilege)

- **Description:** A Google Workspace **super-admin** account, or a custom admin role that includes
  the **Services → Security** and the **API controls / App access control** management privileges.
- **Why required:** Configuring app access control (trusted/limited/blocked), Marketplace settings,
  and the unverified-app block are performed in **Admin console → Security → Access and data control
  → API controls**, which requires these privileges.
- **How to verify:** Sign in to admin.google.com; confirm you can open **Security → Access and data
  control → API controls** and see **App access control** and **Settings**.
- **How to implement if missing:** Have a super-admin assign the role (**Account → Admin roles**), or
  perform the work as super-admin under change control.

## 2. Admin SDK API enabled + a delegated identity for automation

- **Description:** The **Admin SDK API** enabled for the tenant, and an identity the Python tools can
  authenticate as — either your admin user via **Application Default Credentials** (`gcloud auth
  application-default login`) with the required OAuth scopes, or a **service account with
  domain-wide delegation** authorized for the read-only reporting/directory scopes.
- **Why required:** The inventory, validation, and report tools call the **Reports API**
  (`admin.reports.audit.readonly`) for OAuth-token activity and the **Directory API**
  (`admin.directory.user.security` for the `tokens` resource) to enumerate and revoke grants.
- **How to verify:** In the Google Cloud Console for the automation project, confirm **Admin SDK API**
  is enabled; run one of the included discovery tools with `--check-auth` — it prints the
  authenticated principal and the granted scopes.
- **How to implement if missing:** Enable the Admin SDK API in the automation project; for a service
  account, authorize domain-wide delegation in **Admin console → Security → Access and data control →
  API controls → Domain-wide delegation** for the specific read-only scopes. **Never export or commit
  a service-account key** — prefer ADC or workload identity.

## 3. Scope-sensitivity reference (Google's OAuth scope classification)

- **Description:** The current mapping of OAuth scopes to Google's **restricted / sensitive / basic**
  sensitivity tiers, used to risk-score connected apps.
- **Why required:** The risk model classifies each app by the most sensitive scope it holds; this
  depends on Google's published scope classification, which Google updates over time.
- **How to verify:** Cross-check a sample of observed scopes against Google's **OAuth API scopes** and
  **restricted/sensitive scopes** documentation. *Verify the current classification for your tenant —
  do not assume a frozen list.*
- **How to implement if missing:** Use the included scope-config helper to load a reviewable
  scope-tier reference file; any scope not in the reference is flagged **UNKNOWN** for manual triage
  rather than silently treated as low-risk.

## 4. A defined app-vetting decision authority and risk criteria

- **Description:** A named **approver/reviewer** (security or IT-governance) and agreed **risk
  criteria** for deciding whether a third-party app becomes Trusted, Limited, or Blocked (data
  sensitivity, vendor security posture, scope necessity, verification status, business owner).
- **Why required:** The vetting workflow (`App-Vetting Workflow – Org-Wide – v1`) requires a decision
  authority and objective criteria; otherwise "trusted" is arbitrary.
- **How to verify:** Confirm the approver(s) and a written risk-criteria checklist exist and are
  agreed with the security stakeholder from the shared requirements.
- **How to implement if missing:** Define the criteria and approver before configuring the Trusted
  list; the included report generator produces the review packet the approver signs off.

## 5. A pilot OU/group representative of real app usage

- **Description:** The pilot scope (`App-Access Pilot – Pilot-OU – v1`) — an OU or group whose members
  actually use a representative set of third-party apps (not a dormant test OU).
- **Why required:** Blocking unverified apps or tightening Marketplace can break legitimate workflows;
  the pilot must exercise real apps so breakage is caught before org-wide expansion.
- **How to verify:** Confirm the pilot OU/group contains active users whose connected-app inventory
  (from the discovery tool) covers the common business apps.
- **How to implement if missing:** Select or assemble a representative pilot cohort with the business
  and change-management owners; extend the shared pilot OU/group if it is not representative.

## 6. Change-control window for the org-wide access-control change

- **Description:** An approved **change window and rollback plan** for switching the org-wide
  unverified-app policy and Marketplace setting from their current (often permissive) state to the
  governed state.
- **Why required:** These are tenant-wide settings that change what every user can install/authorize;
  they must be scheduled, communicated, and reversible.
- **How to verify:** Confirm a change ticket exists referencing `Unverified-App Block – Org-Wide –
  Pilot` → org-wide expansion, with the documented rollback (revert the setting) attached.
- **How to implement if missing:** Raise the change with the change-control process from the shared
  requirements; do not flip org-wide settings ad hoc.
