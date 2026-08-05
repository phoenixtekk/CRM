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
