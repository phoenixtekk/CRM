# 6. Troubleshooting — Windows Credential Theft Protection

Work top-down: confirm the **profile is applied**, then the **hardware supports VBS**, then the
**runtime state** (Credential Guard running, RunAsPPL set), then **compatibility** (drivers/plug-ins).
Most "Credential Guard won't turn on" cases are a missing hardware prerequisite; most "it broke
something" cases are an incompatible kernel driver or LSA plug-in surfaced by skipping the audit window.
Each symptom below gives the **likely cause** and the **fix**.

> **Before you start:** confirm which control you are diagnosing. Credential Guard, LSASS PPL, WDigest,
> Remote Credential Guard, WinRM, and LAPS are independent profiles — isolate to the one profile whose
> test failed rather than changing all six.

## Symptom: A profile never appears on the device
**Likely cause:** Device not synced, not assigned, or not enrolled.
**Fix:**
1. Confirm the device is in `Credential Protection - Pilot` and the profile is **assigned**
   (`CREDGUARD-Validation.ps1`).
2. Force a sync (**Settings → Accounts → Access work or school → Info → Sync**).
3. Check **Devices → Configuration → (profile) → Device status** for an error.

## Symptom: Credential Guard does not start (SecurityServicesRunning is empty)
**Likely cause:** A hardware prerequisite is missing/disabled, or VBS platform-security level is wrong.
**Fix:**
1. Run `CREDGUARD-Discovery.ps1 -LocalReadiness` — confirm **TPM 2.0, UEFI, Secure Boot, virtualization**
   (R2). Enable whatever is off in firmware.
2. In `Credential Guard - Pilot`, confirm **Turn On Virtualization Based Security = Enabled** and a valid
   **Select Platform Security Level** (Secure Boot).
3. Reboot (VBS/Credential Guard initializes at boot) and re-check `Win32_DeviceGuard`.
4. Exclude devices that cannot meet the prerequisites from the VBS controls.

## Symptom: A driver or app breaks after enabling Credential Guard / HVCI
**Likely cause:** An HVCI-incompatible kernel-mode driver (older VPN, endpoint agent, virtualization
tool).
**Fix:**
1. Review **Event Viewer** for VBS/HVCI driver-compatibility events naming the driver.
2. Update or replace the driver; keep the device in the **without-lock** pilot until clean.
3. If you must back out, unassign the profile (works while **without lock**); UEFI-locked devices require
   the documented VBS-removal procedure (R9).

## Symptom: LSASS protection blocks a security/SmartCard plug-in
**Likely cause:** An unsigned or improperly-signed LSA plug-in is incompatible with RunAsPPL.
**Fix:**
1. Review **… → CodeIntegrity → Operational** (and the LSA log) for **would-block/blocked** events (e.g.
   **3065/3066**) that name the module — this is exactly what the **audit-first** window is for
   (Implementation Step 7).
2. Update/remove the module, or obtain a properly-signed version.
3. Only after the audit is clean, switch `LSASS Protection (RunAsPPL) - Pilot` to **Enabled with UEFI
   lock**. **Verify current event IDs in your build.**

## Symptom: WDigest value still shows 1 (or missing)
**Likely cause:** Profile not applied, or a legacy GPO/registry is re-setting it.
**Fix:**
1. Confirm `WDigest Disabled - Baseline` shows **Succeeded** and re-sync.
2. Check for a conflicting on-prem GPO or startup script setting `UseLogonCredential = 1`; remove it.
3. If the Settings Catalog does not surface the setting, deliver `UseLogonCredential = 0` via the
   **Custom** OMA-URI / remediation fallback (Implementation Step 8).

## Symptom: Outbound RDP breaks after Remote Credential Guard
**Likely cause:** The RDP **target host** does not support/allow Remote Credential Guard, or a mode
mismatch.
**Fix:**
1. Confirm the mode set in `Remote Credential Guard - Pilot` (**Require Remote Credential Guard** vs
   **Restrict Credential Delegation**).
2. Ensure the **host** allows it — *Remote host allows delegation of non-exportable credentials*
   (`AllowProtectedCreds = 1`) and NLA are **host-side** settings owned by the separate **RDP hardening**
   solution, not this profile.
3. For targets that cannot support it, scope those RDP flows out or relax to a compatible mode.

## Symptom: Windows LAPS password is not backed up to Entra
**Likely cause:** Tenant feature off, unsupported build, or backup-directory mis-set.
**Fix:**
1. Entra → **Devices → Device settings** → **Enable Microsoft Entra LAPS = Yes** (Step 11).
2. Confirm the device build supports Windows LAPS (R7) and `Windows LAPS - Baseline` sets **Backup
   Directory = Azure AD (Entra) only**.
3. Check the **Microsoft-Windows-LAPS/Operational** log for the backup result and error code.

## Symptom: Helpdesk cannot retrieve the LAPS password
**Likely cause:** The retriever lacks the read permission.
**Fix:**
1. Grant a role including `microsoft.directory/deviceLocalCredentials/password/read` (R8).
2. Retrieve via Entra → **Devices → (device) → Local administrator password recovery**, or Graph.

## Symptom: Works on some devices, not others
**Likely cause:** Mixed hardware capability or group membership.
**Fix:**
1. Run `CREDGUARD-Report.ps1` to see which devices lack the applied controls.
2. Confirm capable hardware (Test 1) for the VBS controls and correct group membership (R6).
3. Re-sync stragglers; move non-capable devices out of the VBS-control scope.

## Symptom: Coverage report shows fewer devices than the group
**Likely cause:** Some devices not synced, not enrolled, or not capable.
**Fix:**
1. Run `CREDGUARD-Report.ps1` to list the gaps.
2. Run `CREDGUARD-Remediation.ps1` **(`-WhatIf` first)** to correct assignment/scoping.
3. Re-sync and confirm enrollment (R1) and readiness (R2).

## Escalation checklist
Before opening a Microsoft support case, collect: the `CREDGUARD-Discovery.ps1` output (including
`-LocalReadiness`), the profile **Device status** exports, `Win32_DeviceGuard` output, the relevant
CodeIntegrity/LSA and LAPS operational-log events, the exact Windows build, the lock mode in use, and
which specific control (of the six) is failing (isolates the problem to one profile).
