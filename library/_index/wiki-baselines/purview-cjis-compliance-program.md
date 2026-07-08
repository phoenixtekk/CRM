# Microsoft Purview CJIS Compliance Program

> **Version 1.0.0** · Category: Purview · Solution code: CMPCJIS

> This is the online, maintained copy of the implementation guide. When this solution is updated, eligible customers are alerted and can return here for the current content. Downloadable PDF + scripts are attached on the store listing.



---


# Executive Summary — Microsoft Purview CJIS Compliance Program

## The problem
Agencies that handle **Criminal Justice Information (CJI)** must satisfy the **FBI CJIS Security Policy**
and **prove** it at a formal audit — or risk losing access to CJI systems. Microsoft Purview provides
much of the technical machinery (classification, encryption, DLP, retention, audit logging), but out of
the box none of it is **mapped to CJIS**, **configured against CJI**, or assembled into **audit
evidence**. Left as generic tenant settings, Purview does not answer the auditor's question — *show me
how CJI is protected, monitored, and retained* — and the agency scrambles to reconstruct evidence each
cycle.

## The solution
A complete, self-guided **CJIS-aligned Purview program**: a **control map** from the relevant CJIS
Security Policy areas to concrete Purview capabilities; the **configured controls** — a CJI sensitivity
label with encryption, a CJI-exfiltration DLP policy, CJI retention, and audit logging — **piloted in
simulation/test first**; and a repeatable **formal-audit evidence package** the agency's CJIS auditor and
CSA can review. Five safe-by-default PowerShell tools (read-only, or `-WhatIf`/`-Commit` with a separate
`-Enforce -Commit` for the only high-impact changes) do the assessment, scope/health checks,
configuration, validation, and evidence generation — using only Security & Compliance PowerShell,
Exchange Online, and Microsoft Graph.

## What you get
- **A CJIS-to-Purview control map** — each in-scope policy area (auditing & accountability, access
  control / information flow, information protection, media/records, personnel) mapped to the Purview
  object that implements it, with owners and status.
- **Configured CJI controls** — a `CJI – Protected – Label` with encryption, a `CJI Protection –
  Exfiltration – Policy` DLP policy (piloted in **test mode**), `CJI Records – Retention – Policy`, and
  **unified audit logging** with an audit-retention target.
- **A pilot-first, reversible rollout** — every high-impact control validated on a bounded CJI scope and
  reviewed with the security officer before enforcement.
- **A repeatable audit-evidence package** — per control, the implementing object, its state, and the
  audit reference, produced the same way every cycle for the formal audit.
- **Separation of duties by design** — the CJI configurer, audit-evidence reader, and any insider-risk
  reviewer are distinct roles; insider-risk indicators are aggregate/de-identified.

## Approach
Delivery follows a disciplined, reversible model — **Assess → Design → Configure → Pilot (simulate/test)
→ Validate → Expand** — with pass/fail gates and documented rollback, and the DLP/label/retention
controls piloted in simulation/test **before** any enforcement.

## Boundaries
CJIS is generally satisfied only in a **CJIS-authorized cloud** — **Microsoft 365 GCC High** or **Azure
Government** — under a signed Microsoft **CJIS Security Addendum**; **commercial M365 is generally not
CJIS-authorized.** Capabilities are **licensing-/cloud-dependent and evolving** — availability is cited
or flagged **"verify your environment/licensing/tenant,"** never assumed. Whether the configured controls
**satisfy** CJIS, whether the **environment** is authorized, the **records-retention schedule**, and any
**regulatory/legal determination** are **deferred to your CSA, CJIS auditor, records, and legal
functions** — the solution provides the technical method and the evidence, not the judgement.

## The bottom line
Meet CJIS with a Purview-backed program — control mapping, configured controls, and audit evidence —
**configured, piloted, validated, and defensible** in Microsoft Purview, so the next formal audit finds
the controls in place and the evidence already assembled.


---


# 1. Solution Overview — Microsoft Purview CJIS Compliance Program

## What this solution is
Agencies that handle **Criminal Justice Information (CJI)** — including Criminal History Record
Information (CHRI) — must satisfy the **FBI CJIS Security Policy**, and must be able to **prove** it at a
formal audit. Microsoft Purview provides much of the technical machinery — classification, encryption,
data loss prevention, retention/records, and audit logging — but out of the box none of it is **mapped
to CJIS**, configured **against CJI**, or assembled into **audit evidence**. This solution delivers a
**CJIS-aligned Purview program**: a **control map** from the relevant CJIS Security Policy areas to
concrete Purview capabilities; the **configured controls** (a CJI sensitivity label with encryption, a
CJI-exfiltration DLP policy, CJI retention, and audit logging) **piloted in simulation/test first**; and
a repeatable **audit-evidence package** the agency's CJIS auditor and CSA can review. It uses only the
**Microsoft Purview portal**, **Security & Compliance PowerShell**, and **Microsoft Graph** — no
third-party tooling.

> **Environment boundary — read first.** CJIS compliance is generally satisfied only in a
> **US sovereign / government cloud** — **Microsoft 365 GCC High** or **Azure Government** — under a
> signed Microsoft **CJIS Security Addendum / agreement**, with personnel screening and other
> administrative controls the platform cannot provide. **Commercial Microsoft 365 is generally not
> CJIS-authorized.** This solution configures the **technical** Purview controls and produces evidence;
> **whether your environment, agreements, and personnel controls meet CJIS is a determination for your
> CJIS Systems Agency (CSA), CJIS Systems Officer (CSO), and auditor — not this solution.** Verify your
> cloud environment and agreements before relying on any control here.

## Why this matters
- **CJIS non-compliance has real consequences.** A failed formal audit can suspend an agency's access to
  CJI systems. The controls must be **in place** and, just as importantly, **evidenced**.
- **Purview is the technical toolset, but it's unmapped.** Sensitivity labels, DLP, retention, and audit
  each contribute to CJIS policy areas (auditing & accountability, access control, information
  protection, media protection), but only once they are **explicitly mapped** and **configured against
  CJI** — not left as generic tenant settings.
- **Auditors ask for evidence, not screenshots.** "Show me how CJI is protected and monitored" needs a
  repeatable package: which control, which Purview object, what state, and the audit trail — assembled
  the same way every cycle.
- **The capabilities are licensing-dependent and evolving.** Advanced DLP, auto-labeling, Audit
  (Premium), and Compliance Manager's premium/US-gov assessment templates require **E5 / E5 Compliance**
  (some preview), and availability differs in **GCC High / Azure Government** — the program shows what
  your tenant actually has and flags the rest.

## How it works
1. **Assess.** Discovery connects (read-only) and reports the tenant's licensing (E5 / E5 Compliance,
   Audit Premium), the existing CJI-relevant labels/DLP/retention/audit configuration, the **unified
   audit logging** state, and whether a **CJIS assessment template** is available in Compliance Manager —
   flagging environment/licensing items to **verify** (GCC High / Azure Government).
2. **Map.** Build the `CJIS Control Map – Purview – Baseline`: each relevant CJIS Security Policy area →
   the Purview capability that contributes to it → the specific object that will implement it. The
   **control-satisfaction determination stays with the CSA/auditor**; the map records the technical
   method and the evidence.
3. **Configure (simulation/test first).** Scaffold the `CJI – Protected – Label` (with encryption), the
   `CJI Protection – Exfiltration – Policy` DLP policy **in test/simulation mode**, the `CJI Records –
   Retention – Policy` (staged), and confirm audit logging is on — every high-impact policy piloted
   before enforcement.
4. **Pilot.** Validate on the bounded `CJIS Pilot – CJI Scope – Stage1` — a named set of users/sites —
   reviewing the DLP simulation results with the agency's security officer before anything enforces.
5. **Validate.** A read-only validation confirms each mapped control's Purview object exists, is in the
   expected state (label encrypts, DLP in test mode, retention staged, audit on), and that **role
   separation** holds — technical pass/fail, not an adequacy judgement.
6. **Evidence & expand.** Produce the `CJIS Evidence – Formal Audit – Package` for the auditor/CSA, then
   expand the controls to enforcement under change control once the pilot passes and the agency approves.

## The CJIS policy areas Purview contributes to (verify against your current CJIS Security Policy version)
- **Auditing & Accountability** — unified audit logging + **Audit (Premium)** retention of CJI-touching
  activity; formal-audit evidence.
- **Access Control / Information Flow** — **sensitivity labels** (encryption, access scoping) and **DLP**
  to prevent CJI leaving the authorized boundary.
- **Information / System & Communications Protection** — label-based **encryption** of CJI at rest;
  DLP-enforced handling.
- **Media Protection / Records** — **retention & records** management of CJI records per the agency's
  schedule (the **schedule itself is a records/legal determination**).
- **Personnel / Insider threat (aggregate)** — where licensed, **Insider Risk** aggregate indicators,
  privacy-by-design, outcomes **deferred to the agency's HR/legal and CJIS governance**.

> Exact CJIS control numbers and the mapping to NIST 800-53 differ between CJIS Security Policy versions
> (e.g. 5.9.x vs the 6.0 restructuring). This solution maps by **policy area / control intent** and
> flags **"verify against your current CJIS Security Policy version with your CSA/CSO"** — it does not
> assert a control number it cannot confirm.

## What you can control
- The **control map** — which CJIS policy areas are in scope and which Purview objects implement them.
- The **CJI classification scheme** (the label and any custom Sensitive Information Types — the specific
  CJI identifiers come from the agency, not invented here).
- The **DLP scope and actions**, the **retention schedule** (agency determination), and the **audit
  retention** target.
- The **pilot scope**, the **thresholds/gates**, and the **evidence package** format for your auditor.

## Limitations (be honest with buyers)
- **This does not make you CJIS-compliant by itself.** It configures **technical Purview controls** and
  assembles evidence. CJIS compliance also requires the **authorized environment** (GCC High / Azure
  Government), **signed agreements**, **personnel screening**, physical/network controls, and the
  **CSA/auditor's determination** — none of which a Purview program provides.
- **Environment- and licensing-gated.** Several capabilities require **E5 / E5 Compliance** and specific
  availability in **GCC High / Azure Government**; the program shows what your tenant has and flags the
  rest as *"verify your licensing/tenant/environment."*
- **The determination is not ours.** Whether a control **satisfies** its CJIS requirement, the **records
  retention schedule**, and **regulatory applicability** are **CSA / CJIS auditor / records / legal**
  determinations. The solution provides the technical method and the evidence, not the judgement.
- **Insider Risk is privacy-sensitive.** Only **aggregate, de-identified** indicators are used, under
  strict **role separation**; outcomes are **deferred to the agency's HR/legal and CJIS governance**.

## Naming convention (used in every doc and script)
Every artifact this solution creates is named `<Purpose> – <Scope> – <Stage>` and reused verbatim across
the docs, scripts, and portal. The standard set:

| Artifact | Name |
|---|---|
| The CJIS-to-Purview control map | `CJIS Control Map – Purview – Baseline` |
| The CJI sensitivity label (encryption) | `CJI – Protected – Label` |
| The CJI-exfiltration DLP policy | `CJI Protection – Exfiltration – Policy` |
| The CJI retention/records policy | `CJI Records – Retention – Policy` |
| The Compliance Manager assessment | `CJIS Assessment – Compliance Manager – Baseline` |
| The formal-audit evidence package | `CJIS Evidence – Formal Audit – Package` |
| The pilot scope validated first | `CJIS Pilot – CJI Scope – Stage1` |

## The standard deployment model
> Assess licensing/environment and current state → map CJIS policy areas to Purview controls → configure
> the CJI label, DLP, retention, and audit in **simulation/test** → **pilot** on a bounded CJI scope and
> review with the security officer → validate each control's technical state and role separation →
> expand to enforcement and produce the formal-audit evidence package. Pattern:
> **Assess → Design → Configure → Pilot (simulate/test) → Validate → Expand (enforce).**


---


# 2. Requirements Guide — Microsoft Purview CJIS Compliance Program

Verify **every** requirement before building the program. Each entry: **Description · Why · Verify ·
Implement-if-missing.** Category-wide prerequisites (tenant/licensing, Purview roles, the S&C PowerShell
+ Graph toolchain, in-scope workloads, compliance/records/legal stakeholders, pilot & change control)
are in `global-requirements-purview.md` — this guide adds the CJIS-specific detail.

> **Environment/licensing boundary.** CJIS is generally satisfied only in **Microsoft 365 GCC High** or
> **Azure Government** under a signed Microsoft **CJIS Security Addendum**; **commercial M365 is
> generally not CJIS-authorized.** Capability availability and Compliance Manager assessment templates
> differ across these clouds and are **licensing-gated** (E5 / E5 Compliance; Audit Premium; some
> preview). Where this guide flags *"verify your environment/licensing/tenant,"* do so **with your CSA /
> CSO** before relying on a control — the program shows what you have, it never invents a control.

## 2.1 A CJIS-authorized environment and the Microsoft CJIS agreement
**Description:** A tenant in a **CJIS-authorized cloud** — typically **Microsoft 365 GCC High** or
**Azure Government** — covered by the Microsoft **CJIS Security Addendum / agreement** with your state or
the FBI, as coordinated by your **CSA/CSO**.
**Why:** CJI may only be processed in an authorized environment; the technical controls here are
necessary but **not sufficient** without the authorized environment and agreements (Overview boundary).
**Verify:** Confirm the tenant's cloud instance (GCC High / GovCloud) with your Microsoft account
team/CSA; confirm the CJIS Addendum is in place. `CMPCJIS-Discovery.ps1` reports **indicative**
environment/licensing hints but **cannot** attest the CJIS authorization — that is the CSA's.
**Implement:** If not in an authorized environment, **stop** — engage your CSA/CSO and Microsoft before
configuring CJI controls in a non-authorized tenant.

## 2.2 Compliance/data-governance licensing for the CJI controls
**Description:** The controls depend on licensing: **sensitivity labels + encryption** and **retention**
(E3 baseline; auto-labeling/advanced = E5), **DLP** (E3 baseline; advanced classifiers = E5), **Audit
(Premium)** for longer CJI audit retention (E5 / E5 Compliance), **Insider Risk** (E5 / E5 Compliance;
where used), and **Compliance Manager** CJIS/US-gov **assessment templates** (premium; verify GCC High
availability).
**Why:** A control can only be implemented where its capability is licensed and available in your cloud
(GR §1); unlicensed items are flagged *"verify,"* never fabricated.
**Verify:** M365 admin center → `Billing → Licenses`; `CMPCJIS-Discovery.ps1` reads `subscribedSkus` via
Graph and reports which CJI-control capabilities are licensed/reachable.
**Implement:** Assign/purchase the plan (e.g. E5 Compliance for Audit Premium / Insider Risk) before
expecting that control to be available.

## 2.3 Least-privilege Purview roles with separation of duties
**Description:** Least-privilege roles for each function: **Compliance Administrator / Information
Protection** (labels), **Compliance Data Administrator** (DLP/retention), **Records Management**
(records), **Audit** reader roles (audit evidence), and — where used — an **Insider Risk Management**
role held by a **separate** person. Global Administrator only where genuinely required.
**Why:** Purview uses fine-grained role groups and CJIS expects least privilege and separation of duties
(GR §2, §5); the CJI configurer, the audit-evidence reader, and any insider-risk reviewer are
deliberately separated.
**Verify:** Purview portal → `Settings → Roles & scopes / Permissions`; `CMPCJIS-ScopeCheck.ps1` reports
a permission error against any function the account can't perform.
**Implement:** Assign the least-privilege role groups under change control; keep insider-risk and
audit-investigation roles separate from the CJI-control configurer.

## 2.4 The CJI classification scheme and CJI identifiers (from the agency)
**Description:** The agency's definition of **what constitutes CJI/CHRI** in its data estate and how it
should be **classified** — the intent behind the `CJI – Protected – Label` and any **custom Sensitive
Information Types** (specific CJI identifiers — e.g. record numbers, dissemination markings — **come from
the agency**, not invented here).
**Why:** Labels, DLP, and retention key off the classification scheme (GR §4); the specific CJI
identifiers are agency data, and mis-defining them either over-blocks or leaks.
**Verify:** You can state what CJI looks like in your data and the intended label taxonomy; recorded in
the control map. `CMPCJIS-ScopeCheck.ps1` lists existing labels/SITs to build on.
**Implement:** Work with the agency's records/security owners to define CJI and the label/SIT scheme
before configuring policies.

## 2.5 Unified audit logging and an audit-retention target
**Description:** **Unified audit logging enabled** at the source and an agreed **retention target** for
CJI-touching audit activity (**Audit (Premium)** enables longer retention/retention policies for
specific activities).
**Why:** The CJIS **auditing & accountability** policy area needs an audit trail retained for the
required period; Purview audit is the source (GR §3). **The required retention duration is a CJIS/records
determination** — verify against your CJIS Security Policy version.
**Verify:** `CMPCJIS-Discovery.ps1` / `CMPCJIS-ScopeCheck.ps1` report `UnifiedAuditLogIngestionEnabled`
and whether Audit Premium is licensed; confirm the retention target with your CSA/records owner.
**Implement:** Enable unified audit logging under change control; license Audit Premium if the required
retention exceeds the default window.

## 2.6 A CJIS control map owner and the CSA/auditor engagement
**Description:** A named owner for the `CJIS Control Map – Purview – Baseline`, and engagement with the
agency's **CJIS Systems Officer (CSO)**, **CSA**, and **auditor** whose determinations the program must
satisfy (control satisfaction, retention schedule, environment authorization).
**Why:** Purview provides the technical method and evidence; **whether a control satisfies its CJIS
requirement is the CSA/auditor's determination** (GR §5, Overview boundary) — the program must be built
to their interpretation, not a technical default.
**Verify:** The control map has a named owner and the CSA/CSO/auditor are engaged and have reviewed the
mapping approach.
**Implement:** Identify the owner and engage the CJIS governance stakeholders before finalizing the map.

## 2.7 A bounded CJI pilot scope and change control
**Description:** A named **pilot scope** (`CJIS Pilot – CJI Scope – Stage1`) — a limited set of
users/sites/mailboxes containing (or simulating) CJI — to validate the label, DLP (in **test/simulation
mode**), and retention on before any tenant-wide enforcement, plus a **change-control** process.
**Why:** Label, DLP, and retention changes are high-impact; CJIS-scoped changes especially so — every
one is piloted in simulation/test first (GR §6).
**Verify:** A named pilot scope exists, simulation/test mode is confirmed available, and a change
window/approval path is agreed.
**Implement:** Define the pilot scope and change control before configuring or enforcing anything.

## 2.8 An evidence/reporting target for the formal audit
**Description:** Where the `CJIS Evidence – Formal Audit – Package` is produced and stored — the scripts
emit **CSV + HTML** by default (self-contained, no external calls) — and who (auditor/CSA) receives it,
via a **secured** channel appropriate to CJI-adjacent metadata.
**Why:** The deliverable is auditor-facing evidence; a defined, secured output/format is needed, and the
evidence itself (what's protected, where the gaps are) is sensitive.
**Verify:** The output location and secured distribution are agreed; `CMPCJIS-Report.ps1` writes the
package to the target.
**Implement:** Choose the secured output location and distribution before producing the package.


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


# 3. Implementation Guide — Microsoft Purview CJIS Compliance Program

Follow these steps **in order**. Work uses the **Microsoft Purview portal**
(`https://purview.microsoft.com`, or the GCC High / Azure Government equivalent), **Security & Compliance
PowerShell** (`Connect-IPPSSession` — labels, DLP, retention), **Exchange Online** (audit config), and
**Microsoft Graph** (licensing reads). Every write is gated: scripts run **read-only or `-WhatIf` by
default** and change state only with `-Commit`; no high-impact policy **enforces** without a separate,
explicit `-Enforce -Commit`. Artifact names follow the `<Purpose> – <Scope> – <Stage>` convention from
the Overview and are reused verbatim. **Capability availability, portal paths, and cmdlets are
plan-/cloud-dependent and the portal evolves — verify against your tenant and CJIS Security Policy
version with your CSA/CSO.**

> **Model:** confirm the authorized environment and licensing, map the CJIS policy areas to Purview
> controls, configure the CJI label/DLP/retention/audit in **simulation/test**, **pilot** on a bounded
> CJI scope, validate each control's technical state, then expand to enforcement and produce the
> audit-evidence package. Pattern: **Assess → Design → Configure → Pilot (simulate/test) → Validate →
> Expand.** **Control satisfaction, the retention schedule, and environment authorization are CSA /
> auditor / records determinations throughout — this guide provides the technical method and evidence.**

---

## Step 0 — Confirm the authorized environment (Assess — gate before anything else)
1. With your **CSA/CSO** and Microsoft account team, confirm the tenant is in a **CJIS-authorized cloud**
   (**GCC High** / **Azure Government**) and the **CJIS Security Addendum** is in place (Requirement 2.1).
2. Run `CMPCJIS-Discovery.ps1` (read-only) — it reports **indicative** environment/licensing hints but
   **cannot attest CJIS authorization**; that is the CSA's determination.
3. **Pass/fail gate:** the environment and agreements are confirmed by the CSA/CSO. **Do not configure
   CJI controls in a non-authorized tenant.** Fail → stop and engage CSA/CSO/Microsoft first.

## Step 1 — Assess licensing and current state (Assess)
1. Run `CMPCJIS-Discovery.ps1`. It reports: subscribed SKUs and which CJI-control capabilities are
   licensed (labels+encryption, DLP, retention, **Audit Premium**, Insider Risk); the existing
   CJI-relevant labels/DLP/retention; the **unified audit logging** state; and whether a **CJIS
   assessment template** is visible in Compliance Manager (flagged **verify** — availability differs in
   GCC High). Save this as the `CJIS Discovery – Tenant – Baseline` snapshot.
2. **Pass/fail gate:** the baseline is captured and the licensing gaps for any in-scope control are known
   (assign the plan, or record the control as **deferred — not licensed**). Fail → resolve licensing
   before mapping.

## Step 2 — Map CJIS policy areas to Purview controls (Design)
1. With the control-map owner and the CSA/auditor (Requirement 2.6), build the `CJIS Control Map –
   Purview – Baseline`: for each in-scope **CJIS Security Policy area** (auditing & accountability, access
   control / information flow, information/system protection, media protection/records, personnel/insider
   — **verify area numbers against your policy version**), record the **Purview capability** that
   contributes and the **specific object** that will implement it (`CJI – Protected – Label`, `CJI
   Protection – Exfiltration – Policy`, `CJI Records – Retention – Policy`, audit configuration).
2. Mark each mapping's **status** (in scope / deferred — not licensed / covered elsewhere) and its
   **owner**. **The control-satisfaction determination stays with the CSA/auditor** — the map records the
   technical method and evidence, not the judgement.
3. **Pass/fail gate:** every in-scope policy area maps to a named Purview object and owner; the CSA/auditor
   has reviewed the mapping approach. Fail → complete the map before configuring.

## Step 3 — Define the CJI classification scheme (Design)
1. With the agency's records/security owners (Requirement 2.4), define the `CJI – Protected – Label`
   taxonomy and any **custom Sensitive Information Types** for CJI identifiers — **the specific
   identifiers come from the agency**, not invented here. Decide the label's **encryption** and access
   scope (which groups may access CJI).
2. Record the scheme in the control map. `CMPCJIS-ScopeCheck.ps1` lists existing labels/SITs/workloads to
   build on and confirm the in-scope denominators.
3. **Pass/fail gate:** the label taxonomy, encryption/access intent, and any custom SITs are defined and
   agreed. Fail → complete the scheme before creating objects.

## Step 4 — Configure the controls in simulation/test (Configure → Pilot)
1. Confirm **unified audit logging** is on (Requirement 2.5): `CMPCJIS-Configure.ps1 -EnableAudit -WhatIf`
   → review → `-EnableAudit -Commit` (this enables the source audit trail — it is not a user-impacting
   content policy).
2. Scaffold the CJI label and policies **safe-first**:
   `CMPCJIS-Configure.ps1 -Scope Pilot -WhatIf` prints the exact `New-Label` / `New-DlpCompliancePolicy`
   (**Test mode**) / `New-RetentionCompliancePolicy` (**staged/disabled**) it would run. Review every
   line — confirm the DLP is **test/simulation mode**, the label encryption/access scope matches the
   design, and the scope is the **pilot** set (not tenant-wide).
3. Apply safe-first: re-run with `-Commit`. Result: `CJI – Protected – Label` exists with encryption but
   is **unpublished/pilot-scoped**; `CJI Protection – Exfiltration – Policy` exists in **test/simulation
   mode**; `CJI Records – Retention – Policy` exists **staged/disabled**. **No enforcement yet.**
4. **Pass/fail gate:** `CMPCJIS-Discovery.ps1` shows the pilot objects present in the intended safe-first
   state. **Rollback:** `CMPCJIS-Configure.ps1 -Scope Pilot -Remove -Commit` removes the objects the
   program created (it only touches its own named objects; it does not delete pre-existing policies).

## Step 5 — Pilot on the bounded CJI scope (Pilot)
1. Publish the label / target the DLP+retention to the `CJIS Pilot – CJI Scope – Stage1` population only
   (Requirement 2.7). Generate benign in-scope CJI-like activity and review the **DLP test/simulation
   results** in the portal with the agency's **security officer** — this is where an over-broad or
   mis-scoped rule is caught **before** it enforces. **Verify the simulation view/behavior in your
   tenant.**
2. Confirm CJI-touching activity is appearing in the **audit log** for the pilot scope.
3. **Pass/fail gate:** the pilot label applies, the DLP simulation matches CJI as intended (no material
   false-positives/negatives the officer rejects), retention is staged correctly, and audit captures the
   activity. Fail → tune the label/DLP/scope and re-pilot.

## Step 6 — Validate the controls and role separation (Validate)
1. Run the Testing Guide (`05-testing.md`). Run `CMPCJIS-Validate.ps1` (read-only): it confirms unified
   audit logging is on, each mapped control's Purview object exists and is in the expected state (label
   encrypts, DLP in test mode, retention staged), the **audit-retention** target is met (or flagged for
   Audit Premium), and **separation of duties** holds — a **technical** pass/fail, not an adequacy
   judgement.
2. **Pass/fail gate:** validation is technically green for the pilot and role separation holds. Fail →
   correct the control and re-validate. **Whether the controls are *sufficient* for CJIS is the
   CSA/auditor's determination.**

## Step 7 — Produce the formal-audit evidence package (Validate → Expand)
1. Run `CMPCJIS-Report.ps1` (read-only) to produce `CJIS Evidence – Formal Audit – Package` (CSV + HTML):
   the control map with, per control, the implementing Purview object, its current state, and the audit
   references — the repeatable evidence the auditor/CSA reviews (Requirement 2.8). Optionally align it to
   the `CJIS Assessment – Compliance Manager – Baseline` where the assessment template is available.
2. **Pass/fail gate:** the evidence package is produced, accurate, and delivered via the secured channel.
   Fail → correct the underlying control/evidence and regenerate.

## Step 8 — Expand to enforcement under change control (Expand — gated)
1. Only after Steps 5–7 pass and with CSA/change approval, promote the pilot controls to enforcement:
   `CMPCJIS-Configure.ps1 -Scope Pilot -Enforce -WhatIf` → review → `-Enforce -Commit`. This publishes
   the label, moves the DLP policy to **Enable (enforce)**, and applies retention — the one step that
   turns on real user/data impact, separate from the safe-first deploy by design. Then widen the scope to
   the full CJI estate and repeat Steps 4–7 for the full set.
2. Operate the program as a rhythm: schedule the read-only chain (`CMPCJIS-Discovery.ps1` →
   `CMPCJIS-Validate.ps1` → `CMPCJIS-Report.ps1`) so control **drift** and evidence are current for each
   audit cycle; re-check licensing/environment when plans or the CJIS Security Policy version change.
3. **Pass/fail gate:** the CJI controls enforce cleanly on the full scope, validation stays green, and a
   current evidence package exists for the formal audit. **Rollback:** re-run without `-Enforce`
   (`-Commit`) to return DLP to test mode / unpublish the label / stage retention; or `-Remove -Commit`
   to delete the managed objects.

---

### What this guide does NOT do
- **Attest CJIS compliance or authorize the environment.** The **CSA/CSO/auditor** determine control
  satisfaction and environment authorization; this guide configures technical controls and produces
  evidence.
- **Define the CJI identifiers or the retention schedule.** CJI identifiers come from the **agency**; the
  records retention **schedule** and regulatory applicability are **records/legal/CJIS determinations**.
- **Make insider-risk determinations.** Where Insider Risk is used, only aggregate/de-identified
  indicators are handled under role separation; outcomes are **deferred to HR/legal and CJIS governance**.


---


# 5. Testing & Validation — Microsoft Purview CJIS Compliance Program

Work through every gate. Each has a **method**, an **expected result (pass)**, and a **fail action**.
Tests are read-only except where they exercise the safe-first configuration you already committed; no
control is enforced by a test. Do not expand to enforcement or present the evidence package until every
gate passes for the pilot, then re-confirm each audit cycle.

> **Remember:** these gates prove the **technical controls are configured, in the expected state, and
> evidenced** — they do **not** prove the controls **satisfy** CJIS. Control satisfaction, the retention
> schedule, and environment authorization are **CSA / CJIS auditor / records** determinations.

## Gate 0 — The environment is CJIS-authorized (determination — not a script)
- **Method:** confirm with your **CSA/CSO** and Microsoft that the tenant is in an authorized cloud (GCC
  High / Azure Government) under the CJIS Security Addendum (Requirement 2.1).
- **Pass:** the CSA/CSO confirms the authorized environment and agreements.
- **Fail:** stop — do not configure CJI controls in a non-authorized tenant; engage CSA/CSO/Microsoft.

## Gate 1 — Licensing and current state are known
- **Method:** `CMPCJIS-Discovery.ps1` (and `CMPCJIS-ScopeCheck.ps1` for permission/health).
- **Pass:** the CJI-control capabilities are classified licensed/reachable or *"not licensed / verify,"*
  the audit-logging state is reported, and the existing CJI-relevant objects are listed.
- **Fail:** assign the missing license (Requirement 2.2) or role (2.3); a not-licensed control is recorded
  as **deferred**, not fabricated.

## Gate 2 — The control map is complete and reviewed
- **Method:** open `CJIS Control Map – Purview – Baseline`.
- **Pass:** every in-scope CJIS policy area maps to a named Purview object, a status, and an owner; the
  CSA/auditor has reviewed the mapping approach.
- **Fail:** complete the map (Implementation Step 2) and re-review with the CSA/auditor.

## Gate 3 — Unified audit logging is on and retention is targeted
- **Method:** `CMPCJIS-Validate.ps1` audit checks (and the portal audit-search settings).
- **Pass:** `UnifiedAuditLogIngestionEnabled = True`; the audit-retention target is met, or **Audit
  Premium** is flagged where longer retention is required. **The required duration is a CJIS/records
  determination.**
- **Fail:** enable unified audit logging (Implementation Step 4.1); license Audit Premium if needed;
  confirm the target with your CSA/records owner.

## Gate 4 — The CJI label exists with encryption in the expected state
- **Method:** `CMPCJIS-Discovery.ps1` / `CMPCJIS-Validate.ps1` against `CJI – Protected – Label`.
- **Pass:** the label exists, **encryption is configured**, access scope matches the design, and it is
  **unpublished/pilot-scoped** (not tenant-wide) until enforcement.
- **Fail:** correct the label configuration (Implementation Step 4); confirm encryption/access with the
  records/security owner.

## Gate 5 — The CJI DLP policy is present in test/simulation mode
- **Method:** `CMPCJIS-Validate.ps1` against `CJI Protection – Exfiltration – Policy`.
- **Pass:** the DLP policy exists in **test/simulation mode**, scoped to the pilot, targeting CJI as
  designed — **not enforcing**.
- **Fail:** return the policy to test mode / correct the scope; never leave it enforcing before the pilot
  review passes.

## Gate 6 — DLP simulation matches CJI as intended (security-officer review)
- **Method:** generate benign in-scope CJI-like activity; review the DLP test/simulation results in the
  portal with the agency's **security officer** (Implementation Step 5).
- **Pass:** the simulation matches CJI as intended with no material false-positives/negatives the officer
  rejects; the review is recorded.
- **Fail:** tune the label/SIT/DLP conditions and re-simulate before enforcing.

## Gate 7 — CJI retention is staged correctly
- **Method:** `CMPCJIS-Validate.ps1` against `CJI Records – Retention – Policy`.
- **Pass:** the retention policy exists **staged/disabled or pilot-scoped**, per the agency's schedule
  intent. **The retention schedule itself is a records/legal determination.**
- **Fail:** correct the staging; confirm the schedule with the records owner before broad application.

## Gate 8 — Separation of duties holds
- **Method:** `CMPCJIS-Validate.ps1` / `CMPCJIS-ScopeCheck.ps1` role checks.
- **Pass:** the CJI-control configurer, the audit-evidence reader, and any insider-risk reviewer are
  **separate** roles; insider-risk (where used) is aggregate/de-identified under a separate role.
- **Fail:** correct the role assignments (Requirement 2.3) before proceeding.

## Gate 9 — CJI-touching activity is captured in the audit trail
- **Method:** perform a benign in-scope action; confirm it appears in the unified audit log for the pilot
  scope.
- **Pass:** the activity is captured and retrievable within the audit search window.
- **Fail:** confirm audit logging is on and the activity type is audited; verify Audit Premium coverage
  for longer-retention activities.

## Gate 10 — The evidence package is accurate and reconciles
- **Method:** `CMPCJIS-Report.ps1` → open `CJIS Evidence – Formal Audit – Package`; spot-check each
  control's state against its Purview blade.
- **Pass:** each mapped control shows its implementing object, current state, and audit reference, and the
  states reconcile to the portal.
- **Fail:** correct the underlying control/evidence and regenerate the package.

## Evidence to retain
- `CMPCJIS-Discovery.ps1` / `CMPCJIS-ScopeCheck.ps1` outputs (licensing, current state, audit state).
- The reviewed `CJIS Control Map – Purview – Baseline`.
- The recorded DLP simulation review (Gate 6) signed off by the security officer.
- `CMPCJIS-Validate.ps1` output per cycle and the `CJIS Evidence – Formal Audit – Package`.

> Whether the configured controls **satisfy** the CJIS Security Policy — and whether the environment is
> **authorized** — are **CSA / CJIS auditor / records** determinations. These gates prove the controls
> are **configured, in the expected state, and evidenced**, not that they are **compliant**. Capability
> availability is **licensing-/cloud-dependent and evolving — verify against your entitlements, your
> cloud (GCC High / Azure Government), and your CJIS Security Policy version.**


---


# 6. Troubleshooting — Microsoft Purview CJIS Compliance Program

The failure modes that make a CJIS-aligned Purview program **non-authorized, over-blocking, or
unevidenced** — plus the environment, licensing, DLP-simulation, audit, and evidence issues you'll hit.
Each: **symptom → likely cause → fix.** The recurring lesson: this program configures **technical
controls and evidence** — it does **not** attest CJIS compliance or authorize the environment. Control
satisfaction, the retention schedule, and environment authorization are **CSA / auditor / records**
determinations; escalate those rather than treating them as tool faults.

## `CMPCJIS-Discovery.ps1` can't confirm the environment is CJIS-authorized
- **Cause:** the script reports **indicative** licensing/environment hints but **cannot** attest GCC High
  / Azure Government authorization or the CJIS Security Addendum.
- **Fix:** confirm the authorized cloud and agreements with your **CSA/CSO** and Microsoft (Requirement
  2.1) **before** configuring CJI controls. **Commercial M365 is generally not CJIS-authorized** — do not
  proceed there. This is Gate 0 and it is a determination, not a script output.

## A CJI-control capability shows `CHECK` / not licensed
- **Cause:** advanced DLP, auto-labeling, **Audit Premium**, Insider Risk, or the CJIS/US-gov Compliance
  Manager assessment template needs **E5 / E5 Compliance** and specific availability in **your** cloud —
  GCC High / Azure Government lag or differ from commercial.
- **Fix:** confirm the SKU (Requirement 2.2) and **verify availability in your cloud**; assign the plan or
  record the control as **deferred — not licensed** on the control map. Never fabricate a control state.

## The CJI DLP over-blocks legitimate criminal-justice work
- **Cause:** the DLP rule / CJI Sensitive Information Types match too broadly, or it was enforced before
  the simulation review.
- **Fix:** keep the DLP in **test/simulation mode** and review the results with the agency's **security
  officer** (Gate 6) before enforcing. Tune the CJI label/SIT conditions — **the CJI identifiers come from
  the agency**, not the tool. `CMPCJIS-Validate.ps1` FAILs if the pilot policy is not in test mode.

## The CJI DLP misses CJI (false negatives)
- **Cause:** the rule doesn't bind the CJI label or the agency's CJI identifiers, or the SITs are too
  narrow.
- **Fix:** confirm a DLP **rule** exists (`CMPCJIS-Validate.ps1` reports the rule count) and that it
  matches the `CJI – Protected – Label` and/or the agency-defined SITs. Re-simulate and review before
  enforcing. Mis-defined identifiers leak CJI — get them from the agency's records/security owners.

## The CJI label has no encryption / access scope
- **Cause:** `CMPCJIS-Configure.ps1` creates the label but leaves **encryption/access scope** to be
  finalized in the portal per the agency design (the full encryption param set is intricate and
  tenant-specific).
- **Fix:** finalize encryption and the access scope in the portal (or with the documented `Set-Label`
  encryption parameters — **verify supported params in your tenant**). `CMPCJIS-Validate.ps1` reports
  `CHECK` on label encryption until it can confirm it; treat that as an action, not a pass.

## `CMPCJIS-Validate.ps1` FAILs on unified audit logging
- **Cause:** `UnifiedAuditLogIngestionEnabled = False` — the CJIS **auditing & accountability** trail
  isn't on.
- **Fix:** `CMPCJIS-Configure.ps1 -EnableAudit -Commit` (or `Set-AdminAuditLogConfig
  -UnifiedAuditLogIngestionEnabled $true`) under change control. Confirm the required **retention
  duration** (Audit Premium) with your CSA/records owner — the duration is a determination the validator
  flags `CHECK`.

## Audit events aren't retained long enough for CJIS
- **Cause:** the default audit-retention window is shorter than the CJIS-required period, and **Audit
  Premium** / an audit-retention policy isn't in place.
- **Fix:** license **Audit (Premium)** and configure an audit-retention policy for the CJI-touching
  activities. **The required duration is a CJIS/records determination** — confirm it, don't guess.

## Separation-of-duties FAIL / role bleed
- **Cause:** the CJI-control configurer also holds an investigative role (Insider Risk / Communication
  Compliance / eDiscovery), or the audit-evidence reader is the same person.
- **Fix:** separate the roles (Requirement 2.3). Supply the role matrix to `CMPCJIS-Validate.ps1
  -RoleMatrixCsv` to catch conflicts; remove the conflicting membership. Where Insider Risk is used, keep
  it **aggregate/de-identified** under a separate role, outcomes deferred to HR/legal and CJIS governance.

## `CMPCJIS-Configure.ps1 -Enforce -Commit` caused user impact you didn't expect
- **Cause:** enforcement was applied before the pilot simulation was reviewed and signed off.
- **Fix:** enforce is the **one** step that turns on real impact and it is deliberate/gated by design.
  **Rollback:** re-run without `-Enforce` (`-Commit`) to return DLP to test mode / unpublish the label /
  disable retention; or `-Remove -Commit` to delete the program's managed objects (pre-existing policies
  are untouched). Re-review the simulation before re-enforcing.

## The evidence package shows a control as `NOT FOUND` / `OFF`
- **Cause:** the mapped object doesn't exist, isn't in the expected state, or audit is off — a **real gap**
  the package is correctly surfacing.
- **Fix:** `CMPCJIS-Report.ps1` colours these red for a reason — remediate the underlying control
  (create/enable it) and regenerate, or annotate it with the CSA if it's intentionally deferred. Don't
  edit the package to hide a gap; the auditor needs the true state.

## Policy-area numbers in the control map don't match the auditor's
- **Cause:** the CJIS Security Policy is **versioned** — 5.9.x and the 6.0 restructuring (aligned to NIST
  800-53) number and group controls differently.
- **Fix:** the program maps by **policy area / control intent** and flags `verify`. Confirm the exact
  area/control numbers against **your current CJIS Security Policy version** with your CSO/auditor and
  update the control map accordingly.

## `Connect-IPPSSession` / `Connect-ExchangeOnline` / `Connect-MgGraph` fails
- **Cause:** module not installed, MFA/modern-auth not completed, or the wrong cloud endpoint (GCC High /
  Azure Government use different endpoints).
- **Fix:** install the modules; complete the interactive sign-in (Requirement 2.3); for GCC High / Azure
  Government, connect with the correct cloud/environment parameter (verify the endpoint for your cloud).
  Read-only/`-WhatIf` scripts are safe to retry. **No credentials in code.**

## When to escalate beyond this solution
- **Whether the environment is CJIS-authorized, and whether a control *satisfies* CJIS** → **CSA / CSO /
  CJIS auditor**. This program configures technical controls and produces evidence; it does not attest
  compliance.
- **The CJI records-retention schedule and regulatory applicability** → **records and legal**.
- **The CJI identifiers that drive the label/SITs** → the **agency's records/security owners** — they are
  agency data, not invented here.
- **A cmdlet/capability that has genuinely changed or differs in your cloud** → verify against current
  Microsoft documentation for **your** cloud (GCC High / Azure Government); Purview capabilities and the
  portal evolve.


---


# 7. Best Practices — A CJIS Program Purview Can Defend

Operating principles for keeping the CJIS-aligned Purview controls accurate, least-privilege, and
audit-ready. Grounded in Microsoft's public guidance, the FBI CJIS Security Policy's intent, and the
**Assess → Design → Configure → Pilot → Validate → Expand** model.

## Configure the technical control; defer the determination
- Purview implements **technical** controls — classification, encryption, DLP, retention, audit. Whether
  a control **satisfies** its CJIS requirement, whether the environment is **authorized**, and what the
  **retention schedule** is, are **CSA / CJIS auditor / records** determinations. Build to their
  interpretation, record it in the control map, and never assert compliance the program can't attest.
- Map by **policy area / control intent**, and **verify area/control numbers against your current CJIS
  Security Policy version** (5.9.x vs 6.0 differ, and 6.0 aligns to NIST 800-53). Don't hard-code a
  control number you can't confirm with your CSO.

## Environment first — commercial cloud is not a shortcut
- CJI belongs only in an **authorized environment** — **GCC High** or **Azure Government** — under the
  Microsoft **CJIS Security Addendum**. Confirm this **before** configuring CJI controls; a perfectly
  configured control in a non-authorized tenant is still non-compliant.
- Capability availability and Compliance Manager assessment templates **differ** across GCC High / Azure
  Government and are **licensing-gated** — verify each control's availability in **your** cloud, not the
  commercial docs.

## Pilot every high-impact control in simulation/test first
- The CJI label, DLP, and retention are high-impact — a mis-scoped CJI DLP rule can block legitimate
  criminal-justice work or leak CJI. **Always** deploy DLP in **test/simulation mode**, keep the label
  **unpublished/pilot-scoped**, and stage retention **before** enforcing.
- Review the DLP **simulation results** with the agency's **security officer** before enforcement — the
  simulation is where over-blocking and false-negatives are caught safely. Enforcement is a separate,
  deliberate, change-controlled step.

## Least privilege and separation of duties
- Separate the **CJI-control configurer**, the **audit-evidence reader**, and any **insider-risk
  reviewer** — CJIS expects least privilege and separation of duties. Use least-privilege Purview role
  groups; reserve Global/Compliance Administrator for where it's genuinely required.
- Where **Insider Risk** is used, keep it **aggregate and de-identified**, under a **separate** role, with
  outcomes **deferred to the agency's HR/legal and CJIS governance** — never expose case detail in the
  CJIS program artifacts.

## Audit is the accountability backbone — protect it
- **Auditing & accountability** is a core CJIS policy area. Keep **unified audit logging on**, license
  **Audit (Premium)** where the required retention exceeds the default window, and confirm the retention
  **duration** with your CSA/records owner (it's a determination, not a default).
- Treat the audit trail and the evidence package as sensitive — they reveal where CJI lives and where the
  gaps are. Secure the storage and distribution of the evidence.

## Make the evidence repeatable
- Auditors want **repeatable evidence**, not ad-hoc screenshots. Produce the `CJIS Evidence – Formal
  Audit – Package` the same way every cycle: per control, the implementing Purview object, its state, and
  the audit reference. Schedule the read-only chain so the package is current when the audit lands.
- Where a **Compliance Manager** CJIS/US-gov assessment template is available in your cloud, align the
  package to it — but the **control-satisfaction determination stays with the CSA/auditor**.

## Respect the licensing and preview reality
- Advanced DLP, auto-labeling, Audit Premium, Insider Risk, and premium assessment templates are **E5 /
  E5 Compliance** (some **preview**) and cloud-specific. Populate a control only where its capability is
  genuinely licensed and available, and **verify the current supported method** — Purview's capabilities
  and the portal evolve, and GCC High / Azure Government lag or differ.

## Keep CJI identifiers with the agency
- The specific **CJI/CHRI identifiers** that drive the label/SITs are **agency data** — defined by the
  agency's records/security owners, not invented by the tool. Mis-defining them either over-blocks
  legitimate work or leaks CJI. Version the classification scheme and review it as the estate changes.


---


# 8. Deliverables Summary — Microsoft Purview CJIS Compliance Program

What you receive, what to run, and what "done" looks like.

## Documentation
| Document | Purpose |
|---|---|
| **1. Solution Overview** | What the CJIS-aligned Purview program is, the CJIS policy areas Purview contributes to, what you control, honest limitations, the environment boundary (GCC High / Azure Government), and the naming convention. |
| **2. Requirements Guide** | CJIS-specific prerequisites (authorized environment + CJIS agreement, control licensing incl. Audit Premium, least-privilege roles with separation of duties, CJI classification scheme, unified audit logging + retention target, control-map owner + CSA/auditor engagement, bounded pilot, secured evidence target) — each with Verify / Implement. |
| **3. Implementation Guide** | Ordered steps: confirm the authorized environment, assess licensing/state, map CJIS areas to Purview controls, configure the CJI label/DLP/retention/audit in simulation/test, pilot on a bounded CJI scope, validate, produce evidence, and expand to enforcement — pilot-first with pass/fail gates and rollback. |
| **5. Testing & Validation** | Eleven gates from "environment authorized" to "evidence package reconciles," each with method / pass / fail action. |
| **6. Troubleshooting** | The failure modes that make a CJIS program wrong, over-blocking, or unevidenced — environment/licensing gaps, DLP over/under-match, audit not retained, role bleed, evidence drift — and their fixes. |
| **7. Best Practices** | Operating principles: configure the control but defer the determination, environment first, pilot in simulation, least-privilege & separation of duties, audit as backbone, repeatable evidence, licensing/preview reality, CJI identifiers stay with the agency. |

## PowerShell tools (5)
All run **read-only or `-WhatIf` by default**; content-policy writes require `-Commit`, and no high-impact
control **enforces** without a separate `-Enforce -Commit`. No credentials or secrets are embedded.
Configuration uses **Security & Compliance PowerShell** (`Connect-IPPSSession`), **Exchange Online**
(audit config), and **Microsoft Graph** (licensing reads).

| Script | Role | Default |
|---|---|---|
| `CMPCJIS-Discovery.ps1` | Assess: licensing (labels/encryption, DLP, retention, **Audit Premium**, Insider Risk via Graph `subscribedSkus`), existing CJI-relevant objects, unified-audit-logging state, and Compliance Manager assessment-template visibility (flagged verify). | Read-only |
| `CMPCJIS-ScopeCheck.ps1` | Scope/health helper: connection/permission/licensing health across functions; list CJI-candidate labels, DLP/retention policies, workloads, and audit state; role-separation reminders. | Read-only |
| `CMPCJIS-Configure.ps1` | Configure: enable unified audit logging; scaffold `CJI – Protected – Label` (encryption), `CJI Protection – Exfiltration – Policy` (**Test mode**), and `CJI Records – Retention – Policy` (staged); enforce only with `-Enforce -Commit`. | `-WhatIf` (writes on `-Commit`) |
| `CMPCJIS-Validate.ps1` | Validate: audit logging on + retention targeted, each mapped control's object present and in the expected state, encryption on the label, DLP in test mode, retention staged, separation of duties — technical PASS/FAIL. | Read-only |
| `CMPCJIS-Report.ps1` | Report: produce `CJIS Evidence – Formal Audit – Package` (CSV + HTML) — the control map with per-control implementing object, state, and audit reference for the auditor/CSA. | Read-only (output files only) |

## Named artifacts created
- Control map: `CJIS Control Map – Purview – Baseline`.
- CJI label: `CJI – Protected – Label`. DLP: `CJI Protection – Exfiltration – Policy`. Retention:
  `CJI Records – Retention – Policy`.
- Assessment: `CJIS Assessment – Compliance Manager – Baseline`. Evidence: `CJIS Evidence – Formal Audit –
  Package`. Pilot: `CJIS Pilot – CJI Scope – Stage1`.

## Definition of done
- The **authorized environment** (GCC High / Azure Government) and CJIS agreement are **confirmed by the
  CSA/CSO**, and licensing gaps for in-scope controls are resolved or recorded as deferred.
- The **control map** is complete and reviewed with the CSA/auditor; the **CJI classification scheme** is
  agreed with the agency's records/security owners.
- The CJI **label (encryption)**, **DLP (test mode)**, **retention (staged)**, and **unified audit
  logging** are configured, **piloted on the bounded CJI scope**, and the DLP simulation is **reviewed and
  signed off** by the security officer.
- **Validation is technically green** (controls in the expected state; **separation of duties** holds),
  and the **`CJIS Evidence – Formal Audit – Package`** is produced, reconciled, and delivered via the
  secured channel; enforcement expanded under CSA/change approval.

> **Boundary:** this solution delivers **configured technical controls and repeatable evidence**. Whether
> those controls **satisfy** the CJIS Security Policy, whether the **environment** is authorized, and any
> **records-retention / regulatory / legal determination** are **deferred to your CSA, CJIS auditor,
> records, and legal functions.** Capability availability is **licensing-/cloud-dependent and evolving —
> verify against your entitlements, your cloud (GCC High / Azure Government), and your current CJIS
> Security Policy version.**
