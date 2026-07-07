# Requirements

These are the **solution-specific** prerequisites for CMMC Level 2 readiness on Google Workspace. They
are **in addition to** the shared category prerequisites in **`global-requirements-google.md`** (a
provisioned Workspace/Cloud-Identity tenant with super-admin, DNS control, an identity source of truth,
a pilot OU/group and change control, and engaged security/compliance/governance stakeholders). Do not
re-satisfy those here — verify them, then confirm the following.

> **Scoping/applicability is not a prerequisite you satisfy technically.** Whether CMMC Level 2 and
> specific NIST 800-171 requirements apply to your organization, and what constitutes CUI, are
> **determinations for your compliance/legal team and assessor**. The requirements below prepare the
> *environment and inputs*; they do not decide scope.

---

## 1. Workspace edition/add-on that supports the regulated-workload controls

- **Description:** A Google Workspace edition (and any add-on) that provides the controls CMMC L2
  readiness relies on: **Vault** (retention/eDiscovery), **DLP for Drive/Gmail**, **context-aware
  access**, **data regions**, **audit-log export**, and — where the CUI workload requires it —
  **Assured Controls** and **client-side encryption**.
- **Why required:** Several NIST 800-171 families (AU, MP, SC, AC) are implemented through these
  features; without the edition/add-on they are unavailable.
- **How to verify:** In the **Admin console → Billing → Subscriptions**, confirm the edition and any
  Assured Controls / AppSec add-on. In **Account → Account settings → Legal & compliance** / **Data
  regions**, confirm data-region and (if licensed) Assured Controls surfaces are present.
  **Verify Assured Controls availability in your tenant** — it is edition/contract-dependent.
- **How to implement if missing:** Engage Google or your reseller to move to the qualifying edition and
  enable the required add-ons **before** configuration. Flag any capability you cannot confirm as a
  **POA&M** item rather than assuming it exists.

## 2. A defined CUI boundary input (users, groups, Shared Drives, data flows)

- **Description:** A documented list — even a draft — of **who handles CUI**, **which groups/OUs they
  belong to**, **which Shared Drives / shared locations hold CUI**, and **how CUI enters and leaves**
  (mail, Drive sharing, external collaboration, connected apps). This is the input to the
  **`CUI – Boundary – Org`** OU.
- **Why required:** The boundary defines assessment scope; every subsequent control is applied *to the
  boundary*. Without it, scope is unbounded and evidence is unfocused.
- **How to verify:** Confirm a data map / CUI inventory exists (from the compliance/data-governance
  stakeholders named in the shared requirements). The included boundary-exposure tool can help
  *validate* a draft, but the **authoritative determination of what is CUI is your compliance team's**.
- **How to implement if missing:** Work with data-governance/compliance to produce a first-pass CUI
  inventory and data-flow map; refine it during the Assess stage. Treat unknowns as boundary risks.

## 3. Assessor / C3PAO and compliance-owner engagement

- **Description:** A named **compliance owner** (accountable for the SSP/POA&M and the SPRS score) and,
  ideally, the **C3PAO or Registered Practitioner** the organization intends to use — engaged early so
  the readiness work targets their expectations.
- **Why required:** Applicability, scoping, evidence-format expectations, and the ultimate
  determination are theirs. Building readiness without them risks re-work.
- **How to verify:** Confirm the compliance owner is identified and that assessor expectations (scope,
  evidence format, SSP template) are known or requested.
- **How to implement if missing:** Identify the compliance owner before authoring the SSP; engage a
  C3PAO/RP per your organization's procurement process. **This solution does not select or represent an
  assessor.**

## 4. Baseline of the existing Assured Controls / data-region posture

- **Description:** Knowledge of the current **data-region policy**, **Assured Controls state**, and
  **client-side-encryption** configuration for the CUI OUs — typically established by the separate
  Assured Controls / ITAR / DFARS solution.
- **Why required:** NIST 800-171 SC (System & Communications Protection) and MP (Media Protection)
  controls reuse this posture; the readiness work maps to it rather than rebuilding it.
- **How to verify:** Review the data-region/Assured Controls configuration for the CUI OUs in the Admin
  console and confirm it matches the organization's documented regulated-workload design.
- **How to implement if missing:** Complete the Assured Controls / data-region work first (separate
  solution), then return to map those controls into the SSP.

## 5. API access for the assessment and evidence tooling

- **Description:** A **Google Cloud project** with the **Admin SDK (Directory + Reports)**, **Drive**,
  and **Groups Settings** APIs enabled, plus an OAuth client or a service account with **domain-wide
  delegation** limited to **read-only** admin scopes, for running the five Python tools.
- **Why required:** The tools read directory, policy, sharing, and audit-log data to produce the
  control-status map and evidence package. They are read-only/dry-run by default.
- **How to verify:** In the Cloud console confirm the APIs are enabled; run `assess-nist-controls.py
  --check-auth` (below) to confirm the credential authenticates with read-only scopes.
- **How to implement if missing:** Create the project, enable the APIs, and configure a **least-privilege
  read-only** credential (OAuth user consent or a delegated service account restricted to the
  `*.readonly` admin scopes). **Never** grant write scopes to the evidence tooling; **never** commit or
  export the credential. Store secrets outside the repo (ADC / a secured secret store).

## 6. Change-control window scoped to CUI-boundary changes

- **Description:** Beyond the shared change-control prerequisite, a change window and rollback plan
  specifically for the **high-impact CUI-boundary controls** — DLP enforcement, external-sharing
  restriction, context-aware access, and audit-log export — because these affect users' ability to
  send mail and share files.
- **Why required:** Enforcing these fleet-wide without a pilot and rollback can block legitimate work or
  break collaboration. The deployment model requires a documented rollback for each.
- **How to verify:** Confirm an approved window and a named rollback owner for the CUI-boundary changes.
- **How to implement if missing:** Agree the window and rollback path with the change-control and
  business owners before the Configure stage.
