# 3. Implementation Guide — Software Renewals, Contracts & OEM Bundle Tracking

Follow these steps in order. Do the work in your repository tool (a controlled spreadsheet/CSV, a
SAM/ITAM tool, or a CMDB) and run the scripts from an elevated PowerShell prompt. Names in
`backticks` are the named artifacts — create them with these exact names and reuse them verbatim.

> Model: build the repository and calendar once, then run the renewal lifecycle the same way every
> cycle. Prove it on a pilot product family before expanding. Deployment model: Assess → Configure →
> Pilot → Validate → Expand.

## Step 1 — Inventory contracts and renewal dates (Assess)
1. Collect every in-scope contract, order form, true-up statement, and OEM/bundle agreement.
2. For products that expose data via Microsoft Graph, run `SWRENEW-Discovery.ps1 -CsvPath
   .\renewals-seed.csv` to seed subscribed SKUs into a starter CSV.
3. For all other products, add a row per contract from the source documents.
4. Result of this step: a draft list of contracts with vendor, product, quantity, cost, and the
   renewal date where known.

## Step 2 — Build the contract and entitlement repository (Configure)
1. Create the `Contract & Entitlement Repository – All Products – Master` with this schema (one row
   per contract). These exact column names are read by the scripts:
   - `ContractId` — a unique key per contract.
   - `Vendor` — publisher / reseller.
   - `Product` — product or SKU name.
   - `Quantity` — licensed quantity.
   - `UnitCost` and `AnnualCost` — per-unit and total annual cost.
   - `Currency` — e.g. USD.
   - `TermStart` and `RenewalDate` — ISO dates (`YYYY-MM-DD`).
   - `NoticePeriodDays` — days of notice required to cancel/change.
   - `AutoRenew` — `Yes` or `No`.
   - `BundleId` — blank, or the parent bundle key from Step 4.
   - `Owner` — the named renewal owner.
   - `ProcurementLiaison` — the procurement contact.
   - `DocumentLink` — path/URL to the contract document.
2. Import the draft list from Step 1. Restrict edit rights to the SAM analyst and approver.
3. Run `SWRENEW-Validation.ps1 -CsvPath .\repository.csv` to confirm every record has the fields the
   lifecycle needs.

## Step 3 — Build the renewal calendar (Configure)
1. Create the `Renewal Calendar – All Products – Live` as a date-ordered view of the repository,
   sorted by `RenewalDate` ascending, showing `Vendor`, `Product`, `Quantity`, `AnnualCost`,
   `RenewalDate`, `NoticePeriodDays`, `AutoRenew`, and `Owner`.
2. Generate it from the repository with `SWRENEW-Report.ps1 -CsvPath .\repository.csv -OutDir
   .\reports` (produces the calendar and a cost rollup). Refresh it on a schedule (Step 6).

## Step 4 — Map OEM and suite bundles (Configure)
1. Create the `OEM Bundle Map – Vendor Bundles – Master` with: `BundleId`, `ParentSku`,
   `ChildProduct`, `RenewalAnchorDate`, and `Notes` (one row per child entitlement).
2. For each bundle, list its child entitlements under one `BundleId` and one `RenewalAnchorDate`.
3. In the repository, set `BundleId` on every contract row that belongs to a bundle so the calendar
   collapses the bundle into a single renewal decision.

## Step 5 — Arm lead-time alerts (Configure)
1. Define the `Lead-Time Alert Rules – Renewals – Tiered` as four thresholds before `RenewalDate`:
   T-120, T-90, T-60, and T-30 days.
2. Use T-120/T-90 for high-value contracts and any with a long `NoticePeriodDays`; T-60/T-30 catch
   routine renewals. The notice period must always fall inside an active alert window — if
   `NoticePeriodDays` exceeds 120, raise the earliest tier for that contract.
3. Deliver alerts through the channel chosen in Requirement 2.5. Schedule `SWRENEW-Report.ps1` to emit
   the due-soon list per tier; each alert names the `Owner` and `ProcurementLiaison`.

## Step 6 — Define the procurement coordination workflow (Configure)
1. Document the `Renewal Decision Workflow – Per Contract – Standard`:
   - On each alert, the `Owner` reviews usage and need against the repository.
   - The `Owner` classifies the renewal: keep as-is / change quantity or terms / consolidate into a
     bundle / drop.
   - The `Owner` hands the recommendation to the `ProcurementLiaison`, who executes and records the
     outcome and the new `RenewalDate`.
2. Build the routing groups with `SWRENEW-Set-ScopeTargeting.ps1`: `Renewal Owners – Pilot Scope –
   Group` for the pilot, and `Renewal Owners – All Products – Group` for the full portfolio.

## Step 7 — Pilot (Pilot)
1. Pick one product family (G7) as the pilot scope and confine the calendar and alerts to
   `Renewal Owners – Pilot Scope – Group`.
2. Run one full cycle: let an alert fire, run the decision workflow, execute through the liaison, and
   close the record with `SWRENEW-Remediation.ps1 -WhatIf` first, then without `-WhatIf` to write the
   updated renewal record.
3. Complete the Testing Guide for the pilot.

## Step 8 — Validate the pilot (Validate) — pilot gate
1. Confirm the pilot passed the Testing Guide pass/fail gate (every pilot renewal had an alert, a
   documented decision, and a refreshed `RenewalDate`).
2. Do not expand until this gate is green.

## Step 9 — Expand to the full portfolio (Expand)
1. Switch the calendar and alerts to `Renewal Owners – All Products – Group`.
2. Run the same cycle for every contract; re-validate each cycle with `SWRENEW-Validation.ps1` and
   refresh the calendar/cost report with `SWRENEW-Report.ps1`.
3. Review the cost rollup quarterly to spot consolidation and drop opportunities.

---
### Order of operations
`Inventory → Repository → Calendar → OEM bundle map → Lead-time alerts → Decision workflow → Pilot →
Validate (gate) → Expand`
