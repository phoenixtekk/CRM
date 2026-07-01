# 5. Testing Guide — Software License Usage Reporting & Cost Dashboards (Power BI)

Run after the pilot dataset publishes (Implementation Step 9) and after each refresh cycle or scope expansion.

## Test 1 — Sources connect and refresh
Do: In the service, open the dataset `License Usage & Cost – Software Assets – Dataset` and choose Refresh now.
Expected: The manual refresh completes with no credential or gateway errors.

## Test 2 — KPI set matches definitions
Do: On each page, confirm the displayed measures match `License KPI Set – Software Assets – v1` (formula and source).
Expected: Deployment rate, active usage rate, days-to-expiration, cost-per-seat, and reharvest savings are present and calculated as defined.

## Test 3 — Numbers reconcile to source (the gate)
Do: Run `LICRPT-Report.ps1` and `LICRPT-Validation.ps1`; compare entitled and deployed counts to the dashboard for the pilot product family.
Expected: Variance is within the agreed tolerance; `LICRPT-Validation.ps1` reports PASS.

## Test 4 — Expirations timeline is correct
Do: Open `Expirations Timeline – Page`; check the soonest renewal against the entitlement system.
Expected: Days-to-expiration is accurate and sorted soonest-first.

## Test 5 — Reharvesting opportunities are credible
Do: Open `Reharvesting Opportunities – Page`; spot-check one product's idle-seat count against usage data.
Expected: `(Deployed - ActivelyUsed)` and the savings figure match the underlying usage extract.

## Test 6 — Scheduled refresh runs unattended
Do: Confirm `License Refresh – Software Assets – Daily` ran on schedule (dataset > Refresh history).
Expected: The most recent scheduled refresh shows Completed; failure notifications are configured.

## Test 7 — Distribution reaches the right audience
Do: Confirm only `License Reporting – Leadership & Procurement – Audience` members can open the report.
Expected: Intended members have access; others do not.

---
## Pass/fail gate
| Gate | Requirement |
|---|---|
| Pilot pass | Tests 1, 2, 3, 4, 5 pass for the pilot product family; reconciliation variance within tolerance |
| Distribution pass | Tests 6 and 7 pass; scheduled refresh green and audience access correct before broad distribution |
