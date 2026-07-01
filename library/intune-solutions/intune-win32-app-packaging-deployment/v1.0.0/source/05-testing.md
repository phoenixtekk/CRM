# 5. Testing Guide — Intune Win32 Application Packaging & Deployment

Run after the app applies to the pilot ring (Implementation Step 10) and again after expanding to the
broad ring. The worked example is `Contoso LOB Suite – Win32 – v4.2.0`.

## Test 1 — Package built correctly
**Do:** Confirm `WIN32-New-IntuneWinPackage.ps1` produced `ContosoLOB.intunewin` and that the upload
in Intune accepted it (no size/format error).
**Expected:** A valid `.intunewin` exists and the app was created.

## Test 2 — App reports applicable, not blocked by requirements
**Do:** Intune -> **Apps -> Windows ->** `Contoso LOB Suite – Win32 – v4.2.0` **-> Device install
status**.
**Expected:** Pilot devices show the app as targeted and **not** **Not applicable** (requirement
rules pass on x64 / supported OS).

## Test 3 — Install succeeds on the device
**Do:** On a pilot device, sync, then run `WIN32-Validation.ps1 -DetectionType MSI -ProductCode {PRODUCT-GUID}`.
**Expected:** The install command ran, the app is present, and the script reports the detection rule
**matches** (the app is detected as installed).

## Test 4 — Detection rule is correct (reporting is true)
**Do:** Intune -> the app **-> Device install status**; compare to `WIN32-Validation.ps1` on-device.
**Expected:** Intune reports **Installed** and the on-device detection agrees — no "installed but
failed" mismatch and no reinstall loop.

## Test 5 — Dependency installed first
**Do:** On a device that lacked the runtime, confirm `VC++ Redistributable x64 – Win32 – Dependency`
installed before the main app (check its detection/registry key).
**Expected:** The dependency is present; the main app installed after it, in order.

## Test 6 — Supersedence replaces the old version
**Do:** On a device with `Contoso LOB Suite – Win32 – v4.1.0`, confirm the v4.2.0 deployment replaced
it (and uninstalled the old version if that option was chosen).
**Expected:** Only the targeted version remains; no duplicate entries in Programs and Features.

## Test 7 — Uninstall works
**Do:** Temporarily set an **Uninstall** assignment to a single test device (or run the uninstall
command manually on a test VM).
**Expected:** The uninstall command runs cleanly (exit `0`) and detection then reports the app
**not** installed.

## Test 8 — Fleet report
**Do:** Run `WIN32-Report.ps1 -AppName "Contoso LOB Suite – Win32 – v4.2.0"`.
**Expected:** A clear per-device Installed / Failed / Not applicable breakdown across the assigned rings.

---
## Pass/fail gate
| Gate | Requirement |
|---|---|
| **Pilot pass** | Tests 1-6 pass on `App Deployment – Pilot Devices – Ring 1`; install + detection agree |
| **Broad pass** | Tests 3, 4, 8 pass for `App Deployment – Broad Devices – Ring 2` after expansion |

Do **not** assign the broad ring until the pilot gate passes.
