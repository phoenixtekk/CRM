# 1. Solution Overview — GDPR / PII DLP Pack (Microsoft Purview)

## What this solution is
**Personal data** relating to identified or identifiable individuals — names tied to national identifiers,
passport and tax numbers, contact details, financial account data, and the special-category data that
attracts extra protection — leaves an organisation through the same everyday channels everyone uses: an
email with a customer list attached, an HR spreadsheet shared "anyone with the link" from OneDrive or
SharePoint, a national ID number pasted into a Teams chat, or a file of data-subject records copied to a
USB stick or printed from a laptop. **Microsoft Purview Data Loss Prevention (DLP)** detects and controls
that movement by matching the *content* being shared against **sensitive information types (SITs)** and
**classifiers**, then applying a policy action — audit only, warn the user with a **policy tip**, allow with
a business **justification**, or **block** — across **Exchange email, SharePoint, OneDrive, Teams, and
Endpoint (managed devices)**.

This is the **GDPR/PII-aligned DLP pack**: a repeatable, evidence-driven way to stand up EU personal-data
detection and protection policies in Microsoft Purview using only the **Microsoft Purview portal**,
**Security & Compliance PowerShell** (`Connect-IPPSSession`), and **Microsoft Graph** — no third-party DLP
tooling. Its defining discipline is that **every policy is built and proven in SIMULATION mode first**
(Microsoft's built-in test mode that evaluates policy against real traffic and shows what *would* have
matched, with zero user impact), tuned for a low false-positive rate, and only then moved to enforcement.

> **Scope boundary — GDPR determinations are deferred.** This solution delivers the **technical method and
> evidence** for personal-data DLP. *Which* processing is lawful, what constitutes **special-category
> (Article 9) data**, when a transfer is a **restricted cross-border transfer**, what the **lawful basis**
> is, the retention position, and the **enforced action** per data category are **data-protection, privacy
> (DPO), compliance, and legal determinations** — deferred to those functions. The solution helps you
> configure and prove the control; it does not make the GDPR determination. (GDPR: Regulation (EU) 2016/679
> — applicability, lawful basis, and cross-border transfer mechanisms are the organisation's DPO/legal
> counsel to confirm.)

## Why this matters
- DLP that is switched straight to **enforce** without simulation is the classic failure: it blocks
  legitimate business and administration, floods the help desk, and gets disabled within a week.
  Simulation-first is the difference between a control that survives and one that is turned off.
- **National identifier formats are country-specific.** The EU is not one identifier scheme — passport,
  national ID, tax (TIN), and social-security-equivalent numbers differ per member state. Microsoft ships
  **EU-specific built-in SITs** (and per-country ones), but a bespoke national scheme or an internal
  data-subject reference usually needs a **custom SIT** (or **Exact Data Match** against a records export)
  tuned to that format.
- **Special-category data is a policy decision, not a pattern.** Health, biometric, racial/ethnic,
  political, religious, and sexual-orientation data (GDPR Article 9) rarely have a clean regex — they need
  **trainable classifiers** or keyword evidence, and *what* counts as special category is a DPO/legal call.
- **Cross-border transfer is content-plus-context.** DLP can detect personal data leaving to an external or
  non-EU recipient, but *whether* that is a restricted transfer (and what safeguard applies) is a legal
  determination — DLP surfaces the movement and the evidence.
- **Endpoint DLP is licensing- and onboarding-dependent** — it requires the right plan and devices onboarded
  to Purview (shared with Microsoft Defender for Endpoint onboarding). A policy scoped to the Devices
  location does nothing until the endpoints are actually onboarded and reporting.
- False positives are the enemy of adoption. A detector that fires on every internal reference number trains
  staff to ignore every policy tip. Tuning — confidence levels, instance counts, supporting keywords, and
  EDM — is what makes the control usable.

## How it works
1. **Sensitive information types (SITs) and classifiers** define *what* to look for. Purview ships 150+
   **built-in SITs**, including an **EU/GDPR-relevant set** — e.g. *EU Passport Number*, *EU National
   Identification Number*, *EU Social Security Number or Equivalent ID*, *EU Tax Identification Number
   (TIN)*, *EU Driver's License Number*, *EU Debit Card Number*, *International Banking Account Number
   (IBAN)*, and *All Full Names* — plus per-country variants. You can add **custom SITs** (regex + keyword +
   confidence) for local identifiers such as an **internal data-subject reference**, **Exact Data Match
   (EDM)** SITs (matched against a hashed upload of your real data-subject/records export for near-zero false
   positives), and **trainable classifiers** for conceptual categories such as special-category data.
   *Whether a regulatory DLP policy template (for example a GDPR-labeled template) is available in your
   tenant is licensing-/version-dependent — verify in your tenant; do not assume one exists.*
2. **DLP policies** bind those SITs to **locations** (Exchange, SharePoint, OneDrive, Teams chat/channel, and
   **Devices/Endpoint**) with **conditions** (which SIT, how many instances, what confidence; optionally
   *recipient is external* for transfer awareness), **actions** (audit / notify / restrict / block; restrict
   USB/print/cloud-app upload on endpoint), and **user experience** (policy tips, allow-with-justification,
   allow-override).
3. **Simulation mode** runs the policy against live traffic and records what *would* have matched — with or
   without policy tips shown — so you can see the true hit volume and false positives **before** any
   enforcement. Every policy in this pack starts here.
4. **Tuning** reduces false positives using confidence levels, instance thresholds, supporting keyword
   evidence, EDM, and exceptions — measured against the simulation results.
5. **Enforcement** turns the tuned policy on (tips/override/block) in a limited ring, then expands.
6. **Incident/alert handling** — DLP rule matches raise **alerts** in the Purview portal and DLP events flow
   to **Activity Explorer**; this pack wires the triage, severity, and response workflow so matches are
   actually acted on. Because the match evidence *itself* contains personal data, evidence access is kept
   least-privilege (GDPR data-minimisation applied to the control's own records).

## The five DLP locations (and what each controls for personal data)
- **Exchange (email):** customer/HR/marketing lists and data-subject records emailed to unintended or
  external recipients; block or encrypt on match, and detect *external-recipient* transfer.
- **SharePoint & OneDrive:** personal-data files at rest and when shared; block external sharing on match.
- **Teams chat & channel messages:** national identifiers or personal-data content pasted into messages.
- **Endpoint (Devices):** activities on **onboarded** Windows/macOS devices — copy records to USB, copy to
  network share, print, upload to unallowed cloud apps/browsers, copy to clipboard, paste to browser.
  **Requires onboarding and the right licensing.**
- **On-premises / Fabric / Power BI / cloud apps (Defender for Cloud Apps):** additional locations that may
  be available depending on licensing — **verify availability in your tenant.**

## The simulate→enforce journey (the core discipline)
> Define SITs/classifiers for EU personal data → build each DLP policy in **SIMULATION** (no user impact) →
> measure hit volume and false positives in **Activity Explorer / DLP alerts** → **tune** (confidence,
> instance count, keywords, EDM, exceptions) → re-simulate until false positives are acceptable → enable with
> **policy tips + allow-override/justification** in a **pilot ring** → validate → expand to
> **enforce (block)** per the DPO/legal action determination → operate (triage alerts, review overrides,
> re-tune).

## What you can control
- Which SITs/classifiers detect personal data and at what **confidence** and **instance count** they trigger
  (e.g. a single national ID vs a bulk data-subject list).
- Which **locations** each policy covers and which users/sites/groups are **included or excluded** (e.g. an
  HR or DPO function may be treated differently from general staff).
- The **action** per data category (audit → tip → justify → block) — set per the DPO/legal determination.
- Whether the policy adds **transfer awareness** (condition *recipient is external* / non-EU) for
  cross-border movement — the *legal* treatment of that transfer stays with legal.
- Whether users get **policy tips**, can **override** with justification, and what the override says.
- The **pilot ring** enforced first and the simulation dwell time before enforcement.

## Limitations (be honest with buyers)
- **Endpoint DLP requires onboarded devices and the appropriate licensing** (verify your plan — endpoint DLP
  and several advanced classifiers are gated behind E5 / the E5 Compliance add-on). A Devices-location policy
  is inert until onboarding is complete.
- **Some features are in preview** and portal paths **evolve** — this pack flags "verify your
  licensing/tenant" rather than asserting availability that may differ in your tenant.
- DLP inspects **content it can classify**; strongly encrypted or unrecognised file formats, or content below
  the confidence/instance threshold, will not match. DLP is one control among several, not a guarantee.
- **The GDPR treatment of any given content — lawful basis, special-category status, whether a transfer is
  restricted, the retention position, the enforced action — is a data-protection/privacy/legal decision**,
  not a technical default. This pack configures and proves the control; the determination is deferred.

## Naming convention (used in every doc and script)
Every artifact this solution creates uses `<Purpose> – <Scope> – <Stage>`, reused verbatim across the docs,
scripts, and the Purview portal. The standard set:

| Artifact | Name |
|---|---|
| Custom sensitive info type (national ID / data-subject ref) | `EU National ID – Custom SIT – GDPR` |
| EDM schema / SIT (data-subject records) | `Data Subject Records – EDM – GDPR` |
| Email DLP policy (simulation) | `DLP – Email EU Personal Data – Simulation` |
| Cloud DLP policy (simulation) | `DLP – SPO+OneDrive+Teams EU Personal Data – Simulation` |
| Endpoint DLP policy (simulation) | `DLP – Endpoint EU Personal Data – Simulation` |
| Enforced pilot policy | `DLP – All Locations EU Personal Data – Enforce Pilot` |
| Pilot user ring | `GDPR DLP Pilot Ring – Stage1` |
| Policy-tip / override text | `GDPR DLP Notice – Standard – AllPolicies` |
| Incident/alert workflow | `GDPR DLP Alerts – Triage – Operations` |

## The standard deployment model
> **Assess** current personal-data exposure and classification intent → **Design** SITs/classifiers,
> policies, and user experience → **Configure** SITs and policies **in simulation** → **Pilot** (simulate →
> tune → enforce to a ring) → **Validate** against pass/fail gates (personal data blocked, false-positive
> rate low, incidents handled) → **Expand** to the intended scope and ongoing operations. Every high-impact
> change is piloted in simulation first, with a documented rollback.
