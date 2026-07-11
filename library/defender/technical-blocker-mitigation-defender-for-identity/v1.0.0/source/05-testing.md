# 5. Testing Guide — Technical Blocker Mitigation: Defender for Identity

Run these checks after applying a fix on the affected sensor (`MDI Blocker Triage – Affected Sensors – Diagnose`) and again after each additional domain controller. Each test has a **pass/fail gate**; do not resume the wider rollout until the affected sensor passes the test for its blocker class. Objects are referenced by the exact names from the Implementation Guide.

## Test 1 — Blocker pinpointed (baseline captured)
**Procedure:** Run `TBMMDI-Discovery.ps1` and confirm `MDI-blocker-discovery.json` has the plan and identity-signal presence populated; run `TBMMDI-AuditPolicy.ps1` on the affected DC and confirm subcategory states are captured.
**Pass:** A single earliest broken link is identifiable; the affected DCs are in the triage subset.
**Fail:** Snapshot empty or access-denied — fix access (Requirements 2.1/2.2) and re-run.

## Test 2 — Sensor healthy
**Procedure:** In `security.microsoft.com` → **Settings → Identities → Sensors**, confirm the affected sensor shows **Running / Healthy**; run the sensor's own connectivity test.
**Pass:** The sensor is Running / Healthy with service reach.
**Fail:** Sensor Unhealthy / disconnected — see Troubleshooting *MDI sensor unhealthy*.

## Test 3 — DSA working (AD-query signal)
**Procedure:** Run `TBMMDI-Validate.ps1` and confirm `IdentityQueryEvents` returns recent rows for the affected DCs.
**Pass:** AD-query signal is present, indicating a working DSA.
**Fail:** No query signal — see Troubleshooting *DSA missing or under-permissioned*.

## Test 4 — Network traffic / NNR
**Procedure:** Run `TBMMDI-AuditPolicy.ps1` (NNR readiness section) and confirm NNR-relevant ports/config are ready; confirm the sensor resolves endpoints (no NNR warnings in the sensor UI).
**Pass:** NNR is functioning and the sensor sees DC traffic.
**Fail:** NNR warnings / no traffic — see Troubleshooting *Missing network traffic / NNR blind*.

## Test 5 — Event collection
**Procedure:** Run `TBMMDI-AuditPolicy.ps1` and confirm the required advanced-audit subcategories are **enabled**; run `TBMMDI-Validate.ps1` and confirm `IdentityLogonEvents` / `IdentityDirectoryEvents` return recent rows.
**Pass:** Required audit subcategories are enabled and event-based identity signal is flowing.
**Fail:** Subcategories off or no event signal — see Troubleshooting *Event-collection gap*.

## Test 6 — Licensing present
**Procedure:** Run `TBMMDI-Discovery.ps1` and confirm the MDI plan is reported as licensed and the workspace activated.
**Pass:** The required MDI plan is present and activated. *Verify current plan requirements in your tenant.*
**Fail:** Plan missing / not activated — see Troubleshooting *Licensing / activation blocker*.

## Test 7 — Before/after evidence produced
**Procedure:** Run `TBMMDI-Report.ps1` and confirm it emits a before/after comparison from the Step 1 snapshot versus current state.
**Pass:** The report shows the blocker's link moved from broken to cleared.
**Fail:** No change captured — re-run discovery to refresh the baseline.

## Test 8 — Escalation bundle valid (only if escalating)
**Procedure:** If the sensor still will not go healthy or stream after a correct fix, run `TBMMDI-SupportBundle.ps1` and confirm `MDI Support Bundle – <case> – Escalate` contains the discovery snapshot, audit-policy readiness output, affected DC list, and timestamps.
**Pass:** A complete, attachable bundle exists (plus the sensor's own log-collection output).
**Fail:** Bundle incomplete — re-run discovery / audit-policy first, then rebuild.

---
### Exit gate
The affected sensor passes the tests for its blocker class **before** you resume the wider rollout (Implementation Step 6). Re-run Tests 2–5 and 7 after each additional domain controller and compare against the saved baseline.
