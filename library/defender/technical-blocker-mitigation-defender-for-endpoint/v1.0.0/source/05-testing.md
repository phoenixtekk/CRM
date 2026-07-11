# 5. Testing Guide — Technical Blocker Mitigation: Defender for Endpoint

Run these checks after applying a fix on the affected subset (`MDE Blocker Triage – Affected Ring – Diagnose`) and again after each expansion wave. Each test has a **pass/fail gate**; do not resume the wider rollout until the affected subset passes the test for its blocker class. Objects are referenced by the exact names from the Implementation Guide.

## Test 1 — Blocker pinpointed (baseline captured)
**Procedure:** Run `TBMMDE-Discovery.ps1` and confirm `MDE-blocker-discovery.json` was written with the licensing, connector, policy, and per-state device counts populated.
**Pass:** A single earliest broken link is identifiable from the snapshot; the affected devices are in `MDE Blocker Triage – Affected Ring – Diagnose`.
**Fail:** Snapshot empty or access-denied — fix read access (Requirements 2.1) and re-run.

## Test 2 — Service-endpoint connectivity
**Procedure:** Run `TBMMDE-Connectivity.ps1` against a sample affected device.
**Pass:** All documented Defender service endpoints report reachable.
**Fail:** One or more endpoints blocked — see Troubleshooting *Sensor Inactive / Impaired communication*; the fix is a proxy/firewall allow, not an MDE change.

## Test 3 — Device onboarding cleared
**Procedure:** Run `TBMMDE-Validate.ps1`. In `security.microsoft.com` → **Assets → Devices**, confirm each device in the affected subset now shows **Onboarded** (not "Can be onboarded").
**Pass:** Every affected device is onboarded; the script reports onboarded state.
**Fail:** A device stays "Can be onboarded" — see Troubleshooting *Device not onboarding*.

## Test 4 — Sensor health restored
**Procedure:** Run `TBMMDE-Validate.ps1`. In **Assets → Devices**, confirm sensor health is **Active** (not Inactive / Impaired communication / No sensor data) for the affected subset.
**Pass:** Sensors are Active and reporting.
**Fail:** Sensor still Inactive/Impaired — re-check Test 2 connectivity, then see Troubleshooting *Sensor Inactive / Impaired communication*.

## Test 5 — Telemetry flowing
**Procedure:** Run `TBMMDE-Validate.ps1`, which executes the saved query `MDE Onboarding Blocker Check – Tenant – Diagnose` to count recent rows in `DeviceInfo` / `DeviceEvents` for the affected devices.
**Pass:** Recent rows appear for the affected devices within the expected window.
**Fail:** No rows — allow warm-up time, confirm device-group scoping, see Troubleshooting *No telemetry after onboarding*.

## Test 6 — Intune connector healthy (Intune channel)
**Procedure:** Run `TBMMDE-Discovery.ps1` and confirm the reported **MDE ↔ Intune connector** state is **Enabled**; in Intune confirm the EDR policy is assigned to the affected subset.
**Pass:** Connector Enabled and policy assigned.
**Fail:** Connector disabled/expired or policy unassigned — see Troubleshooting *MDE–Intune connector broken*.

## Test 7 — Before/after evidence produced
**Procedure:** Run `TBMMDE-Report.ps1` and confirm it emits a before/after comparison from the Step 1 snapshot versus current state.
**Pass:** The report shows the blocker's link moved from broken to cleared.
**Fail:** No change captured — re-run discovery to refresh the baseline.

## Test 8 — Escalation bundle valid (only if escalating)
**Procedure:** If the blocker persists after a correct fix, run `TBMMDE-SupportBundle.ps1` and confirm `MDE Support Bundle – <case> – Escalate` contains the discovery snapshot, connectivity results, affected device IDs, and timestamps.
**Pass:** A complete, attachable bundle exists (plus the on-device client-analyzer output).
**Fail:** Bundle incomplete — re-run discovery/connectivity first, then rebuild.

---
### Exit gate
The affected subset passes the tests for its blocker class **before** you resume the wider rollout (Implementation Step 6). Re-run Tests 3–5 and 7 after each expansion wave and compare against the saved baseline.
