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
