# 1. Solution Overview — PCI-DSS DLP Pack (Microsoft Purview)

## What this solution is
Payment card numbers spread far beyond the systems that are supposed to hold them. A **Primary Account
Number (PAN)** ends up in an email to a customer, pasted into a Teams chat, saved in a spreadsheet on
OneDrive, copied to a USB stick, or printed from a laptop — every one of those a **cardholder-data
exposure** and a **PCI-DSS gap**. This solution uses **Microsoft Purview Data Loss Prevention (DLP)**,
tuned specifically for **cardholder data**, to detect and control that movement: it matches content
against the **Credit Card Number** sensitive information type (a Luhn-validated PAN detector) and related
classifiers, then applies a policy action — **audit**, warn with a **policy tip**, allow with a business
**justification**, or **block** — across **Exchange email, SharePoint, OneDrive, Teams, and Endpoint
(managed devices)**.

It is a repeatable, evidence-driven way to stand up PCI-aligned DLP using only the **Microsoft Purview
portal**, **Security & Compliance PowerShell** (`Connect-IPPSSession`), and **Microsoft Graph** — no
third-party tooling. Its defining discipline is that **every policy is built and proven in SIMULATION
mode first** (Microsoft's built-in test mode that evaluates policy against real traffic and shows what
*would* have matched, without affecting a single user), tuned for a **low false-positive rate**, and only
then moved to enforcement — because a card-data DLP policy switched straight to *block* halts legitimate
payment workflows and gets turned off within a week.

> **Scope boundary.** This solution delivers the **technical method and evidence** for detecting and
> controlling cardholder data. *Which* systems are inside your **Cardholder Data Environment (CDE)**,
> *what* your PCI-DSS scope is, *whether* a given data flow is compliant, and *what* the enforced action
> must be are **PCI, compliance, and QSA (Qualified Security Assessor) determinations** — deferred to
> those functions. The solution helps you configure and prove the control and produce evidence for an
> assessor; it does not make the compliance determination or attest to PCI-DSS compliance.

## Why this matters (PCI-DSS specifics)
- **PCI-DSS is about where PAN lives and moves.** DLP tuned for cardholder data directly supports the
  standard's account-data-protection and scoping objectives by **finding PAN outside the CDE** (email,
  files, chat, endpoints) — the "PAN sprawl" that widens assessment scope and creates exposure.
- **Sensitive Authentication Data (SAD) must never be stored.** PCI-DSS prohibits storing full track
  data, card verification codes (CVV/CVV2/CVC2/CID), and PINs after authorization. DLP helps you *detect*
  SAD-in-storage as an early-warning signal — but SAD detectors are weak on their own (a 3–4 digit code
  is not reliably distinguishable), so this solution anchors on **PAN detection** and treats SAD as a
  keyword-supported, best-effort signal, not a guarantee.
- **False positives are the enemy of adoption.** The built-in Credit Card detector will fire on any
  Luhn-valid 13–19 digit sequence — including internal reference numbers. Tuning (confidence, instance
  count, supporting keywords, and **Exact Data Match** against your real PANs) is what makes the control
  trusted by the business.
- **Evidence is the deliverable an assessor wants.** DLP match reports, Activity Explorer trails, and a
  documented simulate→enforce change log are the artifacts that demonstrate the control operates — the
  evidence a QSA reviews (the compliance *determination* stays with the QSA).

## How it works
1. **Sensitive information types (SITs) for cardholder data.** The built-in **Credit Card Number** SIT
   detects PANs via a **card-brand pattern + Luhn checksum + supporting keywords** across the major brands
   (Visa, Mastercard, Amex, Discover, JCB, Diners). Where you need near-zero false positives on *your*
   card numbers, add an **Exact Data Match (EDM)** SIT built from a hashed upload of your PAN table.
2. **DLP policies** bind those SITs to **locations** (Exchange, SharePoint, OneDrive, Teams chat/channel,
   and **Devices/Endpoint**) with **conditions** (which SIT, how many instances, what confidence),
   **actions** (audit / notify / restrict / block, restrict USB/print/cloud-upload on endpoint), and
   **user experience** (policy tips, allow-with-justification, allow-override).
3. **Simulation mode** runs each policy against live traffic and records what *would* have matched — with
   or without policy tips shown — so you see true PAN hit volume and false positives **before** any
   enforcement. Every policy in this solution starts here.
4. **Tuning** reduces false positives using confidence levels, instance thresholds, supporting keyword
   evidence, EDM, and exceptions — measured against the simulation results.
5. **Enforcement** turns the tuned policy on (tips/override/block) in a limited ring, then expands.
6. **Incident/alert handling** — DLP rule matches raise **alerts** in the Purview portal and DLP events
   flow to **Activity Explorer**; this solution wires the triage, severity, and response workflow so PAN
   matches are actually investigated and dispositioned.

## The five DLP locations (and what each controls for card data)
- **Exchange (email):** outbound/inbound mail containing PAN in the body or attachments; block or encrypt
  on match — the most common way a card number walks out.
- **SharePoint & OneDrive:** documents at rest and when shared; block external sharing of files containing
  PAN — the "spreadsheet of card numbers shared anyone-with-the-link" case.
- **Teams chat & channel messages:** PAN pasted or shared in messages.
- **Endpoint (Devices):** activities on **onboarded** Windows/macOS devices — copy PAN-bearing files to
  USB, copy to network share, print, upload to unallowed cloud apps/browsers, copy to clipboard, paste to
  browser. **Requires onboarding and the right licensing.**
- **On-premises / cloud apps (Defender for Cloud Apps):** additional locations that may be available
  depending on licensing — **verify availability in your tenant.**

## The simulate→enforce journey (the core discipline)
> Confirm the PAN SIT (and optional EDM) → build each DLP policy in **SIMULATION** (no user impact) →
> measure PAN hit volume and false positives in **Activity Explorer / DLP alerts** → **tune** (confidence,
> instance count, keywords, EDM, exceptions) → re-simulate until false positives are acceptable → enable
> with **policy tips + allow-override/justification** in a **pilot ring** → validate → expand to
> **enforce (block)** for the intended scope → operate (triage PAN alerts, review overrides, re-tune).

## What you can control
- Which SITs/classifiers detect card data and at what **confidence** and **instance count** they trigger
  (e.g. a single PAN vs a bulk export of ≥10).
- Which **locations** each policy covers and which users/sites/groups are **included or excluded** (e.g.
  scope out the sanctioned in-CDE payment application, scope in everything else).
- The **action** per flow (audit → tip → justify → block) — set per the PCI/compliance determination.
- Whether users get **policy tips**, can **override** with justification, and what the override says.
- The **pilot ring** enforced first, and the simulation dwell time before enforcement.

## Limitations (be honest with buyers)
- **Endpoint DLP requires onboarded devices and the appropriate licensing** (verify your plan — endpoint
  DLP, EDM, and several advanced classifiers are gated behind E5 / the E5 Compliance add-on). A
  Devices-location policy is inert until onboarding is complete.
- **PAN detection is content-based.** DLP inspects content it can classify; strongly encrypted files,
  images of cards, unrecognized formats, or a PAN split across fields may not match. **Truncated PANs**
  (first six/last four, per PCI display rules) are intentionally *not* full PANs and will not — and should
  not — match a full-PAN detector. DLP is one control among several, not proof the CDE is contained.
- **SAD detection is best-effort.** CVV/track/PIN detectors are weak in isolation; treat SAD hits as a
  signal to investigate, not a reliable control.
- **EDM is what drives false positives toward zero** but requires the schema, a hashed upload, and an
  ongoing refresh — it is not zero-effort.
- **Some features are in preview** and portal paths **evolve** — this solution flags "verify your
  licensing/tenant" rather than asserting availability that may differ in your tenant.
- **PCI scope, CDE boundaries, the enforced action per flow, and compliance/QSA sign-off are
  determinations for your compliance function and assessor** — this solution configures and proves the
  control and produces the evidence; it does not attest to compliance.

## Naming convention (used in every doc and script)
Every artifact this solution creates uses a consistent name, reused verbatim across the docs, scripts, and
the Purview portal. The standard set:

| Artifact | Name |
|---|---|
| PAN detector (built-in SIT) | `Credit Card Number` (built-in — do not recreate) |
| EDM schema / SIT (your real PANs) | `Cardholder PAN – EDM – PCI` |
| Email DLP policy (simulation) | `DLP – Email PAN – Simulation` |
| Cloud DLP policy (simulation) | `DLP – SPO+OneDrive+Teams PAN – Simulation` |
| Endpoint DLP policy (simulation) | `DLP – Endpoint PAN – Simulation` |
| Enforced pilot policy | `DLP – All Locations PAN – Enforce Pilot` |
| Pilot user ring | `PCI DLP Pilot Ring – Stage1` |
| Policy-tip / override text | `PCI DLP Notice – Standard – AllPolicies` |
| Incident/alert workflow | `PCI DLP Alerts – Triage – Operations` |

## The standard deployment model
> **Assess** current PAN exposure (where card data lives today) → **Design** the PAN SIT / EDM and the
> policies + user experience → **Configure** SITs and policies **in simulation** → **Pilot** (simulate →
> tune → enforce to a ring) → **Validate** against pass/fail gates (PAN leaks blocked, false-positive
> rate low, incidents handled) → **Expand** to the intended enforcement scope and ongoing operations.
> Every high-impact change is piloted in simulation first, with a documented rollback.
