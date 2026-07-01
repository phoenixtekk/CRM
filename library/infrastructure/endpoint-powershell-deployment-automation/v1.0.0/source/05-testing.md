# 5. Testing Guide — Endpoint PowerShell Deployment & Patch Automation Toolkit

Run after the remediation applies to the pilot (Implementation Step 7) and after any change to a
detection or remediation script.

## Test 1 — Toolkit readiness
Do: On the admin workstation run `PSAUTO-Discovery.ps1`.
Expected: Graph SDK present, execution policy allows the scripts, 64-bit host confirmed, and the
Remediations feature reachable — no blocking warnings.

## Test 2 — Detection logic is correct
Do: On a known-good pilot device run `PSAUTO-Validation.ps1` directly; then on a deliberately
drifted device run it again.
Expected: Exit `0` (compliant) on the good device and exit `1` (non-compliant) on the drifted one,
each with a clear status line.

## Test 3 — Remediation is safe by default
Do: Run `PSAUTO-Remediation.ps1` with no parameters on a drifted pilot device.
Expected: It reports the change it would make and changes nothing (`-WhatIf` default); re-running
with `-WhatIf:$false` (or `-Apply`) makes the change and exits `0`.

## Test 4 — The remediation runs in Intune
Do: In Intune open `Endpoint Drift Remediation – Windows – Production` → Device status after the
pilot syncs.
Expected: Pilot devices show a detection result; drifted devices show `Remediated`, healthy devices
show `Without issues`.

## Test 5 — Schedule fires
Do: Confirm the assignment uses `Endpoint Automation Schedule – Windows – Daily`; wait for or force
the next run.
Expected: The run date/time updates on the next cycle; devices are re-checked on schedule.

## Test 6 — Deployment / cleanup runner
Do: Run `PSAUTO-Deploy-CleanupRunner.ps1` on a pilot device with its default `-WhatIf`, then with
`-WhatIf:$false`.
Expected: The planned install/uninstall and cleanup are reported, then applied; a log is written to
`-LogPath` if set; the runner exits `0` on success.

## Test 7 — Fleet report
Do: Run `PSAUTO-Report.ps1`.
Expected: A per-device summary of remediation status (remediated / without issues / failed) across
the targeted devices, plus a count, and an optional CSV.

---
## Pass/fail gate
| Gate | Requirement |
|---|---|
| Pilot pass | Tests 1–4 pass; the remediation remediates a drifted pilot device cleanly |
| Production pass | Tests 4, 5, 7 pass for the production group before/while expanding |
