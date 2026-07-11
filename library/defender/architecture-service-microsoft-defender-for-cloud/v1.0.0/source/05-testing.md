# 5. Testing Guide — Architecture Service: Microsoft Defender for Cloud

Run these checks after the pilot deployment (Implementation Steps 3–6), and again after each expansion wave. Each test has a **pass/fail gate**; do not expand across the hierarchy until the pilot passes. Objects are referenced by the exact names from the Design & Implementation Guide.

## Test 1 — Design record and Bicep parameterized
**Procedure:** Confirm `MDC Architecture Decision Record – Platform – Prod` exists with the onboarding model, plan-per-wave matrix, RBAC model, multicloud plan, export design, and cost model; and that `main.bicep` parameters match it.
**Pass:** The design record is complete and the Bicep reflects it.
**Fail:** Missing sections or Bicep drift — complete Implementation Step 2 before deploying.

## Test 2 — Bicep what-if is clean before apply
**Procedure:** Run `ARCMDC-Deploy.ps1 -Scope 'MDC Scope – Pilot MG – Pilot'` (default `-WhatIf`). Review the predicted changes.
**Pass:** The what-if shows **only** the intended plan enablements at the pilot scope — no unexpected changes.
**Fail:** Unexpected or out-of-scope changes — fix the Bicep/parameters; do **not** `-Apply`. See Troubleshooting *What-if shows unexpected changes*.

## Test 3 — Plans enabled at the pilot scope
**Procedure:** Run `ARCMDC-Validate.ps1`. In **Environment settings → `MDC Scope – Pilot MG – Pilot` → Defender plans**, confirm the wave-1 plans (CSPM + the designed workload plans) are **On**.
**Pass:** The designed plans are enabled at the pilot scope.
**Fail:** Plans Off/Free — re-run Implementation Step 3 (`-Apply`); see Troubleshooting *Plan not enabling at MG scope*.

## Test 4 — Inheritance working (a child subscription inherits the plan)
**Procedure:** Run `ARCMDC-Validate.ps1`. Pick a subscription **under** `MDC Scope – Pilot MG – Pilot` and confirm it shows the **inherited** plan state (not configured per-subscription).
**Pass:** A child subscription inherits the plan from the management-group scope.
**Fail:** The child shows Free / no inheritance — confirm the plan was set at MG (not subscription) scope and the provider is registered; see Troubleshooting *Inheritance not applying*.

## Test 5 — Providers registered
**Procedure:** Run `ARCMDC-Validate.ps1`. Confirm **Microsoft.Security** is Registered on the pilot subscriptions.
**Pass:** The provider is registered wherever plans are enabled.
**Fail:** Not registered — register it (Implementation Step 3 / policy); see Troubleshooting *Provider not registered*.

## Test 6 — RBAC least-privilege and governance rule present
**Procedure:** Run `ARCMDC-Validate.ps1`. Confirm the designed roles are assigned at the pilot scope and `MDC Governance – Platform MG – Prod` exists with owners/due dates; exemptions are time-bound.
**Pass:** RBAC matches the design (least privilege) and the governance rule is in place.
**Fail:** Over-broad role or missing governance rule — align to the design; see Troubleshooting *RBAC sprawl / missing governance*.

## Test 7 — Continuous export and SIEM path working
**Procedure:** Run `ARCMDC-Validate.ps1`. In the central Log Analytics workspace, confirm recommendation/Secure-Score/alert data from `MDC Continuous Export – Platform MG – Prod` is arriving and reaching the SIEM.
**Pass:** Export data lands in the workspace and flows to the SIEM.
**Fail:** No data — confirm the export config, workspace, and SIEM connector; see Troubleshooting *Continuous export no data*.

## Test 8 — Coverage rose and cost matches the model
**Procedure:** Run `ARCMDC-Report.ps1 -Mode Coverage -BaselinePath .\arcmdc-baseline.json` and `-Mode Cost`.
**Pass:** Coverage on the pilot scope is **higher** than baseline and the actual plan/resource drivers are within the cost model's estimate.
**Fail:** Coverage unchanged or cost drivers far exceed the estimate — reconcile before expanding; see Troubleshooting *Cost exceeds the model*.

---
### Exit gate
All eight tests pass on the pilot scope **before** any hierarchy-wide or multicloud expansion (Implementation Step 7). Re-run Tests 2–8 after each wave and compare against the re-saved coverage baseline; keep every deployment **what-if first**.
