# 5. Testing Guide — SCCM Application Migration to Intune Win32

Run per app after the pilot assignment applies (Implementation Step 12) and before retiring the SCCM
deployment. Each app must clear the pilot gate before broad cutover.

## Test 1 — Repackage produced a valid `.intunewin`
Do: Confirm `C:\Packaging\Output\<app>.intunewin` exists and uploaded without error in Intune.
Expected: The Win32 app was created from the `.intunewin` with the migrated name.

## Test 2 — Install/uninstall parity
Do: On a pilot device, confirm the app installed via the Intune command; run
`SCCMAPP-Validation.ps1`.
Expected: The app installs with the same commands SCCM used; uninstall command is present.

## Test 3 — Detection parity
Do: Run `SCCMAPP-Validation.ps1` (checks the app's detection rule — MSI product code / file /
registry / script) and confirm Intune → app → `Device install status` shows `Installed`.
Expected: The Intune detection rule matches the same evidence SCCM detected; status `Installed`.

## Test 4 — Requirements applied
Do: Confirm the app is offered only to devices meeting the requirement rules (architecture / min OS)
that mirror SCCM.
Expected: Devices outside the requirements are `Not applicable`, as they were in SCCM.

## Test 5 — Dependencies and supersedence
Do: On a device missing the prerequisite, confirm the dependency auto-installs first; where the app
supersedes a prior version, confirm the replace/upgrade behavior matches SCCM.
Expected: Dependency installs first; supersedence replaces or upgrades per the SCCM behavior.

## Test 6 — Assignment (ring) parity
Do: Run `SCCMAPP-Set-AppRingTargeting.ps1` (or check `Assignments`) — pilot ring targeted, broad not
yet.
Expected: The same devices that received the SCCM deployment are in the pilot ring; broad deferred.

## Test 7 — Coverage and deployment-success report
Do: Run `SCCMAPP-Report.ps1`.
Expected: Per-app repackage coverage and Intune install-success counts; laggards flagged.

---
## Pass/fail gate
| Gate | Requirement |
|---|---|
| **Per-app pilot pass** | Tests 1–5 pass on the pilot; install + detection parity confirmed before retiring the SCCM deployment |
| **Broad pass** | Tests 2, 3, 6, 7 pass for the broad ring before retiring the SCCM deployment for broad scope |
