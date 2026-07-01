# 5. Testing Guide — Netskope Client Deployment & Traffic Steering at Scale (Intune)

Run after the pilot ring deploys (Implementation Step 7), and again after each ring expansion and any
steering/exception change. Netskope console-side analytics are deferred to the Netskope documentation;
these tests validate the Intune deployment and the device-side client/steering state.

## Test 1 — App deployment succeeded
Do: Intune -> Apps -> Windows -> open `Netskope Client – Windows – Production` -> Device install status
(for the ring under test).
Expected: Devices in the ring show Installed; no Failed installs left unaddressed.

## Test 2 — Client present and healthy on device
Do: On a ring device, run `NSCLIENT-Validation.ps1`.
Expected: Client installed, service running, enrolled to the correct tenant, steering active.

## Test 3 — Steering is actually moving traffic
Do: On a ring device, confirm the client reports steering active (per `NSCLIENT-Validation.ps1` and the
client UI/logs defined by Netskope docs).
Expected: In-scope traffic is steered; the device is not bypassing the platform.

## Test 4 — Exceptions keep business apps working
Do: On a ring device with the client active, use each app on `Steering Exceptions – Business Apps –
Production`.
Expected: Every listed business app works; no app on the exception list is broken by steering/inspection.

## Test 5 — SSL inspection trusts cleanly (if used)
Do: On a ring device, browse inspected HTTPS sites.
Expected: Sites load with no certificate warnings (the decryption certificate is trusted via the
Intune certificate profile).

## Test 6 — Fleet deployment + exception coverage report
Do: Run `NSCLIENT-Report.ps1`.
Expected: A clear per-ring breakdown of installed/failed/pending clients and certificate coverage; any
gaps are visible and assigned for remediation.

## Test 7 — Ring targeting is correct
Do: Run `NSCLIENT-Set-RolloutRingTargeting.ps1 -WhatIf`.
Expected: Each ring group has the intended membership; no device is in two rings or missing from all.

---
## Pass/fail gate
| Gate | Requirement |
|---|---|
| Pilot pass | Tests 1-5 pass on `Device Group – Pilot – Stage1`; no business app broken; no cert errors |
| Early pass | Tests 1-6 pass on `Device Group – Early – Stage2` before broad expansion |
| Broad pass | Tests 1-6 pass on `Device Group – Broad – Stage3`; failed/unhealthy clients remediated |
