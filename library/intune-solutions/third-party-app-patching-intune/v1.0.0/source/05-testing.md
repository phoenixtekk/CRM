# 5. Testing Guide — Third-Party Application Patching with Intune

Run after the pilot assignments apply (Implementation Step 5-6) and after each release cycle.

## Test 1 — Catalog app deployed
**Do:** Intune -> Apps -> Windows -> open the Enterprise App Catalog app -> Device install status.
**Expected:** Pilot devices show **Installed**; auto-update is enabled on the app.

## Test 2 — Win32 update deployed
**Do:** Intune -> Apps -> Windows -> open `PDF Reader Update - Win32 - <x.y.z>` -> Device install status.
**Expected:** Pilot devices show **Installed / Succeeded**; the superseded prior package shows replaced.

## Test 3 — Installed version meets target on device
**Do:** On a pilot device run `TPP-Validation.ps1`.
**Expected:** Each managed app reports a version greater than or equal to its target — result **PATCH STATE OK**.

## Test 4 — Detection rule is correct
**Do:** Confirm the Win32 app reports Installed only when the target version is present (check a device
already at the version, and one below it).
**Expected:** Devices at/above `<x.y.z>` = Installed; devices below = the update applies, then Installed.

## Test 5 — Supersedence moves devices forward
**Do:** On a device running the old version, sync and let the update run.
**Expected:** The old version is replaced by the target version; `TPP-Validation.ps1` confirms the new version.

## Test 6 — Fleet exposure report
**Do:** Run `TPP-Report.ps1` against the fleet with your target versions.
**Expected:** A clear per-app / per-device list of devices below target (out-of-date exposure) and the count current.

## Test 7 — Stuck-update remediation (safe)
**Do:** On a device whose update did not apply, run `TPP-Remediation.ps1` (default `-WhatIf` to preview), then with `-WhatIf:$false` to act.
**Expected:** `-WhatIf` lists the actions it would take; the live run requests a sync/app re-evaluation, after which the update applies.

---
## Pass/fail gate
| Gate | Requirement |
|---|---|
| **Pilot pass** | Tests 1-5 pass; managed apps reach their target version on the pilot |
| **Broad pass** | Tests 1-3, 6 pass for the broad ring before the next release is promoted |
