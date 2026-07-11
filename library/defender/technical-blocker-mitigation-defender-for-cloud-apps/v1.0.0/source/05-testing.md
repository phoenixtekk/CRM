# 5. Testing Guide — Technical Blocker Mitigation: Defender for Cloud Apps

Run these checks after applying a fix on the affected subset (`MDCA Blocker Triage – Affected Apps – Diagnose`) and again after each expansion wave. Each test has a **pass/fail gate**; do not resume the wider rollout until the affected subset passes the test for its blocker class. Session policies stay in **monitor** mode during testing. Objects are referenced by the exact names from the Implementation Guide.

## Test 1 — Blocker pinpointed (baseline captured)
**Procedure:** Run `TBMMCA-Discovery.ps1` and confirm `MDCA-blocker-discovery.json` has the plan, activity-signal presence, discovery hint, and CA App Control summary populated.
**Pass:** A single earliest broken link is identifiable; the affected apps are in the triage subset.
**Fail:** Snapshot empty or access-denied — fix read access (Requirements 2.1) and re-run.

## Test 2 — Connector connected (activity signal)
**Procedure:** Run `TBMMCA-Validate.ps1`; in **Cloud apps → App connectors** confirm the affected connector shows **connected**.
**Pass:** The connector is connected and `CloudAppEvents` shows recent activity for the app.
**Fail:** Connector error/disconnected or no activity — see Troubleshooting *Connector authentication failure*.

## Test 3 — Cloud Discovery data
**Procedure:** In **Cloud apps → Cloud discovery → Dashboard**, confirm discovery data appears from the intended source.
**Pass:** The discovery dashboard shows data.
**Fail:** Dashboard empty — see Troubleshooting *Cloud Discovery no-data*.

## Test 4 — Conditional Access App Control present and scoped
**Procedure:** Run `TBMMCA-ConditionalAccess.ps1`; confirm `Use Conditional Access App Control – Pilot Apps – Diagnose` is **enabled**, targets the affected users/apps, and its session control is **Use Conditional Access App Control**.
**Pass:** A correctly scoped, enabled App Control policy exists.
**Fail:** Missing / disabled / misscoped — see Troubleshooting *Session policy / CA App Control not engaging*.

## Test 5 — Session control engages on a test session
**Procedure:** Have the pilot user sign in to the target app in a browser and generate activity; in the MDCA **activity log** confirm the session was proxied and the monitor-mode session policy recorded a hit.
**Pass:** The test session routes through the MDCA reverse proxy and the session policy records the activity.
**Fail:** Session not proxied — see Troubleshooting *Session policy / CA App Control not engaging*.

## Test 6 — Licensing present
**Procedure:** Run `TBMMCA-Discovery.ps1` and confirm the MDCA plan (and the Entra plan for CA App Control) is reported as licensed.
**Pass:** The required plans are present. *Verify current plan requirements in your tenant.*
**Fail:** Plan missing — see Troubleshooting *Licensing gap*.

## Test 7 — Before/after evidence produced
**Procedure:** Run `TBMMCA-Report.ps1` and confirm it emits a before/after comparison from the Step 1 snapshot versus current state.
**Pass:** The report shows the blocker's link moved from broken to cleared.
**Fail:** No change captured — re-run discovery to refresh the baseline.

## Test 8 — Escalation bundle valid (only if escalating)
**Procedure:** If the blocker persists after a correct fix, run `TBMMCA-SupportBundle.ps1` and confirm `MDCA Support Bundle – <case> – Escalate` contains the discovery snapshot, CA App Control analysis, affected apps/policies, and timestamps.
**Pass:** A complete, attachable bundle exists.
**Fail:** Bundle incomplete — re-run discovery / CA analysis first, then rebuild.

---
### Exit gate
The affected subset passes the tests for its blocker class **before** you resume the wider rollout (Implementation Step 5). Re-run Tests 2–5 and 7 after each expansion wave and compare against the saved baseline. Move a session policy from monitor to enforce only with SOC approval.
