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
