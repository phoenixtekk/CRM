# 5. Testing Guide — Endpoint Imaging, Inventory & Hardware Lifecycle Management

Run after the pilot flow applies (Implementation Step 8) and each lifecycle cycle.

## Test 1 — Provisioning method works
Do: Provision a pilot device by the chosen method — for Autopilot, reset/boot a registered device
and complete OOBE; for imaging, run the task sequence. Then run `IMGLIFE-Validation.ps1`.
Expected: The device provisions to the standard state and enrolls in Intune.

## Test 2 — Autopilot registration present (if Autopilot)
Do: Intune → Devices → Enrollment → Windows Autopilot → Devices; or run `IMGLIFE-Validation.ps1`.
Expected: The pilot device's hardware identity is registered and assigned the deployment profile.

## Test 3 — Device enrolled and reporting hardware
Do: Intune → Devices → All devices → (the device) → Hardware; or run `IMGLIFE-Validation.ps1`.
Expected: The device is present and reports model, serial number, storage, and memory.

## Test 4 — Inventory is the source of truth
Do: Run `IMGLIFE-Report.ps1`.
Expected: The fleet inventory lists the device with its hardware details and lifecycle stage.

## Test 5 — Reconciliation finds gaps
Do: Compare the procurement list (serials) against `IMGLIFE-Report.ps1` output.
Expected: Procured-but-not-deployed and deployed-but-not-inventoried devices are flagged.

## Test 6 — Refresh-due detection
Do: Apply the refresh criteria and run `IMGLIFE-Report.ps1`.
Expected: Devices meeting the criteria appear and are eligible for
`Device Lifecycle – Aging – Refresh-Due`.

## Test 7 — Secure retire/wipe (controlled)
Do: On a disposable pilot device, preview with `IMGLIFE-Remediation.ps1` (WhatIf), then perform
Retire or Wipe in Intune and confirm completion.
Expected: The device returns to a clean state (Wipe) or loses company data/management (Retire), then
is removed from inventory and de-registered from Autopilot.

---
## Pass/fail gate
| Gate | Requirement |
|---|---|
| Pilot pass | Tests 1–5 pass on the pilot group; a test retire/wipe (Test 7) completes cleanly |
| Broad pass | Tests 3–6 pass across the broad population before the next refresh cycle |
