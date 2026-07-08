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
