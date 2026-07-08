# 1. Solution Overview — Financial (GLBA/SOX) DLP Pack (Microsoft Purview)

## What this solution is
Financial institutions and public companies hold two categories of data that must not leak: **customer
nonpublic personal information (NPI)** protected under the **Gramm-Leach-Bliley Act (GLBA)** — account
numbers, bank routing/account numbers, card numbers, Social Security / taxpayer numbers, and the
personally identifiable financial information tied to them — and **financial-reporting and material
non-public information (MNPI)** whose integrity and confidentiality underpin **Sarbanes-Oxley (SOX)**
controls over financial reporting. Both walk out through the same everyday channels: an email with a
customer account export attached, a general-ledger extract shared "anyone with the link" from SharePoint
or OneDrive, card or routing numbers pasted into a Teams chat, or a draft earnings file copied to a USB
stick or printed.

**Microsoft Purview Data Loss Prevention (DLP)** detects and controls that movement by matching the
*content* being shared against **sensitive information types (SITs)** and **classifiers**, then applying a
policy action — audit only, warn with a **policy tip**, allow with a business **justification**, or
**block** — across **Exchange email, SharePoint, OneDrive, Teams, and Endpoint (managed devices)**. This
pack is a repeatable, evidence-driven way to stand up **GLBA/SOX-aligned DLP for financial and NPI data**
using only the **Microsoft Purview portal**, **Security & Compliance PowerShell** (`Connect-IPPSSession`),
and **Microsoft Graph** — no third-party DLP tooling. Its defining discipline is that **every policy is
built and proven in SIMULATION mode first** (Microsoft's built-in test mode that evaluates policy against
real traffic and shows what *would* have matched, with zero user impact), tuned for a low false-positive
rate, then enforced to a pilot ring, then expanded.

> **Scope boundary.** This solution delivers the **technical method and evidence** for DLP configuration.
> *Which* data is NPI under GLBA, *which* records fall in SOX scope, *which* classifiers legally apply,
> what the **enforced action** must be for a given category, and any **records-retention** obligation are
> **compliance, privacy, records, and legal determinations** — deferred to those functions. The solution
> helps you configure and prove the control; it does not make the regulatory determination.

## Why this matters
- **GLBA's Safeguards Rule** obligates financial institutions to protect customer NPI. DLP that detects
  and controls NPI movement across mail, cloud, and endpoints is a direct, demonstrable safeguard — and
  the simulation evidence is exactly the kind of artifact an examiner or auditor expects.
- **SOX** cares about the integrity and confidentiality of financial-reporting data and MNPI. DLP reduces
  the risk of pre-release financial data or general-ledger extracts leaving through uncontrolled channels
  — a control that supports (does not replace) the broader ICFR program.
- DLP switched straight to **enforce** without simulation is the classic failure: it blocks legitimate
  finance workflows (statements, reconciliations, vendor payments), floods the help desk, and gets
  disabled within a week. Simulation-first is the difference between a control that survives an audit and
  one that was turned off before it.
- Financial SITs are **prone to false positives** — a built-in *Credit Card Number* or *ABA Routing
  Number* detector fires on internal reference numbers, GL codes, and invoice IDs. Tuning (confidence
  levels, instance counts, supporting keywords, Exact Data Match) is what makes the control trusted.

## How it works
1. **Sensitive information types (SITs) and classifiers** define *what* to look for. Purview ships
   built-in **financial SITs** — *Credit Card Number*, *ABA Routing Number*, *U.S. Bank Account Number*,
   *International Banking Account Number (IBAN)*, *SWIFT Code*, *U.S. Social Security Number (SSN)*, and
   *U.S. Individual Taxpayer Identification Number (ITIN)* among them — and ships **DLP policy templates**
   for **U.S. Gramm-Leach-Bliley Act (GLBA)** and **U.S. Financial Data** (verify the exact template name
   and SIT membership in your tenant — templates evolve). Where built-ins don't fit (internal account
   numbers, GL/cost-center codes, statement templates) you add **custom SITs** (regex + keyword +
   confidence), **Exact Data Match (EDM)** SITs (matched against a hashed upload of your real account
   data for near-zero false positives), **document fingerprinting** of financial-statement templates, and
   **trainable classifiers** (verify availability/plan).
2. **DLP policies** bind those SITs to **locations** (Exchange, SharePoint, OneDrive, Teams, and
   **Devices/Endpoint**) with **conditions** (which SIT, how many instances, what confidence), **actions**
   (audit / notify / restrict / block, restrict USB/print/cloud-app upload on endpoint), and **user
   experience** (policy tips, allow-with-justification, allow-override).
3. **Simulation mode** runs each policy against live traffic and records what *would* have matched — with
   or without policy tips shown — so you see true hit volume and false positives **before** any
   enforcement. Every policy in this pack starts here.
4. **Tuning** reduces false positives using confidence levels, instance thresholds, supporting keyword
   evidence, EDM, and exceptions — measured against the simulation results.
5. **Enforcement** turns the tuned policy on (tips/override/block) in a limited **finance pilot ring**,
   then expands.
6. **Incident/alert handling** — DLP rule matches raise **alerts** in the Purview portal and events flow
   to **Activity Explorer**; this solution wires the triage, severity, and response workflow so financial
   matches are actually acted on.

## The five DLP locations (and what each controls for financial data)
- **Exchange (email):** outbound mail with account exports, statements, or card/routing numbers; block or
  encrypt on match.
- **SharePoint & OneDrive:** GL extracts, reconciliations, and customer records at rest and when shared;
  block external sharing on match.
- **Teams chat & channel messages:** account/card numbers or MNPI pasted into finance channels.
- **Endpoint (Devices):** activities on **onboarded** Windows/macOS devices — copy financial files to USB,
  print, upload to unallowed cloud apps/browsers, copy to clipboard/paste to browser. **Requires
  onboarding and the right licensing.**
- **Cloud apps / on-premises / Fabric / Power BI:** additional locations that may be available depending
  on licensing — **verify availability in your tenant.**

## The simulate→enforce journey (the core discipline)
> Map financial/NPI SITs and classifiers → build each DLP policy in **SIMULATION** (no user impact) →
> measure hit volume and false positives in **Activity Explorer / DLP alerts** → **tune** (confidence,
> instance count, keywords, EDM, exceptions) → re-simulate until false positives are acceptable → enable
> with **policy tips + allow-override/justification** in a **finance pilot ring** → validate → expand to
> **enforce (block)** per compliance's action determination → operate (triage alerts, review overrides,
> re-tune).

## What you can control
- Which financial/NPI SITs/classifiers are in scope, and at what **confidence** and **instance count**
  they trigger.
- Which **locations** each policy covers and which users/sites/groups (e.g. Finance, Treasury) are
  **included or excluded**.
- The **action** per data category (audit → tip → justify → block) — set per compliance's determination.
- Whether users get **policy tips**, can **override** with justification, and what the override says.
- The **finance pilot ring** enforced first, and the simulation dwell time before enforcement.

## Limitations (be honest with buyers)
- **Endpoint DLP and several advanced classifiers require onboarded devices and E5 / the E5 Compliance
  add-on** (verify your plan). A Devices-location policy is inert until onboarding is complete.
- **Some features are in preview** and portal paths / template names **evolve** — this pack flags "verify
  your licensing/tenant" rather than asserting availability or an exact template name that may differ in
  your tenant.
- DLP inspects **content it can classify**; strongly encrypted or unrecognized formats, or content below
  the confidence/instance threshold, won't match. DLP is one control among several (labels, encryption,
  insider risk, access controls), not a guarantee of GLBA/SOX compliance on its own.
- **EDM, document fingerprinting, and trainable classifiers require setup and, for EDM, an ongoing data
  refresh**; they drive false positives down but are not zero-effort.
- **Which data is NPI/SOX-scoped, the enforced action per category, and any retention obligation are
  compliance/legal determinations**, not technical defaults — this pack configures and proves the control;
  the determination is deferred.

## Naming convention (used in every doc and script)
Every artifact uses `<Purpose> – <Scope> – <Stage>`, reused verbatim across the docs, scripts, and the
Purview portal. The standard set:

| Artifact | Name |
|---|---|
| Custom SIT (internal account no.) | `Account Number – Custom SIT – Financial` |
| Custom SIT (GL / cost-center code) | `GL Account Code – Custom SIT – Financial` |
| EDM schema / SIT (customer records) | `Customer NPI – EDM – Financial` |
| Document fingerprint (statements) | `Financial Statement – Fingerprint – SOX` |
| Email DLP policy (simulation) | `DLP – Email NPI – Simulation` |
| Cloud DLP policy (simulation) | `DLP – SPO+OneDrive+Teams NPI – Simulation` |
| Endpoint DLP policy (simulation) | `DLP – Endpoint NPI – Simulation` |
| SOX financial-records policy (sim.) | `DLP – SOX Financial Records – Simulation` |
| Enforced pilot policy | `DLP – All Locations NPI – Enforce Pilot` |
| Finance pilot user ring | `DLP Pilot Ring – Finance Stage1` |
| Policy-tip / override text | `DLP Notice – GLBA NPI – AllPolicies` |
| Incident/alert workflow | `DLP Alerts – Financial – Operations` |

## The standard deployment model
> **Assess** current financial-data exposure and classification intent → **Design** SITs/classifiers,
> policies, and user experience → **Configure** SITs and policies **in simulation** → **Pilot**
> (simulate → tune → enforce to the finance ring) → **Validate** against pass/fail gates (leaks blocked,
> false-positive rate low, incidents handled) → **Expand** to full enforcement and ongoing operations.
> Every high-impact change is piloted in simulation first, with a documented rollback.
