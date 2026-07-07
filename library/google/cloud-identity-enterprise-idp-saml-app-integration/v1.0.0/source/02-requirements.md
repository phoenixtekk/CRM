# Requirements

These are the **solution-specific** prerequisites for building the SAML app-integration factory.
They build **on top of** the shared **Global Requirements — Google Workspace & Gemini Solutions**
(`global-requirements-google.md`), which already cover: (1) a provisioned Cloud Identity / Workspace
tenant with a super-admin, (2) the source Microsoft/Entra environment where relevant, (3) DNS control,
(4) an **identity & provisioning source of truth**, (5) a pilot scope + change control, and (6)
security/compliance stakeholders. Verify those first; the items below are what *this* solution adds.

Each requirement: **Description / Why required / How to verify / How to implement if missing.**

---

## 1. Super-admin (or delegated app-management admin) in Google Admin

- **Description:** An admin who can manage **Apps → Web and mobile apps** in admin.google.com — a
  super-admin, or a custom admin role with the **Services → Web and mobile apps** privilege
  (and **Users**/**Groups** read for assignment).
- **Why required:** Creating SAML/OIDC apps, exchanging metadata, configuring provisioning, and setting
  group-based assignment all require these privileges.
- **How to verify:** Sign in to **admin.google.com → Account → Admin roles**; confirm your account holds
  Super Admin or a role granting the *Web and mobile apps* privilege.
- **How to implement if missing:** Have a super-admin grant a least-privilege custom admin role
  (Admin roles → Create new role) scoped to app management, rather than handing out full super-admin.

## 2. Governed Google Groups (or OUs) as the assignment mechanism

- **Description:** Directory **Google Groups** (or OUs) that will drive per-app access — sourced/kept
  current from your identity source of truth (Global Requirement 4) via GCDS, SCIM, or your IGA. These
  become the `Assignment Group – <App> – Users` objects.
- **Why required:** The factory assigns apps **by group, never per user**; group membership is the single
  access lever. Ungoverned or manually maintained groups break the lifecycle guarantee.
- **How to verify:** In **admin.google.com → Directory → Groups**, confirm groups exist and their
  membership is populated by your sync (not hand-edited). Confirm the naming convention is agreed.
- **How to implement if missing:** Define the group model and provision it from the source of truth
  before assigning apps; if groups are hand-maintained today, put them under sync/IGA control first.

## 3. Per-app service-provider (SP) admin access and SSO/provisioning capability

- **Description:** Administrative access to **each target app's** own admin console, and confirmation the
  app supports **SAML 2.0 or OIDC** SSO (and, ideally, **SCIM / auto-provisioning**) on the licensed
  tier you hold.
- **Why required:** Federation is a two-sided trust: you configure Google (IdP) *and* the app (SP). Many
  apps gate SSO/SCIM behind a specific ("enterprise"/"plus") license tier.
- **How to verify:** In each app, locate its SSO/SAML (or OIDC) settings and its SCIM/provisioning
  settings; confirm your license tier exposes them. Record findings in the readiness assessment (Tool 1).
- **How to implement if missing:** Obtain SP admin access from the app owner; if SSO/SCIM is gated by
  license, engage procurement to upgrade the app tier, or record the app as **manual-provisioning** in
  the catalog.

## 4. App inventory and business owners

- **Description:** A discoverable **inventory of the SaaS estate** — which apps exist, who owns each, and
  its current authentication method (local passwords, another IdP, or none) — feeding
  `App Catalog – Federated SaaS – v1`.
- **Why required:** You cannot onboard what you cannot see; the catalog is both the plan and the audit
  surface. Owners approve group assignment and provisioning scope.
- **How to verify:** Confirm a source for the inventory (an existing CMDB/CASB export, Workspace token
  audit, expense/SSO logs). Tool 1 produces an initial readiness view; owners are named per app.
- **How to implement if missing:** Assemble the inventory from CASB/CMDB/finance sources and OAuth token
  audit (**admin.google.com → Security → API controls → App access control**), then assign owners.

## 5. Domain verification & IdP metadata/certificate handling

- **Description:** Your primary domain **verified** in Google (from tenant setup) and a process to handle
  Google's **IdP metadata / SSO URL / entity ID / signing certificate**, including planning for
  **certificate rotation**.
- **Why required:** Apps trust Google's signing certificate; an expiring/rotated cert breaks every app
  that pinned it unless rotation is planned. Metadata must be exchanged accurately per app.
- **How to verify:** In **admin.google.com → Apps → Web and mobile apps**, open a SAML app's setup to
  view Google's **SSO URL, Entity ID, and Certificate** (download the IdP metadata). Confirm you can
  track each cert's expiry.
- **How to implement if missing:** Verify the domain (Global Requirement 3 covers DNS), and record the
  IdP metadata + certificate expiry in the catalog so rotation is scheduled, not discovered at outage.

## 6. Pilot cohort and test accounts

- **Description:** A small **`Pilot Cohort – SSO Factory – Pilot`** (OU or group) of real pilot users,
  plus non-production **test accounts**, to validate each integration before full turn-on.
- **Why required:** The house model is pilot-first with pass/fail gates; every new app is proven against
  the pilot cohort before it is assigned to its full audience.
- **How to verify:** Confirm the pilot OU/group exists (Global Requirement 5) and contains members who
  can test each app; confirm test accounts exist in both Google and, where possible, the target app.
- **How to implement if missing:** Create the pilot group, populate it with willing pilot users across
  representative roles, and create test accounts before onboarding the first app.

## 7. Python 3.10+ with Google client libraries and ADC (for the tools)

- **Description:** A workstation/automation host with **Python 3.10+**, the **Google Cloud CLI
  (`gcloud`)**, and the **Google API Python client** (`pip install google-api-python-client
  google-auth`) authenticated via **Application Default Credentials (ADC)** or an admin OAuth flow with
  the **Admin SDK Directory API** enabled.
- **Why required:** The 5 included tools automate discovery, validation, and reporting through the Admin
  SDK (Directory/Groups) and `gcloud` — no hardcoded credentials or exported service-account keys.
- **How to verify:** Run `python --version` (≥3.10), `gcloud auth list`, and confirm ADC is set
  (`gcloud auth application-default print-access-token` returns a token). Confirm the **Admin SDK API**
  is enabled for the identity/automation project.
- **How to implement if missing:** Install Python 3.10+ and the Cloud SDK; run
  `gcloud auth application-default login` (or configure a workload-identity/service account with
  **domain-wide delegation** limited to the read-only Directory scopes the tools request). Never store a
  downloaded service-account key in the repo.
