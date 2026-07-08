# 2. Requirements Guide — Microsoft Purview for Healthcare (HIPAA/PHI)

Verify **every** requirement before configuring. Each entry: **Description · Why · Verify ·
Implement-if-missing.** Category-wide prerequisites are in `global-requirements-purview.md` — this
guide adds the **Healthcare/PHI-specific** prerequisites and does not repeat the six.

## 2.1 Microsoft 365 + Purview/compliance licensing for the PHI controls
**Description:** Licensing that includes the capabilities this solution configures. Sensitivity labels,
manual DLP, and the built-in **U.S. Health Insurance Act (HIPAA)** DLP template ship in Microsoft 365
**E3 / Business Premium**; **auto-labeling at rest, endpoint DLP, DSPM (and DSPM for AI), insider risk
management, communication compliance, and advanced records** require **Microsoft 365 E5** or the **E5
Compliance** add-on.
**Why:** The PHI features are plan-gated; auto-labeling at rest and endpoint DLP will not appear
without the higher plan. Purview licensing/availability evolves — **verify your licensing/tenant**.
**Verify:** Microsoft 365 admin center → **Billing → Licenses**; confirm the feature is visible in the
Purview portal; run `PHI-Discovery.ps1`.
**Implement:** Assign the required plan (E3/Business Premium for labels + HIPAA-template DLP; E5 or the
E5 Compliance add-on for auto-labeling at rest, endpoint DLP, DSPM, insider risk, communication
compliance, advanced records) **before** starting.

## 2.2 Least-privilege Purview roles
**Description:** The operator holds the least-privilege roles to create labels, DLP, and retention —
for example **Compliance Administrator** (or **Information Protection Admin** plus **Data Loss
Prevention** roles), and **Records Management** for records/file-plan work — in the Purview portal.
**Why:** Purview uses fine-grained role groups; Global Administrator alone is not the least-privilege
choice, and PHI-sensitive functions (insider risk, communication compliance) require **strict role
separation**.
**Verify:** `https://purview.microsoft.com` → **Settings → Roles and scopes → Role groups**; confirm
membership.
**Implement:** Add the operator to the least-privilege role group(s). Keep insider-risk and
communication-compliance roles separated and restricted (HR/privacy sensitivity).

## 2.3 In-scope PHI data estate and classification intent
**Description:** The **workloads that hold ePHI** in scope (Exchange, SharePoint, OneDrive, Teams,
onboarded endpoints) and a **PHI classification intent** — what counts as PHI, and which health/PII
sensitive-information types apply (for example the **U.S. Health Insurance Act (HIPAA)** template,
**ICD-9-CM / ICD-10-CM**, **U.S. Social Security Number**, **Drug Enforcement Agency (DEA) Number**).
**Why:** DLP and labels key off the in-scope workloads and the classification scheme; without it the
policies match the wrong content.
**Verify:** Confirm the in-scope workloads and the PHI sensitive-information-type set with clinical,
privacy, and security stakeholders.
**Implement:** Define the PHI scope and the sensitive-information-type set before authoring policies
(Implementation Step 1). Purview protects PHI **within M365/endpoints only** — PHI in a separate EHR or
imaging system is out of scope.

## 2.4 PHI data owners, privacy officer, and a records schedule
**Description:** Named business owners — including the **HIPAA Privacy/Security Officer** and
**records management** — who decide what is PHI, how PHI-restricted content is scoped
(**minimum-necessary**), and **how long** each record type is retained.
**Why:** Retention durations and DLP conditions are **compliance/records decisions, not IT defaults**.
Medical-record retention is set by **state law and your records schedule** (often longer for minors);
the technical config must implement that schedule, not guess it.
**Verify:** A named Privacy/Security Officer and records owner exist; a **records retention schedule**
(source document) is available per record type.
**Implement:** Identify the owners; obtain the retention schedule and the PHI classification decision
before configuring. **Determinations are deferred to these functions** — the solution implements them.

## 2.5 Pilot scope (care-team users and, for endpoint DLP, devices)
**Description:** A Microsoft Entra security group of **pilot users** (a representative clinical/admin
ring) for label/DLP/retention piloting, and — for endpoint DLP — clinical/admin **devices onboarded**
to Microsoft Purview.
**Why:** Every policy is piloted before rollout; DLP in particular must run in **audit** on a pilot
before it can enforce safely, so PHI protection never blocks patient care unexpectedly.
**Verify:** Entra → **Groups**; the pilot group `Purview - PHI Pilot Users` exists. Purview →
**Settings → Device onboarding** shows pilot devices onboarded (endpoint DLP only).
**Implement:** Build the pilot group with `PHI-Set-ScopeTargeting.ps1`; onboard pilot devices via the
Purview device onboarding package.

## 2.6 Clinical continuity / emergency-access plan for label encryption
**Description:** A plan, agreed with clinical IT, for how **label encryption** interacts with clinical
apps, EHR/PACS integrations, and **emergency ("break-glass") access** to PHI.
**Why:** A label that encrypts PHI can block legacy or third-party clinical apps and must never impede
**continuity of care**; this risk is specific to healthcare and must be piloted deliberately.
**Verify:** A documented list of clinical apps/integrations that touch labeled content, and an
emergency-access approach, exists and has been reviewed with clinical IT.
**Implement:** Inventory the clinical apps, test encryption against them on the pilot, and agree the
emergency-access handling before enforcing encryption broadly.

## 2.7 Audit logging enabled
**Description:** Microsoft Purview audit (unified audit log) is turned on.
**Why:** DLP tuning, PHI-coverage reporting, and evidence for HIPAA documentation all read
audit/activity data; without it you cannot review the audit gate or report coverage.
**Verify:** Purview → **Audit**; a search returns results. Run `PHI-Report.ps1`.
**Implement:** Turn on auditing in the Purview **Audit** solution; allow time for events to populate.

## 2.8 Change control for enforce-mode and retention changes
**Description:** A documented change-control / rollback process for switching any DLP policy from
audit to enforce, or for activating a retention policy that disposes of PHI content.
**Why:** Enforce-mode DLP can block clinician work and retention disposal is irreversible; a pilot gate
and rollback are mandatory.
**Verify:** A change ticket exists with an approver, a pilot scope, and a documented rollback (revert
DLP to audit; disable the retention policy).
**Implement:** Record the change, name the pilot scope, define the rollback, and get approval before
enforcing.

---
## Checklist
- [ ] Microsoft 365 + Purview/compliance licensing for the PHI controls (E3 for labels + HIPAA-template DLP; E5/add-on for auto-label at rest, endpoint DLP, DSPM, insider risk, comms compliance) — `PHI-Discovery.ps1` · **verify your licensing/tenant**
- [ ] Least-privilege Purview roles assigned (Compliance Admin / Information Protection + DLP; Records Management; separated insider-risk/comms-compliance roles)
- [ ] In-scope PHI workloads + health sensitive-information-type set defined
- [ ] PHI data owners + Privacy/Security Officer named; **records retention schedule** obtained (determinations deferred)
- [ ] Pilot scope group `Purview - PHI Pilot Users` created — `PHI-Set-ScopeTargeting.ps1`
- [ ] Endpoint devices onboarded (endpoint DLP only) — `PHI-Discovery.ps1`
- [ ] Clinical continuity / emergency-access plan for label encryption reviewed with clinical IT
- [ ] Purview audit logging enabled — `PHI-Report.ps1`
- [ ] Change control + rollback for enforce-mode / retention disposal
