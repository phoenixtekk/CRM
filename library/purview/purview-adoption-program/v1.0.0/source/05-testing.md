# 5. Testing & Validation Guide — Microsoft Purview Adoption Program

Validate that the **adoption program actually drives and measures behavior change** — not that Purview is
merely configured. Each test below has an explicit **pass/fail** signal and, where relevant, a **rollback**.
Run the Part-A tests once when you stand the program up, then treat the Part-B tests as the acceptance gate
for each rollout wave. All checks are **read-only or `-WhatIf`** unless a step is explicitly a controlled
change.

## Test 1 — Adoption surface inventory + baseline (RB-01 / setup)
1. Run `OPSADOPT-Discovery.ps1` and confirm it returns a non-empty inventory of **published** sensitivity
   labels, label policies (with scope), and DLP/retention policies with their mode.
2. Run `OPSADOPT-Discovery.ps1 -SaveBaseline`, then make **no** changes and re-run with `-CompareBaseline`.
   - **Pass:** the diff reports **zero surface drift** and echoes the recorded starting behavior window.
   - **Fail:** drift reported with no change made → the baseline key is wrong; re-baseline.

## Test 2 — Adoption signal reads from the audit log (RB-01)
1. Run `OPSADOPT-Report.ps1 -Days 30`. Confirm it authenticates, searches the unified audit log, and returns
   **labeling activity** (label apply/change/remove events) and **DLP** match/override counts.
   - **Pass:** counts render and reconcile with the Purview **Activity explorer** / audit search for the same
     window; a labeling-coverage figure is computed.
   - **Fail:** an "audit search unavailable / not enabled" error → confirm audit logging and your Audit
     Reader role (Requirement 2.3). *(If no activity exists in the window, the script reports an empty result
     cleanly — a valid pass for a pre-launch baseline.)*
2. Run with `-RingGroup "<current ring>"` and confirm the signal is scoped to the ring's members.
   *(Operation names/record types vary by tenant/workload — if a category looks empty, verify the operation
   names for your tenant; see Troubleshooting.)*

## Test 3 — Champion + ring coverage diff (RB-02 / setup)
1. Run `OPSADOPT-Validation.ps1 -RosterCsv <roster.csv> -RingGroup "Adoption Ring – Purview – Wave1"
   -ChampionsGroup "Champions – Purview – Adoption"`.
   - **Pass:** every in-scope area in the roster maps to a champion present in the champions group, and the
     ring membership matches the intended wave; gaps and unexpected members are listed explicitly.
2. Remove a champion from the roster's area (or from the group) and re-run.
   - **Pass:** the missing-champion gap is flagged for that area.
   - **Rollback:** restore the champion; the next run shows full coverage.

## Test 4 — Ring-expansion helper is safe by default (RB-04 / change control)
1. Run `OPSADOPT-Remediation.ps1 -Action AddWave -RingGroup "Adoption Ring – Purview – Wave2" -MembersCsv
   <wave2.csv> -WhatIf`.
   - **Pass:** it lists the users it *would* add and confirms **no change was made**; the ring membership is
     unchanged when re-checked.
   - **Fail:** any membership change occurs under `-WhatIf` → stop and do not use `-Commit` until fixed.
2. Only in a change window, run the same with `-Commit`.
   - **Pass:** the wave's users are added to the ring **and** a row is written to `Change Record – Purview –
     Adoption`.
   - **Rollback:** `-Action RemoveWave -RingGroup "Adoption Ring – Purview – Wave2" -MembersCsv <wave2.csv>
     -Commit` removes them and records the reversal.

## Test 5 — Adoption KPI dashboard + wave gate (RB-03 / RB-05)
1. Run `OPSADOPT-KpiReport.ps1 -CommsCsv <comms-reach.csv> -RingGroup "<current ring>"`.
   - **Pass:** `KPI Dashboard – Purview – Adoption` renders the KPI set — labeling coverage %, DLP
     override/false-positive rate, champion coverage %, comms reach %, and trend vs the baseline — with each
     KPI compared to its threshold and the **wave-gate** verdict (clear / hold) shown.
   - **Fail:** the comms CSV does not parse → re-export/confirm columns (the script prints the columns it
     found).
2. Confirm a ring **below** threshold produces a **hold** verdict (no expand/enforce) and a ring **at/above**
   threshold produces a **clear** verdict.

## Test 6 — The wave cadence actually fires (program model)
1. Confirm the wave loop has run once end to end: a ring piloted, measured (RB-01), reinforced (RB-02),
   gated (RB-03, recorded in `Wave Gate – Purview – Adoption`), and expanded (RB-04) — each with a named owner.
   - **Pass:** one full wave cycle has produced its artifacts, and mandatory/enforce was introduced **only**
     to a ring that had cleared its gate.
   - **Fail:** any expansion or enforcement done **before** a passing wave gate → roll back the enforcement,
     re-earn adoption, and re-gate before proceeding.

---
## Acceptance gate (all must pass before declaring the program "adopting")
- [ ] Discovery returns the published adoption surface; baseline diff is clean.
- [ ] Report reads labeling + DLP override signal from the audit log and reconciles with Activity explorer.
- [ ] Coverage diff maps every in-scope area to a champion and flags gaps; ring matches the wave.
- [ ] `OPSADOPT-Remediation.ps1` makes no change under `-WhatIf`; `-Commit` expands the ring **and** writes a
      change record; rollback works.
- [ ] KPI dashboard renders all adoption KPIs vs thresholds and shows the correct wave-gate verdict.
- [ ] One full wave cycle has run with named owners, and enforcement was introduced only after a passing gate.
