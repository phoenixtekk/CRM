# 5. Testing Guide — Conditional Access Integration (Government / GCC High)

Run during Report-only (Implementation Step 8) and again after enabling enforcement. All scripts
connect to **US Gov Graph** (`-Environment USGov`); all portal checks use the **`*.us`** endpoints.

## Test 0 — You are on the sovereign cloud
**Do:** Open **`https://entra.microsoft.us`** and confirm the tenant domain ends in
**`.onmicrosoft.us`**. Run **`CAIG-Discovery.ps1`** and confirm it reports the **USGov** Graph
environment (`graph.microsoft.us`).
**Expected:** Portal and Graph both resolve to `*.us`. If Graph shows `graph.microsoft.com`, you
forgot `-Environment USGov`.

## Test 1 — Policies evaluate in Report-only
**Do:** `https://entra.microsoft.us` → **Monitoring & health → Sign-in logs →** open a pilot sign-in
→ **Report-only** tab.
**Expected:** Each policy shows a result (Would apply / satisfied / would block) — proving
evaluation works.

## Test 2 — Compliant device satisfies the control
**Do:** From a compliant pilot device, sign in to `https://outlook.office365.us`. Run
`CAIG-Validation.ps1`.
**Expected:** Access granted; the "require compliant device" policy is satisfied.

## Test 3 — Noncompliant device is challenged/blocked
**Do:** From a noncompliant or unmanaged device, attempt the same sign-in (Report-only shows the
would-be result).
**Expected:** Report-only logs "would block"; after enforcement, access is blocked.

## Test 4 — MFA is required
**Do:** Sign in as a pilot user from a new session (auth goes to `login.microsoftonline.us`).
**Expected:** An MFA challenge appears (after enforcement) / Report-only logs "would require MFA".

## Test 5 — Legacy authentication is blocked
**Do:** Attempt a legacy-auth connection (e.g. an older IMAP client) as a pilot user.
**Expected:** Report-only logs "would block"; after enforcement, the legacy client is denied.

## Test 6 — Break-glass accounts are exempt
**Do:** Run **`CAIG-Validation.ps1`**; sign in with a break-glass account.
**Expected:** Break-glass accounts are excluded from all policies and sign in without CA controls.

## Test 7 — Policy + sign-in report
**Do:** Run **`CAIG-Report.ps1`**.
**Expected:** A clear list of policies/states and a summary of CA results across recent sign-ins,
pulled from `graph.microsoft.us`.

## Test 8 — (If used) named location is honored
**Do:** If you built a location policy in Step 3, sign in from inside and outside the trusted named
location.
**Expected:** The policy applies per the named-location condition (not via legacy MFA Trusted IPs).

---
## Pass/fail gate
| Gate | Requirement |
|---|---|
| **Sovereign check** | Test 0 confirms `*.us` portal + **USGov** Graph before any other test |
| **Pilot pass (Report-only)** | Tests 1–6 behave as expected with **no unexpected** would-blocks for legitimate users |
| **Enforcement pass** | After enabling, pilot users work normally; break-glass verified; no lockouts |
