# 6. Troubleshooting — Remote Desktop (RDP) Security Hardening

Work top-down: confirm the **profile is applied**, then **the specific setting is present and correct**,
then **conflicts**. Most "it didn't harden" cases are a device that hasn't synced, a setting picked from
the wrong category, or a second policy/baseline setting the same value. Most "we broke RDP" cases are the
expected High-encryption legacy-client refusal. Each symptom below gives the **likely cause** and the
**fix**.

> **Before you start:** verify which problem you have. A device that **refuses an old RDP client** after
> this profile is working *as designed* (High encryption) — that is Test 5, not a fault. A device where
> the **settings never took** is a delivery/scoping problem — start at the top.

## Symptom: The profile never appears / never applies on the device
**Likely cause:** Device not synced, not assigned, or not enrolled.
**Fix:**
1. Confirm the device is in the **pilot device group** and the profile is **assigned**
   (`RDPHARD-Validation.ps1`).
2. Force an Intune sync (**Settings → Accounts → Access work or school → Sync**) and re-check
   **Devices → Configuration → `RDP Hardening - Pilot` → Device status**.
3. Confirm the device is **managed** (R1) and on a supported Windows build (R2).

## Symptom: Profile shows "Error" or "Conflict" in Device status
**Likely cause:** A second Settings Catalog profile, a **security baseline** (CIS/STIG), or a legacy
Administrative Templates (ADMX) profile sets the same RDP value to a different setting.
**Fix:**
1. Run `RDPHARD-Discovery.ps1` and review other Windows configuration profiles/baselines.
2. Ensure only **one** source sets each RDP value (e.g. `MinEncryptionLevel`, `fDisableCdm`); remove or
   reconcile the duplicate. When this overlays a CIS/STIG baseline, decide which policy owns the setting
   and remove it from the other.
3. Re-sync and re-check Device status.

## Symptom: RDP still lets you in without a password prompt
**Likely cause:** `fPromptForPassword` not applied, or credentials are being passed by the client (NLA
single-sign-on) so no interactive prompt appears.
**Fix:**
1. Confirm **Always prompt for password upon connection = Enabled** in the profile (Step 5) and applied
   on the device (`fPromptForPassword = 1`, Test 3).
2. Test with a client that is not passing saved/SSO credentials; NLA can authenticate silently up front
   while the host still enforces the in-session password prompt — validate the intended behavior rather
   than assuming a failure.

## Symptom: Local drives still appear inside the RDP session
**Likely cause:** `fDisableCdm` not applied, or the setting was picked from the wrong category.
**Fix:**
1. Confirm **Do not allow drive redirection = Enabled** under **Device and Resource Redirection**
   (not a different redirection setting) — Step 5.
2. Verify on the device (`fDisableCdm = 1`) and reconnect a fresh RDP session (existing sessions keep
   their redirection until reconnect).

## Symptom: The RDP client can still save the password
**Likely cause:** `DisablePasswordSaving` not applied, or it was set only on the host, not the client.
**Fix:**
1. `DisablePasswordSaving` is a **Remote Desktop Connection Client** setting — it must be applied on the
   **initiating** (client) device, not only the host (R4).
2. Confirm the client device is in scope and shows the profile applied (`DisablePasswordSaving = 1`).

## Symptom: We can no longer RDP to some hosts after enabling High encryption
**Likely cause:** **Expected** — those clients cannot negotiate 128-bit and the host now refuses them
(`MinEncryptionLevel = 3`).
**Fix:**
1. This is Test 5 behaving correctly. Identify the legacy/embedded clients (R5) and **upgrade or
   replace** them.
2. If a host must keep serving a legacy client temporarily, scope that host **out** of the High
   encryption setting until the client is remediated — do not weaken it fleet-wide.

## Symptom: Remote Assistance still works
**Likely cause:** Only one Remote Assistance setting was disabled, or another policy re-enables it.
**Fix:**
1. Confirm **both** **Configure Solicited Remote Assistance = Disabled** (`fAllowToGetHelp = 0`) and
   **Configure Offer Remote Assistance = Disabled** (`fAllowUnsolicited = 0`) — Step 5.
2. Check for a competing GPO/baseline re-enabling Remote Assistance and reconcile ownership.

## Symptom: NLA is not enforced
**Likely cause:** `UserAuthentication` not applied, or the OS/edition negotiated a fallback.
**Fix:**
1. Confirm **Require user authentication … using Network Level Authentication = Enabled**
   (`UserAuthentication = 1`) — Step 5 — and applied on the host (Test 3).
2. Re-check on a supported Windows build (R2); force a sync.

## Symptom: Credential-delegation / Restricted Admin behaves unexpectedly
**Likely cause:** Restricted Admin / Remote Credential Guard is out of scope for this profile and is
owned by the credential-theft hardening solution.
**Fix:**
1. Do not troubleshoot `RestrictedRemoteAdministration` here — this profile hardens the endpoint's RDP
   settings, not the full credential-delegation program.
2. See the **credential-theft hardening solution** (cross-referenced, Implementation Step 13) for that
   setting's deployment and troubleshooting.

## Symptom: Coverage report shows fewer devices than the group
**Likely cause:** Some devices not synced, not enrolled, or superseded by a conflicting profile.
**Fix:**
1. Run `RDPHARD-Report.ps1` to list which devices lack the applied profile.
2. Run `RDPHARD-Remediation.ps1` **(`-WhatIf` first)** to correct assignment/scoping.
3. Re-sync stragglers and confirm enrollment (R1) and no conflicting policy (conflicts above).

## Escalation checklist
Before opening a Microsoft support case, collect: the `RDPHARD-Discovery.ps1` output, the profile's
Device status export, the on-device registry values for the six RDP settings, the affected client
type/version (for legacy-client refusals), the Windows build, and whether any CIS/STIG baseline also
targets RDP (isolates a conflict from a delivery problem).
