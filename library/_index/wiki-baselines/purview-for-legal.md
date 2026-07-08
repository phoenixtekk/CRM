# Microsoft Purview for Legal

> **Version 1.0.0** · Category: Purview · Solution code: INDLEGAL

> This is the online, maintained copy of the implementation guide. When this solution is updated, eligible customers are alerted and can return here for the current content. Downloadable PDF + scripts are attached on the store listing.



---


# Executive Summary — Microsoft Purview for Legal

## The problem
A law firm or corporate legal department holds the tenant's most sensitive concentration of material:
**attorney-client privileged** content and **matter records** carrying retention, records, and
legal-hold obligations. Generic tenant configuration does not fit that reality — privilege is
inadvertently disclosed by a mis-sent email or mislabeled file, matter content is under- or
over-retained, and there is no evidence that any control is actually in place. Left unaddressed, that is
both a compliance gap and a data-risk exposure, and it surfaces at the worst possible moment: during a
matter or an audit.

## The solution
A complete, self-guided **Legal-tailored program** built on **Microsoft Purview** — one that *curates and
sequences* the granular Purview capabilities for a legal organization rather than re-teaching each one.
It maps the in-scope obligations to four configured Purview controls — **sensitivity labels** (privileged
and matter-confidential, with encryption), **DLP** (preventing inadvertent disclosure of privileged
material across email, SharePoint, OneDrive, Teams and endpoints), **retention & records** (matter-based
retention plus governed disposition), and **Audit** (the evidence trail) — tracks them in **Compliance
Manager**, **pilots the high-impact ones in simulation/test/disabled mode**, validates them, and produces
an **evidence binder** (control → configuration → proof) you can hand to an auditor or produce in a
matter. Five safe-by-default PowerShell tools (read-only or `-WhatIf` until you commit) do the
assessment, scoping, configuration, validation, and evidence reporting.

## What you get
- **An obligation-to-control register** — every in-scope obligation mapped to the Purview object that implements it, with the required behavior and a named approver.
- **Privilege protection** — an encrypted sensitivity label for privileged content and a matter-confidential label, published to the legal population, with encryption scoped to legal's approved design.
- **Inadvertent-disclosure prevention, simulation-first** — a DLP policy built **in simulation** across email/SharePoint/OneDrive/Teams/Endpoint, its matches reviewed and tuned before a single block, then enforced under sign-off.
- **A governed matter-records lifecycle** — matter-based retention piloted with a non-regulatory label first, with disposition review where the schedule requires, and legal-hold coordination (hold decisions stay legal's).
- **An audit-ready evidence binder** — control → configuration → proof, regenerated on a cadence so it is always current.

## Approach
Delivery follows a disciplined, reversible model — **Assess → Design → Configure → Pilot (simulate/test)
→ Validate → Expand (enforce)** — piloting every high-impact control on a limited scope before
enforcement, with pass/fail gates and documented rollback. DLP is validated **in simulation** before it
ever blocks; the irreversible **regulatory-records** label is gated hardest of all, applied only under
explicit legal/records sign-off.

## Boundaries
Microsoft Purview is **licensing-/plan-dependent** (encryption labels, Teams/Endpoint DLP,
records/regulatory records, and Audit Premium require E5 or the E5 Compliance add-on) and the portal is
**actively evolving** — capabilities and paths are cited or flagged **"verify your licensing/tenant,"**
never assumed. Above all: **what is privileged, how matters map, retention adequacy, disposition
triggers, and whether a matter is under legal hold are deferred to your legal, records, and compliance
functions** — this solution provides the technical control and the evidence, not the determination.
**Legal holds and eDiscovery case actions remain the legal function's; this program references the method
read-only and never creates or releases a hold.**

## The bottom line
A Legal program that is **configured, piloted, validated, and evidenced** in Microsoft Purview — so when
privilege must be protected, a matter's records produced, or a control shown to an auditor, the
capability is already in place and defensible.


---


# 1. Solution Overview — Microsoft Purview for Legal

## What this solution is
A law firm or a corporate legal department holds two things nobody else in the tenant holds in the same
concentration: **attorney-client privileged material** and **matter records** that carry retention,
records, and legal-hold obligations. Generic tenant configuration does not fit that reality — privilege
is inadvertently disclosed, matter content is under- or over-retained, and there is no evidence that any
control is actually in place. This solution is a **Legal-tailored Purview program** that *curates and
sequences* the granular Purview capabilities for a legal organization rather than re-teaching each one:
it stands up (1) **sensitivity labels** for privileged and matter-confidential content — with
encryption; (2) **DLP** to prevent the inadvertent disclosure of privileged material across email,
SharePoint, OneDrive, Teams and endpoints — **piloted in simulation**; (3) **retention & records** for
the matter lifecycle (matter-based retention, disposition review, and legal-hold *coordination*) plus an
**audit-evidence** trail; and (4) tracks the whole thing in **Compliance Manager**. It uses only the
**Microsoft Purview portal** (`purview.microsoft.com`), **Security & Compliance PowerShell**
(`Connect-IPPSSession`), and **Microsoft Graph** — no third-party tooling.

> **This is a technical-control-and-evidence program, not a legal determination.** *Which* content is
> privileged, how matters map to content and retention, what the records schedule is, and whether any
> given matter is under a **legal hold** are **legal and records determinations** owned by your firm's
> **legal, records, and compliance functions**. This solution provides the configured control, the
> register, and the evidence — it does **not** decide privilege, matter scope, retention duration, or
> hold. **Legal holds and eDiscovery case actions are the legal function's; this solution provides the
> technical method and references them, it does not create the hold decision.**

## Why this matters
- **Privilege, once disclosed, is hard to claw back.** An email to the wrong recipient or a mislabeled document can waive privilege. Sensitivity labels (with encryption) plus DLP are the Microsoft controls that keep privileged and matter-confidential content inside the firm — but they only protect content **from the point they are applied forward**, which is why configuring now matters.
- **DLP is high-impact and must not be dropped into enforcement blind.** A DLP policy that blocks legal's own routine sharing on day one is worse than none — it trains people to work around it. Purview DLP supports a **simulation (test) mode** that surfaces what *would* have matched without blocking anything; this program always pilots there first.
- **Matter records live and die on retention.** Matter content must be retained per the records schedule and disposed of under governance — not kept forever by accident, not deleted prematurely. Purview retention labels/policies and **disposition review** operationalize the matter lifecycle; **legal hold** overrides disposal, and coordinating that override is a legal function you *support*, not decide.
- **Evidence is the deliverable.** "We protect privileged material" is an assertion; a **control → configuration → proof** binder is evidence. This program produces one.
- **The controls are licensing-dependent and evolving.** Encryption labels, advanced/endpoint DLP, records/regulatory-records retention, and Audit Premium require **Microsoft 365 E5** or the **E5 Compliance** add-on; the portal changes. Capabilities are **cited or flagged "verify your licensing/tenant"**, never assumed.

## How it works
1. **Assess.** Discover what the tenant already has — compliance licensing/plans, the least-privilege roles, existing sensitivity labels and label policies, DLP policies, retention labels/policies, unified-audit state and audit retention, and (read-only) any existing eDiscovery holds — so the program is built on facts.
2. **Design the control map.** With legal/records, map the in-scope obligations (privilege protection, matter confidentiality, matter records retention, disposition, hold coordination, audit evidence) to the four Purview control domains and to the **named artifacts** below. The privilege/matter/retention/hold determinations are legal's; this solution provides the register and the technical control.
3. **Configure — safely.** Create the sensitivity labels (privileged / matter-confidential, with encryption), the DLP policy **in simulation**, the matter-records retention label + publish policy, the audit-evidence retention policy, and the disposition-review stage. Every high-impact change is piloted disabled/simulated before enforcement.
4. **Pilot & validate.** Prove the labels apply and encrypt, the DLP policy matches privileged content **in simulation** (nothing blocked yet), retention preserves matter content, and audit evidence is retained — on a bounded **pilot scope** before tenant-wide enforcement.
5. **Produce the evidence.** Generate the control-mapping + evidence binder (control → Purview object → configuration → proof) for the legal/compliance file.
6. **Expand & operate.** Move DLP from simulation to enforcement and expand the labels/retention on the approved scope, schedule the read-only re-assessment so drift is caught, and hand the register, binder, and runbook to legal/records as a standing procedure.

## The control stack this solution curates
- **Sensitivity labels (Information Protection)** — `Get/New-Label` + `Get/New-LabelPolicy`: a label for **attorney-client privileged** content (encrypted, restricted) and one for **matter-confidential / work-product** content, published to the legal population — the confidentiality control.
- **Data Loss Prevention** — `Get/New-DlpCompliancePolicy` + `Get/New-DlpComplianceRule`: a policy that detects privileged/matter-confidential content (by label and/or sensitive info types) across Exchange, SharePoint, OneDrive, Teams and **Endpoint**, **built in simulation/test mode first** — the inadvertent-disclosure control. *High-impact.*
- **Retention & records (Data Lifecycle / Records Management)** — `Get/New-ComplianceTag` + `Get/New-RetentionCompliancePolicy`: matter-based retention labels/policies and a **disposition-review** stage for reviewed disposal — the matter-records lifecycle control. **Legal hold overrides disposal; hold decisions are legal's** (`Get-CaseHoldPolicy` is referenced read-only only).
- **Audit (Standard/Premium)** — unified audit logging and **audit log retention policies** (`Get-UnifiedAuditLogRetentionPolicy`) keeping the evidence of who did what — the audit-trail control.
- **Compliance Manager** — an **assessment** that tracks the legal control implementation and improvement actions — the control-tracking layer (configured in-portal; applicability is legal/compliance's determination).

## What you can control
- Which **sensitivity labels** implement privilege / matter-confidentiality, their **encryption** settings, and their publish scope.
- The **DLP** policy's detection (labels + sensitive info types), its **locations** (email/SharePoint/OneDrive/Teams/Endpoint), and — critically — that it runs in **simulation** until validated.
- Which **retention labels/policies** implement the matter-records schedule, and whether disposal is governed by **disposition review**.
- Which operations/users get **extended audit retention** as evidence.
- The **control register** (`Control Map – Legal – Purview`) and the **evidence binder** contents.
- The **pilot scope** validated before any enforcement.

## Limitations (be honest with buyers)
- **We configure the control; legal makes the determination.** What is privileged, how matters map to content, the retention schedule, and whether any matter is under **legal hold** are **legal/records** determinations. **Verify with your legal and records functions.**
- **Legal holds and eDiscovery case actions are legal's.** This solution references the technical method (`Get-CaseHoldPolicy` read-only, eDiscovery holds in-portal) but **does not create, release, or scope a hold** — that is a legal decision with legal consequences.
- **Protection is largely not retroactive.** Labels, DLP, and retention act **from application forward**; they do not reach back to protect or preserve content that was never labeled or captured.
- **DLP and encryption are high-impact.** An encryption label can make content unreadable to unlicensed/external parties; a DLP block can interrupt legitimate legal work. Both are **piloted (simulation/test) first** with documented rollback before enforcement.
- **Records/regulatory-records retention can be irreversible by design.** Where the matter schedule calls for a **regulatory record** label (immutable, non-removable), it is gated hardest — applied only under explicit legal/records sign-off. **Verify the exact behavior in your tenant.**

## Naming convention (used in every doc and script)
Every artifact this solution creates is named `<Purpose> – <Scope> – <Stage>` and reused verbatim
across the docs, scripts, and portal. The standard set:

| Artifact | Name |
|---|---|
| Privileged sensitivity label (encrypted) | `Protect – Legal Privileged – Restricted` |
| Matter-confidential sensitivity label | `Protect – Legal Matter Confidential – Confidential` |
| DLP policy for privileged material (simulation) | `DLP – Legal Privileged – Simulate` |
| Matter-records retention publish policy | `Retention – Legal Matter Records – Publish` |
| Disposition-review stage | `Disposition – Legal Records – Review` |
| Audit evidence retention policy | `Audit Retention – Legal Evidence – LongTerm` |
| Compliance Manager assessment | `Assessment – Legal Controls – Program` |
| Control-mapping register | `Control Map – Legal – Purview` |
| Evidence binder export | `Evidence – Legal Controls – Binder` |
| Pilot validation scope | `Legal Pilot – Privileged Data – Stage1` |

## The standard deployment model
> Assess the controls and licensing you have → design the obligation-to-control map with legal/records →
> configure sensitivity labels, DLP, matter retention, and audit evidence → **pilot in
> simulation/test/disabled mode** on a limited scope → validate the controls work and produce evidence →
> expand to enforcement. Pattern: **Assess → Design → Configure → Pilot (simulate/test) → Validate →
> Expand (enforce).** High-impact controls (encryption labels, DLP, records retention) are always
> piloted before enforcement; legal holds and privilege/retention determinations are legal's.


---


# 2. Requirements Guide — Microsoft Purview for Legal

Verify **every** requirement before configuring. Each entry: **Description · Why · Verify ·
Implement-if-missing.** Category-wide prerequisites (tenant/licensing, Purview roles, the S&C
PowerShell + Graph toolchain, in-scope workloads, compliance/records/legal stakeholders, pilot &
change control) are in `global-requirements-purview.md` — this guide adds the **Legal-program** detail.

> **Legal/licensing boundary.** Encryption sensitivity labels, advanced & endpoint DLP,
> records/regulatory-records retention, and Audit Premium require **Microsoft 365 E5** or the **E5
> Compliance** add-on and evolve; confirm your entitlements rather than assuming. **What is privileged,
> how matters map to content, the retention schedule, and whether a matter is under legal hold** are
> **legal/records determinations** — this solution configures the control and produces evidence; it does
> not make the determination. Where this guide flags "verify your licensing/tenant" or "legal/records to
> determine," do so before relying on the item.

## 2.1 Compliance licensing for labels, DLP, retention, and audit evidence
**Description:** The program spans four licensed control domains. **Sensitivity labels with encryption**
and **auto/advanced-classification** need **E5 / E5 Compliance**; **DLP** for Exchange/SharePoint/OneDrive
is broadly available but **Teams DLP and Endpoint DLP** need **E5 / E5 Compliance**; **records /
regulatory-records retention** needs **E5 / E5 Compliance**; **Audit Premium** (long-term retention,
high-value events) needs **E5 / E5 Compliance / Audit add-on**, assigned **per user**.
**Why:** Every control below is plan-gated; the feature won't be available without the right plan (GR §1).
**Verify:** M365 admin center → `Billing → Licenses`; run `INDLEGAL-Discovery.ps1`, which reports whether
information-protection / DLP-endpoint / records / Audit-Premium-bearing plans are present via Graph.
**Confirm plan/service-plan names against your tenant — they change.**
**Implement:** Assign/purchase E5 or the relevant add-ons to the in-scope legal population before
expecting the feature.

## 2.2 Least-privilege roles for each control domain
**Description:** Distinct least-privilege roles — **Information Protection Admin** for sensitivity labels
& policies; **Compliance Administrator / DLP Compliance Management** for DLP; **Records Management /
Retention Management** for retention & disposition; **Audit Manager/Reader** for evidence; **Compliance
Manager** roles for assessments; and, referenced only, **eDiscovery Manager** for legal holds (owned by
legal). Global Administrator only where genuinely required.
**Why:** Purview uses fine-grained role groups; configuration requires the matching role, and hold/eDiscovery
access is legally sensitive and kept with the legal function (GR §2).
**Verify:** Purview portal → `Settings → Roles & scopes / Permissions` — confirm membership per domain;
`INDLEGAL-Scope.ps1` reports the role groups it can see and the connection identity.
**Implement:** Assign the least-privilege role groups under change control; keep eDiscovery/hold roles with legal.

## 2.3 Security & Compliance PowerShell + Graph toolchain
**Description:** A workstation with the `ExchangeOnlineManagement` module (for `Connect-IPPSSession` —
`*-Label`/`*-LabelPolicy`, `*-DlpCompliancePolicy`/`*-DlpComplianceRule`, `*-ComplianceTag`,
`*-RetentionCompliancePolicy`, `*-UnifiedAuditLogRetentionPolicy`, and read-only `Get-CaseHoldPolicy`)
and `Microsoft.Graph` (licensing reads), with a modern-auth / MFA admin.
**Why:** All configuration and the provided scripts run through Security & Compliance PowerShell and
Graph (GR §3).
**Verify:** `Get-Module -ListAvailable ExchangeOnlineManagement`; `Connect-IPPSSession` and
`Connect-MgGraph` succeed; `INDLEGAL-Discovery.ps1` reports which endpoints are reachable.
**Implement:** `Install-Module ExchangeOnlineManagement -Scope CurrentUser`;
`Install-Module Microsoft.Graph -Scope CurrentUser`.

## 2.4 In-scope legal population, matters, workloads, and channels
**Description:** The **legal population** in scope (a group/OU of attorneys, paralegals, and legal staff),
the **workloads** holding privileged/matter content (Exchange, SharePoint matter sites, OneDrive, Teams),
the **channels** DLP must cover (email, Teams chat/channels, endpoints), and a **classification intent**
(what privileged / matter-confidential / work-product looks like) to drive labels and DLP.
**Why:** Labels, DLP, and retention controls key off the in-scope population/workloads/matters (GR §4).
**Verify:** Confirm the legal-population group, the matter sites/workloads, the DLP channels, and the
classification approach with legal; `INDLEGAL-Scope.ps1` enumerates the group's members and the
mailboxes/sites in scope (read-only).
**Implement:** Define the legal-population group, matter workloads, and classification intent before
authoring controls.

## 2.5 The obligation-to-control map, privilege scope, and records schedule (from legal/records)
**Description:** A documented statement — **from legal and records** — of which content is **privileged**
vs **matter-confidential**, how matters map to content, what must be **retained and for how long** (the
matter-records schedule), what triggers **disposition review**, and which matters carry a **legal hold**.
**Why:** Privilege determination, matter mapping, retention duration, and hold scope are **legal/records
determinations**, not technical defaults (GR §5); the solution configures to them and evidences them —
it does not decide them.
**Verify:** You can name, per control domain, the obligation, the required label/retention/DLP behavior,
the disposition trigger, and the named approver; these populate the `Control Map – Legal – Purview` register.
**Implement:** Capture the privilege scope, matter map, records schedule, and hold list with approvals
before configuring — especially before any **encryption** label or **regulatory-records** (irreversible) label.

## 2.6 DLP simulation, encryption, and disclosure preconditions
**Description:** For the high-impact controls specifically: agreement to build **DLP in simulation/test
mode** first (surface matches, block nothing), a decision on **encryption** behavior for the privileged
label (who can decrypt — internal only, specific groups, external counsel), and how the labels/DLP should
treat **external sharing** (co-counsel, courts, clients).
**Why:** An encryption label can make content unreadable to intended external recipients, and a DLP block
can interrupt legitimate legal sharing; both must be modeled before enforcement (GR §5/§6).
**Verify:** A named DLP simulation window, the agreed encryption/permission scope for the privileged
label, and the external-sharing exceptions legal requires.
**Implement:** Configure the privileged label's encryption/permissions to legal's decision, **build the
DLP policy in simulation**, and keep it there until match review and sign-off are complete.

## 2.7 Unified audit logging on, and an evidence-retention requirement
**Description:** `UnifiedAuditLogIngestionEnabled` must be **true** so the audit-trail control captures
evidence of label/DLP/retention/hold-related activity, plus a documented statement of how long audit
**evidence** must be retained for legal purposes.
**Why:** No audit evidence is written while ingestion is off, and it is **not retroactive**; retention
duration is a legal/compliance determination (GR §5/§6).
**Verify:** `INDLEGAL-Discovery.ps1` reports `UnifiedAuditLogIngestionEnabled` and existing audit
retention policies.
**Implement:** Enable unified audit under change control (Purview Audit solution / Exchange Online), then
create the evidence-retention policy in the Implementation Guide.

## 2.8 A pilot scope, simulation/test mode, and change control
**Description:** A bounded **pilot scope** (`Legal Pilot – Privileged Data – Stage1` — a small set of
attorneys/paralegals, matter sites, and benign test content) and a **change-control** window. Sensitivity
labels can be published to the pilot first; DLP supports **simulation mode**; retention can be trialed
with a **non-regulatory** label first; audit changes are reversible.
**Why:** Encryption labels, DLP, and records retention are **high-impact** — regulatory records are
effectively irreversible — so every change is piloted in simulation/test/disabled mode before enforcement
(GR §6).
**Verify:** A named pilot scope, confirmation that simulation/test/disabled mode is available for each
control, and a change window/approval path.
**Implement:** Define the pilot scope and agree change control before enabling or enforcing any control —
**never enforce a DLP block or apply a regulatory-records label outside the pilot without explicit
legal/records sign-off, and never create/release a legal hold as part of this work (legal's decision).**


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


# 3. Implementation Guide — Microsoft Purview for Legal

Follow these steps **in order**. Configuration uses the **Microsoft Purview portal**
(`https://purview.microsoft.com`), **Security & Compliance PowerShell** (`Connect-IPPSSession` — the
`*-Label`/`*-LabelPolicy`, `*-DlpCompliancePolicy`/`*-DlpComplianceRule`, `*-ComplianceTag`,
`*-RetentionCompliancePolicy`, and `*-UnifiedAuditLogRetentionPolicy` cmdlets), and **Microsoft Graph**
(licensing). Every write is gated: scripts run **read-only or `-WhatIf` by default** and only change
state with `-Commit`. Artifact names follow the `<Purpose> – <Scope> – <Stage>` convention from the
Overview and are reused verbatim.

> **Model:** Assess the controls/licensing you have → design the obligation-to-control map with
> legal/records → configure sensitivity labels, DLP (in simulation), matter retention, and audit
> evidence → **pilot in simulation/test/disabled mode** → validate and evidence → expand to enforcement.
> Pattern: **Assess → Design → Configure → Pilot (simulate/test) → Validate → Expand (enforce).**
>
> **Determination boundary:** what is privileged, how matters map, retention durations, disposition
> triggers, and which matters are under **legal hold** are **legal/records** determinations. This guide
> configures the control and evidences it; it does not make the determination. **DLP is enforced only
> after a validated simulation; a `regulatory-records` label is effectively irreversible — never apply it
> outside the pilot without explicit legal/records sign-off; legal holds are created/released by legal in
> eDiscovery, never by this work.**

## Step 1 — Assess current controls and licensing (Assess)
1. Run `INDLEGAL-Discovery.ps1` (read-only). It connects to Security & Compliance PowerShell and Graph and reports:
   - compliance licensing present (information-protection / DLP-endpoint / records / Audit-Premium-bearing plans — **verify plan names for your tenant**),
   - existing **sensitivity labels** (`Get-Label`) and **label policies** (`Get-LabelPolicy`), flagging any with **encryption**,
   - existing **DLP policies** (`Get-DlpCompliancePolicy`), flagging **mode** (Enable / TestWithNotifications / TestWithoutNotifications),
   - existing **retention labels** (`Get-ComplianceTag`) and **retention policies** (`Get-RetentionCompliancePolicy`), flagging any that are **records**/**regulatory records**,
   - `UnifiedAuditLogIngestionEnabled` and existing **audit retention policies** (`Get-UnifiedAuditLogRetentionPolicy`),
   - **read-only reference only:** any existing eDiscovery **case holds** (`Get-CaseHoldPolicy`) — so hold coverage is visible; the script never creates or changes a hold.
2. Run `INDLEGAL-Scope.ps1` (read-only) to enumerate the intended legal-population group, in-scope mailboxes/matter sites, and the role groups it can see (Requirement 2.2/2.4).
3. Record the gaps against the four control domains. **Pass gate:** a written current-state for labels, DLP, retention, and audit.

## Step 2 — Design the obligation-to-control map (Design)
1. With legal/records (Requirement 2.5), populate the `Control Map – Legal – Purview` register: for each in-scope obligation, name the Purview control object that implements it, the required label/DLP/retention behavior, the disposition trigger, and the approver. **Privilege, matter mapping, retention, and hold are legal's determination; you provide the register and the technical control.**
2. Map the obligations to the standard named artifacts:
   - Privilege/confidentiality → `Protect – Legal Privileged – Restricted` (encrypted label) + `Protect – Legal Matter Confidential – Confidential` (label), published to the legal population.
   - Inadvertent disclosure → `DLP – Legal Privileged – Simulate` (built in simulation).
   - Matter records → `Retention – Legal Matter Records – Publish` (retention label + publish policy) + `Disposition – Legal Records – Review` (disposition stage).
   - Audit evidence → `Audit Retention – Legal Evidence – LongTerm`.
   - Control tracking → `Assessment – Legal Controls – Program` (Compliance Manager).
3. Define the pilot scope `Legal Pilot – Privileged Data – Stage1` (Requirement 2.8) and the encryption/DLP/external-sharing decisions (Requirement 2.6). **Pass gate:** the control map, privilege scope, records schedule, pilot, and approvals are documented.

## Step 3 — Configure the sensitivity labels (Configure → Pilot)
1. Create the two labels with the helper, `-WhatIf` first (prints the exact `New-Label`/`New-LabelPolicy` it would run):
   - `INDLEGAL-Configure.ps1 -Control Labels -WhatIf` → review → `-Commit` (creates `Protect – Legal Privileged – Restricted` **with encryption** per legal's decryption/permission decision, and `Protect – Legal Matter Confidential – Confidential`; then a label policy publishing both to the **pilot** legal population).
2. **Publish to the pilot population first.** Confirm the labels appear in Office/Outlook for pilot users and that applying the privileged label encrypts as designed (Testing Gate 2/3). **Encryption/permission scope is legal's decision — do not broaden decryption beyond what legal approved.**
3. **Pass gate:** `INDLEGAL-Discovery.ps1` lists both labels and the pilot label policy, with the privileged label flagged encrypted. **Rollback:** unpublish the label policy / remove the pilot labels (`-Control Labels -Remove -Commit`); already-encrypted content stays encrypted (by design) — pilot with benign content so this is inconsequential.

## Step 4 — Configure the DLP control — IN SIMULATION (Configure → Pilot)
1. **Build the DLP policy in simulation/test mode** so it surfaces what *would* match and **blocks nothing**. The helper creates it in `TestWithNotifications` (or `TestWithoutNotifications`) scoped to the pilot:
   - `INDLEGAL-Configure.ps1 -Control DLP -Mode TestWithNotifications -WhatIf` → review → `-Commit` (creates `DLP – Legal Privileged – Simulate` via `New-DlpCompliancePolicy` across Exchange/SharePoint/OneDrive/Teams/Endpoint scoped to the pilot, plus a `New-DlpComplianceRule` matching the **privileged/matter labels** and/or the sensitive info types your legal function specified — **the match criteria are legal's determination**).
2. Let the simulation run, then review its matches: are the right items caught, and — critically — is legitimate legal sharing being **over-matched**? Tune the rule (labels, info types, exceptions for approved external counsel/court sharing) **still in simulation**. **Do not switch to Enable until the match review is clean and legal signs off.**
3. **Pass gate:** the DLP policy exists in a **test/simulation** mode, scoped to the pilot, and its match report is reviewed. **Rollback:** remove the policy (`-Control DLP -Remove -Commit`); in simulation nothing was ever blocked, so there is nothing to unwind.

## Step 5 — Configure the matter-records retention control (Configure → Pilot)
1. **Pilot with a non-regulatory records label first** to prove behavior safely. Create the retention label + publish policy with the helper, `-WhatIf` first:
   - `INDLEGAL-Configure.ps1 -Control Retention -WhatIf` → review → `-Commit` (creates a **records** — not regulatory — matter-retention label and the `Retention – Legal Matter Records – Publish` policy scoped to the pilot matter workloads, at the duration your records function specified — **duration/trigger are records' determination**).
2. Validate the label applies and preserves matter content (Testing Gate 5). Where the records schedule requires reviewed disposal, configure the `Disposition – Legal Records – Review` stage in-portal so end-of-retention disposal is reviewed, not automatic. **Only after legal/records sign-off**, and only where the schedule requires it, create any **regulatory-records** (immutable, non-removable) label — gated hardest of all.
3. **Legal hold note:** where a matter is under **legal hold**, the hold overrides disposal. **Creating, scoping, or releasing a hold is the legal function's action in eDiscovery** — this step references it (`Get-CaseHoldPolicy` read-only in Discovery) but never performs it. **Pass gate:** `INDLEGAL-Discovery.ps1` lists the retention label/policy with the expected records behavior and scope. **Rollback:** the **non-regulatory** pilot label/policy is removable (`-Control Retention -Remove -Commit`); a **regulatory-records** label is **not** removable by design — verify behavior in your tenant before committing.

## Step 6 — Configure the audit-evidence control (Configure)
1. Confirm unified audit is on (Requirement 2.7). Create the evidence-retention policy pilot-first:
   - `INDLEGAL-Configure.ps1 -Control Audit -PolicyName "Audit Retention – Legal Evidence – LongTerm" -WhatIf` → review → `-Commit` (creates a `New-UnifiedAuditLogRetentionPolicy` for the record types/operations your legal function requires as evidence — e.g. label changes, DLP matches, file/mail activity — at the agreed duration and a unique priority). **Verify accepted `RetentionDuration` values and that the long-term tier is licensed** (Requirement 2.1).
2. **Pass gate:** `INDLEGAL-Discovery.ps1` lists the audit retention policy with the expected duration/priority. **Rollback:** `INDLEGAL-Configure.ps1 -Control Audit -PolicyName "…" -Remove -Commit` (already-retained records age out under remaining rules).

## Step 7 — Track the program in Compliance Manager (Configure, in-portal)
1. In the Purview portal → **Compliance Manager**, create/assign the assessment `Assessment – Legal Controls – Program` from a relevant **assessment template** (**template availability depends on your licensing — verify in-portal**). Map its improvement actions to the Purview controls configured above.
2. Record, per improvement action, the implementing Purview object and its evidence location (this cross-links to the `Control Map – Legal – Purview` register). **Pass gate:** the assessment reflects the configured controls with evidence links. *(Compliance Manager assessment content and applicability are legal/compliance's determination; no cmdlet invents this — it is authored in-portal.)*

## Step 8 — Validate the controls and generate evidence (Validate)
1. Run `INDLEGAL-Validate.ps1` (read-only) to score the program across gates: both labels present (privileged encrypted), DLP present **in simulation/test**, matter-records retention present and scoped, audit ingestion on with the evidence policy in place, and the pilot scope covered.
2. Run `INDLEGAL-Report.ps1` (read-only) to produce `Evidence – Legal Controls – Binder` — a control → Purview object → configuration → proof export (CSV/JSON) for the legal/compliance file, cross-referenced to `Control Map – Legal – Purview`.
3. Complete the **Testing Guide** before expanding. **Pass gate:** the validation scorecard is green for the pilot scope and the evidence binder is generated.

## Step 9 — Expand to enforcement and operationalize (Expand)
1. Once the pilot passes and legal/records sign off: publish the labels to the full legal population, **switch the DLP policy from simulation (Test) to Enable** on the approved scope, expand the matter-retention and audit-evidence policies, and — where the schedule requires — apply the regulatory-records label under sign-off. Each change is under change control.
2. Confirm the `Disposition – Legal Records – Review` stage governs end-of-retention disposal for the matters the schedule requires. **Coordinate — do not perform — legal-hold overrides with the legal function** (holds are created/released by legal in eDiscovery).
3. Schedule the read-only chain (`INDLEGAL-Discovery.ps1` → `INDLEGAL-Validate.ps1` → `INDLEGAL-Report.ps1`) on a cadence so drift — a DLP policy slipped back to test, an unpublished label, a lapsed license, audit turned off, a removed retention scope — is caught, and re-generate the evidence binder ahead of audits or matters. **Pass gate:** controls enforced on the approved scope, evidence binder current, monitoring cadence scheduled. Hand the register, binder, and runbook to legal/records as the standing procedure.


---


# 5. Testing & Validation — Microsoft Purview for Legal

Work through every gate. Each has a **method**, an **expected result (pass)**, and a **fail action**.
Tests are read-only or use **benign, self-generated pilot content** — no real privileged material, no
matter records, and no legal hold is created or actioned. Do not declare "Legal-ready" until every gate
passes for the pilot scope, then re-confirm on expand.

> **Boundary:** these gates prove the **technical control works and is evidenced**. Whether content is
> **privileged**, how matters map, whether retention is **adequate**, and whether a matter needs a **legal
> hold** are **legal/records determinations**, not test outcomes. **Never create or release a legal hold
> during testing — that is the legal function's action in eDiscovery.**

## Gate 1 — Compliance licensing present for each control
- **Method:** `INDLEGAL-Discovery.ps1` licensing section (Graph `subscribedSkus` / service plans).
- **Pass:** information-protection (encryption labels), DLP-endpoint, records/regulatory-records, and Audit-Premium-bearing plans are present and assigned to the legal population.
- **Fail:** assign the license (Requirement 2.1); a missing plan makes the corresponding control unavailable — that is a licensing gap, not a config defect. **Verify plan names for your tenant.**

## Gate 2 — Sensitivity labels published to the pilot
- **Method:** `INDLEGAL-Discovery.ps1` / portal — confirm `Protect – Legal Privileged – Restricted` and `Protect – Legal Matter Confidential – Confidential` exist (`Get-Label`) and are published (`Get-LabelPolicy`) to the pilot population; confirm they appear in Outlook/Office for a pilot user.
- **Pass:** both labels exist, the label policy targets the pilot, and pilot users can see/apply them.
- **Fail:** confirm the label policy scope and publication latency; retest. Labels can take time to appear for end users.

## Gate 3 — Privileged label encrypts as designed
- **Method:** apply `Protect – Legal Privileged – Restricted` to a **benign** pilot document/email; confirm it is encrypted and that only the permitted identities (per legal's decision) can open it.
- **Pass:** the label applies encryption and the permission scope matches legal's approved design (internal-only / named groups / external counsel as decided).
- **Fail:** correct the label's encryption/permission settings; retest with benign content. **Do not broaden decryption beyond legal's approval.**

## Gate 4 — DLP policy exists IN SIMULATION and matches correctly
- **Method:** `INDLEGAL-Discovery.ps1` / portal — confirm `DLP – Legal Privileged – Simulate` exists (`Get-DlpCompliancePolicy`), is in a **test/simulation** mode (`TestWithNotifications`/`TestWithoutNotifications`), scoped to the pilot; generate **benign** content matching the criteria and confirm it appears as a **simulated** match (blocked nothing).
- **Pass:** the policy is in simulation, scoped to the pilot, and surfaces the right matches without blocking; over-matching of legitimate legal sharing is reviewed and tuned.
- **Fail:** tune the rule (labels/info types/exceptions) **still in simulation**; retest. **Do not switch to Enable until the match review is clean and legal signs off.**

## Gate 5 — Matter-records retention applies and preserves (pilot, non-regulatory first)
- **Method:** apply the **non-regulatory** pilot matter-retention label to benign pilot content, attempt to delete it, then confirm via `INDLEGAL-Discovery.ps1` / portal that retention held and the publish policy is scoped to the pilot matter workloads.
- **Pass:** the label applies, records behavior prevents disallowed deletion, and `Get-ComplianceTag`/`Get-RetentionCompliancePolicy` show it scoped to the pilot at the agreed duration.
- **Fail:** confirm the label type (`-IsRecordLabel`), the publish policy scope, and label latency; retest. **Do not proceed to any regulatory-records label until this passes and legal/records sign off.**

## Gate 6 — Regulatory-records behavior confirmed (only if the schedule requires, post sign-off)
- **Method:** *only where the records schedule requires it and after sign-off*, confirm the regulatory-records label exists as a **regulatory** record label (immutable, retention non-shortenable) on the approved scope.
- **Pass:** the label is present and typed regulatory; its irreversibility is understood and documented.
- **Fail:** verify the regulatory-record behavior in your tenant before wider application; a regulatory label **cannot be undone**, so treat any doubt as a stop.

## Gate 7 — Disposition review configured (where required)
- **Method:** portal — confirm the `Disposition – Legal Records – Review` stage governs end-of-retention disposal for the matters the schedule requires.
- **Pass:** disposal is reviewed (not automatic) for the in-scope matter records, with the correct reviewers.
- **Fail:** configure disposition review in-portal; the disposition trigger/reviewers are records' determination.

## Gate 8 — Unified audit on and evidence policy present
- **Method:** `INDLEGAL-Discovery.ps1` audit section (`UnifiedAuditLogIngestionEnabled`, `Get-UnifiedAuditLogRetentionPolicy`).
- **Pass:** ingestion is `True` and `Audit Retention – Legal Evidence – LongTerm` exists with the agreed duration and a unique priority.
- **Fail:** enable ingestion under change control; create/correct the policy (Implementation Step 6); verify the `RetentionDuration` value and licensing.

## Gate 9 — Legal-hold coverage is visible (read-only reference)
- **Method:** `INDLEGAL-Discovery.ps1` reference section (`Get-CaseHoldPolicy`, read-only) — confirm existing eDiscovery holds are visible so the legal function can see coverage.
- **Pass:** existing holds (if any) are listed for legal's review. **This gate never creates or changes a hold.**
- **Fail:** if legal expects a hold that is not present, that is a **legal action** in eDiscovery — refer it to the legal function; do not create it here.

## Gate 10 — Control map and evidence binder generated
- **Method:** `INDLEGAL-Report.ps1` → `Evidence – Legal Controls – Binder`, cross-referenced to `Control Map – Legal – Purview`.
- **Pass:** every in-scope obligation maps to a Purview object with its configuration and a proof reference; the binder exports cleanly.
- **Fail:** fill the gap (missing control or missing evidence) and re-run. A control with no evidence fails an audit.

## Gate 11 — Validation scorecard is green (pilot)
- **Method:** `INDLEGAL-Validate.ps1`.
- **Pass:** every gate above is green for the pilot scope (and, on expand, for the approved production scope with DLP moved to Enable).
- **Fail:** address the specific red item and re-run before enforcing anything tenant-wide.

## Evidence to retain
- `INDLEGAL-Discovery.ps1` and `INDLEGAL-Validate.ps1` outputs (before/after).
- The `-WhatIf` transcripts for every label, DLP, retention, and audit change, and the DLP **simulation match report**.
- The `Evidence – Legal Controls – Binder` export and the `Control Map – Legal – Purview` register.
- The legal/records sign-offs (encryption scope, DLP enforcement, retention schedule, regulatory-records application) and the pilot roster/approvals (Requirement 2.5/2.6/2.8).

> Privilege determination, matter mapping, retention adequacy, disposition triggers, and legal-hold scope
> are **legal/records determinations** — these gates prove the Purview controls work and are evidenced,
> not that the program satisfies a legal obligation. **Legal holds and eDiscovery actions remain legal's.**


---


# 6. Troubleshooting — Microsoft Purview for Legal

Common failure modes across the four control domains and their fixes. Each: **Symptom → Likely cause →
Resolution.** Stay read-only or `-WhatIf` while diagnosing; keep high-impact changes (encryption, DLP
enforcement, regulatory records) piloted. Determinations (privilege, matter mapping, retention, legal
hold) stay with legal/records — a "fix" here means the *control* behaves as designed, not that the
program *satisfies* a legal obligation.

## A capability is missing from the portal or a cmdlet errors "not recognized"
- **Likely cause:** the feature is **not licensed** (encryption labels, Teams/Endpoint DLP,
  records/regulatory records, Audit Premium need **E5 / E5 Compliance**), or the module/role is missing.
- **Resolution:** run `INDLEGAL-Discovery.ps1` licensing section and confirm the plan is present **and
  assigned to the legal population**; **verify plan/service-plan names for your tenant — they change.**
  Install `ExchangeOnlineManagement` / `Microsoft.Graph`, and confirm the least-privilege role
  (Requirement 2.2). A missing plan is a licensing gap, not a config defect.

## Sensitivity labels don't appear for pilot users
- **Likely cause:** the label **policy** isn't published to those users, or publication latency (labels
  can take time to appear in Office/Outlook).
- **Resolution:** `Get-LabelPolicy` — confirm `Legal Pilot – Privileged Data – Stage1` targets the pilot
  population; wait for propagation and re-check. Confirm the user's app is signed in with the licensed account.

## The privileged label doesn't encrypt, or encrypts the wrong people out
- **Likely cause:** encryption isn't enabled on the label, or the **permission/decryption scope** doesn't
  match legal's approved design (external counsel/courts blocked, or too broad).
- **Resolution:** `Get-Label` — confirm `EncryptionEnabled`/`EncryptionProtectionType` on
  `Protect – Legal Privileged – Restricted`; set the rights/permissions **to legal's approved scope**
  in-portal. **Test with benign content**, confirm intended internal/external recipients can open it.
  **Do not broaden decryption beyond legal's approval.** Remember already-encrypted content stays
  encrypted by design.

## DLP is over-matching — it flags legitimate legal sharing
- **Likely cause:** the rule's match criteria (labels / sensitive info types) are too broad, or there are
  no exceptions for approved co-counsel/court/client sharing.
- **Resolution:** because the policy is **in simulation**, nothing is blocked — review the simulation
  match report, tune the rule (tighten info types, match on the privileged/matter **labels**, add the
  external-sharing exceptions legal specified) **still in simulation**, and re-review. Match criteria are
  **legal's determination** — operationalize what they define. **Do not switch to Enable until the match
  review is clean and legal signs off.**

## DLP appears to "do nothing"
- **Likely cause:** this is expected — the policy is in **simulation/test** mode (`TestWithNotifications`
  / `TestWithoutNotifications`), which surfaces matches but **blocks nothing** by design.
- **Resolution:** confirm mode with `Get-DlpCompliancePolicy` / `INDLEGAL-Discovery.ps1`. Review the
  **simulation matches** in-portal; that *is* the pilot working. Move to `Enable` **in-portal only** after
  match review and legal sign-off (Implementation Step 9). Note Teams/Endpoint locations require E5.

## Matter-records retention isn't preserving content
- **Likely cause:** the publish policy isn't scoped to the matter workloads, the label isn't a **record**
  label, or publication latency.
- **Resolution:** `Get-RetentionCompliancePolicy` / `Get-ComplianceTag` — confirm
  `Retention – Legal Matter Records – Publish` covers the pilot matter sites and the label has
  `IsRecordLabel = $true`; correct scope/type with `INDLEGAL-Configure.ps1 -Control Retention` and
  re-verify. Retention duration is **records' determination**.

## A regulatory-records label can't be removed or shortened
- **Likely cause:** this is **by design** — a **regulatory record** label is immutable, non-removable, and
  its retention cannot be shortened.
- **Resolution:** there is no "fix" — this is the intended irreversibility. This is exactly why you
  **pilot with a non-regulatory label first** and apply the regulatory label only under explicit
  legal/records sign-off, on the approved scope. **Verify the exact behavior in your tenant before wider
  application.** When in doubt, stop.

## Disposal happened (or is about to) on content legal needs held
- **Likely cause:** a matter is under (or should be under) a **legal hold** that overrides disposal, but
  the hold interaction wasn't coordinated with retention/disposition.
- **Resolution:** **legal hold is the legal function's action in eDiscovery** — refer it to legal to
  create/confirm the hold; this solution only **references** hold coverage read-only
  (`Get-CaseHoldPolicy` in `INDLEGAL-Discovery.ps1`). Surface the retention↔hold interaction; do **not**
  create, release, or scope a hold yourself. Configure `Disposition – Legal Records – Review` so disposal
  is reviewed, not automatic.

## Audit shows no evidence / `Get-AdminAuditLogConfig` unavailable
- **Likely cause:** unified audit ingestion is **off** (it can be disabled and is **not retroactive**), or
  `Get-AdminAuditLogConfig` needs an **Exchange Online** (not just S&C) connection.
- **Resolution:** `Connect-ExchangeOnline`, confirm `UnifiedAuditLogIngestionEnabled = True`; enable under
  change control if off. Then confirm `Audit Retention – Legal Evidence – LongTerm` exists with the agreed
  duration/priority (`Get-UnifiedAuditLogRetentionPolicy`). No evidence is written for the period ingestion
  was off.

## "Which cmdlet / which endpoint?" confusion
- **Likely cause:** label/DLP/retention/hold cmdlets live in **Security & Compliance PowerShell**
  (`Connect-IPPSSession`); `Get-AdminAuditLogConfig` lives in **Exchange Online**
  (`Connect-ExchangeOnline`); licensing reads use **Microsoft Graph** (`Connect-MgGraph`).
- **Resolution:** connect to the right endpoint for the task; `INDLEGAL-Discovery.ps1` /
  `INDLEGAL-Scope.ps1` report which endpoints are reachable. Confirm cmdlet availability for your tenant —
  the portal and cmdlet surface evolve.

## The evidence binder has gaps (MISSING/REVIEW rows)
- **Likely cause:** a control isn't configured yet, or a control exists with no captured proof.
- **Resolution:** `INDLEGAL-Report.ps1` lists each control's Status — fill the specific gap (configure the
  missing control or capture its proof) and re-run. A control with no evidence fails an audit. Cross-check
  every row against `Control Map – Legal – Purview`.

## Validation scorecard is red after changes
- **Likely cause:** a policy slipped (DLP reverted to test post-enforcement, a label unpublished, retention
  disabled, audit turned off, a lapsed license).
- **Resolution:** run `INDLEGAL-Validate.ps1`, address the specific red gate, and re-run. Schedule the
  read-only chain (`Discovery → Validate → Report`) so drift is caught before an auditor or opposing party
  finds it. Use `-RequireEnforced` on `INDLEGAL-Validate.ps1` post-expand to assert DLP is in Enable.

> **Boundary reminder:** these fixes make the **control** behave as designed. Whether the control
> **satisfies** a legal obligation — privilege determination, matter mapping, retention adequacy,
> disposition triggers, legal-hold scope — is a **legal/records determination**. **Legal holds and
> eDiscovery actions remain the legal function's; verify capability availability against your licensing
> and current Microsoft documentation.**


---


# 7. Best Practices — A Defensible Legal Program on Microsoft Purview

Operating principles for a Legal-tailored control-and-evidence program that protects privilege, governs
matter records, and survives an audit or a matter. Grounded in Microsoft's public guidance and the
**Assess → Design → Configure → Pilot (simulate/test) → Validate → Expand (enforce)** model.

## Stay in your lane: configure the control, defer the determination
- **You implement and evidence controls; legal/records decide the rules.** What is privileged, how matters map to content, retention durations and disposition triggers, and whether a matter is under **legal hold** are **their** determinations. Capture them in the `Control Map – Legal – Purview` register with named approvers — the register is your defensibility.
- Write findings as "the control is configured as specified and evidenced," never "the firm is protected" or "privilege is preserved."

## Legal holds and eDiscovery are legal's — provide the method, not the decision
- **Never create, scope, or release a legal hold** as part of this work. The program **references** hold coverage read-only (`Get-CaseHoldPolicy`) so legal can see it, but hold decisions have legal consequences and belong to the legal function in eDiscovery.
- Coordinate: make sure retention/disposition does not silently dispose of content the legal function needs held — surface the interaction, let legal decide the hold.

## Always pilot DLP in simulation — enforcement blind is worse than nothing
- **Build `DLP – Legal Privileged – Simulate` in test/simulation mode** and review its matches before enforcing. A DLP policy that blocks legal's routine sharing on day one trains people to work around it and can disrupt a live matter.
- Tune for **over-matching** as much as under-matching: legitimate sharing with co-counsel, courts, and clients must have modeled exceptions **before** you switch to Enable. Match criteria (labels, sensitive info types, exceptions) are **legal's determination** — you operationalize what they define.

## Treat encryption labels — and regulatory records — as one-way doors
- An **encryption** sensitivity label can render content unreadable to intended external recipients (co-counsel, courts). Set the decryption/permission scope to **legal's approved design**, pilot with **benign** content, and confirm external-sharing paths still work.
- A **regulatory-records** label is **immutable and cannot be removed**, and its retention **cannot be shortened** — by design. Use it only where the records schedule requires, pilot with a **non-regulatory** label first, and apply it only under **explicit legal/records sign-off**. When in doubt, stop.

## Protection is (mostly) not retroactive
- Labels, DLP, and retention act **from application forward**. Configure now; content that was never labeled or captured is not reached. This is the strongest argument for building the program before a matter or audit, not during one.

## Make evidence a first-class deliverable
- An auditor or opposing party wants **control → configuration → proof**. Generate the `Evidence – Legal Controls – Binder` regularly, not just at audit time, so evidence is always current and gaps surface early.
- Retain the `-WhatIf` transcripts, the DLP **simulation match report**, before/after discovery outputs, and sign-offs — the *change history* of the control is itself evidence of a governed program.

## Audit is the evidence layer — keep it on and retained
- Ensure **unified audit logging** stays on (it can be disabled) and that `Audit Retention – Legal Evidence – LongTerm` keeps the evidence your legal function requires — label changes, DLP matches, file/mail activity — at a verified duration and licensing tier.
- Treat "is auditing on and retaining?" as a **standing monitored control**, caught by the scheduled read-only chain.

## Least-privilege everywhere, and keep eDiscovery with legal
- Information Protection, DLP, Records/Retention Management, Audit, and Compliance Manager roles are **distinct and least-privilege**; reserve Global Administrator for one-time enablement. Keep **eDiscovery/legal-hold roles with the legal function** — access to holds and case content is legally sensitive. Review membership periodically.

## Pilot every change, keep a rollback (except where you can't)
- Publish labels, run DLP, and trial retention **pilot-first** in simulation/test/disabled mode; validate with the scorecard before expanding. Label policies, DLP-in-simulation, non-regulatory retention labels, and audit policies are reversible — record the exact rollback with every change.
- The deliberate exceptions are the **encryption** behavior (already-encrypted content stays encrypted) and the **regulatory-records** label (meant to be irreversible) — pilot both with benign content and gate the regulatory label hardest of all.

## Operate it as a program, not a project
- Schedule `INDLEGAL-Discovery.ps1` → `INDLEGAL-Validate.ps1` → `INDLEGAL-Report.ps1` on a cadence so drift (a DLP policy slipped back to test, an unpublished label, a narrowed retention scope, a lapsed license, audit turned off) is caught before an auditor or opponent finds it, and re-generate the evidence binder ahead of audits and matters. Hand the register, binder, and runbook to legal/records as the standing procedure.


---


# 8. Deliverables Summary — Microsoft Purview for Legal

What you receive, what to run, and what "done" looks like.

## Documentation
| Document | Purpose |
|---|---|
| **1. Solution Overview** | What the Legal-tailored program is, the four Purview control domains (sensitivity labels, DLP, matter retention, audit evidence), what you control, honest limitations, and the naming convention. |
| **2. Requirements Guide** | Legal-program prerequisites (licensing per control, least-privilege roles, S&C PowerShell + Graph toolchain, in-scope legal population/matters/channels, the obligation-to-control map, DLP-simulation/encryption preconditions, audit, pilot) — each with Verify / Implement. |
| **3. Implementation Guide** | Ordered steps: assess, design the control map, configure labels, DLP (in simulation), matter retention & disposition, audit evidence, track in Compliance Manager, validate & evidence, expand to enforcement — pilot-in-simulation/test-first with pass/fail gates and rollback (and the regulatory-records irreversibility gate; legal holds referenced, never performed). |
| **5. Testing & Validation** | Eleven gates from "licensing present" to "validation scorecard green," each with method / pass / fail action — read-only or benign pilot content; DLP validated in simulation; legal-hold coverage read-only. |
| **6. Troubleshooting** | The failure modes — label/encryption behavior, DLP over-matching, retention scope, disposition, audit off, licensing, endpoint confusion, evidence gaps, hold/retention interaction — and their fixes. |
| **7. Best Practices** | Defensible-program principles: defer determinations, keep legal holds with legal, always pilot DLP in simulation, treat encryption/regulatory records as one-way, make evidence first-class, operate it as a program. |

## PowerShell tools (5)
All run **read-only or `-WhatIf` by default**; writes require `-Commit`. No credentials or secrets are
embedded. Sensitivity labels, DLP, retention labels/policies, and audit retention cmdlets use **Security &
Compliance PowerShell** (`Connect-IPPSSession`); licensing reads use **Microsoft Graph**. `Get-CaseHoldPolicy`
is used **read-only reference only** — the tools never create, change, or release a legal hold.

| Script | Role | Default |
|---|---|---|
| `INDLEGAL-Discovery.ps1` | Assess: licensing, sensitivity labels/policies (encryption), DLP policies (mode), retention labels/policies (records/regulatory), unified-audit state + audit retention, and read-only reference to eDiscovery holds. | Read-only |
| `INDLEGAL-Scope.ps1` | Scope/health helper: legal-population group members, in-scope mailboxes/matter sites, visible role groups, connection identity/health. | Read-only |
| `INDLEGAL-Configure.ps1` | Configure/Remediate: create labels (+encryption), DLP **in simulation**, matter-records retention, and audit-evidence retention — `-Control Labels\|DLP\|Retention\|Audit`. | `-WhatIf` (writes on `-Commit`) |
| `INDLEGAL-Validate.ps1` | Validate: program scorecard across labels (encryption), DLP (in simulation/test), matter retention, audit, pilot coverage. | Read-only |
| `INDLEGAL-Report.ps1` | Report: control → object → configuration → proof export (`Evidence – Legal Controls – Binder`), cross-referenced to the control map. | Read-only |

## Named artifacts created
- Sensitivity labels: `Protect – Legal Privileged – Restricted` (encrypted), `Protect – Legal Matter Confidential – Confidential`.
- DLP: `DLP – Legal Privileged – Simulate` (built and validated in simulation/test mode).
- Matter records: `Retention – Legal Matter Records – Publish` (retention label + publish policy), `Disposition – Legal Records – Review` (disposition stage).
- Audit evidence: `Audit Retention – Legal Evidence – LongTerm`.
- Program tracking: `Assessment – Legal Controls – Program` (Compliance Manager, in-portal).
- Governance/evidence: `Control Map – Legal – Purview`, `Evidence – Legal Controls – Binder`, pilot `Legal Pilot – Privileged Data – Stage1`.

## Definition of done
- Compliance **licensing confirmed** for labels/encryption, DLP (incl. Teams/Endpoint), records retention, and audit evidence on the legal population.
- **Sensitivity labels** published — privileged label encrypting to legal's approved scope, matter-confidential label available.
- **DLP** present and validated **in simulation**, its match report reviewed and tuned — then moved to **Enable** on the approved scope under legal sign-off.
- **Matter-records retention** in place — pilot **non-regulatory** label validated, disposition review configured where the schedule requires, and any **regulatory-records** label applied only under sign-off.
- **Unified audit on** with `Audit Retention – Legal Evidence – LongTerm` retaining evidence; eDiscovery hold coverage **visible** (read-only) for legal.
- The `Control Map – Legal – Purview` register complete and the `Evidence – Legal Controls – Binder` generated; the **validation scorecard green** for the pilot — then expanded to enforcement with a monitoring cadence and disposition review scheduled.

> **Boundary:** this solution delivers the technical control configuration and the evidence. **Privilege
> determination, matter mapping, retention adequacy, disposition triggers, and legal-hold scope are
> deferred to your legal, records, and compliance functions; legal holds and eDiscovery actions remain
> legal's.** Feature availability is **licensing-/tenant-dependent and evolving — verify against your
> entitlements and current Microsoft documentation.**
