# 5. Testing & Validation — Windows Advanced Audit Policy & Security Logging Baseline

Validate against a **pilot device** before expanding. Each test has an explicit **pass/fail gate**. Use
the included PowerShell scripts (Microsoft Graph) for tenant-side checks and the on-device steps for the
actual audit behavior.

> **What "pass" means here:** enrolled Windows 10/11 devices apply the `Win Audit Policy - Baseline -
> Pilot` profile, the advanced subcategories are actually in effect on the device (force-subcategory
> override on), and auditable actions produce the expected Security-log events — including command-line
> in 4688. This solution does **not** forward events to a SIEM.

## Test 1 — Tenant readiness
**Procedure:** Run `WINAUDIT-Discovery.ps1`.
**Pass:** A **Settings Catalog** profile named `Win Audit Policy - Baseline - Pilot` exists
(Platform Windows 10 and later), contains the force-subcategory override and audit subcategory settings,
and includes command-line process auditing.
**Fail:** Missing profile, missing override, or no audit settings → resolve before piloting
(`WINAUDIT-Remediation.ps1`).

## Test 2 — Profile assignment
**Procedure:** Run `WINAUDIT-Validation.ps1` (or check **Devices → Configuration → `Win Audit Policy -
Baseline - Pilot` → Assignments**).
**Pass:** The profile is assigned to **`Win Audit Policy - Pilot Devices`** and to no unintended broad
group.
**Fail:** Not assigned, or assigned to "All devices" prematurely → correct the assignment (Implement
Step 7 / `WINAUDIT-Set-ScopeTargeting.ps1`).

## Test 3 — Profile applied on the device
**Procedure:** On the pilot device, sync; then Intune → profile → **Device status**.
**Pass:** The `Win Audit Policy - Baseline - Pilot` profile shows **Succeeded** on the pilot device.
**Fail:** Not applied / error → force a sync, check for a conflicting profile, and review Device status
detail.

## Test 4 — The force-subcategory override is active (the gate everything depends on)
**Procedure:** On the pilot device (elevated): `reg query
"HKLM\SYSTEM\CurrentControlSet\Control\Lsa" /v SCENoApplyLegacyAuditPolicy`.
**Pass:** Returns **`0x1`** — advanced subcategory settings will be honored.
**Fail:** Returns `0x0` or missing → a legacy basic-audit policy is overriding; remove it (R5) and
re-sync. Until this is `1`, every subcategory below is ignored.

## Test 5 — Subcategories are set as intended
**Procedure:** On the pilot device (elevated): `auditpol /get /category:*`.
**Pass:** The 24 subcategories from Implementation Step 6b show the recommended Success/Failure state —
e.g. *Process Creation* = **Success**, *Credential Validation* = **Success and Failure**, *Account
Lockout* = **Failure**.
**Fail:** Any subcategory shows an unexpected state → confirm Test 4 passed, then re-check the profile
values (Step 6b) and re-sync.

## Test 6 — Events are actually generated (including command line)
**Procedure:** On the pilot device, sign out and back in, then launch `cmd.exe` and `powershell.exe`.
In **Event Viewer → Windows Logs → Security**, find the resulting events.
**Pass:** **4624** (logon) and **4688** (process creation) events appear, and the **4688** events
include a populated **Process Command Line** field.
**Fail (no 4688 command line):** Command-line auditing not applied → confirm Step 6c
(`ProcessCreationIncludeCmdLine_Enabled = Enabled`) and re-sync.

## Test 7 — Security log is sized for retention
**Procedure:** **Event Viewer → Security → Properties** (or `wevtutil gl Security`).
**Pass:** **Maximum log size** is **196608 KB** (or your chosen value ≥ CIS minimum 32768 KB), and
retention is *overwrite as needed*.
**Fail:** Still at the small default → confirm Step 6d applied and re-sync.

## Test 8 — Coverage report
**Procedure:** Run `WINAUDIT-Report.ps1`.
**Pass:** The report lists the pilot device(s) as **applied**; counts match the assigned group.
**Fail:** Devices missing → run `WINAUDIT-Remediation.ps1` (`-WhatIf` first) to fix assignment/scoping,
re-sync stragglers.

## Test 9 — Reversibility / no unintended change (negative test)
**Procedure:** Note the device is otherwise unchanged (no enrollment change, no other policy applied by
this profile). Optionally unassign the profile from a spare pilot device and re-run `auditpol`.
**Pass:** This solution only adds the `Win Audit Policy - Baseline - Pilot` configuration profile;
unassigning it cleanly reverts the audit state — no re-enrollment or cleanup needed.
**Fail:** If enrollment or unrelated settings changed, an unintended policy is also present — confirm
this solution deployed the **audit Settings Catalog profile** only.

## Acceptance gate
Proceed to **Expand** only when Tests 1–8 pass on at least one pilot device (Test 4 is mandatory — the
override must be `0x1`), Test 9 confirms the change is isolated and reversible, and Event Viewer shows
the expected 4624/4688 events with command line.
