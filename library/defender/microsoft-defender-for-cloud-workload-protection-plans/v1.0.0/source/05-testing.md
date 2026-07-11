# 5. Testing Guide — Microsoft Defender for Cloud: Workload Protection Plans (CWPP)

Run these checks after enabling the plans on the pilot subscription (Steps 2–7) and again after each expansion wave. Each test has a **pass/fail gate**; do not expand to more subscriptions until the pilot passes. Objects are referenced by the exact names from the Implementation Guide.

## Test 1 — Workload plans enabled on the pilot
**Procedure:** Run `MDCWP-Validate.ps1 -Plan All`. In Azure portal → **Defender for Cloud → Environment settings → [pilot] → Defender plans**, confirm the in-scope plans (Servers/Containers/Databases/Storage/Key Vault/App Service/Resource Manager) are **On** for `MDC Workload Plans – Pilot Subscription – Pilot`.
**Pass:** Every in-scope plan is On at the agreed tier on the pilot subscription.
**Fail:** A plan is Off or wrong tier — re-apply per Implementation Step 2.

## Test 2 — Defender for Servers coverage (MDE + agent)
**Procedure:** Run `MDCWP-Validate.ps1 -Plan Servers`. Confirm the MDE integration and monitoring agent are provisioned and healthy on the pilot servers (Arc for non-Azure).
**Pass:** Pilot servers report the MDE/agent as healthy; server detection is active.
**Fail:** Agent/MDE not provisioned — see Troubleshooting *Server agent not provisioned*.

## Test 3 — Continuous export flowing
**Procedure:** Run `MDCWP-Validate.ps1 -Plan Export`. Confirm alerts/recommendations land in `MDC Continuous Export – Workspace – Prod` (the `SecurityAlert` table).
**Pass:** Continuous export is active and data is landing in the workspace.
**Fail:** No data — see Troubleshooting *No export data*.

## Test 4 — Alert tuning in place
**Procedure:** Run `MDCWP-Report.ps1 -Section Alerts`. Confirm `MDC Alert Suppression – Benign FP – Prod` exists (scoped/documented) and email notifications are set to the SOC with a sensible severity threshold.
**Pass:** Suppression rule and notifications are configured; the alert queue is signal, not noise.
**Fail:** No tuning or over-broad suppression — re-apply per Implementation Step 5.

## Test 5 — Response workflow is notify-only
**Procedure:** Run `MDCWP-Validate.ps1 -Plan Workflow`. Confirm `MDC Workload Response – Tenant – Prod` exists, triggers on high-severity alerts, and **only notifies / creates a ticket** (no auto-remediation).
**Pass:** The workflow notifies and does not remediate during the pilot.
**Fail:** Auto-remediation is configured before agreed — reset to notify-only and confirm with the SOC.

## Test 6 — Workload alerts stream
**Procedure:** Run `MDCWP-Hunt.ps1` to execute `MDC Workload Alert Validation – Tenant – Validate`. Confirm Defender for Cloud alerts are queryable (via `SecurityAlert` / Graph Security).
**Pass:** Alerts are streaming and queryable.
**Fail:** Empty — see Troubleshooting *No workload alerts*.

## Test 7 — A benign alert actually fires
**Procedure:** Trigger a controlled detection — the Microsoft **sample alert** feature, or an EICAR-style test upload to a protected storage account (Defender for Storage). In **Security alerts**, confirm the alert appears and exported.
**Pass:** The controlled test produces a visible workload alert within the expected window.
**Fail:** No alert — see Troubleshooting *Benign alert does not fire*.

## Test 8 — Cost understood
**Procedure:** Run `MDCWP-Report.ps1 -Section Cost -SaveBaseline`. Confirm the protected-resource counts per plan are recorded so the pilot cost is understood before expansion.
**Pass:** Protected-resource counts/cost baseline captured; spend matches the approved estimate.
**Fail:** Coverage/cost is unexpected — reconcile scope before expanding; *verify current pricing.*

---
### Exit gate
All eight tests pass on the pilot subscription **before** you enable plans on more subscriptions (Implementation Step 8). Re-run Tests 1, 3, 6, 7, and 8 after each expansion wave and compare against the saved baseline.
