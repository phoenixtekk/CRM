# 2. Requirements — Windows Credential Theft Protection

Confirm **every** requirement below before you begin. Each entry follows the same pattern:
**Description · Why required · How to verify · How to implement if missing.** Category-wide
prerequisites (tenant, Intune licensing, admin roles, pilot group, network) are covered once in the
**Global Requirements — Intune Solutions** document; the items here are specific to deploying
Credential Guard, LSASS protection, WDigest/WinRM/credential-delegation hardening, and Windows LAPS to
corporate Windows 10/11 endpoints.

> **Scope reminder.** These requirements are for **endpoint-side credential-theft hardening** on
> **enrolled Windows 10/11** devices. They deliberately do **not** include RDP **host** hardening,
> full CIS/STIG baselines, or domain-controller changes — those are separate solutions.

## R1. Windows 10/11 devices enrolled in Intune
**Description:** The target endpoints are Intune-enrolled/managed Windows 10 (21H2+) or Windows 11
devices (Entra-joined or hybrid-joined).
**Why:** All six controls are delivered as Intune configuration/Endpoint-security policies; they only
reach enrolled devices.
**Verify:** Intune admin center (`https://intune.microsoft.com`) → **Devices → Windows → Windows
devices**; the device is listed and **managed/compliant**.
**Implement:** Enable **Automatic Enrollment** (Entra → Mobility (MDM) → Microsoft Intune) and
Entra-join the device, or enroll via Autopilot; confirm it appears under **Devices → Windows**.

## R2. Hardware readiness for Credential Guard — TPM 2.0, UEFI, Secure Boot, virtualization
**Description:** Devices targeted for Credential Guard have **TPM 2.0**, **UEFI firmware** (not legacy
BIOS), **Secure Boot enabled**, and **CPU virtualization** (Intel VT-x/AMD-V + SLAT) available.
**Why:** Credential Guard runs inside **virtualization-based security (VBS)**; without these the VBS/LSA
isolation cannot start and the policy has no effect (or errors).
**Verify:** On a candidate device run `CREDGUARD-Discovery.ps1 -LocalReadiness`, or check manually:
`Get-Tpm` (TpmPresent/TpmReady **True**), `Confirm-SecureBootUEFI` (**True**), `msinfo32` → **System
Summary** (BIOS Mode = **UEFI**, Secure Boot State = **On**), and **Virtualization-based security** state.
**Implement:** Enable **TPM**, **UEFI/Secure Boot**, and **virtualization (VT-x/AMD-V)** in firmware
(often OEM-manageable); replace/upgrade devices that lack TPM 2.0. Use the readiness output to build the
**capable-devices** group before assigning `Credential Guard - Pilot`.

## R3. Supported, patched Windows build
**Description:** A current, supported Windows 10 (21H2+) or Windows 11 release with recent cumulative
updates.
**Why:** VBS/Credential Guard, LSA protection defaults, and Windows LAPS availability depend on the OS
build; recent releases fix known compatibility issues.
**Verify:** `winver` on the device, or Intune → device → **Hardware → Operating system version**.
**Implement:** Deploy **Update rings** / **Feature updates**, or upgrade to Windows 11. For LAPS
specifically see R7.

## R4. Driver / application VBS-compatibility awareness
**Description:** Awareness that some **kernel-mode drivers** and legacy agents (older VPN, endpoint
security, virtualization tools) may be incompatible with VBS/HVCI or with LSASS running as a protected
process.
**Why:** Enabling Credential Guard or RunAsPPL on an incompatible device can cause driver failures or
blocked LSA plug-ins — this is why the rollout is pilot- and audit-first.
**Verify:** During the pilot, review **Event Viewer** for VBS/HVCI driver-compatibility events and, for
LSA protection, the LSA "would-block" events (Testing, Test 3 and Test 4).
**Implement:** Update or replace incompatible drivers/agents before expanding; keep the device in the
pilot group until clean.

## R5. Administrative roles for Endpoint security and configuration
**Description:** The operator holds **Intune Administrator** (or Endpoint Security Manager) rights, and
LAPS retrieval will require the appropriate Entra role/permission (R8).
**Why:** Creating Device Guard / Settings Catalog profiles and **Account protection** (Credential Guard,
LAPS) policies requires elevated Intune rights.
**Verify:** Entra → **Roles and administrators**; confirm **Intune Administrator**.
**Implement:** Assign **Intune Administrator**; reserve Global Administrator for tenant-wide switches
such as enabling the Entra LAPS feature (R7).

## R6. Pilot group and a capable-device group
**Description:** An Entra security group `Credential Protection - Pilot` for the initial rollout, plus
(recommended) a group scoped to **Credential-Guard-capable** devices (R2) for the VBS controls.
**Why:** Every control is piloted before fleet rollout; Credential Guard should target only capable
hardware to avoid errors on unsupported devices.
**Verify:** Entra → **Groups**; `Credential Protection - Pilot` exists and contains the pilot devices/users.
**Implement:** Entra → **Groups → New group → Security**; add pilot members. Build the capable-device
group from the readiness assessment (R2) — assigned membership, or a dynamic rule once you have a
device-attribute signal.

## R7. Windows LAPS availability (build + Entra tenant feature)
**Description:** The modern **Windows LAPS** (built into Windows) is available on the device, and the
**Entra ID local administrator password (LAPS)** feature is enabled in the tenant.
**Why:** Windows LAPS with Entra backup requires the **April 11 2023** cumulative update (or later) on a
supported build, and the tenant-level switch must be **on** or Entra backup fails.
**Verify:** Device: `Get-Command Set-LapsADPassword`/`Get-LapsDiagnostics` exist and the
**Microsoft-Windows-LAPS/Operational** log is present. Tenant: Entra → **Devices → Device settings** (or
**All devices → Device settings**) → **Enable Microsoft Entra Local Administrator Password Solution
(LAPS)** = **Yes**.
**Implement:** Patch devices to the required build; in Entra set the LAPS device setting to **Yes**
(Global Administrator or the appropriate role). Do **not** run the legacy on-prem LAPS MSI alongside — use
built-in Windows LAPS.

## R8. LAPS password-retrieval permissions
**Description:** The admins who will retrieve local-admin passwords have the right to read them from Entra.
**Why:** Retrieval is gated by an Entra role/permission (`deviceLocalCredentials`); without it the
password is stored but not readable by the helpdesk.
**Verify:** In Entra → **Devices → (a device) → Local administrator password recovery**, an authorized
admin can show the current password.
**Implement:** Grant a role that includes `microsoft.directory/deviceLocalCredentials/password/read`
(e.g. **Cloud Device Administrator** / **Intune Administrator**, or a custom role); document who may
retrieve.

## R9. Change-management awareness of the UEFI lock and rollback
**Description:** Awareness that the **UEFI lock** on Credential Guard (and optionally LSA protection)
makes those controls **sticky** — they are not removed by simply unassigning the profile.
**Why:** Buyers must plan rollback: removing UEFI-locked VBS requires the documented removal procedure
(and often console/physical access), by design.
**Verify:** Decide per phase whether to use **Enabled with UEFI lock** (production) or **Enabled without
lock** (pilots, easy rollback).
**Implement:** Use **without lock** during the pilot; switch to **with lock** for production waves once
compatibility is proven (Implementation Step 5 and Best Practices).

## R10. Pilot user/device and a test remote host (for delegation testing)
**Description:** At least one pilot device on capable hardware, plus a second Windows host to RDP **to**
when validating Remote Credential Guard.
**Why:** The credential-delegation control is validated by making an outbound RDP connection and
confirming credentials are not delegated.
**Verify:** The pilot device is enrolled (R1), capable (R2), in the pilot group (R6); a reachable RDP
target exists.
**Implement:** Add the pilot device to `Credential Protection - Pilot`; identify an RDP target host
(its **host-side** hardening is the separate RDP solution).
