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
