# Clipboard & Screen-Capture Protection — Microsoft Purview

> **Version 1.0.0** · Category: Purview · Solution code: DLPCLIP

> This is the online, maintained copy of the implementation guide. When this solution is updated, eligible customers are alerted and can return here for the current content. Downloadable PDF + scripts are attached on the store listing.



---


# Executive Summary — Clipboard & Screen-Capture Protection in Microsoft Purview

## The problem

Sensitive data leaves endpoints through the two most mundane paths of all — a user **copies content to
the clipboard** and pastes it into personal webmail, chat, or a note-taking app; or a user **takes a
screenshot** of a sensitive document, dashboard, or record and the pixels walk out as an image. Both
**bypass every control that watches the file**: the document can be encrypted, un-shareable, and blocked
from email, yet the copy-paste and the screenshot never touch any of those controls. Left unaddressed,
that is both a **compliance gap** and a direct **data-risk exposure**.

## The solution

This solution delivers **Microsoft Purview Endpoint Data Loss Prevention (Endpoint DLP)** restrictions for
**copy to clipboard** and **screen capture** of sensitive content on **onboarded Windows and macOS
devices**, end to end. It confirms the sensitive-content detectors (sensitivity labels and/or sensitive
information types), configures the Endpoint DLP settings that define sanctioned apps and browsers, and
authors a single policy whose rule restricts the two activities — keyed to your sensitive content.
Crucially, every restriction is **piloted in simulation/test mode first** — it records what it *would* do
without blocking anyone — validated on a small device ring, and only then moved to **enforce**.

## How it works — the model

The delivery follows a disciplined, repeatable model with an explicit pass/fail gate at each step:

**Assess → Design → Configure → Pilot (simulation) → Validate → Expand (enforce).**

Because endpoint block actions stop work at the moment of the action, nothing is enforced until it has
been proven, in simulation, to catch the right content and leave sanctioned copy-paste and normal
screenshots alone — with a one-setting rollback to simulation available at all times.

## What you get

- A complete document set: Overview, Requirements, an ordered Implementation guide, Testing (pass/fail
  gates), Troubleshooting, Best Practices, and this summary.
- **Five PowerShell tools** (Security & Compliance PowerShell / Microsoft Graph) — discovery, configuration
  (simulation, `-WhatIf` first), validation, reporting, and scope/health readiness — all **read-only or
  preview by default, with no credentials in code.**
- A **defensibility evidence pack**: proof of what was configured, that the clipboard and screen-capture
  restrictions were validated in simulation before enforcement, that the false-positive rate is low, and
  that matches raise alerts that are triaged.

## Scope and boundaries

- Endpoint DLP is **licensing-dependent** (typically Microsoft 365 E5 / the E5 Compliance add-on) and
  requires **onboarded devices**; the Purview portal **evolves** — capability availability and exact paths
  are **verified against your licensing/tenant**, never assumed.
- **Screen-capture restriction is newer and may be in preview**, is limited to supported apps/browsers and
  minimum OS builds, and evolves — this solution **flags "verify your licensing/tenant"** and can deliver
  **clipboard restriction first** where screen capture is not yet available.
- **Regulatory, records, and legal determinations** — which data is sensitive, whether copy/screenshot must
  be **blocked** versus **audited**, and whether a user's action is a violation — remain with your
  **compliance, security, records, privacy, and legal** functions. This solution provides the **technical
  method and the evidence**, not the determination.

## The bottom line

Two **uncontrolled exfiltration paths** — the clipboard and the screenshot — become a **monitored, then
enforced** control set in Microsoft Purview: **configured, piloted in simulation, validated, and
defensible.**


---


# 1. Solution Overview — Clipboard & Screen-Capture Protection (Microsoft Purview)

## What this solution is
File-level controls — DLP on email, encryption, external-sharing blocks — do nothing about the two most
mundane exfiltration paths on an endpoint: a user **copies sensitive content to the clipboard** and pastes
it into a personal webmail, chat, or note-taking app; or a user **takes a screenshot** of a sensitive
document, dashboard, or record and the pixels walk out as an image. Both bypass every control that watches
the *file*. **Microsoft Purview Endpoint Data Loss Prevention (Endpoint DLP)** closes those two paths by
watching the *activity* on an **onboarded device**: when content that matches your **sensitive information
types** (or carries a sensitive **sensitivity label**) is copied to the clipboard or captured to screen,
the policy can **audit**, **warn with a policy tip and allow-with-justification**, or **block** the action.

This solution is a repeatable, evidence-driven way to configure **clipboard** and **screen-capture**
restrictions for sensitive content on endpoints using only the **Microsoft Purview portal**, **Security &
Compliance PowerShell** (`Connect-IPPSSession`), and **Microsoft Graph** — no third-party agent. Its
defining discipline is that **every restriction is built and proven in SIMULATION / audit mode first**
(Microsoft's built-in test mode that records what *would* have been restricted against real device
activity, with zero user impact), tuned for a low false-positive rate, and only then moved to enforcement.

> **Scope boundary.** This solution delivers the **technical method and evidence** for clipboard and
> screen-capture restriction on endpoints. *Which* data is regulated, *which* classifiers or labels legally
> apply, and *what* the enforced action must be for a given data category are **business, compliance,
> privacy, and legal determinations** — deferred to those functions. The solution configures and proves the
> control; it does not make the policy decision.

## Why this matters
- **Copy-paste and screenshots are the file controls' blind spot.** A document can be encrypted, un-shareable,
  and blocked from email, yet a user selects the text, copies it, and pastes it into a browser — or snips the
  screen — and none of the file-level controls ever see it. Endpoint DLP watches the *activity*, not just the
  file.
- **Endpoint DLP is licensing- and onboarding-dependent.** Clipboard and screen-capture restrictions require
  the right plan (typically **Microsoft 365 E5** / the **E5 Compliance** add-on) and devices **onboarded** to
  Purview (shared with Microsoft Defender for Endpoint onboarding). A Devices-location policy is inert until
  onboarding is complete — **verify your licensing/tenant**.
- **Screen-capture restriction and some clipboard behaviours are newer / may be in preview** and are gated on
  minimum OS builds and supported apps/browsers. This solution flags "verify your licensing/tenant" rather
  than asserting availability that may differ in your tenant.
- **Enforced-first is the classic failure.** Blocking clipboard/screenshot straight away breaks legitimate
  work — pasting between two sanctioned business apps, screenshotting a normal page — floods the help desk,
  and gets the policy disabled. Audit/simulation first, tuned, is the difference between a control that
  survives and one that is turned off.

## How it works
1. **Sensitive information types (SITs), classifiers, and sensitivity labels** define *what* content is
   sensitive. Endpoint DLP matches the content involved in a device activity against built-in SITs
   (credit card, national ID, health identifiers, etc.), **custom SITs**, **Exact Data Match (EDM)** SITs,
   **trainable classifiers**, or the presence of a **sensitivity label** on the item.
2. **A DLP policy scoped to the Devices (Endpoint) location** binds those detectors to **endpoint activities**
   under *"Audit or restrict activities on devices"*. The two this solution targets are **copy to clipboard**
   (paste into another app/browser) and **screen capture** (Print Screen / Snipping Tool / third-party
   capture of sensitive content). Each activity is set to **Audit**, **Block with override**, or **Block**.
3. **Simulation / audit mode** runs the policy against live device activity and records what *would* have been
   restricted — with or without policy tips shown — so you see the true volume and false positives **before**
   any enforcement. Every restriction in this solution starts here.
4. **Tuning** reduces false positives using confidence levels, instance thresholds, supporting keywords, EDM,
   label-based conditions, and **allowed-app / browser / network exceptions**, measured against the
   simulation results.
5. **Enforcement** turns the tuned restriction on (tip / allow-with-justification / block) in a limited ring,
   then expands.
6. **Incident/alert handling** — restricted clipboard/screen-capture activities raise **alerts** in the
   Purview portal and flow to **Activity Explorer**; this solution wires the triage, severity, and response
   workflow so matches are actually acted on.

## The two activities this solution controls (and what each stops)
- **Copy to clipboard →** copying sensitive content and pasting it into another application or a browser
  (personal webmail, chat, notes). Endpoint DLP can audit, warn-and-justify, or block the paste of classified
  content. Configure the **allowed apps / browsers** so sanctioned tools aren't caught alongside exfiltration.
- **Screen capture →** taking a screenshot (Print Screen, Windows Snipping Tool, or a supported third-party
  capture app) of sensitive content on screen. Endpoint DLP can audit or block the capture. **Availability
  and supported capture apps/OS builds vary — verify your licensing/tenant (this capability is newer / may be
  in preview).**

## A complementary lever: sensitivity-label protection (RMS usage rights)
Where content carries a **sensitivity label with encryption**, the label's **usage rights** independently
govern copy: removing the **EXTRACT ("Copy")** usage right from a permission set prevents copying content out
of protected Office files regardless of endpoint. This solution's primary path is **Endpoint DLP** (which
covers any content, labelled or not, and adds screen capture), but the label-usage-right lever is documented
here as a complementary control where labels are already in use — verify your labeling design with the
information-protection owner.

## The simulate→enforce journey (the core discipline)
> Confirm SITs/labels → build the Endpoint DLP policy with **clipboard + screen-capture** activities in
> **SIMULATION / audit** (no user impact) → measure volume and false positives in **Activity Explorer / DLP
> alerts** → **tune** (confidence, instance count, keywords, EDM, label condition, allowed-app/browser
> exceptions) → re-simulate until false positives are acceptable → enable with **policy tips +
> allow-override/justification** in a **pilot ring** → validate → expand to **enforce (block)** across the
> intended scope → operate (triage alerts, review overrides, re-tune).

## What you can control
- Which **SITs/classifiers/labels** trigger the restriction, and at what **confidence** and **instance count**.
- Which **endpoint activities** are covered — **clipboard**, **screen capture**, or both — and the **action**
  per activity (audit → tip → justify → block).
- Which **users / devices / groups** are **included or excluded**, and the **pilot ring** enforced first.
- The **allowed apps / browsers / network locations** so sanctioned workflows aren't caught.
- Whether users get **policy tips**, can **override** with justification, and what the override says.

## Limitations (be honest with buyers)
- **Endpoint DLP requires onboarded devices and the appropriate licensing** (verify your plan — endpoint DLP
  is gated behind E5 / the E5 Compliance add-on). A Devices-location policy is inert until onboarding is
  complete.
- **Screen-capture restriction and some clipboard behaviours are newer / may be in preview**, are limited to
  **supported apps/browsers and minimum OS builds**, and evolve — this solution flags "verify your
  licensing/tenant" rather than asserting availability.
- Endpoint DLP restricts content it can **classify** (SIT / label match). Content below the confidence/instance
  threshold, or that the device agent cannot classify at the moment of the activity, will not match. DLP is
  one control among several, not a guarantee — a determined user can still photograph a screen with a phone.
- The **enforced action for a data category is a compliance/legal decision**, not a technical default — this
  solution configures and proves the control; the determination is deferred.

## Naming convention (used in every doc and script)
Every artifact this solution creates uses `<Purpose> – <Scope> – <Stage>`, reused verbatim across the docs,
scripts, and the Purview portal. The standard set:

| Artifact | Name |
|---|---|
| Endpoint DLP policy (simulation) | `DLP – Endpoint Clipboard+Screen – Simulation` |
| Content rule on that policy | `DLP – Endpoint Clipboard+Screen – Rule` |
| Enforced pilot policy | `DLP – Endpoint Clipboard+Screen – Enforce Pilot` |
| Pilot user/device ring | `DLP Pilot Ring – Stage1` |
| Policy-tip / override text | `DLP Notice – Clipboard/Screen – Standard` |
| Incident/alert workflow | `DLP Alerts – Clipboard/Screen – Operations` |
| (Optional) label restricting copy | `Confidential – No-Copy – Endpoint` |

## The standard deployment model
> **Assess** current endpoint exposure and classification intent → **Design** the SIT/label detectors and the
> clipboard/screen-capture restriction → **Configure** the Endpoint DLP policy **in simulation/audit** →
> **Pilot** (simulate → tune → enforce to a ring) → **Validate** against pass/fail gates (clipboard/screenshot
> of sensitive content restricted, false-positive rate low, incidents handled) → **Expand** to the full scope
> and ongoing operations. Every high-impact change is piloted in simulation first, with a documented rollback.


---


# 2. Requirements — Clipboard & Screen-Capture Protection (Microsoft Purview)

These are the **solution-specific** prerequisites for configuring clipboard and screen-capture restrictions
for sensitive content on endpoints. They build on — and do not repeat — the six shared prerequisites in
**`global-requirements-purview.md`** (tenant + compliance licensing, least-privilege Purview roles, S&C
PowerShell + Graph toolchain, in-scope data sources, compliance/records/privacy/legal stakeholders, and a
pilot scope + change control). Verify each item below before starting the Implementation Guide.

For every requirement: **Description** (what it is), **Why required**, **How to verify**, **How to implement
if missing**.

---

## 2.1 Licensing sufficient for Endpoint DLP clipboard & screen-capture restrictions
- **Description:** Endpoint DLP activity restrictions — including **copy to clipboard** and **screen
  capture** — are **plan-gated**, typically **Microsoft 365 E5** or the **E5 Compliance** add-on. **Screen-
  capture restriction and some clipboard behaviours are newer and may be in preview** and gated on minimum
  OS builds. This extends GR-#1 with the capability-specific plan detail.
- **Why required:** A DLP policy scoped to the Devices location and using clipboard/screen-capture activities
  will not function without the required plan; the activities may not even be selectable.
- **How to verify:** In the **Microsoft 365 admin center** confirm the subscription/add-ons; in the
  **Purview portal → Data Loss Prevention** confirm the **Devices** location and, when authoring a rule, that
  **copy to clipboard** and **screen capture** appear under *"Audit or restrict activities on devices."*
  **Flag "verify your licensing/tenant"** — availability and preview status evolve.
- **How to implement if missing:** Acquire/assign the required licensing (E5 / E5 Compliance) before building
  the restriction; if screen capture is unavailable in your tenant, deliver clipboard restriction first and
  revisit screen capture when the capability is enabled.

## 2.2 DLP-specific least-privilege roles
- **Description:** The **DLP role groups** in the Purview portal — **Compliance Administrator** or
  **Compliance Data Administrator** to create/manage DLP policies, **DLP Compliance Management** for policy
  management, **View-Only DLP Compliance Management** for read-only review, and the **Data Loss Prevention**
  role for alert/incident handling. Global Administrator only where genuinely required. Extends GR-#2.
- **Why required:** Purview enforces fine-grained role groups; policy authoring and alert triage require the
  matching role, and least privilege keeps the blast radius small.
- **How to verify:** **Purview portal → Settings → Roles & scopes → Permissions** — confirm your account's
  role-group membership includes the DLP roles you need.
- **How to implement if missing:** Assign the least-privilege DLP role group under change control; separate
  policy authors from alert triagers where possible.

## 2.3 Devices onboarded to Purview (the hard gate for any endpoint restriction)
- **Description:** Endpoint DLP monitors activities on **onboarded Windows 10/11 and macOS devices**.
  Onboarding is done in **Purview portal → Settings → Device onboarding** (or via Intune / a script / Group
  Policy) and is **shared with Microsoft Defender for Endpoint onboarding** — devices already onboarded to
  Defender for Endpoint are onboarded for Endpoint DLP. Clipboard/screen-capture restriction additionally
  depends on **minimum OS builds** and **supported apps/browsers**.
- **Why required:** A policy scoped to the **Devices** location does nothing on a device that is not onboarded
  and reporting. Onboarding is the non-negotiable prerequisite for clipboard/screen-capture control.
- **How to verify:** **Purview portal → Settings → Device onboarding → Devices** shows onboarded devices;
  confirm target devices appear and are reporting. Confirm each device meets the minimum OS build documented
  by Microsoft for the clipboard/screen-capture activities. Script #3 (`DLPCLIP-EndpointReadiness.ps1`)
  surfaces the readiness signals.
- **How to implement if missing:** Onboard devices via the Purview device-onboarding package, Intune, or Group
  Policy; confirm the minimum OS build and any required AV/agent state per Microsoft docs before scoping the
  restriction.

## 2.4 A classification intent — the SITs, classifiers, or labels that mark "sensitive"
- **Description:** A documented view of **which content must not be copied/screenshotted** (e.g. payment card
  data, national IDs, health identifiers, source code, or any item carrying a specific **sensitivity label**)
  mapped to the **detector** that identifies it — built-in SITs where they fit, **custom SITs / EDM / trainable
  classifiers** for gaps, and/or a **sensitivity-label condition**. Extends GR-#4.
- **Why required:** The restriction keys off *what* is sensitive; a clipboard/screen-capture rule with no
  precise detector either catches nothing or catches everything (false-positive flood).
- **How to verify:** **Purview portal → Data classification → Classifiers → Sensitive info types** lists
  built-in and custom SITs; **Information protection → Labels** lists sensitivity labels. Confirm the ones you
  need exist (or are planned) with the data owners.
- **How to implement if missing:** Build the SIT/label inventory (this solution's Discovery script assesses
  built-in SIT coverage and any existing endpoint restrictions); plan custom SITs / EDM / a label condition
  for categories not covered.

## 2.5 Allowed-app, browser, and network-exception intent
- **Description:** The list of **sanctioned applications, browsers, and network locations** where copying and
  screen capture of sensitive content is legitimate business (e.g. two internal line-of-business apps, an
  approved browser for the corporate SaaS suite). Endpoint DLP evaluates activities against **allowed / unallowed
  apps and browsers** and **service-domain / network** lists.
- **Why required:** Without allowed-app/browser exceptions, the restriction catches legitimate internal
  copy-paste and screenshots alongside real exfiltration, driving false positives and killing adoption.
- **How to verify:** **Purview portal → Data loss prevention → Endpoint DLP settings** shows the
  unallowed/restricted apps and browsers, service-domain, and network lists; confirm the sanctioned tools are
  represented before authoring the rule.
- **How to implement if missing:** Capture the sanctioned app/browser/network list from IT and the business,
  and configure the Endpoint DLP settings lists before enforcing.

## 2.6 A pilot ring, simulation dwell time, and change control (endpoint-specific)
- **Description:** A named **pilot user/device ring**, an agreed **simulation/audit dwell time** (how long the
  policy runs in audit before enforcement — long enough to capture representative device activity), and the
  **change-control window** for moving audit → enforce. Extends GR-#6.
- **Why required:** Clipboard/screen-capture blocking is high-impact and highly visible to users; enforcing
  without an audit baseline and a limited ring is how the control breaks day-to-day work. The house model
  mandates **simulation/audit first**, then a ring, then expand.
- **How to verify:** Confirm the pilot ring membership, that the policy is created in **simulation/audit
  mode**, and the approval path to enforce.
- **How to implement if missing:** Define the ring and dwell time and agree change control before enabling any
  block action.

## 2.7 An incident/alert triage owner and destination
- **Description:** A named owner (or queue) for **DLP alerts** raised in **Purview portal → Data loss
  prevention → Alerts**, plus where restricted-activity events are reviewed (**Activity Explorer**) and,
  optionally, where they are forwarded (SIEM / Microsoft Sentinel via the Office 365 Management Activity API /
  Defender connectors). Severity and response actions defined.
- **Why required:** A restricted clipboard/screen-capture event with no one to triage it is not a control.
  Alerts and Activity Explorer are where matches surface; someone must own triage, severity, and response.
- **How to verify:** Confirm the triage owner/queue (`DLP Alerts – Clipboard/Screen – Operations`), the
  alert-severity scheme, and any SIEM forwarding is configured.
- **How to implement if missing:** Assign the owner, define severity/response, and (optionally) wire SIEM
  forwarding before enforcement generates real alerts.

---

### Requirements summary

| # | Requirement | Gate |
|---|---|---|
| GR 1–6 | Category prerequisites (`global-requirements-purview.md`) | Tenant/licensing, roles, toolchain, scope, stakeholders, pilot + change control |
| 2.1 | Endpoint DLP clipboard/screen-capture licensing (E5 / E5 Compliance; verify, some preview) | Activities available/selectable |
| 2.2 | DLP least-privilege roles | Author + triage roles assigned |
| 2.3 | Devices onboarded to Purview (+ min OS build) | Endpoint location & activities functional |
| 2.4 | Classification intent — SITs / classifiers / labels | Restriction keys off the correct detector |
| 2.5 | Allowed-app / browser / network exceptions | Sanctioned workflows not caught |
| 2.6 | Pilot ring + simulation dwell + change control | Simulate/audit-first enforced |
| 2.7 | Alert/incident triage owner + destination | Restricted activities are acted on |

> **Deferred to compliance/privacy/legal:** which data categories are in scope, which classifiers/labels
> legally apply, the enforced action per category, and any regulatory applicability. This solution provides
> the technical configuration and evidence, not the determination.


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


# 3. Implementation Guide — Clipboard & Screen-Capture Protection (Microsoft Purview)

This is the exact, ordered procedure to configure **clipboard** and **screen-capture** restrictions for
sensitive content on **onboarded endpoints** — built in **SIMULATION / audit** mode first, tuned, then
enforced in a ring, then expanded. Portal paths and cmdlets are from Microsoft's public documentation;
**licensing-/plan-dependent features and evolving/preview portal paths are flagged "verify your
licensing/tenant"** and are never asserted for your tenant. Do the phases in order. Each phase names its
artifacts (from the Overview naming table), states a **pass/fail gate**, and gives a **rollback**.

> **Automation.** The five delivered PowerShell tools run through **Security & Compliance PowerShell**
> (`Connect-IPPSSession`) and **Microsoft Graph**. They are **read-only or `-WhatIf` by default**; writes
> require an explicit `-Commit` switch, and the config helper is **simulation-only** — it never leaves a
> policy in enforce. No credentials are stored in code.

> **Determinations deferred.** *Which* content categories are in scope, *which* classifiers/labels legally
> apply, and the *enforced action* per category are **compliance/privacy/legal** decisions. This guide
> configures and proves the control; capture those decisions before Phase 4.

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
   .\DLPCLIP-Discovery.ps1 -CsvPath .\DLPCLIP-Posture.csv
   ```
   It reports existing DLP policies and their mode, which ones scope the **Devices/Endpoint** location, any
   **clipboard/screen-capture** restrictions already configured on their rules, and built-in vs custom SIT
   coverage.
3. **Confirm licensing and endpoint readiness** (Req 2.1, 2.3): confirm E5 / E5 Compliance, that target
   devices are **onboarded** and meet the **minimum OS build**, and that the **copy to clipboard** and
   **screen capture** activities are selectable in a rule (script #3 surfaces the readiness signals). If
   screen capture is not available in your tenant, note it and deliver clipboard first.

**Pass/fail gate:** you have a written baseline (existing policies + modes + any endpoint restrictions), a SIT/label
coverage map, and confirmed licensing + onboarding for the Devices location.
**Rollback:** none (read-only).

---

## Phase 1 — Design the classification layer (what counts as "sensitive")

Decide which detector marks content that must not be copied/screenshotted. Do **not** invent SITs — use
built-in where they fit; build custom/EDM/trainable only for gaps; use a **sensitivity-label condition**
where content is already labelled.

4. **Map built-in SITs first.** In **Purview portal → Data classification → Classifiers → Sensitive info
   types**, confirm the built-in SITs for your categories (e.g. *Credit Card Number*, *U.S. Social Security
   Number (SSN)*, national-ID / health-identifier SITs). Note each SIT's **confidence levels** and default
   **instance count**.
5. **Author custom SITs for gaps.** For a category with no built-in match (e.g. an internal case or record
   number), create a custom SIT with a **regex primary pattern**, **supporting keywords**, a **confidence
   level**, and a **character proximity**. Portal: **Classifiers → Sensitive info types → Create sensitive
   info type**. Test it against sample text in the wizard's **Test** step.
6. **Use a sensitivity-label condition where content is labelled.** If the organization already applies a
   label such as *Confidential*, the rule can trigger on **"content contains → Sensitivity labels"** instead
   of (or in addition to) SITs — a precise, low-false-positive signal. Confirm the labels exist with the
   information-protection owner.
7. **(Optional) EDM / trainable classifiers** for categories where pattern SITs over-match or the category is
   conceptual. Verify availability against your plan; *which fields are in scope is the data owner's
   determination.*

**Pass/fail gate:** every in-scope "do not copy/screenshot" category maps to a named, tested detector
(built-in SIT, custom SIT, EDM, trainable classifier, or sensitivity label) at a chosen confidence/instance
count.
**Rollback:** delete unused custom SITs (they have no effect until referenced by a policy).

---

## Phase 2 — Configure the endpoint restriction in SIMULATION (Configure — no user impact)

Create **one Endpoint DLP policy** with a rule that covers the **clipboard** and **screen-capture**
activities, in **simulation / audit** mode. Simulation/audit records what *would* be restricted against real
device activity, with **no** enforcement and (optionally) with policy tips shown.

8. **Set the Endpoint DLP settings first** (Req 2.5). Portal: **Data loss prevention → Endpoint DLP settings**
   → configure the **unallowed / restricted apps and browsers**, **service-domain**, and **network** lists so
   your **sanctioned** apps/browsers are represented (either as allowed, or clearly out of the unallowed
   list). This is what keeps legitimate internal copy-paste and screenshots from being caught.
9. **Create the policy — `DLP – Endpoint Clipboard+Screen – Simulation`.**
   Portal: **Data loss prevention → Policies → Create policy** → custom (or a category template) →
   **Locations: Devices only** (all other locations off for this solution). Confirm the Devices location is
   selectable; if not, revisit licensing/onboarding (Req 2.1/2.3).
10. **Author the rule — `DLP – Endpoint Clipboard+Screen – Rule`.**
    - **Condition:** *Content contains* → the SITs from Phase 1 at the chosen confidence/instance count, and/or
      *Sensitivity labels* from Phase 1.
    - **Actions → "Audit or restrict activities on devices":** set **Copy to clipboard** and **Screen capture**
      (labelled per your tenant's current portal) to **Audit** (the simulation-phase action). Leave the other
      endpoint activities (USB, print, network share, etc.) untouched — they are out of scope for this
      solution.
    - **User experience:** define `DLP Notice – Clipboard/Screen – Standard` policy-tip text and enable
      **allow override with justification** where compliance permits — note tips/overrides only *appear* once
      the policy is enforced; in audit they are captured, not shown, unless "simulation with policy tips" is
      selected.
11. **Set the policy mode to simulation.** Choose **"Run the policy in simulation mode"** (optionally *with
    policy tips*). Finish. In S&C PowerShell this corresponds to `Mode = TestWithNotifications` /
    `TestWithoutNotifications`.
12. **Verify with the config helper** (delivered script #2, `-WhatIf` by default):
    ```powershell
    .\DLPCLIP-Config.ps1 -PolicyName 'DLP - Endpoint Clipboard+Screen - Simulation' `
        -SensitiveTypes 'Credit Card Number' -MinCount 1 -Confidence High -WhatIf
    ```
    The helper previews the `New-DlpCompliancePolicy` / `New-DlpComplianceRule` calls (Devices location,
    simulation mode, clipboard+screen-capture restrictions). Because the exact **endpoint-restriction setting
    names evolve/preview**, the recommended pattern is: build the rule **once in the portal**, then read its
    restriction property with script #1 to confirm the exact names before ever committing with the helper.
    Run with `-Commit` only to apply an intended change; the helper never leaves a policy in enforce mode.

**Pass/fail gate:** the policy exists, is scoped to **Devices only**, covers **clipboard + screen-capture**,
and is confirmed in **simulation** (script #1/#2 report a `Test*` mode).
**Rollback:** delete the simulation policy — simulation has no user impact, so removal is clean.

---

## Phase 3 — Measure and tune (drive false positives down)

Let the policy run in simulation for the agreed **dwell time** (Req 2.6) to capture representative device
activity.

13. **Review what would have been restricted.** **Purview portal → Data loss prevention → Alerts**
    (simulation alerts) and **Data classification → Activity explorer** (filter to endpoint DLP activities —
    *copy to clipboard*, *screen capture*) show every simulated match with the app/browser, the SIT/label, and
    the confidence. Export with the reporting script:
    ```powershell
    .\DLPCLIP-Report.ps1 -Days 14 -CsvPath .\DLPCLIP-Activity.csv
    ```
14. **Classify each match** as true positive or **false positive** and identify the false-positive drivers
    (e.g. legitimate copy-paste between two sanctioned internal apps, a screenshot of a normal page that
    happens to contain a low-confidence pattern).
15. **Tune** to reduce false positives without losing true positives:
    - Raise the **confidence level** (e.g. medium → high) and/or the **instance count** so incidental matches
      don't fire.
    - Prefer a **sensitivity-label condition** over broad SITs where content is labelled — far fewer false
      positives.
    - Add **allowed-app / browser / network exceptions** (Endpoint DLP settings) so sanctioned tools aren't
      caught.
    - Introduce **EDM** for categories where pattern SITs over-match.
    - Add **supporting keywords / proximity** to custom SITs so context is required.
16. **Re-simulate** after each tuning change and re-measure. Repeat until the false-positive rate meets the
    validation gate (see Testing).

**Pass/fail gate:** measured false-positive rate is at/under the agreed threshold on the simulation sample,
with true positives (sensitive-content copy/screenshot) still detected.
**Rollback:** revert the last tuning change (script #2 `-WhatIf` shows the diff before `-Commit`).

---

## Phase 4 — Enforce in a pilot ring (Pilot)

17. **Scope to the pilot ring.** Set `DLP Pilot Ring – Stage1` (users) and the pilot devices as the
    **included** scope on the policy (all other users/devices excluded for now):
    ```powershell
    .\DLPCLIP-Set-Scope.ps1 -PolicyName 'DLP - Endpoint Clipboard+Screen - Simulation' `
        -IncludeGroup 'DLP Pilot Ring - Stage1' -WhatIf
    ```
18. **Move the ring to enforcement.** Change **Policy mode** from *simulation* to **Turn it on / Enforce**.
    Start the clipboard and screen-capture activities at **Block with override (justification)** rather than
    hard block, so the pilot can report false negatives/positives while retaining a business escape hatch.
    (Rename to `DLP – Endpoint Clipboard+Screen – Enforce Pilot` if your change process tracks the transition.)
19. **Confirm enforcement is live** for the ring only (script #1 reports mode `Enable` and the scoped
    identities). On a ring device, confirm a test copy/screenshot of clearly-fake sensitive content now shows
    the `DLP Notice – Clipboard/Screen – Standard` tip and requires justification.
20. **Handle incidents.** Wire `DLP Alerts – Clipboard/Screen – Operations`: assign the alert owner/queue
    (Req 2.7), set severities, and (optionally) forward to SIEM/Sentinel. Triage a real pilot alert end-to-end
    to prove the workflow.

**Pass/fail gate:** the pilot ring is enforced (clipboard/screenshot of sensitive content restricted, tips
shown, overrides captured), matches raise alerts, and the triage workflow produces a dispositioned incident.
No enforcement outside the ring.
**Rollback:** set the policy back to **simulation mode** (single setting) — instantly removes enforcement with
no data change.

---

## Phase 5 — Expand and harden (Enforce → Operate)

21. **Expand scope** from the ring to the full intended population once the pilot gate passes, keeping
    documented exclusions.
22. **Escalate the action** per compliance's determination — e.g. move clipboard/screen-capture from *block
    with override* to **hard block** where required — one activity at a time, re-validating after each.
23. **Operationalize:** schedule the reporting script for a recurring false-positive/alert review, review
    **user overrides** (are people justifying legitimately or bypassing?), refresh **EDM** data on cadence
    (if used), and re-tune the allowed-app/browser lists as tools change.
24. **Validate end-to-end** with the delivered testing procedure (next section) and record the pass/fail
    evidence.

**Pass/fail gate:** enforcement live across the intended scope with the compliance-mandated action for
clipboard and screen capture; false-positive rate steady/low; alerts triaged on cadence; overrides reviewed.
**Rollback:** the policy can be returned to **simulation** at any time as an immediate, non-destructive safety
switch; the clipboard and screen-capture activities can be relaxed independently.

---

## Order-of-operations summary

| Phase | Do | Artifact(s) | Gate | Rollback |
|---|---|---|---|---|
| 0 Assess | Connect, baseline, confirm licensing/onboarding | Posture CSV | Baseline + readiness confirmed | n/a (read-only) |
| 1 Design | Map/build SITs / label condition | Custom SIT / label condition | Every category → tested detector | Delete unused SIT |
| 2 Configure | Build the Devices policy (clipboard+screen) **in simulation** | `…– Simulation` policy + rule | Simulation, Devices-only, both activities | Delete sim policy |
| 3 Tune | Measure + reduce false positives | Activity CSV | FP rate ≤ threshold | Revert tuning change |
| 4 Pilot | Enforce to ring, wire alerts | Pilot ring, alert triage | Ring enforced, incident dispositioned | Back to simulation |
| 5 Expand | Broaden scope, escalate to block, operate | Enforced policy | Full-scope enforce, low FP, alerts triaged | Simulation / relax activity |


---


# 5. Testing & Validation — Clipboard & Screen-Capture Protection (Microsoft Purview)

Validate the Endpoint DLP implementation against explicit **pass/fail gates**. The three headline gates are:
**(A) clipboard/screen-capture of sensitive content is restricted**, **(B) the false-positive rate is low**,
and **(C) incidents are handled and evidenced**. Run every test with **non-real, clearly-fake sample
content** — a test document containing a **fake SIT match** (e.g. the Microsoft test credit-card number
`4111 1111 1111 1111`) and/or carrying the optional **`Confidential – No-Copy – Endpoint`** sensitivity
label — **never** real sensitive data. Record the evidence; it supports the control narrative (whether the
control is *required* and the *enforced action* per category stays a **compliance/privacy/legal**
determination).

> All tests assume the policy from the Implementation Guide, first proven in **simulation** as
> **`DLP – Endpoint Clipboard+Screen – Simulation`** (rule **`DLP – Endpoint Clipboard+Screen – Rule`**) and
> then enforced to the **`DLP Pilot Ring – Stage1`** as **`DLP – Endpoint Clipboard+Screen – Enforce Pilot`**.
> Every endpoint test requires an **onboarded** device (Req 2.3) that meets the minimum OS build. **Screen-
> capture restriction is newer / may be in preview and is OS-/app-gated — verify your licensing/tenant**; if
> it is not available, run the clipboard tests and mark the screen-capture rows *"verify in tenant."**

---

## Test A — Detection & enforcement (clipboard/screen-capture of sensitive content is restricted)

| # | Test | Steps | Pass condition |
|---|---|---|---|
| A1 | Clipboard → unallowed browser/app | On an onboarded ring device, open the fake sensitive test file, **copy** matching content, and **paste** it into an **unallowed** browser or app (e.g. a personal webmail tab). | The paste is audited (simulation) or blocked/tipped (enforce) per the action; the `DLP Notice – Clipboard/Screen – Standard` tip appears when enforced; an endpoint DLP event is logged. |
| A2 | Screen capture of sensitive content | With the fake sensitive file on screen, take a **screenshot** (Print Screen / Snipping Tool / a supported capture app). | The capture is audited or blocked per the action; event logged. **If screen capture is unavailable in your tenant, record "verify in tenant" and skip.** |
| A3 | Label-based match (optional) | Apply the **`Confidential – No-Copy – Endpoint`** label to a fake file, then repeat A1/A2. | The rule fires on the **sensitivity-label** condition (not just the SIT) — confirms the label signal works and is more precise. |
| A4 | Allowed-app / sanctioned workflow negative | **Copy-paste** the same content **between two sanctioned internal apps** (on the Endpoint DLP **allowed** list) and screenshot a normal, non-sensitive page. | Sanctioned copy-paste and non-sensitive screenshots are correctly **not** restricted — confirms the allowed-app/browser exceptions and conditions hold. |
| A5 | Below-threshold negative | Copy content that is **below** the configured confidence/instance count (e.g. a single low-confidence fragment). | Correctly **not** matched — confirms the confidence/instance tuning is doing its job. |

**Gate A (pass):** A1–A3 each produce the configured action and a logged endpoint event; A4–A5 correctly do
not fire.

---

## Test B — False-positive rate (adoption gate)

| # | Test | Steps | Pass condition |
|---|---|---|---|
| B1 | Simulation FP baseline | Over the agreed dwell time, export simulation matches (`DLPCLIP-Report.ps1 -Days <n>`) and classify each clipboard/screen-capture match as TP/FP. | **False-positive rate ≤ the agreed threshold** (define with compliance; label-keyed matching should be very precise, so target a low absolute FP count the triage team can absorb). |
| B2 | "Mentions but isn't" negative | Run legitimate content that merely resembles a pattern (e.g. a training doc that contains a formatted-but-invalid number) through a normal copy. | Not matched — confirms confidence/instance count and (where used) keyword proximity carry the weight. |
| B3 | Post-tuning re-measure | After each tuning change (raise confidence/instance, add label condition, add allowed-app/browser exception, add EDM), re-simulate and re-measure. | FP rate trends **down** while true positives (Test A) still fire. |
| B4 | Override sanity | In the pilot ring, review captured **allow-with-justification** overrides on clipboard/screen-capture. | Overrides are legitimate business justifications, not routine bypass — if routine, re-tune or re-scope. |

**Gate B (pass):** measured FP rate at/under threshold on the simulation sample with true positives intact.

---

## Test C — Incident / alert handling & evidence (the control is operable and auditable)

| # | Test | Steps | Pass condition |
|---|---|---|---|
| C1 | Alert raised | Trigger a match (Test A1/A2). | A DLP **alert** appears in **Purview → Data loss prevention → Alerts** with the correct policy, severity, and evidence. |
| C2 | Triage workflow | The `DLP Alerts – Clipboard/Screen – Operations` owner/queue picks up the alert, sets status, and dispositions it. | Alert moves through the defined states to a resolved disposition by the named owner. |
| C3 | Activity Explorer evidence trail | Locate the same event in **Data classification → Activity explorer** (filter to *copy to clipboard* / *screen capture*) and **export** it. | Full evidence trail present (user, device, app/browser, label/SIT, action) and retained for audit. |
| C4 | SIEM forwarding (if configured) | Confirm the endpoint DLP event reaches the SIEM/Sentinel destination (Req 2.7). | Event present in the downstream system with usable fields. |

**Gate C (pass):** matches raise alerts, alerts are triaged to disposition by the owner, and the retained
evidence trail (and SIEM forward, if used) is present.

---

## Simulation-first & rollback validation

| # | Test | Pass condition |
|---|---|---|
| S1 | Nothing enforced outside the ring | Users/devices **outside** `DLP Pilot Ring – Stage1` experience no clipboard/screen-capture blocking during pilot. |
| S2 | Instant rollback | Setting the enforced policy back to **simulation mode** immediately removes enforcement with no data change (verify a previously-blocked copy/screenshot now only simulates). |
| S3 | Scripts are safe-by-default | `DLPCLIP-Config.ps1` / `DLPCLIP-Set-Scope.ps1` run **without** `-Commit` make no change (`-WhatIf` output only); discovery/validate/report scripts are read-only. |

---

## Evidence to capture (for the deliverable record & control narrative)
- Baseline posture CSV (Phase 0), the endpoint-readiness output, and the SIT/label coverage map.
- Simulation match export + TP/FP classification and the computed **false-positive rate** before/after
  tuning (Gate B).
- Screenshots/log of Test A enforcement actions (clipboard **and** screen capture, and the optional
  label-based match) and the raised alerts (Gate A/C).
- The dispositioned, retained incident from Test C2/C3 and, if used, the SIEM forward (C4).
- Confirmation that outside-ring users were unaffected (S1) and that simulation rollback works (S2).

> **Determination boundary.** These tests prove the **control works** and produce the **evidence**. Whether
> the control is *required* for a given data category, the **acceptable false-positive threshold**, and the
> **enforced action** (audit vs block-with-override vs hard block) per category are **compliance / privacy /
> legal** sign-offs, captured alongside the evidence above.


---


# Troubleshooting — Clipboard & Screen-Capture Protection (Microsoft Purview)

The failures you will actually hit, with the most likely cause and the fix. Work top-down: **most "the
restriction isn't working" reports trace back to onboarding, screen-capture availability, condition
matching, allowed-app coverage, or simulation-vs-enforce confusion — not the rule itself.** Where a portal
path or cmdlet parameter is named, **verify it against your tenant** — the Purview portal and the endpoint
restriction options evolve, and **screen-capture restriction is newer / may be in preview**.

---

## 1. A device shows no clipboard/screen-capture activity at all

**Symptoms:** Copy or screenshot a matching file on a device and **nothing** appears in Activity explorer
(Devices); the policy never fires.

**Likely causes & fixes**
- **Device isn't onboarded.** The #1 cause. Confirm the device appears under **Purview → Settings → Device
  onboarding → Devices**. If not, re-run your onboarding method (Intune/GPO/local script/ConfigMgr). There
  is **no** S&C PowerShell cmdlet to onboard — it is a portal/management-tool action.
- **Unsupported / unpatched OS build.** Clipboard and screen-capture sensing need a supported minimum
  Windows/macOS build and a current agent. Patch and retest.
- **Onboarding still propagating.** After onboarding, allow time for the device to register and for activity
  to surface — endpoint telemetry is **not** instant. Wait and retry.
- **Check the readiness signals:** `DLPCLIP-ScopeHealth.ps1` reports managed-device counts (Graph) and
  Endpoint-DLP-settings readability — but remember the device count is a **proxy**; the authoritative check
  is the **Devices** list in the portal.

---

## 2. Clipboard is caught, but screen capture is not (or the activity isn't selectable)

**Symptoms:** Copy-to-clipboard is audited/blocked, but a screenshot of the same content does nothing — or
**screen capture** isn't even offered when you author the rule.

**Fix**
- **Screen-capture restriction is newer / may be in preview**, gated on licensing, supported apps/browsers,
  and minimum OS builds. **Verify your licensing/tenant** — if it is unavailable, **deliver clipboard
  restriction first** and revisit screen capture when the capability is enabled. `DLPCLIP-Validate.ps1`
  marks the screen-capture check **VERIFY** (not FAIL) when it can't read the restriction.
- Confirm target devices meet the **minimum OS build** documented by Microsoft for the screen-capture
  activity, and that the capture tool in use is a **supported** one.
- Do **not** treat a missing screen-capture activity as a bug in the policy — it is a capability/availability
  question. Flag it, don't force it.

---

## 3. The restriction fires on the wrong things (false positives)

**Symptoms:** Legitimate work is flagged/blocked — copy-paste between two sanctioned internal apps, or a
screenshot of a normal page.

**Likely causes & fixes**
- **Allowed apps/browsers not configured (or stale).** Add the sanctioned apps/browsers to the **Endpoint
  DLP settings** (Data loss prevention → Endpoint DLP settings) so they aren't caught alongside real
  exfiltration. A missing exception is the most common false-positive driver on endpoints.
- **Condition too broad.** If the rule keys on "all content" instead of a **sensitivity label / SIT**, it
  matches everything. Tighten the condition — prefer a **sensitivity-label condition** where content is
  labelled. `DLPCLIP-Validate.ps1` gate **A6** flags a rule with no readable content condition.
- **SIT confidence/count too loose.** Raise the confidence level or instance count on the sensitive
  information type to cut noise, then re-test.
- Tune **in simulation** — never tune by loosening an already-enforcing block in production. Re-measure with
  `DLPCLIP-Report.ps1` after each change (Gate B in `05-testing.md`).

---

## 4. The restriction doesn't fire on content it should

**Symptoms:** A file you expect to match is copied/screenshotted with no policy match.

**Likely causes & fixes**
- **Content doesn't carry the label/SIT.** The test file must actually carry the **sensitivity label** or
  contain the **sensitive information type** the rule keys on. Confirm the label is applied / the SIT pattern
  is present (seed a known match, e.g. the Microsoft test credit-card number `4111 1111 1111 1111`).
- **Label not published / SIT not in scope.** Confirm the label is published to the user (Information
  Protection → Label policies) and the SIT exists (Data classification). `DLPCLIP-Discovery.ps1` inventories
  both and flags rules that carry a clipboard/screen-capture restriction.
- **Rule disabled.** `DLPCLIP-Validate.ps1` gate **A5a** flags a disabled rule.
- **Below-threshold content.** A single low-confidence fragment below the configured confidence/instance
  count will correctly not match — that is tuning, not a fault.

---

## 5. Simulation looks fine but enforcement doesn't block

**Symptoms:** In simulation the copy/screenshot is recorded; after "turning it on" the block/warn still
doesn't happen.

**Likely causes & fixes**
- **Policy still in a Test mode.** Simulation records but does **not** block. To enforce, move the policy out
  of simulation: portal → turn the policy **On**; PowerShell →
  `Set-DlpCompliancePolicy -Identity 'DLP - Endpoint Clipboard+Screen - Simulation' -Mode Enable`.
  `DLPCLIP-Validate.ps1` gate **A3** shows the current mode.
- **Restriction action still Audit.** The rule's clipboard/screen-capture restriction may be **Audit** even
  though the policy is enforcing. Set the per-activity action to **Block with override** / **Block** per the
  compliance determination.
- **Device out of scope.** Enforcement only applies to devices in the policy's Devices scope. Confirm with
  `DLPCLIP-ScopeHealth.ps1` / gate **A4** — during pilot, scope is `DLP Pilot Ring - Stage1`, not `All`.
- **Propagation delay.** Policy/action changes take time to reach endpoints. Wait, then retest.

---

## 6. `New-DlpComplianceRule` fails on the clipboard/screen-capture restriction

**Symptoms:** `DLPCLIP-Configure.ps1 -Commit` (or manual scripting) errors when setting the endpoint
restriction, e.g. an invalid Setting name or value.

**Fix**
- **Verify the exact Setting names and values for your tenant.** The endpoint-restriction Setting names
  (copy to clipboard, screen capture) and permitted values (`Audit` / `Block` / `BlockWithOverride` /
  `Ignore`) **evolve**, and **screen capture may be preview**. Run `Get-Help New-DlpComplianceRule -Full`
  and check current Microsoft docs, then adjust the hashtable. `DLPCLIP-Configure.ps1` deliberately
  **prints the planned Setting names** so you can verify before `-Commit`.
- **Prefer the portal for the first build** if the PowerShell parameter names are uncertain, then read the
  result back with `DLPCLIP-Discovery.ps1` to learn the exact shape in your tenant before committing.

---

## 7. `-EndpointDlpLocation` / scope errors

**Symptoms:** Creating the policy errors on the location/scope value.

**Fix**
- The **Devices** location is scoped by user/group (or `All`). Confirm the pilot group
  (`DLP Pilot Ring - Stage1`) exists and the identifier is one your tenant accepts.
  `DLPCLIP-ScopeHealth.ps1` reports the group and the current scope.
- Avoid `All` during the pilot — scope to the pilot ring first (gate **A4**).

---

## 8. Activity report is empty or export fails

**Symptoms:** `DLPCLIP-Report.ps1` returns no clipboard/screen-capture rows, or the Activity Explorer export
warns and skips.

**Likely causes & fixes**
- **Licensing/permission.** `Export-ActivityExplorerData` is licensing-dependent; the script **warns and
  degrades to policy-modes only** rather than failing. Fall back to **Purview → Activity explorer** (filter
  to *copy to clipboard* / *screen capture*) and **DLP → Alerts** in the portal.
- **Field naming differs.** The script keeps rows whose serialized event mentions a clipboard/screen-capture
  token; if the tenant names fields differently, rows may be returned but not matched — check the portal
  filter directly.
- **Quiet pilot window.** A small pilot may simply have no activity — widen `-Days` or perform the sanctioned
  test actions from `05-testing.md` first.
- **Role.** Ensure the connected account holds a role that can read Activity Explorer.

---

## 9. "It blocked an admin / broke a workflow" — emergency rollback

**Do this immediately, then diagnose:**
- Return the policy to **simulation** or **off**:
  `Set-DlpCompliancePolicy -Identity 'DLP - Endpoint Clipboard+Screen - Simulation' -Mode TestWithoutNotifications`
  (simulation) or `-Mode Disable` (off). Either **stops enforcement at once**, with no data change.
- Or set the offending **restriction action back to Audit** for the clipboard/screen-capture activity.
- Then work the relevant section above (usually §3 false positives or §5 scope), fix **in simulation**,
  re-validate with `DLPCLIP-Validate.ps1`, and only then re-enforce.

---

## When to escalate to the determination owners (not a technical fix)

Some questions are **not** troubleshooting — they are **determinations** that belong to compliance /
security / records / HR-legal (see `global-requirements-purview.md` §5):

- *Should* copy/screenshot of this content be **blocked** or only **audited**? → the **compliance** owners.
- Is *this content* actually sensitive / in scope? → **compliance / data owners**.
- Is a user's copy/screenshot a **violation**, and what is the consequence? → **HR / legal**.

Provide them the **evidence** (`DLPCLIP-Report.ps1`, Activity explorer, the `DLPCLIP-Validate.ps1` output) —
not a verdict. And stay honest about the boundary: Endpoint DLP restricts content it can **classify** at the
moment of the activity — a determined user can still **photograph a screen with a phone**. It is one
supporting control, not a guarantee.


---


# 7. Best Practices — Clipboard & Screen-Capture Protection (Microsoft Purview)

Field-tested practices for running clipboard and screen-capture Endpoint DLP so the control stays trusted,
effective, low-noise, and **defensible**. These complement the Implementation and Testing guides.

## Simulate before you enforce — always
- **Never** switch a new or materially changed endpoint restriction straight to block. Build
  **`DLP – Endpoint Clipboard+Screen – Simulation`** in **simulation / audit** first, long enough to capture
  representative device activity (Req 2.6), and read the results before enabling.
- Use **simulation with policy tips** on the pilot ring when you want end-user feedback before hard block.
- Treat **simulation mode as your permanent safety switch**: the enforced policy returns to simulation in one
  setting, instantly removing enforcement with no data change — this is your rollback.

## Onboarding is the gate (endpoint-specific)
- A **Devices-location policy is inert until the device is onboarded** (shared with Microsoft Defender for
  Endpoint) and reporting — verify onboarding and the **minimum OS build** before blaming the policy.
- **Screen-capture restriction is newer / may be in preview**, is limited to **supported apps/browsers and
  minimum OS builds**, and evolves — **verify your licensing/tenant** and deliver **clipboard first** if
  screen capture is not yet available. Flag, don't assume.
- Roll the two activities out **audit-first**: audit **copy to clipboard** and **screen capture** of
  sensitive content before restricting, so you see real usage and avoid blocking legitimate work.

## Label first, patterns second
- Where content is already labelled, key the rule on a **sensitivity-label condition** (optionally the
  **`Confidential – No-Copy – Endpoint`** label) as the primary, precise signal — it follows the marking
  decision a human or auto-labeling policy already made and produces far fewer false positives than broad SITs.
- Use **SITs at a chosen confidence and instance count** for unlabelled content; introduce **custom SITs /
  EDM / trainable classifiers** only for real gaps, and **never invent a SIT pattern** — build custom SITs
  from patterns the data owner supplies and test them in the SIT wizard's **Test** step.
- Getting the label/classifier right feeds the whole information-protection program — invest there, not in
  ever-more-complex regex.

## Right-size the allowed-app / browser / network exceptions
- **Mind allowed vs unallowed apps/browsers and network exceptions** so sanctioned copy-paste (e.g. between
  two internal line-of-business apps) and legitimate screenshots aren't caught alongside real exfiltration.
- Capture the sanctioned app/browser/network list from IT **and** the business before enforcing; re-tune it
  as tools change. A missing exception is the most common false-positive driver on endpoints.

## Tune for a low false-positive rate (adoption depends on it)
- Most false positives come from **broad SITs over-firing** — fix with **higher confidence/instance count**,
  a **label condition**, allowed-app/browser exceptions, or EDM, measured against the simulation results.
- Every false positive that reaches a user erodes trust in **every** policy tip. Budget for a tuning cycle,
  not a one-time build. Re-simulate after each change.

## Right-size the user experience
- Show **clear, actionable policy tips** in plain language — reuse one standard notice
  (**`DLP Notice – Clipboard/Screen – Standard`**) that tells the user the content is sensitive and what they
  may/may not do, not a compliance error code.
- Prefer **allow-with-justification / override** over hard block where legitimate exceptions exist, then
  **review the overrides** — routine overriding means the policy is mis-scoped. Reserve **hard block** for the
  categories where compliance requires it, escalating **one activity at a time**.

## Scope tightly, then expand
- Enforce first to the **`DLP Pilot Ring – Stage1`** (users **and** devices), keeping everyone else excluded,
  then expand once the pilot gate passes — this cuts false positives, shrinks blast radius, and keeps the
  control narrative clean.

## Evidence & operations (this is what a reviewer asks for)
- Give clipboard/screen-capture **alerts an owner and an SLA** via
  **`DLP Alerts – Clipboard/Screen – Operations`** (Req 2.7). Match volume without triage is not a control.
- **Retain the evidence trail** — alert dispositions, Activity Explorer exports, the simulate→enforce change
  log, and compliance sign-offs — so the control can be *shown*, not just claimed.
- Review **Activity Explorer** and the false-positive rate on a **recurring cadence**; re-tune as data and
  behaviour drift. Refresh **EDM** data on cadence if used.
- Enforce **least-privilege roles** and, where possible, **separate policy authors from alert triagers**.

## Stay honest about the boundary
- Endpoint DLP restricts content it can **classify** at the moment of the activity — a determined user can
  still **photograph a screen with a phone**. DLP is **one supporting control**, not a guarantee; combine it
  with sensitivity labels + encryption, access control, and insider-risk where the risk warrants.
- The **enforced action, which data categories are in scope, and whether the control is required** are
  **compliance / privacy / legal** decisions — you provide the technical control and the evidence; they own
  the call.


---


# Deliverables Summary — Clipboard & Screen-Capture Protection in Microsoft Purview

Everything included in this solution, what each piece is for, and how it maps to the deployment model. Use
it as the table of contents and the "did we finish?" checklist.

## Documents

| Document | What it gives you |
|---|---|
| **01 — Solution Overview** | What clipboard & screen-capture Endpoint DLP delivers, the two activities it controls (copy to clipboard, screen capture), onboarding, the simulate-first rule, the complementary label-usage-right lever, and the Assess→Design→Configure→Pilot→Validate→Expand model. |
| **02 — Requirements** | The solution-specific prerequisites (2.1–2.7): Endpoint DLP clipboard/screen-capture licensing (E5 / E5 Compliance; screen capture newer/preview), DLP least-privilege roles, devices onboarded (+ minimum OS build), a classification intent (SITs / labels), allowed-app/browser/network exceptions, a pilot ring + simulation dwell + change control, and an alert-triage owner. Each with Verify / Implement-if-missing. References the category `global-requirements-purview.md`. |
| **03 — Implementation Guide** | The ordered build: connect & baseline → design the classification layer → author the Devices policy with the clipboard+screen-capture rule **in simulation** → measure & tune → enforce to a ring → expand. Every object named, with a pass/fail gate and rollback per phase. |
| **05 — Testing & Validation** | The pass/fail gates: detection & enforcement (A) for clipboard and screen capture, false-positive rate (B), incident/alert handling & evidence (C), simulation-first & rollback validation, and the evidence to capture. |
| **06 — Troubleshooting** | The failures you will actually hit — no endpoint activity, screen capture not available, false positives, the rule not firing, simulation-vs-enforce confusion, restriction-setting errors, empty reports — each with cause and fix. |
| **07 — Best Practices** | How to run it well: simulate-then-enforce discipline, keying on labels first, right-sizing the allowed-app/browser exceptions, tuning for a low false-positive rate, the user experience, evidence/operations, and the honesty about the boundary. |
| **Executive Summary** | The one-page business-level summary for stakeholders and sign-off. |

## PowerShell tools (5)

All are **read-only or `-WhatIf` by default**, use interactive modern-auth (`Connect-IPPSSession` /
`Connect-MgGraph`), and contain **no credentials**. They do **not** onboard devices (onboarding is a
portal/management-tool action), do **not** enforce (the config helper is simulation-only), and do **not**
invent cmdlets. Because **screen-capture restriction is newer / may be in preview** and restriction Setting
names evolve, the tools **read and print** the setting shape and degrade gracefully rather than asserting
availability — **verify your licensing/tenant.**

| Script | Purpose | Safe default |
|---|---|---|
| **DLPCLIP-Discovery.ps1** | Inventory existing DLP policies/rules and **Devices** coverage, flag any rule that already restricts clipboard/screen-capture, read the Endpoint DLP settings, and list labels + sensitive info types — the baseline of what already restricts copy/screenshot on the endpoint. | Read-only |
| **DLPCLIP-Configure.ps1** | Build/update the `DLP - Endpoint Clipboard+Screen - Simulation` policy and its **clipboard + screen-capture** rule **in simulation**; requires `-Commit` to write and supports `-WhatIf`. Never enforces. | `-WhatIf` (preview) |
| **DLPCLIP-Validate.ps1** | Run the configuration gates (policy exists, Devices location, simulation mode, pilot scope, clipboard + screen-capture restrictions, sensitive-content condition) with PASS/FAIL output; screen capture flagged VERIFY where not readable. | Read-only |
| **DLPCLIP-Report.ps1** | Roll up policy modes and, where available, export **clipboard/screen-capture** endpoint events (matches, audits, blocks, overrides) from Activity Explorer to CSV — the operational + evidence view for the false-positive measure. | Read-only |
| **DLPCLIP-ScopeHealth.ps1** | Report device onboarding + Endpoint DLP feature/licensing readiness for clipboard & screen-capture (managed-device signals via Graph, pilot-group membership, policy scope, Endpoint DLP settings readability). | Read-only |

## How it maps to the deployment model

| Phase | Deliverables used |
|---|---|
| **Assess** | 01, 02, `DLPCLIP-Discovery.ps1`, `DLPCLIP-ScopeHealth.ps1` |
| **Design** | 02, 03 (named objects + detectors), 07 |
| **Configure** | 03, `DLPCLIP-Configure.ps1 -WhatIf` then `-Commit` (simulation) |
| **Pilot (simulation)** | 03, 05 (Gate B simulation pass), `DLPCLIP-Report.ps1` |
| **Validate** | 05, `DLPCLIP-Validate.ps1`, `DLPCLIP-Report.ps1` |
| **Expand (enforce)** | 03 (Phase 4/5), 05 (Gate A enforce pass), 06, 07 |

## Definition of done

- Pilot Windows/macOS devices **onboarded** and visible in **Purview → Devices**, meeting the minimum OS
  build for clipboard/screen-capture (screen capture **verified** available, or clipboard delivered first).
- Endpoint DLP settings (allowed/unallowed apps & browsers, service domains, network) defined so sanctioned
  copy-paste and normal screenshots are not caught.
- `DLP - Endpoint Clipboard+Screen - Simulation` with its rule built **in simulation**, all configuration
  gates (A) PASS.
- Behavioural gates (A) PASS in the **simulation pass**, then in the **enforce pass** to the pilot ring;
  the **false-positive gate (B)** meets the agreed threshold; **incident/alert handling (C)** produces a
  dispositioned incident.
- **Evidence pack** captured (baseline, simulation match export + TP/FP classification, enforcement
  screenshots/alerts, dispositioned incident, rollback proof) and stored with the change record.
- Regulatory / policy determinations (which data, and whether the action is audit / block-with-override /
  hard block) recorded by the **compliance / security** owners — not by the administrator.
