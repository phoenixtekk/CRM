# 5. Testing Guide — Workspace ONE to Intune Application Rebuild & Repackaging

Run these per app after pilot assignment (Implementation Step 12) and again after broad expansion.
The per-app validation gate is the rule: an app does not move to the broad ring until it passes
Tests 1 to 4 on a pilot device.

## Test 1 — App assignment applied
Do: Intune to Apps to All apps to open the rebuilt app (e.g. `Acme Field Suite – Win32 – v4.2.0`) to
Properties to Assignments. Confirm the pilot group is assigned with the correct intent.
Expected: The pilot group (`App Rebuild – Pilot Devices – Ring 1` or `App Rebuild – Pilot Users –
Ring 1`) is present with Required/Available matching the source workflow.

## Test 2 — App installs on the pilot device
Do: On a pilot device, sync policy and let the app install; or run `WS1APP-Validation.ps1` with the
app's detection type and value.
Expected: For Win32, the app is present and the detection rule matches (MSI product code, file
version, or registry value). For store/mobile apps, the app appears installed on the device.

## Test 3 — Intune reports the app Installed
Do: Open the app to Device install status (or Overview); or run `WS1APP-Report.ps1`.
Expected: The pilot devices show Installed in the app `installSummary` / per-device `deviceStatuses`;
no Failed devices in the pilot.

## Test 4 — App configuration applied (where applicable)
Do: For apps with an app configuration policy (`Acme Field Suite – AppConfig – Managed`), confirm the
configured behavior on the pilot device (the app reflects the configured keys/values).
Expected: The app behaves per the recreated configuration — parity with the source payload.

## Test 5 — Detection parity (no reinstall loop, no false-installed)
Do: After install, re-sync and observe the app status across two cycles.
Expected: The app stays Installed without reinstalling each cycle (detection rule is correct) and is
not falsely reported Installed when absent.

## Test 6 — Supersedence replaces the prior version
Do: For a superseding app, confirm a device on the prior version moves to the new version per the
chosen Uninstall-previous setting.
Expected: The device ends on the new rebuilt version; the prior version is removed or upgraded as
configured.

## Test 7 — Assignment parity across the estate
Do: Run `WS1APP-Report.ps1` to list rebuilt apps and their assignments; compare against the source
assignment mapping (Requirement 2.7).
Expected: Each in-scope app is assigned to the intended group(s) with the intended intent — the same
users/devices receive the same apps as in Workspace ONE.

## Test 8 — No double-install during coexistence
Do: On a pilot device still managed by both platforms, confirm the app is delivered once and not
fighting between platforms.
Expected: A single healthy install; the source assignment is retired only after the Intune install is
confirmed (Implementation Step 13).

---
## Pass/fail gate
| Gate | Requirement |
|---|---|
| Per-app pilot pass | Tests 1 to 4 pass for that app on a pilot device; no Failed pilot device |
| Estate broad pass | Tests 3, 5, 7 pass for the broad ring; assignment parity confirmed across in-scope apps before retiring source assignments |
