# 5. Testing & Validation — Remote Desktop (RDP) Security Hardening

Validate against a **pilot device** before expanding. Each test has an explicit **pass/fail gate**.
Use the included PowerShell scripts (Microsoft Graph) for tenant-side checks and the on-device steps
for the enforced behavior. Test 5 is the **legacy-client** test — the one that gates expansion because
High encryption is a breaking change.

> **What "pass" means here:** the managed Windows endpoint enforces the five hardened RDP settings
> (High encryption, always prompt for password, no drive redirection, no saved passwords, Remote
> Assistance disabled) plus NLA, verifiable both in Intune and on the device — and legacy-client impact
> is known before you widen.

## Test 1 — Tenant readiness
**Procedure:** Run `RDPHARD-Discovery.ps1`.
**Pass:** A Settings Catalog profile named **`RDP Hardening - Pilot`** exists and reports the expected
RDP settings present (encryption, password prompt, drive redirection, saved passwords, Remote
Assistance, NLA).
**Fail:** Missing profile or missing settings → create/complete it (Implementation Phase 2 /
`RDPHARD-Remediation.ps1`).

## Test 2 — Profile assignment
**Procedure:** Run `RDPHARD-Validation.ps1` (or check **Devices → Configuration → `RDP Hardening -
Pilot` → Assignments**).
**Pass:** The profile is assigned to the intended **pilot device group** and to no unintended broad
group.
**Fail:** Not assigned, or assigned to "All devices" prematurely → correct the assignment (Implement
Step 7 / `RDPHARD-Set-ScopeTargeting.ps1`).

## Test 3 — Profile applied on the device
**Procedure:** On the pilot device, sync Intune, then check **Devices → Configuration → `RDP Hardening -
Pilot` → Device status**. Optionally verify the registry values on the device.
**Pass:** The profile shows **Succeeded**, and on the device
`HKLM\SOFTWARE\Policies\Microsoft\Windows NT\Terminal Services\MinEncryptionLevel = 3`,
`fPromptForPassword = 1`, `fDisableCdm = 1`, `fAllowToGetHelp = 0`, `UserAuthentication = 1`, and
`DisablePasswordSaving = 1` (Remote Desktop Connection Client key).
**Fail:** Not applied / error → force a sync and re-check; resolve conflicts (Troubleshooting).

## Test 4 — Hardened session behavior (modern client)
**Procedure:** From a **modern** RDP client, connect to the pilot host.
**Pass:** The session **prompts for a password**, **local drives are not redirected** into the session,
the client **cannot save** the password, **NLA** authenticates before the session appears, and the
connection succeeds at 128-bit (High) encryption.
**Fail:** Password not prompted, drives visible, password savable, or NLA not enforced → re-check the
corresponding setting in the profile (Step 5) and that the device applied it (Test 3).

## Test 5 — Legacy-client impact (the breaking-change gate)
**Procedure:** From a **legacy / embedded** RDP client that cannot negotiate 128-bit (or a deliberately
downgraded test), attempt to connect to the piloted host.
**Pass (expected):** The host **refuses** the sub-128-bit client — this **confirms** High encryption is
enforcing. Record which clients are affected.
**Interpretation:** This is the intended behavior, not a defect. **Do not expand** until every legacy
client that must reach in-scope hosts is upgraded/replaced, or those hosts are scoped out of the High
encryption setting until the clients are remediated (R5).

## Test 6 — Remote Assistance disabled
**Procedure:** On the pilot device, attempt to launch **Solicited Remote Assistance** (e.g.
`msra.exe /novice`).
**Pass:** Solicited Remote Assistance is **blocked/disabled** (`fAllowToGetHelp = 0`); Offer Remote
Assistance is likewise disabled (`fAllowUnsolicited = 0`).
**Fail:** Remote Assistance still launches → confirm both Remote Assistance settings are **Disabled** in
the profile (Step 5) and applied (Test 3).

## Test 7 — Coverage report
**Procedure:** Run `RDPHARD-Report.ps1`.
**Pass:** The report lists the pilot device(s) as **profile applied**; counts match the assigned group.
**Fail:** Devices missing from the report → run `RDPHARD-Remediation.ps1` (`-WhatIf` first) to fix
assignment/scoping, then re-sync stragglers.

## Test 8 — Reversibility (negative test)
**Procedure:** On a spare pilot device, unassign the `RDP Hardening - Pilot` profile and re-sync.
**Pass:** The endpoint cleanly reverts to its prior RDP behavior (the policy registry values are
removed) with **no re-imaging and no re-enrollment** — confirming the change is reversible by
unassignment.
**Fail:** Behavior does not revert → confirm no second profile or a security baseline is also setting
these values (Troubleshooting: conflicts).

## Acceptance gate
Proceed to **Expand** only when Tests 1–4, 6, and 7 pass on at least one pilot device, **Test 5
confirms the legacy-client impact is known and acceptable**, and Test 8 confirms the change is
reversible. Widen in waves, re-checking legacy-client impact for each new population.
