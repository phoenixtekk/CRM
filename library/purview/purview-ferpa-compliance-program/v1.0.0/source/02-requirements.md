# 2. Requirements Guide — Microsoft Purview FERPA Compliance Program

Verify **every** requirement before configuring. Each entry: **Description · Why · Verify ·
Implement-if-missing.** Category-wide prerequisites (tenant/licensing, Purview roles, the S&C
PowerShell + Graph toolchain, in-scope workloads, compliance/records/legal stakeholders, pilot &
change control) are in `global-requirements-purview.md` — this guide adds the FERPA-program detail.

> **Regulatory/licensing boundary.** Auto-labeling, advanced/endpoint DLP, trainable classifiers, and
> Audit Premium require **Microsoft 365 E5** or the **E5 Compliance** add-on and evolve; confirm your
> entitlements rather than assuming. **Which data are education records, who are eligible students and
> school officials, which disclosures are permitted, and whether a configuration satisfies FERPA (34 CFR
> Part 99)** are **compliance/registrar/records/legal determinations** — this solution configures the
> control and produces evidence; it does not make the determination. Where this guide flags "verify your
> licensing/tenant" or "compliance/registrar to determine," do so before relying on the item.

## 2.1 Compliance licensing for classification, DLP, retention, and audit evidence
**Description:** The program spans licensed control domains. **Sensitivity labels & manual DLP** are
baseline; **auto-labeling, trainable classifiers, and Endpoint DLP** need **E5 / E5 Compliance**;
**Audit Premium** (high-value events, long-term retention) needs **E5 / E5 Compliance / Audit add-on**,
assigned **per user**.
**Why:** Several controls below are plan-gated; the feature won't be available without the right plan (GR §1).
**Verify:** M365 admin center → `Billing → Licenses`; and run `CMPFERPA-Discovery.ps1`, which reports
whether information-protection/DLP/Audit-Premium-bearing plans are present via Graph. **Confirm
plan/service-plan names against your tenant — they change.**
**Implement:** Assign/purchase E5 or the relevant add-ons to in-scope users before expecting the feature.

## 2.2 Least-privilege roles for labels, DLP, retention, and audit
**Description:** Distinct least-privilege roles per domain — **Information Protection** (Admin/Analyst/
Investigator/Reader) for sensitivity labels; **Compliance Administrator / Data Loss Prevention** roles
for DLP; **Records Management / Retention Management** for retention labels & policies; **Audit
Manager/Reader** for evidence; **Compliance Manager** roles for assessments. Global Administrator only
where genuinely required.
**Why:** Purview uses fine-grained role groups; configuration requires the matching role, and access to
student-record controls is itself sensitive (GR §2).
**Verify:** Purview portal → `Settings → Roles & scopes / Permissions` — confirm membership per domain;
`CMPFERPA-Scope.ps1` reports the role groups it can see and connection identity.
**Implement:** Assign the least-privilege role groups under change control.

## 2.3 Security & Compliance PowerShell + Graph toolchain
**Description:** A workstation with the `ExchangeOnlineManagement` module (for `Connect-IPPSSession` —
sensitivity labels `*-Label`/`*-LabelPolicy`, DLP `*-DlpCompliancePolicy`/`*-DlpComplianceRule`,
retention `*-RetentionCompliancePolicy`/`*-ComplianceTag`, sensitive info types
`Get-DlpSensitiveInformationType`, `*-UnifiedAuditLogRetentionPolicy`) and `Microsoft.Graph` (licensing
reads), with a modern-auth/MFA admin.
**Why:** All configuration and the provided scripts run through Security & Compliance PowerShell and
Graph (GR §3).
**Verify:** `Get-Module -ListAvailable ExchangeOnlineManagement`; `Connect-IPPSSession` and
`Connect-MgGraph` succeed; `CMPFERPA-Discovery.ps1` reports which endpoints are reachable.
**Implement:** `Install-Module ExchangeOnlineManagement -Scope CurrentUser`;
`Install-Module Microsoft.Graph -Scope CurrentUser`.

## 2.4 In-scope education-record data, workloads, and endpoints
**Description:** The **workloads** holding education records (Exchange, SharePoint, OneDrive, Teams, and —
for Endpoint DLP — onboarded **devices**), the **data locations** where student records live (registrar
sites, SIS exports, faculty mailboxes), and a **classification intent** — which **sensitive information
types / trainable classifiers** recognize education-record PII (names, student IDs, grades, disciplinary
and health records).
**Why:** Classification, DLP, retention, and audit controls key off the in-scope workloads and the
classification scheme (GR §4).
**Verify:** Confirm the in-scope workloads/locations, the device-onboarding state (for Endpoint DLP), and
the classification approach with compliance/registrar; `CMPFERPA-Scope.ps1` enumerates the target
locations/mailboxes/sites and existing sensitive information types (read-only).
**Implement:** Define the in-scope data locations and the classification scheme before authoring controls;
onboard devices to Purview if Endpoint DLP is in scope.

## 2.5 The FERPA-obligation-to-control map and records schedule (from compliance/registrar/legal)
**Description:** A documented statement — **from compliance, registrar/records, and legal** — of which
data are **education records**, which **disclosures are permitted** (consent, directory information,
school officials with legitimate educational interest, health/safety, audit/evaluation), what must be
**retained and for how long** (the records schedule), and who approves.
**Why:** What is an education record, permitted disclosure, and retention duration are
**regulatory/records/legal determinations**, not technical defaults (GR §5); the solution configures to
them and evidences them — it does not decide them.
**Verify:** You can name, per control domain, the obligation, the permitted-disclosure rule, the required
retention, and the named approver; these populate the `Control Map – FERPA – Purview` register.
**Implement:** Capture the obligation-to-control map, the permitted-disclosure rules (which drive DLP
exceptions), and the records schedule with approvals before configuring — especially before enforcing
any DLP policy.

## 2.6 DLP simulation-mode preconditions and disclosure exceptions
**Description:** For the disclosure-prevention control specifically: agreement that DLP is built and
validated in **simulation mode** first, the **permitted-disclosure exceptions** (so authorized sharing —
e.g. to the student, to school officials, under consent — is not falsely blocked), the **actions** on
enforcement (block, block-with-override, notify), and the **end-user notification/policy-tip** wording.
**Why:** DLP reads and can block user content — an enforced policy that is mis-scoped disrupts legitimate
educational work; permitted disclosures are compliance/registrar determinations that must be encoded as
exceptions before enforcement (GR §5/§6).
**Verify:** Named permitted-disclosure exceptions, agreed enforcement actions, and a policy-tip/notice
sign-off; confirm simulation mode is available for the DLP policy.
**Implement:** Capture the exceptions and enforcement actions; **build the DLP policy in simulation mode**
until validation and sign-off are complete.

## 2.7 Unified audit logging on, and an access-evidence retention requirement
**Description:** `UnifiedAuditLogIngestionEnabled` must be **true** so the access-evidence control
captures who accessed/disclosed education records, plus a documented statement of how long audit
**evidence** must be retained.
**Why:** No audit evidence is written while ingestion is off, and it is **not retroactive**; retention
duration is a compliance determination (GR §5/§6).
**Verify:** `CMPFERPA-Discovery.ps1` reports `UnifiedAuditLogIngestionEnabled` and existing audit
retention policies.
**Implement:** Enable unified audit under change control (via the Purview Audit solution / Exchange
Online), then create the evidence-retention policy in Step 5 of the Implementation Guide.

## 2.8 A pilot scope, simulation/test mode, and change control
**Description:** A bounded **pilot scope** (`FERPA Pilot – Education Records – Stage1` — a small set of
registrar sites/mailboxes/users/devices) and a **change-control** window. The sensitivity label can be
published to the pilot first; DLP supports **simulation mode**; retention can be trialed on the pilot
scope; audit changes are reversible.
**Why:** DLP, labels, and retention are **high-impact** — so every change is piloted in
simulation/test/disabled mode before enforcement (GR §6).
**Verify:** A named pilot scope, confirmation that simulation/test/disabled mode is available for each
control, and a change window/approval path.
**Implement:** Define the pilot scope and agree change control before enforcing any control — **never move
a DLP policy from simulation to enforcement outside the pilot without explicit compliance/registrar
sign-off.**
