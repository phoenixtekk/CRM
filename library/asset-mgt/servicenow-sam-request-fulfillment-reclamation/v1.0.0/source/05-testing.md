# 5. Testing Guide — ServiceNow SAM Request Fulfillment & License Reclamation Workflow

Run after the pilot build applies (Implementation Step 8) and after each workflow change. Use the
scripts where noted; they read ServiceNow via the Table API where available.

## Test 1 — Intake captures a tracked request
Do: Submit `Software Request – Standard – Intake` and `Software Request – Restricted – Intake` for a
pilot product.
Expected: Each submission creates a tracked request record with requester, software model, and
justification — no email needed.

## Test 2 — Triage routes correctly
Do: Observe `Request Triage – Software – Triage` for both submissions.
Expected: The standard request with an owned entitlement auto-approves; the restricted request routes to
`Approval Group – Restricted Software – Triage` and waits for approval.

## Test 3 — Entitlement check is accurate
Do: Run `SNOWSAM-Validation.ps1` and inspect the entitlement the request will consume.
Expected: `Entitlement Check – Software – Entitlement` returns "available" when units exist and "needs
procurement / reharvest" when the pool is exhausted; available = purchased minus allocated matches the
record.

## Test 4 — Fulfillment records the assignment
Do: Approve and let `License Fulfillment – Software – Fulfillment` complete.
Expected: The license is allocated, the assignment is recorded against the entitlement (available
decremented), the request is marked fulfilled, and a fulfillment time is stamped.

## Test 5 — Reclamation flags the right candidates (report-only)
Do: Run `License Reclamation – Unused – Reclamation` in report-only mode; review with the SAM owner; run
`SNOWSAM-Report.ps1`.
Expected: `Reclaim Rule – Inactive User – Reclamation` and `Reclaim Rule – No Usage 90d – Reclamation`
flag only genuinely inactive/unused assignments — no false positives on active users.

## Test 6 — Reclamation returns units (enforce mode)
Do: Switch reclamation to enforce on a known-stale assignment; re-run `SNOWSAM-Report.ps1`.
Expected: The assignment is removed, the unit returns to the available pool, and a reclamation event is
recorded.

## Test 7 — KPI set reports throughput and yield
Do: Run `SNOWSAM-Report.ps1` (and open the dashboard for `KPI Set – Request & Reclamation – Reporting`).
Expected: Request volume, time-to-fulfill, reclamation count/units, and pool utilization render with
real pilot data.

---
## Pass/fail gate
| Gate | Requirement |
|---|---|
| Pilot pass | Tests 1 to 5 pass; a full request flows intake to fulfillment and reclamation candidates are correct in report-only |
| Expand pass | Tests 6 to 7 pass; reclamation returns units and the KPI set reports cleanly before expanding scope |
