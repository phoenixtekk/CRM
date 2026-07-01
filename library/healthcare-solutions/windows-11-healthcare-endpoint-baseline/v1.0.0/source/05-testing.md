# 5. Testing Guide — Windows 11 Healthcare Endpoint Baseline

Run after the pilot assignment applies (Implementation Step 8) and again after expanding to
production. All Test 1 through Test 6 must pass on the pilot before the expand step (the pilot gate).

## Test 1 — Profiles applied
Do: Intune, Devices, Configuration, open `W11 Device Restrictions – All – Baseline`, Device status.
Expected: Pilot devices show Succeeded. Repeat for `W11 Settings Catalog – All – Baseline`.

## Test 2 — Security baseline applied
Do: Intune, Endpoint security, Security baselines, open `W11 Security Baseline – All – Baseline`,
check status.
Expected: Pilot devices show Succeeded with no Conflict.

## Test 3 — Settings present on device
Do: On a pilot device run `W11HC-Validation.ps1`.
Expected: Defender/SmartScreen on, baseline registry values present, no conflicting authority.

## Test 4 — Update ring applied
Do: Intune, Devices, Windows, Update rings, open `W11 Update Ring – Clinical – Baseline`, Device
status; or run `W11HC-Validation.ps1`.
Expected: Pilot devices show Succeeded; deferral/active-hours values match the ring.

## Test 5 — Power behavior correct
Do: On a clinical pilot device run `powercfg /q` (or `W11HC-Validation.ps1`) and confirm sleep and
display-off are Never on plugged-in power.
Expected: Shared clinical device does not sleep or blank mid-shift; corporate device conserves on
battery.

## Test 6 — Fleet report
Do: Run `W11HC-Report.ps1`.
Expected: A clear per-device baseline status (which baseline policies are Succeeded, which devices
lag) and OS-build inventory.

---
## Pass/fail gate
| Gate | Requirement |
|---|---|
| Pilot pass | Tests 1 through 6 pass on the pilot groups; no Conflict on the security baseline |
| Production pass | Tests 1 through 4 and Test 6 pass for the production groups after expand |
