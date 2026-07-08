# 2. Requirements Guide — Microsoft Purview GDPR Compliance Program

Verify **every** requirement before configuring. Each entry: **Description · Why · Verify ·
Implement-if-missing.** Category-wide prerequisites are in `global-requirements-purview.md` — this
guide names the **GDPR-specific** licensing, roles, scope, and inputs; it does not repeat the six.

## 2.1 Compliance licensing for the GDPR assessment + mapped controls
**Description:** Licensing that surfaces **Compliance Manager**, the **GDPR assessment template**, and
the technical controls this program maps. Compliance Manager and the Microsoft 365 data-protection
baseline assessment ship broadly; the **GDPR template**, **premium assessment templates**,
**auto-labeling at rest**, **endpoint DLP**, **Audit Premium**, **DSPM**, **Insider Risk Management**,
and **Communication Compliance** require **Microsoft 365 E5** or the **E5 Compliance** add-on.
**Priva Subject Rights Requests** (the managed DSR workflow) requires **Microsoft Priva** licensing.
**Why:** The GDPR template and the mapped premium controls will not appear without the right plan;
availability is plan-/tenant-dependent and the portal evolves — **verify your licensing/tenant**.
**Verify:** Microsoft 365 admin center → **Billing → Licenses**; in Purview → **Compliance Manager →
Assessment templates** confirm **GDPR** is available; run `GDPR-Discovery.ps1`.
**Implement:** Assign the required plan/add-on before starting; if a template or control is absent,
confirm the plan rather than assuming the tenant lacks the capability.

## 2.2 Least-privilege Compliance Manager + Purview roles (separation of duties)
**Description:** The operator holds only the roles the program needs — **Compliance Manager
Assessors / Contributors** for the assessment, **Compliance Administrator** (or **Information
Protection Admin** + **Data Loss Prevention** roles) for the mapped controls, **Audit** roles for the
audit evidence, and (where scoped) **eDiscovery** / **Subject Rights Request** roles for the DSR
method. HR/privacy-sensitive capabilities (Insider Risk, Communication Compliance) are **separated**
from the general operator.
**Why:** Purview uses fine-grained role groups; least-privilege and **role separation** are both a
control and evidence for GDPR accountability (Art. 5(2)/32). Global Administrator alone is not the
least-privilege choice.
**Verify:** `https://purview.microsoft.com` → **Settings → Roles and scopes → Role groups**; confirm
membership and that sensitive roles are held by separate owners. Run `GDPR-Discovery.ps1` (role
report).
**Implement:** Assign the least-privilege role groups under change control; capture the separation as
`GDPR Roles – Separation Evidence`.

## 2.3 In-scope GDPR assessment template selected
**Description:** The **GDPR assessment** to work against — the built-in **GDPR** template (and any
overlay the organization runs, e.g. **ISO 27701** where entitled) — chosen with compliance/privacy.
**Why:** The assessment defines the improvement actions, the score, and the evidence structure; the
program is built around the chosen template.
**Verify:** Purview → **Compliance Manager → Assessments**; confirm the GDPR template is available to
add. Run `GDPR-Discovery.ps1`.
**Implement:** Confirm the template with compliance/privacy stakeholders before creating the pilot
assessment (Implementation Step 3).

## 2.4 Scope: EU personal data, workloads, and the classification intent
**Description:** The **workloads and data sources** holding **EU personal data** in scope (Exchange,
SharePoint, OneDrive, Teams, endpoints), and the **EU personal-data sensitive-information types**
(e.g. **EU National Identification Number**, **EU Passport Number**, **EU Driver's License Number**,
**EU Tax Identification Number**, **EU Debit Card Number**, **EU Social Security Number or Equivalent
ID**) that drive labels and DLP.
**Why:** Purview policies key off the in-scope workloads and the sensitive-information types; the
control map and evidence are scoped to them.
**Verify:** Confirm the in-scope workloads and the EU SIT set with stakeholders; run
`GDPR-Discovery.ps1` to list the SITs and current label/DLP coverage.
**Implement:** Define the scope and the EU SIT set before authoring policies; capture it in
`GDPR Scope – Record`.

## 2.5 Data-subject-request (DSR) method decided
**Description:** The chosen **DSR locate-review-produce** method: **Microsoft Priva Subject Rights
Requests** (managed workflow) where Priva is licensed, or **Purview eDiscovery (Standard/Premium) /
content search** as the locate method where it is not.
**Why:** GDPR access/erasure/portability rights (Art. 15/17/20) have a one-month clock; the method
must be decided and wired before a request arrives. Availability depends on Priva/eDiscovery
licensing — verify.
**Verify:** Purview → **eDiscovery** (content search available) and, if licensed, the **Priva** portal
→ **Subject Rights Requests**. Run `GDPR-Discovery.ps1`.
**Implement:** Decide the method with privacy/legal; document it in the DSR runbook (Implementation
Step 7). Erasure/production **decisions** remain privacy/legal calls — the tooling locates and
produces, it does not decide.

## 2.6 Compliance, privacy, records & legal stakeholders + ROPA source
**Description:** Named **compliance, privacy (DPO), records, security, and legal** owners, and the
source of the **records of processing activities (Art. 30)**, lawful-basis register, and retention
schedules the configuration must satisfy.
**Why:** GDPR applicability, lawful basis, ROPA content, DPIA outcomes, and retention durations are
**their** determinations, not technical defaults; several mapped capabilities (Insider Risk,
Communication Compliance) carry HR/privacy sensitivity.
**Verify:** Confirm the DPO/owners, the ROPA source, the lawful-basis register, and the retention
schedule.
**Implement:** Identify the owners and capture the requirements in `GDPR Scope – Record` before
configuring.

## 2.7 Audit logging enabled (accountability evidence)
**Description:** Microsoft Purview **Audit** (unified audit log) is turned on so activity is captured
for accountability (Art. 5(2)) and breach investigation (Art. 33).
**Why:** The evidence register and coverage report read audit/activity data; without it the audit
control has no proof.
**Verify:** Purview → **Audit**; searching returns results. Run `GDPR-EvidenceReport.ps1`.
**Implement:** Turn on auditing in the Purview **Audit** solution; allow time for events to populate.

## 2.8 Pilot scope and change control
**Description:** A Microsoft Entra security group of pilot users/locations (`GDPR - Pilot Scope`) and
a documented **change-control / rollback** process for any high-impact control switched to enforce
(DLP to enforce, a retention policy that deletes content).
**Why:** Every mapped high-impact control is piloted in **simulation/test** before enforcement;
enforce-mode DLP can block work and retention deletion is irreversible.
**Verify:** Entra → **Groups**; `GDPR - Pilot Scope` exists. A change ticket exists with an approver,
a pilot scope, and a documented rollback. Run `GDPR-Set-Scope.ps1 -WhatIf`.
**Implement:** Build the pilot group with `GDPR-Set-Scope.ps1`; record the change and rollback and get
approval before enforcing anything.

---
## Checklist
- [ ] Compliance licensing (Compliance Manager + **GDPR template**; E5/E5 Compliance for premium controls; **Priva** for managed SRR) — `GDPR-Discovery.ps1`
- [ ] Least-privilege Compliance Manager + Purview roles with **separation** — `GDPR-Discovery.ps1` → `GDPR Roles – Separation Evidence`
- [ ] In-scope **GDPR assessment template** selected with compliance/privacy
- [ ] Scope: EU personal-data workloads + **EU sensitive-information types** captured → `GDPR Scope – Record`
- [ ] **DSR method** decided (Priva SRR or eDiscovery/content search)
- [ ] Compliance/privacy (DPO)/records/legal stakeholders + **ROPA / lawful-basis / retention** source named
- [ ] Purview **audit logging** enabled — `GDPR-EvidenceReport.ps1`
- [ ] Pilot scope `GDPR - Pilot Scope` + change control / rollback — `GDPR-Set-Scope.ps1`
