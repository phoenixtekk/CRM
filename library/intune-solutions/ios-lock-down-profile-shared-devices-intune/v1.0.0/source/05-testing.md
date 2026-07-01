# 5. Testing Guide — iOS Lock-Down Profile for Shared & Corporate iPhones

Run after the pilot phones enroll (Implementation Step 15) and after any profile change. Test **both**
models — a shared phone and a corporate phone.

## Test 1 — Tenant building blocks present
**Do:** Run `IOSLD-Discovery.ps1`.
**Expected:** PASS for APNs, ADE token, both enrollment profiles (`iOS Shared – ADE – Pilot`,
`iOS Corporate – ADE – Pilot`), both groups, the lock-down restrictions profile, the corporate baseline,
and compliance — overall **READY**.

## Test 2 — Shared phone is shared and supervised
**Do:** Run `IOSLD-Validation.ps1 -DeviceName "<shared phone>"` (or `-Serial`).
**Expected:** **No primary user**, **Supervised = Yes**, iOS platform, member of `iOS – Shared Devices`.

## Test 3 — Lock-down applied to the shared phone
**Do:** Intune → **Devices → Configuration →** `iOS Lock-Down – Shared – Restrictions` **→ Device
status** (and `iOS Kiosk – Shared – Pilot` if used). On the phone, try to open the App Store / Safari.
**Expected:** Profile shows **Succeeded**; App Store/Safari are blocked; only the role app(s) are
available. In single-app kiosk, the phone stays pinned to the one app.

## Test 4 — Corporate phone is user-assigned and supervised
**Do:** Run `IOSLD-Validation.ps1 -DeviceName "<corporate phone>"`.
**Expected:** **Has a primary user** (the assigned user), **Supervised = Yes**, member of
`iOS – Corporate Devices`, **compliant**.

## Test 5 — Corporate baseline applied (and lighter)
**Do:** Intune → **Devices → Configuration →** `iOS Corporate – Baseline – Restrictions` **→ Device
status**. On the corporate phone, confirm normal use (App Store usable per policy).
**Expected:** Profile **Succeeded**; the phone is **not** locked to one app and is usable as a normal
work phone within policy.

## Test 6 — Shared sign-in works at the app layer
**Do:** On the shared phone, open the role app and sign in with the `iOS Shared – App Sign-in` account.
**Expected:** The shared account signs in and the app works; the device itself has no user identity.

## Test 7 — Corporate sign-in works with the user's own identity
**Do:** On the corporate phone, open Company Portal / a work app and confirm sign-in with the user's
**own** Entra ID.
**Expected:** Sign-in (with SSO/MFA) succeeds; the phone reports the assigned user.

## Test 8 — Compliance and access
**Do:** Intune → **Devices → Compliance** for both `iOS Shared – Compliance – Pilot` and
`iOS Corporate – Compliance – Pilot`; check Conditional Access report-only results.
**Expected:** Pilot phones are **compliant**; CA report-only shows the policies would apply as intended.

## Test 9 — Fleet posture report
**Do:** Run `IOSLD-Report.ps1`.
**Expected:** A clear shared-vs-corporate breakdown — each phone classified, supervision and compliance
shown, and any model mismatch flagged.

---
## Pass/fail gate
| Gate | Requirement |
|---|---|
| **Shared pass** | Tests 1, 2, 3, 6, 8 pass for the shared phone |
| **Corporate pass** | Tests 1, 4, 5, 7, 8 pass for the corporate phone |
| **Expand** | Both gates pass and Test 9 shows correct fleet classification |
