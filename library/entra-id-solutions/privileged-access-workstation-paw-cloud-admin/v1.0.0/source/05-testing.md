# 5. Testing Guide — Privileged Access Workstation (PAW) for Cloud Administration

Run after the pilot PAW and policy are configured in report-only (Implementation Step 8), again after
the enforcement flip (Step 9), and after each expansion. Use `ENTPAW-Validate.ps1` for configuration
state and `ENTPAW-Report.ps1` for privileged-access coverage.

## Test 1 — PAW is hardened and compliant
Do: `Intune -> Devices -> (pilot PAW) -> Device compliance`; confirm `Compliance – PAW – Pilot` is Compliant and the baseline/ASR/app-control/isolation profiles show applied. Run `ENTPAW-Validate.ps1`.
Expected: The pilot PAW is compliant, hardened, and shows email/web isolation applied; App Control is at least in audit with no unexpected blocks of admin tooling.

## Test 2 — Device marker is set only on PAWs
Do: Entra -> `Devices`; confirm `extensionAttribute1 = PAW` on the pilot PAWs and on no other devices; run `ENTPAW-Validate.ps1`.
Expected: Only PAWs carry the marker; the device group / device filter resolves to exactly the PAW set.

## Test 3 — Enforcement policy exists, report-only, break-glass excluded
Do: Run `ENTPAW-Validate.ps1`.
Expected: `CA – Require PAW for Privileged Roles – Pilot (Report-Only)` exists, is report-only, targets `PAW Admins – Cloud Admin – Pilot`, uses the PAW device filter, requires compliant device, and excludes `CA Break-Glass Exclusion`.

## Test 4 — Privileged sign-in from the PAW would succeed
Do: A pilot admin signs in to a protected admin surface from the PAW; open the sign-in in `Sign-in logs -> Report-only`.
Expected: The policy would grant (PAW + compliant); the admin can reach the admin portal / activate PIM from the PAW.

## Test 5 — Privileged sign-in from a non-PAW would be blocked
Do: The same pilot admin attempts the protected admin surface from a general-purpose (non-PAW) device; review the report-only result.
Expected: `CA – Require PAW for Privileged Roles – Pilot (Report-Only)` shows "Would block" for the non-PAW device.

## Test 6 — PIM activation works from the PAW
Do: From the PAW, the pilot admin activates an eligible role in PIM (MFA + justification + approval if set).
Expected: Activation succeeds from the PAW and grants the role for the configured window; the admin never holds standing privilege.

## Test 7 — Break-glass path is never blocked
Do: Confirm (report-only and after enforcement) a break-glass account can sign in with the device-filter policy not applying; run `ENTPAW-Validate.ps1`.
Expected: Break-glass accounts are excluded and retain an unobstructed path in, even from a non-PAW device.

## Test 8 — Non-PAW privileged access is visible in reporting
Do: Run `ENTPAW-Report.ps1` (KQL or Graph fallback).
Expected: Any privileged sign-in attempted from a non-PAW device is listed, so gaps and policy exceptions are visible.

## Test 9 — Enforcement matches the report-only prediction
Do: After flipping to On (Step 9), repeat Tests 4 and 5 against the real `Conditional Access` result.
Expected: PAW sign-ins succeed; non-PAW privileged sign-ins are blocked; no unexpected admin is locked out.

---
## Pass/fail gate
| Gate | Requirement |
|---|---|
| Pilot pass | Tests 1-7 pass in report-only; PAW allowed, non-PAW would-block, break-glass excluded |
| Enforce pass | Test 9 passes; a non-PAW privileged sign-in is blocked and PAW admins are unaffected |
| Expand pass | Tests re-pass at the wider scope in report-only before enforcing tenant-wide; App Control moved to enforced after tuning |
