# 5. Testing Guide — Custom Sensitive Information Types (Microsoft Purview)

Run these after building the SIT (Step 3) and again after each tuning change and before enforcing. Every
test here is **safe and read-only or contained to a simulation policy** — the point is to prove the
**detector's precision** (positives match, look-alikes don't) and that the consuming policy behaves in
**simulation** before any enforcement. Handle real sample data per your data-handling policy.
**Downstream consuming capabilities are licensing-dependent — verify availability against your tenant.**

## Test 1 — Toolchain and SIT cmdlets work
**Do:** Run `CLSCUSTOM-Discovery.ps1`.
**Expected:** `Connect-IPPSSession` succeeds; `Get-DlpSensitiveInformationType` returns SITs;
`Test-DataClassification` runs. The `Custom SIT Inventory – Evidence` snapshot lists existing custom
SITs and rule packages. **Fail** → install/update ExchangeOnlineManagement, confirm the role (Req 2.3).

## Test 2 — The SIT exists and is correctly composed
**Do:** Run `CLSCUSTOM-Report.ps1` (or `Get-DlpSensitiveInformationType -Identity 'Custom SIT – Employee
ID – Pilot'`); review its patterns.
**Expected:** The SIT exists with the intended **primary element** (regex/keyword), **supporting
evidence**, **character proximity**, and **confidence levels**, and the expected **recommended**
confidence. **Fail** → correct via `CLSCUSTOM-Configuration.ps1` (rule-package re-import).

## Test 3 — Positive samples match at the intended confidence (true positives)
**Do:** Run `CLSCUSTOM-Validation.ps1`; review the `Custom SIT Test – Positive` results in
`Custom SIT Validation – Report`.
**Expected:** Every positive sample **matches** the SIT, and does so at the **expected confidence**
level (e.g. High where a supporting keyword is present in proximity). **Fail (false negatives)** → the
regex/proximity/evidence is too tight; loosen and re-validate (Implementation Step 5).

## Test 4 — Negative / look-alike samples do NOT match (false-positive check)
**Do:** In the same `CLSCUSTOM-Validation.ps1` run, review the `Custom SIT Test – Negative` results.
**Expected:** No negative sample matches — including hard negatives (numbers of the same length, the
identifier **without** its surrounding keyword, adjacent formats). **Fail (false positives)** → the
regex/evidence is too broad; tighten (anchors, character classes, require supporting evidence, raise the
recommended confidence) and re-validate. This is the gate that protects every downstream policy.

## Test 5 — Character proximity is doing its job
**Do:** Validate two crafted items: (a) the identifier **with** its keyword within the proximity window;
(b) the identifier **far from** any keyword (outside the window).
**Expected:** (a) matches at the higher confidence; (b) matches only at a lower confidence or not at all,
per your design. **Fail** → adjust the proximity window / confidence design (Implementation Step 2/5).

## Test 6 — Publishing latency accounted for
**Do:** If a just-created/changed SIT doesn't yet behave as validated, wait and re-run
`CLSCUSTOM-Validation.ps1`.
**Expected:** After the SIT has fully published, validation results are stable and repeatable. **Fail
after ample time** → re-check the rule-package import and pattern definitions, not just latency.

## Test 7 — The consuming policy runs in SIMULATION (no enforcement)
**Do:** With the SIT referenced by `Custom SIT DLP – Simulation`, run `CLSCUSTOM-Report.ps1` and check
the policy state.
**Expected:** The consuming policy is in **test/simulation** (or disabled) mode — it reports what it
*would* match but **blocks/labels/alerts nothing**. The report shows the SIT is referenced. **Fail** →
set the policy to simulation before it processes real content.

## Test 8 — Real-content precision in simulation
**Do:** Let `Custom SIT DLP – Simulation` observe real traffic in its limited scope; review what it
*would* have matched (simulation results / policy-tip-only signals).
**Expected:** The would-be matches are overwhelmingly **true** instances of the identifier; look-alikes
are not flagged. **Fail** → tune the SIT (Step 5) and/or the policy's confidence threshold; re-simulate.

## Test 9 — "Where-used" inventory is accurate
**Do:** Run `CLSCUSTOM-Report.ps1`.
**Expected:** The report lists the SIT's patterns/confidence and **every policy that references it** (DLP
/ auto-label / etc.) — the reuse evidence. **Fail** → confirm the SIT name and that the reporting scope
covers the relevant policy types.

## Test 10 — Safe automation defaults
**Do:** Run `CLSCUSTOM-Configuration.ps1` and `CLSCUSTOM-Set-Scope.ps1` with no action switch.
**Expected:** Each runs in **`-WhatIf`** mode and only *describes* the change; nothing is modified until
`-Commit` is supplied. `CLSCUSTOM-Discovery.ps1`, `CLSCUSTOM-Validation.ps1`, and `CLSCUSTOM-Report.ps1`
are read-only. **Fail** → stop; do not run with `-Commit` until the dry-run output and validation are
correct.

---
**Gate to enforce:** Tests 1–2 (build), 3–6 (detector precision), 7–8 (simulation on real content), and
9–10 (evidence + safety) all pass → promote the consuming policy from simulation to enforce
(Implementation Step 7). Any fail → tune and re-test. Enforcement is a data-owner/compliance-approved
decision; retention/records/legal determinations are deferred to those functions.
