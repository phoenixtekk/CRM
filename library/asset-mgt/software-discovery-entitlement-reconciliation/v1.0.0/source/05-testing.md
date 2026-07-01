# 5. Testing Guide — Software Discovery & Entitlement Reconciliation

Run after the pilot pipeline completes (Implementation Step 9) and after each reconciliation cycle or
when a new source is added.

## Test 1 — Discovery returns installed software
**Do:** Run `SWDISC-Discovery.ps1` against the pilot source.
**Expected:** The `Installed-Software Inventory – All Sources – Discovery` is produced with publisher,
title, edition/version, and device columns populated for the scoped devices.

## Test 2 — Every raw row normalizes to a SKU
**Do:** Run `SWDISC-Validation.ps1` over the pilot inventory.
**Expected:** All raw rows resolve through the `Normalization Map – SKU Vocabulary – Configure` to a
canonical SKU; zero unresolved rows (or the unresolved rows are listed for rule creation).

## Test 3 — Entitlement register joins on the SKU vocabulary
**Do:** Run `SWDISC-Validation.ps1` and confirm SKUs in the
`Entitlement Register – Systems of Record – Configure` match the normalization map's vocabulary.
**Expected:** Register SKUs and normalized SKUs share one vocabulary; no orphaned-vocabulary warnings.

## Test 4 — Reconciliation ledger is produced
**Do:** Run `SWDISC-Report.ps1`.
**Expected:** The `Reconciliation Ledger – SKU vs Entitlement – Validate` lists, per SKU, installed
quantity, entitled quantity, and the position (over / under / balanced).

## Test 5 — Exceptions are captured, not dropped
**Do:** Inspect the `Exception Register – Unmatched & Edge Cases – Validate` from `SWDISC-Report.ps1`.
**Expected:** Every install with no SKU, and every SKU with installs but no entitlement, appears in
the register with a reason — nothing silently discarded.

## Test 6 — Remediation preview is safe
**Do:** Run `SWDISC-Remediation.ps1` (default `-WhatIf`).
**Expected:** Pending normalization-map fixes are previewed only; no changes are committed until the
script is re-run with `-WhatIf:$false`.

## Test 7 — Position holds across sources
**Do:** After expansion (Step 10), re-run `SWDISC-Report.ps1` for the full scope.
**Expected:** The ledger reconciles consistently across sources for shared SKUs; the same product from
two sources counts once per device, not twice.

---
## Pass/fail gate
| Gate | Requirement |
|---|---|
| Pilot pass | Tests 1-6 pass for the pilot source; the exception register is triaged |
| Expand pass | Tests 1-5 and 7 pass for the full multi-source scope |
