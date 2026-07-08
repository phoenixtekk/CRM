# FERPA DLP Pack — Microsoft Purview

> **Version 1.0.0** · Category: Purview · Solution code: DLPFERPA

> This is the online, maintained copy of the implementation guide. When this solution is updated, eligible customers are alerted and can return here for the current content. Downloadable PDF + scripts are attached on the store listing.



---


# Executive Summary — FERPA DLP Pack (Microsoft Purview)

## The problem
Student **education records** — grades, disciplinary records, student identifiers, financial-aid data, and
the personally identifiable information tied to them — leave the institution through the channels people use
every day: an email with a class roster attached, an "anyone with the link" gradebook share, a student ID
pasted into Teams, or a records file copied to USB or printed from a faculty laptop. FERPA (20 U.S.C.
§ 1232g; 34 CFR Part 99) requires those records to be protected; without a working data-loss control, leaks
are invisible until they become an incident. The common failed attempt — switching data-loss controls
straight to "block" — floods the help desk with false positives and gets turned off within a week.

## The solution
Stand up **Microsoft Purview Data Loss Prevention (DLP)**, tuned for education records, across all five
locations — **Exchange email, SharePoint, OneDrive, Teams, and Endpoint (managed devices)** — using only the
Microsoft Purview portal, Security & Compliance PowerShell, and Microsoft Graph. Detection is driven by
**sensitive information types** (built-in SSN/name/address types, a **custom Student ID SIT** tuned to your
local format, and **Exact Data Match** against the real records where near-zero false positives matter), and
the defining discipline is that **every policy is built and proven in SIMULATION first** — Microsoft's
built-in test mode that shows what *would* be blocked, with zero user impact — then tuned for a **low
false-positive rate**, then enforced to a **pilot ring**, then expanded. The result: record leaks are blocked
without blocking teaching and administration.

## What it delivers
- A mapped **classification layer** for education records — the right detector for each in-scope category,
  reusing built-in types and adding a Student ID custom SIT / EDM / trainable classifiers only for real gaps.
- **DLP policies across email, cloud, Teams, and endpoint**, each proven in simulation, tuned, and enforced
  through policy tips, user justification/override, or block.
- A **measured false-positive rate** kept at/under an agreed threshold — the difference between a control
  faculty trust and one they ignore.
- An **incident/alert triage workflow** so every match is acted on, with an evidence trail in Activity
  Explorer, least-privilege evidence access, and optional SIEM forwarding.
- **Five PowerShell tools** (posture assessment, policy config helper, validation checker, match/false-
  positive report, scope helper) — read-only or `-WhatIf` by default, no credentials in code.

## Business outcomes
- **Record leaks blocked** across the channels student data actually walks out through — email, cloud
  sharing, and USB/print on endpoints.
- **Minimal disruption** — simulation-first plus tuning means the control catches leaks without a wave of
  false positives, and any policy reverts to simulation instantly if needed.
- **Operable and auditable** — matches raise alerts that are triaged to disposition, with evidence retained
  for a defensible FERPA compliance posture.
- **Self-guided at a fraction of consulting cost** — the same method a specialist would use, documented and
  tooled to run in-house.

## Boundaries (so scope is clear)
DLP is licensing-/plan-dependent — **Endpoint DLP and advanced classifiers require E5 / E5 Compliance (or A5)
and onboarded devices** (verify your tenant). This solution provides the **technical configuration and the
evidence**; *which* records are FERPA-protected, what is **directory** versus **non-directory** information,
which disclosures are permitted, the **enforced action per category**, and the **acceptable false-positive
threshold** are **FERPA-compliance, registrar, privacy, and legal determinations**, captured alongside the
delivered evidence.


---


# 1. Solution Overview — FERPA DLP Pack (Microsoft Purview)

## What this solution is
Student **education records** — grades, disciplinary and counseling records, student identifiers, financial
aid data, and the personally identifiable information tied to them — leave educational institutions through
the same everyday channels everyone uses: an email with a class roster attached, a gradebook shared "anyone
with the link" from OneDrive or SharePoint, a student ID number pasted into a Teams chat, or a spreadsheet
of records copied to a USB stick or printed from a faculty laptop. **Microsoft Purview Data Loss Prevention
(DLP)** detects and controls that movement by matching the *content* being shared against **sensitive
information types (SITs)** and **classifiers**, then applying a policy action — audit only, warn the user
with a **policy tip**, allow with a business **justification**, or **block** — across **Exchange email,
SharePoint, OneDrive, Teams, and Endpoint (managed devices)**.

This is the **FERPA-aligned DLP pack**: a repeatable, evidence-driven way to stand up education-record
detection and protection policies in Microsoft Purview using only the **Microsoft Purview portal**,
**Security & Compliance PowerShell** (`Connect-IPPSSession`), and **Microsoft Graph** — no third-party DLP
tooling. Its defining discipline is that **every policy is built and proven in SIMULATION mode first**
(Microsoft's built-in test mode that evaluates policy against real traffic and shows what *would* have
matched, with zero user impact), tuned for a low false-positive rate, and only then moved to enforcement.

> **Scope boundary — FERPA determinations are deferred.** This solution delivers the **technical method and
> evidence** for education-record DLP. *Which* records are FERPA-protected, what counts as **directory
> information** (disclosable without consent unless the student/parent has opted out) versus **non-directory
> PII** (which requires consent), which disclosures are permitted, and the **enforced action** per data
> category are **FERPA-compliance, registrar, privacy, and legal determinations** — deferred to those
> functions. The solution helps you configure and prove the control; it does not make the FERPA
> determination. (FERPA: 20 U.S.C. § 1232g; 34 CFR Part 99 — applicability is the institution's counsel to
> confirm.)

## Why this matters
- DLP that is switched straight to **enforce** without simulation is the classic failure: it blocks
  legitimate teaching and administration, floods the help desk, and gets disabled within a week.
  Simulation-first is the difference between a control that survives and one that is turned off.
- **Student identifiers are institution-specific.** There is no reliable built-in "student ID" detector —
  student ID formats are local, so accurate detection usually needs a **custom SIT** (or **Exact Data Match**
  against the SIS export), tuned to your ID scheme. Getting this classification layer right is what makes the
  control trusted.
- **Directory vs non-directory is a policy decision, not a technical default.** The same name-and-address
  content may be freely disclosable directory information for one student and protected for another who has
  opted out. DLP detects the *content*; the registrar/FERPA function decides the *treatment*.
- **Endpoint DLP is licensing- and onboarding-dependent** — it requires the right plan and devices onboarded
  to Purview (shared with Microsoft Defender for Endpoint onboarding). A policy scoped to the Devices
  location does nothing until the endpoints are actually onboarded and reporting.
- False positives are the enemy of adoption. A detector that fires on every internal reference number trains
  faculty and staff to ignore every policy tip. Tuning — confidence levels, instance counts, supporting
  keywords, and EDM — is what makes the control usable.

## How it works
1. **Sensitive information types (SITs) and classifiers** define *what* to look for. Purview ships 150+
   **built-in SITs** (e.g. *U.S. Social Security Number (SSN)*, *All Full Names*, *U.S. Physical Addresses*,
   *U.S. Bank Account Number*), and you can add **custom SITs** (regex + keyword + confidence) for local
   identifiers such as a **Student ID**, **Exact Data Match (EDM)** SITs (matched against a hashed upload of
   your real SIS/records export for near-zero false positives), and **trainable classifiers** for conceptual
   categories (e.g. transcripts, disciplinary letters). *Whether a regulatory DLP policy template (for
   example a FERPA-labeled template) is available in your tenant is licensing-/version-dependent — verify in
   your tenant; do not assume one exists.*
2. **DLP policies** bind those SITs to **locations** (Exchange, SharePoint, OneDrive, Teams chat/channel, and
   **Devices/Endpoint**) with **conditions** (which SIT, how many instances, what confidence), **actions**
   (audit / notify / restrict / block; restrict USB/print/cloud-app upload on endpoint), and **user
   experience** (policy tips, allow-with-justification, allow-override).
3. **Simulation mode** runs the policy against live traffic and records what *would* have matched — with or
   without policy tips shown — so you can see the true hit volume and false positives **before** any
   enforcement. Every policy in this pack starts here.
4. **Tuning** reduces false positives using confidence levels, instance thresholds, supporting keyword
   evidence, EDM, and exceptions — measured against the simulation results.
5. **Enforcement** turns the tuned policy on (tips/override/block) in a limited ring, then expands.
6. **Incident/alert handling** — DLP rule matches raise **alerts** in the Purview portal and DLP events flow
   to **Activity Explorer**; this pack wires the triage, severity, and response workflow so matches are
   actually acted on.

## The five DLP locations (and what each controls for education records)
- **Exchange (email):** rosters, grade reports, and records emailed to unintended or external recipients;
  block or encrypt on match.
- **SharePoint & OneDrive:** gradebooks and record files at rest and when shared; block external sharing on
  match.
- **Teams chat & channel messages:** student identifiers or record content pasted into messages.
- **Endpoint (Devices):** activities on **onboarded** Windows/macOS devices — copy records to USB, copy to
  network share, print, upload to unallowed cloud apps/browsers, copy to clipboard, paste to browser.
  **Requires onboarding and the right licensing.**
- **On-premises / Fabric / Power BI / cloud apps (Defender for Cloud Apps):** additional locations that may
  be available depending on licensing — **verify availability in your tenant.**

## The simulate→enforce journey (the core discipline)
> Define SITs/classifiers for education records → build each DLP policy in **SIMULATION** (no user impact) →
> measure hit volume and false positives in **Activity Explorer / DLP alerts** → **tune** (confidence,
> instance count, keywords, EDM, exceptions) → re-simulate until false positives are acceptable → enable with
> **policy tips + allow-override/justification** in a **pilot ring** → validate → expand to
> **enforce (block)** per the FERPA function's action determination → operate (triage alerts, review
> overrides, re-tune).

## What you can control
- Which SITs/classifiers detect education records and at what **confidence** and **instance count** they
  trigger (e.g. a single student ID vs a bulk roster).
- Which **locations** each policy covers and which users/sites/groups are **included or excluded** (e.g. the
  registrar's office may be treated differently from general faculty).
- The **action** per data category (audit → tip → justify → block) — set per the FERPA/registrar
  determination.
- Whether users get **policy tips**, can **override** with justification, and what the override says.
- The **pilot ring** enforced first and the simulation dwell time before enforcement.

## Limitations (be honest with buyers)
- **Endpoint DLP requires onboarded devices and the appropriate licensing** (verify your plan — endpoint DLP
  and several advanced classifiers are gated behind E5 / the E5 Compliance add-on). A Devices-location policy
  is inert until onboarding is complete.
- **Some features are in preview** and portal paths **evolve** — this pack flags "verify your
  licensing/tenant" rather than asserting availability that may differ in your tenant.
- DLP inspects **content it can classify**; strongly encrypted or unrecognized file formats, or content below
  the confidence/instance threshold, will not match. DLP is one control among several, not a guarantee.
- **The FERPA treatment of any given content — directory vs non-directory, permitted disclosure, enforced
  action — is a compliance/registrar/legal decision**, not a technical default. This pack configures and
  proves the control; the determination is deferred.

## Naming convention (used in every doc and script)
Every artifact this solution creates uses `<Purpose> – <Scope> – <Stage>`, reused verbatim across the docs,
scripts, and the Purview portal. The standard set:

| Artifact | Name |
|---|---|
| Custom sensitive info type (student identifier) | `Student ID – Custom SIT – FERPA` |
| EDM schema / SIT (SIS records) | `Student Records – EDM – FERPA` |
| Email DLP policy (simulation) | `DLP – Email Education Records – Simulation` |
| Cloud DLP policy (simulation) | `DLP – SPO+OneDrive+Teams Education Records – Simulation` |
| Endpoint DLP policy (simulation) | `DLP – Endpoint Education Records – Simulation` |
| Enforced pilot policy | `DLP – All Locations Education Records – Enforce Pilot` |
| Pilot user ring | `FERPA DLP Pilot Ring – Stage1` |
| Policy-tip / override text | `FERPA DLP Notice – Standard – AllPolicies` |
| Incident/alert workflow | `FERPA DLP Alerts – Triage – Operations` |

## The standard deployment model
> **Assess** current education-record exposure and classification intent → **Design** SITs/classifiers,
> policies, and user experience → **Configure** SITs and policies **in simulation** → **Pilot** (simulate →
> tune → enforce to a ring) → **Validate** against pass/fail gates (records blocked, false-positive rate low,
> incidents handled) → **Expand** to the intended scope and ongoing operations. Every high-impact change is
> piloted in simulation first, with a documented rollback.


---


# 2. Requirements — FERPA DLP Pack (Microsoft Purview)

These are the **solution-specific** prerequisites for implementing FERPA-aligned education-record DLP across
endpoint, cloud, and email. They build on — and do not repeat — the six shared prerequisites in
**`global-requirements-purview.md`** (tenant + compliance licensing, least-privilege Purview roles,
S&C PowerShell + Graph toolchain, in-scope data sources, compliance/records/privacy/legal stakeholders, and
a pilot scope + change control). Verify each item below before starting the Implementation Guide.

For every requirement: **Description** (what it is), **Why required**, **How to verify**, **How to implement
if missing**.

---

## 2.1 Licensing sufficient for the DLP features you will use — especially Endpoint DLP
- **Description:** DLP for **Exchange/SharePoint/OneDrive/Teams** and **built-in SITs** is broadly available,
  but **Endpoint DLP**, **advanced/custom classifiers**, **Exact Data Match**, and **trainable classifiers**
  are **plan-gated** — typically **Microsoft 365 E5** or the **E5 Compliance** add-on (some capabilities are
  in **preview**). Many institutions run **Microsoft 365 A3/A5 (Education)** SKUs; confirm the DLP features
  you need are included in your specific A-plan. This extends GR-#1 with the DLP-specific plan detail.
- **Why required:** A DLP policy scoped to a location or using a classifier your plan doesn't include will not
  function. Endpoint DLP and EDM in particular are E5/E5-Compliance (or A5) capabilities.
- **How to verify:** In the **Microsoft 365 admin center** confirm the subscription/add-ons (A3/A5/E5/E5
  Compliance); in the **Purview portal → Data Loss Prevention** confirm the **Endpoint DLP** and **Devices**
  location and the classifier types you intend to use are visible. **Flag "verify your licensing/tenant"** —
  availability evolves.
- **How to implement if missing:** Acquire/assign the required licensing before building endpoint or
  advanced-classifier policies; scope the initial rollout to features your plan covers.

## 2.2 DLP-specific least-privilege roles
- **Description:** The **DLP role groups** in the Purview portal — **Compliance Administrator** or
  **Compliance Data Administrator** to create/manage DLP policies, **DLP Compliance Management** for policy
  management, **View-Only DLP Compliance Management** for read-only review, and the **Data Loss Prevention**
  role for alert/incident handling. Global Administrator only where genuinely required. Extends GR-#2.
- **Why required:** Purview enforces fine-grained role groups; DLP configuration and alert triage require the
  matching role, and least privilege keeps the blast radius small — especially important where alert
  evidence may itself contain student PII.
- **How to verify:** **Purview portal → Settings → Roles & scopes → Permissions** (or Microsoft Purview
  roles) — confirm your account's role-group membership includes the DLP roles you need.
- **How to implement if missing:** Assign the least-privilege DLP role group under change control; separate
  policy authors from alert triagers where possible.

## 2.3 Devices onboarded to Purview for Endpoint DLP
- **Description:** Endpoint DLP monitors activities on **onboarded Windows 10/11 and macOS devices** —
  faculty and staff laptops are the endpoints where records are copied to USB, printed, or uploaded.
  Onboarding is done in **Purview portal → Settings → Device onboarding** (or via Intune / a script / Group
  Policy) and is **shared with Microsoft Defender for Endpoint onboarding** — devices already onboarded to
  Defender for Endpoint are onboarded for Endpoint DLP.
- **Why required:** A DLP policy scoped to the **Devices** location does nothing on a device that is not
  onboarded and reporting. Onboarding is the hard prerequisite for any endpoint control.
- **How to verify:** **Purview portal → Settings → Device onboarding → Devices** shows onboarded devices;
  confirm target devices appear and are reporting.
- **How to implement if missing:** Onboard devices via the Purview device-onboarding package, Intune, or
  Group Policy; confirm the minimum OS build and any required Antimalware/AV state per Microsoft docs before
  scoping endpoint policies.

## 2.4 An education-record classification intent and a student-identifier SIT inventory
- **Description:** A documented view of **which education records and identifiers you are protecting**
  (student ID numbers, SSNs, grades/transcripts, disciplinary and counseling records, financial-aid data,
  and the PII tied to them) mapped to the **SITs/classifiers** that detect them — built-in SITs where they
  fit (e.g. *U.S. SSN*, *All Full Names*), and a **custom SIT / EDM / trainable classifier** for local
  student identifiers and record types. Extends GR-#4.
- **Why required:** DLP policies key off SITs; there is no reliable built-in "student ID" detector, so
  without a custom SIT tuned to your ID scheme (and knowing at what confidence/instance count it should
  fire), policies are guesswork and generate false positives.
- **How to verify:** **Purview portal → Data classification → Classifiers → Sensitive info types** lists
  built-in and custom SITs; confirm the ones you need exist (or are planned). Confirm the record categories
  and identifier formats with the registrar/data owners.
- **How to implement if missing:** Build the SIT inventory (this solution's Discovery script assesses
  built-in SIT coverage); plan a **`Student ID – Custom SIT – FERPA`** and, where near-zero false positives
  are required, a **`Student Records – EDM – FERPA`** schema.

## 2.5 Source data for Exact Data Match (only if EDM is used)
- **Description:** For **EDM** SITs, a **sensitive data table** (e.g. an export of the Student Information
  System / records) and a workstation with the **EDM Upload Agent** to hash and upload it — the raw data
  never leaves your control; only salted hashes are uploaded.
- **Why required:** EDM matches against *your actual student records*, which is what drives false positives
  to near zero — but it requires the schema, the hashed upload, and a **refresh cadence** as enrollment
  changes.
- **How to verify:** Confirm the source table, the EDM schema, the upload agent host, and a scheduled
  refresh. **Purview portal → Data classification → Exact data matches** shows configured EDM schemas.
- **How to implement if missing:** Define the EDM schema and refresh process (*which* fields are in scope is
  deferred to the registrar/data owner); if EDM is not in your plan or not needed, use a custom SIT with
  confidence/keyword tuning instead.

## 2.6 A pilot ring, simulation dwell time, and change control (DLP-specific)
- **Description:** A named **pilot user/device ring** (`FERPA DLP Pilot Ring – Stage1`), an agreed
  **simulation dwell time** (how long each policy runs in simulation before enforcement — long enough to
  capture representative traffic, ideally spanning a grading or enrollment cycle), and the **change-control
  window** for moving simulation → enforce. Extends GR-#6.
- **Why required:** DLP is high-impact in an academic setting where records move constantly during grading
  and admissions; enforcing without a simulation baseline and a limited ring is how DLP breaks the business.
  The house model mandates **simulation first**, then a ring, then expand.
- **How to verify:** Confirm the pilot ring membership, that **simulation mode** is selected on each new
  policy, and the approval path to enforce.
- **How to implement if missing:** Define the ring and dwell time and agree change control before enabling
  any enforcement action.

## 2.7 An incident/alert triage owner and destination
- **Description:** A named owner (or queue) for **DLP alerts** raised in **Purview portal → Data loss
  prevention → Alerts** (`FERPA DLP Alerts – Triage – Operations`), plus where DLP events are reviewed
  (**Activity Explorer**) and, optionally, where they are forwarded (SIEM/Microsoft Sentinel via the Office
  365 Management Activity API / Defender connectors). Severity and response actions defined. Because alert
  evidence can contain student PII, the triage owner must hold the appropriate least-privilege role.
- **Why required:** A DLP match with no one to triage it is not a control. Alerts and Activity Explorer are
  where matches surface; someone must own triage, severity, and response.
- **How to verify:** Confirm the triage owner/queue, the alert-severity scheme, and any SIEM forwarding is
  configured.
- **How to implement if missing:** Assign the owner, define severity/response, and (optionally) wire SIEM
  forwarding before enforcement generates real alerts.

---

### Requirements summary

| # | Requirement | Gate |
|---|---|---|
| GR 1–6 | Category prerequisites (`global-requirements-purview.md`) | Tenant/licensing, roles, toolchain, scope, stakeholders, pilot + change control |
| 2.1 | DLP/Endpoint licensing (E5 / E5 Compliance / A5; verify) | Endpoint & advanced classifiers available |
| 2.2 | DLP least-privilege roles | Author + triage roles assigned |
| 2.3 | Devices onboarded to Purview | Endpoint location functional |
| 2.4 | Education-record classification intent + student-ID SIT inventory | Policies key off correct SITs |
| 2.5 | EDM source data + agent (if used) | Near-zero-FP matching for real records |
| 2.6 | Pilot ring + simulation dwell + change control | Simulate-first enforced |
| 2.7 | Alert/incident triage owner + destination | Matches are acted on |

> **Deferred to FERPA compliance / registrar / privacy / legal:** which records are FERPA-protected,
> directory vs non-directory treatment, permitted disclosures, the enforced action per category, and
> regulatory applicability. This solution provides the technical configuration and evidence, not the
> determination.


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


# 3. Implementation Guide — FERPA DLP Pack (Microsoft Purview)

This is the exact, ordered procedure to implement FERPA-aligned education-record DLP across **email, cloud,
Teams, and endpoint** — every policy built in **SIMULATION** first, tuned, then enforced in a ring, then
expanded. Portal paths and cmdlets are from Microsoft's public documentation; **licensing-/plan-dependent
features and evolving portal paths are flagged "verify your licensing/tenant"** and are never asserted for
your tenant. Do the phases in order. Each phase names its artifacts (from the Overview naming table), states
a **pass/fail gate**, and gives a **rollback**.

> **Automation.** The five delivered PowerShell tools run through **Security & Compliance PowerShell**
> (`Connect-IPPSSession`) and **Microsoft Graph**. They are **read-only or `-WhatIf` by default**; writes
> require an explicit `-Commit` switch. No credentials are stored in code.

> **Determinations deferred.** *Which* records are FERPA-protected, **directory vs non-directory** treatment,
> which disclosures are permitted, and the *enforced action* per category are **FERPA-compliance / registrar
> / privacy / legal** decisions. This guide configures and proves the control; capture those decisions
> before Phase 3.

---

## Phase 0 — Connect and baseline (Assess)

1. **Connect the toolchain** (GR-#3). On the admin workstation:
   ```powershell
   Install-Module ExchangeOnlineManagement -Scope CurrentUser -Force   # provides Connect-IPPSSession
   Connect-IPPSSession -UserPrincipalName admin@contoso.com            # Security & Compliance PowerShell
   Connect-MgGraph -Scopes 'Organization.Read.All','InformationProtectionPolicy.Read' -NoWelcome
   ```
2. **Run the posture assessment** (delivered script #1, read-only):
   ```powershell
   .\DLPFERPA-Discovery.ps1 -CsvPath .\DLPFERPA-Posture.csv
   ```
   It reports existing DLP policies and their mode, built-in vs custom SIT coverage (including whether a
   student-identifier custom SIT already exists), and licensing/endpoint readiness signals.
3. **Confirm licensing and endpoint readiness** (Req 2.1, 2.3): confirm E5/E5-Compliance/A5 where endpoint or
   advanced classifiers are needed, and that target faculty/staff devices are **onboarded**.

**Pass/fail gate:** you have a written baseline (existing policies + modes), a SIT coverage map for education
records, and confirmed licensing + endpoint onboarding for the locations you will target.
**Rollback:** none (read-only).

---

## Phase 1 — Design the classification layer (SITs & classifiers for education records)

Decide, per in-scope record category, which detector applies. Do **not** invent SITs — use built-in where
they fit; build custom/EDM/trainable only for gaps. *Whether a regulatory (e.g. FERPA-labeled) DLP policy
template is available is version-/licensing-dependent — check the template gallery, but do not rely on one
existing.*

4. **Map built-in SITs first.** In **Purview portal → Data classification → Classifiers → Sensitive info
   types**, confirm the built-in SITs for your categories — e.g. *U.S. Social Security Number (SSN)*, *All
   Full Names*, *U.S. Physical Addresses*, *U.S. Bank Account Number* (for financial-aid data). Note each
   SIT's **confidence levels** and default **instance count**.
5. **Author a custom SIT for the student identifier.** Student IDs are institution-specific, so create
   `Student ID – Custom SIT – FERPA` with a **regex primary pattern** matched to your ID format, **supporting
   keywords** (e.g. "student ID", "student number", "SIS ID"), a **confidence level**, and a **character
   proximity**. Portal: **Classifiers → Sensitive info types → Create sensitive info type**. Test it against
   sample text in the wizard's **Test** step with fabricated IDs.
6. **Configure EDM where near-zero false positives are required** (Req 2.5). Define the schema
   (`Student Records – EDM – FERPA`), hash-and-upload the SIS/records export with the **EDM Upload Agent**,
   and set a **refresh cadence** tied to enrollment changes. Portal: **Data classification → Exact data
   matches**. *Which fields are in scope is the registrar/data owner's determination.*
7. **Add trainable classifiers where a category is conceptual, not pattern-based** (e.g. transcripts,
   disciplinary letters) — use a built-in trainable classifier where one fits, or train a custom one on
   sample content. Verify availability against your plan.

**Pass/fail gate:** every in-scope record category maps to a named, tested SIT/classifier at a chosen
confidence and instance count; the student-ID custom SIT matches fabricated IDs and does not match unrelated
numbers.
**Rollback:** delete unused custom SITs/EDM schemas (they have no effect until referenced by a policy).

---

## Phase 2 — Build the DLP policies in SIMULATION (Configure — no user impact)

Create **one policy per location group**, each in **simulation mode**. Simulation evaluates the policy
against real traffic and records what *would* match, with **no** enforcement and (optionally) with policy
tips shown.

8. **Email DLP policy — `DLP – Email Education Records – Simulation`.**
   Portal: **Data loss prevention → Policies → Create policy** → custom (or a regulatory template if one
   applies in your tenant) → **Locations: Exchange email only** → rule: condition *Content contains* the
   education-record SITs from Phase 1 (Student ID SIT, SSN, and/or the EDM SIT) at the chosen
   confidence/instance count → action *Restrict access or encrypt* (kept inert by simulation) → **Policy
   mode: Run the policy in simulation mode** (optionally *with policy tips*). Finish.
9. **Cloud DLP policy — `DLP – SPO+OneDrive+Teams Education Records – Simulation`.**
   Same flow → **Locations: SharePoint sites, OneDrive accounts, Teams chat and channel messages** →
   conditions as above → action *Restrict access* (block external sharing on match) → **simulation mode**.
10. **Endpoint DLP policy — `DLP – Endpoint Education Records – Simulation`** (requires onboarded devices +
    licensing). Same flow → **Locations: Devices** → conditions as above → **endpoint activities to
    audit/restrict**: *copy to USB/removable media*, *copy to network share*, *print*, *upload to unallowed
    cloud apps/browser*, *copy to clipboard*, *paste to browser* → **simulation mode**. Confirm the Devices
    location is selectable (if not, revisit licensing/onboarding — Req 2.1/2.3).
11. **Set the user experience** consistently: define `FERPA DLP Notice – Standard – AllPolicies` policy-tip
    text (in plain academic language — *why* this was flagged and *what to do*) and enable **allow override
    with justification** where the FERPA/registrar function permits — but note tips/overrides only *appear*
    once a policy is enforced; in simulation they are captured, not shown to end users unless "simulation
    with policy tips" is selected.
12. **Verify with the config helper** (delivered script #2, `-WhatIf` by default):
    ```powershell
    .\DLPFERPA-Config.ps1 -PolicyName 'DLP - Email Education Records - Simulation' `
        -Locations Exchange -SensitiveTypes 'Student ID - Custom SIT - FERPA' -MinCount 5 -Confidence High -WhatIf
    ```
    Run with `-Commit` only to apply an intended change; the script never leaves a policy in enforce mode.

**Pass/fail gate:** all three policies exist and are confirmed in **simulation** (script #1/#2 report
`Mode = TestWithoutNotifications / TestWithNotifications`, i.e. simulation), scoped to the correct locations
and education-record SITs.
**Rollback:** delete the simulation policy — simulation has no user impact, so removal is clean.

---

## Phase 3 — Measure and tune (drive false positives down)

Let each policy run in simulation for the agreed **dwell time** (Req 2.6) to capture representative academic
traffic (grading, admissions, registrar operations).

13. **Review what matched.** **Purview portal → Data loss prevention → Alerts** (simulation alerts) and
    **Data classification → Activity explorer** (filter to DLP activities) show every simulated match with
    the file/message, the SIT, and the confidence. Export with the reporting script:
    ```powershell
    .\DLPFERPA-Report.ps1 -Days 14 -CsvPath .\DLPFERPA-Matches.csv
    ```
14. **Classify each match** as true positive or **false positive** and identify the false-positive drivers
    (e.g. the Student ID SIT firing on unrelated 8-digit numbers, or a name-and-address match on **directory
    information** the registrar has deemed disclosable — a treatment decision, not a detector fault).
15. **Tune** to reduce false positives without losing true positives:
    - Raise the **confidence level** (e.g. medium → high) so only high-confidence matches count.
    - Raise the **instance count** (e.g. require ≥5 student IDs, not 1) to focus on bulk-roster leaks.
    - Add **supporting keywords / proximity** to the Student ID custom SIT so context is required.
    - Introduce **EDM** (`Student Records – EDM – FERPA`) for categories where pattern SITs over-match.
    - Add **exceptions** (e.g. exclude a registrar mailbox/site the FERPA function has scoped out) where
      justified.
16. **Re-simulate** after each tuning change and re-measure. Repeat until the false-positive rate meets the
    validation gate (see Testing).

**Pass/fail gate:** measured false-positive rate is at/under the agreed threshold on the simulation sample,
with true positives (real education-record leaks) still detected.
**Rollback:** revert the last tuning change (script #2 `-WhatIf` shows the diff before `-Commit`).

---

## Phase 4 — Enforce in a pilot ring (Pilot)

17. **Scope to the pilot ring.** Add `FERPA DLP Pilot Ring – Stage1` (users) and pilot devices as the
    **included** scope on each policy (all other users/devices excluded for now):
    ```powershell
    .\DLPFERPA-Set-Scope.ps1 -PolicyName 'DLP - Email Education Records - Simulation' `
        -PilotRingGroup 'FERPADLPPilotRing@contoso.com' -Location Exchange -Commit
    ```
18. **Move the ring to enforcement.** Change **Policy mode** from *simulation* to **Turn it on / Enforce**.
    Start with **policy tips + allow-override (justification)** rather than hard block, so pilot staff can
    report false negatives/positives while retaining a business escape hatch for legitimate record handling.
19. **Confirm enforcement is live** for the ring only (script #1 reports mode `Enable` and the scoped
    identities). Confirm end users in the ring now see the `FERPA DLP Notice – Standard – AllPolicies` tip on
    a test match (fabricated data).
20. **Handle incidents.** Wire `FERPA DLP Alerts – Triage – Operations`: assign the alert owner/queue
    (Req 2.7), set severities, and (optionally) forward to SIEM/Sentinel. Triage a real simulated/pilot alert
    end-to-end to prove the workflow — and confirm alert evidence is only accessible to appropriately-roled
    staff.

**Pass/fail gate:** the pilot ring is enforced (tips shown, overrides captured), matches raise alerts, and
the triage workflow produces a dispositioned incident. No enforcement outside the ring.
**Rollback:** set the policy back to **simulation mode** (single setting) — instantly removes enforcement
with no data change.

---

## Phase 5 — Expand and harden (Enforce → Operate)

21. **Expand scope** from the ring to the full intended population once the pilot gate passes, keeping
    documented exclusions (e.g. the registrar's office if scoped differently by the FERPA function).
22. **Escalate the action** per the FERPA/registrar determination — e.g. move a category from *tip + override*
    to **block** where required (external sharing of non-directory records) — one category/location at a time,
    re-validating after each.
23. **Operationalize:** schedule the reporting script for a recurring false-positive/alert review, review
    **user overrides** (are staff justifying legitimately or bypassing?), refresh **EDM** data on cadence as
    enrollment changes, and re-tune as data and behavior change.
24. **Validate end-to-end** with the delivered testing procedure (next section) and record the pass/fail
    evidence.

**Pass/fail gate:** enforcement live across the intended scope with the FERPA-mandated action per category;
false-positive rate steady/low; alerts triaged on cadence; overrides reviewed.
**Rollback:** any policy can be returned to **simulation** at any time as an immediate, non-destructive
safety switch; individual policies can be disabled without affecting others.

---

## Order-of-operations summary

| Phase | Do | Artifact(s) | Gate | Rollback |
|---|---|---|---|---|
| 0 Assess | Connect, baseline, confirm licensing/onboarding | Posture CSV | Baseline + readiness confirmed | n/a (read-only) |
| 1 Design | Map built-in SITs, build Student ID SIT / EDM / classifiers | Custom SIT / EDM schema | Every category → tested detector | Delete unused SIT/EDM |
| 2 Configure | Build 3 policies in **simulation** | Email/Cloud/Endpoint sim policies | All in simulation, correct scope | Delete sim policy |
| 3 Tune | Measure + reduce false positives | Matches CSV | FP rate ≤ threshold | Revert tuning change |
| 4 Pilot | Enforce to ring, wire alerts | Pilot ring, alert triage | Ring enforced, incident dispositioned | Back to simulation |
| 5 Expand | Broaden scope, escalate to block, operate | Enforced policies | Full-scope enforce, low FP, alerts triaged | Simulation / disable |


---


# 5. Testing & Validation — FERPA DLP Pack (Microsoft Purview)

Validate the education-record DLP implementation against explicit **pass/fail gates**. The three headline
gates are: **(A) record leaks are blocked**, **(B) the false-positive rate is low**, and **(C) incidents are
handled**. Run every test with **non-real, clearly-fake sample data** — fabricated student IDs, the
Microsoft-documented test SSN pattern, and dummy names — **never real student records or PII**. Record the
evidence.

> All tests assume the policies from the Implementation Guide, first proven in **simulation** and then
> enforced to the **pilot ring**. Endpoint tests require an **onboarded** device (Req 2.3).

---

## Test A — Detection & enforcement (record leaks are blocked)

| # | Test | Steps | Pass condition |
|---|---|---|---|
| A1 | Email match blocked | From a pilot-ring user, send an email to an **external** recipient containing a fabricated roster with enough fake student IDs/SSNs to meet the threshold. | Message is blocked/encrypted per the enforced action; sender sees the policy tip; a DLP alert is raised. |
| A2 | SharePoint/OneDrive external share blocked | As a ring user, upload a fake gradebook with the education-record SIT and attempt to share it **externally**. | External sharing is blocked/restricted on match; event appears in Activity Explorer. |
| A3 | Teams message match | Paste fabricated student-ID/record content into a Teams chat/channel covered by the policy. | Message is blocked or tipped per the enforced action; event logged. |
| A4 | Endpoint — USB copy | On an onboarded ring device, copy a fake records file to **removable media**. | Activity is audited/blocked per policy; endpoint DLP event appears in Activity Explorer. |
| A5 | Endpoint — print / cloud upload | On the ring device, attempt to **print** the fake records file and **upload** it to an unallowed cloud app/browser. | Each activity is audited/restricted per policy; events logged. |
| A6 | Below-threshold negative | Send content with **fewer** student IDs than the threshold (or lower confidence). | Correctly **not** matched — confirms the threshold/confidence tuning holds. |

**Gate A (pass):** A1–A5 each produce the enforced action and a logged event; A6 correctly does not match.

---

## Test B — False-positive rate (adoption gate)

| # | Test | Steps | Pass condition |
|---|---|---|---|
| B1 | Simulation FP baseline | Over the agreed dwell time, export simulation matches (`DLPFERPA-Report.ps1 -Days <n>`) and classify each as TP/FP. | **False-positive rate ≤ the agreed threshold** (define with the FERPA function; a common target is ≤10% of matches, or an absolute FP count the triage team can absorb). |
| B2 | Legitimate-traffic negative | Run representative legitimate academic content (no real student data) through the covered channels — internal course materials, reference numbers, non-record documents. | Legitimate traffic is **not** matched — no spurious tips/blocks. |
| B3 | Student-ID SIT precision | Send documents containing unrelated numbers with the same digit length as a student ID but no supporting keywords. | The `Student ID – Custom SIT – FERPA` does **not** fire without its keyword/proximity context. |
| B4 | Post-tuning re-measure | After each tuning change (confidence↑, instance count↑, keywords, EDM, exceptions), re-simulate and re-measure. | FP rate trends **down** while true positives (Test A) still fire. |
| B5 | Override sanity | In the pilot ring, review captured **allow-with-justification** overrides. | Overrides are legitimate academic/administrative justifications, not routine bypass — if routine, re-tune or re-scope. |

**Gate B (pass):** measured FP rate at/under threshold on the simulation sample with true positives intact.

---

## Test C — Incident / alert handling (the control is operable)

| # | Test | Steps | Pass condition |
|---|---|---|---|
| C1 | Alert raised | Trigger a policy match (Test A1/A4). | A DLP **alert** appears in **Purview → Data loss prevention → Alerts** with the correct policy, severity, and evidence. |
| C2 | Triage workflow | The `FERPA DLP Alerts – Triage – Operations` owner/queue picks up the alert, sets status, and dispositions it. | Alert moves through the defined states to a resolved disposition by the named owner. |
| C3 | Activity Explorer trail | Locate the same event in **Data classification → Activity explorer**. | Full evidence trail present (user, location, SIT, action) for investigation. |
| C4 | Evidence access control | Confirm who can view the alert evidence (which may contain student PII). | Only appropriately-roled staff can view; least-privilege holds (Req 2.2/2.7). |
| C5 | SIEM forwarding (if configured) | Confirm the DLP event reaches the SIEM/Sentinel destination (Req 2.7). | Event present in the downstream system with usable fields. |

**Gate C (pass):** matches raise alerts, alerts are triaged to disposition by the owner with least-privilege
evidence access, and the trail (and SIEM forward, if used) is present.

---

## Simulation-first & rollback validation

| # | Test | Pass condition |
|---|---|---|
| S1 | Nothing enforced outside the ring | Users/devices **outside** `FERPA DLP Pilot Ring – Stage1` experience no blocking during pilot. |
| S2 | Instant rollback | Setting any enforced policy back to **simulation mode** immediately removes enforcement with no data change (verify a previously-blocked action now only simulates). |
| S3 | Scripts are safe-by-default | `DLPFERPA-Config.ps1` and `DLPFERPA-Set-Scope.ps1` run **without** `-Commit` make no change (`-WhatIf` output only); discovery/validate/report scripts are read-only. |

---

## Evidence to capture (for the deliverable record)
- Baseline posture CSV (Phase 0) and the education-record SIT coverage map.
- Simulation match export + TP/FP classification and the computed **false-positive rate** before/after
  tuning (Gate B).
- Screenshots/log of Test A enforcement actions and the raised alerts (Gate A/C).
- The dispositioned incident from Test C2, the evidence-access confirmation (C4), and, if used, the SIEM
  forward (C5).
- Confirmation that outside-ring users were unaffected (S1) and that simulation rollback works (S2).

> **Determination boundary.** These tests prove the **control works**. Whether a given record category's
> enforced action, its directory-vs-non-directory treatment, and the acceptable FP threshold are *acceptable*
> is a FERPA-compliance/registrar/legal sign-off, captured alongside the evidence above.


---


# 6. Troubleshooting — FERPA DLP Pack (Microsoft Purview)

Symptom-first fixes for the failures you actually hit implementing education-record DLP across email, cloud,
Teams, and endpoint. Most problems are one of: a policy not matching, the student-ID SIT not firing, the
endpoint location unavailable, too many false positives, or matches that raise no alert.

---

## Policy / detection

**A DLP policy matches nothing even though the content clearly contains education records.**
- Confirm the policy is actually **enabled and in a mode that evaluates** — a *disabled* policy does nothing;
  a **simulation** policy evaluates and logs but does not block. Check with `DLPFERPA-Discovery.ps1` (Mode
  column) or `DLPFERPA-Validate.ps1`.
- Check the **instance count and confidence** on the rule — if it requires ≥5 student IDs at High confidence
  and your test has 1, it correctly won't fire. Lower the threshold for testing, or add more sample
  instances.
- **Policy propagation takes time** — newly created/changed DLP policies can take **up to ~1 hour (and longer
  for some locations)** to take effect. Wait before concluding it's broken.
- Confirm the **location scope** includes where you're testing (e.g. the specific site/user), and that the
  test identity isn't in an **exclusion** (e.g. a registrar mailbox the FERPA function scoped out).

**The `Student ID – Custom SIT – FERPA` never matches.**
- Test the SIT's **regex + keywords** in the SIT wizard's **Test** step with a fabricated ID that matches
  your format. A too-strict regex, wrong **character proximity**, or a required keyword that isn't present
  will suppress all matches. Loosen and re-test incrementally.
- If it matches *too much* (e.g. every 8-digit number), that's a precision problem, not a miss — add/require
  supporting keywords ("student ID", "SIS ID") and tighten proximity (see False positives below).

**Matches appear in simulation but nothing is blocked.**
- That is **correct** — simulation logs what *would* happen without enforcing. To block, move the policy to
  **enforce** for the pilot ring (Implementation Phase 4). If you expected blocking, you're still in
  simulation.

**A name-and-address match looks like a false positive but the registrar says it's fine.**
- That may be **directory information** the FERPA/registrar function has deemed disclosable — a *treatment*
  decision, not a detector fault. Don't weaken the detector; implement the agreed exception as a documented
  scope exclusion, and record the FERPA sign-off.

## Endpoint DLP

**The Devices/Endpoint location isn't available when creating a policy.**
- **Licensing:** Endpoint DLP requires the appropriate plan (E5 / E5 Compliance / A5) — check the licensing
  signal with `DLPFERPA-Validate.ps1` and **verify in the admin center**.
- **Onboarding:** the Devices location depends on **onboarded devices** — confirm in **Purview portal →
  Settings → Device onboarding**. No onboarded devices → the location does nothing even if selectable.

**Endpoint policy is enforced but device activities (USB/print/upload) aren't caught.**
- Confirm the specific **device is onboarded and reporting** (portal device list), meets the **minimum OS
  build**, and — for some activities — that the required agent/AV prerequisites per Microsoft docs are met.
- Confirm the **activity is in scope** of the rule (e.g. "copy to USB" is enabled) and that the app/browser
  or network path isn't on an **allowed/exception** list (e.g. a sanctioned SIS/LMS tool).
- Allow for **reporting latency** — endpoint events can take time to surface in Activity Explorer.

## False positives (the adoption killer)

**Faculty/staff are getting policy tips on legitimate, non-record content.**
- Export matches with `DLPFERPA-Report.ps1 -CsvPath ...`, classify TP/FP, and identify the driver.
- **Raise confidence** (medium→high) and/or **instance count** (a single ID is often legitimate; a roster is
  a leak) so low-signal hits don't fire.
- Add **supporting keywords/proximity** to the Student ID custom SIT so context is required, not just a
  number pattern.
- For a built-in SIT (or a pattern SIT) that over-matches your identifiers, move that category to **Exact
  Data Match** (`Student Records – EDM – FERPA`) so only your real enrolled records match.
- Add a targeted **exception** where the FERPA function has justified it (specific mailbox/site) — narrowly,
  with a documented reason.
- Re-simulate after each change and re-measure — don't stack multiple changes blind.

## Alerts / incident handling

**Policy matches occur but no alert appears / no one is notified.**
- Confirm **alerts are configured** on the rule (alert on match, threshold) and check **Purview → Data loss
  prevention → Alerts**. Some low-severity matches aggregate rather than alert per event.
- Confirm **audit logging is enabled** in the tenant — the report script and Activity Explorer rely on it.
- Confirm the **triage owner/queue** (`FERPA DLP Alerts – Triage – Operations`) exists and, if forwarding to
  SIEM/Sentinel, that the connector is healthy (Req 2.7).

**Triage staff can't see the alert evidence (or see too much).**
- Alert evidence can contain student PII — access is governed by **role**. Confirm the triage owner holds the
  least-privilege **Data Loss Prevention / View-Only DLP** role and nothing broader (Req 2.2/2.7).

**The report script returns no matches.**
- **Audit log latency:** DLP events can take time to appear; widen `-Days` and re-run.
- Freshly created policies need **dwell time** — there may simply be no matches yet.
- Confirm **audit logging is on** and your account has the **View-Only DLP / audit** role.

## Connectivity / tooling

**`Connect-IPPSSession` or a DLP cmdlet fails.**
- Ensure the **ExchangeOnlineManagement** module is installed/updated and you're using a **modern-auth /
  MFA-capable** admin.
- Confirm the account holds the required **DLP role** (Compliance Administrator / Compliance Data
  Administrator / DLP Compliance Management) — a missing role surfaces as "cmdlet not recognized" or access
  denied.

**A script made an unexpected change.**
- The delivered scripts are **read-only or `-WhatIf` by default**; writes require `-Commit`. If a change
  landed, it was committed intentionally — the config helper never leaves a policy in **enforce**, so the
  safe recovery is always to set the policy back to **simulation** in the portal (one setting, no data
  change).

---

### Fast triage table

| Symptom | First check |
|---|---|
| Policy matches nothing | Mode (disabled/sim), instance count/confidence, propagation time, scope/exclusion |
| Student ID SIT never fires | Test regex+keywords+proximity in the SIT wizard |
| Student ID SIT over-matches | Require supporting keywords, tighten proximity, or move to EDM |
| Nothing blocked | Still in **simulation** — that's expected; enforce the ring to block |
| "False positive" on name/address | May be **directory information** — a registrar/FERPA treatment call, not a detector fault |
| Devices location missing | Licensing (E5/E5 Compliance/A5) + device **onboarding** |
| Endpoint activity not caught | Device onboarded/reporting, activity in scope, allowed-app/network exceptions |
| Too many false positives | Raise confidence/instance count, add keywords/EDM, exceptions, re-simulate |
| No alert on match | Alert config on rule, audit logging on, triage owner, SIEM connector |
| Evidence access wrong | Least-privilege DLP role on the triage owner |
| Report returns nothing | Audit latency/dwell time, audit logging on, role |
| Cmdlet/connect fails | Module updated, modern auth, correct DLP role |


---


# 7. Best Practices — FERPA DLP Pack (Microsoft Purview)

Field-tested practices for running education-record DLP across endpoint, cloud, and email so the control
stays trusted, effective, and low-noise in an academic environment. These complement the Implementation and
Testing guides.

## Simulate before you enforce — always
- **Never** switch a new or materially changed DLP policy straight to enforce. Run it in **simulation**
  first, long enough to capture representative academic traffic (a grading or admissions cycle is ideal —
  Req 2.6), and read the results before enabling.
- Use **simulation with policy tips** on the pilot ring when you want faculty/staff feedback before hard
  block.
- Treat **simulation mode as your permanent safety switch**: any enforced policy can be returned to
  simulation in one setting, instantly removing enforcement with no data change — this is your rollback.

## Get the student-identifier classification right
- **There is no reliable built-in student-ID detector** — build `Student ID – Custom SIT – FERPA` tuned to
  your local ID format, with **supporting keywords and proximity** so a bare number doesn't fire.
- Use **Exact Data Match** (`Student Records – EDM – FERPA`) for categories where pattern SITs over-fire — it
  matches your *actual* enrolled records and drives false positives toward zero, at the cost of an upload +
  refresh cadence tied to enrollment.
- **Reuse built-in SITs** (SSN, names, addresses, bank account) wherever they fit; build custom/EDM/trainable
  only for genuine gaps — fewer, well-tuned detectors beat a sprawl of overlapping ones.

## Tune for a low false-positive rate (adoption depends on it)
- Start at **higher confidence** and a **realistic instance count** — a single student ID is often
  legitimate; a roster of them in one outbound file is a leak. Bulk-exfiltration thresholds cut false
  positives dramatically.
- Every false positive that reaches a faculty member erodes trust in **every** policy tip. Budget for a
  tuning cycle, not a one-time build.
- Re-simulate after each change and re-measure — don't stack multiple tuning changes blind.

## Respect the directory-vs-non-directory boundary
- **DLP detects content; the registrar/FERPA function decides treatment.** The same name-and-address content
  may be disclosable **directory information** for one student and protected for another who has opted out.
  Don't encode a FERPA determination into a detector — scope and action follow the compliance decision.
- Where the FERPA function scopes a mailbox/site out (e.g. the registrar's controlled disclosure workflow),
  implement it as a **documented exception**, not a silently weakened policy.

## Right-size the user experience
- Show **clear, actionable policy tips** in plain academic language — tell the user *why* and *what to do*,
  not a compliance error code. Reuse one standard notice (`FERPA DLP Notice – Standard – AllPolicies`).
- Prefer **allow-with-justification / override** over hard block for categories where legitimate academic
  exceptions exist, then **review the overrides** — routine overriding means the policy is mis-scoped.
- Reserve **hard block** for the categories where the FERPA function requires it (e.g. external sharing of
  non-directory records); escalate to block one category at a time, re-validating each.

## Endpoint DLP specifics
- **Onboarding is the gate.** A Devices policy is inert until the faculty/staff device is onboarded (shared
  with Defender for Endpoint) and reporting — verify onboarding before blaming the policy.
- Roll endpoint controls out **audit-first**: audit USB/print/cloud-upload activities before restricting, so
  you see real record-handling patterns and avoid blocking legitimate academic workflows.
- Mind **unallowed vs allowed apps/browsers and network exceptions** — configure the allowed-app and
  network-path lists so sanctioned SIS/LMS tools aren't caught alongside exfiltration paths.

## Operations & governance
- Give DLP **alerts an owner and an SLA** (Req 2.7). Match volume without triage is not a control. Forward to
  SIEM/Sentinel where central SecOps needs visibility — but keep evidence access least-privilege since it can
  contain student PII.
- Review **Activity Explorer** and the false-positive rate on a **recurring cadence**; re-tune as data and
  behavior drift across terms.
- Enforce **least-privilege roles** and, where possible, **separate policy authors from alert triagers**.
- **Refresh EDM data** on a schedule aligned to enrollment — stale EDM data silently degrades matching.
- Keep a **change log** of every simulate→enforce transition and every action escalation, with the FERPA/
  registrar sign-off attached.

## Stay inside the boundary
- DLP is **one control**, not a guarantee — it inspects content it can classify; combine with sensitivity
  labels, encryption, and insider-risk where the risk warrants.
- **Verify licensing/tenant** before relying on any endpoint or advanced-classifier capability, and before
  assuming a FERPA-labeled policy template exists — plans and portal paths evolve; don't assume a feature is
  present.
- The **FERPA treatment, the enforced action, and the acceptable false-positive threshold per category are
  compliance/registrar/legal determinations** — you provide the technical control and the evidence; they own
  the decision.


---


# 8. Deliverables Summary — FERPA DLP Pack (Microsoft Purview)

What you receive in this solution, and what "done" looks like.

## Documentation
| Document | What it gives you |
|---|---|
| **Solution Overview** | The education-record DLP model — SITs/classifiers (including the Student ID custom SIT and EDM), the five locations (email, SharePoint, OneDrive, Teams, endpoint), policy tips/overrides, the directory-vs-non-directory boundary, and the simulate→enforce journey; naming convention. |
| **Requirements Guide** | Solution-specific prerequisites (DLP/Endpoint licensing incl. A3/A5, DLP roles, device onboarding, education-record classification intent + student-ID SIT inventory, EDM source data, pilot ring, alert triage owner) each with verify/implement steps, on top of the six category prerequisites. |
| **Implementation Guide** | The exact ordered phases: connect/baseline → design education-record SITs → build policies **in simulation** → tune false positives → enforce to a pilot ring → expand; each phase named, gated, and with a rollback. |
| **Testing & Validation** | Pass/fail gates for the three headline outcomes — record leaks blocked (A), low false-positive rate (B), incidents handled (C) — plus student-ID precision, evidence-access, simulation-first and rollback checks, all with fabricated test data. |
| **Troubleshooting Guide** | The common failure modes (policy not matching, student-ID SIT never fires, endpoint location missing, floods of false positives, no alerts) and how to resolve them. |
| **Best Practices** | Simulate-first discipline, student-identifier classification, false-positive tuning, the directory/non-directory boundary, user-experience design, endpoint specifics, and operations/governance. |
| **Executive Summary** | One-page business framing for approvers. |

## PowerShell tools (5) — Security & Compliance PowerShell / Graph
All tools are **read-only or `-WhatIf` by default**; writes require an explicit `-Commit`. No credentials are
stored in code. They connect via `Connect-IPPSSession` and/or `Connect-MgGraph`.

| # | Script | Role | Default safety |
|---|---|---|---|
| 1 | **DLPFERPA-Discovery.ps1** | DLP posture + education-record SIT coverage assessment: existing policies and their mode, built-in vs custom SIT coverage (incl. whether a student-ID SIT exists), licensing/endpoint readiness signals. | Read-only |
| 2 | **DLPFERPA-Config.ps1** | DLP policy configuration/remediation helper: creates/updates an education-record policy **in simulation mode** and reports the intended change. | `-WhatIf` (writes need `-Commit`; never leaves a policy in enforce) |
| 3 | **DLPFERPA-Validate.ps1** | Validation checker: confirms the FERPA policy set is in simulation, scoped to the correct locations/SITs, and (optionally) checks endpoint-location/onboarding readiness — reports pass/fail per gate. | Read-only |
| 4 | **DLPFERPA-Report.ps1** | DLP match / false-positive tuning report: exports simulation/enforcement matches for TP-vs-FP classification and rate calculation. | Read-only |
| 5 | **DLPFERPA-Set-Scope.ps1** | Scope/health helper: reports a policy's locations/mode/scope and (with `-Commit`) adjusts the included/excluded users/groups (e.g. the pilot ring). | `-WhatIf` (writes need `-Commit`) |

## Definition of done
- Education-record SITs/classifiers mapped for every in-scope category (built-in reused; `Student ID – Custom
  SIT – FERPA` and, where needed, `Student Records – EDM – FERPA` for gaps).
- Email, cloud (SPO/OneDrive/Teams), and endpoint DLP policies built and **proven in simulation**.
- False-positive rate measured and tuned to at/under the agreed threshold (Gate B), with student-ID precision
  confirmed.
- Enforcement live for the pilot ring with policy tips + override, then expanded per the FERPA function's
  action determination (Gate A).
- DLP alerts raised, triaged to disposition with least-privilege evidence access, and evidence trailed in
  Activity Explorer (Gate C).
- Simulation-rollback and safe-by-default scripts verified; change log and FERPA/registrar sign-offs captured.

> **Boundary:** the solution delivers the technical control and the evidence. The **records in scope, the
> directory-vs-non-directory treatment, the classifiers that legally apply, the enforced action per category,
> and the acceptable false-positive threshold** are FERPA-compliance/registrar/privacy/legal determinations,
> captured alongside the evidence.
