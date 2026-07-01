# 5. Testing Guide — Microsoft 365 Security Baseline & Audit Readiness

Run after the pilot configuration applies (Implementation Step 9) and after each review cycle.

## Test 1 — Baseline captured
**Do:** Run `M365SEC-Discovery.ps1` and confirm the baseline register (`M365 Security Baseline
Register – Tenant Services – Baseline`) records each target setting's current and desired value.
**Expected:** Every baseline setting has a recorded current value and a desired value.

## Test 2 — Secure Score measured and improving
**Do:** `https://security.microsoft.com` to Secure Score; compare with the pre-configuration score
recorded in Step 2.
**Expected:** The score has improved and the configured improvement actions show as completed /
in-progress.

## Test 3 — Baseline compliance
**Do:** Run `M365SEC-Validation.ps1`.
**Expected:** The tenant matches the baseline register; deviations are listed as explicit gaps.

## Test 4 — Identity posture
**Do:** Confirm legacy authentication is blocked and the Conditional Access / admin-role baseline is
in place for the pilot scope.
**Expected:** Legacy auth blocked; scoped policies applied to `M365 Baseline Scope – Pilot – Users`;
sign-in still works for pilot users.

## Test 5 — Email protection active (EOP)
**Do:** Confirm the anti-malware / anti-phish / anti-spam / Safe Attachments / Safe Links preset
policies are applied and mail flow is healthy for the pilot.
**Expected:** Preset security policies enabled per the baseline; legitimate mail still delivers.

## Test 6 — Collaboration posture
**Do:** Confirm SharePoint/OneDrive external-sharing and Teams guest-access settings match the
baseline register.
**Expected:** Sharing/guest posture matches the baseline; expected collaboration still works.

## Test 7 — Controls mapped and evidenced
**Do:** In Compliance Manager confirm `Compliance Assessment – Target Framework – Mapping` shows the
improvement actions worked; run `M365SEC-Report.ps1` and confirm the evidence pack (`Control
Evidence Pack – Tenant Baseline – Audit`) has dated evidence per control.
**Expected:** Improvement actions have implementation/test status; each control has current, dated
evidence.

---
## Pass/fail gate
| Gate | Requirement |
|---|---|
| **Pilot pass** | Tests 1 to 6 pass; Secure Score improved; no loss of sign-in, mail, or sharing for the pilot |
| **Audit pass** | Test 7 passes; controls mapped in Compliance Manager with current, dated evidence |
