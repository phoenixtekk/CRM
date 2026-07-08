# Requirements — Endpoint DLP for Windows in Microsoft Purview

Confirm every prerequisite below **before** you configure anything. Category-level prerequisites
(tenant, compliance licensing model, least-privilege roles, Security & Compliance PowerShell / Graph
toolchain, in-scope data sources, compliance/privacy/legal stakeholders, pilot scope + change
control) are in `global-requirements-purview.md` — reference them; they are **not** repeated here.
The items below are the ones **specific to Windows Endpoint DLP**: **device onboarding**, the
**endpoint global settings**, and the **per-channel** control decisions.

Each requirement is written as **Description · Why · Verify · Implement if missing.**

---

## R1. Endpoint DLP licensing, assigned to in-scope users

**Description:** The licensing that includes **Endpoint DLP** — typically **Microsoft 365 E5**, the
**E5 Compliance**, or the **E5 Information Protection & Governance** add-on — assigned to the users
who sign in to the **in-scope Windows devices**.
**Why:** Endpoint DLP is a premium, plan-gated capability; without the right licence the **Devices**
location and the endpoint activities are not available, and endpoint enforcement is licensed **per
user**.
**Verify:** Microsoft 365 admin center → **Billing → Licenses** confirms the SKU/add-on. In the
Purview portal, **Data Loss Prevention** exposes the **Devices** location and **Settings → Device
onboarding** is present. Cross-check advanced endpoint activities against the *Microsoft Purview
service description* — **verify against your licensing/tenant.**
**Implement if missing:** Acquire and assign the required SKU/add-on to in-scope users before
onboarding devices or authoring endpoint rules.

## R2. Least-privilege roles for DLP + device onboarding

**Description:** The least-privilege roles, mapped to **named** people:
- **Compliance Administrator** or **Compliance Data Administrator** (or the **DLP Compliance
  Management** role group) to author the DLP policy and rules and to configure Endpoint DLP settings.
- The rights to **onboard devices** by your chosen method (e.g. **Intune Administrator** for an
  Intune configuration profile, or a device/GPO administrator for Group Policy / local script).
- **Global Administrator** only where genuinely required (e.g. first-time service enablement).
**Why:** Purview uses fine-grained role groups; policy authoring and device onboarding are distinct
duties and should not be over-granted to one account.
**Verify:** Purview portal → **Roles & scopes / Permissions** confirms the DLP role membership;
your device-management console confirms the onboarding role. `DLPWIN-Discovery.ps1` reports the DLP
policy/role signals it can read.
**Implement if missing:** Assign the least-privilege role for each duty under change control.

## R3. Supported, healthy Windows devices ready to onboard

**Description:** In-scope endpoints running a **supported Windows build** (Windows 10 version 1809 or
later, or Windows 11) with a current **antimalware client** and the servicing/updates Endpoint DLP
requires, joined/managed in a way that supports your onboarding method.
**Why:** Endpoint DLP sensing depends on the Windows client components; unsupported or unpatched
devices will not report endpoint activities reliably.
**Verify:** Confirm the OS build and update state on a sample of devices; `DLPWIN-Discovery.ps1`
(Graph) reports managed-device OS/version signals where readable. **Confirm exact minimum build/AV
requirements against current Microsoft docs for your tenant.**
**Implement if missing:** Patch/upgrade devices to a supported build and healthy AV state before
onboarding.

## R4. A device-onboarding method chosen and available

**Description:** A chosen method to **onboard Windows devices to Microsoft Purview** — one of
**Microsoft Intune** (endpoint DLP / device onboarding configuration profile), **Group Policy**,
**local onboarding script**, or **Microsoft Configuration Manager** — using the onboarding package
from **Purview → Settings → Device onboarding**. (Onboarding is shared with **Microsoft Defender for
Endpoint**; devices already onboarded to Defender for Endpoint may already satisfy this.)
**Why:** Onboarding is what makes endpoint activities visible to Purview; the method must fit how
the estate is managed and be repeatable for the pilot and expansion rings.
**Verify:** Purview → **Settings → Device onboarding** shows the onboarding packages/options; a test
device appears in the **Devices** list after onboarding. `DLPWIN-ScopeHealth.ps1` prompts to confirm
onboarding status in-portal and reports managed-device counts (Graph) as a proxy.
**Implement if missing:** Select the onboarding method that matches your management tooling, download
the package, and onboard the **pilot** devices first.

## R5. In-scope sensitive content to key the rules on (labels and/or SITs)

**Description:** The **sensitive content** the endpoint rules will match — **sensitivity labels**
(e.g. *Confidential*) already published and in use, and/or **sensitive information types** (built-in
or custom) and/or trainable classifiers — that define *what* triggers the USB/print/clipboard/
network/cloud rules.
**Why:** An endpoint rule acts on **content that matches a condition**; without labels or SITs to
match, the rule has nothing to key on (or would apply to *all* content, which is rarely intended).
**Verify:** Purview → **Information Protection → Labels** shows the labels published; **Data
classification → Sensitive info types** shows the SITs; content in scope carries labels (Activity/
Content explorer where available). `DLPWIN-Discovery.ps1` inventories labels and SITs.
**Implement if missing:** Publish/adopt the needed sensitivity labels or select the SITs first. (A
full labeling rollout may be a separate project; endpoint rules can start on SITs and add label
conditions once labels are in use.)

## R6. Endpoint DLP global settings defined (device / printer / share groups, browsers, domains)

**Description:** The **Endpoint DLP settings** every endpoint rule depends on, defined with your
stakeholders and named:
- **Removable-storage device groups** (which USB devices are corporate/allowed vs restricted).
- **Printer groups** (which printers are sanctioned).
- **Network-share coverage / groups** (which shares are in scope or excluded).
- **Browser and domain restrictions** — **unallowed browsers**, **service domains** (allowed) and
  **sensitive service domains**, and **unallowed cloud service domains** for cloud-egress control.
- **Restricted apps / app groups**, **file-path exclusions**, and (where used) **VPN settings** and
  **business-justification** options.
**Why:** These settings are the *vocabulary* the rules speak — "block copy to USB **except** the
corporate device group," "block upload **except** to sanctioned service domains." Without them the
rules cannot distinguish sanctioned from unsanctioned paths.
**Verify:** Purview → **Data Loss Prevention → Endpoint DLP settings** shows each group/list defined.
`DLPWIN-Discovery.ps1` reports the endpoint settings it can read and flags anything not readable.
**Implement if missing:** Define the groups and lists **before** authoring the rules that reference
them. **Verify the exact settings pages and option names against your tenant** (they evolve).

## R7. The Microsoft Purview browser extension for Chrome/Firefox (cloud-egress + clipboard-to-web)

**Description:** The **Microsoft Purview browser extension** deployed to **Chrome** and **Firefox**
on in-scope devices, so cloud-egress and clipboard-to-web activity is visible in those browsers.
(**Microsoft Edge** is covered natively and needs no extension.)
**Why:** Without the extension, Chrome/Firefox uploads and web-paste actions are **not** seen or
controlled — a coverage gap that undermines the cloud-egress rule.
**Verify:** Confirm the extension is installed/managed on a sample of Chrome and Firefox instances
(e.g. via your browser management policy). **Verify deployment method against current Microsoft
docs.**
**Implement if missing:** Deploy the extension (via Intune/GPO or the browser's enterprise policy)
to in-scope Chrome/Firefox before relying on the cloud-egress rule for those browsers.

## R8. Per-channel control decision (audit / warn / block) — agreed with stakeholders

**Description:** A documented decision, **per channel** (USB, print, clipboard, network share, cloud
egress), of the intended action — **Audit**, **Warn with override**, or **Block** — and which
sensitive content each applies to, agreed with **compliance / security** (and HR/legal where the
action affects users).
**Why:** The action is a **policy decision, not a technical default**; blocking versus auditing a
channel has real operational and user impact and must reflect enterprise policy, not the
administrator's preference.
**Verify:** Confirm the per-channel action matrix and the in-scope content **in writing** before you
move any rule from simulation to enforce.
**Implement if missing:** Capture the decision with the relevant owners; until then, deploy **audit
/ simulation only.** (See `global-requirements-purview.md` §5.)

## R9. A named pilot device group and change control (simulation/test first)

**Description:** A **named pilot device group** (a limited set of onboarded devices, e.g.
`DG-EDLP-Pilot`, or a pilot user group `SG-EDLP-Pilot`) and agreement to run the policy in
**simulation/test mode first**, under a **change-control** process, before any enforcing,
broad-scope rollout.
**Why:** Endpoint block actions are high-impact; simulation on a small ring proves the channels are
seen and the rules *would* act **without** disrupting real work, and lets you tune before enforcing.
**Verify:** Confirm the pilot group exists and is onboarded, that **simulation/test mode** is used,
and a change window/approval path. `DLPWIN-ScopeHealth.ps1` (`-WhatIf`) previews pilot-scope
targeting.
**Implement if missing:** Define the pilot group, onboard it, deploy in simulation, and agree change
control before enabling enforcement.
