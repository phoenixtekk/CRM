# Endpoint DLP for macOS — Microsoft Purview

> **Version 1.0.0** · Category: Purview · Solution code: DLPMAC

> This is the online, maintained copy of the implementation guide. When this solution is updated, eligible customers are alerted and can return here for the current content. Downloadable PDF + scripts are attached on the store listing.



---


# Executive Summary — Endpoint DLP for macOS (Microsoft Purview)

Data Loss Prevention programs are often built for Windows and the cloud — and leave **Macs as the
blind spot**. The same sensitive content that is blocked from leaving a Windows PC can walk off a Mac
over a USB drive, a browser upload, a network copy, the clipboard, or a print job. That is a
compliance gap and a real data-risk exposure. The fix does not require a new product: **Microsoft
Purview Endpoint DLP** already extends to **macOS**, in the tenant and policy engine you run today.

This solution delivers macOS Endpoint DLP end to end: **onboarding** Macs into Purview device
management (via **Intune** or **Jamf Pro**), configuring the shared **Endpoint DLP settings**, and
building a **DLP policy** that monitors and controls the key **egress channels** on the Mac —
piloted in **simulation / test (Audit)** first, validated in **Activity Explorer**, and only then
**enforced** on a controlled scope. It is written for an administrator with no prior macOS
Endpoint-DLP experience.

## What you get
- A plain-language **Solution Overview** of how macOS Endpoint DLP works — onboarding, the
  system/network extensions and Full Disk Access, the egress channels, and the simulation-first model.
- A **Requirements Guide** with verify / implement-if-missing for every prerequisite (the category
  Purview requirements — licensing, roles, toolchain, classification intent, stakeholders, pilot — are
  referenced, not repeated).
- An **Implementation Guide** of precise, ordered **Purview + Intune + Security & Compliance
  PowerShell** steps: onboard the Macs, set Endpoint DLP settings, create the policy **in
  test/simulation**, pilot, validate, then enforce — each object named, with pass/fail gates and a
  one-command rollback.
- Five **PowerShell scripts** for readiness discovery, safe policy creation (`-WhatIf`, test-mode
  only), validation, Activity-Explorer reporting, and an onboarding/scope health check.
- **Testing** and **Troubleshooting** guides for a confident rollout.

## What this delivers
macOS endpoints **onboarded** to Purview and **watched** across cloud/browser upload, USB, network
share, clipboard, print, and restricted-app access — **audited in simulation**, **validated** with
evidence, and **enforced** (Block) on the channels compliance approves, in waves. The Mac blind spot is
closed inside the DLP program you already own.

## The deployment model
**Assess → Design → Configure → Pilot (simulate) → Validate → Expand (enforce)** — build onboarding and
the policy, prove them silently on a handful of Macs, then enforce and roll out in waves.

## An honest note
macOS Endpoint DLP support is a **subset of Windows** and is **evolving** (limited to the three latest
major macOS versions); onboarding requires real endpoint work (extension approval + Full Disk Access
via MDM). Enforcement is **high-impact** — hence simulation-first with a documented rollback. **Which**
data is regulated and **what** must be blocked are **compliance, records, and legal** determinations;
this package provides the technical configuration and the evidence, not the determination — and flags
**"verify your licensing / tenant / macOS version"** wherever availability is plan- or version-
dependent.

## Outcome
A macOS fleet inside your **Microsoft Purview** DLP program — onboarded, monitored across the key
egress channels, piloted in simulation, validated, and enforced on a controlled scope: a closed blind
spot that is configured, evidenced, and defensible.


---


# 1. Solution Overview — Endpoint DLP for macOS (Microsoft Purview)

## What this solution is
This solution extends **Microsoft Purview Endpoint Data Loss Prevention (Endpoint DLP)** to **macOS
devices**. It covers the whole path: **onboarding** Macs into Microsoft Purview device management,
configuring the **Endpoint DLP settings** and a **DLP policy** that monitors and controls **egress
channels** on the Mac (cloud/browser upload, USB removable media, network share, clipboard, print,
and access by unallowed apps) — piloting the policy in **simulation / test mode** first, validating
what it would catch, and only then moving to **enforce** on a controlled scope.

Mac endpoints are frequently the **blind spot** in a DLP program: the same sensitive content that is
blocked from leaving a Windows PC can walk out on a Mac over USB, a browser upload, or a network
copy. This package closes that gap in Purview, the same tenant and policy engine you already use — no
third-party endpoint DLP product.

It is **vendor-neutral** on the management plane: macOS onboarding is authored for both **Microsoft
Intune** and **Jamf Pro** at the pattern level, with the Intune path given step-by-step and the Jamf
equivalent named and deferred to Jamf's documentation for its console specifics.

## The macOS Endpoint DLP model in one paragraph
Endpoint DLP works by **onboarding** a device so a management/monitoring agent reports device
activity to Microsoft Purview. On macOS this agent relies on macOS **system and network extensions**,
a **Full Disk Access** grant, and an **onboarding package** delivered by your MDM (Intune or Jamf).
Once a Mac is onboarded and appears in Purview **device onboarding**, a **DLP policy** scoped to the
**Devices (Endpoint)** location applies to it. The policy's **rules** detect sensitive content (by
sensitive information type, sensitivity label, or other conditions) and apply **endpoint
restrictions** to egress activities — **Audit**, **Warn/Block with override**, or **Block**. Global
behavior (which browsers are approved, which apps are "unallowed", which cloud domains are
sensitive/approved, path exclusions) lives in **Endpoint DLP settings** and is shared by all endpoint
policies.

> **Licensing / plan note (verify your licensing/tenant).** Endpoint DLP is part of **Microsoft
> Purview Data Loss Prevention** and is licensed with **Microsoft 365 E5 / E5 Compliance** (or
> equivalent). macOS Endpoint DLP support and the exact set of monitored activities are **evolving and
> version-dependent** — Microsoft supports Endpoint DLP on the **three latest major macOS releases**.
> Confirm current macOS support, licensing, and per-activity availability against Microsoft's public
> documentation and your tenant before relying on any specific control.

## Egress channels this solution targets on macOS
macOS Endpoint DLP can monitor and restrict a **subset** of the endpoint activities available on
Windows. The channels this solution configures (each **verify current support for your macOS
version**):

- **Cloud / browser upload** — uploading sensitive files to a **cloud service domain** from a browser,
  and uploading from an **unallowed / non-approved browser**. Coverage of **service domains** and
  **sensitive service domains** on non-Edge browsers (Chrome, Firefox) requires the **Microsoft
  Purview browser extension**; Edge is supported without an add-on.
- **USB / removable media** — copying sensitive files to a USB or other removable drive.
- **Network share** — copying sensitive files to a network share.
- **Clipboard** — copying sensitive content to the clipboard (paste into another app/browser).
- **Print** — printing sensitive files.
- **Unallowed apps / restricted app groups** — access to sensitive files by apps you designate as
  restricted (e.g. personal cloud-sync or messaging apps).

For each channel the DLP rule sets an **action**: **Audit** (log only — the safe pilot default),
**Block with override / Warn** (user can justify), or **Block** (hard stop). This solution pilots at
**Audit / simulation** and only tightens to Block after validation.

## What is authored exactly vs deferred
- **Exact navigation is given** for the **Microsoft Purview portal** (`purview.microsoft.com`) —
  **Device onboarding**, **Endpoint DLP settings**, and **Data Loss Prevention → Policies** — and for
  the **Intune** onboarding path and **Security & Compliance PowerShell** (`Connect-IPPSSession`)
  automation.
- **Jamf Pro** onboarding is integrated at the **pattern level** — where a step (deploy onboarding
  package, approve system/network extensions, grant Full Disk Access via a PPPC/TCC profile) is a Jamf
  console action, this solution names the action and defers the Jamf specifics to Jamf's
  documentation.
- **Records/retention/legal/regulatory determinations** — *which* data is regulated, *what* must be
  blocked vs merely audited, and *whether* a given activity is permissible — are **deferred to the
  organization's compliance, privacy, records, and legal functions**. This solution delivers the
  **technical configuration and the evidence**, not the policy determination.
- **Purview is evolving and licensing-dependent** — where a control's availability on macOS is
  version- or plan-dependent, this package flags **"verify your licensing / tenant / macOS version"**
  rather than asserting it.

## Benefits
- **Closes the Mac blind spot** — the same Purview DLP engine now watches egress on macOS, not just
  Windows and cloud.
- **One policy plane** — Macs are governed by DLP policies in the tenant you already run; no separate
  endpoint-DLP product.
- **Safe by construction** — every policy is piloted in **simulation / test (Audit)** first, validated
  in Activity Explorer, then enforced — high-impact blocking is never flipped on blind.
- **Evidenced** — Activity Explorer and the provided reporting script show exactly what the policy
  would catch (and later, blocks), so the control is **defensible**.
- **Automatable & safe** — Security & Compliance PowerShell / Graph scripts are read-only or run in
  **-WhatIf / test mode** by default, with no credentials in code.

## Limitations (be honest with buyers)
- **macOS support is a subset and evolving.** Not every Windows Endpoint DLP activity exists on macOS,
  and support is limited to the **three latest major macOS versions** — **verify current coverage**.
- **Onboarding is real endpoint work.** macOS requires **system/network extension approval**, **Full
  Disk Access**, and an **onboarding package** via MDM — a misconfigured extension/TCC profile means
  the Mac never reports and the policy silently does nothing.
- **Determinations are not ours.** What to block, what is regulated, and whether an activity is allowed
  are **compliance/records/legal** decisions — this package configures and evidences, it does not
  decide.
- **Enforcement is high-impact.** A Block rule can interrupt legitimate work — hence **simulation →
  Audit → Block** with pass/fail gates and a documented rollback.

## The standard deployment model
> **Assess** the Mac fleet and in-scope data → **Design** the onboarding + policy + endpoint settings →
> **Configure** onboarding and a DLP policy in **test/simulation (Audit)** → **Pilot** on a handful of
> onboarded Macs → **Validate** in Activity Explorer against pass/fail gates → **Expand** and only then
> move rules to **Block (enforce)** in waves.
> Pattern: **Assess → Design → Configure → Pilot (simulate/test) → Validate → Expand (enforce)**, with
> explicit pass/fail gates and a documented rollback.


---


# 2. Requirements Guide — Endpoint DLP for macOS (Microsoft Purview)

Verify **every** requirement before configuring. Each entry: **Description · Why required · How to
verify · How to implement if missing.** Category-wide Purview prerequisites (a tenant with the right
**compliance licensing**, least-privilege **Purview roles**, the **Security & Compliance PowerShell /
Graph toolchain**, **in-scope data/classification**, **compliance/records/privacy/legal stakeholders**,
and a **pilot scope + change control with simulation/test mode**) are in
`global-requirements-purview.md` — confirm those **first**; this guide adds the macOS Endpoint DLP
specifics and does not duplicate the six.

> **Object names used throughout (use verbatim):**
> DLP policy `Endpoint DLP - macOS - Pilot` (and `Endpoint DLP - macOS - Prod`);
> DLP rule `macOS Egress - Sensitive Content`;
> macOS onboarding configuration (Intune) `Purview DLP - macOS Onboarding`;
> restricted app group (Endpoint DLP settings) `macOS - Restricted Apps`;
> approved/sensitive cloud-domain intent recorded in **Endpoint DLP settings → Sensitive service
> domains / Browser and domain restrictions**;
> policy **Mode** progression `TestWithoutNotifications` → `TestWithNotifications` → `Enable`.

## 2.1 Endpoint DLP licensing (E5 / E5 Compliance) — category G1
**Description:** The tenant is licensed for **Microsoft Purview Data Loss Prevention including Endpoint
DLP** — **Microsoft 365 E5** or the **E5 Compliance** add-on (or equivalent).
**Why required:** Endpoint DLP is a premium DLP capability; without the plan the **Devices**
location and endpoint restrictions are unavailable. *(Verify your licensing/tenant.)*
**How to verify:** Purview portal → **Data Loss Prevention** is available and a policy can select the
**Devices** location; M365 admin center shows the subscription/add-on.
**How to implement if missing:** Assign/purchase the required licensing before starting.

## 2.2 Least-privilege Purview / DLP roles (category G2)
**Description:** An operator in a least-privilege Purview role that can manage DLP — e.g.
**Compliance Administrator** or **Compliance Data Administrator** / **DLP Compliance Management**, plus
**Information Protection** where labels are involved. Device onboarding + Activity Explorer viewing
require the corresponding compliance roles.
**Why required:** Purview uses fine-grained role groups; creating policies, editing Endpoint DLP
settings, and onboarding devices each require the matching role.
**How to verify:** Purview portal → **Settings → Roles & scopes / Permissions** shows the role
membership; the operator can open **Data Loss Prevention** and **Device onboarding**.
**How to implement if missing:** Assign the least-privilege role group under change control (Global
Administrator only where genuinely required).

## 2.3 Security & Compliance PowerShell + Graph toolchain (category G3)
**Description:** A workstation with **Security & Compliance PowerShell** (`Connect-IPPSSession` via the
**ExchangeOnlineManagement** module) and, for the onboarding/health helper, **Microsoft Graph
PowerShell** — signed in as a modern-auth / MFA-capable admin.
**Why required:** The DLP policy/rule automation and reporting run through Security & Compliance
PowerShell; the onboarding scope check uses Graph against Intune.
**How to verify:** `Connect-IPPSSession` and `Connect-MgGraph` both succeed; **`DLPMac-Discovery.ps1`**
runs read-only.
**How to implement if missing:** `Install-Module ExchangeOnlineManagement` and
`Install-Module Microsoft.Graph`; confirm modern-auth sign-in before running steps.

## 2.4 Supported macOS versions in scope
**Description:** The target Macs run a **supported macOS release** — Microsoft supports Endpoint DLP on
the **three latest major macOS versions** *(verify current support)*.
**Why required:** The DLP system/network extensions and monitored activities are tied to supported
macOS versions; older releases are unsupported and may not report.
**How to verify:** Confirm the fleet's macOS versions against Microsoft's current supported list;
**`DLPMac-Onboarding-Check.ps1`** reports macOS device OS versions from Intune.
**How to implement if missing:** Update Macs to a supported macOS version before onboarding.

## 2.5 An MDM to deliver onboarding (Intune or Jamf Pro)
**Description:** A managed path to deploy the **onboarding package**, the **system/network extension**
approvals, and the **Full Disk Access (PPPC/TCC)** profile to Macs — **Microsoft Intune** (authored
step-by-step) or **Jamf Pro** (pattern-level, deferred to Jamf docs).
**Why required:** macOS will not load the DLP extensions or grant Full Disk Access silently — these are
delivered as MDM configuration profiles; without MDM you cannot reliably onboard at scale.
**How to verify:** Macs are enrolled in Intune (or Jamf) and can receive configuration profiles;
**`DLPMac-Onboarding-Check.ps1`** lists managed macOS devices.
**How to implement if missing:** Enroll the Macs in Intune or Jamf first (a separate prerequisite),
then return here.

## 2.6 macOS devices onboarded to Microsoft Purview device management
**Description:** The pilot Macs are **onboarded** and appear in Purview **Device onboarding** as
reporting devices (this is what makes an endpoint-scoped DLP policy apply to them).
**Why required:** A DLP policy scoped to **Devices** only affects **onboarded** devices; an un-onboarded
Mac is invisible to Endpoint DLP and the policy silently does nothing on it.
**How to verify:** Purview portal → **Settings → Device onboarding → Devices** lists the Macs as
onboarded/active *(verify the exact portal path for your tenant)*. There is no supported Security &
Compliance PowerShell cmdlet that enumerates onboarded devices — confirm in the portal.
**How to implement if missing:** Onboard via Intune (Implementation Phase 1) or Jamf; confirm the Mac
reports in device onboarding before scoping the policy.

## 2.7 macOS system/network extension + Full Disk Access approved
**Description:** The macOS **system extension** and **network (content-filter) extension** are
**approved**, and **Full Disk Access** is granted to the DLP/Defender agent via a **PPPC/TCC**
configuration profile.
**Why required:** Without extension approval and Full Disk Access, the Mac cannot inspect file activity
or egress — the agent installs but reports nothing, so the policy appears to "not work".
**How to verify:** On a pilot Mac, **System Settings → Privacy & Security** shows the extension allowed
and Full Disk Access granted; the device reports activity in Activity Explorer after a test action.
**How to implement if missing:** Deploy the system-extension allow-list, network-extension, and
PPPC/Full-Disk-Access profiles via Intune (Phase 1) or Jamf; these must be **pushed by MDM**, not
clicked per device, for a silent rollout.

## 2.8 The Microsoft Purview browser extension for non-Edge browsers (cloud egress)
**Description:** For **cloud/service-domain** coverage in **Chrome / Firefox** on macOS, the
**Microsoft Purview extension** is deployed; **Microsoft Edge** is supported without an add-on.
**Why required:** Sensitive-service-domain and "unallowed browser" controls on non-Edge browsers depend
on the extension; without it, uploads via Chrome/Firefox are not evaluated for those controls.
**How to verify:** The extension is present/forced in the target browsers (via Intune/Jamf browser
policy); a test upload from Chrome/Firefox is evaluated.
**How to implement if missing:** Force-install the Purview extension in the in-scope browsers, or
restrict cloud-egress testing to Edge for the initial pilot.

## 2.9 In-scope sensitive data + classification intent (category G4)
**Description:** The **sensitive content** the policy detects — **sensitive information types (SITs)**,
**sensitivity labels**, and/or keyword/EDM conditions — agreed with data owners, and which **egress
channels** matter for the Mac fleet.
**Why required:** A DLP rule keys off *what* is sensitive; without an agreed detection basis the policy
either over-triggers (noise) or misses (gap). The classification determination is a governance input.
**How to verify:** A named list of SITs/labels/conditions and the target egress channels exists and is
signed off by data owners.
**How to implement if missing:** Work with compliance/data owners to define the detection basis
(category G4/G5) before authoring the rule.

## 2.10 Endpoint DLP settings baseline (restricted apps, domains, exclusions)
**Description:** The tenant-wide **Endpoint DLP settings** relevant to macOS — **restricted app groups**
(`macOS - Restricted Apps`), **sensitive/approved service domains**, **browser & domain
restrictions**, and **file-path exclusions** — are reviewed and set to the pilot intent.
**Why required:** These global settings are shared by all endpoint DLP policies; they control which
browsers/apps/domains the rules act on. Wrong exclusions = false negatives; missing restricted-app
groups = the app rule can't reference them.
**How to verify:** Purview portal → **Data Loss Prevention → Endpoint DLP settings** reflects the
intended app groups, domains, and exclusions; **`DLPMac-Validation.ps1`** flags a rule that references
a group not present.
**How to implement if missing:** Configure the settings in Implementation Phase 2 before enabling the
rule's app/domain restrictions.

## 2.11 Pilot scope + change control with simulation/test mode (category G6)
**Description:** A small **pilot set** of onboarded Macs, a **change-control** window, and use of the
DLP policy's **test/simulation mode** (`TestWithoutNotifications` → `TestWithNotifications`) **before**
`Enable` (enforce). Endpoint DLP blocking is high-impact.
**Why required:** Every Purview solution follows **Assess → Design → Configure → Pilot (simulate) →
Validate → Expand (enforce)**; a Block rule can interrupt legitimate work, so it is validated in
simulation/Audit first.
**How to verify:** A named pilot Mac set, an approval window, and the policy created in a **test** mode
(not `Enable`) exist; **`DLPMac-Discovery.ps1`** reports each endpoint policy's Mode.
**How to implement if missing:** Define the pilot and agree change control; create the policy in
`TestWithoutNotifications` first (Implementation Phase 3).

---
## Checklist
- [ ] Endpoint DLP licensing (E5 / E5 Compliance) confirmed (2.1 / category G1)
- [ ] Least-privilege Purview/DLP role on the operator (2.2 / category G2)
- [ ] Security & Compliance PowerShell + Graph toolchain working (2.3 / category G3)
- [ ] Fleet on a supported macOS version (three latest major) (2.4)
- [ ] MDM (Intune or Jamf) able to deliver onboarding + profiles (2.5)
- [ ] Pilot Macs onboarded and visible in Purview device onboarding (2.6)
- [ ] System/network extension approved + Full Disk Access granted (2.7)
- [ ] Purview browser extension deployed for Chrome/Firefox cloud egress (2.8)
- [ ] In-scope SITs/labels/conditions + target egress channels agreed (2.9 / category G4)
- [ ] Endpoint DLP settings baseline (restricted apps, domains, exclusions) set (2.10)
- [ ] Pilot scope + change control + policy in test/simulation mode (2.11 / category G6)


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


# 3. Implementation Guide — Endpoint DLP for macOS (Microsoft Purview)

Follow these steps **in order**. The **Microsoft Purview portal**, the **Intune** onboarding path, and
the **Security & Compliance PowerShell** automation are given click-by-click / cmdlet-exact. **Jamf
Pro** onboarding is named and deferred to Jamf's documentation for its console specifics. Category
Purview prerequisites (licensing, roles, toolchain, classification intent, stakeholders, pilot/change
control) are assumed confirmed (Requirements + `global-requirements-purview.md`).

Consoles used:
- **Microsoft Purview portal** — `https://purview.microsoft.com` (Device onboarding, Endpoint DLP
  settings, Data Loss Prevention → Policies)
- **Microsoft Intune admin center** — `https://intune.microsoft.com` (macOS onboarding + extension /
  Full Disk Access profiles)
- **Jamf Pro** — deferred to Jamf documentation for the equivalent profiles
- **Security & Compliance PowerShell** — `Connect-IPPSSession`

> **Model:** Onboard the Macs, configure the endpoint settings, create the DLP policy **in
> test/simulation (Audit)**, pilot on a few onboarded Macs, validate in Activity Explorer, then move
> rules to **Block (enforce)** in waves. **Assess → Design → Configure → Pilot (simulate) → Validate →
> Expand (enforce).**

> **Artifact names (use verbatim):** onboarding config (Intune) `Purview DLP - macOS Onboarding`; DLP
> policy `Endpoint DLP - macOS - Pilot` (later `Endpoint DLP - macOS - Prod`); DLP rule
> `macOS Egress - Sensitive Content`; restricted app group `macOS - Restricted Apps`.

> **Risk + rollback (read first):** Endpoint DLP **Block** actions can interrupt legitimate work
> (blocked USB copy, blocked upload, blocked print). This solution therefore creates the policy in
> **`TestWithoutNotifications`** (silent simulation / Audit) and only advances to `Enable` after
> validation. **Rollback:** set the policy **Mode** back to `TestWithoutNotifications` (or `Disable`)
> to stop enforcing immediately (`Set-DlpCompliancePolicy -Mode`); un-scope by removing the **Devices**
> location; fully stop by disabling the policy. Onboarding is reversible by **off-boarding** the device
> in Purview / removing the MDM profiles. Regulatory/records/legal determinations remain with the
> relevant governance functions — this guide configures the technical control.

---

## Phase 1 — Onboard macOS devices to Microsoft Purview

### Step 1 — Get the macOS onboarding package from Purview
1. Purview portal → **Settings → Device onboarding** *(verify the exact path for your tenant; the
   onboarding blade has moved between the compliance portal and the new Purview portal)*.
2. Choose **macOS** and the **deployment method** — **Intune** or **Jamf** — and **download the
   onboarding package** (a configuration payload / `.mobileconfig` / onboarding blob).
3. Note that onboarding for Endpoint DLP on macOS uses the same device-onboarding pipeline as Microsoft
   Defender for Endpoint; if MDE is already deployed on the Mac, the extensions may be shared —
   **verify against current Microsoft guidance for your tenant**.

### Step 2 — Deploy onboarding + required profiles via Intune
Create these in Intune → **Devices → macOS → Configuration** (name the onboarding one
`Purview DLP - macOS Onboarding`) and assign to the **pilot Mac group**:
1. **Onboarding package** — upload the payload from Step 1 as a **configuration profile** (custom /
   `.mobileconfig`).
2. **System extension** — a **System Extensions** profile that **allows** the DLP/Defender extension
   (team identifier / bundle IDs per Microsoft's macOS deployment docs).
3. **Network extension** — a **content-filter / network extension** profile so egress can be inspected.
4. **Full Disk Access (PPPC/TCC)** — a **Privacy Preferences Policy Control** profile granting **Full
   Disk Access** to the agent so it can see file activity.
5. **(Optional) Background/Notifications** profiles per Microsoft's macOS guidance.
6. Assign all profiles to the **pilot Mac group** and let them apply.

> **Jamf path (deferred):** deploy the same four payloads — onboarding package, **System Extensions**
> allow, **Content Filter / network** extension, and **PPPC (Full Disk Access)** — via Jamf **Configuration
> Profiles**. The payload contents are Microsoft's; the Jamf console steps are deferred to Jamf's docs.

### Step 3 — Confirm the Macs are onboarded
1. Purview portal → **Settings → Device onboarding → Devices** — the pilot Macs appear as
   **onboarded/active** *(verify path)*.
2. On a pilot Mac, **System Settings → Privacy & Security** shows the extension **allowed** and **Full
   Disk Access** granted.
3. Run **`DLPMac-Onboarding-Check.ps1`** — it reports managed macOS devices, OS versions, and whether
   the onboarding/extension configuration profiles are present in Intune.
4. **Pass/fail gate:** at least the pilot Macs are onboarded and show the extension + Full Disk Access.
   Do **not** proceed until Macs report — a policy on an un-onboarded Mac does nothing.

---

## Phase 2 — Configure Endpoint DLP settings (shared, tenant-wide)

### Step 4 — Set the Endpoint DLP settings baseline
Purview portal → **Data Loss Prevention → Endpoint DLP settings**. Review/set (to the pilot intent
agreed with data owners — determinations remain theirs):
1. **Restricted apps and app groups** — create the app group `macOS - Restricted Apps` listing the
   macOS apps you want to restrict access to sensitive files (e.g. personal cloud-sync / messaging
   apps, by bundle ID/name). The DLP rule references this group.
2. **Browser and domain restrictions to sensitive data** — set **unallowed browsers** (so sensitive
   files can't upload via non-approved browsers) and confirm **Microsoft Edge** is the approved browser;
   deploy the **Purview browser extension** for Chrome/Firefox (Requirement 2.8).
3. **Sensitive service domains** — define the **service domain groups** (approved vs sensitive) that
   the cloud-egress control acts on.
4. **File path exclusions (macOS)** — add any macOS paths to exclude from monitoring (to cut noise),
   being careful not to exclude paths that would create a gap.

> These settings are **shared by every endpoint DLP policy** — change them under change control.
> **`DLPMac-Validation.ps1`** flags a rule that references the `macOS - Restricted Apps` group if the
> group is absent.

---

## Phase 3 — Create the DLP policy in simulation/test (Audit) mode

### Step 5 — Create the endpoint-scoped DLP policy (test mode)
1. **Portal path:** Purview → **Data Loss Prevention → Policies → Create policy** → choose the data
   categories/custom, name it **`Endpoint DLP - macOS - Pilot`**, and select the **Devices** location
   **only** (turn off Exchange/SharePoint/OneDrive/Teams for this Mac-focused pilot).
2. On **Policy mode**, choose **Run the policy in simulation mode** (optionally with policy tips off) —
   this is the **`TestWithoutNotifications`** mode: it **audits/simulates** without user-visible tips or
   blocks.
3. **Automation (preferred, safe):** run **`DLPMac-Set-Policy.ps1`** — default **-WhatIf** (previews the
   `New-DlpCompliancePolicy` / `New-DlpComplianceRule` it would run); add **-Commit** to create the
   policy **in `TestWithoutNotifications`** and the rule with **Audit** endpoint restrictions:
   ```
   New-DlpCompliancePolicy -Name 'Endpoint DLP - macOS - Pilot' -EndpointDlpLocation All -Mode TestWithoutNotifications
   ```
   The script never creates the policy in `Enable` mode — enforcement is a deliberate later step.

### Step 6 — Add the egress rule (Audit actions first)
1. In the policy, **Create rule** `macOS Egress - Sensitive Content`.
2. **Conditions:** content is sensitive — the agreed **SIT(s) / sensitivity label(s) / conditions**
   (Requirement 2.9).
3. **Endpoint restrictions (start at Audit):** set each in-scope channel to **Audit** for the pilot:
   - **Upload to a cloud service / access by unallowed browser** → **Audit**
   - **Copy to a USB removable device** → **Audit**
   - **Copy to a network share** → **Audit**
   - **Copy to clipboard** → **Audit**
   - **Print** → **Audit**
   - **Access by restricted apps** (`macOS - Restricted Apps`) → **Audit**
   *(Only include channels supported on your macOS version — verify current support.)*
4. Save the rule. **`DLPMac-Set-Policy.ps1 -Commit`** creates this rule with **Audit** restrictions via
   `New-DlpComplianceRule -EndpointDlpRestrictions` — never Block on first creation.

### Step 7 — Confirm the policy is scoped and in test mode
1. Run **`DLPMac-Discovery.ps1`** — it lists the endpoint-scoped policy, confirms **Mode =
   TestWithoutNotifications** (flags anything in `Enable`), and lists the rule's egress restrictions.
2. Run **`DLPMac-Validation.ps1`** — confirms the policy targets **Devices**, is in a **test** mode, and
   the rule includes the intended channels + references a present restricted-app group.
3. **Pass/fail gate:** policy exists, **Devices**-scoped, **Mode = TestWithoutNotifications**, rule
   present with **Audit** actions. Do not advance until this passes.

---

## Phase 4 — Pilot, validate, then enforce

### Step 8 — Drive test activities on a pilot Mac and validate
1. On an onboarded pilot Mac, perform benign test egress with **non-production test content that
   matches the SIT** (e.g. a file with dummy test data): copy to USB, copy to a network share, upload
   from a browser, copy to clipboard, print, open with a restricted app.
2. Purview portal → **Activity Explorer** (or run **`DLPMac-Report.ps1`**, which uses
   `Export-ActivityExplorerData`) — the simulated/audited **Endpoint DLP** events for the Mac appear
   with the activity, app, and matched rule.
3. **Pass/fail gate (simulation):** every driven channel produces an **audited** event attributed to
   `Endpoint DLP - macOS - Pilot` / `macOS Egress - Sensitive Content`, and no unexpected volume of
   false positives. If a channel produces nothing, revisit onboarding/extensions (Phase 1) or the
   channel's macOS support before enforcing.

### Step 9 — Advance to notifications, then enforce (Block) — deliberately, in scope
Only after Step 8 passes and **compliance/records/legal sign off** the enforcement intent:
1. **`TestWithNotifications`** — move the policy to test **with** policy tips so pilot users see
   warnings (still no block): `Set-DlpCompliancePolicy -Identity 'Endpoint DLP - macOS - Pilot' -Mode
   TestWithNotifications`. Confirm tips appear on the Mac; gather user feedback.
2. **Enforce selectively** — change the rule's chosen channels from **Audit** to **Block** (or
   **Block with override / Warn**) for the channels compliance approved, and set the policy to
   **`Enable`**: `Set-DlpCompliancePolicy -Identity 'Endpoint DLP - macOS - Pilot' -Mode Enable`.
   Start with the **highest-risk, lowest-friction** channel (often USB) rather than all at once.
3. Re-run **`DLPMac-Report.ps1`** — confirm blocks/overrides are recorded as intended.
4. **Rollback if needed:** `Set-DlpCompliancePolicy -Mode TestWithoutNotifications` (back to silent
   simulation) reverts enforcement immediately on next sync.

### Step 10 — Expand to production in waves
1. Create the production twin **`Endpoint DLP - macOS - Prod`** (or widen the pilot policy's onboarded
   scope), starting again in **`TestWithoutNotifications`** for the newly onboarded Macs.
2. Onboard production Macs in **waves** (Phase 1) so each wave is validated in simulation before it is
   enforced.
3. Re-run **`DLPMac-Validation.ps1`** and **`DLPMac-Report.ps1`** after each wave; only advance the mode
   once the wave passes.

---
### Order of operations
`Onboard Macs (Intune/Jamf: package + system/network extension + Full Disk Access) → confirm onboarded →
Endpoint DLP settings (restricted apps, domains, exclusions) → create DLP policy Devices-scoped in
TestWithoutNotifications → add egress rule with Audit actions → discovery/validation confirm test mode →
drive test activities + validate in Activity Explorer → TestWithNotifications → enforce (Block) selected
channels on Enable → expand in waves (each starting in simulation)`


---


# 5. Testing Guide — Endpoint DLP for macOS (Microsoft Purview)

Run after the Macs are onboarded and the DLP policy is created **in test/simulation (Audit) mode**
(Implementation Phases 1–3), and again after each mode advance and expansion wave. Back each test with
**`DLPMac-Discovery.ps1`** / **`DLPMac-Validation.ps1`** / **`DLPMac-Report.ps1`** and the Purview
portal. **Use non-production test content** that matches the in-scope SIT — never real regulated data.

## Test 1 — Macs are onboarded and reporting
**Do:** Run **`DLPMac-Onboarding-Check.ps1`**; Purview portal → **Settings → Device onboarding →
Devices**.
**Expected:** The pilot Macs appear **onboarded/active**; the system/network extension is allowed and
Full Disk Access is granted on the device.

## Test 2 — DLP policy is Devices-scoped and in test/simulation mode
**Do:** Run **`DLPMac-Discovery.ps1`**.
**Expected:** `Endpoint DLP - macOS - Pilot` exists, targets the **Devices (Endpoint)** location
**only**, and **Mode = TestWithoutNotifications** (not `Enable`). Anything already in `Enable` is
flagged for review.

## Test 3 — The egress rule is present with the intended channels
**Do:** Run **`DLPMac-Validation.ps1`**.
**Expected:** Rule `macOS Egress - Sensitive Content` exists with the agreed **conditions** (SIT/label)
and the intended egress restrictions (cloud/browser, USB, network share, clipboard, print, restricted
apps), all at **Audit** for the pilot; the referenced restricted-app group `macOS - Restricted Apps`
exists.

## Test 4 — USB / removable media egress is audited
**Do:** On a pilot Mac, copy a test file (matching the SIT) to a USB drive.
**Expected:** An **audited** Endpoint DLP event for **copy to removable media** appears in Activity
Explorer / **`DLPMac-Report.ps1`**, attributed to the policy + rule. No block yet (Audit mode).

## Test 5 — Network-share copy is audited
**Do:** Copy the test file to a mounted network share.
**Expected:** An **audited** "copy to network share" event is recorded for the Mac.

## Test 6 — Cloud / browser upload is audited
**Do:** Upload the test file from an approved browser (Edge) and, if the Purview extension is deployed,
from Chrome/Firefox to a sensitive service domain.
**Expected:** An **audited** cloud-egress / unallowed-browser event appears. (If Chrome/Firefox produce
nothing, confirm the **Purview browser extension** — Requirement 2.8.)

## Test 7 — Clipboard and print are audited
**Do:** Copy sensitive test content to the clipboard (and paste elsewhere); print the test file.
**Expected:** **Audited** clipboard and print events are recorded (subject to current macOS support for
those channels).

## Test 8 — Restricted-app access is audited
**Do:** Open the test file with an app listed in `macOS - Restricted Apps`.
**Expected:** An **audited** "access by restricted app" event is recorded.

## Test 9 — Notifications appear in TestWithNotifications
**Do:** After passing Tests 4–8, advance the policy to **`TestWithNotifications`**
(`Set-DlpCompliancePolicy -Mode TestWithNotifications`) and repeat one egress action.
**Expected:** A **policy tip / notification** appears to the user on the Mac; still **no block**.

## Test 10 — Enforcement blocks the selected channel(s)
**Do:** After compliance/legal sign-off, set the chosen channel(s) to **Block** and the policy to
**`Enable`**; repeat the action for an enforced channel and for a non-enforced one.
**Expected:** The **enforced** channel is **blocked** (or blocked-with-override) and recorded;
non-enforced channels remain audited. **`DLPMac-Report.ps1`** shows the block/override events.

## Test 11 — Rollback reverts enforcement
**Do:** Set the policy back to **`TestWithoutNotifications`** and repeat the previously-blocked action.
**Expected:** The action is **no longer blocked** (silent simulation restored) on next sync —
confirming the documented rollback works.

---
## Pass/fail gate
| Gate | Requirement |
|---|---|
| **Onboarding pass** | Tests 1–3 pass (Macs onboarded/reporting; policy Devices-scoped in test mode; rule present) |
| **Simulation pass** | Tests 4–8 pass (each in-scope channel produces an audited event on the Mac) |
| **Enforcement pass** | Tests 9–11 pass (notifications, then Block on selected channels, and rollback all behave as intended) |

> Do not enforce (Block / `Enable`) until the **Simulation pass** gate is green and compliance/records/
> legal have signed off the enforcement intent. Re-run Tests 4–8 in simulation for every expansion wave
> before advancing that wave's mode.


---


# 6. Troubleshooting Guide — Endpoint DLP for macOS (Microsoft Purview)

Symptom → likely root cause → fix. Use **`DLPMac-Discovery.ps1`** (policy scope + Mode + egress
restrictions), **`DLPMac-Validation.ps1`** (pass/fail on scope + mode + channels),
**`DLPMac-Report.ps1`** (Activity Explorer evidence), and **`DLPMac-Onboarding-Check.ps1`**
(Intune-side onboarding/extension health) to confirm before and after each fix. Where a control's
availability on macOS is **version- or plan-dependent, verify against current Microsoft guidance / your
licensing / tenant** rather than assuming.

## A. Onboarding

### A Mac never shows any DLP activity (policy "does nothing")
- **Mac not onboarded.** Endpoint DLP only affects **onboarded** devices. **Fix:** confirm the Mac in
  Purview → **Settings → Device onboarding → Devices**; run **`DLPMac-Onboarding-Check.ps1`** to confirm
  the onboarding profile is deployed in Intune; onboard it (Implementation Phase 1) if absent.
- **System / network extension not approved.** Without the approved extension the agent can't inspect
  egress. **Fix:** deploy the **System Extensions** allow + **network/content-filter** profile via MDM;
  on the Mac, **System Settings → Privacy & Security** should show the extension allowed.
- **Full Disk Access not granted.** The agent can't see file activity without it. **Fix:** deploy the
  **PPPC/TCC (Full Disk Access)** profile via Intune/Jamf; verify it is granted on the Mac. These must
  be **pushed by MDM**, not clicked per device, for a silent rollout.

### Onboarding package deployed but the Mac still isn't "active"
- **Profiles not assigned / not yet applied.** **Fix:** confirm all four payloads (onboarding, system
  extension, network extension, Full Disk Access) are **assigned to the pilot Mac group** and have
  applied; force an MDM sync; re-check `DLPMac-Onboarding-Check.ps1`.
- **Unsupported macOS version.** Support is the **three latest major** releases. **Fix:** update macOS;
  the onboarding check flags clearly old majors (verify the current supported list).
- **MDE pipeline conflict / duplication.** macOS DLP shares onboarding with Defender for Endpoint.
  **Fix:** if MDE is already present, don't double-deploy conflicting extensions — **verify the shared
  configuration against current Microsoft guidance for your tenant.**

## B. Policy scope / mode

### The policy exists but nothing is audited on Macs
- **Policy not scoped to Devices.** A policy on Exchange/SharePoint/etc. won't touch endpoints. **Fix:**
  `DLPMac-Validation.ps1` FAILs if the **Devices (Endpoint)** location is missing — add it (or recreate
  with `-EndpointDlpLocation All` via `DLPMac-Set-Policy.ps1`).
- **Policy Disabled.** **Fix:** `DLPMac-Discovery.ps1` reports `Enabled`; enable the policy.
- **No rule / rule has no endpoint restrictions.** **Fix:** confirm `macOS Egress - Sensitive Content`
  exists with endpoint restrictions (`DLPMac-Discovery.ps1` lists them); add the channels at **Audit**.

### The policy is unexpectedly blocking users
- **Policy is in Enable (enforcing) prematurely.** **Fix (immediate rollback):**
  `Set-DlpCompliancePolicy -Identity 'Endpoint DLP - macOS - Pilot' -Mode TestWithoutNotifications` —
  reverts to silent simulation on next sync. `DLPMac-Validation.ps1` FAILs when a pilot policy is
  enforcing unexpectedly.
- **A channel was set to Block instead of Audit.** **Fix:** set the channel's action back to **Audit**
  in the rule; only Block after the simulation gate passes and compliance signs off.

## C. Channel coverage

### Cloud/browser upload isn't caught
- **Non-Edge browser without the Purview extension.** Service-domain controls on **Chrome/Firefox**
  need the **Microsoft Purview browser extension**; Edge is native. **Fix:** force-install the extension
  (Requirement 2.8), or test cloud egress from Edge for the initial pilot.
- **Sensitive service domains / browser restrictions not set.** These live in **Endpoint DLP settings**.
  **Fix:** configure **Sensitive service domains** and **Browser and domain restrictions** (Step 4).

### A specific channel (clipboard / print / network share) produces no events
- **Channel not supported on that macOS version, or not enabled in the rule.** macOS supports a
  **subset** of Windows channels and it **evolves**. **Fix:** confirm the channel is in the rule
  (`DLPMac-Validation.ps1` WARNs if an expected channel is missing) and **verify current macOS support**
  before concluding it's broken.

### Restricted-app control does nothing
- **`macOS - Restricted Apps` group missing or empty.** The rule's app control acts on the group in
  **Endpoint DLP settings**. **Fix:** create/populate the group (by bundle ID/name); `DLPMac-Validation.ps1`
  notes the dependency.

## D. Reporting / evidence

### `DLPMac-Report.ps1` returns no events
- **No activity driven / not yet propagated.** Endpoint events can lag. **Fix:** drive a test action
  with SIT-matching **test** content, wait, and re-run; widen with `-Days 30`.
- **Role lacks Activity Explorer export.** **Fix:** ensure the operator has the compliance role that
  permits `Export-ActivityExplorerData`.
- **Filter field names drifted.** The script retries without the workload filter; if still empty,
  **verify current Activity Explorer field names** against Microsoft guidance and review in the portal.

### Events show but none are tagged macOS
- **Platform field absent/normalised differently.** **Fix:** the report notes this; confirm the device
  platform in **Activity Explorer** directly (filter by device) rather than relying on the platform tag.

## E. Determinations (not a technical fix)
- **"Should this be blocked / is this regulated?"** These are **compliance, records, privacy, and
  legal** determinations, not endpoint-configuration questions. **Fix:** route to the relevant
  governance function; this solution configures and evidences the control once they decide.

---
## Escalation checklist
1. `DLPMac-Onboarding-Check.ps1` — Macs managed, supported macOS, onboarding/extension/PPPC profiles present?
2. Purview portal → **Device onboarding** — do the Macs show **onboarded/active**? (No cmdlet for this.)
3. `DLPMac-Discovery.ps1` — policy Devices-scoped, Mode = a **test** mode, rule egress restrictions listed?
4. `DLPMac-Validation.ps1` — PASS on scope + mode + intended channels + restricted-app group present?
5. `DLPMac-Report.ps1` — driven test activity appears as audited events attributed to the policy/rule?
6. Still stuck → capture the symptom and **verify current Microsoft guidance** for macOS Endpoint DLP
   support (version + channel + licensing) in your tenant before any fleet-wide change; keep enforcement
   in **TestWithoutNotifications** until resolved.


---


# 7. Best Practices — Endpoint DLP for macOS (Microsoft Purview)

Field-proven recommendations for a safe, defensible macOS Endpoint DLP rollout.

## Design
- **Simulation first, always.** Create every endpoint policy in **`TestWithoutNotifications`**
  (silent simulation / Audit). Blocking macOS egress is high-impact — validate what a policy *would*
  catch before it interrupts anyone. Advance **TestWithoutNotifications → TestWithNotifications →
  Enable** deliberately, one gate at a time.
- **Scope the Mac pilot by onboarding, not by guesswork.** Endpoint DLP applies to **onboarded**
  devices; control the pilot by onboarding only the pilot Macs first, and keep the policy on the
  **Devices** location only so you're testing macOS behavior in isolation.
- **Let compliance decide *what*, you deliver *how*.** Which content is regulated, what must be blocked
  vs merely audited, and whether an activity is permissible are **compliance/records/privacy/legal**
  determinations. Configure and evidence the control; don't invent the policy.
- **Detect on agreed signals.** Base rules on the **SITs/labels/conditions** data owners signed off —
  not a reflexive "block everything". Over-broad detection creates noise that buries real events.

## Onboarding
- **Push the extensions and Full Disk Access by MDM — never per device.** The macOS **system
  extension**, **network extension**, and **Full Disk Access (PPPC/TCC)** must arrive as MDM profiles
  (Intune or Jamf). A single missing profile means the Mac onboards but **reports nothing** — the
  quietest, most dangerous failure mode.
- **Verify onboarding before you trust the policy.** Confirm each pilot Mac in Purview **device
  onboarding** and drive a test activity that shows up in Activity Explorer **before** assuming the
  policy works. Run **`DLPMac-Onboarding-Check.ps1`** to confirm the profiles are deployed.
- **Reuse the Defender pipeline where present.** macOS Endpoint DLP shares onboarding with Microsoft
  Defender for Endpoint; if MDE is already deployed the extensions may be shared — **verify against
  current Microsoft guidance for your tenant** rather than double-deploying.
- **Stay on supported macOS.** Support is limited to the **three latest major macOS versions** — keep
  the fleet current, and re-verify channel support after a major macOS release.

## Policy and endpoint settings
- **Keep Endpoint DLP settings and rules in lockstep.** The rule's app restriction references the
  `macOS - Restricted Apps` group and its cloud control references your service-domain groups — if the
  group/domain settings drift, the rule acts on the wrong thing. Run **`DLPMac-Validation.ps1`** on
  every change.
- **Mind the browser boundary.** Edge is covered natively; **Chrome/Firefox need the Purview
  extension** for service-domain controls. If the extension isn't deployed, either deploy it or scope
  cloud-egress testing to Edge and say so — don't assume silent coverage.
- **Exclude paths with intent.** File-path exclusions cut noise but can create gaps; document each
  exclusion and why. Never exclude a path that would let regulated content leave unseen.

## Operations
- **Pilot on a few, then wave.** Prove onboarding + simulation on a handful of Macs, pass the gates,
  then expand in waves — each new wave starts in **simulation** before its mode advances.
- **Enforce the highest-risk, lowest-friction channel first.** USB copy is often the cleanest first
  Block; add channels one at a time, watching **`DLPMac-Report.ps1`** for false positives and override
  patterns.
- **Know the one-command rollback.** `Set-DlpCompliancePolicy -Mode TestWithoutNotifications` reverts
  enforcement to silent simulation immediately on next sync. Rehearse it so an over-blocking incident
  is a 30-second fix, not a fire drill.
- **Watch overrides and false positives.** A channel with many user overrides (Block-with-override) or
  false positives is a signal the detection or the channel choice needs tuning — treat it as data, not
  noise.

## Automation & security
- **Run read-only first, -WhatIf before -Commit.** `DLPMac-Discovery` / `DLPMac-Validation` /
  `DLPMac-Report` / `DLPMac-Onboarding-Check` are read-only; **`DLPMac-Set-Policy.ps1`** defaults to
  **-WhatIf** and, even with **-Commit**, only ever creates the policy in **test/simulation** mode —
  enforcement stays a manual, deliberate `Set-DlpCompliancePolicy` step.
- **Least privilege, no secrets.** Connect with the least Purview/Graph scopes each task needs
  (`Connect-IPPSSession` interactively; Graph read scopes for the onboarding check); never place
  credentials, tokens, or secrets in scripts or source control.
- **Evidence is the deliverable.** Export Activity Explorer results (via `DLPMac-Report.ps1`) as the
  audit trail that the control exists and works — this is what makes the macOS DLP posture
  **defensible** to auditors and regulators.


---


# 8. Deliverables Summary — Endpoint DLP for macOS (Microsoft Purview)

## Documentation
| Document | Purpose |
|---|---|
| Executive Summary | Business case and what's in the box |
| 1. Solution Overview | The macOS Endpoint DLP model, onboarding (Intune/Jamf), the egress channels, simulation-first rollout, what's exact vs deferred |
| 2. Requirements Guide | Every macOS Endpoint DLP prerequisite with Verify / Implement-if-missing (category Purview GRs referenced, not duplicated) |
| Global Requirements (Purview) | Category-wide Purview prerequisites, published once |
| 3. Implementation Guide | Exact, ordered Purview + Intune + Security & Compliance PowerShell steps: onboard macOS, endpoint DLP settings, DLP policy in test/simulation, pilot, validate, enforce; each object named, pass/fail gates + rollback |
| 5. Testing Guide | Validation procedures with pass/fail gates (onboarding → simulation → enforcement) |
| 6. Troubleshooting Guide | Onboarding, extension/Full-Disk-Access, policy-scope, channel-coverage, and enforcement issues by symptom → root cause |
| 7. Best Practices | Field-proven recommendations for a safe, defensible macOS DLP rollout |

## PowerShell scripts (Security & Compliance PowerShell / Microsoft Graph)
| Script | What it does | Safety |
|---|---|---|
| `DLPMac-Discovery.ps1` | Endpoint DLP readiness: lists DLP policies scoped to the **Devices** location, each policy's **Mode** (flags anything in `Enable`), and each rule's endpoint egress restrictions; advises verifying macOS onboarding in the portal | Read-only (`Connect-IPPSSession`) |
| `DLPMac-Set-Policy.ps1` | Creates the endpoint-scoped DLP policy **in `TestWithoutNotifications` (simulation)** and the `macOS Egress - Sensitive Content` rule with **Audit** endpoint restrictions; idempotent by name; never creates in `Enable` | Default `-WhatIf`; `-Commit` to write (test mode only) |
| `DLPMac-Validation.ps1` | Validates the policy targets **Devices**, is in a **test/simulation** mode, and the rule includes the intended egress channels and references a present restricted-app group | Read-only |
| `DLPMac-Report.ps1` | Exports **Endpoint DLP** activity from **Activity Explorer** (`Export-ActivityExplorerData`) for the Mac fleet — audited/blocked egress events by activity, app, and rule — the evidence trail | Read-only |
| `DLPMac-Onboarding-Check.ps1` | Scope/health helper (Graph): reports managed **macOS** devices + OS versions from Intune and whether the onboarding / extension / Full-Disk-Access configuration profiles are present; defers definitive onboarding status to the Purview portal | Read-only (`Connect-MgGraph`) |

## What the buyer receives
- This implementation guide as a branded **Word** document and **PDF**.
- All five **PowerShell scripts** in a single ZIP.
- A repeatable process: **Assess → Design → Configure → Pilot (simulate) → Validate → Expand (enforce).**

## Outcome
macOS endpoints brought into the **Microsoft Purview** DLP program: **onboarded**, watched across the
key **egress channels** (cloud/browser, USB, network share, clipboard, print, restricted apps),
**piloted in simulation**, **validated** in Activity Explorer, and **enforced** on a controlled scope —
a closed Mac blind spot that is configured, evidenced, and **defensible**, with regulatory/records/
legal determinations left to the relevant governance functions.
