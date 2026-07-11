# 5. Testing Guide — Technical Blocker Mitigation: Defender for Cloud

Run these checks after applying a fix on the affected scope (`MDC Blocker Triage – Affected Scope – Diagnose`) and again after each expansion wave. Each test has a **pass/fail gate**; do not resume the wider rollout until the affected scope passes the test for its blocker class. Objects are referenced by the exact names from the Implementation Guide.

## Test 1 — Blocker pinpointed (baseline captured)
**Procedure:** Run `TBMMDC-Discovery.ps1` and confirm `MDC-blocker-discovery.json` has plan states, provisioning settings, connectors, and policy/assessment presence populated; run `TBMMDC-Coverage.ps1` for the coverage baseline.
**Pass:** A single earliest broken link is identifiable; the affected scope is documented.
**Fail:** Snapshot empty or access-denied — fix read access (Requirements 2.1) and re-run.

## Test 2 — Defender plan enabled
**Procedure:** Run `TBMMDC-Validate.ps1`; in **Defender for Cloud → Environment settings → Defender plans** confirm the required plan shows **On** for the affected subscription.
**Pass:** The required plan(s) show **On** (Standard).
**Fail:** Plan Free / will not stay on — see Troubleshooting *Plan will not enable / reverts to Free*.

## Test 3 — Agent / agentless coverage
**Procedure:** Run `TBMMDC-Coverage.ps1`; confirm the affected machines are covered (agent/extension provisioned or agentless scanning enabled) with no unexplained gaps.
**Pass:** Covered resources report data; the coverage gap is closed.
**Fail:** Machines still report no data — see Troubleshooting *Agent / agentless coverage gap*.

## Test 4 — AWS / GCP connector connected
**Procedure:** Run `TBMMDC-Validate.ps1`; in **Environment settings** confirm the AWS/GCP connector shows **connected / syncing**.
**Pass:** The connector is connected and resources appear in scope.
**Fail:** Connector not connected / not syncing — see Troubleshooting *AWS/GCP connector failure*.

## Test 5 — Recommendations / assessments populate
**Procedure:** Run `TBMMDC-Validate.ps1`; confirm assessments/recommendations exist for the affected scope and Secure Score returns a value.
**Pass:** Assessments populate and Secure Score is present.
**Fail:** Empty Secure Score / no assessments — see Troubleshooting *Recommendations not populating*.

## Test 6 — Policy assignment present
**Procedure:** Run `TBMMDC-Discovery.ps1`; confirm the **Microsoft cloud security benchmark** policy assignment exists and is evaluating at the affected scope.
**Pass:** The benchmark policy is assigned and evaluating.
**Fail:** Missing/failing assignment — see Troubleshooting *Recommendations not populating*.

## Test 7 — Before/after evidence produced
**Procedure:** Run `TBMMDC-Report.ps1` and confirm it emits a before/after comparison (including Secure Score movement where relevant) from the Step 1 snapshot versus current state.
**Pass:** The report shows the blocker's link moved from broken to cleared.
**Fail:** No change captured — re-run discovery to refresh the baseline.

## Test 8 — Escalation bundle valid (only if escalating)
**Procedure:** If the blocker persists after a correct fix, run `TBMMDC-SupportBundle.ps1` and confirm `MDC Support Bundle – <case> – Escalate` contains the discovery snapshot, coverage analysis, affected scope, and timestamps.
**Pass:** A complete, attachable bundle exists.
**Fail:** Bundle incomplete — re-run discovery / coverage first, then rebuild.

---
### Exit gate
The affected scope passes the tests for its blocker class **before** you resume the wider rollout (Implementation Step 6). Re-run Tests 2–5 and 7 after each expansion wave and compare against the saved baseline.
