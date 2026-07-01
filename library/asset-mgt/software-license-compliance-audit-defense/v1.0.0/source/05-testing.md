# 5. Testing Guide — Software License Compliance & Audit-Defense (Effective License Position)

Run after the pilot reconciliation (Implementation Step 8) and after each reconciliation cycle.

## Test 1 — Both inputs are complete
Do: Open the `Entitlement Baseline – <Publisher/Product> – Source` and the
`Deployment Inventory – <Publisher/Product> – Discovered`; run `LICCOMP-Validation.ps1`.
Expected: Both sets are present for the in-scope product, with no empty quantity, edition, or metric
fields; every entitlement line has a proof reference (or is flagged "unproven").

## Test 2 — Normalization joins cleanly
Do: In the `Effective License Position – <Publisher/Product> – ELP` workbook, check the
normalization mapping; run `LICCOMP-Validation.ps1`.
Expected: Every raw product/edition name maps to one canonical line; no unmapped rows; deployment is
counted in the entitlement's metric.

## Test 3 — The ELP reconciles
Do: Review the ELP line math (entitled minus consumed, after product use rights); run
`LICCOMP-Report.ps1`.
Expected: Each product line shows a clear position; rights and metric notes are present; the totals
match the report.

## Test 4 — The gap register is complete
Do: Open the `Gap Register – <Publisher/Product> – Reconciled`.
Expected: Every shortfall and surplus from the ELP appears, each with a cause, an owner, and a
planned action; no gap is unassigned.

## Test 5 — Remediation previews safely
Do: Run `LICCOMP-Remediation.ps1` (default `-WhatIf`).
Expected: It reports the over-deployment/stale assignments it would reclaim and makes no change;
nothing is removed until re-run with `-WhatIf:$false` after sign-off.

## Test 6 — Gaps close on re-reconciliation
Do: After closing actions, refresh the inventory and re-run `LICCOMP-Report.ps1`.
Expected: Shortfalls are closed or carry an approved, dated action; the position improves.

## Test 7 — Audit package is defensible
Do: Open the `Audit Package – <Publisher/Product> – Defense`.
Expected: It contains the entitlement proofs, deployment evidence with source/date, normalization
notes, product-use-rights interpretation, the ELP, the gap-closure record, and owner sign-off.

---
## Pass/fail gate
| Gate | Requirement |
|---|---|
| Pilot pass | Tests 1 to 4 and Test 7 pass for the pilot publisher/product; shortfalls have an approved action |
| Expand pass | Tests 1 to 7 pass for each added publisher/product before it is declared audit-ready |
