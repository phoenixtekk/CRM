# 5. Testing Guide — Microsoft Purview Data Security Posture Management (DSPM & DSPM for AI)

Run these after each stage. Every test is safe (read-only or simulation/test); the simulation and test
reviews are the **gates** before any enforcement. Pass/fail is explicit.

## Test 1 — Environment, licensing, roles, and auditing
**Do:** Run `PURVDSPM-ScopeConfig.ps1`; open **DSPM** and **DSPM for AI** in the Purview portal.
**Expected:** Sign-in succeeds; auditing reports as **on**; both DSPM blades load without an access
error; the licensing-dependent features are enumerated. Any absent capability is noted, not assumed.
**Gate:** Do not proceed until DSPM and DSPM for AI are visible and auditing is on.

## Test 2 — Controls inventory is complete
**Do:** Run `PURVDSPM-Discovery.ps1`; compare against **Information Protection → Labels** and **DLP →
Policies** in the portal.
**Expected:** `DSPM Posture – Estate – Discovery` lists every sensitivity label, label policy, DLP
policy, and auto-labeling policy shown in the portal — the baseline of levers DSPM will recommend.

## Test 3 — Posture and recommendations render
**Do:** Open **DSPM → Overview** and **Recommendations**; run `PURVDSPM-Discovery.ps1
-IncludeSensitiveTypes`.
**Expected:** The posture overview and sensitive-data trends display; a recommendations list is present;
`Sensitive-Data Risk – Estate – Assess` records the in-scope sensitive information types.

## Test 4 — DSPM for AI reports populate
**Do:** Open **DSPM for AI → Reports**; run `PURVDSPM-AIExposure.ps1`.
**Expected:** The AI data-access and sensitive-interaction views render (or, pre-adoption, show the
oversharing exposure with no AI activity yet); `AI Exposure – Copilot – Assess` and `Oversharing Report
– Sites – Assess` are written. *Note:* AI-interaction reporting depends on auditing being on (Test 1)
and on Copilot/AI usage having occurred.

## Test 5 — Oversharing targets are identifiable
**Do:** Cross-read `Oversharing Report – Sites – Assess` with the AI data-access view.
**Expected:** You can name the top oversharing targets — broadly-shared sites holding unlabeled
sensitive content — as the priority reduction set.

## Test 6 — Recommendation baseline captured
**Do:** Run `PURVDSPM-Tracker.ps1`.
**Expected:** `DSPM Recommendations – Estate – Tracker` snapshots the current recommendations and the
DLP / auto-labeling policy states — the before-state to re-measure against.

## Test 7 — Reduction helper makes no change in dry-run
**Do:** Run `PURVDSPM-Reduce-Oversharing.ps1 -Action AutoLabel -WhatIf` and `... -Action DlpForAI
-WhatIf`; then re-run `PURVDSPM-Discovery.ps1`.
**Expected:** The dry-run prints the intended policy it *would* create; the discovery inventory is
unchanged — `-WhatIf` created nothing. **This is the gate that proves the helper is safe by default.**

## Test 8 — Pilot policies are created in simulation/test only
**Do:** Run the helper with `-Commit` for the pilot (`Auto-Label Sensitive – Pilot – Simulation`, `DLP
for AI – Pilot – Test`); inspect them in the portal.
**Expected:** The auto-labeling policy is in **simulation** mode (labels nothing) and the DLP policy is
in **test/disabled** mode (enforces nothing). Neither changes content.
**Gate:** If either landed in an enforcing state, stop and correct before continuing.

## Test 9 — Simulation/test results are acceptable (enforcement gate)
**Do:** Let the pilot run the agreed window; review auto-labeling **simulation results** and DLP **test**
matches in the portal for false positives; confirm with stakeholders.
**Expected:** Simulated labels/blocks match intent with an acceptable false-positive rate and no
legitimate collaboration would be broken.
**Gate:** **Do not enforce (Step 8 of implementation) until this passes.**

## Test 10 — Recommendations move and oversharing drops on re-measure
**Do:** After acting on the agreed set, re-run `PURVDSPM-Tracker.ps1` and `PURVDSPM-AIExposure.ps1`;
compare to the baseline.
**Expected:** Actioned recommendations show progress/closed status and the pilot oversharing signal is
lower — evidence the posture actually improved, not just that a policy exists.

## Test 11 — Rollback works
**Do:** On a pilot policy, exercise the documented rollback (return to simulation/test or delete).
**Expected:** The policy reverts with no residual content change; the tracker export confirms the
before-state is restorable.
