# 5. Testing Guide — Endpoint Reporting & Dashboards

Run after the pilot is built (Implementation Step 8) and after each distribution cycle. The goal of
testing here is **reconciliation** — the report/export numbers must equal the console numbers.

## Test 1 — Data sources readable
**Do:** Run `EPRPT-Discovery.ps1`.
**Expected:** It signs in and reads managed devices, compliance, configuration, and apps, and reports
non-zero device counts for the scope.

## Test 2 — Scope groups correct
**Do:** Run `EPRPT-Set-ReportingScopeTargeting.ps1` in read mode.
**Expected:** `Endpoint Reporting Scope – Pilot – Stage` and `Endpoint Reporting Scope – Fleet – Prod`
exist with the expected membership counts.

## Test 3 — Export produces files
**Do:** Run `EPRPT-Export-Scheduled.ps1` (default dry single run) to the reporting destination.
**Expected:** One or more CSV/JSON export files land in `-OutputPath` and open cleanly.

## Test 4 — KPI report renders
**Do:** Run `EPRPT-Report.ps1 -Group "Endpoint Reporting Scope – Pilot – Stage"`.
**Expected:** A consolidated report shows patch %, compliance %, encryption %, app success %, and
health % plus a per-device CSV.

## Test 5 — Numbers reconcile (the gate)
**Do:** Run `EPRPT-Validation.ps1` for the pilot scope; compare each KPI to the matching Intune
**Reports** portal view (Device compliance, Windows updates, Encryption, App install status).
**Expected:** Each KPI matches the console within the validation tolerance; no KPI flagged as
mismatched.

## Test 6 — Configuration Manager devices counted (if applicable)
**Do:** Open Configuration Manager console → **Monitoring → Reporting → Reports** and compare the
software-update/compliance figures to the consolidated report's Configuration Manager portion.
**Expected:** Configuration-Manager-managed devices are represented and consistent.

## Test 7 — Distribution cycle
**Do:** Confirm the scheduled export `Endpoint KPI Distribution – Leadership – Prod` produced its
latest files and the dashboard refreshed.
**Expected:** Current-dated export files exist; the dashboard shows the latest KPI values.

---
## Pass/fail gate
| Gate | Requirement |
|---|---|
| **Pilot pass** | Tests 1–5 pass; every KPI reconciles for `Endpoint Reporting Scope – Pilot – Stage` |
| **Fleet pass** | Tests 1–7 pass for `Endpoint Reporting Scope – Fleet – Prod` before broad distribution |
