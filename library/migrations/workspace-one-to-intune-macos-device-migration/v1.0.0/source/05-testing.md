# 5. Testing Guide — Workspace ONE to Intune: macOS Device Migration

Run after the pilot ring migrates (Implementation Step 8) and again per production wave (Step 10).
Tests use the named artifacts from the Implementation Guide.

## Test 1 — ABM reassignment took effect
Do: In Apple Business Manager, confirm the pilot Macs show MDM server
`WS1MAC Intune - macOS MDM Server`; in Intune to Devices to Enrollment to Apple to Enrollment program
tokens, sync the token and confirm the Macs are assigned to Intune.
Expected: Each pilot Mac is assigned to the Intune MDM server in ABM and appears under the Intune
enrollment token.

## Test 2 — Re-enrolled into Intune
Do: Intune to Devices to macOS to macOS devices; or run `WS1MAC-Validation.ps1` per device.
Expected: Each pilot Mac is enrolled and managed by Intune (no longer managed by Workspace ONE).

## Test 3 — Settings-catalog parity applied
Do: Intune to Devices to macOS to Configuration to `WS1MAC Parity - macOS Settings - Pilot` to Device
status / Per-setting status; or `WS1MAC-Validation.ps1`.
Expected: Pilot Macs show Succeeded; the settings match the Workspace ONE parity reference.

## Test 4 — Custom profiles and shell scripts applied
Do: Check `WS1MAC Parity - macOS Custom - Pilot` (Configuration to Device status) and
`WS1MAC Parity - macOS Shell - Pilot` (Devices to macOS to Shell scripts to the script to Device
status); or `WS1MAC-Validation.ps1`.
Expected: Custom profiles show Succeeded and shell scripts show their last run as success.

## Test 5 — Posture parity (real use)
Do: On a pilot Mac, confirm the migrated posture matches the prior Workspace ONE state — restrictions,
login window, Software Update, FileVault, certificates, and any app config — by using the device for
real work.
Expected: No regression versus the Workspace ONE posture; users can do their normal work.

## Test 6 — Fleet migration + parity report
Do: Run `WS1MAC-Report.ps1` for the ring.
Expected: A clear per-device migration status and per-object parity breakdown (succeeded vs drift)
for the ring.

## Test 7 — Rollback rehearsed (pilot only)
Do: On one pilot Mac, rehearse the rollback (Implementation Step 8.6): reassign in ABM back to the
Workspace ONE MDM server, or remove an Intune parity assignment and sync.
Expected: The rollback path works and is documented before any production wave.

---
## Pass/fail gate
| Gate | Requirement |
|---|---|
| Pilot pass | Tests 1 to 6 pass on the pilot ring; rollback (Test 7) is rehearsed; no unresolved enrollment or parity gap |
| Wave pass | Tests 1 to 4 and 6 pass for each production wave before the next wave migrates |
