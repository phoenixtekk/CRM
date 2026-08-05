# Windows Interactive Logon & Network-Access Security Options Hardening (Intune)

> **Version 1.0.0** · Category: Intune · Solution code: WINSECOPT

> This is the online, maintained copy of the implementation guide. When this solution is updated, eligible customers are alerted and can return here for the current content. Downloadable PDF + scripts are attached on the store listing.



---


# Executive Summary — Windows Interactive Logon & Network-Access Security Options Hardening (Intune)

A security assessment of a Windows fleet always leaves a short list of **Security Options and logon
policies** that no other hardening product owns — the settings that sit *between* the well-known
workstreams. The NTLM/SMB, RDP, and credential-theft products each carry their own findings; what is
left over are the **interactive-logon behaviors** and the **network-access controls at the logon
screen** that quietly widen the attack surface: a machine that will happily join an untrusted network
while on the corporate LAN, a smart card that can be pulled without locking the session, an automatic
sign-in that re-establishes the last user after an update reboot, and a network-selection UI exposed
before anyone has authenticated. This solution is the **hardening pack that closes exactly those
leftover findings** using **Microsoft Intune Settings Catalog** — no Group Policy, no imaging.

**A deliberately scoped, gap-only capability.** This package hardens **four** specific Windows
policies and nothing else:

- **Prohibit connection to non-domain networks when connected to a domain-authenticated network** —
  stops a bridged/dual-homed path off the trusted network (Windows Connection Manager,
  `fBlockNonDomain = 1`).
- **Interactive logon: Smart card removal behavior = Lock Workstation** — pulling the card locks the
  session instead of leaving it open (`scremoveoption = 1`).
- **Disable "Sign-in and lock last interactive user automatically after a restart"** — no automatic
  re-establishment of the last user's session after an update reboot (`DisableAutomaticRestartSignOn = 1`).
- **Do not display network selection UI** — hides the network-picker on the sign-in screen so an
  unauthenticated user cannot change connectivity (`DontDisplayNetworkSelectionUI = 1`).

It does **not** re-do the work owned by the NTLM/SMB hardening, RDP hardening, or credential-theft /
LSA-protection products — it complements them and complements a CIS/STIG baseline. It resolves roughly
**four** Windows Client assessment findings that those products leave behind.

**Honest about user impact.** Disabling automatic restart sign-on means that after a Windows Update
reboot, the last interactive user is **not** silently signed back in and locked — the user must log in
again. That is the intended, more-secure behavior; this package calls it out so you can set the
expectation before rollout rather than field surprised tickets.

This package delivers the complete, field-tested method to stand it up in Intune — written so a single
administrator can follow it end to end:

- **One profile, one purpose.** A single named **Settings Catalog** profile —
  **`Interactive Logon & Network-Access Hardening - Pilot`** — carrying the four settings, deployed
  pilot-first and fully reversible by unassigning it.
- **Verify-don't-invent.** Every exact CSP/Settings-Catalog path and value is given, and the ones that
  Microsoft renames between releases are flagged **verify in your tenant** rather than assumed.
- **Pilot-first, reversible.** The standard shape — **Assess → Configure → Pilot → Validate →
  Expand** — with explicit pass/fail gates, a negative test that nothing else changed, and five
  ready-to-run PowerShell scripts (Microsoft Graph; discovery/validation/reporting are read-only,
  remediation and targeting default to a safe preview).

**Outcome:** the leftover interactive-logon and network-access Security-Options findings closed across
the Windows fleet — hardened, proven on a pilot before you scale, without a consulting engagement and
without touching how the devices are enrolled or imaged.


---


# 1. Solution Overview — Windows Interactive Logon & Network-Access Security Options Hardening (Intune)

## What this solution is
This solution hardens a small, specific set of **Windows interactive-logon and network-access
Security Options** on **Windows 10/11** devices managed by **Microsoft Intune**, using the **Settings
Catalog**. It is the **"leftover findings" pack** — the Security-Options and logon policies that a
fleet assessment flags but that are **not owned** by the NTLM/SMB hardening, RDP hardening, or
credential-theft / LSA-protection products. Deploying it removes those remaining findings and
complements a CIS or DISA STIG baseline.

Concretely, it configures **four** policies through Intune Settings Catalog — no on-prem Group Policy,
no imaging, no re-enrollment:

| # | Policy (admin-facing name) | Settings Catalog category | Underlying value |
|---|----------------------------|---------------------------|------------------|
| 1 | Prohibit connection to non-domain networks when connected to domain-authenticated network | Windows Connection Manager | `fBlockNonDomain = 1` (Enabled) |
| 2 | Interactive logon: Smart card removal behavior = **Lock Workstation** | Local Policies\Security Options | `scremoveoption = 1` |
| 3 | Sign-in and lock last interactive user automatically after a restart = **Disabled** | Administrative Templates\Windows Components\Windows Logon Options | `DisableAutomaticRestartSignOn = 1` |
| 4 | Do not display network selection UI = **Enabled** | Administrative Templates\System\Logon | `DontDisplayNetworkSelectionUI = 1` |

> **Scope, stated plainly.** This solution delivers **only** these four Security-Options / logon
> controls. It is **not** NTLM/SMB hardening, **not** RDP hardening, **not** credential-theft
> protection (Credential Guard / LSA protection / LAPS), and **not** a full CIS/STIG baseline — those
> are separate products. It is the pack that catches the **remaining** interactive-logon and
> network-access findings those products leave behind.

## Why these four, and why together
Each of the four is a classic "Security Options" assessment finding that maps to a real, unglamorous
risk at the sign-in boundary. They are shipped together because they share the same delivery method
(one Settings Catalog profile), the same audience (any enrolled Windows client), and the same
lifecycle (pilot, validate, expand):

1. **Prohibit connection to non-domain networks (Windows Connection Manager, `fBlockNonDomain`).**
   When a device is connected to a domain-authenticated (corporate) network, Windows will normally let
   it *also* connect to a non-domain network (a phone hotspot, an untrusted Wi-Fi). That creates a
   **network bridge** off the trusted segment. Enabling this policy blocks the automatic non-domain
   connection while the domain connection is active.
2. **Smart card removal behavior = Lock Workstation (`scremoveoption`).** On smart-card sites, pulling
   the card should **lock** the workstation immediately. Left at the default ("No Action"), a user can
   remove their card and walk away with the session unlocked. Setting it to **Lock Workstation**
   enforces the lock.
3. **Disable automatic restart sign-on (`DisableAutomaticRestartSignOn`).** After a Windows Update
   reboot, Windows can automatically sign the **last interactive user** back in and lock the screen so
   apps resume. Convenient — but it re-establishes a user session without a fresh credential prompt.
   Setting the GPO **"Sign-in and lock last interactive user automatically after a restart"** to
   **Disabled** turns this off (`DisableAutomaticRestartSignOn = 1`), so the user must log in again.
4. **Do not display network selection UI (`DontDisplayNetworkSelectionUI`).** By default the Windows
   sign-in screen shows a network-selection button, letting an **unauthenticated** person at the lock
   screen change network connectivity. Enabling this policy hides that UI.

## How it works, step by step
1. **One Settings Catalog profile.** You create a single **Windows 10 and later → Settings Catalog**
   configuration profile named **`Interactive Logon & Network-Access Hardening - Pilot`** and add the
   four settings from their Settings Catalog categories (Implementation, Phase 2).
2. **Assign to a pilot group.** The profile is assigned to a named pilot group
   (**`SEC - Interactive Logon Hardening Pilot`**) — never to *All devices* first.
3. **Devices sync and apply.** Enrolled Windows devices in the group pick up the profile on their next
   MDM sync; each setting writes its policy CSP value (the registry values in the table above).
4. **Validate the applied state.** The included scripts confirm the profile exists with the four
   settings, is assigned to the intended group, and reports **Succeeded** per device.
5. **Expand in waves.** Once the pilot passes the acceptance gate, broaden the assignment or promote
   the profile to the standard hardening profile for corporate Windows devices.

## What this changes for users (be honest)
- **After an update reboot, users re-authenticate.** With automatic restart sign-on disabled, Windows
  will **not** silently sign the last user back in after an Update reboot. The user sees the normal
  sign-in screen and logs in again. This is the intended hardening — communicate it so it is not
  mistaken for a fault.
- **Smart-card users: removing the card locks the screen.** Expected and desired on card sites; make
  sure users know to keep their card in while working.
- **No network picker at the lock screen.** Users cannot change Wi-Fi from the sign-in screen; they
  connect after signing in (or you pre-provision Wi-Fi via a separate profile).
- **Non-domain networks blocked while on the corporate network.** A device already on the corporate
  network will not auto-join a second, non-domain network at the same time. Roaming devices off the
  corporate network are unaffected.

## Limitations (be honest with buyers)
- **Enrolled Windows 10/11 clients only.** Delivered by Intune MDM; it only reaches enrolled devices.
  It is not a server-hardening or non-Windows product.
- **Gap-only.** It deliberately excludes NTLM/SMB, RDP, credential-theft, and full-baseline controls —
  those are separate solutions. Deploy it *alongside* them, not instead of them.
- **Reversible, but behavioral.** Unassigning the profile reverts the settings; but while assigned,
  the user-impact items above are real and intended.
- **Identifiers can change.** The Settings Catalog display names and setting-definition IDs reflect
  current Microsoft documentation — **verify them in your tenant** before fleet rollout rather than
  assuming, especially the exact `settingDefinitionId` values used by the scripts.

## The standard deployment model
This solution uses **one** repeatable model across our catalog:

> **Enrolled Windows 10/11 devices receive a single named Settings Catalog profile carrying the four
> interactive-logon and network-access Security Options, deployed pilot-first and reversible.**

Every step follows the repeatable pattern: **Assess → Configure → Pilot → Validate → Expand.**


---


# 2. Requirements — Windows Interactive Logon & Network-Access Security Options Hardening

Confirm **every** requirement below before you begin. Each entry follows the same pattern:
**Description · Why required · How to verify · How to implement if missing.** Category-wide
prerequisites (tenant, Intune licensing, admin roles, pilot group, supported Windows baseline,
network) are covered once in the **Global Requirements — Intune Solutions** document; the items here
are specific to this interactive-logon & network-access Security Options hardening pack.

> **Scope reminder.** These requirements are for the **four** Security-Options / logon controls in
> this pack (Windows Connection Manager non-domain block, smart-card removal = Lock Workstation,
> disable automatic restart sign-on, hide the network selection UI). They deliberately do **not**
> include NTLM/SMB, RDP, credential-theft, or full-baseline hardening — those are separate solutions.

## R1. Windows 10/11 devices enrolled in Intune
**Description:** The target devices are Intune-enrolled Windows 10 (21H2+) or Windows 11 clients.
**Why:** The Settings Catalog profile is delivered by Intune MDM; it only reaches enrolled devices.
**Verify:** Intune admin center (`https://intune.microsoft.com`) → **Devices → Windows → Windows
devices**; the device is listed and **managed** (Entra joined or Entra hybrid joined).
**Implement:** Enroll via **Automatic Enrollment** (Entra join + MDM auto-enroll) or Autopilot so the
device appears under **Devices → Windows**. (Enrollment itself is covered by the enrollment solutions.)

## R2. Settings Catalog available in the tenant
**Description:** The Intune **Settings Catalog** profile type for Windows is available.
**Why:** This solution configures all four policies through one Settings Catalog profile rather than
device-configuration templates or on-prem Group Policy.
**Verify:** Intune → **Devices → Configuration → Create → New policy**; choose **Platform = Windows 10
and later**, **Profile type = Settings catalog**; the catalog search opens.
**Implement:** Settings Catalog is standard in current Intune; if it is missing, confirm the tenant is
on a supported service release and your account has the **Intune Administrator** role (Global
Requirement G3).

## R3. Existing hardening coverage identified (avoid overlap)
**Description:** Awareness of what your NTLM/SMB, RDP, credential-theft, and baseline products already
configure.
**Why:** This pack is **gap-only** — it closes the *leftover* interactive-logon and network-access
findings. Deploying it on top of a baseline that already sets one of these four would create a
**duplicate/conflicting** setting.
**Verify:** In Intune → **Devices → Configuration**, review existing security baselines and hardening
profiles for any of: Windows Connection Manager, Interactive logon smart-card removal, automatic
restart sign-on, network selection UI.
**Implement:** If a baseline already sets one of the four, decide a single owner for that setting
(remove it here or there) so exactly one profile controls it — see Best Practices, "Own each setting
once."

## R4. Smart card infrastructure (only if you enable smart-card removal behavior)
**Description:** For control #2 (smart-card removal = Lock Workstation), the fleet actually uses smart
cards / virtual smart cards for logon.
**Why:** The Lock-Workstation-on-removal behavior only has an effect where smart-card logon is in use;
on a fleet with no smart cards the setting is harmless but inert.
**Verify:** Confirm whether users authenticate with PIV/CAC or virtual smart cards (certificate-based
smart-card logon), e.g. via your PKI / certificate-deployment profiles.
**Implement:** If you do not use smart cards, you may still deploy the setting (no effect) or omit
control #2 from the profile — document the choice. If you do use them, keep the value **Lock
Workstation**.

## R5. Network topology understood (Windows Connection Manager non-domain block)
**Description:** For control #1, an understanding of how devices reach the corporate
(domain-authenticated) network and whether any legitimate workflow relies on simultaneous non-domain
connectivity.
**Why:** Blocking non-domain networks while on the domain network is a security win, but a device that
*legitimately* needs a second, non-domain connection at the same time (rare) would be affected.
**Verify:** Confirm the corporate network authenticates the machine to the domain (so Windows sees it
as "domain-authenticated"), and that no supported workflow depends on a concurrent non-domain link.
**Implement:** For the common single-network case, enable the block. If a legitimate dual-connection
workflow exists, document the exception before enabling; the setting is per-device via the profile
assignment.

## R6. User-impact communication plan (automatic restart sign-on)
**Description:** A short comms plan warning users that after a Windows Update reboot they will need to
**sign in again** (no automatic restart sign-on).
**Why:** Control #3 changes a visible behavior. Without a heads-up, users may report the re-login as a
fault.
**Verify:** You have a one-line notice ready for the pilot group ("After updates restart your PC, you
will be asked to sign in again — this is expected and more secure").
**Implement:** Include the notice in the pilot invitation and in fleet comms before you expand.

## R7. Microsoft Graph PowerShell SDK (for the included scripts)
**Description:** The **Microsoft.Graph** PowerShell module installed on the admin workstation that runs
the scripts.
**Why:** All five scripts use Microsoft Graph to read/validate/report and (for remediation/targeting)
to create or assign the profile.
**Verify:** In PowerShell, `Get-Module Microsoft.Graph -ListAvailable` returns a version.
**Implement:** `Install-Module Microsoft.Graph -Scope CurrentUser`. Discovery/Validation/Report need
read scopes (`DeviceManagementConfiguration.Read.All`, `DeviceManagementManagedDevices.Read.All`);
Remediation/Set-ScopeTargeting need `DeviceManagementConfiguration.ReadWrite.All`.

## R8. Pilot group and pilot device
**Description:** A named Entra security group (**`SEC - Interactive Logon Hardening Pilot`**) with at
least one enrolled Windows pilot device.
**Why:** Every solution is validated on a pilot before fleet rollout.
**Verify:** Entra → **Groups**; the group exists and contains the pilot device (or the pilot user, for
a user-targeted assignment). The pilot device is enrolled (R1).
**Implement:** Entra → **Groups → New group → Security**, name it **`SEC - Interactive Logon Hardening
Pilot`**, add the pilot device/user. This is the group used for the profile assignment (Global
Requirement G5).


---


# Global Requirements — Intune Solutions (category-level)

These requirements apply to **every** solution in the **Intune Solutions**
category. They are published once at the category level so individual listings stay small.
Confirm these before deploying *any* Intune solution. Each entry: **Description · Why · Verify · Implement-if-missing.**

## G1. Microsoft Entra ID tenant
**Description:** An active Microsoft Entra ID (Azure AD) tenant.
**Why:** It is the identity backbone for every cloud and Intune-managed resource.
**Verify:** Sign in to `https://entra.microsoft.com` as an administrator.
**Implement:** Create a Microsoft 365/Azure subscription, which provisions a tenant.

## G2. Microsoft Intune subscription
**Description:** An Intune-bearing license plan.
**Why:** Intune delivers all configuration, compliance, and security policies.
**Verify:** `https://intune.microsoft.com` loads; **Tenant administration → Tenant status** shows active.
**Implement:** Assign Microsoft 365 E3/E5, Business Premium, or standalone Intune Plan 1.

## G3. Administrative roles
**Description:** Appropriate Entra/Intune admin roles for the operator.
**Why:** Creating policies and enrollment settings requires elevated rights.
**Verify:** Entra → **Roles and administrators**; confirm **Intune Administrator**.
**Implement:** Assign **Intune Administrator**; reserve Global Administrator for tenant-wide changes.

## G4. Device enrollment in Intune
**Description:** Targeted Windows devices are enrolled and manageable.
**Why:** Policies only reach enrolled devices.
**Verify:** Intune → **Devices → All devices**; the device appears and is **compliant**.
**Implement:** Enable **Automatic Enrollment** and join devices to Entra ID.

## G5. Pilot security group
**Description:** A Microsoft Entra security group for pilot/targeted users or devices.
**Why:** Every solution is piloted before fleet rollout.
**Verify:** Entra → **Groups**; the pilot group exists.
**Implement:** Entra → **Groups → New group** → **Security** → add members.

## G6. Supported Windows baseline
**Description:** Windows 10 21H2+ or Windows 11 with current updates.
**Why:** Modern Intune features assume a patched, supported OS.
**Verify:** `winver`, or Intune → device → **Hardware**.
**Implement:** Deploy **Update rings** or upgrade to Windows 11.

## G7. Network access to Microsoft cloud endpoints
**Description:** Outbound HTTPS to Microsoft 365, Entra, and Intune service URLs.
**Why:** Enrollment, policy sync, and authentication depend on these endpoints.
**Verify:** From a device, reach `https://login.microsoftonline.com` and `https://enrollment.manage.microsoft.com`.
**Implement:** Allow Microsoft's published Office 365/Intune URL & IP ranges through proxy/firewall.

---
**The standard deployment model (all solutions):** **Assess → Configure → Pilot → Validate → Expand.**


---


# 3. Implementation — Windows Interactive Logon & Network-Access Security Options Hardening

Follow these steps **in order**. The *why* for each capability lives in the Solution Overview; the
steps below are deliberately short and exact so you can **click to implement**. Throughout, the
repeatable pattern applies: **Assess → Configure → Pilot → Validate → Expand.** Do everything against a
**pilot group** first.

All admin-center steps use the Microsoft Intune admin center at `https://intune.microsoft.com` unless
noted.

> **This deploys the four Security-Options / logon controls only** on **enrolled Windows 10/11**
> clients, via a single **Settings Catalog** profile. It does not enroll or image devices and does not
> configure NTLM/SMB, RDP, or credential-theft hardening.

---

## Phase 1 — Assess and prepare

### Step 1. Confirm enrollment and the Windows baseline
1. Go to **Devices → Windows → Windows devices** and confirm the pilot device is **managed** (Entra
   joined or Entra hybrid joined).
2. Open the device → **Hardware** and confirm **Windows 10 21H2+** or **Windows 11** with current
   updates.

### Step 2. Check for existing owners of these four settings (avoid conflicts)
1. Go to **Devices → Configuration** and review your existing **security baselines** and hardening
   profiles.
2. Confirm that **none** of them already sets: *Windows Connection Manager* non-domain block,
   *Interactive logon: Smart card removal behavior*, *automatic restart sign-on*, or *Do not display
   network selection UI*. If one does, decide a single owner for that setting before continuing
   (Requirements R3).

### Step 3. Create (or confirm) the pilot group
1. Go to **Groups → New group** (or Entra → **Groups**).
2. **Group type = Security**; **Group name = `SEC - Interactive Logon Hardening Pilot`**.
3. Add the pilot device (for device-targeted assignment) or pilot user, then **Create**.

---

## Phase 2 — Create the Settings Catalog profile

### Step 4. Create the profile
1. Go to **Devices → Configuration → Create → New policy**.
2. **Platform = Windows 10 and later**; **Profile type = Settings catalog**; click **Create**.
3. **Basics → Name:** **`Interactive Logon & Network-Access Hardening - Pilot`**. **Description:**
   *Closes the leftover interactive-logon and network-access Security Options findings (Windows
   Connection Manager non-domain block, smart-card removal = Lock Workstation, disable automatic
   restart sign-on, hide network selection UI).* Click **Next**.

### Step 5. Add setting #1 — Prohibit connection to non-domain networks
1. On **Configuration settings**, click **+ Add settings**.
2. In the settings picker, search **`Windows Connection Manager`** and select that category.
3. Tick **Prohibit connection to non-domain networks when connected to domain authenticated network**.
   Close the picker.
4. Set the setting's toggle to **Enabled**.
   - *Underlying value:* `fBlockNonDomain = 1` (policy CSP
     `WindowsConnectionManager/ProhibitConnectionToNonDomainNetworksWhenConnectedToDomainAuthenticatedNetwork`).
     **Verify the exact display name in your tenant** — Microsoft occasionally revises catalog labels.

### Step 6. Add setting #2 — Interactive logon: Smart card removal behavior
1. Click **+ Add settings** again. Search **`Smart Card Removal Behavior`** (category **Local Policies
   Security Options**).
2. Tick **Interactive Logon Smart Card Removal Behavior**. Close the picker.
3. Set its value to **Lock Workstation**.
   - *Underlying value:* `scremoveoption = 1` (policy CSP
     `LocalPoliciesSecurityOptions/InteractiveLogon_SmartCardRemovalBehavior`). Options are *No Action
     (0)*, **Lock Workstation (1)**, *Force Logoff (2)*, *Disconnect (3)* — choose **Lock Workstation**.

### Step 7. Add setting #3 — Disable automatic restart sign-on
1. Click **+ Add settings**. Search **`Sign-in and lock last interactive user automatically after a
   restart`** (category **Administrative Templates\Windows Components\Windows Logon Options**).
2. Tick the setting. Close the picker.
3. Set the toggle to **Disabled**. *(Disabling this GPO turns automatic restart sign-on OFF.)*
   - *Underlying value:* `DisableAutomaticRestartSignOn = 1` (policy CSP
     `WindowsLogon/DisableAutomaticRestartSignOn` — **verify the catalog wording in your tenant**; the
     ADMX-backed label and the CSP name differ, and setting the ADMX policy to **Disabled** is what
     yields `DisableAutomaticRestartSignOn = 1`).

### Step 8. Add setting #4 — Do not display network selection UI
1. Click **+ Add settings**. Search **`Do not display network selection UI`** (category
   **Administrative Templates\System\Logon**).
2. Tick the setting. Close the picker.
3. Set the toggle to **Enabled**.
   - *Underlying value:* `DontDisplayNetworkSelectionUI = 1` (policy CSP
     `WindowsLogon/DontDisplayNetworkSelectionUI`).

> After Steps 5–8 the profile carries **four** settings. Click **Next**.

### Step 9. Scope tags, assignment, review
1. **Next** through **Scope tags** (set if you use them).
2. **Assignments:** add the **`SEC - Interactive Logon Hardening Pilot`** group. Do **not** assign to
   *All devices* yet. Click **Next**.
3. **Review + create** → **Create**.

> Prefer automation? Run the included **`WINSECOPT-Remediation.ps1`** (Microsoft Graph) to create the
> profile with all four settings if it is missing (defaults to **-WhatIf** — preview first, then re-run
> to apply), **`WINSECOPT-Set-ScopeTargeting.ps1`** to set/adjust the group assignment (also
> **-WhatIf** by default), and **`WINSECOPT-Discovery.ps1`** to confirm the profile is present and
> correctly configured.

---

## Phase 3 — Pilot

### Step 10. Push and confirm the profile
1. On the pilot device, force an MDM sync: **Settings → Accounts → Access work or school →
   (your account) → Info → Sync**.
2. In Intune → **Devices → Configuration → `Interactive Logon & Network-Access Hardening - Pilot` →
   Device status**, confirm the pilot device shows **Succeeded**.

### Step 11. Spot-check the applied values on the device
1. On the pilot device, confirm the four registry values are set (read-only check):
   - `HKLM\SOFTWARE\Policies\Microsoft\Windows\WcmSvc\GroupPolicy\fBlockNonDomain = 1`
   - `HKLM\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Winlogon\scremoveoption = 1`
   - `HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\System\DisableAutomaticRestartSignOn = 1`
   - `HKLM\SOFTWARE\Policies\Microsoft\Windows\System\DontDisplayNetworkSelectionUI = 1`
   - **Verify these exact registry paths in your build** — they reflect current Windows behavior but
     can differ across releases.

### Step 12. Validate the user-visible behavior
1. At the **sign-in screen**, confirm the **network-selection button is gone** (setting #4).
2. If smart cards are in use, **remove the card** from a signed-in pilot device and confirm the
   **session locks** (setting #2).
3. Trigger (or simulate) a **Windows Update reboot** and confirm the device returns to the **sign-in
   screen** rather than auto-signing the last user back in (setting #3). Tell the pilot user this is
   expected (Requirements R6).
4. While connected to the corporate network, confirm the device does **not** auto-join a second,
   non-domain network (setting #1).

---

## Phase 4 — Validate and expand

### Step 13. Validate with the scripts
1. Run **`WINSECOPT-Discovery.ps1`** (tenant readiness: the Settings Catalog profile exists with the
   four settings present).
2. Run **`WINSECOPT-Validation.ps1`** to confirm the profile is **assigned** to the intended group and
   the pilot device shows the profile **applied** (Succeeded).
3. Run **`WINSECOPT-Report.ps1`** to produce a coverage report (which Windows devices have the
   hardening profile applied).

### Step 14. Remediate gaps (safe by default)
1. If the profile is missing or mis-scoped, run **`WINSECOPT-Remediation.ps1`** — it **defaults to
   `-WhatIf`** and prints exactly what it would create/assign. Review, then re-run with
   `-WhatIf:$false` to apply.

### Step 15. Expand in waves
1. Once the pilot passes (Testing gate), broaden the assignment to the next group with
   **`WINSECOPT-Set-ScopeTargeting.ps1`** (or make it the standard hardening profile for corporate
   Windows devices).
2. Re-confirm with **`WINSECOPT-Report.ps1`** after each wave before widening further, and re-check
   that no other baseline has started to co-own one of the four settings (Requirements R3).


---


# 5. Testing & Validation — Windows Interactive Logon & Network-Access Security Options Hardening

Validate against a **pilot device** before expanding. Each test has an explicit **pass/fail gate**.
Use the included PowerShell scripts (Microsoft Graph) for tenant-side checks and the on-device steps
for the applied values and user-visible behavior.

> **What "pass" means here:** the single named Settings Catalog profile is assigned and applied, all
> four settings carry their intended values on the pilot device, and the four user-visible behaviors
> are correct — with nothing else changed on the device.

## Test 1 — Tenant readiness
**Procedure:** Run `WINSECOPT-Discovery.ps1`.
**Pass:** A Windows **Settings Catalog** profile exists that carries all **four** target settings
(Windows Connection Manager non-domain block, smart-card removal behavior, disable automatic restart
sign-on, do not display network selection UI).
**Fail:** Profile missing or one of the four settings absent → create/complete it (Implementation
Steps 4–8, or `WINSECOPT-Remediation.ps1`) before piloting.

## Test 2 — Profile assignment
**Procedure:** Run `WINSECOPT-Validation.ps1` (or check **Devices → Configuration → (profile) →
Assignments**).
**Pass:** The profile is assigned to **`SEC - Interactive Logon Hardening Pilot`** and to no unintended
broad group.
**Fail:** Not assigned, or assigned to "All devices" prematurely → correct the assignment
(Implementation Step 9 / `WINSECOPT-Set-ScopeTargeting.ps1`).

## Test 3 — Profile applied on the device
**Procedure:** In Intune → profile → **Device status** (or on the device, force a sync).
**Pass:** The **`Interactive Logon & Network-Access Hardening - Pilot`** profile shows **Succeeded** on
the pilot device.
**Fail:** Not applied / error → force a sync and re-check; resolve any conflict (Troubleshooting).

## Test 4 — Applied values on the device
**Procedure:** On the pilot device, read the four policy registry values (read-only):
`fBlockNonDomain`, `scremoveoption`, `DisableAutomaticRestartSignOn`, `DontDisplayNetworkSelectionUI`.
**Pass:** All four equal **1** at the paths listed in Implementation Step 11.
**Fail:** Any value missing or `0` → confirm the setting is present in the profile and re-sync; verify
the exact registry path for your Windows build.

## Test 5 — Network selection UI hidden
**Procedure:** Sign out and view the **sign-in screen**.
**Pass:** No **network-selection** button/UI is shown at the lock/sign-in screen (setting #4).
**Fail:** Network picker still visible → confirm setting #4 = **Enabled** and the device re-synced.

## Test 6 — Smart-card removal locks the session
**Procedure:** *(Only if smart cards are used — Requirements R4.)* On a signed-in pilot device, remove
the smart card.
**Pass:** The workstation **locks** immediately (setting #2 = Lock Workstation).
**Fail:** Session stays unlocked → confirm `scremoveoption = 1` and that smart-card logon is actually
in use.

## Test 7 — No automatic restart sign-on after an update reboot
**Procedure:** Trigger (or simulate) a **Windows Update** reboot on the pilot device.
**Pass:** The device returns to the **sign-in screen**; the last user is **not** auto-signed-in and
locked — the user must log in again (setting #3).
**Fail:** The last user's session is silently re-established → confirm the GPO
"Sign-in and lock last interactive user automatically after a restart" is set to **Disabled**
(`DisableAutomaticRestartSignOn = 1`).

## Test 8 — Non-domain network blocked while on the corporate network
**Procedure:** With the pilot device connected to the corporate (domain-authenticated) network,
attempt to connect to a non-domain network (e.g. a phone hotspot).
**Pass:** Windows does **not** automatically establish the concurrent non-domain connection while the
domain connection is active (setting #1).
**Fail:** A second non-domain connection is established automatically → confirm setting #1 = **Enabled**
and the device is seen as domain-authenticated on the corporate network.

## Test 9 — Coverage report
**Procedure:** Run `WINSECOPT-Report.ps1`.
**Pass:** The report lists the pilot device(s) as **profile applied**; counts match the assigned group.
**Fail:** Devices missing from the report → run `WINSECOPT-Remediation.ps1` (`-WhatIf` first) to fix
assignment/scoping.

## Test 10 — Nothing else changed (negative test)
**Procedure:** Confirm the profile carries **only** the four target settings, and the device's
enrollment, ownership, and other baselines are unchanged.
**Pass:** Only the four Security-Options / logon values changed; NTLM/SMB, RDP, credential-theft, and
other baseline settings are untouched (this pack is gap-only).
**Fail:** Other settings changed → confirm you added only the four settings in Steps 5–8 and that no
duplicate/conflicting profile is present.

## Acceptance gate
Proceed to **Expand** only when Tests 1–9 pass on at least one pilot device, Test 10 confirms the
change is limited to the four settings, and a real pilot user confirms the update-reboot re-login
behavior is understood and acceptable.


---


# 6. Troubleshooting — Windows Interactive Logon & Network-Access Security Options Hardening

Work top-down: confirm the **profile is applied**, then that **each of the four settings carries the
intended value**, then the **user-visible behavior**. Most issues are a missing setting in the
profile, a **conflict** with a security baseline that already owns the same policy, or the
"Disabled-means-on" inversion on the automatic-restart-sign-on control. Each symptom below gives the
**likely cause** and the **fix**.

> **Before you start:** confirm no other product owns these settings. If a security baseline or another
> hardening profile already sets one of the four, that is an ownership/conflict problem (Requirements
> R3), not a profile error.

## Symptom: The profile never appears on the device
**Likely cause:** Device not synced, not assigned, or not enrolled.
**Fix:**
1. Confirm the device is in **`SEC - Interactive Logon Hardening Pilot`** and the profile is
   **assigned** (`WINSECOPT-Validation.ps1`).
2. Force a sync: **Settings → Accounts → Access work or school → (account) → Info → Sync**.
3. Check **Devices → Configuration → (profile) → Device status** for an error.

## Symptom: Profile shows "Error" / "Conflict" in Device status
**Likely cause:** A security baseline or a second hardening profile already sets one of the four
policies to a different value.
**Fix:**
1. Run `WINSECOPT-Discovery.ps1` and review your baselines for Windows Connection Manager,
   Interactive-logon smart-card removal, automatic restart sign-on, or network selection UI.
2. Decide a **single owner** for the conflicting setting — remove it from the baseline or from this
   profile so exactly one profile controls it (Requirements R3).
3. Re-sync and re-check Device status.

## Symptom: A setting isn't taking effect on the device
**Likely cause:** The setting was not actually added to the profile, or its value is wrong.
**Fix:**
1. Confirm all **four** settings are present in the profile (`WINSECOPT-Discovery.ps1` / profile UI).
2. Spot-check the registry value on the device (Testing, Test 4): the value should be **1** at the
   documented path.
3. If the value is missing, re-add the setting (Implementation Steps 5–8) and re-sync.

## Symptom: Automatic restart sign-on still happens after an update reboot
**Likely cause:** The **inversion** — the ADMX policy was set to *Enabled* instead of **Disabled**, so
automatic restart sign-on is still on.
**Fix:**
1. Open the profile and confirm **"Sign-in and lock last interactive user automatically after a
   restart"** is set to **Disabled** (this yields `DisableAutomaticRestartSignOn = 1`).
2. Spot-check `HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\System\DisableAutomaticRestartSignOn = 1`.
3. Re-sync and re-test the update reboot (Testing, Test 7).

## Symptom: Smart-card removal doesn't lock the screen
**Likely cause:** Smart-card logon isn't actually in use, or the value isn't Lock Workstation.
**Fix:**
1. Confirm the fleet uses smart-card / virtual-smart-card **logon** (Requirements R4) — the behavior
   only fires for card-based logon.
2. Confirm the setting value is **Lock Workstation** (`scremoveoption = 1`), not "No Action".
3. Re-sync and re-test (Testing, Test 6).

## Symptom: Network selection UI still shows at sign-in
**Likely cause:** Setting #4 not Enabled, or the device hasn't re-synced.
**Fix:**
1. Confirm **Do not display network selection UI = Enabled** (`DontDisplayNetworkSelectionUI = 1`).
2. Force a sync and lock the device to re-render the sign-in screen.
3. If users now can't pick Wi-Fi before logon, pre-provision the corporate Wi-Fi with a separate Wi-Fi
   profile (Best Practices).

## Symptom: A legitimate workflow lost its non-domain connection
**Likely cause:** Setting #1 is blocking a *legitimately* needed concurrent non-domain connection.
**Fix:**
1. Confirm the workflow genuinely needs simultaneous domain + non-domain connectivity (rare —
   Requirements R5).
2. If it does, scope this device out of the assignment (exclusion group via
   `WINSECOPT-Set-ScopeTargeting.ps1 -ExcludeGroupId ...`) and document the exception, rather than
   disabling the setting fleet-wide.

## Symptom: Works for some devices, not others
**Likely cause:** Group membership, sync timing, or a per-device conflict.
**Fix:**
1. Confirm affected devices are in the assigned group (`WINSECOPT-Report.ps1`).
2. Re-sync stragglers and confirm enrollment (Requirements R1).
3. Check Device status on the affected devices for a conflict with another profile.

## Symptom: Coverage report shows fewer devices than the group
**Likely cause:** Some devices not synced, not enrolled, or in an error state.
**Fix:**
1. Run `WINSECOPT-Report.ps1` to list which devices lack the applied profile.
2. Run `WINSECOPT-Remediation.ps1` **(`-WhatIf` first)** to correct assignment/scoping.
3. Re-sync stragglers and confirm enrollment (Requirements R1).

## Escalation checklist
Before opening a Microsoft support case, collect: the `WINSECOPT-Discovery.ps1` output, the profile's
Device status export, the four registry values from an affected device, the Windows build/version, and
whether any security baseline co-owns one of the four settings (isolates a genuine platform issue from
a policy conflict).


---


# 7. Best Practices — Windows Interactive Logon & Network-Access Security Options Hardening

These practices keep the hardening pack precise, predictable, and reversible on enrolled Windows 10/11
devices. They assume the deployment model in the Solution Overview: a single named **Settings Catalog**
profile carrying the four interactive-logon and network-access controls, deployed via Intune,
pilot-first.

## Own each setting once
- **This pack is gap-only — don't co-own settings.** Before deploying, confirm your NTLM/SMB, RDP,
  credential-theft, and CIS/STIG baselines do **not** already set any of these four. Two profiles that
  set the same policy differently produce a **conflict** ("Error" in Device status).
- **One profile per concern.** Keep these four in the single named profile
  **`Interactive Logon & Network-Access Hardening - Pilot`** so the owner of each Security-Options
  finding is obvious. If a baseline must own one of the four, remove it here.

## Communicate the user-visible changes before you enable them
- **Automatic restart sign-on off = re-login after updates.** Send the one-line notice from
  Requirements R6 to the pilot group and again before each expansion wave. This single behavior drives
  most of the "is it broken?" tickets — pre-empt it.
- **Smart-card removal locks the screen.** On card sites, remind users to keep the card in while
  working; the lock-on-removal is the intended protection.
- **No network picker at sign-in.** If users occasionally need to pick Wi-Fi before logging in,
  pre-provision the corporate Wi-Fi with a separate Wi-Fi profile so hiding the picker doesn't strand
  them.

## Scope narrowly, then widen
- **Assign to `SEC - Interactive Logon Hardening Pilot`, never "All devices" first.** Expand in waves
  after each gate passes.
- **Rollback is unassignment.** Because this only adds a configuration profile, removing the
  assignment reverts the four settings — no imaging or account cleanup. Keep the profile so you can
  re-target quickly.

## Get the values right, and verify them
- **Use the intended values exactly:** Windows Connection Manager block **Enabled** (`fBlockNonDomain =
  1`); smart-card removal **Lock Workstation** (`scremoveoption = 1`); automatic restart sign-on GPO
  **Disabled** (`DisableAutomaticRestartSignOn = 1`); do not display network selection UI **Enabled**
  (`DontDisplayNetworkSelectionUI = 1`).
- **Verify catalog labels and CSP names in your tenant.** Microsoft renames Settings Catalog display
  strings and occasionally the `settingDefinitionId` values; confirm current names before a wide
  rollout, and update the scripts' identifiers to match if they have drifted.
- **Mind the "Disabled means on" inversion.** Control #3 is the one that trips people up: you set the
  ADMX policy to **Disabled** to *disable* automatic restart sign-on. Double-check this one on the
  pilot with the registry spot-check (Testing, Test 4).

## Operate and monitor
- **Report before you widen.** Run `WINSECOPT-Report.ps1` each wave; only broaden when coverage matches
  the assigned group.
- **Remediate with `-WhatIf` first.** `WINSECOPT-Remediation.ps1` and
  `WINSECOPT-Set-ScopeTargeting.ps1` preview by default — read the plan, then apply with
  `-WhatIf:$false`.
- **Re-check ownership after baseline changes.** Whenever you update a security baseline, re-run
  Discovery to confirm the baseline hasn't started to co-own one of these four settings.

## Change control
- **Version scope changes.** When you adjust a value or the assignment, note the date and reason;
  re-run Discovery and Report to confirm no regressions.
- **Review after major Windows upgrades.** Confirm the four settings still apply and the registry paths
  still match after significant Windows feature updates before expanding further.


---


# 8. Deliverables Summary — Windows Interactive Logon & Network-Access Security Options Hardening

Everything included in this solution package, and what each piece is for.

## Documentation (this guide)
- **Executive Summary** — the business case and outcome in one page, and the explicit scope: the four
  leftover interactive-logon and network-access Security Options findings, not NTLM/SMB, RDP,
  credential-theft, or full-baseline hardening.
- **Solution Overview** — what each of the four controls does (Windows Connection Manager non-domain
  block, smart-card removal = Lock Workstation, disable automatic restart sign-on, hide the network
  selection UI), the exact values, the honest user-impact, and how this pack is gap-only and
  complements a CIS/STIG baseline.
- **Requirements Guide** — every Intune/Windows prerequisite with how to **verify** and how to
  **implement if missing**, including checking for existing owners of these settings, plus the
  category-level Global Requirements.
- **Implementation Guide** — exact, ordered, click-by-click steps across four phases: assess and
  prepare, build the single named Settings Catalog profile with the four settings, pilot, then
  validate and expand.
- **Testing & Validation** — ten tests with explicit pass/fail gates (including registry spot-checks
  and a negative test that nothing else changed) and an acceptance gate.
- **Troubleshooting** — top-down diagnosis for missing/not-applying settings, baseline conflicts, the
  "Disabled-means-on" inversion, and the user-visible behaviors.
- **Best Practices** — owning each setting once, communicating the user-visible changes, precise values
  with verify-in-tenant discipline, and reversible pilot-first rollout.

## PowerShell scripts (Microsoft Graph) — `WINSECOPT-Scripts.zip`
All scripts are tenant-side (run from an admin workstation with the Microsoft Graph PowerShell SDK);
each has a header explaining **Purpose · How to run · Expected results**. Discovery, Validation, and
Report are **read-only**; Remediation and Set-ScopeTargeting **default to `-WhatIf`** (preview first,
then apply).

1. **`WINSECOPT-Discovery.ps1`** — tenant readiness: a Windows Settings Catalog profile is present that
   carries all four target settings.
2. **`WINSECOPT-Validation.ps1`** — validates the profile's **assignment** and per-device **applied**
   state, with a clear PASS/FAIL summary.
3. **`WINSECOPT-Report.ps1`** — tenant-wide CSV report of Windows devices and whether the hardening
   profile is applied — the coverage report.
4. **`WINSECOPT-Remediation.ps1`** — safe remediation: creates the Settings Catalog profile with the
   four settings if missing and assigns it to a target group. **`-WhatIf` by default**; applies only
   when re-run with `-WhatIf:$false`.
5. **`WINSECOPT-Set-ScopeTargeting.ps1`** — sets/adjusts the profile's group assignment (target-group
   builder, with optional exclusion group). **`-WhatIf` by default.**

## Hero image
- **`WINSECOPT-hero.png`** — the product image used on the marketplace listing.

## How it's delivered
A **Word** document and **PDF** (cover, table of contents, page numbers, and a scripts appendix), plus
all five PowerShell scripts in a single **ZIP** — yours to keep and reuse across **unlimited devices**.
