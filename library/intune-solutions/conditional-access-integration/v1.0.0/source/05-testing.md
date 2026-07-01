# 5. Testing Guide — Conditional Access Integration

Run during Report-only (Implementation Step 7) and again after enabling enforcement.

## Test 1 — Policies evaluate in Report-only
**Do:** Entra → **Monitoring → Sign-in logs →** open a pilot sign-in → **Report-only** tab.
**Expected:** Each policy shows a result (Would apply / satisfied / would block) — proving evaluation works.

## Test 2 — Compliant device satisfies the control
**Do:** From a compliant pilot device, sign in to `https://outlook.office.com`. Run `CAI-Validation.ps1`.
**Expected:** Access granted; the "require compliant device" policy is satisfied.

## Test 3 — Noncompliant device is challenged/blocked
**Do:** From a noncompliant or unmanaged device, attempt the same sign-in (Report-only shows the would-be result).
**Expected:** Report-only logs "would block"; after enforcement, access is blocked.

## Test 4 — MFA is required
**Do:** Sign in as a pilot user from a new session.
**Expected:** An MFA challenge appears (after enforcement) / Report-only logs "would require MFA".

## Test 5 — Legacy authentication is blocked
**Do:** Attempt a legacy-auth connection (e.g. older IMAP client) as a pilot user.
**Expected:** Report-only logs "would block"; after enforcement, the legacy client is denied.

## Test 6 — Break-glass accounts are exempt
**Do:** Run **`CAI-BreakGlassCheck.ps1`**; sign in with a break-glass account.
**Expected:** Break-glass accounts are excluded from all policies and sign in without CA controls.

## Test 7 — Policy + sign-in report
**Do:** Run **`CAI-PolicyReport.ps1`** and **`CAI-SignInReport.ps1`**.
**Expected:** A clear list of policies/states and a summary of CA results across recent sign-ins.

---
## Pass/fail gate
| Gate | Requirement |
|---|---|
| **Pilot pass (Report-only)** | Tests 1–6 behave as expected with **no unexpected** would-blocks for legitimate users |
| **Enforcement pass** | After enabling, pilot users work normally; break-glass verified; no lockouts |
