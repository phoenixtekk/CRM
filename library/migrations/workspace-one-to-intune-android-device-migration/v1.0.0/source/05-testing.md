# 5. Testing Guide — Workspace ONE to Intune: Android Enterprise Device Migration

Run after the pilot ring re-enrolls (Implementation Step 8) and again for each wave before
expanding. Each test states Do and Expected.

## Test 1 — Managed Google Play connection active
Do: Intune > Devices > Android > Enrollment > Connectors and tokens > Managed Google Play; or run
`WS1DROID-Discovery.ps1`.
Expected: The binding shows a linked Google account and active status. (No connection = no apps;
this gates everything.)

## Test 2 — Enrollment profiles exist per in-scope mode
Do: Intune > Devices > Android > Enrollment; or run `WS1DROID-Validation.ps1`.
Expected: Each in-scope profile is present
(`Android Enrollment Profile – Work Profile BYOD – Migration`,
`Android Enrollment Profile – Fully Managed – Migration`,
`Android Enrollment Profile – Dedicated – Migration`); corporate modes have a valid token / QR.

## Test 3 — Device landed in the correct mode
Do: For a re-enrolled pilot device, Intune > Devices > All devices > (device) > check Ownership and
the management/enrollment type; or run `WS1DROID-Validation.ps1`.
Expected: The device shows the intended Android Enterprise mode (work profile vs fully managed vs
dedicated) — not the wrong mode.

## Test 4 — App parity present
Do: Run `WS1DROID-Report.ps1` (source app list vs Intune-assigned), and on the device confirm the
work apps are installed.
Expected: Every in-scope app from `App Parity – Android Estate – Migration` is installed/available;
the parity gap is zero for the device.

## Test 5 — Configuration parity applied
Do: On the device, confirm Wi-Fi/email/VPN/certificate and restrictions behave as before; in Intune
the device shows `Config Parity – Android Estate – Migration` profiles as succeeded.
Expected: Connectivity and security settings match the pre-migration state; no failed profiles.

## Test 6 — Compliance and access
Do: Intune > Devices > Compliance; confirm the device is compliant. Attempt access to a
Conditional-Access-gated resource.
Expected: The device is compliant under `Compliance Baseline – Android Estate – Migration` and
access works (or is blocked) exactly as intended.

## Test 7 — Migration status report
Do: Run `WS1DROID-Report.ps1` for the ring.
Expected: A clear per-device migration status (mode, enrollment, app-parity gap) for the ring with
no unexpected failures.

---
## Pass/fail gate
| Gate | Requirement |
|---|---|
| Pilot pass | Tests 1 to 6 pass for every pilot device across all in-scope modes; Test 7 shows zero unresolved failures |
| Wave pass | Tests 3 to 7 pass for the wave before the next wave begins |

If the pilot gate fails, do not expand: remediate (`WS1DROID-Remediation.ps1`) or roll the affected
devices back to Workspace ONE per Implementation Step 8.
