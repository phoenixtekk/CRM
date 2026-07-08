# Microsoft Purview FERPA Compliance Program

> **Version 1.0.0** · Category: Purview · Solution code: CMPFERPA

> This is the online, maintained copy of the implementation guide. When this solution is updated, eligible customers are alerted and can return here for the current content. Downloadable PDF + scripts are attached on the store listing.



---


# Executive Summary — Microsoft Purview FERPA Compliance Program

## The problem
For any institution holding student education records, an audit or a data-incident review comes down to
two demands: *"show me the control"* and *"show me the evidence."* FERPA obligations — protecting the
personally identifiable information in education records and governing its disclosure — too often exist as
policy on paper with no mapped technical control behind them and no evidence that can be produced on
demand. Left unaddressed, that is both a compliance gap and a data-risk exposure, and it surfaces at the
worst possible moment: after an unauthorized disclosure has already happened.

## The solution
A complete, self-guided FERPA **control-and-evidence program** built on **Microsoft Purview**. It maps
the in-scope obligations to three configured Purview controls — **classification & sensitivity labeling**
of education records, **Data Loss Prevention** against unauthorized disclosure, and **retention & Audit**
(the records lifecycle and access-evidence trail) — **pilots the high-impact ones in simulation/test/
disabled mode**, validates them, and produces an **evidence binder** (control → configuration → proof)
you can hand to an auditor. Five safe-by-default PowerShell tools (read-only or `-WhatIf` until you
commit) do the assessment, scoping, configuration, validation, and evidence reporting.

## What you get
- **An obligation-to-control register** — every in-scope FERPA obligation mapped to the Purview object that implements it, with the classification/DLP/retention scope, permitted-disclosure exceptions, and a named approver.
- **Education-record classification & protection** — sensitive information types / trainable classifiers and a `Protect – FERPA Education Records – Confidential` sensitivity label that marks and, where designed, encrypts education-record data across email, files, and Teams.
- **Disclosure prevention, simulation-first** — a DLP policy built **in simulation mode** with permitted-disclosure exceptions, validated across Exchange/SharePoint/OneDrive/Teams/Endpoint, and enforced only under compliance/registrar sign-off.
- **A records lifecycle and access-evidence trail** — retention on education records, and unified audit with a long-term retention policy keeping the evidence of who accessed and disclosed records.
- **An audit-ready evidence binder** — control → configuration → proof, regenerated on a cadence so it is always current.

## Approach
Delivery follows a disciplined, reversible model — **Assess → Design → Configure → Pilot (simulate/test)
→ Validate → Expand (enforce)** — piloting every high-impact control on a limited scope before
enforcement, with pass/fail gates and documented rollback. The disclosure-prevention DLP control is
built and validated **in simulation mode** and moved to enforcement only under explicit
compliance/registrar sign-off on the approved scope.

## Boundaries
Microsoft Purview is **licensing-/plan-dependent** (auto-labeling, advanced/endpoint DLP, trainable
classifiers, and Audit Premium require E5 or the E5 Compliance add-on) and the portal is **actively
evolving** — capabilities and paths are cited or flagged **"verify your licensing/tenant,"** never
assumed. Above all: **which data are education records, who are eligible students and school officials,
which disclosures are permitted, retention adequacy, and whether a configuration satisfies FERPA (34 CFR
Part 99) are deferred to your compliance, registrar, records, privacy, and legal functions** — this
solution provides the technical control and the evidence, not the determination, and makes no
certification claim.

## The bottom line
A FERPA program that is **configured, piloted, validated, and evidenced** in Microsoft Purview — so when
an auditor or a parent asks to see the control and the proof, both are already in hand.


---


# 1. Solution Overview — Microsoft Purview FERPA Compliance Program

## What this solution is
An education institution or any organization holding student education records lives under one recurring
demand from a regulator, an auditor, or a parent: *"Show me the control"* and *"Show me the evidence."*
FERPA obligations — protecting the personally identifiable information (PII) in student education records
and governing its **disclosure** — need to be **mapped to concrete controls**, those controls
**configured**, and the whole thing **evidenced** in a form you can produce on demand. This solution
builds that program on **Microsoft Purview**: it maps the technical control surface (classification &
labeling of education records, data-loss prevention of unauthorized disclosure, and retention/audit
evidence of access) to a FERPA-aligned control register, **configures** the controls in Purview,
**pilots the high-impact ones in simulation/test/disabled mode first**, validates, and produces an
**evidence binder** you can defend. It uses only the **Microsoft Purview portal**
(`purview.microsoft.com`), **Security & Compliance PowerShell** (`Connect-IPPSSession`), and
**Microsoft Graph** — no third-party tooling.

> **This is a technical-control-and-evidence program, not a legal opinion.** *Which* data are "education
> records," who are "eligible students" and "school officials with a legitimate educational interest,"
> which disclosures are permitted, and whether any given configuration *satisfies* FERPA (34 CFR Part 99)
> are **compliance, registrar, records, and legal determinations** deferred to your **compliance,
> registrar/records, privacy, and legal functions**. This solution provides the Purview method, the
> configured control, and the evidence — **not** the determination that it meets FERPA.

## Why this matters
- **Unauthorized disclosure is the core FERPA risk, and it is preventable.** FERPA governs the disclosure of PII from education records. Purview **Data Loss Prevention (DLP)** is the Microsoft control that detects and blocks that disclosure across email, files, Teams, and endpoints — but it is **high-impact**, which is why it is always **piloted in simulation mode** before any enforcement.
- **You cannot protect what you have not identified.** Education records must first be **classified** — with **sensitive information types**, trainable classifiers, and **sensitivity labels** — so DLP, retention, and encryption controls have something to key off. Classification is the foundation control.
- **Evidence is the deliverable auditors actually want.** A control that works but can't be *shown* to work fails a review. This solution's reporting produces a **control-to-configuration-to-evidence** binder so "the control is in place" is provable, not asserted, and access to records is auditable.
- **The controls are licensing-dependent and evolving.** Auto-labeling, advanced/endpoint DLP, trainable classifiers, and Audit Premium require **Microsoft 365 E5** or the **E5 Compliance** add-on; the portal and tooling change. Capabilities are **cited or flagged "verify your licensing/tenant"**, never assumed.

## How it works
1. **Assess.** Discover what you already have — compliance licensing/plans, the least-privilege roles, existing sensitivity labels, DLP policies, sensitive information types, retention labels/policies, unified-audit state, and audit retention — so the program is built on facts, not assumptions.
2. **Design the control map.** With compliance/registrar/records/legal, map the in-scope FERPA obligations to the three Purview control domains (classify & label education records, DLP against unauthorized disclosure, retention & audit evidence) and to the **named artifacts** below. Which data are education records and which disclosures are permitted are the institution's determinations; this solution provides the register structure and the technical control.
3. **Configure — in simulation/test first.** Create the education-record sensitivity label and publish policy, the DLP policy **in simulation mode**, the education-record retention policy, and the audit evidence-retention policy. Every high-impact change is piloted simulated/disabled before enforcement.
4. **Pilot & validate.** Prove the label applies and protects, DLP matches education records and generates simulation events (in simulation mode) without blocking users, retention holds, and audit evidence is retained — on a bounded **pilot scope** before tenant-wide enforcement.
5. **Produce the evidence.** Generate the control-mapping + evidence binder (control → Purview object → configuration → proof) for the compliance/audit file.
6. **Expand & operate.** Move DLP from simulation to enforcement on the approved scope, schedule the read-only re-assessment so drift is caught, and hand the binder and runbook to the compliance/registrar function as a standing procedure.

## The control stack this solution configures
- **Classification & sensitivity labels** — **sensitive information types** / **trainable classifiers** that recognize education-record PII, and a **sensitivity label** (`Protect – FERPA Education Records – Confidential`) that marks and, where designed, encrypts education-record data across Exchange, SharePoint, OneDrive, and Teams — the identification-and-protection control.
- **Data Loss Prevention (DLP)** — the policy that detects and (once enforced) blocks unauthorized disclosure of education records across **Exchange, SharePoint, OneDrive, Teams, and Endpoint**, built and validated **in simulation mode** first — the disclosure-prevention control. *High-impact.*
- **Data lifecycle & retention** — retention **labels/policies** governing how long education records are kept and when they are disposed — the records-lifecycle control.
- **Audit (Standard/Premium)** — unified audit logging and **audit log retention policies** keeping the evidence of who accessed/disclosed what — the access-evidence control.
- **Compliance Manager** — a FERPA **assessment** (`Assessment – FERPA Controls – Program`) that tracks improvement actions and scores control implementation — the control-tracking layer (configured in-portal; applicability determination is compliance's).

## What you can control
- Which **sensitive information types / classifiers** and the **sensitivity label** identify and protect education records, and their scope.
- The **DLP policy** scope, conditions, and actions — built and validated in **simulation mode** first, enforced only after sign-off.
- Which **retention labels/policies** govern the education-record lifecycle and disposition.
- Which record types/operations/users get **extended audit retention** as access evidence.
- The **control register** (which FERPA obligation maps to which Purview object) and the **evidence binder** contents.
- The **pilot scope** validated in simulation/test/disabled mode before any enforcement.

## Limitations (be honest with buyers)
- **We configure the control; we do not make the determination.** What is an "education record," who is an "eligible student" or a "school official," which disclosures are permitted (consent, directory information, health/safety emergency, audit/evaluation), and whether a configuration satisfies FERPA are **compliance/registrar/records/legal** determinations. **Verify with your governance functions.**
- **DLP is high-impact and must be piloted in simulation.** An enforced DLP policy can block legitimate work if mis-scoped; it is always built in **simulation mode**, validated, and enforced only under sign-off on an approved scope, with a documented rollback.
- **Protection is largely not retroactive.** Labels, DLP, and retention policies act from application/enable forward; they do not reach back to reclassify or recover history that wasn't captured.
- **Classification accuracy needs tuning.** Sensitive information types and trainable classifiers produce false positives/negatives; the pilot exists to tune them before enforcement, and the adequacy of the match logic is a compliance/registrar decision, not a technical default.
- **No certification claim.** This solution does not assert FERPA compliance or certify the institution; it delivers the technical control configuration and the evidence. **Rule applicability and adequacy are your governance functions' determinations.**

## Naming convention (used in every doc and script)
Every artifact this solution creates is named `<Purpose> – <Scope> – <Stage>` and reused verbatim
across the docs, scripts, and portal. The standard set:

| Artifact | Name |
|---|---|
| Education-record sensitivity label | `Protect – FERPA Education Records – Confidential` |
| Sensitivity-label publish policy | `Protect – FERPA Education Records – Publish` |
| DLP policy (simulation-first) | `DLP – FERPA Education Records – Simulate` |
| Education-record retention policy | `Retention – FERPA Records – Publish` |
| Audit evidence retention policy | `Audit Retention – FERPA Evidence – LongTerm` |
| Compliance Manager assessment | `Assessment – FERPA Controls – Program` |
| Disposition-review stage | `Disposition – FERPA Records – Review` |
| Control-mapping register | `Control Map – FERPA – Purview` |
| Evidence binder export | `Evidence – FERPA Controls – Binder` |
| Pilot validation scope | `FERPA Pilot – Education Records – Stage1` |

## The standard deployment model
> Assess the controls and licensing you have → design the FERPA-obligation-to-control map with
> compliance/registrar/legal → configure classification & labels, DLP, and retention & audit evidence →
> **pilot in simulation/test/disabled mode** on a limited scope → validate the controls work and produce
> evidence → expand to enforcement. Pattern: **Assess → Design → Configure → Pilot (simulate/test) →
> Validate → Expand (enforce).** High-impact controls (DLP, labels, retention) are always piloted before
> enforcement.


---


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


---


# Global Requirements — Microsoft Purview Solutions

These requirements apply to **every** solution in the **Purview** category (implementing and managing
Microsoft Purview, sensitivity & retention labels, DLP, data lifecycle & records, insider risk,
communication compliance, audit, data security posture management, and data governance). Verify each
before starting a solution's implementation steps.

> **Vendor boundary (applies to every Purview solution).** The **Microsoft Purview portal**
> (purview.microsoft.com), the **Microsoft 365 admin center**, **Security & Compliance PowerShell**
> (`Connect-IPPSSession`), and **Microsoft Graph** are authored at exact, current click-by-click /
> cmdlet detail from Microsoft's public documentation. Microsoft Purview features are heavily
> **licensing-/plan-dependent** (many require **Microsoft 365 E5** or the **E5 Compliance** add-on;
> some are in preview) and the portal is **actively evolving** — capability availability and portal
> paths are **cited or flagged "verify your licensing/tenant"**, never asserted or invented.
> **Regulatory, records-retention, and legal determinations** (retention schedules, records file plans,
> legal holds, insider-risk case actions, regulatory applicability) are **deferred to the organization's
> compliance, records, privacy, and legal functions** — the solutions provide the technical
> configuration method and evidence, not the determination. Automation is **PowerShell** (Security &
> Compliance PowerShell / Graph) — never with hardcoded credentials or secrets.

## 1. Microsoft 365 tenant with the required Purview/compliance licensing
- **Description:** A Microsoft 365 tenant with the **compliance licensing** the capability requires
  (E3 for baseline; **E5 / E5 Compliance** for advanced DLP, auto-labeling, insider risk, communication
  compliance, Audit Premium, DSPM, etc.).
- **Why required:** Most Purview capabilities are plan-gated; the feature won't be available without the
  right plan.
- **How to verify:** In the M365 admin center confirm the subscription/add-ons; check the feature is
  visible in the Purview portal.
- **How to implement if missing:** Assign/purchase the required licensing before starting.

## 2. Purview roles (least-privilege) and portal access
- **Description:** Access with the least-privilege **Purview / compliance role** the solution names
  (e.g. Compliance Administrator, Compliance Data Administrator, Information Protection, Records
  Management, Insider Risk, eDiscovery, Audit roles), with Global Administrator only where required.
- **Why required:** Purview uses fine-grained role groups; configuration requires the matching role.
- **How to verify:** Purview portal → **Roles & scopes / Permissions** — confirm the role membership.
- **How to implement if missing:** Assign the least-privilege role group under change control.

## 3. Security & Compliance PowerShell + Graph toolchain
- **Description:** A workstation with **Security & Compliance PowerShell** (`Connect-IPPSSession` via the
  ExchangeOnlineManagement module) and **Microsoft Graph PowerShell**, modern-auth / MFA-capable admin.
- **Why required:** Configuration, automation, and the provided scripts run through these.
- **How to verify:** `Connect-IPPSSession` and `Connect-MgGraph` succeed with the admin account.
- **How to implement if missing:** Install the modules and confirm modern-auth sign-in before running steps.

## 4. Data sources & scope in scope
- **Description:** The **workloads and data sources** in scope (Exchange, SharePoint, OneDrive, Teams,
  endpoints/devices, and — for data governance — the broader data estate) and a **data-classification /
  sensitivity** intent to drive labels, DLP, and retention.
- **Why required:** Purview policies key off the in-scope workloads and the classification scheme.
- **How to verify:** Confirm the in-scope workloads and the classification/sensitivity approach with
  stakeholders.
- **How to implement if missing:** Define the scope and classification intent before authoring policies.

## 5. Compliance, records, privacy & legal stakeholders
- **Description:** Engagement with the **compliance, records-management, privacy, security, and legal**
  stakeholders whose policies the configuration must satisfy (retention schedules, records file plans,
  regulatory obligations, insider-risk and communication-compliance policy, legal hold).
- **Why required:** Purview configuration must align to enterprise policy and legal/records requirements,
  not technical defaults; several capabilities have HR/legal sensitivity.
- **How to verify:** Confirm the applicable policies, the records schedule, and named approvers.
- **How to implement if missing:** Identify the owners and capture the requirements before configuring.

## 6. A pilot scope and change control
- **Description:** A **pilot scope** (users/sites/policies in simulation or a limited ring) to validate
  on before tenant-wide enforcement, and a **change-control** process — most Purview policies support a
  **simulation / test / disabled** mode that MUST be used before enforcement.
- **Why required:** Every solution follows an **Assess → Design → Configure → Pilot (simulate) → Validate
  → Expand (enforce)** model; DLP, labels, retention, and insider-risk changes are high-impact.
- **How to verify:** Confirm a named pilot scope, that simulation/test mode is available, and a change
  window/approval path.
- **How to implement if missing:** Define the pilot and agree change control before enforcing anything.

*The deployment model across every Purview solution is the same: **Assess → Design → Configure → Pilot
(simulate/test) → Validate → Expand (enforce)**, with explicit pass/fail gates and a documented rollback.
Automation is delivered as **PowerShell** (Security & Compliance PowerShell / Graph) — never with
hardcoded credentials or secrets. Regulatory/records/legal determinations are deferred to the relevant
governance functions.*


---


# 3. Implementation Guide — Microsoft Purview FERPA Compliance Program

Follow these steps **in order**. Configuration uses the **Microsoft Purview portal**
(`https://purview.microsoft.com`), **Security & Compliance PowerShell** (`Connect-IPPSSession` — the
`*-Label`/`*-LabelPolicy`, `*-DlpCompliancePolicy`/`*-DlpComplianceRule`,
`*-RetentionCompliancePolicy`/`*-ComplianceTag`, and `*-UnifiedAuditLogRetentionPolicy` cmdlets), and
**Microsoft Graph** (licensing). Every write is gated: scripts run **read-only or `-WhatIf` by default**
and only change state with `-Commit`. Artifact names follow the `<Purpose> – <Scope> – <Stage>`
convention from the Overview and are reused verbatim.

> **Model:** Assess the controls/licensing you have → design the obligation-to-control map with
> compliance/registrar/legal → configure classification & labels, DLP, and retention & audit evidence →
> **pilot in simulation/test/disabled mode** → validate and evidence → expand to enforcement. Pattern:
> **Assess → Design → Configure → Pilot (simulate/test) → Validate → Expand (enforce).**
>
> **Determination boundary:** which data are education records, which disclosures are permitted, retention
> durations, and whether a configuration *satisfies* FERPA are **compliance/registrar/records/legal**
> determinations. This guide configures the control and evidences it; it does not make the determination.
> **A DLP policy is enforced only after it passes in simulation and compliance/registrar signs off —
> never enforce outside the pilot without sign-off.**

## Step 1 — Assess current controls and licensing (Assess)
1. Run `CMPFERPA-Discovery.ps1` (read-only). It connects to Security & Compliance PowerShell and Graph and reports:
   - compliance licensing present (information-protection / DLP / Audit-Premium-bearing plans — **verify plan names for your tenant**),
   - existing **sensitivity labels** (`Get-Label`) and **label policies** (`Get-LabelPolicy`),
   - existing **DLP policies** (`Get-DlpCompliancePolicy`), flagging any in **enforce** vs **simulation/test** mode,
   - existing **retention labels** (`Get-ComplianceTag`) and **retention policies** (`Get-RetentionCompliancePolicy`),
   - available **sensitive information types** relevant to education records (`Get-DlpSensitiveInformationType`),
   - `UnifiedAuditLogIngestionEnabled` and existing **audit retention policies** (`Get-UnifiedAuditLogRetentionPolicy`).
2. Run `CMPFERPA-Scope.ps1` (read-only) to enumerate the intended in-scope education-record locations, mailboxes/sites, device-onboarding state, and the role groups it can see (Requirement 2.2/2.4).
3. Record the gaps against the three control domains. **Pass gate:** a written current-state for classification, DLP, and retention/audit.

## Step 2 — Design the obligation-to-control map (Design)
1. With compliance/registrar/records/legal (Requirement 2.5), populate the `Control Map – FERPA – Purview` register: for each in-scope obligation, name the Purview control object that implements it, the classification/DLP/retention scope, the permitted-disclosure exceptions, and the approver. **What is an education record and which disclosures are permitted are the institution's determinations; you provide the register and the technical control.**
2. Map the obligations to the standard named artifacts:
   - Identify & protect → `Protect – FERPA Education Records – Confidential` (sensitivity label) + `Protect – FERPA Education Records – Publish` (label publish policy), keyed off the education-record **sensitive information types / trainable classifiers**.
   - Prevent disclosure → `DLP – FERPA Education Records – Simulate` (DLP policy, built in simulation).
   - Records lifecycle → `Retention – FERPA Records – Publish` (retention policy) + `Disposition – FERPA Records – Review` (disposition stage).
   - Access evidence → `Audit Retention – FERPA Evidence – LongTerm`.
   - Control tracking → `Assessment – FERPA Controls – Program` (Compliance Manager).
3. Define the pilot scope `FERPA Pilot – Education Records – Stage1` (Requirement 2.8) and the permitted-disclosure exceptions for DLP (Requirement 2.6). **Pass gate:** the control map, records schedule, disclosure exceptions, pilot, and approvals are documented.

## Step 3 — Configure the classification & labeling control (Configure → Pilot)
1. Confirm the education-record **sensitive information types / trainable classifiers** exist and match your data (Requirement 2.4). Create the sensitivity label and publish it to the pilot with the helper, `-WhatIf` first (prints the exact `New-Label`/`New-LabelPolicy` it would run):
   - `CMPFERPA-Configure.ps1 -Control Label -WhatIf` → review → `-Commit` (creates `Protect – FERPA Education Records – Confidential` and publishes it via `Protect – FERPA Education Records – Publish` scoped to the pilot).
2. Validate the label appears to pilot users and applies to education-record content (Testing Gate 2). Where the design calls for **encryption/marking**, confirm the label's protection settings in-portal before wider publish. **Pass gate:** the label exists, is published to the pilot, and applies. **Rollback:** unpublish/remove via `-Control Label -Remove -Commit`.

## Step 4 — Configure the disclosure-prevention (DLP) control — IN SIMULATION (Configure → Pilot)
1. **Build the DLP policy in simulation mode.** The helper creates it in test/simulation, scoped to the pilot locations, matching the education-record sensitive information types / the sensitivity label, with the **permitted-disclosure exceptions** you supply (Requirement 2.6):
   - `CMPFERPA-Configure.ps1 -Control DLP -PilotScope "FERPA Pilot – Education Records – Stage1" -WhatIf` → review → `-Commit` (creates `DLP – FERPA Education Records – Simulate` via `New-DlpCompliancePolicy -Mode Enable` in **TestWithoutNotifications/simulation** and `New-DlpComplianceRule` with the conditions your compliance/registrar function specified — **the match logic and exceptions are compliance's determination**).
2. Confirm the policy generates **simulation events** against benign education-record test content across the in-scope workloads **without blocking users**, and that permitted-disclosure exceptions suppress false positives. **Do not enforce tenant-wide; do not switch to block until validation passes and sign-off is complete.**
3. **Pass gate:** the DLP policy exists in **simulation**, is scoped to the pilot, and surfaces expected matches with acceptable false-positive rate. **Rollback:** disable/remove the policy (`-Control DLP -Remove -Commit`); no user content is altered by a simulation-mode policy.

## Step 5 — Configure the retention & audit-evidence controls (Configure)
1. **Retention.** Create the education-record retention policy pilot-first (`-Control Retention`): `CMPFERPA-Configure.ps1 -Control Retention -WhatIf` → review → `-Commit` (creates `Retention – FERPA Records – Publish` at the duration your records schedule requires; **verify accepted `RetentionDuration` values**). Where disposition review is required, configure `Disposition – FERPA Records – Review`.
2. **Audit evidence.** Confirm unified audit is on (Requirement 2.7). Create the evidence-retention policy pilot-first: `CMPFERPA-Configure.ps1 -Control Audit -PolicyName "Audit Retention – FERPA Evidence – LongTerm" -WhatIf` → review → `-Commit` (creates a `New-UnifiedAuditLogRetentionPolicy` for the record types/operations your compliance function requires as access evidence, at the agreed duration and a unique priority). **Verify accepted `RetentionDuration` values and that the long-term tier is licensed** (Requirement 2.1).
3. **Pass gate:** `CMPFERPA-Discovery.ps1` lists the retention and audit policies with the expected duration/scope/priority. **Rollback:** `-Control Retention -Remove -Commit` / `-Control Audit -PolicyName "…" -Remove -Commit` (already-retained records age out under remaining rules).

## Step 6 — Track the program in Compliance Manager (Configure, in-portal)
1. In the Purview portal → **Compliance Manager**, create/assign the assessment `Assessment – FERPA Controls – Program` from a FERPA-relevant **assessment template** (**template availability depends on your licensing — verify in-portal**). Map its improvement actions to the Purview controls configured above.
2. Record, per improvement action, the implementing Purview object and its evidence location (this cross-links to the `Control Map – FERPA – Purview` register). **Pass gate:** the assessment reflects the configured controls with evidence links. *(Compliance Manager assessment content and applicability are compliance's determination; no cmdlet invents this — it is authored in-portal.)*

## Step 7 — Validate the controls and generate evidence (Validate)
1. Run `CMPFERPA-Validate.ps1` (read-only) to score the program across gates: the education-record label present and published, the DLP policy present in **simulation** with exceptions, retention scoped, audit ingestion on with the evidence policy in place, and the pilot scope covered.
2. Run `CMPFERPA-Report.ps1` (read-only) to produce `Evidence – FERPA Controls – Binder` — a control → Purview object → configuration → proof export (CSV/JSON) for the compliance/audit file, cross-referenced to `Control Map – FERPA – Purview`.
3. Complete the **Testing Guide** before expanding. **Pass gate:** the validation scorecard is green for the pilot scope and the evidence binder is generated.

## Step 8 — Expand to enforcement and operationalize (Expand)
1. Once the pilot passes and compliance/registrar signs off, expand scope: publish the sensitivity label to the full in-scope population, extend retention and audit-evidence policies, and **move the DLP policy from simulation to enforcement** (block / block-with-override per the approved actions) on the approved scope — each under change control.
2. Configure the `Disposition – FERPA Records – Review` stage so end-of-retention disposal is reviewed, not automatic (where the records schedule requires disposition review).
3. Schedule the read-only chain (`CMPFERPA-Discovery.ps1` → `CMPFERPA-Validate.ps1` → `CMPFERPA-Report.ps1`) on a cadence so drift — a DLP policy reverted to simulation or disabled, a removed label scope, a lapsed license, audit turned off — is caught, and re-generate the evidence binder before each audit. **Pass gate:** controls enforced on the approved scope, evidence binder current, monitoring cadence scheduled. Hand the register, binder, and runbook to the compliance/registrar function as the standing procedure.


---


# 5. Testing & Validation — Microsoft Purview FERPA Compliance Program

Work through every gate. Each has a **method**, an **expected result (pass)**, and a **fail action**.
Tests are read-only or use **benign, self-generated pilot content** — no production education records
are exposed and no user is blocked (DLP stays in simulation). Do not declare "FERPA-ready" until every
gate passes for the pilot scope, then re-confirm on expand.

> **Boundary:** these gates prove the **technical control works and is evidenced**. Whether the control
> **satisfies** FERPA — whether the classified data are the right education records, whether the DLP
> match logic and permitted-disclosure exceptions are adequate, whether retention meets the schedule —
> is a **compliance/registrar/records/legal determination**, not a test outcome. **Never enforce a DLP
> policy as part of testing — keep it in simulation until sign-off.**

## Gate 1 — Compliance licensing present for each control
- **Method:** `CMPFERPA-Discovery.ps1` licensing section (Graph `subscribedSkus` / service plans).
- **Pass:** information-protection/DLP (incl. Endpoint if in scope) and Audit Premium-bearing plans are present and assigned to the in-scope population.
- **Fail:** assign the license (Requirement 2.1); a missing plan makes the corresponding control unavailable — that is a licensing gap, not a config defect. **Verify plan names for your tenant.**

## Gate 2 — Sensitivity label applies to education records (pilot)
- **Method:** confirm `Protect – FERPA Education Records – Confidential` is published to the pilot (`Get-Label`/`Get-LabelPolicy`), then apply it to benign pilot education-record content and confirm it takes (and, if designed, encrypts/marks).
- **Pass:** the label appears to pilot users, applies, and `Get-Label` shows the expected settings.
- **Fail:** confirm label publish scope, availability latency, and the sensitive-info-type/classifier match; retest.

## Gate 3 — Education-record classification matches (SIT / classifier)
- **Method:** `CMPFERPA-Discovery.ps1` sensitive-info-types section; test benign content containing education-record patterns (student ID, grades) against the chosen SIT/classifier.
- **Pass:** the in-scope sensitive information types / trainable classifiers exist and match the education-record test content at an acceptable rate.
- **Fail:** tune the SIT/classifier or select a better match; **match-logic adequacy is compliance/registrar's determination, not a test.**

## Gate 4 — DLP policy present IN SIMULATION with disclosure exceptions
- **Method:** `CMPFERPA-Discovery.ps1` / `CMPFERPA-Validate.ps1` — confirm `DLP – FERPA Education Records – Simulate` (`Get-DlpCompliancePolicy`) is in **simulation/test** mode (not enforce), scoped to the pilot locations, with the permitted-disclosure exceptions configured.
- **Pass:** the DLP policy exists, is in simulation, pilot-scoped, and carries the exceptions.
- **Fail:** correct the mode/scope/exceptions; **do not switch to enforce**. Confirm the exceptions with compliance/registrar (determination).

## Gate 5 — DLP surfaces simulation matches without blocking (benign)
- **Method:** generate **benign test content** matching the policy conditions across the in-scope workloads (email, SharePoint/OneDrive, Teams, endpoint if in scope); confirm simulation events appear and **no user is blocked**.
- **Pass:** simulation matches are generated, false positives are within the agreed tolerance, and no enforcement action fires.
- **Fail:** confirm conditions/scope and ingestion latency; adjust exceptions and retest. A high false-positive rate is a tuning task before enforcement.

## Gate 6 — Retention policy scoped
- **Method:** `CMPFERPA-Discovery.ps1` / portal — confirm `Retention – FERPA Records – Publish` covers the in-scope education-record locations for the pilot at the agreed duration.
- **Pass:** the retention policy exists, is enabled, and covers the intended locations at the agreed duration.
- **Fail:** correct locations/duration with `CMPFERPA-Configure.ps1 -Control Retention`; re-verify. Confirm the duration against the records schedule (determination).

## Gate 7 — Unified audit on and evidence policy present
- **Method:** `CMPFERPA-Discovery.ps1` audit section (`UnifiedAuditLogIngestionEnabled`, `Get-UnifiedAuditLogRetentionPolicy`).
- **Pass:** ingestion is `True` and `Audit Retention – FERPA Evidence – LongTerm` exists with the agreed duration and a unique priority.
- **Fail:** enable ingestion under change control; create/correct the policy (Implementation Step 5); verify the `RetentionDuration` value and licensing.

## Gate 8 — Control map and evidence binder generated
- **Method:** `CMPFERPA-Report.ps1` → `Evidence – FERPA Controls – Binder`, cross-referenced to `Control Map – FERPA – Purview`.
- **Pass:** every in-scope obligation maps to a Purview object with its configuration and a proof reference; the binder exports cleanly.
- **Fail:** fill the gap (missing control or missing evidence) and re-run. A control with no evidence fails an audit.

## Gate 9 — Validation scorecard is green (pilot)
- **Method:** `CMPFERPA-Validate.ps1`.
- **Pass:** every gate above is green for the pilot scope (and, on expand, for the approved production scope with DLP enforced).
- **Fail:** address the specific red item and re-run before enforcing anything.

## Evidence to retain
- `CMPFERPA-Discovery.ps1` and `CMPFERPA-Validate.ps1` outputs (before/after).
- The `-WhatIf` transcripts for every label, DLP, retention, and audit change.
- The `Evidence – FERPA Controls – Binder` export and the `Control Map – FERPA – Purview` register.
- The compliance/registrar sign-offs (education-record scope, permitted-disclosure exceptions, DLP enforcement, retention schedule) and the pilot roster/approvals (Requirement 2.5/2.6/2.8).

> Education-record scope, DLP match/exception adequacy, retention adequacy, and rule applicability are
> **compliance/registrar/records/legal determinations** — these gates prove the Purview controls work and
> are evidenced, not that the program satisfies FERPA.


---


# 6. Troubleshooting — Microsoft Purview FERPA Compliance Program

Symptom → likely cause → fix, for the failure modes this program hits most. Diagnosis is read-only
(`CMPFERPA-Discovery.ps1` / `CMPFERPA-Validate.ps1`); fixes go through `CMPFERPA-Configure.ps1`
(`-WhatIf` first, `-Commit` to apply). Remember the boundary: these are **technical** fixes — whether a
configuration satisfies FERPA is a **compliance/registrar/records/legal determination**.

## The sensitivity label doesn't appear to pilot users
- **Cause:** the label isn't published, the publish policy is disabled or scoped to the wrong users, or label-availability latency (publishing can take time to propagate to clients).
- **Fix:** `CMPFERPA-Discovery.ps1` → confirm `Protect – FERPA Education Records – Confidential` exists (`Get-Label`) and `Protect – FERPA Education Records – Publish` is enabled and scoped to the pilot (`Get-LabelPolicy`). Correct scope with `CMPFERPA-Configure.ps1 -Control Label`; allow propagation time, then re-test (Gate 2).

## Classification misses education records (false negatives) or over-matches (false positives)
- **Cause:** the chosen **sensitive information types / trainable classifiers** don't match your education-record patterns (student IDs, grades, disciplinary/health records), or match too broadly.
- **Fix:** `CMPFERPA-Discovery.ps1` sensitive-info-types section lists candidates; tune the SIT/classifier or build a **custom SIT** for your student-ID format. This is exactly what the **pilot** is for — measure and tune before enforcement. **Match-logic adequacy is compliance/registrar's determination, not a technical default.**

## DLP policy fires on legitimate, permitted disclosures
- **Cause:** the **permitted-disclosure exceptions** (to the student, to school officials with legitimate educational interest, under consent, directory information) aren't encoded, so authorized sharing is flagged.
- **Fix:** add the exceptions to `DLP – FERPA Education Records – Simulate` in-portal (they are compliance/registrar's determination), keep the policy **in simulation**, and re-measure the false-positive rate (Gate 5). Only enforce once the rate is acceptable **and** sign-off is complete.

## DLP is blocking users during testing
- **Cause:** the policy was moved to **enforce** (block) instead of staying in **simulation** — DLP is high-impact and the pilot must stay in simulation until sign-off.
- **Fix:** revert the policy to simulation/test mode (`CMPFERPA-Validate.ps1` flags the mode; the Configure helper creates it in `TestWithoutNotifications`). Never enforce outside the pilot without explicit compliance/registrar sign-off. This is the documented rollback for the disclosure-prevention control.

## `Get-DlpCompliancePolicy` shows the FERPA policy as ENFORCING unexpectedly
- **Cause:** an in-portal edit switched the mode, or the policy was created enforcing.
- **Fix:** confirm whether enforcement was **signed off** and recorded with the evidence binder. If not, revert to simulation. `CMPFERPA-Validate.ps1` gates this specifically — a policy enforcing without recorded sign-off is a governance finding.

## Endpoint DLP doesn't match on devices
- **Cause:** devices aren't **onboarded** to Purview, or Endpoint DLP isn't licensed (needs E5 / E5 Compliance).
- **Fix:** confirm licensing (`CMPFERPA-Discovery.ps1` licensing section) and device onboarding (Purview portal → Settings → Device onboarding; `CMPFERPA-Scope.ps1` flags this). Endpoint is a separate location in the DLP policy — verify it's in scope. **Verify feature availability for your tenant.**

## Retention policy not applying to education records
- **Cause:** the policy is disabled, scoped to the wrong locations, or the retention duration doesn't match the records schedule.
- **Fix:** `CMPFERPA-Discovery.ps1` / `CMPFERPA-Validate.ps1` → confirm `Retention – FERPA Records – Publish` is enabled and covers the in-scope locations. Correct with `CMPFERPA-Configure.ps1 -Control Retention`. **Confirm the duration against the records schedule (compliance/registrar determination), not a technical default.**

## Unified audit shows no access evidence
- **Cause:** `UnifiedAuditLogIngestionEnabled` is **False**; no audit evidence is captured while ingestion is off, and it is **not retroactive**.
- **Fix:** enable unified audit under change control (Purview Audit solution / Exchange Online), then create `Audit Retention – FERPA Evidence – LongTerm` (Implementation Step 5). Re-run `CMPFERPA-Discovery.ps1` to confirm ingestion is on (Gate 7).

## `Get-AdminAuditLogConfig` fails in the Security & Compliance session
- **Cause:** `Get-AdminAuditLogConfig` runs in **Exchange Online PowerShell**, not the Security & Compliance session — a common endpoint confusion.
- **Fix:** `Connect-ExchangeOnline` for the audit-config read; the validation script already attempts this fallback. Keep the two sessions distinct (S&C PowerShell for labels/DLP/retention/audit-retention; Exchange Online for `Get-AdminAuditLogConfig`).

## A licensing check reports a plan "NOT found"
- **Cause:** the indicative **service-plan name** in the discovery script doesn't match your tenant's naming, or the plan genuinely isn't licensed. Plan names change over time.
- **Fix:** treat the check as **indicative** — verify the actual entitlement in the M365 admin center (`Billing → Licenses`). If genuinely unlicensed, the corresponding control (auto-labeling, Endpoint DLP, Audit Premium) is unavailable until assigned — a **licensing gap, not a config defect**. **Verify plan names for your tenant.**

## The evidence binder shows a control MISSING
- **Cause:** the control isn't configured, or it's named differently from the register.
- **Fix:** `CMPFERPA-Report.ps1` marks each control PRESENT/MISSING; a MISSING control has no proof and **fails an audit**. Configure the missing control (Implementation Guide) or reconcile the artifact name to the `Control Map – FERPA – Purview` register, then re-run. Retain the binder with the `-WhatIf` transcripts and sign-offs.

## A cmdlet name or parameter isn't recognized
- **Cause:** Purview cmdlets, `-Mode` values, and `-RetentionDuration` values are **tenant-/version-dependent and evolving**; the portal changes.
- **Fix:** **verify the exact cmdlet, parameter, and accepted values against current Microsoft documentation and your tenant** before committing. The scripts are safe-by-default (`-WhatIf`) precisely so you can preview the exact command and confirm it before any change. Do not force a command whose behavior you can't confirm.

> **Boundary reminder:** these fixes restore the **technical control**. Education-record scope,
> permitted-disclosure/DLP-exception adequacy, retention adequacy, and whether the program satisfies FERPA
> (34 CFR Part 99) are **compliance/registrar/records/legal determinations** — this solution provides the
> method and the evidence, not the determination, and makes no certification claim.


---


# 7. Best Practices — A Defensible FERPA Program on Microsoft Purview

Operating principles for a control-and-evidence program that survives an audit. Grounded in Microsoft's
public guidance and the **Assess → Design → Configure → Pilot (simulate/test) → Validate → Expand
(enforce)** model.

## Stay in your lane: configure the control, defer the determination
- **You implement and evidence controls; compliance/registrar/records/legal decide the rules.** What is an education record, who is an eligible student or a school official with legitimate educational interest, which disclosures are permitted, retention durations, and whether a configuration satisfies FERPA (34 CFR Part 99) are **their** determinations. Capture them in the `Control Map – FERPA – Purview` register with named approvers — the register is your defensibility.
- Write findings as "the control is configured as specified and evidenced," never "the institution is FERPA-compliant." This solution makes **no certification claim**.

## Classify first — you can't protect what you can't see
- Education-record protection stands on **classification**. Invest in the right **sensitive information types / trainable classifiers** and the **sensitivity label** before DLP and retention, so those controls have a reliable signal to key off.
- Tune classification in the **pilot**: measure false positives/negatives on benign test content and refine before enforcement. Match-logic adequacy is a compliance/registrar decision — you operationalize what they define.

## Treat DLP as a one-way lever — pilot in simulation, enforce under sign-off
- An enforced DLP policy can **block legitimate educational work** if mis-scoped. **Always build `DLP – FERPA Education Records – Simulate` in simulation mode**, validate matches and false-positive rate, encode the **permitted-disclosure exceptions** (to the student, to school officials, under consent), and switch to enforce only under **explicit compliance/registrar sign-off** on the approved scope.
- Choose the enforcement action deliberately — **block, block-with-override, or notify** — and set clear **policy tips** so users understand why an action fired. Keep a documented rollback (revert to simulation) with every enforcement change.

## Protection is (mostly) not retroactive
- Labels, DLP, and retention act **from application/enable forward**. Configure now; deferring leaves education-record exposure and history you cannot recreate. This is the strongest argument for building the program before an audit, not during one.

## Make evidence a first-class deliverable
- An auditor wants **control → configuration → proof**. Generate the `Evidence – FERPA Controls – Binder` regularly, not just at audit time, so evidence is always current and gaps surface early.
- Retain the `-WhatIf` transcripts, before/after discovery outputs, and sign-offs — the *change history* of the control is itself evidence of a governed program.

## Audit is the access-evidence layer — keep it on and retained
- Ensure **unified audit logging** stays on (it can be disabled) and that the `Audit Retention – FERPA Evidence – LongTerm` policy keeps the evidence of who accessed/disclosed education records, at a verified duration and licensing tier.
- Treat "is auditing on and retaining?" as a **standing monitored control**, caught by the scheduled read-only chain.

## Least-privilege everywhere, reviewed periodically
- Information Protection, DLP, Records/Retention Management, Audit, and Compliance Manager roles are **distinct and least-privilege**; reserve Global Administrator for one-time enablement. Review membership periodically — access to student-record controls is itself sensitive.

## Pilot every change, keep a rollback
- Publish labels, enable DLP (simulation), apply retention, and extend audit **pilot-first** in simulation/test/disabled mode; validate with the scorecard before expanding. Every control here is reversible — record the exact rollback with every change, and never move DLP to enforcement outside the pilot without sign-off.

## Operate it as a program, not a project
- Schedule `CMPFERPA-Discovery.ps1` → `CMPFERPA-Validate.ps1` → `CMPFERPA-Report.ps1` on a cadence so drift (a DLP policy reverted to simulation or disabled, a narrowed label scope, a lapsed license, audit turned off) is caught before an auditor finds it, and re-generate the evidence binder ahead of every audit cycle. Hand the register, binder, and runbook to compliance/registrar as the standing procedure.


---


# 8. Deliverables Summary — Microsoft Purview FERPA Compliance Program

What you receive, what to run, and what "done" looks like.

## Documentation
| Document | Purpose |
|---|---|
| **1. Solution Overview** | What the program is, the three Purview control domains (classify & label education records, DLP against unauthorized disclosure, retention & audit evidence), what you control, honest limitations, and the naming convention. |
| **2. Requirements Guide** | FERPA-program prerequisites (licensing per control, least-privilege roles, S&C PowerShell + Graph toolchain, in-scope education-record data/workloads/endpoints, the obligation-to-control map, DLP simulation/disclosure-exception preconditions, audit, pilot) — each with Verify / Implement. |
| **3. Implementation Guide** | Ordered steps: assess, design the control map, configure classification & labels, DLP (in simulation), retention & audit, track in Compliance Manager, validate & evidence, expand to enforcement — pilot-in-simulation/test-first with pass/fail gates and rollback. |
| **5. Testing & Validation** | Nine gates from "licensing present" to "validation scorecard green," each with method / pass / fail action — read-only or benign pilot content, DLP kept in simulation. |
| **6. Troubleshooting** | The failure modes — label/classification behavior, DLP false positives/enforcement, retention scope, audit off, licensing, endpoint/onboarding, evidence gaps — and their fixes. |
| **7. Best Practices** | Defensible-program principles: defer determinations, classify first, treat DLP as a one-way lever, make evidence first-class, operate it as a program. |

## PowerShell tools (5)
All run **read-only or `-WhatIf` by default**; writes require `-Commit`. No credentials or secrets are
embedded. Sensitivity labels, DLP, retention, and audit retention cmdlets use **Security & Compliance
PowerShell** (`Connect-IPPSSession`); licensing reads use **Microsoft Graph**.

| Script | Role | Default |
|---|---|---|
| `CMPFERPA-Discovery.ps1` | Assess: licensing, sensitivity labels/policies, DLP policies (enforce vs simulation), retention labels/policies, sensitive info types, unified-audit state + audit retention. | Read-only |
| `CMPFERPA-Scope.ps1` | Scope/health helper: in-scope education-record locations/mailboxes/sites, device-onboarding state, visible role groups, connection identity/health. | Read-only |
| `CMPFERPA-Configure.ps1` | Configure/Remediate: create the education-record label + publish policy, the DLP policy **in simulation**, retention, and audit-evidence retention — `-Control Label\|DLP\|Retention\|Audit`. | `-WhatIf` (writes on `-Commit`) |
| `CMPFERPA-Validate.ps1` | Validate: program scorecard across label/classification, DLP (simulation + exceptions), retention, audit, pilot coverage. | Read-only |
| `CMPFERPA-Report.ps1` | Report: control → object → configuration → proof export (`Evidence – FERPA Controls – Binder`), cross-referenced to the control map. | Read-only |

## Named artifacts created
- Classification/protection: `Protect – FERPA Education Records – Confidential` (sensitivity label), `Protect – FERPA Education Records – Publish` (publish policy).
- Disclosure prevention: `DLP – FERPA Education Records – Simulate` (built and validated in simulation mode).
- Records lifecycle: `Retention – FERPA Records – Publish`, `Disposition – FERPA Records – Review`.
- Access evidence: `Audit Retention – FERPA Evidence – LongTerm`.
- Program tracking: `Assessment – FERPA Controls – Program` (Compliance Manager, in-portal).
- Governance/evidence: `Control Map – FERPA – Purview`, `Evidence – FERPA Controls – Binder`, pilot `FERPA Pilot – Education Records – Stage1`.

## Definition of done
- Compliance **licensing confirmed** for classification, DLP, retention, and audit evidence on the in-scope population.
- Classification & labeling control in place — `Protect – FERPA Education Records – Confidential` published to the approved scope and applying to education records.
- Disclosure-prevention control in place — `DLP – FERPA Education Records – Simulate` validated **in simulation** with permitted-disclosure exceptions, then moved to enforcement on the approved scope **under compliance/registrar sign-off**.
- Retention scoped and **unified audit on** with `Audit Retention – FERPA Evidence – LongTerm` retaining access evidence.
- The `Control Map – FERPA – Purview` register complete and the `Evidence – FERPA Controls – Binder` generated; the **validation scorecard green** for the pilot — then expanded to enforcement with a monitoring cadence and disposition review scheduled.

> **Boundary:** this solution delivers the technical control configuration and the evidence.
> **Education-record scope, permitted-disclosure/DLP-exception adequacy, retention adequacy, and any FERPA
> determination are deferred to your compliance, registrar, records, privacy, and legal functions.**
> Feature availability is **licensing-/tenant-dependent and evolving — verify against your entitlements
> and current Microsoft documentation.**
