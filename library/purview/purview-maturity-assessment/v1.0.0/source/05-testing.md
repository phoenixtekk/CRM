# 5. Testing Guide — Microsoft Purview Maturity Assessment

Run these after each stage: discovery and scoring (Implementation Steps 3–4), the roadmap and readout
(Steps 5–6), and — if the quick-win baseline is applied — the pilot (Steps 8–9) and re-assessment
(Step 10). The assessment tests verify the **method produced defensible, evidence-backed output**; the
baseline tests verify the quick wins landed **non-enforcing and scoped to the pilot**.

## Test 1 — Read access and health confirmed
**Do:** Run `PURVIEW-Set-ScopeTargeting.ps1 -HealthCheck`.
**Expected:** `Connect-IPPSSession` and `Connect-MgGraph` succeed; the account's roles are listed; all
ten domains report **readable** (or a documented licensing/role reason for any that are not). No domain
silently unreadable.

## Test 2 — Cross-domain evidence gathered
**Do:** Run `PURVIEW-Discovery.ps1`.
**Expected:** A signal (or an explicit "unreadable/unlicensed / verify your licensing-tenant") for each
of the ten domains D1–D10 — no domain missing from the inventory.

## Test 3 — Scorecard is complete and evidence-backed
**Do:** Run `PURVIEW-MaturityScore.ps1`; open the `Purview Maturity Scorecard`.
**Expected:** Every domain has a 0–5 score **and** a one-line evidence sentence behind it (e.g.
"D2 = L2: one DLP policy, Exchange-only, Test mode"). The overall band equals the weighted average of
the ten scores. Licensing-capped domains are flagged, not silently zeroed.

## Test 4 — Scores match the rubric (spot-check)
**Do:** Pick two domains — one configured, one absent — and compare their score to the rubric in
Implementation Step 4.
**Expected:** The absent domain scores `L0`; the configured domain's level matches its evidence (e.g.
enforced + documented + owned = `L3`; test-mode pilot only = `L2`). No score exceeds what the evidence
supports.

## Test 5 — Roadmap covers every gap
**Do:** Review `Purview Maturity Roadmap - 3 Horizons` against the scorecard.
**Expected:** Every domain below its target appears in exactly one horizon (Now / Next / Later) with a
named owner; D4/D5 items are marked HR/legal-gated; regulated retention/records/hold items are marked
as compliance/records/legal determinations, not IT tasks.

## Test 6 — Readout renders
**Do:** Run `PURVIEW-MaturityScore.ps1 -EvidencePath .\purview-evidence.json -CsvPath .\scorecard.csv`.
**Expected:** A readable scorecard (per-domain scores + overall band) printed and exported to CSV —
suitable, alongside the `Purview Maturity Roadmap - 3 Horizons`, for the stakeholder readout.

> Tests 7–9 apply only if the quick-win baseline (Implementation Steps 7–9) was run.

## Test 7 — Baseline created non-enforcing and pilot-scoped
**Do:** Run `PURVIEW-Validation.ps1` (or inspect the objects in the portal).
**Expected:** `Sensitivity Label - Confidential - Baseline` + its label policy, and
`DLP Policy - Baseline PII - Test`, exist scoped to `Purview - Pilot Users`; the DLP policy is in
**Test mode** (not enforce); no auto-labeling is turned on out of simulation.

## Test 8 — Audit enabled (if it was off)
**Do:** After remediation, run `PURVIEW-Discovery.ps1` and check the D6 signal (or Purview → **Audit**).
**Expected:** The unified audit log reports **on**; searches begin returning events (allow time to
populate).

## Test 9 — Re-assessment shows movement
**Do:** Re-run `PURVIEW-Discovery.ps1` → `PURVIEW-MaturityScore.ps1`.
**Expected:** The domains touched by the quick wins (typically D1/D2/D6/D10) move up from L0/L1 toward
L2; no domain regresses; the overall band reflects the change.

---
## Pass/fail gate
| Gate | Requirement |
|---|---|
| **Assessment pass** | Tests 1–6 pass — every domain readable or documented, scored with evidence, roadmapped with owners, readout rendered |
| **Baseline pass** | Tests 7–8 pass — quick-win objects present, **non-enforcing**, pilot-scoped; audit on |
| **Trend pass** | Test 9 passes — re-assessment shows the intended domains moving up, none regressing |
