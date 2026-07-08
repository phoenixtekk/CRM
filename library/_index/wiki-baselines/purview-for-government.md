# Microsoft Purview for Government

> **Version 1.0.0** · Category: Purview · Solution code: INDGOV

> This is the online, maintained copy of the implementation guide. When this solution is updated, eligible customers are alerted and can return here for the current content. Downloadable PDF + scripts are attached on the store listing.



---


# Executive Summary — Microsoft Purview for Government

## The problem
Government and public-sector organizations hold data that carries obligations most enterprises never face:
**Criminal Justice Information (CJI)** under the FBI CJIS Security Policy, **Controlled Unclassified
Information (CUI)** under CMMC / NIST SP 800-171, and **ITAR-controlled technical data** whose export — even
access by a foreign person — is regulated. An auditor or assessor comes down to two demands: *"show me the
control"* and *"show me the evidence."* Too often the protection exists as policy on paper, with no mapped
technical control behind it, no encryption binding protection to the data, no barrier to it leaving, and no
evidence that can be produced on demand. Left unaddressed, that is both a compliance gap and a data-risk
exposure — and it surfaces at the worst possible moment: mid-assessment.

## The solution
A complete, self-guided **Government-tailored Purview program** — an industry bundle that curates and
sequences the Purview capabilities into one defensible whole on **Microsoft Purview**. It maps the in-scope
obligations to configured controls: **sensitivity labels with encryption** for CJI/CUI/ITAR (protection
travels with the data), **DLP including endpoint DLP** to stop egress of that controlled data — **built and
piloted in simulation first** — **records retention and an audit-evidence trail**, all **tracked in
Compliance Manager** against CJIS / CMMC / NIST SP 800-171 assessment templates. Five safe-by-default
PowerShell tools (read-only or `-WhatIf` until you commit) do the assessment, scoping, configuration,
validation, and evidence reporting. It references the granular Purview products for deep how-to rather than
re-teaching them — its value is selecting, naming, and evidencing the right controls for a government tenant.

## What you get
- **An obligation-to-control register** — every in-scope obligation (CJIS, CMMC/NIST 800-171, ITAR) mapped to
  the Purview object that protects it, with the required retention/audit and a named approver.
- **CJI/CUI/ITAR sensitivity labels with encryption** — piloted for access outcomes first (an encrypting label
  changes who can open a file; ITAR access is a legal constraint) and published under sign-off.
- **DLP and endpoint DLP, simulation-first** — services and device egress (USB/print/cloud-upload) policies
  built **in simulation**, tuned against real matches, and enforced only after validation.
- **Records retention and an audit-evidence trail** — government records preservation, unified audit on, and a
  long-term retention policy keeping the evidence CJIS/CMMC call for.
- **An assessor-ready evidence binder** — control → configuration → proof, plus a DLP simulation-match
  summary, regenerated on a cadence so it is always current.

## Approach
Delivery follows a disciplined, reversible model — **Assess → Design → Configure → Pilot (simulate/test) →
Validate → Expand (enforce)** — piloting every high-impact control on a limited scope before enforcement, with
pass/fail gates and documented rollback. DLP and endpoint DLP are built in **simulation** and enforced only
after they match the right content without disrupting the mission; encrypting labels are piloted for access
before broad publish.

## Boundaries
Microsoft Purview is **licensing-/plan-dependent** (label encryption, advanced/endpoint DLP, and Audit Premium
require E5 or the E5 Compliance add-on) and **cloud-dependent** — **GCC, GCC High, and DoD differ** in feature
availability and connection endpoints, and ITAR/CUI often **require** GCC High or higher. Capabilities and
paths are cited or flagged **"verify your licensing/tenant/cloud,"** never assumed. Above all: **which data is
CJI/CUI/ITAR, which CMMC level applies, retention adequacy, ITAR access sufficiency, and whether a
configuration satisfies CJIS/CMMC/ITAR are deferred to your compliance, security, records, and legal
functions** — this solution provides the technical control and the evidence, not the determination, and makes
**no certification or authorization-to-operate claim.**

## The bottom line
A Government program that is **configured, piloted, validated, and evidenced** in Microsoft Purview — so when
an assessor asks to see the control and the proof, both are already in hand.


---


# 1. Solution Overview — Microsoft Purview for Government

## What this solution is
A government or public-sector organization holds data that carries obligations most enterprises never
face: **Criminal Justice Information (CJI)** under the FBI CJIS Security Policy, **Controlled Unclassified
Information (CUI)** under CMMC / NIST SP 800-171, and **ITAR-controlled technical data** whose export —
even a view by a foreign person — is regulated. Each demands the same two answers from an auditor or
assessor: *"show me the control"* and *"show me the evidence."* This solution delivers a **Government-tailored
Purview program** that curates and sequences the Purview capabilities into one coherent, defensible whole:
**sensitivity labels** (with encryption) for CJI/CUI/ITAR, **DLP including endpoint DLP** to stop egress of
that controlled data — **piloted in simulation first** — **retention and audit evidence**, all **tracked in
Compliance Manager** against CJIS / CMMC / NIST 800-171 assessment templates. It uses only the **Microsoft
Purview portal** (`purview.microsoft.com`), **Security & Compliance PowerShell** (`Connect-IPPSSession`), and
**Microsoft Graph** — no third-party tooling.

> **This is an industry bundle — a curated program, not a re-teaching of each granular product.** It
> references the deep how-to of the individual Purview capabilities (endpoint DLP, sensitivity-label
> encryption, retention, insider risk) rather than duplicating them; its value is **selecting, naming, and
> sequencing** the right controls for a government tenant and evidencing them together.

> **This is a technical-control-and-evidence program, not a compliance determination or an
> authorization.** *Which* data is CJI, CUI, or ITAR-controlled; *which* CMMC level applies; and whether any
> configuration *satisfies* the CJIS Security Policy, CMMC, NIST SP 800-171, or the ITAR are **compliance,
> security, and legal determinations** deferred to your organization's governance functions. This solution
> provides the register, the technical control, and the evidence — **never** the determination, a
> certification, or an authorization-to-operate claim.

## The sovereign-cloud caveat (read first)
Many government tenants run in a **sovereign cloud** — **GCC**, **GCC High**, or **DoD** — not commercial
Microsoft 365. **Feature availability, portal endpoints, and the PowerShell/Graph connection endpoints
differ** in those clouds, and ITAR/CUI workloads are frequently *required* to run in **GCC High** or higher.
This solution **never asserts** a capability is present in a given government cloud: every capability and path
is **cited or flagged "verify for your cloud/tenant."** Connection specifics — `Connect-IPPSSession
-ConnectionUri …` and `Connect-MgGraph -Environment …` for USGov/USGovDoD — are called out in the
Implementation Guide and scripts and must be confirmed for your environment.

## Why this matters
- **CJI, CUI, and ITAR carry export and handling rules with teeth.** CJI mishandling can cost CJIS access; a
  CUI lapse can sink a CMMC assessment and the contract behind it; an ITAR export — including a foreign
  person merely accessing controlled technical data — is a legal event. A **sensitivity label with encryption**
  is the Purview control that binds protection to the data itself; **DLP/endpoint DLP** is the control that
  stops it leaving. This solution puts both in place, named and evidenced.
- **The controls must fit government, not generic defaults.** A generic label/DLP build does not distinguish
  CJI from CUI from ITAR, does not encrypt, and does not map to CJIS/CMMC/NIST controls. This program tailors
  the labels, the DLP conditions, and the assessment to the government control set.
- **Egress controls are high-impact — simulate before you enforce.** A DLP or endpoint-DLP rule flipped
  straight to *block* can halt legitimate mission work. Every DLP control here is **created and piloted in
  simulation/test mode**, validated, and only then enforced.
- **Evidence is the deliverable an assessor actually wants.** A control that works but can't be *shown* fails
  an assessment. The reporting here produces a **control → configuration → proof** binder so "the control is
  in place" is provable, not asserted.
- **The controls are licensing-dependent, cloud-dependent, and evolving.** Label encryption, auto-labeling,
  advanced/endpoint DLP, Audit Premium, and Compliance Manager premium templates require **Microsoft 365 E5**
  or the **E5 Compliance** add-on (government SKUs), and behavior differs by cloud. Capabilities are **cited
  or flagged "verify your licensing/tenant/cloud,"** never assumed.

## How it works
1. **Assess.** Discover what you already have — compliance licensing/plans (in the government SKU), the
   least-privilege roles, existing sensitivity labels and label policies, DLP policies (and endpoint-DLP
   onboarding), retention labels/policies, unified-audit state and audit retention, and which cloud you are
   in — so the program is built on facts.
2. **Design the control map.** With compliance/security/records/legal, map the in-scope obligations (CJIS,
   CMMC/NIST 800-171, ITAR) to the Purview control domains and to the **named artifacts** below. The
   data-classification and rule-applicability calls are the governance functions' determination; this
   solution provides the register structure and the technical control.
3. **Configure — labels first, then DLP in simulation.** Create the CJI/CUI/ITAR sensitivity labels (with
   encryption) and their publish policy, then the DLP and endpoint-DLP policies **in simulation/test mode**,
   and the retention and audit-evidence controls. Every high-impact change is piloted before enforcement.
4. **Pilot & validate.** Prove the labels apply and encrypt, the DLP policies *match* the right controlled
   content in simulation (without blocking), retention preserves, and audit evidence is retained — on a
   bounded **pilot scope** before tenant-wide enforcement.
5. **Produce the evidence.** Generate the control-mapping + evidence binder (control → Purview object →
   configuration → proof) and the DLP simulation-match report for the compliance/assessment file.
6. **Expand & enforce.** Move DLP from simulation to enforce on the approved scope, extend the labels,
   retention, and audit-evidence policies, schedule the read-only re-assessment so drift is caught, and hand
   the register, binder, and runbook to the compliance function as a standing procedure.

## The control stack this solution curates
- **Sensitivity labels (with encryption)** — the labels `Protect – Gov CJI – Restricted`,
  `Protect – Gov CUI – Controlled`, and `Protect – Gov ITAR – Controlled` bind classification and encryption
  to CJI/CUI/ITAR data so protection travels with the file. *The label taxonomy operationalizes the
  classification your security/compliance function defines.* (Deep label-encryption/how-to: the granular
  sensitivity-labeling product — referenced, not re-taught here.)
- **Data Loss Prevention, incl. endpoint DLP** — `DLP – Gov Controlled Data – Simulate` (Exchange/SharePoint/
  OneDrive/Teams) and `DLP – Gov Endpoint Egress – Simulate` (devices: USB/print/cloud-upload) detect and
  prevent egress of CJI/CUI/ITAR — **built and validated in simulation first.** (Deep endpoint-DLP onboarding:
  the granular endpoint-DLP product — referenced.)
- **Records & data lifecycle** — retention labels/policies (`Retention – Gov Records – Publish`) for
  government records preservation and disposition.
- **Audit (Standard/Premium)** — unified audit logging and an audit-log retention policy
  (`Audit Retention – Gov Evidence – LongTerm`) keeping the who-did-what evidence.
- **Compliance Manager** — an `Assessment – Gov Controls (CJIS/CMMC/NIST 800-171) – Program` built from the
  relevant assessment template(s), tracking improvement actions and control scores — the control-tracking
  layer (configured in-portal; applicability is compliance's determination).

## What you can control
- Which **sensitivity labels** (and whether they **encrypt**) implement CJI/CUI/ITAR protection, and their
  publish scope.
- The **DLP** and **endpoint-DLP** policy scope and conditions — built in **simulation** first, enforced only
  after validation.
- Which **retention labels/policies** implement records preservation, and which record types/operations get
  **extended audit retention** as evidence.
- The **control register** (which obligation maps to which Purview object) and the **evidence binder**
  contents.
- The **pilot scope** (`Gov Pilot – Controlled Data – Stage1`) validated before any enforcement.

## Limitations (be honest with buyers)
- **We configure the control; we do not make the determination.** Which data is CJI/CUI/ITAR, which CMMC
  level applies, retention schedules, and whether a configuration satisfies CJIS/CMMC/NIST 800-171/ITAR are
  **compliance/security/records/legal** determinations. **Verify with your governance functions.** This
  solution makes **no certification or authorization-to-operate claim.**
- **Sovereign-cloud differences are real and must be verified.** GCC/GCC High/DoD differ in feature
  availability and endpoints; ITAR/CUI often mandate GCC High. **Do not assume** a capability shown here is
  present in your cloud — verify.
- **Egress enforcement can disrupt the mission.** DLP/endpoint-DLP set to *block* can stop legitimate work —
  which is why every DLP control is **piloted in simulation** and enforced only after validation, with a
  documented rollback.
- **Label encryption changes access and portability.** An encrypting label restricts who can open a file and
  can affect downstream tooling; pilot it and confirm access outcomes before broad publish.
- **Endpoint DLP requires device onboarding and the right licensing/cloud.** Devices must be onboarded and
  the endpoint-DLP capability licensed/available in your cloud — **verify** before expecting device egress
  control.

## Naming convention (used in every doc and script)
Every artifact this solution creates is named `<Purpose> – <Scope> – <Stage>` and reused verbatim across the
docs, scripts, and portal. The standard set:

| Artifact | Name |
|---|---|
| CJI sensitivity label (encrypt) | `Protect – Gov CJI – Restricted` |
| CUI sensitivity label (encrypt) | `Protect – Gov CUI – Controlled` |
| ITAR sensitivity label (encrypt) | `Protect – Gov ITAR – Controlled` |
| Controlled-data DLP policy (simulation) | `DLP – Gov Controlled Data – Simulate` |
| Endpoint egress DLP policy (simulation) | `DLP – Gov Endpoint Egress – Simulate` |
| Government records retention publish policy | `Retention – Gov Records – Publish` |
| Audit evidence retention policy | `Audit Retention – Gov Evidence – LongTerm` |
| Compliance Manager assessment | `Assessment – Gov Controls (CJIS/CMMC/NIST 800-171) – Program` |
| Control-mapping register | `Control Map – Gov – Purview` |
| Evidence binder export | `Evidence – Gov Controls – Binder` |
| Pilot validation scope | `Gov Pilot – Controlled Data – Stage1` |

## The standard deployment model
> Assess the controls, licensing, and cloud you have → design the obligation-to-control map with
> compliance/security/legal → configure sensitivity labels, DLP/endpoint DLP, retention, and audit evidence →
> **pilot in simulation/test mode** on a limited scope → validate the controls work and produce evidence →
> expand to enforcement. Pattern: **Assess → Design → Configure → Pilot (simulate/test) → Validate → Expand
> (enforce).** High-impact controls (encrypting labels, DLP, endpoint DLP, retention) are always piloted
> before enforcement.


---


# 2. Requirements Guide — Microsoft Purview for Government

Verify **every** requirement before configuring. Each entry: **Description · Why · Verify ·
Implement-if-missing.** Category-wide prerequisites (tenant/licensing, Purview roles, the S&C PowerShell +
Graph toolchain, in-scope workloads, compliance/records/legal stakeholders, pilot & change control) are in
`global-requirements-purview.md` — this guide adds the **Government-program** detail (CJIS/CMMC/ITAR,
sensitivity labels, DLP/endpoint DLP, and the sovereign-cloud specifics).

> **Regulatory/licensing/cloud boundary.** Label encryption, auto-labeling, advanced and **endpoint DLP**,
> Audit Premium, and premium Compliance Manager templates require **Microsoft 365 E5** or the **E5
> Compliance** add-on (in the government SKU) and evolve; behavior and endpoints **differ by cloud**
> (GCC/GCC High/DoD). **Which data is CJI/CUI/ITAR, which CMMC level applies, retention schedules, and
> whether a configuration satisfies CJIS/CMMC/NIST 800-171/ITAR** are **compliance/security/records/legal
> determinations** — this solution configures the control and produces evidence; it does not make the
> determination, and makes **no authorization/certification claim.** Where this guide flags "verify your
> licensing/tenant/cloud," do so before relying on the item.

## 2.1 Government tenant, cloud, and compliance licensing
**Description:** A Microsoft 365 **government** tenant, and knowledge of **which cloud** it is —
**Commercial**, **GCC**, **GCC High**, or **DoD**. The program's control domains are plan-gated:
**sensitivity-label encryption + auto-labeling** and **advanced/endpoint DLP** need **E5 / E5 Compliance**;
**Audit Premium** (long-term retention, high-value events) needs **E5 / E5 Compliance / Audit add-on**;
premium **Compliance Manager** templates are licensing-gated. ITAR/CUI workloads are frequently **required**
to run in **GCC High** or higher.
**Why:** Every control below is plan- and cloud-gated; the feature may be unavailable, or behave/route
differently, without the right plan and cloud (GR §1).
**Verify:** M365 admin center → `Billing → Licenses`; confirm the cloud (GCC/GCC High/DoD) with your tenant
admin; run `INDGOV-Discovery.ps1`, which reports whether label/DLP/Audit-Premium-bearing plans are present
via Graph. **Confirm plan/service-plan names against your tenant and cloud — they differ and change.**
**Implement:** Assign/purchase E5 or the relevant add-ons to in-scope users; where ITAR/CUI mandates it,
confirm the tenant is in the required cloud **before** relying on the controls.

## 2.2 Least-privilege roles for labels, DLP, records, and audit
**Description:** Distinct least-privilege roles per domain — **Information Protection** (Admin/Analyst/
Investigator/Reader) for **sensitivity labels**; **Compliance Administrator / DLP Compliance Management** for
**DLP and endpoint DLP**; **Records Management / Retention Management** for retention; **Audit Manager/Reader**
for evidence; **Compliance Manager** roles for the assessment. Global Administrator only where genuinely
required.
**Why:** Purview uses fine-grained role groups; configuration requires the matching role, and separating
duties (who configures vs who reviews DLP matches / reads audit evidence) is itself a control (GR §2).
**Verify:** Purview portal → `Settings → Roles & scopes / Permissions` — confirm membership per domain;
`INDGOV-Scope.ps1` reports the role groups it can see and the connection identity.
**Implement:** Assign the least-privilege role groups under change control; document who may read DLP matches
and audit evidence (they are sensitive).

## 2.3 Security & Compliance PowerShell + Graph toolchain — with the correct cloud endpoints
**Description:** A workstation with the `ExchangeOnlineManagement` module (for `Connect-IPPSSession` —
sensitivity labels `*-Label`/`*-LabelPolicy`, DLP `*-DlpCompliancePolicy`/`*-DlpComplianceRule`, retention
`*-ComplianceTag`/`*-RetentionCompliancePolicy`, `*-UnifiedAuditLogRetentionPolicy`) and `Microsoft.Graph`
(licensing reads), with a modern-auth/MFA admin. **In a sovereign cloud you must pass the cloud endpoint:**
`Connect-IPPSSession -ConnectionUri <your cloud's S&C endpoint>` and `Connect-MgGraph -Environment
USGov|USGovDoD`.
**Why:** All configuration and the provided scripts run through S&C PowerShell and Graph; **the default
(commercial) endpoints will not connect a GCC High/DoD tenant** (GR §3).
**Verify:** `Get-Module -ListAvailable ExchangeOnlineManagement`; `Connect-IPPSSession` (with the cloud
`-ConnectionUri` if applicable) and `Connect-MgGraph -Environment …` succeed; `INDGOV-Discovery.ps1` reports
which endpoints are reachable. **Confirm the exact `-ConnectionUri`/`-Environment` for your cloud from
Microsoft's current documentation.**
**Implement:** `Install-Module ExchangeOnlineManagement -Scope CurrentUser`; `Install-Module Microsoft.Graph
-Scope CurrentUser`; record your cloud's connection parameters in the runbook.

## 2.4 In-scope controlled data, workloads, endpoints, and classification intent
**Description:** The **CJI / CUI / ITAR data** in scope, the **workloads** holding it (Exchange, SharePoint,
OneDrive, Teams) and the **endpoints/devices** to control (for endpoint DLP), plus a **classification
intent** (which sensitivity label maps to CJI, CUI, ITAR) that drives labels and DLP. **Endpoint DLP requires
devices to be onboarded.**
**Why:** Labels, DLP, and endpoint DLP key off the in-scope data/workloads/devices and the classification
scheme (GR §4).
**Verify:** Confirm the in-scope controlled-data types, workloads, and (for endpoint DLP) onboarded devices
with security/compliance; `INDGOV-Scope.ps1` enumerates the target population, in-scope mailboxes/sites, and
reports device-onboarding readiness pointers (read-only).
**Implement:** Define the controlled-data scope and classification intent, and onboard the pilot devices for
endpoint DLP, before authoring policies. **Which data *is* CJI/CUI/ITAR is a compliance/security
determination.**

## 2.5 The obligation-to-control map (from compliance/security/records/legal)
**Description:** A documented statement — **from compliance, security, records, and legal** — of which
obligations are in scope (CJIS Security Policy, CMMC level / NIST SP 800-171, ITAR), which data each governs,
what must be **retained and for how long**, and who approves. This populates
`Control Map – Gov – Purview`.
**Why:** Rule applicability, CMMC level, data classification, and retention duration are
**regulatory/security/legal determinations**, not technical defaults (GR §5); the solution configures to them
and evidences them — it does not decide them.
**Verify:** You can name, per obligation, the controlled-data type, the required control (label/DLP/retention/
audit), and the named approver.
**Implement:** Capture the obligation-to-control map and retention schedule with approvals before configuring
— especially before publishing an **encrypting** label or enforcing any **DLP**.

## 2.6 ITAR / encryption / access preconditions
**Description:** For the ITAR and encrypting-label controls specifically: agreement on **who may decrypt**
(e.g. U.S.-person access constraints for ITAR technical data), the label's **encryption/rights** definition,
whether **guest/external** access must be blocked, and the disposition of DLP matches involving controlled
data.
**Why:** An encrypting label changes who can open a file, and ITAR access is a legal constraint — mis-scoped
access or decryption is a control failure and potentially an export event (GR §5, and the category's
sensitivity rules). **Whether a given access configuration satisfies ITAR is legal's determination.**
**Verify:** Named decryption/access rules, an approved encryption/rights definition per label, and a
sign-off on external-access posture.
**Implement:** Obtain the access/encryption sign-off; define the label's rights in-portal; **pilot the label
on non-production content** and confirm access outcomes before broad publish.

## 2.7 Unified audit logging on, and an evidence-retention requirement
**Description:** `UnifiedAuditLogIngestionEnabled` must be **true** so the audit-trail control captures
evidence, plus a documented statement of how long audit **evidence** must be retained (e.g. for CJIS/CMMC
audit-log requirements).
**Why:** No audit evidence is written while ingestion is off, and it is **not retroactive**; retention
duration is a compliance determination (GR §5/§6).
**Verify:** `INDGOV-Discovery.ps1` reports `UnifiedAuditLogIngestionEnabled` and existing audit retention
policies. **Confirm long-term retention is licensed/available in your cloud.**
**Implement:** Enable unified audit under change control, then create the evidence-retention policy in the
Implementation Guide.

## 2.8 A pilot scope, simulation/test mode, and change control
**Description:** A bounded **pilot scope** (`Gov Pilot – Controlled Data – Stage1` — a small set of users/
sites/devices) and a **change-control** window. **DLP and endpoint DLP support a simulation/test mode** that
MUST be used before enforcement; encrypting labels are piloted on non-production content first; retention/
audit changes are reversible.
**Why:** Encrypting labels, DLP, endpoint DLP, and retention are **high-impact** — a DLP block can halt
mission work and an encrypting label changes access — so every change is piloted in simulation/test mode
before enforcement (GR §6).
**Verify:** A named pilot scope, confirmation that simulation/test mode is available for DLP/endpoint DLP in
your cloud, and a change window/approval path.
**Implement:** Define the pilot scope and agree change control before enabling or enforcing any control —
**never move a DLP policy from simulation to enforce, or publish an encrypting label broadly, without
validation and sign-off.**


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


# 3. Implementation Guide — Microsoft Purview for Government

Follow these steps **in order**. Configuration uses the **Microsoft Purview portal**
(`https://purview.microsoft.com`), **Security & Compliance PowerShell** (`Connect-IPPSSession` — the
`*-Label`/`*-LabelPolicy`, `*-DlpCompliancePolicy`/`*-DlpComplianceRule`, `*-ComplianceTag`/
`*-RetentionCompliancePolicy`, and `*-UnifiedAuditLogRetentionPolicy` cmdlets), and **Microsoft Graph**
(licensing). Every write is gated: scripts run **read-only or `-WhatIf` by default** and only change state
with `-Commit`. Artifact names follow the `<Purpose> – <Scope> – <Stage>` convention from the Overview and
are reused verbatim.

> **Model:** Assess the controls/licensing/cloud you have → design the obligation-to-control map with
> compliance/security/legal → configure sensitivity labels, DLP/endpoint DLP, retention, and audit evidence
> → **pilot in simulation/test mode** → validate and evidence → expand to enforcement. Pattern: **Assess →
> Design → Configure → Pilot (simulate/test) → Validate → Expand (enforce).**
>
> **Sovereign-cloud note:** in GCC High/DoD you MUST connect with the cloud endpoint —
> `Connect-IPPSSession -ConnectionUri <your cloud's S&C endpoint>` and `Connect-MgGraph -Environment
> USGov|USGovDoD`. **Verify the exact endpoint/environment for your cloud** before running any step.
>
> **Determination boundary:** which data is CJI/CUI/ITAR, which CMMC level applies, retention durations, and
> whether a configuration *satisfies* CJIS/CMMC/NIST 800-171/ITAR are **compliance/security/records/legal**
> determinations. This guide configures the control and evidences it; it does not make the determination or
> claim any authorization/certification. **DLP is high-impact — never enforce a policy that has not passed
> simulation and sign-off; never publish an encrypting label broadly before piloting access outcomes.**

## Step 1 — Assess current controls, licensing, and cloud (Assess)
1. Run `INDGOV-Discovery.ps1` (read-only). It connects to Security & Compliance PowerShell and Graph
   (pass your cloud endpoints where applicable) and reports:
   - compliance licensing present (sensitivity-label / DLP / Audit-Premium-bearing plans — **verify plan
     names for your tenant and cloud**),
   - existing **sensitivity labels** (`Get-Label`) and **label policies** (`Get-LabelPolicy`), flagging which
     **encrypt**,
   - existing **DLP policies** (`Get-DlpCompliancePolicy`), flagging **mode** (simulation vs enforce) and any
     with **endpoint (Devices)** locations,
   - existing **retention labels/policies** (`Get-ComplianceTag` / `Get-RetentionCompliancePolicy`),
   - `UnifiedAuditLogIngestionEnabled` and existing **audit retention policies**
     (`Get-UnifiedAuditLogRetentionPolicy`).
2. Run `INDGOV-Scope.ps1` (read-only) to enumerate the intended in-scope population, mailboxes/sites, the
   role groups it can see, and endpoint-onboarding readiness pointers (Requirement 2.2/2.4).
3. Record the gaps across the control domains. **Pass gate:** a written current-state for labels, DLP/endpoint
   DLP, retention, and audit — and a confirmed cloud (GCC/GCC High/DoD).

## Step 2 — Design the obligation-to-control map (Design)
1. With compliance/security/records/legal (Requirement 2.5), populate the `Control Map – Gov – Purview`
   register: for each in-scope obligation (CJIS, CMMC/NIST 800-171, ITAR), name the controlled-data type, the
   Purview control object that protects it, the required retention/audit, and the approver. **The
   classification and rule-to-control mapping are governance's determination; you provide the register and the
   technical control.**
2. Map the obligations to the standard named artifacts:
   - CJI protection → `Protect – Gov CJI – Restricted` (encrypting label).
   - CUI protection → `Protect – Gov CUI – Controlled` (encrypting label).
   - ITAR technical-data protection → `Protect – Gov ITAR – Controlled` (encrypting label, with U.S.-person
     access constraints per legal).
   - Egress prevention → `DLP – Gov Controlled Data – Simulate` (services) + `DLP – Gov Endpoint Egress –
     Simulate` (devices).
   - Records preservation → `Retention – Gov Records – Publish`.
   - Audit evidence → `Audit Retention – Gov Evidence – LongTerm`.
   - Control tracking → `Assessment – Gov Controls (CJIS/CMMC/NIST 800-171) – Program` (Compliance Manager).
3. Define the pilot scope `Gov Pilot – Controlled Data – Stage1` (Requirement 2.8) and the encryption/access
   sign-off for the labels (Requirement 2.6). **Pass gate:** the control map, retention schedule, encryption/
   access design, pilot, and approvals are documented.

## Step 3 — Configure the sensitivity labels — pilot access outcomes first (Configure → Pilot)
1. Create the three government labels with the helper, `-WhatIf` first (prints the exact `New-Label` it would
   run). **Pilot on non-production content** and confirm who can open/decrypt before broad publish:
   - `INDGOV-Configure.ps1 -Control Labels -WhatIf` → review → `-Commit` (creates
     `Protect – Gov CJI – Restricted`, `Protect – Gov CUI – Controlled`, `Protect – Gov ITAR – Controlled`).
   **Define the encryption/rights per label in-portal** (who may decrypt; for ITAR, the U.S.-person access
   constraint your legal function specified — **that access rule is legal's determination**).
2. Publish the labels to the **pilot scope only** first via a label policy (`New-LabelPolicy` scoped to
   `Gov Pilot – Controlled Data – Stage1`), confirm the labels appear and encrypt as designed, then expand
   publish on sign-off.
3. **Pass gate:** `INDGOV-Discovery.ps1` lists the labels with the expected encryption, published to the
   pilot; pilot users can apply them and access behaves as designed. **Rollback:** unpublish the label policy
   / remove the pilot labels (`-Control Labels -Remove -Commit`); note that content already encrypted retains
   its protection — verify decryption/access recovery in your tenant before broad use.

## Step 4 — Configure the DLP controls — IN SIMULATION (Configure → Pilot)
1. **Create both DLP policies in simulation/test mode**, scoped to the pilot. The helper defaults DLP to
   simulation and `-WhatIf`:
   - Services DLP: `INDGOV-Configure.ps1 -Control DLP -WhatIf` → review → `-Commit` (creates
     `DLP – Gov Controlled Data – Simulate` across Exchange/SharePoint/OneDrive/Teams, in **simulation**, with
     the conditions your compliance/security function specified — CJI/CUI/ITAR sensitive-info types and/or the
     government labels — **the conditions/SITs are governance's determination**).
   - Endpoint DLP: `INDGOV-Configure.ps1 -Control EndpointDLP -WhatIf` → review → `-Commit` (creates
     `DLP – Gov Endpoint Egress – Simulate` for **Devices**, in **simulation**, covering USB/print/cloud-upload
     egress). **Requires devices onboarded and endpoint DLP licensed/available in your cloud (Requirement
     2.4/2.1).**
2. Let simulation run and review **what would have matched/blocked** with `INDGOV-Report.ps1` — tune
   conditions to reduce false positives/negatives **before** any enforcement. **Do not enforce yet.**
3. **Pass gate:** both DLP policies exist **in simulation**, scoped to the pilot, and simulation surfaces the
   expected controlled-data matches without blocking. **Rollback:** remove the policy
   (`-Control DLP|EndpointDLP -Remove -Commit`) — simulation makes no user-facing change, so rollback is
   clean.

## Step 5 — Configure the records-retention and audit-evidence controls (Configure)
1. Create the government records retention publish policy pilot-first:
   - `INDGOV-Configure.ps1 -Control Retention -WhatIf` → review → `-Commit` (creates a retention label +
     `Retention – Gov Records – Publish` scoped to the pilot; **confirm the retention duration/disposition
     with records — that is their determination**).
2. Confirm unified audit is on (Requirement 2.7), then create the evidence-retention policy:
   - `INDGOV-Configure.ps1 -Control Audit -PolicyName "Audit Retention – Gov Evidence – LongTerm" -WhatIf` →
     review → `-Commit` (creates a `New-UnifiedAuditLogRetentionPolicy` for the record types/operations your
     compliance function requires as evidence, at the agreed duration and a unique priority). **Verify accepted
     `RetentionDuration` values and that the long-term tier is licensed in your cloud (Requirement 2.1).**
3. **Pass gate:** `INDGOV-Discovery.ps1` lists the retention policy and the audit retention policy with the
   expected duration/priority. **Rollback:** `-Control Retention|Audit -Remove -Commit` (already-retained
   records age out under remaining rules).

## Step 6 — Track the program in Compliance Manager (Configure, in-portal)
1. In the Purview portal → **Compliance Manager**, create/assign
   `Assessment – Gov Controls (CJIS/CMMC/NIST 800-171) – Program` from the relevant **assessment template(s)**
   — CJIS Security Policy, CMMC, and/or NIST SP 800-171 (**template availability depends on your licensing and
   cloud — verify in-portal**). Map its improvement actions to the Purview controls configured above.
2. Record, per improvement action, the implementing Purview object and its evidence location (this cross-links
   to `Control Map – Gov – Purview`). **Pass gate:** the assessment reflects the configured controls with
   evidence links. *(Assessment content and applicability — and which CMMC level applies — are compliance's
   determination; no cmdlet invents this, it is authored in-portal.)*

## Step 7 — Validate the controls and generate evidence (Validate)
1. Run `INDGOV-Validate.ps1` (read-only) to score the program across gates: labels present and encrypting and
   published to the pilot; DLP + endpoint DLP present **in simulation**; retention present; audit ingestion on
   with the evidence policy in place; the pilot scope covered.
2. Run `INDGOV-Report.ps1` (read-only) to produce `Evidence – Gov Controls – Binder` — a control → Purview
   object → configuration → proof export (CSV/JSON) plus the **DLP simulation-match** summary — for the
   compliance/assessment file, cross-referenced to `Control Map – Gov – Purview`.
3. Complete the **Testing Guide** before expanding. **Pass gate:** the validation scorecard is green for the
   pilot scope and the evidence binder is generated.

## Step 8 — Expand to enforcement and operationalize (Expand)
1. Once the pilot passes and compliance/security sign off, expand scope: publish the labels to the full
   in-scope population, **move `DLP – Gov Controlled Data – Simulate` and `DLP – Gov Endpoint Egress –
   Simulate` from simulation to enforce** (rename/re-stage per your convention if desired, keeping the control
   traceable), and extend the retention and audit-evidence policies — each under change control.
2. Schedule the read-only chain (`INDGOV-Discovery.ps1` → `INDGOV-Validate.ps1` → `INDGOV-Report.ps1`) on a
   cadence so drift — a DLP policy dropped back to simulation or disabled, an unpublished label, a lapsed
   license, audit turned off, a device off-boarded — is caught, and re-generate the evidence binder before
   each assessment. **Pass gate:** controls enforced on the approved scope, evidence binder current,
   monitoring cadence scheduled. Hand the register, binder, and runbook to the compliance function as the
   standing procedure. **This delivers and evidences the controls; it does not certify CJIS/CMMC/ITAR
   compliance — that determination is your governance functions'.**


---


# 5. Testing & Validation — Microsoft Purview for Government

Work through every gate. Each has a **method**, an **expected result (pass)**, and a **fail action**. Tests
are read-only or use **benign, self-generated pilot content** on the pilot scope — no production controlled
data is exfiltrated and no DLP policy is enforced during testing. Do not declare "ready to enforce" until
every gate passes for the pilot scope, then re-confirm on expand.

> **Boundary:** these gates prove the **technical control works and is evidenced**. Whether the control
> **satisfies** the CJIS Security Policy, CMMC / NIST SP 800-171, or the ITAR — classification correctness,
> retention adequacy, CMMC-level fit, access sufficiency — is a **compliance/security/records/legal
> determination**, not a test outcome, and this solution makes **no certification/authorization claim.**
> **Sovereign cloud:** confirm each cmdlet/feature behaves as expected **in your cloud** (GCC/GCC High/DoD).

## Gate 1 — Compliance licensing present for each control (in your cloud)
- **Method:** `INDGOV-Discovery.ps1` licensing section (Graph `subscribedSkus` / service plans; connect with
  the correct `-Environment` for your cloud).
- **Pass:** sensitivity-label (encryption/auto-label), DLP/endpoint-DLP, and Audit-Premium-bearing plans are
  present and assigned to the in-scope population.
- **Fail:** assign the license (Requirement 2.1); a missing plan makes the corresponding control unavailable
  — a licensing gap, not a config defect. **Verify plan names for your tenant and cloud.**

## Gate 2 — Connectivity to the correct cloud endpoint
- **Method:** `INDGOV-Discovery.ps1` / `INDGOV-Scope.ps1` connect via `Connect-IPPSSession -ConnectionUri …`
  and `Connect-MgGraph -Environment …` for your cloud.
- **Pass:** both endpoints connect and enumerate objects.
- **Fail:** confirm the exact `-ConnectionUri` / `-Environment` for GCC/GCC High/DoD from current Microsoft
  documentation; the commercial defaults will not connect a sovereign tenant.

## Gate 3 — Government labels exist, encrypt, and publish to the pilot
- **Method:** `INDGOV-Discovery.ps1` / portal — confirm `Protect – Gov CJI – Restricted`,
  `Protect – Gov CUI – Controlled`, `Protect – Gov ITAR – Controlled` exist (`Get-Label`), are configured to
  **encrypt**, and are published (`Get-LabelPolicy`) to `Gov Pilot – Controlled Data – Stage1`.
- **Pass:** all three labels exist, encrypt per the approved rights, and are available to pilot users.
- **Fail:** confirm the label's encryption/rights definition and the label-policy scope; re-verify. **Confirm
  the ITAR access constraint with legal before wider publish.**

## Gate 4 — Label applies and access behaves as designed (pilot content)
- **Method:** apply each label to benign pilot content; confirm encryption applies and that an authorized user
  can open it while an out-of-scope/external user cannot (per the approved rights).
- **Pass:** the label applies, content is encrypted, and access matches the design.
- **Fail:** adjust the rights definition in-portal and retest; **do not broaden publish until access outcomes
  are correct** — an encrypting label changes who can open a file.

## Gate 5 — Services DLP present IN SIMULATION and matching the right content
- **Method:** `INDGOV-Discovery.ps1` / `INDGOV-Validate.ps1` — confirm `DLP – Gov Controlled Data – Simulate`
  exists (`Get-DlpCompliancePolicy`), is in **simulation/test mode**, scoped to the pilot; generate benign
  test content matching the CJI/CUI/ITAR conditions and confirm simulation records a match.
- **Pass:** the policy exists in simulation, is pilot-scoped, and simulation surfaces the expected matches
  **without blocking**.
- **Fail:** confirm the conditions/SITs and scope; tune to reduce false positives/negatives. **Conditions/SIT
  adequacy is governance's determination, not a test.** **Do not enforce.**

## Gate 6 — Endpoint DLP present IN SIMULATION on onboarded devices
- **Method:** `INDGOV-Discovery.ps1` — confirm `DLP – Gov Endpoint Egress – Simulate` exists for **Devices**
  in simulation; on a pilot **onboarded** device, attempt a benign USB/print/cloud-upload of test content and
  confirm simulation records the egress (without blocking).
- **Pass:** the endpoint policy exists in simulation, the pilot device is onboarded, and egress attempts are
  recorded.
- **Fail:** confirm device onboarding and endpoint-DLP licensing/availability **in your cloud**; verify the
  egress-channel conditions; retest. **Do not enforce.**

## Gate 7 — Records retention scoped and audit on with evidence policy
- **Method:** `INDGOV-Discovery.ps1` — confirm `Retention – Gov Records – Publish` exists/enabled and scoped
  to the pilot; confirm `UnifiedAuditLogIngestionEnabled = True` and `Audit Retention – Gov Evidence –
  LongTerm` present (`Get-UnifiedAuditLogRetentionPolicy`).
- **Pass:** retention is scoped and enabled; ingestion is True and the audit-evidence policy exists at the
  agreed duration/priority.
- **Fail:** correct the retention scope/duration (records' determination) and/or enable ingestion under change
  control; verify the `RetentionDuration` value and licensing.

## Gate 8 — Control map and evidence binder generated
- **Method:** `INDGOV-Report.ps1` → `Evidence – Gov Controls – Binder`, cross-referenced to
  `Control Map – Gov – Purview`, including the **DLP simulation-match** summary.
- **Pass:** every in-scope obligation maps to a Purview object with its configuration and a proof reference;
  the binder and simulation summary export cleanly.
- **Fail:** fill the gap (missing control or missing evidence) and re-run. A control with no evidence fails an
  assessment.

## Gate 9 — Validation scorecard is green (pilot)
- **Method:** `INDGOV-Validate.ps1`.
- **Pass:** every gate above is green for the pilot scope (and, on expand, for the approved production scope).
- **Fail:** address the specific red item and re-run before enforcing anything or broadening publish.

## Evidence to retain
- `INDGOV-Discovery.ps1` and `INDGOV-Validate.ps1` outputs (before/after).
- The `-WhatIf` transcripts for every label, DLP, endpoint-DLP, retention, and audit change.
- The `INDGOV-Report.ps1` **DLP simulation-match** summary and the `Evidence – Gov Controls – Binder` export
  and `Control Map – Gov – Purview` register.
- The compliance/security/legal sign-offs (data classification, encryption/ITAR access, DLP enforcement,
  retention schedule) and the pilot roster/approvals (Requirement 2.5/2.6/2.8).

> Classification correctness, retention adequacy, CMMC-level fit, ITAR access sufficiency, and rule
> applicability are **compliance/security/records/legal determinations** — these gates prove the Purview
> controls work and are evidenced, not that the program satisfies CJIS/CMMC/ITAR. Feature behavior is
> **cloud-dependent — verify in your cloud.**


---


# 6. Troubleshooting — Microsoft Purview for Government

The failure modes you are most likely to hit, and how to fix them. Each entry: **symptom → likely cause →
fix**. Read-only diagnostics first; only change state through `INDGOV-Configure.ps1` (which is `-WhatIf` by
default and keeps DLP in simulation). Remember the boundary: **classification (CJI/CUI/ITAR), CMMC level,
retention adequacy, and ITAR access are compliance/security/records/legal determinations**, and behavior is
**cloud-dependent — verify in your cloud.**

## `Connect-IPPSSession` / `Connect-MgGraph` fails or connects the wrong tenant
- **Likely cause:** you are in a sovereign cloud (GCC High/DoD) but used the **commercial** endpoint — the
  default endpoints will not connect a sovereign tenant.
- **Fix:** pass your cloud's endpoint: `Connect-IPPSSession -ConnectionUri <your cloud's S&C endpoint>` and
  `Connect-MgGraph -Environment USGov|USGovDoD`. All five scripts accept `-ConnectionUri` / `-GraphEnvironment`.
  **Verify the exact endpoint/environment for your cloud from current Microsoft documentation** — do not
  assume the value shown in an example.

## A capability is missing from the portal or a cmdlet errors "not recognized"
- **Likely cause:** the feature is **not licensed** (needs E5 / E5 Compliance in your gov SKU), or **not
  available in your cloud** (GCC/GCC High/DoD differ), or the module is out of date.
- **Fix:** run `INDGOV-Discovery.ps1` licensing section; confirm the plan is present **and assigned** to
  in-scope users (Requirement 2.1). Update `ExchangeOnlineManagement` / `Microsoft.Graph`. If the capability
  genuinely isn't in your cloud, that is a **cloud/licensing gap**, not a config defect — verify with your
  tenant admin.

## Graph licensing check reports plans "NOT found" that you believe you have
- **Likely cause:** **service-plan names differ in government SKUs** and change over time; the indicative
  names in `INDGOV-Discovery.ps1` are examples to **verify**, not authoritative.
- **Fix:** list your actual plans (`Invoke-MgGraphRequest -Method GET -Uri '/v1.0/subscribedSkus'`) and match
  the capability to the plan name **your** tenant uses. Update the script's `$wanted` map to your cloud's
  names. Treat the check as directional.

## A sensitivity label doesn't appear for pilot users
- **Likely cause:** the label exists (`Get-Label`) but isn't **published** via an enabled label policy, or the
  policy isn't scoped to the pilot users, or client/label-availability latency.
- **Fix:** confirm an enabled `Get-LabelPolicy` scopes the government labels to `Gov Pilot – Controlled Data –
  Stage1`; allow for publish latency; re-check with `INDGOV-Validate.ps1` (Labels gates). Publish **pilot-first**
  before broad rollout.

## An encrypting label blocks users who should have access (or lets in users who shouldn't)
- **Likely cause:** the label's **encryption/rights** definition is wrong — the point of Gate 4 is to catch
  this before broad publish. For ITAR, the U.S.-person access constraint may be missing or too broad.
- **Fix:** correct the rights in-portal, re-test access on benign pilot content (Testing Gate 4), and only then
  broaden publish. **The ITAR access rule is legal's determination** — do not set it yourself. Content already
  encrypted retains its protection; verify decryption/access recovery in your tenant before wide use.

## DLP simulation shows no matches (or far too many)
- **Likely cause:** the DLP **conditions / sensitive-info types** are under- or over-matching CJI/CUI/ITAR
  content — exactly what simulation is for.
- **Fix:** review matches with `INDGOV-Report.ps1 -DlpMatches`; tune the rule's conditions/SITs in-portal (the
  SITs are governance's determination). Zero matches during an active simulation usually means **under-matching
  detection**, not that no controlled data moved (Testing Gate 5/6). **Keep the policy in simulation** until it
  matches correctly.

## Endpoint DLP records nothing on a test device
- **Likely cause:** the device is **not onboarded**, endpoint DLP is **not available/licensed in your cloud**,
  or the egress-channel conditions (USB/print/cloud-upload) don't cover the test action.
- **Fix:** confirm device onboarding in the Purview portal → **Settings → Devices**; confirm endpoint DLP is
  available in your cloud (Requirement 2.4/2.1); verify the rule's egress-channel conditions; retest. Endpoint
  DLP only controls **onboarded** devices.

## A DLP policy is blocking legitimate work
- **Likely cause:** a policy was moved to **enforce** before simulation validated it, or the block scope is too
  broad.
- **Fix:** move it **back to simulation** (`Set-DlpCompliancePolicy … -Mode Enable` / recreate via
  `INDGOV-Configure.ps1`), review matches, tune conditions, and only re-enforce after validation and sign-off
  (Implementation Step 8). **DLP is high-impact — simulate first, always.**

## `Get-AdminAuditLogConfig` / `UnifiedAuditLogIngestionEnabled` cannot be read
- **Likely cause:** that cmdlet runs in **Exchange Online PowerShell** (`Connect-ExchangeOnline`), not S&C
  PowerShell, and needs your **cloud** endpoint.
- **Fix:** `Connect-ExchangeOnline -ConnectionUri <your cloud endpoint>` then re-read; `INDGOV-Validate.ps1`
  attempts this fallback automatically. If ingestion is **False**, enable it under change control — audit
  evidence is **not retroactive**.

## Audit retention policy rejected (invalid `RetentionDuration` or unlicensed tier)
- **Likely cause:** the requested long-term duration isn't an accepted value or isn't **licensed** in your
  cloud (Audit Premium).
- **Fix:** verify accepted `-RetentionDuration` values and that the long-term tier is licensed (Requirement
  2.1); adjust `-Duration` and re-run `INDGOV-Configure.ps1 -Control Audit`. Ensure a **unique** `-Priority`.

## The evidence binder has "NOT FOUND" rows
- **Likely cause:** a control in `Control Map – Gov – Purview` has no implementing Purview object, or the object
  name doesn't match the naming convention verbatim.
- **Fix:** create the missing control via `INDGOV-Configure.ps1`, or correct the object name to match the
  convention exactly; re-run `INDGOV-Report.ps1`. A control with no evidence fails an assessment.

## "Is this configuration CJIS/CMMC/ITAR compliant?" — the wrong question for this tool
- **Reality:** this solution **configures and evidences** the technical controls; whether they **satisfy** the
  CJIS Security Policy, CMMC / NIST SP 800-171, or the ITAR — and which CMMC level applies — is a
  **compliance/security/legal determination**. It makes **no certification or authorization-to-operate claim.**
- **Fix:** take the `Evidence – Gov Controls – Binder` and `Control Map – Gov – Purview` to your governance
  functions for the determination; keep the technical controls green via the scheduled read-only chain.


---


# 7. Best Practices — A Defensible Government Program on Microsoft Purview

Operating principles for a control-and-evidence program that survives a CJIS audit, a CMMC assessment, or an
ITAR review. Grounded in Microsoft's public guidance and the **Assess → Design → Configure → Pilot
(simulate/test) → Validate → Expand (enforce)** model.

## Stay in your lane: configure the control, defer the determination
- **You implement and evidence controls; compliance/security/records/legal decide the rules.** Which data is
  CJI/CUI/ITAR, which CMMC level applies, retention durations, ITAR access constraints, and whether a
  configuration satisfies the CJIS Security Policy, CMMC / NIST SP 800-171, or the ITAR are **their**
  determinations. Capture them in `Control Map – Gov – Purview` with named approvers — the register is your
  defensibility.
- Write findings as "the control is configured as specified and evidenced," never "the agency is compliant" or
  "authorized." This solution makes **no certification/ATO claim.**

## Verify everything against YOUR cloud
- GCC, GCC High, and DoD differ from commercial (and from each other) in feature availability, portal paths,
  and PowerShell/Graph endpoints. **Never assume** a capability or path shown here exists in your cloud —
  confirm it, and record your cloud's `-ConnectionUri` / `-Environment` in the runbook.
- ITAR and CUI workloads frequently **require** GCC High or higher. Confirm the tenant is in the required
  cloud **before** relying on any control for those obligations — that placement itself is often a
  determination.

## Treat DLP as high-impact: simulate, then enforce
- **Always create DLP and endpoint DLP in simulation/test mode.** A block set too broadly can halt legitimate
  mission work; a block set too narrowly lets controlled data leave. Run simulation, review matches with
  `INDGOV-Report.ps1`, tune conditions, and only then enforce — on the approved scope, under change control.
- Keep the **conditions and sensitive-info types owned by security/compliance** — you operationalize what they
  define; you don't invent what counts as CJI/CUI/ITAR.
- Endpoint DLP only works on **onboarded devices** with the right licensing/cloud — verify onboarding before
  claiming device egress is controlled.

## Encrypting labels change access — pilot access outcomes first
- An encrypting label binds protection to the file but also **changes who can open it**. For **ITAR**, the
  U.S.-person access constraint is a **legal** requirement, not a default. Pilot each label on non-production
  content, confirm authorized users can open and out-of-scope/external users cannot, and only then broaden the
  publish policy.
- Confirm downstream impact (co-authoring, external sharing, third-party tools) before wide rollout — an
  encrypting label can break workflows if published blind.

## Make evidence a first-class deliverable
- An auditor/assessor wants **control → configuration → proof**. Generate `Evidence – Gov Controls – Binder`
  and the DLP simulation-match summary regularly, not just at assessment time, so evidence is current and gaps
  surface early.
- Retain the `-WhatIf` transcripts, before/after discovery outputs, and sign-offs — the *change history* of
  the control is itself evidence of a governed program.

## Audit is the evidence layer — keep it on and retained
- Ensure **unified audit logging** stays on (it can be disabled) and that `Audit Retention – Gov Evidence –
  LongTerm` keeps the evidence CJIS/CMMC audit-log requirements call for, at a verified duration and licensing
  tier for your cloud.
- Treat "is auditing on and retaining?" as a **standing monitored control**, caught by the scheduled read-only
  chain.

## Least-privilege everywhere, and separate who reads matches/evidence
- Information Protection, DLP Compliance Management, Records Management, Audit, and Compliance Manager roles are
  **distinct and least-privilege**; reserve Global Administrator for one-time enablement. **DLP matches and
  audit evidence can contain controlled data** — restrict who may read them, separate from the configuring
  admin, and review membership periodically.

## Pilot every change, keep a rollback
- Publish labels, run DLP/endpoint DLP, and apply retention **pilot-first** in simulation/test on
  `Gov Pilot – Controlled Data – Stage1`; validate with the scorecard before expanding. Simulation DLP,
  pilot-scoped label policies, retention, and audit policies are reversible — record the exact rollback with
  every change. (Content already encrypted by a label retains protection — verify decryption/access recovery
  in your tenant.)

## Operate it as a program, not a project
- Schedule `INDGOV-Discovery.ps1` → `INDGOV-Validate.ps1` → `INDGOV-Report.ps1` on a cadence so drift (a DLP
  policy back in simulation or disabled, an unpublished label, a lapsed license, audit turned off, a device
  off-boarded) is caught before an assessor finds it, and re-generate the evidence binder ahead of every
  assessment cycle. Hand the register, binder, and runbook to compliance as the standing procedure.


---


# 8. Deliverables Summary — Microsoft Purview for Government

What you receive, what to run, and what "done" looks like. This is a **Government industry bundle** — it
curates and sequences Purview capabilities (sensitivity labels, DLP/endpoint DLP, retention, audit,
Compliance Manager) for a CJIS/CMMC/ITAR tenant, referencing the granular products for deep how-to rather
than re-teaching them.

## Documentation
| Document | Purpose |
|---|---|
| **1. Solution Overview** | What the bundle is, the curated Purview control stack (labels, DLP/endpoint DLP, retention, audit, Compliance Manager), the sovereign-cloud caveat, what you control, honest limitations, and the naming convention. |
| **2. Requirements Guide** | Government-program prerequisites (tenant/cloud/licensing, least-privilege roles, S&C PowerShell + Graph with the correct cloud endpoints, in-scope controlled data/devices, the obligation-to-control map, ITAR/encryption/access preconditions, audit, pilot) — each with Verify / Implement. |
| **3. Implementation Guide** | Ordered steps: assess, design the control map, configure labels (pilot access first), DLP/endpoint DLP **in simulation**, retention + audit, track in Compliance Manager, validate & evidence, expand to enforcement — with pass/fail gates and rollback. |
| **5. Testing & Validation** | Nine gates from "licensing present in your cloud" to "validation scorecard green," each with method / pass / fail action — read-only or benign pilot content, no enforcement during test. |
| **6. Troubleshooting** | The failure modes — cloud-endpoint/connection, label encryption/access, DLP not matching or blocking, endpoint-DLP onboarding, retention scope, audit off, licensing, evidence gaps — and their fixes. |
| **7. Best Practices** | Defensible-program principles: defer determinations, verify against your cloud, simulate DLP before enforce, pilot label access, make evidence first-class, operate it as a program. |

## PowerShell tools (5)
All run **read-only or `-WhatIf` by default**; writes require `-Commit`. No credentials or secrets are
embedded. Sensitivity labels, DLP/endpoint DLP, retention, and audit cmdlets use **Security & Compliance
PowerShell** (`Connect-IPPSSession` — pass your cloud's `-ConnectionUri` in GCC High/DoD); licensing and DLP
alert reads use **Microsoft Graph** (`Connect-MgGraph -Environment …`).

| Script | Role | Default |
|---|---|---|
| `INDGOV-Discovery.ps1` | Assess: licensing, sensitivity labels/policies (flag encrypting), DLP policies (flag mode + endpoint), retention, unified-audit state + audit retention. | Read-only |
| `INDGOV-Scope.ps1` | Scope/health helper: in-scope population/mailboxes/sites, visible role groups, endpoint-onboarding readiness, cloud-endpoint reachability, connection identity. | Read-only |
| `INDGOV-Configure.ps1` | Configure/Remediate: create the CJI/CUI/ITAR labels, DLP + endpoint DLP **in simulation**, records retention, and audit-evidence retention — `-Control Labels\|DLP\|EndpointDLP\|Retention\|Audit`. | `-WhatIf` (writes on `-Commit`) |
| `INDGOV-Validate.ps1` | Validate: program scorecard across labels (encrypt+publish), DLP + endpoint DLP (in simulation), retention, audit, pilot coverage. | Read-only |
| `INDGOV-Report.ps1` | Report: control → object → configuration → proof export (`Evidence – Gov Controls – Binder`) plus the **DLP simulation-match** summary, cross-referenced to the control map. | Read-only |

## Named artifacts created
- Labels: `Protect – Gov CJI – Restricted`, `Protect – Gov CUI – Controlled`, `Protect – Gov ITAR – Controlled`
  (encrypting; published pilot-first).
- DLP: `DLP – Gov Controlled Data – Simulate` (services) and `DLP – Gov Endpoint Egress – Simulate` (devices)
  — built and validated **in simulation**, enforced only after sign-off.
- Records/audit: `Retention – Gov Records – Publish`, `Audit Retention – Gov Evidence – LongTerm`.
- Program tracking: `Assessment – Gov Controls (CJIS/CMMC/NIST 800-171) – Program` (Compliance Manager,
  in-portal).
- Governance/evidence: `Control Map – Gov – Purview`, `Evidence – Gov Controls – Binder`, pilot
  `Gov Pilot – Controlled Data – Stage1`.

## Definition of done
- Cloud confirmed (GCC/GCC High/DoD) and compliance **licensing confirmed** for labels, DLP/endpoint DLP, and
  audit evidence on the in-scope population.
- The three government **labels** created (encrypting), **piloted for access outcomes**, and published — pilot
  first, then the approved scope under sign-off.
- **DLP + endpoint DLP** present **in simulation**, matching the right controlled content without blocking;
  moved to **enforce** only after validation and compliance/security sign-off.
- Records retention scoped, **unified audit on** with `Audit Retention – Gov Evidence – LongTerm` retaining
  evidence.
- The `Control Map – Gov – Purview` register complete, the `Evidence – Gov Controls – Binder` and DLP
  simulation-match summary generated, and the **validation scorecard green** for the pilot — then expanded to
  enforcement with a monitoring cadence.

> **Boundary:** this solution delivers the technical control configuration and the evidence. **Data
> classification (CJI/CUI/ITAR), CMMC-level applicability, retention adequacy, ITAR access sufficiency, and
> any regulatory determination are deferred to your compliance, security, records, and legal functions**, and
> it makes **no certification or authorization-to-operate claim.** Feature availability is **licensing-/
> tenant-/cloud-dependent and evolving — verify against your entitlements, your cloud (GCC/GCC High/DoD), and
> current Microsoft documentation.**
