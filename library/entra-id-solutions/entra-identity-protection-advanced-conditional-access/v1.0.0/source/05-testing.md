# 5. Testing Guide — Entra Identity Protection & Advanced Conditional Access

Run after the pilot policies are configured in report-only (Implementation Step 8), again after each
enforcement flip (Step 9), and after each expansion. Use `ENTIDP-Validate.ps1` for configuration
state and `ENTIDP-Report.ps1` for the risk-and-coverage picture.

## Test 1 — Identity Protection signal is flowing
Do: Entra -> `Protection -> Identity Protection -> Risky sign-ins` / `Risky users`; or run `ENTIDP-Report.ps1`.
Expected: The reports show detections/scoring (confirming P2 signal). If empty, verify P2 licensing before continuing.

## Test 2 — All four policies exist, report-only, break-glass excluded
Do: Run `ENTIDP-Validate.ps1`.
Expected: `CA – Sign-In Risk – Pilot (Report-Only)`, `CA – User Risk – Pilot (Report-Only)`, `CA – Step-Up Sensitive Apps – Pilot (Report-Only)`, and `CA – Token Protection – Pilot (Report-Only)` all exist, are in report-only, target the pilot group, and exclude `CA Break-Glass Exclusion`.

## Test 3 — Sign-in risk policy would apply on a risky sign-in
Do: With a pilot (non-break-glass) user, trigger or await a medium/high sign-in-risk event; open the sign-in in `Sign-in logs -> Report-only`.
Expected: `CA – Sign-In Risk – Pilot (Report-Only)` shows "Would apply" and would require MFA; a low-risk sign-in shows the policy not applied.

## Test 4 — User risk policy would require password change
Do: For a pilot user flagged high user-risk (or a confirmed-compromised test account), review the report-only result.
Expected: `CA – User Risk – Pilot (Report-Only)` would require MFA and a secure password change; break-glass accounts never show an apply.

## Test 5 — Step-up on the sensitive context
Do: A pilot user invokes the sensitive app/action mapped to `Auth Context c1 – Sensitive Actions – Pilot` (for example PIM activation or the sensitive app).
Expected: `CA – Step-Up Sensitive Apps – Pilot (Report-Only)` would require the phishing-resistant authentication strength; routine sign-ins to non-sensitive apps are unaffected.

## Test 6 — Token protection would apply on the supported client
Do: A pilot user signs in from the supported Windows scenario/client; review the report-only result and run `ENTIDP-Validate.ps1`.
Expected: `CA – Token Protection – Pilot (Report-Only)` would require token protection for the supported workload; unsupported clients are not blocked (they fall outside the policy scope). *Verify current supported clients.*

## Test 7 — CAE revocation behaves
Do: In a controlled test, disable a pilot test account (or reset its password) while it holds a live session to a CAE-supported service (Exchange/SharePoint/Graph).
Expected: The session is challenged/revoked in near real time (minutes), not after the full token lifetime.

## Test 8 — Break-glass path is never blocked
Do: Confirm (report-only and after enforcement) that a break-glass account can sign in with no risk/step-up/token policy applying; run `ENTIDP-Validate.ps1`.
Expected: Break-glass accounts are excluded from all four policies and retain an unobstructed path in.

## Test 9 — Enforcement matches the report-only prediction
Do: After flipping a policy to On (Step 9), repeat the relevant test above against the real `Conditional Access` result (not report-only).
Expected: The enforced behaviour matches what report-only predicted; no unexpected user population is blocked.

---
## Pass/fail gate
| Gate | Requirement |
|---|---|
| Pilot pass | Tests 1-6 and Test 8 pass in report-only; report-only results match intent; break-glass excluded |
| Enforce pass | Test 9 passes for each policy as it is flipped, in the recommended order, with no unexpected blocks |
| Expand pass | Tests re-pass at the wider scope in report-only before enforcing tenant-wide |
