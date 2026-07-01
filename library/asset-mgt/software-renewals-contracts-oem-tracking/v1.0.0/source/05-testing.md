# 5. Testing Guide — Software Renewals, Contracts & OEM Bundle Tracking

Run after the pilot is configured (Implementation Step 7) and again each renewal cycle. Use the
pilot scope (`Renewal Owners – Pilot Scope – Group`) until the gate passes.

## Test 1 — Repository complete
Do: Run `SWRENEW-Validation.ps1 -CsvPath .\repository.csv`.
Expected: Every record reports complete — no missing `RenewalDate`, `NoticePeriodDays`, `AutoRenew`,
`Quantity`, or `AnnualCost`. Result line reads REPOSITORY COMPLETE.

## Test 2 — Calendar reflects the repository
Do: Run `SWRENEW-Report.ps1 -CsvPath .\repository.csv -OutDir .\reports` and open the
`Renewal Calendar – All Products – Live` output.
Expected: Every in-scope contract appears, sorted by `RenewalDate`, with owner and cost shown.

## Test 3 — OEM bundles collapse to one decision
Do: Inspect a bundled contract in the calendar.
Expected: The bundle's child entitlements share one `BundleId` and one renewal anchor — the calendar
shows a single renewal decision, not one per child.

## Test 4 — Lead-time alerts fire at the right tier
Do: With a contract whose `RenewalDate` is within 120 / 90 / 60 / 30 days, run `SWRENEW-Report.ps1`.
Expected: The contract appears in the correct due-soon tier, and its notice period falls inside the
alert window. The alert names the `Owner` and `ProcurementLiaison`.

## Test 5 — A renewal routes through the decision workflow
Do: Take one alerted pilot renewal through the `Renewal Decision Workflow – Per Contract – Standard`.
Expected: The owner records a keep / change / consolidate / drop decision and the liaison records the
outcome — a documented decision exists before the renewal date.

## Test 6 — Closing updates the record (safe)
Do: Run `SWRENEW-Remediation.ps1 -CsvPath .\repository.csv -WhatIf`, review the proposed changes,
then run without `-WhatIf`.
Expected: With `-WhatIf`, changes are previewed only. Without it, the closed renewal's `RenewalDate`
advances to the next term and missing records are filled. A backup of the CSV is written first.

## Test 7 — Owners route correctly
Do: Run `SWRENEW-Set-ScopeTargeting.ps1` and review the `Renewal Owners – Pilot Scope – Group`.
Expected: Each contract maps to a named owner; alerts reach the right person.

---
## Pass/fail gate
| Gate | Requirement |
|---|---|
| Pilot pass | Tests 1–5 pass; every pilot renewal had an alert, a documented decision, and a refreshed `RenewalDate` |
| Expand pass | Tests 1, 2, 4, 7 pass for the full portfolio before the next quarterly review |
