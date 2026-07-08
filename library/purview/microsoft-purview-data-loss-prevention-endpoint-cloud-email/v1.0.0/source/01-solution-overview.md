# 1. Solution Overview — Microsoft Purview Data Loss Prevention (DLP): Endpoint, Cloud & Email

## What this solution is
Sensitive data leaves organizations through the everyday channels people already use: an email with a
customer spreadsheet attached, a document shared "anyone with the link" from OneDrive or SharePoint, a
credit-card number pasted into a Teams chat, or a file copied to a USB stick or printed from a laptop.
**Microsoft Purview Data Loss Prevention (DLP)** detects and controls that movement by matching the
*content* being shared against **sensitive information types** and **classifiers**, then applying a policy
action — audit only, warn the user with a **policy tip**, allow with a business **justification**, or
**block** — across **Exchange email, SharePoint, OneDrive, Teams, and Endpoint (managed devices)**.

This solution is a repeatable, evidence-driven way to implement Purview DLP across all of those locations
using only the **Microsoft Purview portal**, **Security & Compliance PowerShell** (`Connect-IPPSSession`),
and **Microsoft Graph** — no third-party DLP tooling. Its defining discipline is that **every policy is
built and proven in SIMULATION mode first** (Microsoft's built-in test mode that evaluates policy against
real traffic and shows what *would* have matched, without affecting a single user), tuned for a low
false-positive rate, and only then moved to enforcement.

> **Scope boundary.** This solution delivers the **technical method and evidence** for DLP configuration.
> *Which* data is regulated, *which* classifiers legally apply, and *what* the enforced action must be for
> a given data category are **business, compliance, privacy, and legal determinations** — deferred to those
> functions. The solution helps you configure and prove the control; it does not make the policy decision.

## Why this matters
- DLP that is switched straight to **enforce** without simulation is the classic failure: it blocks
  legitimate business, floods the help desk, and gets disabled within a week. Simulation-first is the
  difference between a control that survives and one that is turned off.
- **Endpoint DLP is licensing- and onboarding-dependent** — it requires the right plan and devices
  onboarded to Purview (shared with Microsoft Defender for Endpoint onboarding). A DLP policy scoped to
  the Devices location does nothing until the endpoints are actually onboarded and reporting.
- False positives are the enemy of adoption. A built-in credit-card detector that fires on internal
  reference numbers trains users to ignore every policy tip. Tuning — confidence levels, instance counts,
  supporting keywords, and Exact Data Match — is what makes the control trusted.
- The same sensitive-information-type library drives DLP, auto-labeling, and insider risk. Getting the
  classification layer right here pays off across the whole Purview estate.

## How it works
1. **Sensitive information types (SITs) and classifiers** define *what* to look for. Purview ships
   150+ **built-in SITs** (credit card, SSN/national ID, IBAN, health record numbers, etc.), and you can
   add **custom SITs** (regex + keyword + confidence), **Exact Data Match (EDM)** SITs (matched against a
   hashed upload of your real data for near-zero false positives), and **trainable classifiers**
   (machine-learned categories such as source code, resumes, or financial statements).
2. **DLP policies** bind those SITs to **locations** (Exchange, SharePoint, OneDrive, Teams chat/channel,
   and **Devices/Endpoint**) with **conditions** (which SIT, how many instances, what confidence),
   **actions** (audit / notify / restrict / block, restrict USB/print/cloud-app upload on endpoint), and
   **user experience** (policy tips, allow-with-justification, allow-override).
3. **Simulation mode** runs the policy against live traffic and records what *would* have matched — with
   or without policy tips shown — so you can see the true hit volume and false positives **before** any
   enforcement. Every policy in this solution starts here.
4. **Tuning** reduces false positives using confidence levels, instance thresholds, supporting keyword
   evidence, EDM, and exceptions — measured against the simulation results.
5. **Enforcement** turns the tuned policy on (tips/override/block) in a limited ring, then expands.
6. **Incident/alert handling** — DLP rule matches raise **alerts** in the Purview portal and DLP events
   flow to **Activity Explorer**; this solution wires the triage, severity, and response workflow so
   matches are actually acted on.

## The five DLP locations (and what each controls)
- **Exchange (email):** outbound/inbound mail matched on content, attachments, and recipients; block or
  encrypt on match.
- **SharePoint & OneDrive:** documents at rest and when shared; block external sharing on match.
- **Teams chat & channel messages:** sensitive content pasted or shared in messages.
- **Endpoint (Devices):** activities on **onboarded** Windows/macOS devices — copy to USB, copy to network
  share, print, upload to unallowed cloud apps/browsers, copy to clipboard, paste to browser. **Requires
  onboarding and the right licensing.**
- **On-premises / Fabric / Power BI / cloud apps (Defender for Cloud Apps):** additional locations that
  may be available depending on licensing — **verify availability in your tenant.**

## The simulate→enforce journey (the core discipline)
> Define SITs/classifiers → build each DLP policy in **SIMULATION** (no user impact) → measure hit volume
> and false positives in **Activity Explorer / DLP alerts** → **tune** (confidence, instance count,
> keywords, EDM, exceptions) → re-simulate until false positives are acceptable → enable with **policy
> tips + allow-override/justification** in a **pilot ring** → validate → expand to **enforce (block)**
> tenant-wide → operate (triage alerts, review overrides, re-tune).

## What you can control
- Which SITs/classifiers are in scope and at what **confidence** and **instance count** they trigger.
- Which **locations** each policy covers and which users/sites/groups are **included or excluded**.
- The **action** per data category (audit → tip → justify → block) — set per compliance's determination.
- Whether users get **policy tips**, can **override** with justification, and what the override says.
- The **pilot ring** enforced first, and the simulation dwell time before enforcement.

## Limitations (be honest with buyers)
- **Endpoint DLP requires onboarded devices and the appropriate licensing** (verify your plan — endpoint
  DLP and several advanced classifiers are gated behind E5 / the E5 Compliance add-on). A Devices-location
  policy is inert until onboarding is complete.
- **Some features are in preview** and portal paths **evolve** — this solution flags "verify your
  licensing/tenant" rather than asserting availability that may differ in your tenant.
- DLP inspects **content it can classify**; strongly encrypted or unrecognized file formats, or content
  below the confidence/instance threshold, will not match. DLP is one control among several, not a
  guarantee.
- **EDM and trainable classifiers require setup and, for EDM, an ongoing data refresh**; they are the tools
  that drive false positives down but they are not zero-effort.
- The **enforced action for a data category is a compliance/legal decision**, not a technical default —
  this solution configures and proves the control; the determination is deferred.

## Naming convention (used in every doc and script)
Every artifact this solution creates uses `<Purpose> – <Scope> – <Stage>`, reused verbatim across the
docs, scripts, and the Purview portal. The standard set:

| Artifact | Name |
|---|---|
| Custom sensitive info type | `Employee ID – Custom SIT – Classification` |
| EDM schema / SIT | `Customer PII – EDM – Classification` |
| Email DLP policy (simulation) | `DLP – Email PII – Simulation` |
| Cloud DLP policy (simulation) | `DLP – SPO+OneDrive+Teams PII – Simulation` |
| Endpoint DLP policy (simulation) | `DLP – Endpoint PII – Simulation` |
| Enforced pilot policy | `DLP – All Locations PII – Enforce Pilot` |
| Pilot user ring | `DLP Pilot Ring – Stage1` |
| Policy-tip / override text | `DLP Notice – Standard – AllPolicies` |
| Incident/alert workflow | `DLP Alerts – Triage – Operations` |

## The standard deployment model
> **Assess** current data exposure and classification intent → **Design** SITs/classifiers, policies, and
> user experience → **Configure** SITs and policies **in simulation** → **Pilot** (simulate → tune → enforce
> to a ring) → **Validate** against pass/fail gates (leaks blocked, false-positive rate low, incidents
> handled) → **Expand** to tenant-wide enforcement and ongoing operations. Every high-impact change is
> piloted in simulation first, with a documented rollback.
