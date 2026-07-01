# 5. Testing Guide — Workspace ONE to Intune iOS/iPadOS Device Migration

Run after the pilot ring re-enrolls (Implementation Step 12) and after each broad wave.

## Test 1 — ABM re-assignment took effect
Do: In Apple Business Manager > Devices, open a migrated device and confirm its MDM server is
`Intune MDM Server – Apple – Migration`.
Expected: The device shows the Intune MDM server, not the Workspace ONE server.

## Test 2 — Device enrolled supervised in Intune
Do: On a pilot device run `WS1IOS-Validation.ps1`, or check Intune > Devices > iOS/iPadOS.
Expected: The device is present, Supervised = Yes, enrolled via Automated Device Enrollment, and in its ring group.

## Test 3 — No longer managed by Workspace ONE
Do: Confirm the device no longer responds to Workspace ONE (the management profile is the Intune one after erase).
Expected: The device shows only the Intune management profile; Workspace ONE no longer controls it.

## Test 4 — Enrollment profile applied
Do: In Intune, on the ADE token > Devices, confirm the assigned profile.
Expected: Pilot devices show `iOS Migration – Corporate Supervised – Pilot` (broad shows the Broad profile).

## Test 5 — Configuration parity
Do: Run `WS1IOS-Validation.ps1`; on the device check Wi-Fi, email, VPN, and restrictions.
Expected: `iOS Parity – Corporate Wi-Fi – Cutover` and `iOS Parity – Device Restrictions – Cutover` are applied and connectivity works.

## Test 6 — App parity
Do: Run `WS1IOS-Report.ps1` (app parity section) and check the device home screen.
Expected: The parity apps from the matrix are installed and assignments report Installed.

## Test 7 — Compliance
Do: Intune > Devices > Compliance, or `WS1IOS-Validation.ps1`.
Expected: `iOS Parity – Compliance Baseline – Cutover` evaluates the device as Compliant.

## Test 8 — Fleet migration report
Do: Run `WS1IOS-Report.ps1`.
Expected: A clear per-device view of supervision, enrollment profile, ring group, and app-parity status.

---
## Pass/fail gate
| Gate | Requirement |
|---|---|
| Pilot pass | Tests 1 to 7 pass for every pilot device; users confirm normal use |
| Broad pass | Tests 1 to 5 and 8 pass for the wave before the next wave begins |
