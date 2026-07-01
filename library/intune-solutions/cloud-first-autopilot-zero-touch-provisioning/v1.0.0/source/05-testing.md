# 5. Testing Guide — Cloud-First Autopilot Zero-Touch Provisioning

Run after the pilot device provisions (Implementation Step 10) and after each expansion wave.

## Test 1 — Device is Autopilot-registered
Do: Intune → Devices → Enrollment → Windows → Windows Autopilot → Devices; confirm the pilot device is
listed with the profile assigned. Or run `CFAP-Validation.ps1`.
Expected: The device appears and the deployment profile status is Assigned.

## Test 2 — Profile applied and join type correct
Do: Run `CFAP-Validation.ps1`, or on the device run `dsregcmd /status`.
Expected: `AzureAdJoined: YES` and `DomainJoined: NO` (cloud-first); the assigned profile is
`Autopilot Profile – Entra Join – Provisioning`.

## Test 3 — ESP blocked and completed
Do: Watch the provisioning run, or check Intune → Devices → Monitor → Enrollment Status Page.
Expected: The Enrollment Status Page blocked the desktop, installed the required apps/baseline, and
finished with success.

## Test 4 — Provisioning-time apps present
Do: Run `CFAP-Validation.ps1` (checks managed-app install state), or open Company Portal on the device.
Expected: Every app in `App Assignments – Core Apps – Provisioning` shows Installed.

## Test 5 — Security baseline applied
Do: Intune → Endpoint security → Security baselines → `Security Baseline – Cloud-First – Provisioning`
→ check the device status.
Expected: The pilot device shows Succeeded for the baseline.

## Test 6 — Near zero-touch confirmed
Do: Record the technician actions performed during the build (target: power-on only).
Expected: No imaging, no manual domain join, no per-app installs — technician touch is power-on only.

## Test 7 — Provisioning + touch report
Do: Run `CFAP-Report.ps1`.
Expected: A clear per-device provisioning-success result and a technician-touch summary across the
pilot group.

## Test 8 — (Conditional) Domain-join exception, if used
Do: Only if Step 11 created a hybrid exception: on that device run `dsregcmd /status`.
Expected: For the exception device only, `DomainJoined: YES` and `AzureAdJoined: YES`; all default
devices remain cloud-first.

---
## Pass/fail gate
| Gate | Requirement |
|---|---|
| Pilot pass | Tests 1–7 pass; the pilot device provisions cloud-first with apps/baseline present and technician touch is power-on only |
| Expand pass | Tests 1–5 and 7 pass for each wave before broadening rollout |
