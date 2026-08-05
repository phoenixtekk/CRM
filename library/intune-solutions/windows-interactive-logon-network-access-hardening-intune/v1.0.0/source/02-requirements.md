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
