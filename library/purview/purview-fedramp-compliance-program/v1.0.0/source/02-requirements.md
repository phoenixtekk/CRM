# 2. Requirements Guide — Microsoft Purview FedRAMP Compliance Program

Verify **every** requirement before configuring. Each entry: **Description · Why · Verify ·
Implement-if-missing.** Category-wide prerequisites (tenant/licensing, Purview roles, the S&C
PowerShell + Graph toolchain, in-scope workloads, compliance/security/legal stakeholders, pilot &
change control) are in `global-requirements-purview.md` — this guide adds the FedRAMP-program detail.

> **Determination/licensing boundary.** Sensitivity labels with encryption, DLP, auto-classification,
> and Audit Premium require **Microsoft 365 E5** or the **E5 Compliance** add-on and evolve; confirm your
> entitlements rather than assuming. **Which FedRAMP baseline applies (Low/Moderate/High), which NIST
> 800-53 controls are in scope, which control a Purview object satisfies, and whether the tenant supports
> an ATO** are **security/compliance/legal determinations** — this solution configures the control and
> produces evidence; it does not make the determination and asserts no certification/ATO. Where this
> guide flags "verify your licensing/tenant" or "security/compliance to determine," do so before relying
> on the item.

## 2.1 Compliance licensing for information protection, DLP, and audit evidence
**Description:** The program spans three licensed control domains. **Sensitivity labels with
encryption** and **auto-classification** need **E5 / E5 Compliance**; **DLP** (advanced conditions,
endpoint DLP) needs **E5 / E5 Compliance**; **Audit Premium** (high-value events, long-term retention)
needs **E5 / E5 Compliance / Audit add-on**, assigned **per user**. Compliance Manager's **FedRAMP
assessment templates** (Moderate/High) may require premium templates.
**Why:** Every control below is plan-gated; the feature won't be available without the right plan (GR §1).
**Verify:** M365 admin center → `Billing → Licenses`; and run `CMPFEDRAMP-Discovery.ps1`, which reports
whether information-protection / DLP / Audit-Premium-bearing plans are present via Graph. **Confirm
plan/service-plan names against your tenant — they change.**
**Implement:** Assign/purchase E5 or the relevant add-ons to in-scope users before expecting the feature.

## 2.2 Least-privilege roles for labels, DLP, audit, and Compliance Manager
**Description:** Distinct least-privilege roles for each domain — **Information Protection** (Admin /
Analyst) for sensitivity labels & policies; **Compliance Administrator** / **DLP Compliance Management**
for DLP; **Records/Retention Management** for retention; **Audit Manager/Reader** for evidence;
**Compliance Manager** roles for the assessment. Global Administrator only where genuinely required.
**Why:** Purview uses fine-grained role groups; configuration requires the matching role, and
least-privilege is itself a control expectation (GR §2).
**Verify:** Purview portal → `Settings → Roles & scopes / Permissions` — confirm membership per domain;
`CMPFEDRAMP-Scope.ps1` reports the role groups it can see and connection identity.
**Implement:** Assign the least-privilege role groups under change control; reserve Global Administrator
for one-time enablement.

## 2.3 Security & Compliance PowerShell + Graph toolchain
**Description:** A workstation with the `ExchangeOnlineManagement` module (for `Connect-IPPSSession` —
sensitivity labels (`*-Label`/`*-LabelPolicy`), DLP (`*-DlpCompliancePolicy`/`*-DlpComplianceRule`),
retention (`*-RetentionCompliancePolicy`/`*-ComplianceTag`), and `*-UnifiedAuditLogRetentionPolicy`) and
`Microsoft.Graph` (licensing reads), with a modern-auth/MFA admin.
**Why:** All configuration and the provided scripts run through Security & Compliance PowerShell and
Graph (GR §3).
**Verify:** `Get-Module -ListAvailable ExchangeOnlineManagement`; `Connect-IPPSSession` and
`Connect-MgGraph` succeed; `CMPFEDRAMP-Discovery.ps1` reports which endpoints are reachable.
**Implement:** `Install-Module ExchangeOnlineManagement -Scope CurrentUser`;
`Install-Module Microsoft.Graph -Scope CurrentUser`.

## 2.4 In-scope controlled data, workloads, and classification intent
**Description:** The **controlled information** in scope (the data whose FedRAMP baseline drives the
program), the **workloads** holding it (Exchange, SharePoint, OneDrive, Teams, and — for endpoint DLP —
onboarded devices), and a **classification intent** (which sensitive info types / label defines
"controlled") to drive labels and DLP.
**Why:** Labels, DLP, and retention key off the in-scope controlled data, workloads, and the
classification scheme (GR §4).
**Verify:** Confirm the controlled-data definition, in-scope workloads/endpoints, and the classification
approach with security/compliance; `CMPFEDRAMP-Scope.ps1` enumerates the target group's members and the
mailboxes/sites in scope (read-only).
**Implement:** Define the controlled-data scope and classification intent before authoring controls.

## 2.5 The NIST-800-53-to-control map and control baseline (from security/compliance)
**Description:** A documented statement — **from security and compliance** — of the applicable FedRAMP
**baseline** (Low/Moderate/High), which **NIST SP 800-53 controls** (AC, AU, SC, MP, IA, CM, …) are in
scope, which are addressed by Purview data-centric mechanisms, and who approves.
**Why:** Baseline selection, control applicability, and whether a Purview object satisfies a control are
**security/compliance determinations**, not technical defaults (GR §5); the solution configures to them
and evidences them — it does not decide them.
**Verify:** You can name, per in-scope control, the NIST 800-53 identifier, the implementing Purview
object, and the named approver; these populate the `Control Map – FedRAMP – Purview` register.
**Implement:** Capture the control map, baseline, and approvals before configuring — especially before
applying **encryption** labels or **enforcing** DLP.

## 2.6 DLP simulation/test preconditions and endpoint onboarding
**Description:** For the DLP control specifically: agreement that DLP is built and validated in
**test/simulation mode** first (no blocking), the **sensitive info types / label** that define a match,
the intended **actions** at enforcement, and — if endpoint DLP is in scope — that devices are
**onboarded** to Purview.
**Why:** DLP can block real user actions; enforcing it blind is disruptive and risky (GR §6). Endpoint
DLP requires device onboarding before any endpoint condition works.
**Verify:** The match definition and intended actions are documented; `CMPFEDRAMP-Discovery.ps1` reports
existing DLP policies and their **mode**; device onboarding status is confirmed in-portal if endpoint DLP
is in scope.
**Implement:** Document the match/actions; onboard devices if needed; **build the policy in test mode**
until validation and sign-off are complete.

## 2.7 Unified audit logging on, and an evidence-retention requirement (NIST AU)
**Description:** `UnifiedAuditLogIngestionEnabled` must be **true** so the AU audit-trail control captures
evidence, plus a documented statement of how long audit **evidence** must be retained for the baseline.
**Why:** No audit evidence is written while ingestion is off, and it is **not retroactive**; retention
duration is a compliance determination (GR §5/§6).
**Verify:** `CMPFEDRAMP-Discovery.ps1` reports `UnifiedAuditLogIngestionEnabled` and existing audit
retention policies.
**Implement:** Enable unified audit under change control (via the Purview Audit solution / Exchange
Online), then create the evidence-retention policy in the Implementation Guide.

## 2.8 A pilot scope, simulation/test mode, and change control
**Description:** A bounded **pilot scope** (`FedRAMP Pilot – Controlled Data – Stage1` — a small set of
controlled-data owners/mailboxes/sites) and a **change-control** window. Sensitivity labels can be
trialed on benign content; DLP supports **test/simulation** mode; audit/retention changes are reversible.
**Why:** DLP, encryption labels, and retention are **high-impact** — so every change is piloted in
simulation/test/disabled mode before enforcement (GR §6).
**Verify:** A named pilot scope, confirmation that test/simulation/disabled mode is available for each
control, and a change window/approval path.
**Implement:** Define the pilot scope and agree change control before enabling, enforcing, or applying any
control — **never enforce DLP or apply encryption outside the pilot without explicit sign-off.**
