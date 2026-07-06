# 5. Testing Guide — macOS Identity-Threat & Account-Lockout Hardening

Run after the pilot configuration and remediation apply (Implementation Steps 6–7) and after each
review cycle.

## Test 1 — Mac-originated failures identified
**Do:** Run `MACLOCK-Discovery.ps1` and confirm the findings register (`MACLOCK Sign-in Failure
Findings - Mac-Originated - Sources`) lists the affected users, Macs, apps, and error codes read from
the Entra sign-in logs.
**Expected:** Every Mac-originated failure source is recorded with a user, an app, an error code, and
a count.

## Test 2 — Smart Lockout configured
**Do:** In Entra, **Protection → Authentication methods → Password protection**, confirm the lockout
threshold and duration match the desired values in `MACLOCK Lockout & Spray Register - Mac Fleet -
Baseline`; run `MACLOCK-Validation.ps1`.
**Expected:** Threshold and duration match the register; validation reports MATCH for Smart Lockout.

## Test 3 — MFA enforced for the pilot
**Do:** Confirm `MACLOCK CA - Require MFA - Mac Pilot` is On (or evaluated in report-only) for
`MACLOCK Scope - Pilot - Macs`; have a pilot user sign in.
**Expected:** The pilot user is prompted for MFA; a correct-password-only attempt is not sufficient;
sign-in still succeeds for the legitimate user.

## Test 4 — Mac credential state remediated
**Do:** For a remediated pilot Mac, confirm the stale keychain items are cleared, the saved credential
(Mail / Wi-Fi / app) holds the current password, and any SecureToken / local-account divergence is
resolved.
**Expected:** The Mac no longer re-submits the old password; the user signs in without repeated
prompts.

## Test 5 — Failures reduced
**Do:** In the Entra sign-in logs (filtered to Status = Failure, OS = macOS), compare the pilot users'
failure count against the pre-remediation baseline recorded in Step 2; run `MACLOCK-Report.ps1`.
**Expected:** Mac-originated failures for the pilot users have dropped materially; no new
account lockouts for those users.

## Test 6 — No new lockouts / spray detections for the pilot
**Do:** Confirm no new account-lockout or (if licensed) password-spray / risk detections are firing
for the pilot users after remediation.
**Expected:** The lockouts and spray detections that were attributed to those users' Macs have
stopped recurring.

## Test 7 — Evidence captured
**Do:** Confirm `MACLOCK Remediation Evidence Pack - Mac Credential State` holds dated before/after
evidence (sign-in-log counts, Smart Lockout + CA settings, per-Mac remediation) from
`MACLOCK-Report.ps1`.
**Expected:** Each pilot user/Mac has current, dated before/after evidence.

---
## Pass/fail gate
| Gate | Requirement |
|---|---|
| **Pilot pass** | Tests 1–4 pass; MFA works and no legitimate pilot user is locked out |
| **Reduction pass** | Tests 5–6 pass; Mac-originated failures down and no new lockouts/spray for the pilot |
| **Evidence pass** | Test 7 passes; before/after evidence captured and dated |
