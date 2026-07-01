# 5. Testing Guide — Configuration Manager and Intune Co-Management Enablement

Run after the pilot collection enrolls (Implementation Step 5) and after each workload move.

## Test 1 — Co-management enabled and pilot scoped
Do: Console to Administration to Cloud Services to Co-management to Properties; confirm
`Co-Management – Configuration – Production` exists with automatic enrollment set to Pilot and the
pilot collection `Co-Management – Pilot Collection – Stage 1`.
Expected: Co-management is enabled and scoped to the pilot collection only.

## Test 2 — Pilot devices enrolled in Intune
Do: Intune to Devices to All devices; confirm pilot devices appear. On a device run
`COMGMT-Validation.ps1`.
Expected: Pilot devices are present in Intune and report co-managed (dual authority).

## Test 3 — Cloud attach (tenant attach) healthy
Do: Run `COMGMT-Validation.ps1`; in Intune to Devices, confirm tenant-attached devices show.
Expected: The site is connected and devices are visible from the cloud console.

## Test 4 — Workload authority is correct per slider
Do: Run `COMGMT-Report.ps1` and on a pilot device run `COMGMT-Validation.ps1`.
Expected: Each moved workload reports Intune (or Pilot Intune) as the authority; unmoved workloads
report Configuration Manager.

## Test 5 — Moved workload policy applies
Do: For the workload just moved (e.g. Compliance), confirm the Intune policy applies — for Compliance
the device shows a compliance state in Intune.
Expected: The Intune policy for the moved workload is applying on the pilot device.

## Test 6 — Equivalent Intune policy assigned before move
Do: Run `COMGMT-Report.ps1` to list which workloads have an assigned Intune policy.
Expected: Every workload set to Pilot Intune or Intune has an assigned equivalent Intune policy (no
capability gap).

## Test 7 — Un-enrolled clients remediated
Do: Run `COMGMT-Report.ps1` to find pilot devices not yet enrolled; run `COMGMT-Remediation.ps1`
(default `-WhatIf` first).
Expected: The report identifies gaps; remediation triggers a policy/enrollment retry on those
clients.

---
## Pass/fail gate
| Gate | Requirement |
|---|---|
| Pilot pass (per workload) | Tests 1 to 6 pass for that workload on the pilot collection |
| Expand pass | Tests 4 and 6 pass fleet-wide before moving the slider to Intune (all) |
