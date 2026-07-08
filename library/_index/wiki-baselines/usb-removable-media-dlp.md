# USB & Removable-Media DLP — Microsoft Purview

> **Version 1.0.0** · Category: Purview · Solution code: DLPUSB

> This is the online, maintained copy of the implementation guide. When this solution is updated, eligible customers are alerted and can return here for the current content. Downloadable PDF + scripts are attached on the store listing.



---


# Executive Summary — USB & Removable-Media DLP in Microsoft Purview

## The problem

Removable media is the classic exfiltration path. A file copied to a **USB stick**, an SD card, or an
external drive walks out the door in a pocket — and server-side DLP (Exchange, SharePoint, OneDrive,
Teams) never sees it, because the copy happens entirely on the endpoint. Left unaddressed, that is
both a **compliance gap** and a direct **data-risk exposure**.

## The solution

This solution governs data to **USB and removable media** end to end in Microsoft Purview, using
**two complementary control layers** on onboarded devices:

- **Endpoint DLP — removable media (content-aware):** detects and acts on *copy a sensitive file to
  removable storage* — Audit / Warn / Block — keyed to your sensitive content (sensitivity labels
  and/or sensitive information types), with an allow-list for corporate-issued media.
- **Device control — removable-storage access (device-aware):** allows / audits / blocks read, write,
  or execute on removable storage **by device group**, independent of content — so unapproved USB
  devices can be blocked or made read-only regardless of what is on them.

Together they deliver *block / audit / allow **by policy*** for USB and removable media. Crucially,
the content layer is **piloted in simulation/test mode** and the device layer **audit-first** — each
records what it *would* do without blocking anyone — validated on a small device ring, and only then
moved to **enforce**.

## How it works — the model

The delivery follows a disciplined, repeatable model with an explicit pass/fail gate at each step:

**Assess → Design → Configure → Pilot (simulation/audit) → Validate → Expand (enforce).**

Because removable-media block and read-only actions stop work at the moment of the action, nothing is
enforced until it has been proven, in simulation/audit, to see the right activity and act only on the
right content and the right devices — with a fast rollback available at all times.

## What you get

- A complete document set: Overview, Requirements, an ordered Implementation guide, Testing
  (pass/fail gates), Troubleshooting, Best Practices, and this summary.
- **Five PowerShell tools** (Security & Compliance PowerShell / Microsoft Graph) — discovery,
  configuration (simulation, `-WhatIf` first), validation, reporting, and scope/health — all
  **read-only or preview by default, with no credentials in code.**
- A **defensibility evidence pack**: proof of what was configured across both layers, that each was
  validated in simulation/audit before enforcement, and that enforcement behaves as designed.

## Scope and boundaries

- Endpoint DLP and device control are **licensing-dependent** (typically Microsoft 365 E5 / E5
  Compliance / E5 Information Protection & Governance) and the Purview portal and device-control
  surfaces **evolve** — capability availability and exact paths are **verified against your
  licensing/tenant**, never assumed. Device-control policy deployment is a **management-tool** action
  (Intune / GPO / OMA-URI), not a Security & Compliance PowerShell cmdlet.
- **Regulatory, records, and legal determinations** — which data is sensitive, which devices are
  approved, and whether an action is a violation — remain with your **compliance, security, records,
  privacy, and legal** functions. This solution provides the **technical method and the evidence**,
  not the determination.

## The bottom line

The **classic USB exfiltration path** becomes a **monitored, then enforced** control set in Microsoft
Purview — content-aware and device-aware, **configured, piloted in simulation/audit, validated, and
defensible.**


---


# Solution Overview — USB & Removable-Media DLP in Microsoft Purview

## What this solution delivers

Removable media is the classic exfiltration path. A file copied to a **USB stick**, an SD card, or an
external drive walks out the door in a pocket — and server-side DLP (Exchange, SharePoint, OneDrive,
Teams) never sees it, because the copy happens entirely on the endpoint. This solution governs data
to **USB and removable media** end to end in Microsoft Purview, using **two complementary control
layers** on onboarded devices:

1. **Endpoint DLP — removable-media rules (content-aware).** Once a device is **onboarded** to
   Microsoft Purview, an Endpoint DLP policy can **see and control** the on-device activity *copy a
   matching file to removable media* — **Audit**, **Warn with override**, or **Block** — keyed to your
   **sensitive content** (sensitivity labels and/or sensitive information types), with an allow-list
   for **corporate-issued** media.
2. **Device control — removable-storage access control (device-aware).** Independently of content, a
   **device-control** policy can **allow / audit / block read, write, or execute** on removable
   storage **by device group** — so unapproved USB devices can be blocked (or made read-only)
   regardless of what is on them.

The two layers answer different questions. Endpoint DLP asks *"is this **content** sensitive?"* and
acts on the file; device control asks *"is this **device** approved?"* and acts on the medium. Used
together they deliver *block/audit/allow **by policy*** for USB and removable media — configured,
**piloted in simulation/test** where the capability supports it, validated, and defensible.

This solution walks a competent-but-novice administrator through the complete, repeatable
deployment:

1. **Confirm onboarding & prerequisites** — the device must be **onboarded to Microsoft Purview**
   before any removable-media activity is visible or controllable, and the licensing/roles must be in
   place.
2. **Define the removable-media vocabulary** — the **removable-storage device group(s)** that
   distinguish corporate/allowed media from everything else, plus file-path exclusions where needed.
3. **Author the controls in the safe mode first** — the Endpoint DLP removable-media rule(s) in
   **simulation/test mode** (nothing blocked), and the device-control policy in an **audit-first**
   posture — each keyed to the design.
4. **Validate, then enforce and expand** — prove, on a small pilot device ring, that the activity is
   *seen* and *would* act; then move rules from simulation to **enforce** (and device control from
   audit to block) deliberately, with an explicit pass/fail gate and a documented rollback at every
   step.

## The two control layers (how they differ)

| Layer | What it keys on | What it controls | Configured where |
|---|---|---|---|
| **Endpoint DLP — removable media** | **Content** (sensitivity label and/or sensitive info type) | The on-device activity *copy a matching file to a removable/USB device* — Audit / Warn / Block, **except** the corporate device group. | **Microsoft Purview → Data Loss Prevention** (a DLP policy on the **Devices** location, with the removable-media endpoint restriction). |
| **Device control — removable-storage access control** | **Device** (a removable-storage device group / device properties) | **Read / Write / Execute** on removable storage — Allow / Audit / Block by device group, **regardless of content**. | **Device-control policy** deployed to onboarded devices via your management tooling (e.g. Intune / Group Policy / OMA-URI) — **verify the exact surface and availability for your tenant**. |

> **Both require onboarding.** A device must be **onboarded to Microsoft Purview** (the onboarding
> surface shared with **Microsoft Defender for Endpoint**) before removable-media activity is visible
> or controllable. **No onboarding, no control.**

## Endpoint DLP removable-media control — what it is (and is not)

- **It is** the extension of Purview Data Loss Prevention to the **Devices** location for the
  **removable-media** activity — detecting and acting on *copy a matching file to a USB / removable
  storage device*, with an allow-list of **corporate** removable-media device groups so approved
  media is exempt.
- **It is not** a whole-of-endpoint DLP rollout. This solution is **focused on removable media / USB
  and device control**; other endpoint egress channels (print, clipboard, network share, cloud/browser
  upload) are out of scope here and are a separate, broader Endpoint DLP engagement.
- **It is licensing-dependent.** Endpoint DLP is a premium capability (typically **Microsoft 365 E5**,
  the **E5 Compliance**, or the **E5 Information Protection & Governance** add-on) and in-scope users
  must be licensed. Device-control availability and the exact deployment surface likewise depend on
  your licensing and management tooling. Some settings are newer or in preview and the portal evolves
  — **verify capability availability and exact portal paths against your licensing/tenant** rather
  than assuming (see `global-requirements-purview.md` §1).

## Simulate / audit first — these are high-impact controls

A **Block** on removable media stops real work at the moment someone tries to copy a file or plug in a
device. A mis-scoped rule can block a legitimate user mid-task. Therefore:

- The Endpoint DLP removable-media policy is deployed in **simulation / test mode first** (the DLP
  policy modes *Test with notifications* / *Test without notifications*; in the portal, *"Run the
  policy in simulation mode"*) — it **evaluates and records what it *would* do without blocking
  anyone** — validated on a small pilot device group, and only then moved to **enforce**.
- The device-control policy is deployed **audit-first** (allow + audit) before any **block**, on the
  same pilot ring.

**Verify the exact simulation/test terminology and the device-control audit/enforce settings in your
tenant** (the wording evolves).

> **Determinations are not yours to make.** *Which* data is sensitive, *which* devices are approved,
> and *whether* a given copy is a policy violation are **compliance / records / security / HR-legal**
> determinations — this solution delivers the technical configuration and the evidence, not the
> determination (see `global-requirements-purview.md` §5).

## The standard deployment model

Every step follows the same repeatable model, with an explicit **pass/fail gate** between phases:

**Assess → Design → Configure → Pilot (simulation/audit) → Validate → Expand (enforce).**

- **Assess** — confirm licensing, least-privilege roles, device-onboarding readiness, the in-scope
  sensitive content, the pilot device group, and compliance/security stakeholder sign-off.
- **Design** — decide the removable-media action (audit / warn / block) and the device-control posture
  (read-only vs block for unapproved media), define the corporate device group(s), name every object,
  and set the pilot scope.
- **Configure** — set the removable-media device group(s), then build the Endpoint DLP policy + rule(s)
  in **simulation** and the device-control policy in **audit-first**.
- **Pilot** — run in simulation/audit on the pilot devices; confirm the activity is seen and *would*
  act without blocking anyone.
- **Validate** — run the pass/fail gates in `05-testing.md`.
- **Expand** — move rules to enforce and device control to block, widen device scope **only** after the
  gate passes; roll back per `03-implementation.md` if a gate fails.

## What's in the box

- This overview, a **Requirements** guide, an ordered **Implementation** guide, **Testing**
  (pass/fail gates), **Troubleshooting**, **Best Practices**, and a **Deliverables Summary** +
  **Executive Summary**.
- **Five PowerShell tools** (Security & Compliance PowerShell / Microsoft Graph): a **Discovery**
  inventory of onboarding readiness, removable-media settings, and existing config; a
  **Configure/Remediation** helper that builds the removable-media DLP policy + rule(s) in
  **simulation (`-WhatIf` first)**; a **Validation** checker; a **Reporting** rollup of removable-media
  configuration and activity; and a **scope/health** helper — **read-only or `-WhatIf` by default; no
  credentials in code.** (Device-control *policy deployment* is a management-tool action — the scripts
  report on it and DLP but do **not** invent a cmdlet to push a device-control policy.)

> **Sources.** Microsoft Learn — *Learn about Microsoft Purview Endpoint data loss prevention*,
> *Get started with / Onboard Windows devices into Microsoft Purview*, *Configure endpoint DLP
> settings* (removable-storage device groups), *Create and deploy data loss prevention policies*
> (conditions, actions, simulation mode), and *Device control / Removable storage access control*.
> These capabilities are **licensing-dependent** and the Purview portal is **evolving** — **verify
> capability availability, portal paths, and cmdlet parameters against your licensing/tenant** rather
> than assuming.


---


# Requirements — USB & Removable-Media DLP in Microsoft Purview

Confirm every prerequisite below **before** you configure anything. Category-level prerequisites
(tenant, compliance licensing model, least-privilege roles, Security & Compliance PowerShell / Graph
toolchain, in-scope data sources, compliance/privacy/legal stakeholders, pilot scope + change
control) are in `global-requirements-purview.md` — reference them; they are **not** repeated here.
The items below are the ones **specific to USB / removable-media control**: **device onboarding**,
the **removable-storage settings**, and the **two control layers** (content-aware Endpoint DLP and
device-aware device control).

Each requirement is written as **Description · Why · Verify · Implement if missing.**

---

## R1. Endpoint DLP / device-control licensing, assigned to in-scope users

**Description:** The licensing that includes **Endpoint DLP** — typically **Microsoft 365 E5**, the
**E5 Compliance**, or the **E5 Information Protection & Governance** add-on — assigned to the users
who sign in to the **in-scope devices**. Device-control availability likewise depends on your
licensing and management tooling.
**Why:** Endpoint DLP is a premium, plan-gated capability; without the right licence the **Devices**
location and the removable-media activity are not available, and endpoint enforcement is licensed
**per user**.
**Verify:** Microsoft 365 admin center → **Billing → Licenses** confirms the SKU/add-on. In the
Purview portal, **Data Loss Prevention** exposes the **Devices** location and **Settings → Device
onboarding** is present. Cross-check the removable-media/device-control activities against the
*Microsoft Purview service description* — **verify against your licensing/tenant.**
**Implement if missing:** Acquire and assign the required SKU/add-on to in-scope users before
onboarding devices or authoring removable-media rules.

## R2. Least-privilege roles for DLP + device onboarding + device-control deployment

**Description:** The least-privilege roles, mapped to **named** people:
- **Compliance Administrator** or **Compliance Data Administrator** (or the **DLP Compliance
  Management** role group) to author the DLP policy/rule and configure the removable-storage settings.
- The rights to **onboard devices** by your chosen method (e.g. **Intune Administrator** for an
  Intune configuration profile, or a device/GPO administrator for Group Policy / local script).
- The rights to **deploy the device-control policy** through your management tooling (typically the
  same Intune / device-management role) — device control is deployed **to devices**, not authored in
  Security & Compliance PowerShell.
- **Global Administrator** only where genuinely required (e.g. first-time service enablement).
**Why:** Purview uses fine-grained role groups; DLP authoring, device onboarding, and device-control
deployment are distinct duties and should not be over-granted to one account.
**Verify:** Purview portal → **Roles & scopes / Permissions** confirms the DLP role membership; your
device-management console confirms the onboarding + device-control roles. `DLPUSB-Discovery.ps1`
reports the DLP policy/role signals it can read.
**Implement if missing:** Assign the least-privilege role for each duty under change control.

## R3. Supported, healthy devices ready to onboard

**Description:** In-scope endpoints running a **supported build** (Windows 10 version 1809 or later,
or Windows 11; macOS is supported for removable-media DLP with its own minimums) with a current
**antimalware client** and the servicing/updates Endpoint DLP requires, managed in a way that
supports your onboarding method.
**Why:** Removable-media sensing depends on the client components; unsupported or unpatched devices
will not report the *copy to removable media* activity reliably.
**Verify:** Confirm the OS build and update state on a sample of devices; `DLPUSB-Discovery.ps1`
(Graph) reports managed-device OS/version signals where readable. **Confirm exact minimum build/AV
requirements — and macOS support specifics — against current Microsoft docs for your tenant.**
**Implement if missing:** Patch/upgrade devices to a supported build and healthy AV state before
onboarding.

## R4. A device-onboarding method chosen and available

**Description:** A chosen method to **onboard devices to Microsoft Purview** — one of **Microsoft
Intune**, **Group Policy**, **local onboarding script**, or **Microsoft Configuration Manager** —
using the onboarding package from **Purview → Settings → Device onboarding**. (Onboarding is shared
with **Microsoft Defender for Endpoint**; devices already onboarded there may already satisfy this.)
**Why:** Onboarding is what makes the removable-media activity visible to Purview; the method must
fit how the estate is managed and be repeatable for the pilot and expansion rings.
**Verify:** Purview → **Settings → Device onboarding** shows the onboarding packages/options; a test
device appears in the **Devices** list after onboarding. `DLPUSB-ScopeHealth.ps1` prompts to confirm
onboarding status in-portal and reports managed-device counts (Graph) as a proxy.
**Implement if missing:** Select the onboarding method that matches your management tooling, download
the package, and onboard the **pilot** devices first.

## R5. In-scope sensitive content to key the Endpoint DLP rule on (labels and/or SITs)

**Description:** The **sensitive content** the removable-media DLP rule will match — **sensitivity
labels** (e.g. *Confidential*) already published and in use, and/or **sensitive information types**
(built-in or custom) and/or trainable classifiers — that define *what* triggers the *copy to
removable media* control.
**Why:** The content-aware layer acts on **content that matches a condition**; without labels or SITs
to match, the rule has nothing to key on (or would apply to *all* content copied to USB, which is
rarely intended for the content layer).
**Verify:** Purview → **Information Protection → Labels** shows the labels published; **Data
classification → Sensitive info types** shows the SITs; in-scope content carries labels (Activity/
Content explorer where available). `DLPUSB-Discovery.ps1` inventories labels and SITs.
**Implement if missing:** Publish/adopt the needed sensitivity labels or select the SITs first. (The
device-control layer is content-agnostic and can start without this; the Endpoint DLP layer needs it.)

## R6. Removable-storage device group(s) defined (the "corporate/allowed media" allow-list)

**Description:** The **removable-storage device group(s)** in **Endpoint DLP settings** that
distinguish **corporate-issued / approved** media (by device ID, vendor ID, serial number, etc., as
your standard allows) from everything else, plus any **file-path exclusions**. Name the corporate
group (e.g. `USBG-Corporate`).
**Why:** These groups are the *vocabulary* both layers speak — "block copy to USB **except** the
corporate device group," "allow **only** approved removable storage." Without them the controls
cannot distinguish sanctioned from unsanctioned media.
**Verify:** Purview → **Data Loss Prevention → Endpoint DLP settings → Removable storage device
groups** shows the group defined and populated. `DLPUSB-Discovery.ps1` reports the endpoint settings
it can read and flags anything not readable.
**Implement if missing:** Define the corporate device group(s) **before** authoring the rule or the
device-control policy that references them. **Verify the exact settings page and device-property
options against your tenant** (they evolve).

## R7. A device-control deployment surface (for the device-aware layer)

**Description:** The mechanism to deploy a **removable-storage access control (device-control)**
policy to onboarded devices — typically **Microsoft Intune** (device-control profile / settings
catalog), **Group Policy**, or **OMA-URI**, referencing the same removable-storage device group(s).
The device-control policy sets **Allow / Audit / Block** for **read / write / execute** on removable
storage **by device group**, independent of content.
**Why:** The content-aware Endpoint DLP layer sees *sensitive* files; the device-aware layer controls
the **medium** regardless of content (e.g. make unapproved USB read-only or blocked). Delivering both
gives *block/audit/allow by policy*.
**Verify:** Confirm your management tooling exposes the removable-storage/device-control settings and
that a test policy targets the pilot devices. **Verify the exact device-control surface, setting
names, and availability for your tenant/OS** — these differ by platform and evolve.
**Implement if missing:** Select the device-control surface that matches your management tooling and
confirm it can target the pilot ring. (There is **no** Security & Compliance PowerShell cmdlet to
push a device-control policy — the provided scripts *report* on it but do not deploy it.)

## R8. Control decision (audit / warn / block, read-only vs block) — agreed with stakeholders

**Description:** A documented decision, for **each layer**, of the intended action, agreed with
**compliance / security** (and HR/legal where the action affects users):
- **Endpoint DLP (content):** for *copy sensitive content to removable media* — **Audit**, **Warn
  with override**, or **Block** — and which sensitive content it applies to.
- **Device control (device):** the posture for **unapproved** removable storage — **Audit**,
  **read-only**, or **Block** for read/write/execute — and the approved-media exception.
**Why:** The action is a **policy decision, not a technical default**; blocking versus auditing
removable media, or making it read-only, has real operational and user impact and must reflect
enterprise policy.
**Verify:** Confirm the per-layer action decision and the in-scope content/media **in writing**
before you move anything from simulation/audit to enforce.
**Implement if missing:** Capture the decision with the relevant owners; until then, deploy **audit /
simulation only.** (See `global-requirements-purview.md` §5.)

## R9. A named pilot device group and change control (simulation/audit first)

**Description:** A **named pilot device group** (a limited set of onboarded devices, e.g.
`DG-USB-Pilot`, or a pilot user group `SG-USB-Pilot`) and agreement to run the Endpoint DLP policy in
**simulation/test mode** and the device-control policy in **audit-first** posture, under a
**change-control** process, before any enforcing, broad-scope rollout.
**Why:** Removable-media block/read-only actions are high-impact; simulation/audit on a small ring
proves the activity is seen and the controls *would* act **without** disrupting real work, and lets
you tune before enforcing.
**Verify:** Confirm the pilot group exists and is onboarded, that **simulation/test** (DLP) and
**audit** (device control) modes are used first, and a change window/approval path.
`DLPUSB-ScopeHealth.ps1` (`-WhatIf`) previews pilot-scope targeting.
**Implement if missing:** Define the pilot group, onboard it, deploy in simulation/audit, and agree
change control before enabling enforcement.


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


# Implementation Guide — USB & Removable-Media DLP in Microsoft Purview

This is the ordered, do-it-in-this-sequence guide. It follows the standard model —
**Assess → Design → Configure → Pilot (simulation/audit) → Validate → Expand (enforce)** — with every
object **named**, an explicit **pass/fail gate** at each phase, and a **rollback** for each change.
Do **not** skip the simulation/audit phase; removable-media block and read-only actions are
high-impact.

**The two control layers you are delivering:**

| Layer | Keys on | Controls | Built where |
|---|---|---|---|
| **Endpoint DLP — removable media** | **Content** (label / SIT) | *Copy a matching file to removable/USB storage* — Audit / Warn / Block, except the corporate device group | **Purview → Data Loss Prevention** (Devices location, removable-media restriction) |
| **Device control — removable-storage access** | **Device** (device group) | **Read / Write / Execute** on removable storage — Allow / Audit / Block by device group | **Management tooling** (Intune / GPO / OMA-URI) — **verify surface for your tenant** |

**Named objects used throughout (rename to your convention, but be consistent):**

| Object | Name used here |
|---|---|
| Endpoint DLP policy | `EDLP-USB-Pilot` |
| Removable-media rule | `EDLP-Rule-USB` |
| Device-control policy (management tool) | `DC-RemovableStorage-Pilot` |
| Corporate removable-media device group | `USBG-Corporate` |
| Pilot device group | `DG-USB-Pilot` |
| Pilot user group | `SG-USB-Pilot` |

> **Tooling note.** Endpoint **device onboarding** and the **removable-storage device groups** are
> configured in the **Purview portal** — there is no supported Security & Compliance PowerShell cmdlet
> to *onboard* a device or to *deploy* a device-control policy. The DLP **policy and rule** can be
> authored in the portal **or** with `New-/Set-DlpCompliancePolicy` and `New-/Set-DlpComplianceRule`;
> the provided `DLPUSB-Configure.ps1` builds them in **simulation** with `-WhatIf` by default. The
> **device-control policy** is deployed through your management tooling — the scripts *report* on
> it, they do not push it. **Verify every portal path and cmdlet parameter against your tenant** — the
> portal and the removable-media restriction parameter names evolve.

---

## Phase 0 — Assess (confirm you are ready)

1. **Confirm requirements.** Walk `02-requirements.md` R1–R9. Do **not** proceed until licensing,
   roles, supported devices, an onboarding method, in-scope sensitive content, the removable-storage
   device group plan, the device-control surface, the per-layer action decision, and a pilot group
   are all confirmed.
2. **Run Discovery.** `Connect-IPPSSession`, then `.\DLPUSB-Discovery.ps1` to inventory existing DLP
   policies/rules, the **Devices** coverage, sensitivity labels, and SITs. Keep the CSV as your
   baseline.
3. **Confirm onboarding readiness.** `.\DLPUSB-ScopeHealth.ps1` reports managed-device signals
   (Graph) and prompts you to confirm, **in Purview → Settings → Device onboarding**, that the pilot
   devices are onboarded.

**Gate 0 (pass/fail):** All of R1–R9 satisfied, Discovery baseline captured, pilot devices onboarded
and visible in **Purview → Devices**. **Fail → stop** and close the gap; do not configure.

---

## Phase 1 — Onboard the pilot devices

1. In **Purview portal → Settings → Device onboarding** (verify path), review the supported
   onboarding methods and download the package for your chosen method (Intune / Group Policy / local
   script / Configuration Manager).
   - *Local script* is fine for a **handful of pilot machines**; use **Intune or GPO** for scale.
   - If devices are already **onboarded to Microsoft Defender for Endpoint**, they may already be
     onboarded here — confirm they appear under **Devices**.
2. Onboard **only the pilot devices** (`DG-USB-Pilot`) first.

**Gate 1:** Pilot devices show as **onboarded** in **Purview → Devices**; a test activity (copy a
benign file to a USB stick) appears in **Activity explorer** (Devices) within the expected latency.
**Fail → rollback:** offboard the device via your onboarding tool's offboarding package; re-check the
device prerequisites (R3) before retrying. **No policy is configured yet, so there is nothing to
enforce-rollback at this stage.**

---

## Phase 2 — Define the removable-storage device group(s)

In **Purview → Data Loss Prevention → Endpoint DLP settings → Removable storage device groups**
(verify path), create `USBG-Corporate` listing the corporate-issued/approved USB devices (by device
ID / vendor ID / serial number, as your standard allows). This is the allow-list both layers use to
**block everything except** approved media. Define any **file-path exclusions** here too.

**Gate 2:** `USBG-Corporate` exists and is populated; `DLPUSB-Discovery.ps1` re-run reports it as
readable (or you have confirmed it in-portal where a setting is not exposed to PowerShell).
**Fail → rollback:** remove/blank the group; groups are inert until a rule or device-control policy
references them, so there is no user impact yet.

---

## Phase 3 — Author the Endpoint DLP policy + removable-media rule in SIMULATION

Create **one** DLP policy, `EDLP-USB-Pilot`, scoped to the **Devices** location and the **pilot scope
only**, in **simulation/test mode** (nothing is blocked), with a single removable-media rule. Author
in the portal or run `.\DLPUSB-Configure.ps1 -WhatIf` first, then `.\DLPUSB-Configure.ps1 -Commit`
(still simulation) to create the objects.

1. **Create the policy** (simulation, Devices location, pilot scope):
   - Location: **Devices** only, scoped to `DG-USB-Pilot` / `SG-USB-Pilot`.
   - Mode: **simulation/test** (portal: *"Run the policy in simulation mode"*; PowerShell: a **Test**
     mode — `TestWithoutNotifications` for a silent pilot, or `TestWithNotifications` to also show
     policy tips). **Verify the exact mode value in your tenant.**
2. **Add the removable-media rule** `EDLP-Rule-USB`:
   - **Condition** on your sensitive content (a sensitivity-label condition such as *Confidential*,
     and/or a sensitive-info-type condition) — **not** "all content".
   - **Endpoint restriction:** the *copy to a removable USB/removable-storage device* activity, set to
     **Audit** while in simulation, **except** `USBG-Corporate` (approved media is exempt).
   - The endpoint restriction is set on the rule (portal → **Devices** activities, or PowerShell via
     the rule's endpoint-restriction parameter). **Verify the exact restriction Setting name and
     permitted values (`Audit` / `Warn` / `Block` / `Ignore`) against `Get-Help New-DlpComplianceRule
     -Full` in your tenant** before scripting them.
3. **Save.** The policy is now evaluating on the pilot devices **without blocking anyone.**

**Gate 3:** `EDLP-USB-Pilot` exists, is in **simulation/test**, scoped to **Devices + pilot only**,
with `EDLP-Rule-USB` present, conditioned on sensitive content, and referencing `USBG-Corporate`.
`DLPUSB-Validate.ps1` reports **PASS** for policy-exists, Devices-location, mode-is-simulation,
scope-is-pilot, and rule-present.
**Fail → rollback:** `Set-DlpCompliancePolicy -Identity EDLP-USB-Pilot -Mode Disable` (or delete with
`Remove-DlpCompliancePolicy`); simulation blocks nothing, so impact is limited to telemetry.

---

## Phase 4 — Deploy the device-control policy in AUDIT-first

In your **management tooling** (Intune / GPO / OMA-URI — verify surface, R7), create
`DC-RemovableStorage-Pilot` targeting `DG-USB-Pilot`:

1. Set the posture for **unapproved** removable storage to **Audit** first (allow + audit), with
   **`USBG-Corporate`** as the approved exception.
2. Do **not** set Block/read-only yet — audit-first proves the control is seen without disrupting
   work.

**Gate 4a:** `DC-RemovableStorage-Pilot` is deployed to the pilot devices in **audit** posture;
device-control audit events appear for a test USB action. **Fail → rollback:** remove the assignment
in your management tool; nothing is blocked in audit posture.

---

## Phase 5 — Pilot & validate (simulation + audit)

1. Let both layers run on `DG-USB-Pilot` for the agreed observation window.
2. Perform the **sanctioned test actions** in `05-testing.md` on a pilot device (copy a test-labeled
   file to a non-corporate USB; copy to a `USBG-Corporate` device; plug in an unapproved USB).
3. Review **Activity explorer** (Devices), the DLP policy's **simulation results**, and the
   device-control **audit** events; run `.\DLPUSB-Report.ps1` to roll up configuration and (where
   available) activity.
4. **Tune:** adjust the DLP condition/allow-list to remove false positives (e.g. add a legitimate
   corporate USB to `USBG-Corporate`) and confirm both layers **see** the activity.

**Gate 5 (pass/fail):** The Endpoint DLP rule recorded the *copy sensitive content to USB* action in
simulation (would act), the device-control policy recorded the unapproved-media action in audit, the
`USBG-Corporate` exception is respected, false positives triaged, and the **R8 action decision**
confirmed **in writing**. **Fail → do not enforce**; keep tuning in simulation/audit.

---

## Phase 6 — Enforce, then expand

**Only after Gate 5 passes.**

1. **Endpoint DLP:** update `EDLP-Rule-USB` to its **R8** action — **Warn (override)** or **Block** —
   then move the policy out of simulation to **enforce** (portal: turn the policy **On**; PowerShell:
   `Set-DlpCompliancePolicy -Identity EDLP-USB-Pilot -Mode Enable`), still scoped to the pilot first.
2. **Device control:** update `DC-RemovableStorage-Pilot` from **audit** to the **R8** posture —
   **read-only** or **Block** for unapproved removable storage — in your management tool, still
   targeting the pilot.
3. **Re-run the sanctioned tests** (`05-testing.md`) and confirm the enforced behaviour: sensitive
   content is blocked/warned on non-corporate USB, unapproved media is read-only/blocked, and
   `USBG-Corporate` remains allowed.
4. **Expand scope in rings.** Widen the **Devices** scope and the device-control assignment (add the
   next device group), re-validate, and repeat. Consider renaming/cloning to production policies
   (`EDLP-USB` / `DC-RemovableStorage`) as you exit pilot.

**Gate 6:** On the pilot, the enforced content block/warn and the device-control read-only/block act
as designed and `USBG-Corporate` is not blocked; expansion rings each pass the same gate before
widening.
**Fail → rollback:** immediately return the DLP policy to **simulation/test**
(`Set-DlpCompliancePolicy -Mode TestWithoutNotifications`) or **Disable** it, and set the
device-control policy back to **audit** in your management tool — this stops enforcement at once —
then diagnose per `06-troubleshooting.md` before re-enforcing.

---

## Rollback summary (fast reference)

| Situation | Action |
|---|---|
| The DLP rule blocks legitimate work | Set `EDLP-Rule-USB` action back to **Audit**, or set the policy to **simulation/test**, then tune the allow-list/conditions. |
| Device control blocks a legitimate USB | Add the device to `USBG-Corporate`, or set the device-control posture back to **audit/read-only** in your management tool. |
| The whole DLP policy misbehaves | `Set-DlpCompliancePolicy -Identity EDLP-USB-Pilot -Mode Disable` (stops all enforcement) or `-Mode TestWithoutNotifications` (back to simulation). |
| A device should not be in scope | Remove it from the scoped device/user group and the device-control assignment, or **offboard** it via your onboarding tool. |
| Start over cleanly | `Remove-DlpComplianceRule -Identity EDLP-Rule-USB`, then `Remove-DlpCompliancePolicy -Identity EDLP-USB-Pilot`; remove the device-control assignment in your management tool. |

> Enforcement changes are **high-impact** — make them under change control, keep the pilot ring
> small, and never move both layers to hard **Block** at once without validating each in
> simulation/audit first.


---


# Testing & Validation — USB & Removable-Media DLP

This is the pass/fail gate set. Run it in two passes: **once in simulation/audit** (Phase 5 — the
activity is *seen* and the controls *would* act, nothing is blocked) and **again after enforce**
(Phase 6 — the block/warn/read-only actions *actually* apply). Every test uses **benign test
content** deliberately marked to match your policy conditions (e.g. a document carrying your
*Confidential* sensitivity label and/or seeded with a matching sensitive information type) and a
**non-corporate test USB** — **never** real regulated data.

> **Determination boundary.** These tests prove the **controls work as configured**. Whether a given
> real-world action is a *violation*, and any consequence, is a **compliance / security / HR-legal**
> determination — not a test outcome (see `global-requirements-purview.md` §5).

Run `.\DLPUSB-Validate.ps1` for the configuration gates and `.\DLPUSB-Report.ps1` for the
activity/telemetry rollup between passes.

---

## A. Configuration gates (automated — `DLPUSB-Validate.ps1`, read-only)

| # | Check | PASS signal |
|---|---|---|
| A1 | DLP policy exists | `EDLP-USB-Pilot` is present. |
| A2 | Devices location | The policy covers the **Devices** location. |
| A3 | Simulation first | In the pilot pass, the policy **Mode** is a **Test/simulation** mode (not `Enable`). |
| A4 | Pilot scope | The policy is scoped to `DG-USB-Pilot` / `SG-USB-Pilot`, **not** all devices. |
| A5 | Removable-media rule present | `EDLP-Rule-USB` exists and is enabled. |
| A6 | Sensitive-content condition | The rule carries a sensitivity-label and/or sensitive-info-type condition (not "all content"). |
| A7 | Allow-list group referenced | The rule references `USBG-Corporate` as the approved-media exception. |

**Gate A:** All applicable rows PASS. Any FAIL → fix in `03-implementation.md` before behavioural
testing.

> Device-control policy configuration is **not** readable via Security & Compliance PowerShell —
> confirm `DC-RemovableStorage-Pilot` and its posture in your **management tooling** (Intune / GPO /
> OMA-URI) as a manual gate.

---

## B. Behavioural tests — both layers (manual, on a pilot device)

Perform each action with the stated media/content and record the result. In the **simulation/audit
pass** the expected result is *"activity recorded; no block."* In the **enforce pass** the expected
result is the **R8** action.

| # | Layer | Test action (on a pilot device) | Simulation/audit PASS | Enforce PASS (per R8) |
|---|---|---|---|---|
| B1 | **Endpoint DLP (content)** | Copy the **matching test file** to a **non-corporate** USB stick | Activity recorded in Activity explorer; no block | Blocked/Warned as designed |
| B2 | **Endpoint DLP (exception)** | Copy the same file to a **`USBG-Corporate`** device | Activity recorded; no block | **Allowed** (approved media exempt) |
| B3 | **Device control (device)** | Plug in an **unapproved** USB and attempt read/write | Audit event recorded; access allowed | **Read-only / blocked** per R8 |
| B4 | **Device control (exception)** | Plug in a **`USBG-Corporate`** device and read/write | Audit event recorded; access allowed | **Allowed** (approved media exempt) |

**Gate B (simulation/audit pass):** B1–B4 all recorded the activity. A test that records **nothing**
is a coverage failure — do not enforce it; diagnose per `06-troubleshooting.md` (onboarding, latency,
condition match, device-group membership).

**Gate B (enforce pass):** The enforced content block/warn (B1) and device-control read-only/block
(B3) act as designed **and** the `USBG-Corporate` exceptions (B2, B4) are **not** blocked. Any
deviation → roll back to simulation/audit and tune.

---

## C. Negative / false-positive tests (both passes)

| # | Check | PASS signal |
|---|---|---|
| C1 | Non-matching content | Copying a file that carries **no** matching label/SIT to a non-corporate USB triggers **no** Endpoint DLP content match. |
| C2 | Allow-listed media | The corporate USB (`USBG-Corporate`) is **not** blocked by either layer in the enforce pass. |
| C3 | Out-of-scope device | A device **not** in `DG-USB-Pilot` shows **no** enforcement from this policy or the device-control assignment. |
| C4 | Override/justification | Where **Warn/override** or **business justification** is configured on the DLP rule, the prompt appears and the override is **logged**. |

**Gate C:** All applicable rows PASS. A false positive (C1/C2 fails) must be tuned **before** wider
enforcement — false positives erode user trust and drive shadow workarounds.

---

## D. Evidence to capture (for the defensibility pack)

Capture and retain, for each pass:

- `DLPUSB-Validate.ps1` output (configuration gate results).
- `DLPUSB-Report.ps1` output (policy modes + Activity-explorer export of removable-media activity,
  where available).
- Screenshots of **Purview → Activity explorer (Devices)** showing the removable-media activity, the
  device-control **audit/enforce** events in your management tool, and the **policy tip / block
  dialog** in the enforce pass.
- A completed **B-layer matrix** signed off by the change owner, the **R8 action decision**, the
  **device-group (`USBG-Corporate`) membership**, and the **onboarding confirmation** (pilot devices
  listed in **Purview → Devices**).

> This evidence set is what makes the control **defensible** — it shows *what* was configured across
> both layers, *that* each was validated in simulation/audit before enforcement, and *that*
> enforcement behaves as designed. Store it with the change record.


---


# Troubleshooting — USB & Removable-Media DLP

The failures you will actually hit, with the most likely cause and the fix. Work top-down: **most
"the policy isn't working" reports trace back to onboarding, device-group membership, condition
matching, or simulation-vs-enforce confusion — not the rule itself.** Where a portal path or cmdlet
parameter is named, **verify it against your tenant** — the Purview portal and the removable-media /
device-control options evolve.

---

## 1. A device shows no removable-media activity at all

**Symptoms:** Copy a matching file to a USB stick on a device and **nothing** appears in Activity
explorer (Devices); the policy never fires.

**Likely causes & fixes**
- **Device isn't onboarded.** The #1 cause. Confirm the device appears under **Purview → Devices**
  (Settings → Device onboarding). If not, re-run your onboarding method (Intune/GPO/local script/
  ConfigMgr). There is **no** S&C PowerShell cmdlet to onboard — it is a portal/management-tool action.
- **Unsupported / unpatched build.** Endpoint sensing needs a supported build (Windows 10 1809+ /
  Windows 11, or a supported macOS) and a current antimalware client (R3). Patch and retest.
- **Onboarding still propagating.** After onboarding, allow time for the device to register and for
  activity to surface — endpoint telemetry is **not** instant. Wait and retry.
- **Check the proxy signal:** `DLPUSB-ScopeHealth.ps1` reports managed-device counts (Graph) — but
  remember that is a **proxy**; the authoritative check is the **Devices** list in the portal.

---

## 2. Endpoint DLP (content) sees the copy, but device control does nothing (or vice-versa)

**Symptoms:** Only one of the two layers is acting.

**Fix**
- **They are configured in different places.** Endpoint DLP (content) is the Purview **DLP policy**;
  device control (device) is deployed through your **management tooling** (Intune / GPO / OMA-URI).
  Confirm **both** exist: `DLPUSB-Validate.ps1` covers the DLP policy; check
  `DC-RemovableStorage-Pilot` in your management tool for the device-control layer.
- **Device control not assigned to the pilot ring.** Verify the device-control policy targets
  `DG-USB-Pilot` and reached the device (management-tool reporting).
- **Remember what each layer does:** content DLP only fires on **sensitive** content; device control
  fires on the **device** regardless of content. A plain (non-sensitive) file copy to an unapproved
  USB is a *device-control* event, not a content-DLP event — that is by design.

---

## 3. The control fires on the wrong things (false positives)

**Symptoms:** Legitimate work is flagged/blocked — a corporate USB, or a non-sensitive file copy.

**Likely causes & fixes**
- **Approved device not in `USBG-Corporate`.** Add the corporate device to the removable-storage
  device group (Endpoint DLP settings) and make sure the DLP rule **and** the device-control policy
  reference it as the approved exception.
- **Content condition too broad.** If the Endpoint DLP rule keys on "all content" instead of a
  **sensitivity label / SIT**, it matches everything copied to USB. Tighten the condition (R5).
  `DLPUSB-Validate.ps1` gate **A6** flags a rule with no readable content condition. (If you actually
  want to stop *all* USB use, that belongs in the **device-control** layer, not a content rule keyed
  to "all content.")
- **SIT confidence/count too loose.** Raise the confidence level or instance count on the sensitive
  information type to cut noise, then re-test.
- Tune **in simulation/audit** — never tune by loosening an already-enforcing block in production.

---

## 4. The rule doesn't fire on content it should

**Symptoms:** A file you expect to match is copied to USB with no policy match.

**Likely causes & fixes**
- **Content doesn't carry the label/SIT.** The test file must actually carry the **sensitivity
  label** or contain the **sensitive information type** the rule keys on. Seed a known match.
- **Label not published / SIT not in scope.** Confirm the label is published to the user (Information
  Protection → Label policies) and the SIT exists (Data classification). `DLPUSB-Discovery.ps1`
  inventories both.
- **Rule disabled.** `DLPUSB-Validate.ps1` gate **A5b** flags a disabled rule.

---

## 5. Simulation/audit looks fine but enforcement doesn't block

**Symptoms:** In simulation/audit the activity is recorded; after "turning it on" the block/warn/
read-only still doesn't happen.

**Likely causes & fixes**
- **DLP policy still in a Test mode.** Simulation records but does **not** block. To enforce, move the
  policy out of simulation: portal → turn the policy **On**; PowerShell → `Set-DlpCompliancePolicy
  -Identity EDLP-USB-Pilot -Mode Enable`. `DLPUSB-Validate.ps1` gate **A3** shows the current mode.
- **Rule action still Audit.** The removable-media restriction may be **Audit** even though the policy
  is enforcing. Set it to **Warn/Block** per the R8 decision.
- **Device-control policy still in audit.** In your management tool, move `DC-RemovableStorage-Pilot`
  from **audit** to **read-only / Block** for unapproved media.
- **Device out of scope.** Enforcement only applies to devices in scope. Confirm with
  `DLPUSB-ScopeHealth.ps1` / gate **A4** and the device-control assignment.
- **Propagation delay.** Policy/action changes take time to reach endpoints. Wait, then retest.

---

## 6. `New-DlpComplianceRule` fails on the removable-media restriction

**Symptoms:** `DLPUSB-Configure.ps1 -Commit` (or manual scripting) errors when setting the endpoint
restriction, e.g. an invalid Setting name or value.

**Fix**
- **Verify the exact Setting name and value for your tenant.** The removable-media endpoint-restriction
  Setting name and permitted values (`Audit` / `Warn` / `Block` / `Ignore`) **evolve**. Run
  `Get-Help New-DlpComplianceRule -Full` and check current Microsoft docs, then adjust the hashtable.
  The script deliberately **prints the planned Setting name** so you can verify before `-Commit`.
- **Prefer the portal for the first build** if PowerShell parameter names are uncertain, then read the
  result back with `DLPUSB-Discovery.ps1` to learn the exact shape in your tenant.

---

## 7. `-EndpointDlpLocation` / scope errors

**Symptoms:** Creating the policy errors on the location/scope value.

**Fix**
- The **Devices** location is scoped by user/group (or `All`). Confirm the pilot group
  (`SG-USB-Pilot`) exists and the identifier is one your tenant accepts. `DLPUSB-ScopeHealth.ps1`
  reports the group and the current scope.
- Avoid `All` during the pilot — scope to the pilot group first (gate **A4**).

---

## 8. The device-control policy won't deploy / doesn't reach devices

**Symptoms:** `DC-RemovableStorage-Pilot` shows as failed/not-applied in your management tool.

**Likely causes & fixes**
- **This is a management-tool issue, not a Purview one.** Device control is deployed via **Intune /
  GPO / OMA-URI** — troubleshoot in that console (assignment, targeting, sync, per-OS support). The
  provided scripts do **not** deploy or read the device-control policy.
- **OS / surface mismatch.** The removable-storage/device-control settings and their availability
  **differ by platform** and evolve — verify the exact surface for your tenant/OS.
- **Device not onboarded/managed.** The device must be managed by the tool pushing the policy; confirm
  enrollment/management state.

---

## 9. Activity report is empty or export fails

**Symptoms:** `DLPUSB-Report.ps1` returns no activity, or the Activity Explorer export warns and skips.

**Likely causes & fixes**
- **Licensing/permission.** `Export-ActivityExplorerData` is licensing-dependent; the script **warns
  and degrades to policy-modes only** rather than failing. Fall back to **Purview → Activity explorer**
  (filter to **Devices**) in the portal.
- **Quiet pilot window.** A small pilot may simply have no activity in the window — widen `-Days` or
  perform the sanctioned test actions from `05-testing.md` first.
- **Role.** Ensure the connected account holds a role that can read Activity Explorer.
- **Device-control audit lives elsewhere.** Device-control audit events are in your **management
  tool**, not Activity Explorer — check both.

---

## 10. "It blocked an admin / broke a workflow" — emergency rollback

**Do this immediately, then diagnose:**
- Return the DLP policy to **simulation** or **off**: `Set-DlpCompliancePolicy -Identity EDLP-USB-Pilot
  -Mode TestWithoutNotifications` (simulation) or `-Mode Disable` (off). Either **stops enforcement at
  once.**
- Set the device-control policy back to **audit** (or remove its assignment) in your management tool.
- Or add the affected device to `USBG-Corporate` if it should have been approved.
- Then work the relevant section above (usually §3 false positives or §5 scope), fix **in
  simulation/audit**, re-validate with `DLPUSB-Validate.ps1`, and only then re-enforce.

---

## When to escalate to the determination owners (not a technical fix)

Some questions are **not** troubleshooting — they are **determinations** that belong to compliance /
security / records / HR-legal (see `global-requirements-purview.md` §5):

- *Should* removable media be **blocked**, **read-only**, or only **audited**? → the **R8** decision
  owners.
- Is *this device* actually approved corporate media? → the **device/security owners**.
- Is a user's action a **violation**, and what is the consequence? → **HR / legal**.

Provide them the **evidence** (`DLPUSB-Report.ps1`, Activity explorer, device-control audit, the
validation output) — not a verdict.


---


# Best Practices — USB & Removable-Media DLP

Field-tested guidance for running USB / removable-media control well. It complements — does not
replace — the implementation steps and the pass/fail gates.

## Run both layers, and know what each one is for

- **Endpoint DLP is content-aware; device control is device-aware.** Use them together: Endpoint DLP
  stops *sensitive content* from reaching removable media; device control governs *the medium* (allow
  / read-only / block by device group) regardless of content. Neither alone gives the full picture.
- **Lead with the layer that matches the intent.** If the goal is "sensitive data must not leave on a
  stick," the Endpoint DLP content rule is primary. If the goal is "only corporate USBs are usable,"
  the device-control layer is primary. Most organizations want both.

## Deploy the way the house model says — simulate/audit, then enforce

- **Never enforce a control you have not validated in simulation/audit.** The single most common cause
  of a removable-media incident is a **Block** or **read-only** setting pushed without a
  simulation/audit pass. Each layer goes **simulation/audit → validate → enforce**, one ring at a time.
- **Small pilot ring first.** Onboard and scope a handful of devices (`DG-USB-Pilot`) before the
  estate. It is far cheaper to find a false positive on ten machines than ten thousand.
- **One layer at a time to enforce.** Do not flip both content-block and device-block on together.
  Enforce one, validate, then the other.
- **Keep a rollback ready.** `Set-DlpCompliancePolicy -Mode TestWithoutNotifications` (back to
  simulation) or `-Mode Disable` stops DLP enforcement instantly; reverting the device-control policy
  to **audit** in your management tool stops that layer. Know both before you enforce.

## Curate the removable-storage device group deliberately

- **`USBG-Corporate` is what lets you block the bad path without blocking the business.** Keep it
  accurate and review it on a schedule — a stale allow-list is both a false-positive source and a
  bypass (an unapproved device slipping in, or a retired device still trusted).
- **Choose device-matching properties that are hard to spoof** where your standard allows (serial
  number / device instance) rather than only broad vendor IDs, so "corporate" really means corporate.
- **Use file-path exclusions sparingly** — each exclusion is a monitoring blind spot.

## Key the content rule on *sensitive* content, not everything

- **Condition on labels and/or SITs**, not "all content." An Endpoint DLP rule that blocks *any* USB
  copy generates noise and workarounds; one that blocks **labeled/classified** content is defensible
  and proportionate. (If you want to stop *all* USB use, that is the **device-control** layer's job,
  not a content rule keyed to "all content.")
- **Lead with sensitivity labels where they exist** — a label is an explicit business decision about
  sensitivity and travels with the file. Fall back to **sensitive information types** where labels are
  not yet adopted, and tune SIT confidence/count to reduce false positives before you enforce.

## Onboarding hygiene

- **Onboarding is shared with Defender for Endpoint** — coordinate so you do not double-manage or
  fight another team's onboarding/offboarding. Confirm devices in **Purview → Devices**, not by
  assumption. **No onboarding, no removable-media control.**
- **Keep the client and AV current** — endpoint sensing depends on it; unpatched devices under-report.
- **Offboard cleanly** using the offboarding package when a device leaves scope; do not just delete
  the record.

## Operate it, don't set-and-forget

- **Review Activity explorer (Devices) and device-control audit regularly** and roll up with
  `DLPUSB-Report.ps1`. Rising removable-media activity is a signal to review scope, tuning, or user
  education — not automatically a reason to block harder.
- **Watch override / business-justification trends.** Constant overrides may mean a genuine business
  need that belongs in `USBG-Corporate` (or a scoped exception), not a block.
- **Version and name policies clearly.** Move from `EDLP-USB-Pilot` / `DC-RemovableStorage-Pilot` to
  production names as you exit pilot; keep a change log of scope and action changes across **both**
  the Purview policy and the management-tool device-control policy.
- **Re-validate after portal / management-tool changes.** The Purview portal and the device-control
  surfaces evolve; re-run `DLPUSB-Validate.ps1` after Microsoft feature updates and confirm nothing
  regressed.

## Keep the roles and determinations where they belong

- **Least privilege, split duties.** DLP authoring, device onboarding, and device-control deployment
  are different roles — do not fold them into one over-privileged account.
- **Determinations stay with the owners.** *Which* data is sensitive, *which* devices are approved,
  and *whether* an action is a violation are **compliance / security / HR-legal** calls. You provide
  the configuration and the evidence, not the judgement (see `global-requirements-purview.md` §5).
- **Communicate before you enforce.** Policy tips and user notice reduce friction and support the
  lawful, transparent operation of a removable-media control; surprise blocks generate tickets and
  workarounds.

## Security & handling of the tooling

- **Read-only / `-WhatIf` by default.** Run the provided scripts in their safe default first; only add
  `-Commit`/`-Apply` when you intend to write, under change control.
- **No secrets in code.** The scripts use interactive modern-auth (`Connect-IPPSSession` /
  `Connect-MgGraph`); never hardcode credentials, tokens, or app secrets. The scripts **report** on
  the device-control policy but never invent a cmdlet to deploy it.
- **Least-privilege connections.** Connect with the least-privilege role that the task needs, not a
  standing Global Administrator session.


---


# Deliverables Summary — USB & Removable-Media DLP in Microsoft Purview

Everything included in this solution, what each piece is for, and how it maps to the deployment
model. Use it as the table of contents and the "did we finish?" checklist.

## Documents

| Document | What it gives you |
|---|---|
| **01 — Solution Overview** | What USB / removable-media DLP delivers, the **two control layers** (content-aware Endpoint DLP + device-aware device control), onboarding, the simulate/audit-first rule, and the Assess→Design→Configure→Pilot→Validate→Expand model. |
| **02 — Requirements** | The solution-specific prerequisites (R1–R9): endpoint/device-control licensing, DLP + onboarding + device-control roles, supported devices, an onboarding method, in-scope sensitive content, the removable-storage device group, the device-control surface, the per-layer action decision, and a pilot group — each with Verify / Implement-if-missing. References the category `global-requirements-purview.md`. |
| **03 — Implementation Guide** | The ordered build: onboard pilot devices → define `USBG-Corporate` → author the Endpoint DLP policy + rule **in simulation** → deploy device control **audit-first** → pilot & validate → enforce & expand. Every object named, with a pass/fail gate and rollback per phase. |
| **05 — Testing & Validation** | The pass/fail gates: configuration gates (A), per-layer behavioural tests (B) run in simulation/audit then enforce, false-positive/negative tests (C), and the evidence to capture (D). |
| **06 — Troubleshooting** | The failures you will actually hit — no removable-media activity, device-control not applying, false positives, corporate USB blocked, simulation-vs-enforce confusion — each with cause and fix. |
| **07 — Best Practices** | How to run it well: run both layers with intent, simulate/audit-then-enforce discipline, curating `USBG-Corporate`, keying the content rule on sensitive content, onboarding hygiene, ongoing operation, and role/determination boundaries. |
| **Executive Summary** | The one-page business-level summary for stakeholders and sign-off. |

## PowerShell tools (5)

All are **read-only or `-WhatIf` by default**, use interactive modern-auth
(`Connect-IPPSSession` / `Connect-MgGraph`), and contain **no credentials**. They do **not** onboard
devices or deploy the device-control policy (both are portal/management-tool actions) and do **not**
invent cmdlets.

| Script | Purpose | Safe default |
|---|---|---|
| **DLPUSB-Discovery.ps1** | Inventory existing DLP policies/rules and **Devices** coverage, the removable-storage device groups it can read, sensitivity labels, and sensitive info types — the baseline of what already protects removable media. | Read-only |
| **DLPUSB-Configure.ps1** | Build/update the `EDLP-USB-Pilot` policy and the `EDLP-Rule-USB` removable-media rule **in simulation**; requires `-Commit` to write and supports `-WhatIf`. | `-WhatIf` (preview) |
| **DLPUSB-Validate.ps1** | Run the configuration gates (policy exists, Devices location, simulation-first, pilot scope, removable-media rule, sensitive-content condition, allow-list group) with PASS/FAIL output. | Read-only |
| **DLPUSB-Report.ps1** | Roll up policy modes and, where available, **removable-media DLP activity** via Activity-explorer export — the operational + evidence view. Reminds you to pair with the device-control audit from your management tool. | Read-only |
| **DLPUSB-ScopeHealth.ps1** | Report onboarding/scope health (managed-device signals via Graph, policy scope) and preview pilot-scope targeting; `-WhatIf` for any scoping change. | `-WhatIf` / read-only |

## How it maps to the deployment model

| Phase | Deliverables used |
|---|---|
| **Assess** | 01, 02, `DLPUSB-Discovery.ps1`, `DLPUSB-ScopeHealth.ps1` |
| **Design** | 02, 03 (named objects + action decision), 07 |
| **Configure** | 03, `DLPUSB-Configure.ps1 -WhatIf` then `-Commit` (simulation) + device-control audit-first in your management tool |
| **Pilot (simulation/audit)** | 03, 05 (Gate B simulation/audit pass), `DLPUSB-Report.ps1` |
| **Validate** | 05, `DLPUSB-Validate.ps1`, `DLPUSB-Report.ps1` |
| **Expand (enforce)** | 03 (Phase 6), 05 (Gate B enforce pass), 06, 07 |

## Definition of done

- Pilot devices **onboarded** and visible in **Purview → Devices**.
- `USBG-Corporate` removable-storage device group defined and populated.
- `EDLP-USB-Pilot` with `EDLP-Rule-USB` built **in simulation**, all configuration gates (A) PASS.
- `DC-RemovableStorage-Pilot` device-control policy deployed **audit-first** in your management tool.
- Behavioural gates (B) PASS in the **simulation/audit pass**, then in the **enforce pass** for the
  actions the R8 decision blocks/warns/read-only; false-positive gates (C) PASS.
- **Evidence pack** (D) captured and stored with the change record.
- Regulatory / policy determinations (which data, which media, which action) recorded by the
  **compliance / security** owners — not by the administrator.
