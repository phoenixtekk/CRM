# 1. Solution Overview — HIPAA / PHI DLP Pack (Microsoft Purview)

## What this solution is
**Protected health information (PHI)** — a patient name or medical record number combined with a
diagnosis, a claim, a lab result, or an insurance identifier — leaves organizations through the same
everyday channels as any other data: an email to the wrong recipient, a "anyone with the link" cloud
share, a spreadsheet of member records pasted into Teams, or a discharge summary copied to a USB stick
or printed. For a HIPAA-regulated organization (a covered entity or business associate) that movement
is both a **compliance gap** and a **breach exposure**.

This solution is a repeatable, evidence-driven way to implement **Microsoft Purview Data Loss
Prevention (DLP)** tuned for **PHI** across **Exchange email, SharePoint, OneDrive, Teams, and Endpoint
(managed devices)** — using only the **Microsoft Purview portal**, **Security & Compliance PowerShell**
(`Connect-IPPSSession`), and **Microsoft Graph** — no third-party DLP tooling. Detection is driven by
the **HIPAA-relevant sensitive information types (SITs)** Microsoft ships (see below), extended with
**custom SITs / Exact Data Match** for your own identifiers (e.g. a medical record number format). Its
defining discipline is that **every policy is built and proven in SIMULATION mode first** (Microsoft's
built-in test mode that evaluates policy against real traffic and shows what *would* have matched,
without affecting a single user), tuned for a low false-positive rate, and only then enforced.

> **Scope boundary (read this first).** This solution delivers the **technical method and the
> evidence** for PHI-focused DLP. *Which* data is PHI in your environment, *which* HIPAA identifiers and
> classifiers legally apply, *what* the enforced action must be, retention of DLP evidence, and — above
> all — **whether a given event constitutes a reportable HIPAA breach** are **compliance, privacy,
> HIPAA-Security/Privacy-Officer, and legal determinations**, deferred to those functions. The solution
> helps you configure and prove the control; it does not make the regulatory determination.

## Why this matters
- PHI DLP switched straight to **enforce** without simulation is the classic failure: it blocks
  legitimate clinical and billing workflows (referrals, claims, care coordination), floods the help
  desk, and gets disabled within a week. Simulation-first is the difference between a control that
  survives an OCR audit and one that was turned off.
- **PHI is a combination, not a single token.** A diagnosis code on its own, or a name on its own, is
  often not PHI; the *pair* is. Microsoft's HIPAA detection reflects this — which is exactly why
  confidence, instance count, and supporting evidence tuning matters so much for PHI.
- **Endpoint DLP is licensing- and onboarding-dependent** — it requires the right plan and devices
  onboarded to Purview (shared with Microsoft Defender for Endpoint onboarding). A DLP policy scoped to
  the Devices location does nothing until the endpoints are actually onboarded and reporting.
- A HIPAA control has to be **defensible**: an evidence trail (Activity Explorer, DLP alerts, an audit
  export) that shows the control exists, what it caught, and how incidents were handled. This solution
  produces that evidence as a first-class deliverable.

## How it works
1. **Sensitive information types (SITs) and classifiers** define *what* to look for. For PHI, Purview
   ships a built-in **DLP policy template "U.S. Health Insurance Act (HIPAA)"** and the underlying
   built-in SITs it uses — including **U.S. Social Security Number (SSN)**, **International
   Classification of Diseases (ICD-9-CM)**, and **International Classification of Diseases
   (ICD-10-CM)** — plus related SITs such as **Drug Enforcement Agency (DEA) Number** and passport/ID
   SITs. You extend these with **custom SITs** (e.g. a medical record number / MRN regex + keyword +
   confidence), **Exact Data Match (EDM)** against a hashed upload of your patient roster for near-zero
   false positives, and **trainable classifiers** where a category is conceptual. *Confirm each SIT's
   availability in your tenant — the SIT library and templates evolve.*
2. **DLP policies** bind those SITs to **locations** (Exchange, SharePoint, OneDrive, Teams
   chat/channel, and **Devices/Endpoint**) with **conditions** (which SIT, how many instances, what
   confidence), **actions** (audit / notify / restrict / block; encrypt outbound mail; restrict
   USB/print/cloud-upload on endpoint), and **user experience** (policy tips, allow-with-justification,
   allow-override).
3. **Simulation mode** runs the policy against live traffic and records what *would* have matched — with
   or without policy tips shown — so you see the true PHI hit volume and false positives **before** any
   enforcement. Every policy in this solution starts here.
4. **Tuning** reduces false positives using confidence levels, instance thresholds, supporting keyword
   evidence, EDM, and exceptions — measured against the simulation results.
5. **Enforcement** turns the tuned policy on (tips/override/block; encrypt PHI email) in a limited ring,
   then expands.
6. **Incident/alert handling** — DLP rule matches raise **alerts** in the Purview portal and DLP events
   flow to **Activity Explorer**; this solution wires triage, severity, and response so a possible PHI
   disclosure is actually reviewed (and escalated to the Privacy/Security Officer where the *breach*
   determination is made — deferred).

## The five DLP locations (and what each controls for PHI)
- **Exchange (email):** outbound mail containing PHI matched on content, attachments, and recipients —
  block, or **encrypt** on match to an external recipient.
- **SharePoint & OneDrive:** documents containing PHI at rest and when shared; block external sharing on
  match.
- **Teams chat & channel messages:** PHI pasted or shared in messages (a common care-coordination leak).
- **Endpoint (Devices):** activities on **onboarded** Windows/macOS devices — copy PHI to USB, copy to
  network share, print, upload to unallowed cloud apps/browsers, copy to clipboard, paste to browser.
  **Requires onboarding and the right licensing.**
- **On-premises / Fabric / Power BI / cloud apps (Defender for Cloud Apps):** additional locations that
  may be available depending on licensing — **verify availability in your tenant.**

## The simulate→enforce journey (the core discipline)
> Map HIPAA SITs/classifiers → build each DLP policy in **SIMULATION** (no user impact) → measure PHI
> hit volume and false positives in **Activity Explorer / DLP alerts** → **tune** (confidence, instance
> count, keywords, EDM, exceptions) → re-simulate until false positives are acceptable → enable with
> **policy tips + allow-override/justification** (and **encrypt** for outbound PHI email) in a **pilot
> ring** → validate → expand to enforcement tenant-wide → operate (triage alerts, review overrides,
> re-tune).

## What you can control
- Which HIPAA SITs/classifiers are in scope and at what **confidence** and **instance count** they
  trigger.
- Which **locations** each policy covers and which users/sites/groups are **included or excluded**
  (e.g. a clinical department pilot ring).
- The **action** per data category (audit → tip → justify → block → encrypt) — set per compliance's
  determination.
- Whether users get **policy tips**, can **override** with justification, and what the override says.
- The **pilot ring** enforced first, and the simulation dwell time before enforcement.

## Limitations (be honest with buyers)
- **This is not a HIPAA breach determination tool.** DLP surfaces *potential* PHI disclosures; whether
  an event is a **reportable breach** (and any 60-day notification) is a Privacy/Security-Officer and
  legal decision — deferred.
- **Endpoint DLP requires onboarded devices and the appropriate licensing** (verify your plan —
  endpoint DLP and several advanced classifiers are gated behind E5 / the E5 Compliance add-on). A
  Devices-location policy is inert until onboarding is complete.
- **Some features are in preview** and portal paths / the SIT library **evolve** — this solution flags
  "verify your licensing/tenant" rather than asserting availability that may differ in your tenant.
- DLP inspects **content it can classify**; strongly encrypted or unrecognized formats, scanned images
  without OCR, or content below the confidence/instance threshold will not match. DLP is one control
  among several (labels, encryption, access), not a guarantee.
- **The enforced action and the acceptable false-positive threshold for PHI are compliance/legal
  decisions**, not technical defaults — this solution configures and proves the control; the
  determination is deferred.

## Naming convention (used in every doc and script)
Every artifact this solution creates uses `<Purpose> – <Scope> – <Stage>`, reused verbatim across the
docs, scripts, and the Purview portal. The standard set:

| Artifact | Name |
|---|---|
| Custom sensitive info type (e.g. MRN) | `MRN – Custom SIT – PHI` |
| EDM schema / SIT (patient roster) | `Patient Identifiers – EDM – PHI` |
| Email DLP policy (simulation) | `DLP – PHI Email – Simulation` |
| Cloud DLP policy (simulation) | `DLP – PHI SPO+OneDrive+Teams – Simulation` |
| Endpoint DLP policy (simulation) | `DLP – PHI Endpoint – Simulation` |
| Enforced pilot policy | `DLP – PHI All Locations – Enforce Pilot` |
| Pilot user ring | `PHI DLP Pilot Ring – Stage1` |
| Policy-tip / override text | `PHI DLP Notice – Standard – AllPolicies` |
| Incident/alert workflow | `PHI DLP Alerts – Triage – Operations` |

## The standard deployment model
> **Assess** current PHI exposure and classification intent → **Design** HIPAA SITs/classifiers,
> policies, and user experience → **Configure** SITs and policies **in simulation** → **Pilot**
> (simulate → tune → enforce to a ring) → **Validate** against pass/fail gates (PHI leaks blocked,
> false-positive rate low, incidents handled) → **Expand** to tenant-wide enforcement and ongoing
> operations. Every high-impact change is piloted in simulation first, with a documented rollback.
