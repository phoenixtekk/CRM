# 5. Testing Guide — Zero Trust Architecture: Conditional Access Baseline & Rollout

Run after the baseline is built in report-only (Implementation Step 3) and again before and after
each enforce wave. Scripts are referenced by name; all reads are read-only.

## Test 1 — Baseline exists and is report-only
Do: Run `ENTZTCA-Discovery.ps1` (or `ENTZTCA-Validate.ps1`).
Expected: All baseline policies `CA001`-`CA008` (minus any you skipped for licensing) exist, each with
`Enable policy = Report-only`, and each excludes `CA Exclusion - Break-Glass - Steady`.

## Test 2 — Break-glass is excluded from every policy
Do: Run `ENTZTCA-Validate.ps1 -BreakGlassUpn bg1@contoso.onmicrosoft.com,bg2@contoso.onmicrosoft.com`.
Expected: Every policy reports the break-glass accounts as excluded — no policy applies to them. Any
policy missing the exclusion is flagged in red.

## Test 3 — What-If matches the persona design
Do: `Conditional Access -> What If` for one representative user per persona (admin, internal, guest)
and for a break-glass account.
Expected: Each persona sees the intended policies apply (admin -> `CA002`/`CA008`; internal ->
`CA001`/`CA003`; guest -> `CA006`); the break-glass account has **no** policy applied.

## Test 4 — Report-only impact is clean
Do: After a few days of report-only, review `Conditional Access -> Insights and reporting` and run
`ENTZTCA-Report.ps1`.
Expected: Each policy "would apply" to the correct persona; no unexpected "would block" for legitimate
users; service accounts are not caught by interactive policies.

## Test 5 — MFA is required where enforced
Do: After enforcing `CA001` for a wave, have an internal pilot user sign in from a browser without a
prior MFA session.
Expected: The user is required to complete MFA; a user outside the enforced scope is not.

## Test 6 — Phishing-resistant MFA required for admins
Do: After enforcing `CA002`, have a pilot admin attempt sign-in with only a phishable method.
Expected: Access is blocked until they use a phishing-resistant method (FIDO2 / passkey); the admin
succeeds with it.

## Test 7 — Device control enforced
Do: After enforcing `CA003`, have an internal pilot user sign in from a non-compliant / non-hybrid
device to a targeted app.
Expected: Access is blocked (or remediation is required); the same user on a compliant/hybrid device
is granted. *If `CA003` was skipped for licensing, mark N/A.*

## Test 8 — Legacy authentication blocked
Do: After enforcing `CA007`, attempt a legacy-auth sign-in (for example a basic-auth mail client) as a
scoped user.
Expected: The legacy sign-in is blocked; modern-auth sign-ins for the same user succeed; break-glass
and any documented legacy exception are unaffected.

## Test 9 — Risk policies fire (P2 only)
Do: If licensed for P2 and `CA004`/`CA005` are enforced, simulate/observe a medium+ risk sign-in.
Expected: `CA004` requires MFA on the risky sign-in; `CA005` requires a secure password change on high
user risk. *Mark N/A if P1-only.*

## Test 10 — Rollback works
Do: Set one enforced policy back to `Report-only`.
Expected: Enforcement stops immediately; the policy still logs impact in report-only. Confirms the
one-click rollback path.

---
## Pass/fail gate
| Gate | Requirement |
|---|---|
| Report-only pass | Tests 1-4 pass; every policy is report-only and excludes break-glass; report-only impact is clean |
| Pilot enforce pass | Tests 5-8 (and 9 if P2) pass for the pilot ring; Test 2 still passes; Test 10 confirms rollback |
| Wave expand pass | Tests 5-8 pass for each enforced wave with no spike in unexpected blocks (`ENTZTCA-Report.ps1`); break-glass never blocked |
