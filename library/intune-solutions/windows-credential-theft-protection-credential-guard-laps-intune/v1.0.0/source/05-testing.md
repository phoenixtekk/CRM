# 5. Testing & Validation — Windows Credential Theft Protection

Validate against a **pilot device** on **capable hardware** before expanding. Each test has an explicit
**pass/fail gate**. Use the included PowerShell scripts (Microsoft Graph) for tenant-side checks and the
on-device steps for the runtime state.

> **What "pass" means here:** on the pilot device, Credential Guard is **running**, LSASS is a
> **protected process**, WDigest keeps **no plaintext**, credential delegation is **restricted**, WinRM
> stores **no RunAs credential**, and the device has a **unique, retrievable** LAPS password — with no
> broken drivers/apps.

## Test 1 — Hardware readiness
**Procedure:** Run `CREDGUARD-Discovery.ps1 -LocalReadiness` on the candidate device.
**Pass:** TPM 2.0 present/ready, UEFI + Secure Boot **On**, virtualization available — device is
**Credential-Guard-capable**.
**Fail:** Any prerequisite missing → enable in firmware or exclude the device from the VBS controls (R2).

## Test 2 — Profiles present and assigned
**Procedure:** Run `CREDGUARD-Discovery.ps1` then `CREDGUARD-Validation.ps1`.
**Pass:** All six profiles (`Credential Guard - Pilot`, `LSASS Protection (RunAsPPL) - Pilot`,
`WDigest Disabled - Baseline`, `Remote Credential Guard - Pilot`, `WinRM No RunAs Credentials -
Baseline`, `Windows LAPS - Baseline`) exist and are assigned to `Credential Protection - Pilot`; pilot
devices report **Succeeded**.
**Fail:** Missing/unassigned profile → create/assign (Implementation) or run `CREDGUARD-Remediation.ps1`
(`-WhatIf` first).

## Test 3 — Credential Guard is running (and nothing broke)
**Procedure:** On the pilot device run
`(Get-CimInstance -ClassName Win32_DeviceGuard -Namespace root\Microsoft\Windows\DeviceGuard).SecurityServicesRunning`
(or `msinfo32` → *Virtualization-based security Services Running*). Reboot and confirm normal operation.
**Pass:** `SecurityServicesRunning` contains **1** (Credential Guard); the device boots and core
apps/drivers work.
**Fail:** Credential Guard not running → confirm VBS platform-security level and hardware (Test 1); if a
driver fails, review VBS/HVCI driver-compatibility events (R4) and remediate before expanding.

## Test 4 — LSASS protection audited then enforced
**Procedure:** With `LSASS Protection (RunAsPPL) - Pilot` deployed, review **Event Viewer → …
CodeIntegrity → Operational** (and the LSA log) for **would-block** events (e.g. **3065/3066**); then
confirm `HKLM\SYSTEM\CurrentControlSet\Control\Lsa\RunAsPPL = 1`.
**Pass:** No unresolved would-block events during the audit window; `RunAsPPL = 1`; LSASS runs protected.
**Fail:** A plug-in/driver is flagged as incompatible → update/remove it and re-audit before switching to
UEFI-lock enforcement (Implementation Step 7).

## Test 5 — WDigest keeps no plaintext
**Procedure:** Check `HKLM\SYSTEM\CurrentControlSet\Control\SecurityProviders\WDigest\UseLogonCredential`.
**Pass:** Value = **0** — Windows does not cache reusable plaintext passwords in LSASS.
**Fail:** Value **1** or missing → confirm `WDigest Disabled - Baseline` applied; re-sync or deliver via
the Custom/remediation fallback (Implementation Step 8).

## Test 6 — Remote Credential Guard restricts outbound delegation
**Procedure:** From the pilot device, RDP **out** to the test host (R10) and confirm the connection uses
Remote Credential Guard (no credentials delegated). Confirm the policy value
`HKLM\SOFTWARE\Policies\Microsoft\Windows\CredentialsDelegation\RestrictedRemoteAdministration = 1` with
the Remote Credential Guard mode.
**Pass:** The outbound RDP session works and the originating credential is **not** delegated to the host.
**Fail:** Delegation still occurs, or RDP breaks → verify the mode chosen (Implementation Step 9) and
that the **host side** supports it (that is the separate RDP hardening solution, not this profile).

## Test 7 — WinRM stores no RunAs credential
**Procedure:** Check `HKLM\SOFTWARE\Policies\Microsoft\Windows\WinRM\Service\DisableRunAs`.
**Pass:** Value = **1** — WinRM will not store a RunAs credential.
**Fail:** Missing/0 → confirm `WinRM No RunAs Credentials - Baseline` applied and re-sync.

## Test 8 — Windows LAPS backup and retrieval
**Procedure:** On the pilot device confirm the **Microsoft-Windows-LAPS/Operational** log shows a
successful password backup; in Entra → **Devices → (device) → Local administrator password recovery**,
retrieve the current password as an authorized admin (R8).
**Pass:** A unique local-admin password is backed up to Entra and retrievable; rotation age matches the
policy.
**Fail:** No backup / not retrievable → confirm the Entra LAPS tenant feature is **On** (Step 11), the
build supports Windows LAPS (R7), and the retriever has the permission (R8).

## Test 9 — Coverage report
**Procedure:** Run `CREDGUARD-Report.ps1`.
**Pass:** The report lists the pilot device(s) with the credential-protection controls **applied**;
counts match the assigned group.
**Fail:** Devices missing → run `CREDGUARD-Remediation.ps1` (`-WhatIf` first) and re-sync stragglers.

## Test 10 — Reversibility / no unintended breakage (negative test)
**Procedure:** On a **without-lock** pilot device, unassign a VBS profile and confirm the control backs
out cleanly; confirm no unrelated policy changed.
**Pass:** Without-lock controls revert on unassignment; only the six named profiles were introduced. (For
**UEFI-locked** production devices, removal follows the documented VBS-removal procedure — R9.)
**Fail:** Behavior does not revert as expected for a without-lock device → confirm which lock mode was
set and re-check assignment scope.

## Acceptance gate
Proceed to **Expand** (and to **UEFI-lock enforcement**) only when Tests 1–9 pass on at least one capable
pilot device, the LSASS audit window (Test 4) is clean, Test 10 confirms reversibility for without-lock
devices, and a real pilot user confirms day-to-day apps, VPN, RDP, and sign-in behave normally.
