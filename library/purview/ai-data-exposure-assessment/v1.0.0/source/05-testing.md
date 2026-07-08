# 5. Testing Guide — AI Data-Exposure Assessment (Microsoft Purview)

Run these after each stage. Every test is safe (read-only or simulation); the simulation review is the
**gate** that proves the recommended fix path is sound *before* anyone commits to enforcing it. Pass/fail is
explicit.

## Test 1 — Environment, licensing, roles, auditing, and AI-in-scope
**Do:** Run `AIEXPOSE-ScopeCheck.ps1`; open **DSPM for AI** in the Purview portal.
**Expected:** Sign-in succeeds; auditing reports as **on**; DSPM for AI loads without an access error; the
licensing-dependent controls are enumerated; the AI-interaction probe reports records present (in-adoption)
or none (pre-adoption). Any absent capability is noted, not assumed.
**Gate:** Do not proceed until DSPM for AI is visible and auditing is on.

## Test 2 — Access-surface inventory is complete
**Do:** Run `AIEXPOSE-Discovery.ps1`; compare against **Information Protection → Labels** and **DLP →
Policies** in the portal.
**Expected:** `AI Access Scope – Estate – Discovery` lists every sensitivity label, label policy, DLP
policy/rule, and auto-labeling policy shown in the portal — the baseline of protection exposure is measured
against.

## Test 3 — Sensitive-type scope is captured
**Do:** Run `AIEXPOSE-Discovery.ps1 -IncludeSensitiveTypes`.
**Expected:** `Sensitive Exposure – Estate – Assess` records the in-scope sensitive information types — a
portable record of what "sensitive" means in the tenant to accompany the assessment.

## Test 4 — Reachability signal populates
**Do:** Run `AIEXPOSE-Discovery.ps1 -Days 30` (with Exchange Online connected); open **DSPM for AI → Reports**.
**Expected:** `AI Reachability – Copilot – Assess` and `Oversharing Exposure – Sites – Assess` are written;
the portal AI data-access view renders. *Note:* AI-interaction reporting depends on auditing being on (Test
1) and on Copilot/AI usage having occurred — pre-adoption, the AI-interaction set is legitimately empty
while the oversharing signal is still present.

## Test 5 — Oversharing hotspots are identifiable
**Do:** Cross-read `Oversharing Exposure – Sites – Assess` with the AI data-access view.
**Expected:** You can name the top oversharing sites — broadly-shared locations likely to hold unlabeled
sensitive content — as the priority reachability set.

## Test 6 — Risk register ranks the priority exposure
**Do:** Run `AIEXPOSE-RiskRegister.ps1`.
**Expected:** `Exposure Risk Register – Estate – Rank` is written, sorted highest exposure first, each row
carrying a Score, a Rationale, and a suggested fix family. An empty register is a valid pre-adoption result
(no broad-sharing signal in the window), not a failure.

## Test 7 — Pilot helper makes no change in dry-run
**Do:** Run `AIEXPOSE-PilotRemediation.ps1 -Action AutoLabelSim -SensitivityLabel "Confidential" -WhatIf`;
then re-run `AIEXPOSE-Discovery.ps1`.
**Expected:** The dry-run prints the intended simulation policy it *would* create; the discovery inventory
is unchanged — `-WhatIf` created nothing. **This is the gate that proves the helper is safe by default.**

## Test 8 — Pilot policy is created in SIMULATION only
**Do:** Run the helper with `-Commit`
(`AIEXPOSE-PilotRemediation.ps1 -Action AutoLabelSim -SensitivityLabel "Confidential" -Commit`); inspect the
policy `Exposure Remediation – Pilot – Simulation` in the portal and via `AIEXPOSE-Validate.ps1`.
**Expected:** The auto-labeling policy is in **simulation** mode (`TestWithoutNotifications`) and labels
nothing. No content is changed.
**Gate:** If the policy landed in any enforcing mode, stop and correct (return to `TestWithoutNotifications`
or delete) before continuing — this assessment never enforces.

## Test 9 — Simulation results confirm the fix path (validation gate)
**Do:** Add the matching auto-labeling rule; let the simulation evaluate; review the **simulation results**
in the portal for false positives; confirm with stakeholders.
**Expected:** The would-be labels match intent with an acceptable false-positive rate — evidence the
recommended fix would land on the right content.
**Gate:** This is the evidence that de-risks a future enforcement decision. Enforcement itself remains a
separate follow-on; the assessment stops here.

## Test 10 — Assessment evidence is complete and consistent
**Do:** Run `AIEXPOSE-Validate.ps1`.
**Expected:** `AIEXPOSE Validate – Estate – Assess` reports PASS for every expected export (scope check,
discovery, reachability, oversharing, register), the register is in descending score order, and any pilot
policy is confirmed simulation-only. Any FAIL (missing export or a non-simulation policy) is corrected
before hand-off.

## Test 11 — Rollback works
**Do:** On the pilot simulation policy, exercise the documented rollback (delete it).
**Expected:** The policy is removed with no residual content change — the assessment changed nothing but the
one simulation policy, which enforced nothing.
