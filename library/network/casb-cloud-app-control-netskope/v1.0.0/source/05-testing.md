# 5. Testing Guide — CASB & Cloud App Control with Netskope

Run after the pilot policies apply (Implementation Step 7) and after each expansion stage. Use the
named artifacts from the Implementation Guide.

## Test 1 — Discovery populated and scored
Do: Confirm the app risk register — All cloud apps – Discovery stage is populated; run `NSCASB-Report.ps1`.
Expected: Discovered apps are listed with a risk score and a disposition; sanctioned vs unsanctioned is distinguished.

## Test 2 — Sanctioned app allowed
Do: From a pilot endpoint, use a sanctioned app for normal work (login, view, edit).
Expected: The sanctioned app works normally; the Sanctioned apps policy – In-scope apps – Configure allows it.

## Test 3 — Restrict / coach on an unsanctioned app
Do: From a pilot endpoint, attempt the controlled activity (for example upload) on an unsanctioned app.
Expected: The Unsanctioned apps policy – Shadow IT – Configure restricts, coaches, or blocks per the register — not all-or-nothing.

## Test 4 — Inline activity control fires
Do: Exercise a controlled activity (upload, external share, download) covered by the activity controls — Inline – Configure profile.
Expected: The lever applies (allow / restrict / coach / block) on the activity, scoped to the pilot group; confirm with `NSCASB-Validation.ps1`.

## Test 5 — Data-movement control catches sensitive content
Do: Attempt to move sensitive test content to an unsanctioned destination.
Expected: The data-movement control restricts or blocks the transfer per policy.

## Test 6 — API connection governs data at rest
Do: For a sanctioned API-governed app, create a test exposed share / external collaborator.
Expected: The API connections — Sanctioned apps – Configure surface the finding (and apply the chosen response once promoted from monitor mode).

## Test 7 — Pilot scoping correct
Do: Run `NSCASB-Validation.ps1`.
Expected: The named policies are scoped to `CASB Pilot – Pilot users – Pilot` (not the whole fleet) before expansion.

## Test 8 — Usage & risk report
Do: Run `NSCASB-Report.ps1`.
Expected: A clear cloud-app usage and risk report — sanctioned vs shadow IT, per-app risk score, and policy coverage gaps.

---
## Pass/fail gate
| Gate | Requirement |
|---|---|
| Pilot pass | Tests 1-7 pass for the pilot group; controls fire as designed with no business-blocking false positives |
| Expand pass | Tests 1-4 and 8 pass after re-scoping to `CASB Broad – All users – Expand`; API policies promoted only after pilot pass |
