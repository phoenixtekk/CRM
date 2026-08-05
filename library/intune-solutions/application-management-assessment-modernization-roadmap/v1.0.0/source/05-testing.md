# 5. Testing Guide — Application Management Current-State Assessment & Modernization Roadmap

The purpose of these tests is different from a configuration solution's. There is nothing deployed to
verify. Instead, these tests prove the **assessment itself is trustworthy**: that every score is
evidence-backed, that the method is repeatable (a second assessor reaches the same scores), and that the
outputs (findings, roadmap, readout) are complete and internally consistent. Run each test at the stage
named; the pass/fail gates at the end must all pass before the readout.

## Test 1 — Access is genuinely read-only

**Do:** After connecting, run `Get-MgContext` and `APPASMT-Estate-Inventory.ps1 -WhatIfAccessCheck`.
**Expected:** `Get-MgContext` shows scopes ending only in `.Read.All` — no `.ReadWrite` scope anywhere.
The access check confirms the app estate is readable. No script in the pack contains a `New-`, `Set-`,
`Update-`, `Remove-`, or `Invoke-*` write call.
**Why it matters:** the read-only guarantee is a deliverable. If any write scope is present, stop and
reduce the grant before proceeding — the customer approved a read-only assessment.

## Test 2 — Every dimension has evidence, or an explicit gap

**Do:** After Step 5, open the `APPASMT – Evidence Pack` and `APPASMT-EvidencePack.json`.
**Expected:** Each of the nine dimensions has either a signal (script output, artifact, or interview
note) or an explicit **"Insufficient Evidence"** marker. No dimension is silently blank.
**Why it matters:** a blank dimension read as L1 is a fabricated finding. "Insufficient Evidence" is an
honest, actionable result (it tells the customer to grant access or produce the artifact).

## Test 3 — Every score cites its evidence

**Do:** Review the `APPASMT – Scoring Sheet`. For each dimension, follow the evidence citation to the
artifact, interview note, or script output it names.
**Expected:** Every current-level score points to a real, locatable piece of evidence. Spot-check three
dimensions and confirm the evidence actually supports the level awarded per the evidence table in
Implementation Step 5.
**Why it matters:** a score you cannot trace to evidence is an opinion. The whole value of the model is
that the score is defensible.

## Test 4 — The score matches the evidence table (repeatability spot-check)

**Do:** Pick two dimensions — ideally one high and one low. Independently re-award the level from the
evidence, using only the evidence table (Implementation Step 5), without looking at the recorded score.
**Expected:** The independently re-derived level matches the recorded level. If it does not, the
evidence table was applied inconsistently — reconcile and correct.
**Why it matters:** repeatability is the test of objectivity. If two passes over the same evidence
disagree, the model is being scored on opinion, not evidence.

## Test 5 — Interview claims and technical data are reconciled

**Do:** Compare the interview evidence to the script evidence for D3 (rings) and D4 (currency).
**Expected:** Where they agree, the score is confident. Where they disagree (e.g. "we always use rings"
but `APPASMT-Assignment-Analysis.ps1` shows All-Devices assignments), the disagreement is **recorded as
a finding**, not silently resolved in favour of one side.
**Why it matters:** the gap between what people believe and what the tenant actually does is often the
single most valuable finding in the whole assessment.

## Test 6 — Every gap becomes a finding

**Do:** Cross-check the `APPASMT – Scoring Sheet` against the `APPASMT – Findings Register`.
**Expected:** Every dimension with a gap > 0 has at least one finding. Each finding has all fields
populated: dimension, description, cited evidence, business impact, risk rating, remediation direction,
and effort band. No finding contains build-level step-by-step instructions.
**Why it matters:** a gap with no finding is a gap the roadmap will miss; a finding that re-teaches
implementation breaks the scope boundary that keeps this an assessment.

## Test 7 — Every finding lands in exactly one wave, with dependencies drawn

**Do:** Review the `APPASMT – Roadmap One-Pager` and `APPASMT – Wave Plan`.
**Expected:** Every finding sits in exactly one of Wave 1 (Quick Wins), Wave 2 (Foundational), or
Wave 3 (Strategic). Each strategic item that depends on a foundational item has the dependency drawn.
No Wave 3 item is scheduled to start before the Wave 2 item it depends on.
**Why it matters:** a roadmap with unsequenced dependencies is a wish list. The dependency arrows are
what make it a plan.

## Test 8 — The executive summary contains all five mandatory elements

**Do:** Read the executive summary page of `APPASMT – Executive Readout`.
**Expected:** It contains, on one page: (1) the overall maturity band, (2) the three highest-risk
findings, (3) the single most important dependency, (4) the Wave 1 quick wins startable next week, and
(5) the headline effort for the full roadmap.
**Why it matters:** the executive summary is the only page most sponsors read. If it is missing any of
the five, the decision-maker cannot make the decision the assessment exists to enable.

## Test 9 — The assessment is repeatable end to end

**Do:** Confirm the Evidence Pack, Scoring Sheet, Findings Register, and Roadmap are all retained and
named per this solution, and that re-running the five scripts against the same tenant reproduces the
same summary counts (within the noise of ongoing tenant activity).
**Expected:** The artifacts are complete and named; a re-run reproduces the machine signals. The
engagement can be re-run in 6–12 months to measure the trend.
**Why it matters:** the trend across re-runs is the proof the modernization investment worked — but only
if the first run was captured in a form the second run can be compared to.

---

## Pass/fail gate

| Gate | Requirement |
|---|---|
| **Read-only** | Test 1 passes — only `.Read.All` scopes; no write calls anywhere |
| **Evidence complete** | Tests 2–3 pass — every dimension has evidence or an explicit gap; every score cites its source |
| **Objective & reconciled** | Tests 4–5 pass — independent re-scoring matches; interview vs data disagreements are findings |
| **Findings complete** | Test 6 passes — every gap is a fully-populated finding; no implementation detail |
| **Roadmap sound** | Tests 7–8 pass — findings waved with dependencies; executive summary has all five elements |
| **Repeatable** | Test 9 passes — artifacts retained and named; scripts reproduce; trend re-run is possible |
