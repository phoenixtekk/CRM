# 6. Troubleshooting Guide — Software Renewals, Contracts & OEM Bundle Tracking

Use `SWRENEW-Validation.ps1` for repository completeness, `SWRENEW-Report.ps1` for the calendar and
due-soon tiers, `SWRENEW-Discovery.ps1` to re-seed from Graph, and `SWRENEW-Remediation.ps1` (default
`-WhatIf`) for safe fixes.

## A. Renewals not appearing on the calendar
| Symptom | Cause | Remediation |
|---|---|---|
| A known contract is missing from the calendar | No record in the repository, or a blank `RenewalDate` | Add the contract; run `SWRENEW-Validation.ps1` to find blank dates; fill from the source document |
| Calendar is empty or stale | Report run against the wrong CSV, or not refreshed | Re-run `SWRENEW-Report.ps1 -CsvPath .\repository.csv -OutDir .\reports` |
| Contract shows but in the wrong order | `RenewalDate` not in `YYYY-MM-DD` ISO format | Correct the date format; re-run the report |

## B. Alerts firing late, early, or not at all
- Alert never fires: the contract has no `RenewalDate`, or the alerting schedule is not running. Fix
  the date and confirm the scheduled `SWRENEW-Report.ps1` job is active.
- Alert fires too late to give notice: `NoticePeriodDays` is longer than the earliest active tier.
  Raise the earliest tier for that contract so the notice window sits inside an alert.
- Alert reaches the wrong person: `Owner` is wrong or the routing group is stale. Update the
  repository and re-run `SWRENEW-Set-ScopeTargeting.ps1`.

## C. OEM bundle problems
| Symptom | Cause | Remediation |
|---|---|---|
| Cost looks double-counted | Child entitlements tracked as separate contracts | Set a shared `BundleId` on each child row; map them in the `OEM Bundle Map – Vendor Bundles – Master` |
| Dropping one product broke another | Bundle dependency not mapped | Record the parent SKU and all child entitlements; treat the bundle as one decision |
| Bundle renews twice | Two anchor dates for one bundle | Set a single `RenewalAnchorDate` for the `BundleId` |

## D. Validation reports incomplete records
- `SWRENEW-Validation.ps1` flags missing `RenewalDate`, `NoticePeriodDays`, `AutoRenew`, `Quantity`,
  or `AnnualCost`. Fill from source documents; for truly unknown dates, request from the vendor and
  use `SWRENEW-Remediation.ps1` to insert a placeholder record pending confirmation.

## E. Discovery returns no subscription data
- `SWRENEW-Discovery.ps1` returns nothing from Graph: the read scope is missing or the product does
  not expose subscription data. Grant `Organization.Read.All` / `Directory.Read.All`; for vendors
  with no API, populate the repository from contracts manually.

## F. Remediation made an unexpected change
- Always preview first with `-WhatIf`. If a write was wrong, restore from the timestamped backup CSV
  the script writes before any change (same folder as the repository).

## G. Diagnostics quick reference
```powershell
Import-Csv .\repository.csv | Where-Object { -not $_.RenewalDate }        # rows with no renewal date
Import-Csv .\repository.csv | Sort-Object { [datetime]$_.RenewalDate } |  # next renewals
  Select-Object Vendor,Product,RenewalDate,NoticePeriodDays -First 10
Import-Csv .\repository.csv | Group-Object BundleId                       # bundle groupings
```

## H. When to escalate
If the repository is complete, alerts are firing on time, owners are correct, and a renewal still
slipped, review the alerting channel's delivery (mailbox/queue health) and the decision-workflow
hand-off — the gap is in delivery or hand-off, not in the data.
