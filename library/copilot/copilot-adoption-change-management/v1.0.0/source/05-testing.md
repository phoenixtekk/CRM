# 5. Testing Guide — Microsoft 365 Copilot Adoption & Change-Management Program

Run after the pilot launches (Implementation Step 8) and on the recurring monthly cadence. Because this
is a change program, the "tests" confirm the program is stood up *and* that adoption is actually moving
against the baseline.

## Test 1 — Baseline captured
Do: Run `CPLTADOPT-Discovery.ps1`.
Expected: Assigned Copilot licenses and the count/list of users who have actually used Copilot in the
window are reported — a dated baseline you can compare against later.

## Test 2 — Champions coverage is complete
Do: Run `CPLTADOPT-ChampionsRoster.ps1`.
Expected: `Copilot Champions Network - Tenant - Steady` has at least one champion per major department;
any uncovered department is flagged.

## Test 3 — Pilot cohort is licensed
Do: Run `CPLTADOPT-Discovery.ps1` scoped to `Copilot Adoption Pilot - Pilot - Pilot`.
Expected: Every pilot member holds an assigned Copilot license; unlicensed members are flagged for
assignment.

## Test 4 — Program readiness validated
Do: Run `CPLTADOPT-Validate.ps1`.
Expected: PASS for the program elements — sponsor named, champions group populated with coverage, pilot
group licensed, use-case catalog and comms cadence recorded, and measurement working.

## Test 5 — Adoption is measurable and moving
Do: Run `CPLTADOPT-Report.ps1` and compare active usage to the Test 1 baseline.
Expected: Active usage among the pilot cohort is above baseline and shows week-over-week growth; usage
by app identifies which surfaces to push next.

## Test 6 — Under-used surfaces and cohorts are identified
Do: Review the `CPLTADOPT-Report.ps1` breakdown by app and by role/department.
Expected: The report names the under-adopted apps and the lagging departments so training and champion
attention can be targeted.

## Test 7 — License optimization surfaces reclaimable seats
Do: Run `CPLTADOPT-LicenseOptimization.ps1`.
Expected: Assigned-but-unused Copilot seats are listed as reclaim/reallocation candidates with
days-since-last-use.

---
## Pass/fail gate
| Gate | Requirement |
|---|---|
| Pilot pass | Tests 1–5 pass; pilot active usage is above baseline and growing |
| Expand pass | Tests 2–6 pass across waves; adoption sustained month-over-month; unused-license review (Test 7) on a schedule |

> Note: where a usage signal is unavailable in your tenant (*verify availability*), substitute
> champion-reported and survey-based measures for that test and record the substitution.
