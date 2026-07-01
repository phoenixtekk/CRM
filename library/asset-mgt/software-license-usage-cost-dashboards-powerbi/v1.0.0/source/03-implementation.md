# 3. Implementation Guide — Software License Usage Reporting & Cost Dashboards (Power BI)

Follow these steps in order. Authoring is in Power BI Desktop; publishing, refresh, and distribution
are in the Power BI service (`https://app.powerbi.com`). Excel Power Query is used to stage the
license/contract export. Names in backticks are artifact names — reuse them verbatim.

> Model: define the KPI set, connect license and usage data, build the dashboard pages, set scheduled
> refresh and distribution, then pilot, validate (reconciliation gate), and expand.

## Step 1 — Define and record the KPI set
1. Create a one-page definition for `License KPI Set – Software Assets – v1` listing each KPI, its
   formula, and its source:
   - Deployment rate = `Deployed / Entitled` per product.
   - Active usage rate = `ActivelyUsed / Deployed` per product (define the active window, for example 30 days).
   - Days-to-expiration = `RenewalDate - Today` per contract.
   - Cost-per-seat = `AnnualUnitCost` and `AnnualUnitCost x Entitled / ActivelyUsed`.
   - Reharvesting savings = `(Deployed - ActivelyUsed) x AnnualUnitCost` per product.
2. Save it beside the report; every later page implements exactly these definitions.

## Step 2 — Stage the license/entitlement data (Excel Power Query)
1. Export entitlements (product, entitled quantity, annual unit cost, renewal date, publisher) to a file.
2. In Excel: Data > Get Data > From File, load the export, and in the Power Query Editor set types
   (quantity and cost as numbers, renewal date as date) and trim/clean product names.
3. Name the query `License Entitlements – Software Assets – Source`. Close & Load to a table; save the workbook to the share or workspace location.

## Step 3 — Generate the usage/deployment extract
1. Run `LICRPT-Export-Scheduled.ps1` to produce the usage/license extract CSV (a single dry run by
   default; add the run switch to write the file). It writes subscribed-SKU counts and per-user
   activity from Microsoft Graph.
2. Confirm the output CSV contains product, deployed/assigned count, and last-activity columns. Place it in the same location as Step 2.

## Step 4 — Build the dataset in Power BI Desktop
1. Open Power BI Desktop. Home > Get data: connect the `License Entitlements – Software Assets – Source`
   table and the Step 3 usage CSV.
2. In Transform data (Power Query), align the product key in both queries (same casing/spelling) and set data types. Apply.
3. Model view: create a relationship from entitlements to usage on the product key (one-to-one or
   one-to-many as your data dictates). Name the model file `License Usage & Cost – Software Assets – Dataset`.

## Step 5 — Author the KPI measures (DAX)
1. New measure for each KPI in Step 1, for example:
   - `Deployment Rate = DIVIDE(SUM(Usage[Deployed]), SUM(Entitlements[Entitled]))`
   - `Reharvest Savings = SUMX(VALUES(Entitlements[Product]), (CALCULATE(SUM(Usage[Deployed])) - CALCULATE(SUM(Usage[ActivelyUsed]))) * CALCULATE(MAX(Entitlements[AnnualUnitCost])))`
2. Add a `Days To Expiration = DATEDIFF(TODAY(), MAX(Entitlements[RenewalDate]), DAY)` measure.
3. Keep every measure traceable to a Step 1 definition.

## Step 6 — Build the dashboard pages
1. Add four report pages, named verbatim:
   - `Deployment & Usage – Page` — a per-product table of entitled/deployed/used plus the deployment- and usage-rate cards.
   - `Expirations Timeline – Page` — a timeline/bar of days-to-expiration, sorted ascending (soonest first).
   - `Reharvesting Opportunities – Page` — products ranked by `Reharvest Savings` descending.
   - `Cost Efficiency – Page` — cost-per-seat by product and total annualized spend.
2. Add a report-level slicer for publisher/product so the audience can filter to the reporting scope.

## Step 7 — Publish to the service
1. Home > Publish; select the workspace `License Reporting – Software Assets – Workspace`.
2. Name the published report `License Usage & Cost – Software Assets – Report`.

## Step 8 — Configure scheduled refresh
1. In the service, open the dataset > Settings.
2. Under Data source credentials, sign in for each source; if a source is on-prem, bind it to the gateway (requirement 2.8).
3. Under Scheduled refresh, enable it, set the cadence (daily or weekly), and name the schedule
   `License Refresh – Software Assets – Daily`. Add a failure-notification address.

## Step 9 — Pilot on a single product family
1. Limit the slicer/scope to one well-understood product family (global G7 pilot scope).
2. Run `LICRPT-Report.ps1` to produce the same KPI numbers from source data independently of Power BI.

## Step 10 — Validate (reconciliation gate)
1. Run `LICRPT-Validation.ps1` to reconcile the dataset's entitlement and usage counts against the
   systems of record; confirm the variance is within tolerance.
2. Compare the dashboard's pilot numbers to the `LICRPT-Report.ps1` output and to the entitlement
   system. Do not distribute broadly until they match within tolerance. Complete the Testing Guide.

## Step 11 — Distribute and expand
1. After the gate passes, grant the report (or a published app) to the audience group
   `License Reporting – Leadership & Procurement – Audience` (build/update it with `LICRPT-Set-ScopeTargeting.ps1`).
2. Expand the reporting scope to the remaining products/publishers; re-run Steps 9 to 10 for each new scope before widening distribution.

---
### Order of operations
`Define KPI set -> stage entitlements (Excel) -> generate usage extract -> build dataset -> author measures -> build pages -> publish -> scheduled refresh -> pilot -> reconciliation gate -> distribute & expand`
