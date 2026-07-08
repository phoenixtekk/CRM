# Print DLP — Microsoft Purview

> **Version 1.0.0** · Category: Purview · Solution code: DLPPRINT

> This is the online, maintained copy of the implementation guide. When this solution is updated, eligible customers are alerted and can return here for the current content. Downloadable PDF + scripts are attached on the store listing.



---


# Executive Summary — Print DLP (Microsoft Purview)

Every other data-loss control watches the file — email DLP, external-sharing blocks, encryption. None of
them sees a user open a sensitive document, press **Print**, and walk out with paper that has no audit
trail, no revocation, and no way back. Printing is the quiet blind spot in most data-protection programs,
and it is exactly the path a regulator or a breach post-mortem will ask about.

This solution closes it using **Microsoft Purview Endpoint Data Loss Prevention (Endpoint DLP)**: a policy
that watches the **Print activity** on onboarded devices and — when a document's content matches your
**sensitive information types** or carries a sensitive **sensitivity label** — can **audit**, **warn with a
policy tip and allow-with-justification**, or **block** the print, while telling **sanctioned corporate
printers** apart from **network, local, and print-to-PDF/XPS** output. It stands the control up end to end
using only the **Purview portal**, **Security & Compliance PowerShell**, and **Microsoft Graph** — no
third-party agent — and is written for an administrator with no prior Endpoint DLP experience.

## What you get
- A plain-language **Solution Overview** of the print exfiltration gap, how the Print activity and **printer
  groups** work, the complementary **sensitivity-label PRINT usage right**, and the simulate→enforce
  discipline.
- A **Requirements Guide** with verify / implement-if-missing for every prerequisite (the category Purview
  requirements — tenant/compliance licensing, DLP roles, S&C PowerShell + Graph, in-scope data,
  stakeholders, pilot + change control — are referenced, not repeated).
- An **Implementation Guide** of precise, ordered steps: build the detectors, define printer groups, create
  the Devices-only Print policy **in simulation**, tune false positives down, enforce to a pilot ring, then
  expand — each artifact named, with pass/fail gates and rollback.
- Five **PowerShell scripts** for posture discovery, safe configuration (`-WhatIf`, simulation-only),
  policy-shape validation, activity reporting, and endpoint-readiness checks.
- **Testing** and **Troubleshooting** guides for a confident rollout.

## What this delivers
Printing of sensitive content is **controlled by policy** — proven in simulation, tuned to a low
false-positive rate, enforced from a ring outward, with corporate printing preserved, restricted prints
audited and alerted, and the control **defensible and evidenced**.

## The deployment model
**Assess → Design → Configure → Pilot (simulate) → Validate → Expand** — build the policy in simulation,
prove it against real print activity, enforce on a handful of users, then roll out in waves.

## An honest note
Endpoint DLP requires **onboarded devices and the right licensing** (typically **E5 / E5 Compliance** —
**verify your licensing/tenant**), and a Devices-location policy is inert until onboarding is complete.
**Windows** print restriction is the most complete; **macOS** print support and specific behaviours evolve —
where behaviour is OS-/tenant-dependent this package flags **"verify against current Microsoft guidance /
your tenant"** rather than asserting it. Which data is in scope and what the enforced action must be are
**compliance, privacy, and legal determinations**, deferred to those functions; this package delivers the
technical method and the evidence, not the determination.

## Outcome
A print-DLP control that stops sensitive documents from walking out on paper — configured, piloted in
simulation, validated against pass/fail gates, and operable — so the capability is in place and defensible
in Microsoft Purview.


---


# 1. Solution Overview — Print DLP (Microsoft Purview)

## What this solution is
Most data-loss controls watch the *file* — email DLP, external-sharing blocks, encryption. None of them
see a user select **Print**, send a sensitive document to a printer, and walk away with paper that leaves
the building unlogged and unrecoverable. **Microsoft Purview Endpoint Data Loss Prevention (Endpoint DLP)**
closes that path by watching the *print activity* on an **onboarded device**: when a document whose content
matches your **sensitive information types** (or carries a sensitive **sensitivity label**) is sent to a
printer, the policy can **audit** the print, **warn with a policy tip and allow-with-justification**, or
**block** it — and can distinguish **corporate/allowed printers** from **local, network, or universal
(print-to-PDF/XPS)** printing.

This solution is a repeatable, evidence-driven way to configure the **Print** restriction for sensitive
content on endpoints using only the **Microsoft Purview portal**, **Security & Compliance PowerShell**
(`Connect-IPPSSession`), and **Microsoft Graph** — no third-party agent. Its defining discipline is that
**every restriction is built and proven in SIMULATION / audit mode first** (Microsoft's built-in test mode
that records what *would* have been restricted against real device activity, with zero user impact), tuned
for a low false-positive rate, and only then moved to enforcement.

> **Scope boundary.** This solution delivers the **technical method and evidence** for restricting printing
> of sensitive content on endpoints. *Which* data is regulated, *which* classifiers or labels legally apply,
> and *what* the enforced action must be for a given data category are **business, compliance, privacy, and
> legal determinations** — deferred to those functions. The solution configures and proves the control; it
> does not make the policy decision.

## Why this matters
- **Printing is the file controls' blind spot.** A document can be encrypted, un-shareable, and blocked from
  email, yet a user opens it and prints it — and none of the file-level controls ever see it. Paper has no
  audit trail, no revocation, and no DLP at the mail gateway. Endpoint DLP watches the *print activity*, not
  just the file.
- **Endpoint DLP is licensing- and onboarding-dependent.** The Print restriction requires the right plan
  (typically **Microsoft 365 E5** / the **E5 Compliance** add-on) and devices **onboarded** to Purview
  (shared with Microsoft Defender for Endpoint onboarding). A Devices-location policy is inert until
  onboarding is complete — **verify your licensing/tenant**.
- **Print controls are OS- and printer-dependent.** Print restriction is most complete on **onboarded
  Windows 10/11** devices; **macOS** print support and specific behaviours differ and evolve — this solution
  flags "verify your licensing/tenant" rather than asserting availability. **Printer groups** (corporate vs
  network vs local vs universal/PDF) let you allow sanctioned printing while restricting the rest.
- **Enforced-first is the classic failure.** Blocking printing straight away breaks legitimate work — a
  clerk printing a routine form, a nurse printing a chart at the ward printer — floods the help desk, and
  gets the policy disabled. Audit/simulation first, tuned, is the difference between a control that survives
  and one that is turned off.

## How it works
1. **Sensitive information types (SITs), classifiers, and sensitivity labels** define *what* content is
   sensitive. Endpoint DLP matches the content of the document being printed against built-in SITs
   (credit card, national ID, health identifiers, etc.), **custom SITs**, **Exact Data Match (EDM)** SITs,
   **trainable classifiers**, or the presence of a **sensitivity label** on the item.
2. **A DLP policy scoped to the Devices (Endpoint) location** binds those detectors to the **Print**
   endpoint activity under *"Audit or restrict activities on devices."* The action per activity is **Audit**,
   **Block with override**, or **Block**, and can differentiate **printer types** using **printer groups**.
3. **Printer groups** (defined once in **Endpoint DLP settings**) let you treat classes of printers
   differently — e.g. allow printing sensitive content to a locked-down **corporate** printer group while
   auditing or blocking **network**, **local (USB/directly attached)**, and **universal/print-to-PDF/XPS**
   printing.
4. **Simulation / audit mode** runs the policy against live device activity and records what *would* have
   been restricted — with or without policy tips shown — so you see the true volume and false positives
   **before** any enforcement. Every restriction in this solution starts here.
5. **Tuning** reduces false positives using confidence levels, instance thresholds, supporting keywords,
   EDM, label-based conditions, and **printer-group / app exceptions**, measured against the simulation
   results.
6. **Enforcement** turns the tuned restriction on (tip / allow-with-justification / block) in a limited
   ring, then expands.
7. **Incident/alert handling** — restricted print activities raise **alerts** in the Purview portal and flow
   to **Activity Explorer**; this solution wires the triage, severity, and response workflow so matches are
   actually acted on.

## The activity this solution controls (and what it stops)
- **Print →** sending a document that contains sensitive content to any printer. Endpoint DLP can **audit**
  the print, **warn-and-justify**, or **block** it, and can apply **different actions per printer group** —
  the core lever for allowing sanctioned corporate printing while restricting network, local, and
  print-to-PDF/XPS output. **Availability of specific print behaviours and macOS support varies — verify your
  licensing/tenant.**

## A complementary lever: sensitivity-label protection (RMS usage rights)
Where content carries a **sensitivity label with encryption**, the label's **usage rights** independently
govern printing: removing the **PRINT** usage right from a permission set prevents printing protected Office
files regardless of endpoint. This solution's primary path is **Endpoint DLP** (which covers any content,
labelled or not, and adds printer-group differentiation), but the label-usage-right lever is documented here
as a complementary control where labels are already in use — verify your labeling design with the
information-protection owner.

## The simulate→enforce journey (the core discipline)
> Confirm SITs/labels → define **printer groups** (corporate/allowed vs network/local/universal) → build the
> Endpoint DLP policy with the **Print** activity in **SIMULATION / audit** (no user impact) → measure volume
> and false positives in **Activity Explorer / DLP alerts** → **tune** (confidence, instance count, keywords,
> EDM, label condition, printer-group exceptions) → re-simulate until false positives are acceptable → enable
> with **policy tips + allow-override/justification** in a **pilot ring** → validate → expand to **enforce
> (block)** across the intended scope → operate (triage alerts, review overrides, re-tune).

## What you can control
- Which **SITs/classifiers/labels** trigger the restriction, and at what **confidence** and **instance count**.
- The **action** on the Print activity (audit → tip → justify → block), and **different actions per printer
  group** — allow corporate, restrict network/local/universal.
- Which **users / devices / groups** are **included or excluded**, and the **pilot ring** enforced first.
- The **printer groups** and any **app exceptions** so sanctioned printing isn't caught.
- Whether users get **policy tips**, can **override** with justification, and what the override says.

## Limitations (be honest with buyers)
- **Endpoint DLP requires onboarded devices and the appropriate licensing** (verify your plan — endpoint DLP
  is gated behind E5 / the E5 Compliance add-on). A Devices-location policy is inert until onboarding is
  complete.
- **Print behaviours are OS- and printer-dependent and evolve.** Restriction is most complete on onboarded
  **Windows 10/11**; **macOS** print support and specific behaviours differ — this solution flags "verify
  your licensing/tenant" rather than asserting availability.
- Endpoint DLP restricts content it can **classify** (SIT / label match). Content below the
  confidence/instance threshold, or that the device agent cannot classify at the moment of the print, will
  not match. DLP is one control among several, not a guarantee — a determined user can still photograph a
  screen or retype content.
- The **enforced action for a data category is a compliance/legal decision**, not a technical default — this
  solution configures and proves the control; the determination is deferred.

## Naming convention (used in every doc and script)
Every artifact this solution creates uses `<Purpose> – <Scope> – <Stage>`, reused verbatim across the docs,
scripts, and the Purview portal. The standard set:

| Artifact | Name |
|---|---|
| Endpoint DLP policy (simulation) | `DLP – Endpoint Print – Simulation` |
| Content rule on that policy | `DLP – Endpoint Print – Rule` |
| Enforced pilot policy | `DLP – Endpoint Print – Enforce Pilot` |
| Pilot user/device ring | `DLP Pilot Ring – Stage1` |
| Corporate/allowed printer group | `Printers – Corporate – Allowed` |
| Policy-tip / override text | `DLP Notice – Print – Standard` |
| Incident/alert workflow | `DLP Alerts – Print – Operations` |
| (Optional) label restricting print | `Confidential – No-Print – Endpoint` |

## The standard deployment model
> **Assess** current endpoint exposure and classification intent → **Design** the SIT/label detectors, the
> printer groups, and the print restriction → **Configure** the Endpoint DLP policy **in simulation/audit** →
> **Pilot** (simulate → tune → enforce to a ring) → **Validate** against pass/fail gates (printing of
> sensitive content restricted, corporate printing allowed, false-positive rate low, incidents handled) →
> **Expand** to the full scope and ongoing operations. Every high-impact change is piloted in simulation
> first, with a documented rollback.


---


# 2. Requirements — Print DLP (Microsoft Purview)

These are the **solution-specific** prerequisites for configuring the **Print** restriction for sensitive
content on endpoints. They build on — and do not repeat — the six shared prerequisites in
**`global-requirements-purview.md`** (tenant + compliance licensing, least-privilege Purview roles, S&C
PowerShell + Graph toolchain, in-scope data sources, compliance/records/privacy/legal stakeholders, and a
pilot scope + change control). Verify each item below before starting the Implementation Guide.

For every requirement: **Description** (what it is), **Why required**, **How to verify**, **How to implement
if missing**.

---

## 2.1 Licensing sufficient for Endpoint DLP print restrictions
- **Description:** Endpoint DLP activity restrictions — including the **Print** activity — are **plan-gated**,
  typically **Microsoft 365 E5** or the **E5 Compliance** add-on. Specific print behaviours (printer-group
  differentiation, macOS print) may be **newer or vary by OS/tenant** and are gated on minimum OS builds.
  This extends GR-#1 with the capability-specific plan detail.
- **Why required:** A DLP policy scoped to the Devices location and using the Print activity will not
  function without the required plan; the activity may not even be selectable.
- **How to verify:** In the **Microsoft 365 admin center** confirm the subscription/add-ons; in the
  **Purview portal → Data Loss Prevention** confirm the **Devices** location and, when authoring a rule, that
  **Print** appears under *"Audit or restrict activities on devices."* **Flag "verify your licensing/tenant"**
  — availability and macOS support evolve.
- **How to implement if missing:** Acquire/assign the required licensing (E5 / E5 Compliance) before building
  the restriction; if a specific print behaviour is unavailable in your tenant/OS, deliver Windows print
  restriction first and revisit the rest when the capability is enabled.

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
  Defender for Endpoint are onboarded for Endpoint DLP. Print restriction additionally depends on **minimum
  OS builds** and OS-specific support (Windows print is the most complete; **macOS print support varies —
  verify your tenant**).
- **Why required:** A policy scoped to the **Devices** location does nothing on a device that is not onboarded
  and reporting. Onboarding is the non-negotiable prerequisite for print control.
- **How to verify:** **Purview portal → Settings → Device onboarding → Devices** shows onboarded devices;
  confirm target devices appear and are reporting. Confirm each device meets the minimum OS build documented
  by Microsoft for the Print activity. Script #5 (`DLPPRINT-EndpointReadiness.ps1`) surfaces the readiness
  signals.
- **How to implement if missing:** Onboard devices via the Purview device-onboarding package, Intune, or
  Group Policy; confirm the minimum OS build and any required AV/agent state per Microsoft docs before
  scoping the restriction.

## 2.4 A classification intent — the SITs, classifiers, or labels that mark "sensitive"
- **Description:** A documented view of **which content must not be printed** (e.g. payment card data,
  national IDs, health identifiers, source code, or any item carrying a specific **sensitivity label**)
  mapped to the **detector** that identifies it — built-in SITs where they fit, **custom SITs / EDM /
  trainable classifiers** for gaps, and/or a **sensitivity-label condition**. Extends GR-#4.
- **Why required:** The restriction keys off *what* is sensitive; a print rule with no precise detector
  either catches nothing or catches everything (false-positive flood).
- **How to verify:** **Purview portal → Data classification → Classifiers → Sensitive info types** lists
  built-in and custom SITs; **Information protection → Labels** lists sensitivity labels. Confirm the ones
  you need exist (or are planned) with the data owners.
- **How to implement if missing:** Build the SIT/label inventory (this solution's Discovery script assesses
  built-in SIT coverage and any existing endpoint restrictions); plan custom SITs / EDM / a label condition
  for categories not covered.

## 2.5 Printer-group and app-exception intent
- **Description:** The definition of **which printers are sanctioned** for sensitive output (e.g. a
  locked-down corporate/managed print queue) versus **network**, **local (USB/directly attached)**, and
  **universal / print-to-PDF/XPS** printing that should be audited or blocked — expressed as **printer
  groups** — plus any **applications** whose printing is legitimately exempt. Endpoint DLP evaluates the
  Print activity against **printer groups** and the app lists in **Endpoint DLP settings**.
- **Why required:** Without printer-group differentiation, the restriction catches all legitimate printing to
  the sanctioned corporate queue alongside the risky paths, driving false positives and killing adoption.
- **How to verify:** **Purview portal → Data loss prevention → Endpoint DLP settings → Printer groups**
  shows the defined groups; confirm the sanctioned corporate printers are represented before authoring the
  rule.
- **How to implement if missing:** Capture the sanctioned printer list (name/IP/USB identifiers) from IT,
  define the `Printers – Corporate – Allowed` group and any others, and configure the Endpoint DLP settings
  lists before enforcing.

## 2.6 A pilot ring, simulation dwell time, and change control (endpoint-specific)
- **Description:** A named **pilot user/device ring**, an agreed **simulation/audit dwell time** (how long
  the policy runs in audit before enforcement — long enough to capture representative print activity, e.g.
  through a monthly close or billing cycle where printing spikes), and the **change-control window** for
  moving audit → enforce. Extends GR-#6.
- **Why required:** Print blocking is high-impact and highly visible to users; enforcing without an audit
  baseline and a limited ring is how the control breaks day-to-day work. The house model mandates
  **simulation/audit first**, then a ring, then expand.
- **How to verify:** Confirm the pilot ring membership, that the policy is created in **simulation/audit
  mode**, and the approval path to enforce.
- **How to implement if missing:** Define the ring and dwell time and agree change control before enabling
  any block action.

## 2.7 An incident/alert triage owner and destination
- **Description:** A named owner (or queue) for **DLP alerts** raised in **Purview portal → Data loss
  prevention → Alerts**, plus where restricted-activity events are reviewed (**Activity Explorer**) and,
  optionally, where they are forwarded (SIEM / Microsoft Sentinel via the Office 365 Management Activity API
  / Defender connectors). Severity and response actions defined.
- **Why required:** A restricted print event with no one to triage it is not a control. Alerts and Activity
  Explorer are where matches surface; someone must own triage, severity, and response.
- **How to verify:** Confirm the triage owner/queue (`DLP Alerts – Print – Operations`), the alert-severity
  scheme, and any SIEM forwarding is configured.
- **How to implement if missing:** Assign the owner, define severity/response, and (optionally) wire SIEM
  forwarding before enforcement generates real alerts.

---

### Requirements summary

| # | Requirement | Gate |
|---|---|---|
| GR 1–6 | Category prerequisites (`global-requirements-purview.md`) | Tenant/licensing, roles, toolchain, scope, stakeholders, pilot + change control |
| 2.1 | Endpoint DLP print licensing (E5 / E5 Compliance; verify OS/tenant support) | Print activity available/selectable |
| 2.2 | DLP least-privilege roles | Author + triage roles assigned |
| 2.3 | Devices onboarded to Purview (+ min OS build) | Endpoint location & Print activity functional |
| 2.4 | Classification intent — SITs / classifiers / labels | Restriction keys off the correct detector |
| 2.5 | Printer groups + app exceptions | Corporate printing allowed; risky paths restricted |
| 2.6 | Pilot ring + simulation dwell + change control | Simulate/audit-first enforced |
| 2.7 | Alert/incident triage owner + destination | Restricted prints are acted on |

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


# 3. Implementation Guide — Print DLP (Microsoft Purview)

This is the exact, ordered procedure to configure the **Print** restriction for sensitive content on
**onboarded endpoints** — built in **SIMULATION / audit** mode first, tuned, then enforced in a ring, then
expanded. Portal paths and cmdlets are from Microsoft's public documentation; **licensing-/plan-dependent
features and evolving/preview portal paths (and macOS print support) are flagged "verify your
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
   .\DLPPRINT-Discovery.ps1 -CsvPath .\DLPPRINT-Posture.csv
   ```
   It reports existing DLP policies and their mode, which ones scope the **Devices/Endpoint** location, any
   **Print** restriction already configured on their rules, and built-in vs custom SIT coverage.
3. **Confirm licensing and endpoint readiness** (Req 2.1, 2.3): confirm E5 / E5 Compliance, that target
   devices are **onboarded** and meet the **minimum OS build**, and that the **Print** activity is selectable
   in a rule (script #5 surfaces the readiness signals). If a specific print behaviour (e.g. macOS print) is
   not available in your tenant, note it and deliver Windows print first.

**Pass/fail gate:** you have a written baseline (existing policies + modes + any endpoint restrictions), a
SIT/label coverage map, and confirmed licensing + onboarding for the Devices location.
**Rollback:** none (read-only).

---

## Phase 1 — Design the classification layer (what counts as "sensitive")

Decide which detector marks content that must not be printed. Do **not** invent SITs — use built-in where
they fit; build custom/EDM/trainable only for gaps; use a **sensitivity-label condition** where content is
already labelled.

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

**Pass/fail gate:** every in-scope "do not print" category maps to a named, tested detector (built-in SIT,
custom SIT, EDM, trainable classifier, or sensitivity label) at a chosen confidence/instance count.
**Rollback:** delete unused custom SITs (they have no effect until referenced by a policy).

---

## Phase 2 — Define printer groups and configure the restriction in SIMULATION (Configure — no user impact)

First define **printer groups** so sanctioned printing can be treated differently, then create **one
Endpoint DLP policy** with a rule that covers the **Print** activity, in **simulation / audit** mode.
Simulation/audit records what *would* be restricted against real device activity, with **no** enforcement
and (optionally) with policy tips shown.

8. **Define printer groups** (Req 2.5). Portal: **Data loss prevention → Endpoint DLP settings → Printer
   groups** → create `Printers – Corporate – Allowed` and add the sanctioned corporate printers (by
   friendly name, IP range, USB product/vendor ID, or "print to local", "network printer",
   "universal print", "print to file" as your tenant exposes them). This group is what lets you **allow**
   sensitive printing to the managed queue while **auditing/blocking** network, local, and
   print-to-PDF/XPS output.
9. **Create the policy — `DLP – Endpoint Print – Simulation`.**
   Portal: **Data loss prevention → Policies → Create policy** → custom (or a category template) →
   **Locations: Devices only** (all other locations off for this solution). Confirm the Devices location is
   selectable; if not, revisit licensing/onboarding (Req 2.1/2.3).
10. **Author the rule — `DLP – Endpoint Print – Rule`.**
    - **Condition:** *Content contains* → the SITs from Phase 1 at the chosen confidence/instance count,
      and/or *Sensitivity labels* from Phase 1.
    - **Actions → "Audit or restrict activities on devices":** set the **Print** activity (labelled per your
      tenant's current portal) to **Audit** (the simulation-phase action). Where the portal exposes
      **per-printer-group** actions, set **corporate/allowed** to *Audit* (later *Allow/Audit only*) and
      **network / local / universal (print to PDF/XPS)** to *Audit* now. Leave the other endpoint activities
      (USB, clipboard, network share, etc.) untouched — they are out of scope for this solution.
    - **User experience:** define `DLP Notice – Print – Standard` policy-tip text and enable **allow override
      with justification** where compliance permits — note tips/overrides only *appear* once the policy is
      enforced; in audit they are captured, not shown, unless "simulation with policy tips" is selected.
11. **Set the policy mode to simulation.** Choose **"Run the policy in simulation mode"** (optionally *with
    policy tips*). Finish. In S&C PowerShell this corresponds to `Mode = TestWithNotifications` /
    `TestWithoutNotifications`.
12. **Verify with the config helper** (delivered script #2, `-WhatIf` by default):
    ```powershell
    .\DLPPRINT-Config.ps1 -PolicyName 'DLP - Endpoint Print - Simulation' `
        -SensitiveTypes 'Credit Card Number' -MinCount 1 -Confidence High -WhatIf
    ```
    The helper previews the `New-DlpCompliancePolicy` / `New-DlpComplianceRule` calls (Devices location,
    simulation mode, Print restriction). Because the exact **endpoint-restriction setting names and
    printer-group syntax evolve**, the recommended pattern is: build the rule **once in the portal**, then
    read its restriction property with script #1 to confirm the exact names before ever committing with the
    helper. Run with `-Commit` only to apply an intended change; the helper never leaves a policy in enforce
    mode.

**Pass/fail gate:** the policy exists, is scoped to **Devices only**, covers the **Print** activity, treats
the `Printers – Corporate – Allowed` group distinctly, and is confirmed in **simulation** (script #1/#2/#3
report a `Test*` mode).
**Rollback:** delete the simulation policy — simulation has no user impact, so removal is clean.

---

## Phase 3 — Measure and tune (drive false positives down)

Let the policy run in simulation for the agreed **dwell time** (Req 2.6) to capture representative print
activity — ideally spanning a period of peak printing (month-end, billing run).

13. **Review what would have been restricted.** **Purview portal → Data loss prevention → Alerts**
    (simulation alerts) and **Data classification → Activity explorer** (filter to endpoint DLP activities —
    *print*) show every simulated match with the printer, the SIT/label, and the confidence. Export with the
    reporting script:
    ```powershell
    .\DLPPRINT-Report.ps1 -Days 14 -CsvPath .\DLPPRINT-Activity.csv
    ```
14. **Classify each match** as true positive or **false positive** and identify the false-positive drivers
    (e.g. routine forms printed to the corporate queue, a document that happens to contain a low-confidence
    pattern).
15. **Tune** to reduce false positives without losing true positives:
    - Raise the **confidence level** (e.g. medium → high) and/or the **instance count** so incidental matches
      don't fire.
    - Prefer a **sensitivity-label condition** over broad SITs where content is labelled — far fewer false
      positives.
    - Refine **printer groups**: keep sanctioned corporate printing in the `Printers – Corporate – Allowed`
      group at *Audit/Allow*, and focus the restriction on **network / local / universal** printing.
    - Introduce **EDM** for categories where pattern SITs over-match.
    - Add **supporting keywords / proximity** to custom SITs so context is required.
16. **Re-simulate** after each tuning change and re-measure. Repeat until the false-positive rate meets the
    validation gate (see Testing).

**Pass/fail gate:** measured false-positive rate is at/under the agreed threshold on the simulation sample,
with true positives (sensitive-content print) still detected and sanctioned corporate printing not caught.
**Rollback:** revert the last tuning change (script #2 `-WhatIf` shows the diff before `-Commit`).

---

## Phase 4 — Enforce in a pilot ring (Pilot)

17. **Scope to the pilot ring.** Set `DLP Pilot Ring – Stage1` (users) and the pilot devices as the
    **included** scope on the policy (all other users/devices excluded for now):
    ```powershell
    .\DLPPRINT-Set-Scope.ps1 -PolicyName 'DLP - Endpoint Print - Simulation' `
        -IncludeGroup 'DLP Pilot Ring - Stage1' -WhatIf
    ```
    > *(The scope helper is delivered as part of the config/remediation tool — `DLPPRINT-Config.ps1
    > -SetScope`. Run `-WhatIf` first; `-Commit` to apply.)*
18. **Move the ring to enforcement.** Change **Policy mode** from *simulation* to **Turn it on / Enforce**.
    Start the Print activity at **Block with override (justification)** rather than hard block, so the pilot
    can report false negatives/positives while retaining a business escape hatch. Keep the
    `Printers – Corporate – Allowed` group at *Allow/Audit*. (Rename to `DLP – Endpoint Print – Enforce Pilot`
    if your change process tracks the transition.)
19. **Confirm enforcement is live** for the ring only (script #1 reports mode `Enable` and the scoped
    identities; script #4 validates the Devices-only, Print-restriction, printer-group configuration). On a
    ring device, confirm a test print of clearly-fake sensitive content to a **non-corporate** printer now
    shows the `DLP Notice – Print – Standard` tip and requires justification, while printing to the corporate
    queue behaves per policy.
20. **Handle incidents.** Wire `DLP Alerts – Print – Operations`: assign the alert owner/queue (Req 2.7),
    set severities, and (optionally) forward to SIEM/Sentinel. Triage a real pilot alert end-to-end to prove
    the workflow.

**Pass/fail gate:** the pilot ring is enforced (printing of sensitive content to non-corporate printers
restricted, tips shown, overrides captured, corporate printing allowed), matches raise alerts, and the
triage workflow produces a dispositioned incident. No enforcement outside the ring.
**Rollback:** set the policy back to **simulation mode** (single setting) — instantly removes enforcement
with no data change.

---

## Phase 5 — Expand and harden (Enforce → Operate)

21. **Expand scope** from the ring to the full intended population once the pilot gate passes, keeping
    documented exclusions.
22. **Escalate the action** per compliance's determination — e.g. move Print (for network/local/universal
    groups) from *block with override* to **hard block** where required — one printer group at a time,
    re-validating after each.
23. **Operationalize:** schedule the reporting script for a recurring false-positive/alert review, review
    **user overrides** (are people justifying legitimately or bypassing?), refresh **EDM** data on cadence
    (if used), and re-tune the **printer groups** as printers change.
24. **Validate end-to-end** with the delivered testing procedure (next section) and record the pass/fail
    evidence.

**Pass/fail gate:** enforcement live across the intended scope with the compliance-mandated action per
printer group; sanctioned corporate printing unaffected; false-positive rate steady/low; alerts triaged on
cadence; overrides reviewed.
**Rollback:** the policy can be returned to **simulation** at any time as an immediate, non-destructive
safety switch; the Print action can be relaxed per printer group independently.

---

## Order-of-operations summary

| Phase | Do | Artifact(s) | Gate | Rollback |
|---|---|---|---|---|
| 0 Assess | Connect, baseline, confirm licensing/onboarding | Posture CSV | Baseline + readiness confirmed | n/a (read-only) |
| 1 Design | Map/build SITs / label condition | Custom SIT / label condition | Every category → tested detector | Delete unused SIT |
| 2 Configure | Define printer groups; build the Devices policy (Print) **in simulation** | Printer group + `…– Simulation` policy + rule | Simulation, Devices-only, Print activity, corporate group distinct | Delete sim policy |
| 3 Tune | Measure + reduce false positives | Activity CSV | FP rate ≤ threshold; corporate printing not caught | Revert tuning change |
| 4 Pilot | Enforce to ring, wire alerts | Pilot ring, alert triage | Ring enforced, incident dispositioned | Back to simulation |
| 5 Expand | Broaden scope, escalate to block, operate | Enforced policy | Full-scope enforce, low FP, alerts triaged | Simulation / relax printer group |


---


# 5. Testing Guide — Print DLP (Microsoft Purview)

Run after the Endpoint DLP print policy is built in **simulation** (Implementation Phases 2–3) and again
after each enforcement stage (Phases 4–5). Back each test with **`DLPPRINT-Discovery.ps1`** (posture),
**`DLPPRINT-Validation.ps1`** (policy shape), **`DLPPRINT-EndpointReadiness.ps1`** (onboarding), and
**`DLPPRINT-Report.ps1`** (activity). Where print behaviour is **OS-/tenant-dependent (e.g. macOS), verify
against current Microsoft guidance / your tenant** rather than assuming.

## Test 1 — Licensing and endpoint readiness
**Do:** Run **`DLPPRINT-EndpointReadiness.ps1`**; check **Purview portal → Settings → Device onboarding**.
**Expected:** Target devices are **onboarded** and reporting, meet the minimum OS build, and the **Print**
activity is selectable when authoring a Devices-location rule. Any gap is listed to fix before enforcement.

## Test 2 — Policy is Devices-only and in simulation
**Do:** Run **`DLPPRINT-Discovery.ps1`** / **`DLPPRINT-Validation.ps1`**; check the policy in the portal.
**Expected:** `DLP – Endpoint Print – Simulation` exists, scoped to **Devices only**, its rule sets the
**Print** activity, and its mode is a **`Test*` (simulation)** mode — not enforce.

## Test 3 — Printer groups resolve correctly
**Do:** Run **`DLPPRINT-Validation.ps1`**; check **Endpoint DLP settings → Printer groups**.
**Expected:** `Printers – Corporate – Allowed` exists and contains the sanctioned corporate printers; the
rule treats corporate printing distinctly from network / local / universal (print-to-PDF/XPS).

## Test 4 — Simulation detects a sensitive print (true positive)
**Do:** On a ring device, print a document containing clearly-**fake** but SIT-matching content (e.g. a test
credit-card / SSN pattern) to a **non-corporate** printer. Run **`DLPPRINT-Report.ps1 -Days 1`**.
**Expected:** The print appears in **Activity Explorer** / simulation **Alerts** as a match, with the SIT,
confidence, and printer — showing it *would* have been restricted. No user impact (simulation).

## Test 5 — Corporate printing is not caught
**Do:** Print the same test document to a printer in `Printers – Corporate – Allowed`. Re-run the report.
**Expected:** Printing to the sanctioned corporate queue is **allowed / audit-only** per design — not
flagged as a would-be block. This is the "don't break legitimate printing" gate.

## Test 6 — Non-sensitive print does not match (no false positive)
**Do:** Print a plainly non-sensitive document (no SIT/label match) to any printer.
**Expected:** No print DLP match is recorded — the detector is specific enough not to fire on ordinary
content.

## Test 7 — False-positive rate meets the gate
**Do:** After the agreed simulation dwell time, run **`DLPPRINT-Report.ps1 -Days <dwell>`** and classify
matches true/false positive.
**Expected:** The measured **false-positive rate is at/under the agreed threshold**, with true positives
still detected. If not, tune (Implementation Phase 3) and re-measure before enforcing.

## Test 8 — Enforcement blocks with override on the pilot ring
**Do:** After moving `DLP Pilot Ring – Stage1` to enforce (Block with override), print sensitive test
content to a **non-corporate** printer on a ring device.
**Expected:** The `DLP Notice – Print – Standard` policy tip appears and the print requires **justification
to override** (or is blocked outright if hard block is configured). Corporate printing still works.

## Test 9 — Enforcement is scoped to the ring only
**Do:** Run **`DLPPRINT-Discovery.ps1`** / **`DLPPRINT-Validation.ps1`**; on a **non-ring** device print the
same sensitive test content.
**Expected:** The report shows mode `Enable` scoped to the ring identities only; the non-ring device is
**not** restricted. No enforcement leaks outside the pilot.

## Test 10 — Alerts raise and triage end-to-end
**Do:** From the enforced ring, trigger a restricted print; check **Data loss prevention → Alerts** and the
`DLP Alerts – Print – Operations` queue.
**Expected:** A **DLP alert** is generated at the configured severity, is assigned to the owner/queue, and
can be **dispositioned** (and forwarded to SIEM/Sentinel if wired). A restricted print with no triage is not
a control.

---
## Pass/fail gate
| Gate | Requirement |
|---|---|
| **Readiness pass** | Tests 1–3 pass (onboarded + licensed; Devices-only simulation policy; printer groups resolve) |
| **Simulation pass** | Tests 4–7 pass (sensitive print detected; corporate printing not caught; no FP on ordinary content; FP rate ≤ threshold) |
| **Enforcement pass** | Tests 8–10 pass (ring blocks with override; scoped to ring only; alerts raise and triage) |

> Do not expand beyond the pilot until all three gates pass. Re-run Tests 4–10 after each expansion wave and
> after any printer-group or detector change.


---


# 6. Troubleshooting Guide — Print DLP (Microsoft Purview)

Symptom → likely root cause → fix. Use **`DLPPRINT-Discovery.ps1`** (posture),
**`DLPPRINT-EndpointReadiness.ps1`** (onboarding/licensing), **`DLPPRINT-Validation.ps1`** (policy shape),
and **`DLPPRINT-Report.ps1`** (activity) to confirm before and after each fix. Where print behaviour is
**OS-/tenant-dependent (e.g. macOS) or evolving, verify against current Microsoft guidance / your tenant**
rather than assuming.

## A. Availability / setup

### The "Print" activity isn't selectable when authoring a rule
- **Licensing insufficient.** Endpoint DLP activity restrictions are plan-gated (typically E5 / E5
  Compliance). **Fix:** confirm the subscription in the M365 admin center; run
  **`DLPPRINT-EndpointReadiness.ps1`**. Assign the required licensing (Req 2.1).
- **Devices location not enabled / no onboarded devices.** The Print activity only appears with the Devices
  location available. **Fix:** confirm **Settings → Device onboarding** shows onboarded devices; onboard
  targets (Req 2.3).

### "Devices" location can't be selected on the policy
- **Onboarding incomplete.** A Devices-location policy is inert until devices are onboarded (shared with
  Defender for Endpoint onboarding). **Fix:** onboard via the Purview package / Intune / Group Policy;
  re-check with `DLPPRINT-EndpointReadiness.ps1`.

## B. Nothing is detected (false negatives)

### A sensitive print isn't flagged even in simulation
- **Device not onboarded or not reporting.** No onboarded, reporting device = no endpoint signal. **Fix:**
  `DLPPRINT-EndpointReadiness.ps1`; confirm the device is onboarded and checked in; confirm the minimum OS
  build for the Print activity.
- **Detector too strict.** Confidence too high or instance count too large, so real content doesn't match.
  **Fix:** lower confidence/instance count, or switch to a **sensitivity-label condition**; re-simulate.
- **Content not classifiable at print time.** The agent couldn't classify the document (e.g. image-only PDF,
  unsupported format). **Fix:** verify the format is supported; consider a label condition for such content.
- **Policy scoped away from the user/device.** The user/device is excluded or outside the included group.
  **Fix:** `DLPPRINT-Validation.ps1` shows the scoped identities; correct the include/exclude.

### macOS prints aren't restricted like Windows
- **OS-specific support differs.** Windows print restriction is the most complete; **macOS print support and
  specific behaviours evolve**. **Fix:** **verify against current Microsoft guidance / your tenant** for
  macOS print support; deliver Windows print first and revisit macOS when the capability is confirmed.

## C. Too much is detected (false positives)

### Ordinary documents are flagged as would-be blocks
- **Detector too broad.** A low-confidence SIT matches incidental patterns. **Fix:** raise confidence /
  instance count, add supporting keywords/proximity, or prefer a **label condition**; re-simulate and
  re-measure with `DLPPRINT-Report.ps1`.
- **Pattern SIT over-matches structured data.** **Fix:** introduce **Exact Data Match (EDM)** for
  customer/account numbers; refresh EDM data on cadence.

### Legitimate corporate printing is being caught
- **Corporate printers not in the allowed group.** The `Printers – Corporate – Allowed` group is missing
  printers or the rule doesn't treat it distinctly. **Fix:** **Endpoint DLP settings → Printer groups** —
  add the sanctioned printers (name/IP/USB IDs); keep that group at *allow/audit* while restricting
  network/local/universal. Re-run `DLPPRINT-Validation.ps1`.
- **Printer moved / changed IP.** A stale printer group no longer matches the moved corporate printer.
  **Fix:** refresh the printer group whenever the print estate changes.

## D. Printer groups

### Print-to-PDF/XPS (print to file) isn't being restricted
- **Universal / print-to-file class not covered.** Physical-printer rules don't automatically cover
  print-to-file. **Fix:** ensure the **universal / print-to-file** class is in scope of the restriction (not
  just physical printers) — this is a common quiet exfiltration gap.

### A printer lands in the wrong group
- **Ambiguous match (name vs IP vs USB ID).** Overlapping group definitions. **Fix:** tighten the group
  membership criteria so each printer resolves to exactly one group; validate with
  `DLPPRINT-Validation.ps1`.

## E. Enforcement / user experience

### Users see no policy tip or override prompt
- **Still in simulation.** Tips/overrides only appear once the policy is **enforced** (unless "simulation
  with policy tips" is selected). **Fix:** confirm mode with `DLPPRINT-Discovery.ps1` (`Test*` = simulation,
  `Enable` = enforce); move the ring to enforce when ready.
- **Policy-tip / override not configured.** **Fix:** set `DLP Notice – Print – Standard` text and enable
  allow-override-with-justification in the rule's user-experience settings.

### Enforcement leaked outside the pilot ring
- **Scope not limited to the ring.** **Fix:** `DLPPRINT-Validation.ps1` shows the scoped identities; set the
  included scope to `DLP Pilot Ring – Stage1` only (config helper `-SetScope`), all others excluded.

### A hard block is stopping essential printing
- **Escalated too fast / wrong printer group.** **Fix:** immediate rollback — set the policy back to
  **simulation** (single setting, no data change), or relax the affected **printer group** to *block with
  override* / *audit*; re-tune before re-escalating.

## F. Alerts / operations

### Restricted prints don't raise alerts (or no one sees them)
- **Alert not enabled / no triage owner.** **Fix:** confirm the rule's **alert** is on and severity set;
  assign the `DLP Alerts – Print – Operations` owner/queue (Req 2.7). A restricted print with no triage is
  not a control.
- **SIEM forwarding not wired.** **Fix:** confirm the Office 365 Management Activity API / Defender
  connector to Sentinel is configured if forwarding is required.

### Reports show rising overrides
- **Detector or printer groups mis-calibrated, or users bypassing.** **Fix:** review override justifications
  in `DLPPRINT-Report.ps1`; if legitimate, calibration is fine; if routine bypass, tighten the detector or
  printer groups, or escalate the action per compliance.

---
## Escalation checklist
1. `DLPPRINT-EndpointReadiness.ps1` — licensed, devices onboarded/reporting, Print activity available?
2. `DLPPRINT-Discovery.ps1` — policy exists, Devices-only, correct mode (Test* vs Enable), Print restriction set?
3. `DLPPRINT-Validation.ps1` — printer groups resolve, corporate group distinct, scope = intended identities?
4. `DLPPRINT-Report.ps1` — matches, false-positive rate, overrides, restricted printers as expected?
5. Still stuck → capture the print symptom and **verify the current Microsoft guidance** for Endpoint DLP
   Print behaviour (especially macOS / printer-group syntax) in your tenant before a fleet-wide change.


---


# 7. Best Practices — Print DLP (Microsoft Purview)

Field-proven recommendations for a print restriction that survives contact with real users.

## Design
- **Simulate before you enforce — always.** Print blocking is high-impact and visible. Build the policy in
  **simulation/audit**, measure real print volume and false positives, tune, and only then enforce. This is
  the single biggest predictor of whether the control stays on.
- **Key off precise detectors, not broad ones.** A print rule tied to a **sensitivity label** or a
  well-tuned **SIT** (right confidence + instance count) fires on the right documents; a broad, low-confidence
  SIT floods the help desk and gets the policy disabled. Prefer a **label condition** where content is
  already labelled.
- **Let compliance own the "what" and "how enforced."** Which categories must not be printed, and whether the
  action is audit / warn / block, are **compliance/privacy/legal determinations**. You configure and prove
  the control; you don't decide the policy.

## Printer groups
- **Allow the sanctioned path; restrict the rest.** Define `Printers – Corporate – Allowed` for the managed,
  locked-down queue and keep it at *allow/audit*, then focus enforcement on **network**, **local
  (USB/directly attached)**, and **universal / print-to-PDF/XPS** printing. Blocking *all* printing is almost
  never the requirement and guarantees pushback.
- **Keep printer groups current.** Printers move, get replaced, and change IPs. A stale group either misses a
  new risky printer or wrongly catches a moved corporate one. Review printer groups whenever the print estate
  changes and re-run **`DLPPRINT-Validation.ps1`**.
- **Watch print-to-PDF/XPS ("universal").** Printing to a file is a quiet exfiltration path that bypasses
  physical-printer controls entirely — make sure the universal/print-to-file class is covered by the
  restriction, not just physical printers.

## Detection & tuning
- **Tune against the simulation sample, one change at a time.** Raise confidence/instance count, add
  supporting keywords/proximity, or switch to a label condition — then re-simulate and re-measure. Changing
  several knobs at once hides which one helped.
- **Use EDM where pattern SITs over-match.** For structured data (customer/account numbers), **Exact Data
  Match** dramatically cuts false positives versus a regex SIT. Refresh the EDM data on cadence.
- **Set an honest false-positive threshold and hold to it.** Agree the acceptable rate with the business
  before enforcing, and don't move to block until the simulation sample meets it.

## Rollout
- **Pilot on a ring, then wave.** Prove enforcement on `DLP Pilot Ring – Stage1` with **block-with-override**
  first (a business escape hatch that still captures evidence), pass all three testing gates, then expand in
  waves — validating each. Never flip the whole tenant at once.
- **Escalate to hard block deliberately.** Move from *block with override* to *hard block* per printer group,
  one at a time, only where compliance requires it, re-validating after each. Keep documented exclusions.
- **Simulation is your instant rollback.** Setting the policy back to simulation removes enforcement
  immediately with no data change — the safety switch for any surprise after go-live.

## Operations
- **Triage means someone, not somewhere.** Assign `DLP Alerts – Print – Operations` to a real owner/queue,
  set severities, and (optionally) forward to Sentinel. A restricted print with no triage owner is not a
  control. Triage a real alert during the pilot to prove the workflow.
- **Review overrides, not just blocks.** If users are justifying overrides legitimately, the policy is
  calibrated; if they're bypassing routinely, the detector or printer groups need work. Report on overrides
  as a first-class signal.
- **Report on a schedule.** Run **`DLPPRINT-Report.ps1`** on a cadence to watch false-positive drift, new
  printers, and alert volume — catch drift before it becomes a ticket storm.

## Complementary control
- **Use sensitivity-label PRINT usage rights where labels exist.** For encrypted-labelled Office files,
  removing the **PRINT** usage right blocks printing regardless of endpoint or OS — a useful complement to
  Endpoint DLP for the highest-sensitivity content. Confirm the labeling design with the information-
  protection owner; don't change usage rights unilaterally.

## Automation & security
- **Run the scripts read-only first.** `DLPPRINT-Discovery` / `DLPPRINT-Validation` / `DLPPRINT-Report` /
  `DLPPRINT-EndpointReadiness` are read-only; the config helper defaults to **`-WhatIf`** — preview before
  `-Commit`, and it never leaves a policy in enforce.
- **Least privilege, no secrets.** Connect with the **least S&C PowerShell / Graph scopes** each task needs;
  never place credentials or tokens in scripts or source control.
- **Verify OS-dependent behaviour.** Windows print restriction is the most complete; **macOS print support
  and specific behaviours evolve — verify against current Microsoft guidance / your tenant** before relying
  on them fleet-wide.


---


# 8. Deliverables Summary — Print DLP (Microsoft Purview)

## Documentation
| Document | Purpose |
|---|---|
| Executive Summary | Business case and what's in the box |
| 1. Solution Overview | The print exfiltration gap, how Endpoint DLP's Print activity + printer groups close it, and the Assess→Design→Configure→Pilot(simulate)→Validate→Expand model |
| 2. Requirements Guide | Every print-DLP prerequisite with Verify / Implement-if-missing (category Purview GRs referenced, not duplicated): licensing, DLP roles, device onboarding, classification intent, printer groups, pilot ring, alert triage |
| Global Requirements (Purview) | Category-wide Purview prerequisites, published once |
| 3. Implementation Guide | Exact, ordered Purview portal + S&C PowerShell + Graph steps: detectors, printer groups, the Devices-only Print policy **in simulation**, tune, enforce to a ring, expand — each artifact named, with pass/fail gates + rollback |
| 5. Testing Guide | Validation procedures with pass/fail gates (readiness, simulation, enforcement) |
| 6. Troubleshooting Guide | Print-DLP issues by symptom → root cause → fix |
| 7. Best Practices | Field-proven recommendations for a print restriction that survives real users |

## PowerShell scripts (Security & Compliance PowerShell / Microsoft Graph)
| Script | What it does | Safety |
|---|---|---|
| `DLPPRINT-Discovery.ps1` | Posture assessment: existing DLP policies + mode, which scope the Devices/Endpoint location, any Print restriction already configured, built-in vs custom SIT coverage | Read-only |
| `DLPPRINT-Config.ps1` | Configuration/remediation helper: previews/creates the Devices-only Print policy + rule **in simulation mode**, and (with `-SetScope`) sets the pilot-ring include scope; never leaves a policy in enforce | Default `-WhatIf`; `-Commit` to write |
| `DLPPRINT-Validation.ps1` | Validates the policy shape: Devices-only, Print activity set, printer groups resolve, simulation vs enforce mode, scoped identities — the "is it built right" report | Read-only |
| `DLPPRINT-Report.ps1` | Exports print DLP activity (matches, overrides, printers, SIT/label, confidence) over N days from the audit log for false-positive/alert review | Read-only |
| `DLPPRINT-EndpointReadiness.ps1` | Scope/health helper: onboarded-device readiness and licensing signals for the Devices location and the Print activity | Read-only |

## What the buyer receives
- This implementation guide as a branded **Word** document and **PDF**.
- All five **PowerShell scripts** in a single ZIP.
- A repeatable process: **Assess → Design → Configure → Pilot (simulate) → Validate → Expand.**

## Outcome
Printing of sensitive documents is **controlled by policy** on onboarded endpoints — proven in **simulation**
first, tuned to a low false-positive rate, enforced from a pilot ring outward, with **corporate printing
still allowed**, restricted prints **audited and alerted**, and the whole control **defensible and
evidenced** in Microsoft Purview. Regulatory/records/legal determinations remain with the relevant
governance functions; this package delivers the technical method and the proof.
