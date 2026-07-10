# 5. Testing Guide — Microsoft Sentinel Cost & Data-Tier Optimization

Run after the pilot table's change is configured (Implementation Step 7) and after each expansion. The two things every test must prove together: the bill went **down**, and coverage stayed **intact**.

## Test 1 — Baseline captured

**Do:** Before any change, run `SENTCOST-Audit.ps1` and save the output. Or in `Logs`, capture the 31-day billable GB per table.
**Expected:** A saved baseline of billable GB per table, so post-change savings are measurable.

## Test 2 — Pilot table is high-volume and low-value

**Do:** Run `SENTCOST-Tiering.ps1 -RuleTables <rule table list>`.
**Expected:** The pilot table appears among the top-volume tables and is flagged **safe to retier** (no active analytics rule queries it).

## Test 3 — DCR filter is active and dropping only noise

**Do:** `Monitor` → `Data Collection Rules` → confirm `Noise Filter - <TableName> - Pilot` transformation is present. In `Logs`, query the table for the filtered values over a window after the change.
**Expected:** The transformation is live; the noise rows no longer appear post-change, while legitimate rows still arrive.

## Test 4 — Table tier and retention match the decision

**Do:** Run `SENTCOST-Validate.ps1`. Or `Log Analytics workspaces` → `Tables` → `Manage table` for the pilot table.
**Expected:** The table plan (Analytics/Basic/Auxiliary) and interactive/archive retention match `Tier Decision - <TableName> - Pilot`.

## Test 5 — Billable volume dropped

**Do:** After a representative window, re-run `SENTCOST-Audit.ps1` and compare to the Test 1 baseline.
**Expected:** The pilot table's billable GB is measurably lower (from the DCR filter and/or the cheaper tier).

## Test 6 — Coverage is intact (the critical test)

**Do:** Re-run every analytics rule, workbook, and hunting query that touches (or is near) the pilot table. `Microsoft Sentinel` → `Analytics` → confirm rules still fire; run saved hunts.
**Expected:** Nothing that should still work is broken or returning empty because of the change. If anything is, roll back the tier/filter for that table (Troubleshooting).

## Test 7 — Forecast produced and defensible

**Do:** Run `SENTCOST-Forecast.ps1` with your region's rate and candidate commitment tiers.
**Expected:** A current-vs-optimized monthly projection and a recommended pay-as-you-go-or-commitment decision, recorded as `Cost Forecast - Workspace - Pilot`.

---

## Pass/fail gate

| Gate | Requirement |
|---|---|
| Pilot pass | Tests 1-7 pass: the pilot table's billable GB dropped, its tier/retention/filter match the decision, and **no dependent detection, workbook, or hunt broke** |
| Expand pass | Tests 5 and 6 pass for each additional table before moving on, and the re-forecast confirms savings against the budget target before any commitment tier is applied |
