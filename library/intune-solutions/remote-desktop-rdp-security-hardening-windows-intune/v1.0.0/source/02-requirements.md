# 2. Requirements — Remote Desktop (RDP) Security Hardening for Windows Endpoints

Confirm **every** requirement below before you begin. Each entry follows the same pattern:
**Description · Why required · How to verify · How to implement if missing.** Category-wide
prerequisites (tenant, Intune licensing, admin roles, pilot group, network) are covered once in the
**Global Requirements — Intune Solutions** document; the items here are specific to hardening RDP on
Windows endpoints via the Intune Settings Catalog.

> **Scope reminder.** These requirements are for **endpoint-side** RDP hardening (host and client
> behavior) on **enrolled, managed Windows 10/11** devices. They deliberately do **not** include
> network/gateway controls (RD Gateway, firewall, VPN) or the full credential-theft program — those
> are separate solutions.

## R1. Enrolled, managed Windows 10/11 endpoints
**Description:** The target devices are Intune-enrolled Windows 10/11 clients (Entra-joined or
hybrid-joined).
**Why:** The Settings Catalog configuration profile is delivered by Intune MDM and only reaches
enrolled, managed devices.
**Verify:** Intune admin center (`https://intune.microsoft.com`) → **Devices → Windows → Windows
devices**; the device is listed and **managed**.
**Implement:** Enroll the device (Automatic Enrollment on Entra join, or Autopilot) so it appears under
**Devices → Windows** as managed (Global Requirement G4).

## R2. Supported Windows baseline
**Description:** Windows 10 21H2+ or Windows 11 with current updates on the target endpoints.
**Why:** The Administrative Templates / Settings Catalog RDP settings and their CSP delivery assume a
patched, supported Windows client.
**Verify:** On the device run `winver`; or Intune → device → **Hardware**.
**Implement:** Deploy **Update rings** or upgrade to Windows 11 (Global Requirement G6).

## R3. Settings Catalog availability
**Description:** Access to **Devices → Configuration → Create → New policy → Windows 10 and later →
Settings catalog** in your Intune tenant.
**Why:** This solution builds the RDP hardening profile from Settings Catalog **Administrative
Templates** settings.
**Verify:** In Intune, start **Create → New policy** and confirm **Settings catalog** is selectable for
**Windows 10 and later**.
**Implement:** Settings Catalog is available in all current Intune tenants; if absent, confirm the
tenant's Intune licensing (Global Requirement G2) and region.

## R4. Inventory of RDP hosts and clients
**Description:** Knowledge of which endpoints **accept** incoming RDP (hosts) and which **initiate**
outbound RDP (clients / admin jump boxes).
**Why:** The RDSH settings matter most on hosts; the saved-password and credential-delegation settings
matter on clients. Knowing the split lets you target and interpret results correctly.
**Verify:** Review your remote-access practice; on a device, RDP-host state is
`HKLM\SYSTEM\CurrentControlSet\Control\Terminal Server\fDenyTSConnections` (`0` = RDP enabled). The
included `RDPHARD-Report.ps1` summarizes coverage across devices.
**Implement:** If you do not need a device to host RDP at all, disabling RDP there is stronger than
hardening it — note those devices and exclude or separately handle them.

## R5. Legacy-client impact assessment (before High encryption)
**Description:** Confirmation of whether any RDP clients in scope cannot negotiate **128-bit**
encryption.
**Why:** Setting encryption to **High** (`MinEncryptionLevel = 3`) causes the host to **refuse**
sub-128-bit clients. Modern clients are fine; genuinely legacy/embedded clients may break.
**Verify:** Identify any old thin clients, embedded RDP clients, or third-party RDP tools that connect
to in-scope hosts; test one against a piloted host (Testing, Test 5).
**Implement:** Upgrade or replace legacy clients before expanding, or scope those hosts out of the High
encryption setting until the clients are remediated.

## R6. The RDP hardening configuration profile
**Description:** A Windows **Settings Catalog** configuration profile named **`RDP Hardening - Pilot`**
carrying the five findings plus NLA.
**Why:** This profile is what enforces the hardened RDP settings on the endpoint.
**Verify:** Intune → **Devices → Configuration**; a profile named **`RDP Hardening - Pilot`** exists and
is assigned to your pilot group. Confirm with `RDPHARD-Discovery.ps1`.
**Implement:** Create it during deployment (Implementation Guide, Phase 2), or create/assign it with the
included `RDPHARD-Remediation.ps1` (defaults to **-WhatIf** preview).

## R7. Pilot security group
**Description:** A Microsoft Entra security group of pilot **devices** for the first assignment.
**Why:** Every solution is validated on a pilot before fleet rollout; RDP hardening includes a
breaking-change setting (High encryption) that must be piloted.
**Verify:** Entra → **Groups**; the pilot device group exists (Global Requirement G5).
**Implement:** Entra → **Groups → New group → Security**; add the pilot devices. Assign the profile to
this group (Implementation Step 7 / `RDPHARD-Set-ScopeTargeting.ps1`).

## R8. Admin workstation for the PowerShell scripts (Microsoft Graph)
**Description:** A workstation with **PowerShell 7+** and the **Microsoft Graph PowerShell SDK**
installed, run by an operator with Intune admin rights.
**Why:** The five included scripts validate and remediate the profile through Microsoft Graph.
**Verify:** `Get-Module -ListAvailable Microsoft.Graph.Authentication` returns a version; the operator
can `Connect-MgGraph`.
**Implement:** `Install-Module Microsoft.Graph -Scope CurrentUser`. Read-only scripts need
`DeviceManagementConfiguration.Read.All` (Report also needs
`DeviceManagementManagedDevices.Read.All`); change-making scripts need
`DeviceManagementConfiguration.ReadWrite.All`.

## R9. Awareness of adjacent controls (network + credential)
**Description:** Awareness that this solution is the **endpoint** layer and pairs with network-side and
credential-side controls.
**Why:** Hardened RDP settings on the endpoint do not replace an RD Gateway, network segmentation, or a
full credential-theft program (Restricted Admin / Remote Credential Guard). Setting expectations
prevents "we hardened RDP but exposure X remains" gaps.
**Verify:** Confirm your RD Gateway / firewall posture and whether the credential-theft hardening
solution is (or will be) deployed for the credential-delegation side.
**Implement:** Deploy the network controls separately; deploy the credential-theft hardening solution
for Restricted Admin / Remote Credential Guard (cross-referenced in Implementation, Phase 4).

## R10. Pilot device that hosts (or initiates) RDP
**Description:** At least one enrolled pilot Windows device that actually **accepts** incoming RDP (and,
ideally, one that **initiates** it), so silent-vs-breaking behavior is observable.
**Why:** You cannot validate encryption, password-prompt, redirection, and Remote Assistance behavior on
a device that never sees an RDP session.
**Verify:** On the pilot host, `fDenyTSConnections = 0` (RDP enabled); you can initiate an RDP session to
it from a test client.
**Implement:** Add the pilot host/client to the **pilot security group** (R7) used for the profile
assignment, and confirm you can reach it over RDP from a controlled test client.
