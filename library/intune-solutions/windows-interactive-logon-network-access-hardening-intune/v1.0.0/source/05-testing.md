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
