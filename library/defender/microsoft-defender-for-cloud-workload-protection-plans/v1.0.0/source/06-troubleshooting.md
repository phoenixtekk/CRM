# 6. Troubleshooting Guide — Microsoft Defender for Cloud: Workload Protection Plans (CWPP)

Common field issues, in **symptom → cause → fix** form. Run `MDCWP-Discovery.ps1` and `MDCWP-Validate.ps1` first — most causes surface there.

## Plan will not enable
**Symptom:** Test 1 fails — a workload plan stays **Off** or the enablement errors.
**Cause:** The running account lacks **Security Admin / Owner** on the subscription, the `Microsoft.Security` provider is not registered, or a policy blocks the change.
**Fix:** Confirm the role on the pilot subscription (IAM); register the `Microsoft.Security` resource provider; check for a blocking Azure Policy. Re-run the enablement (`MDCWP-EnablePlans.ps1 -Apply`) and `MDCWP-Validate.ps1 -Plan All`.

## Server agent not provisioned
**Symptom:** Test 2 fails — pilot servers show no MDE/monitoring agent, or detection is inactive.
**Cause:** Auto-provisioning is off, the monitoring agent/extension failed to deploy, or a non-Azure server is not Arc-connected.
**Fix:** In **Defender plans → Servers → Settings**, enable auto-provisioning of the MDE integration and monitoring agent; connect non-Azure servers via **Azure Arc**; check the extension deployment status on the VM. *Verify current agent/extension requirements.* Re-run `MDCWP-Validate.ps1 -Plan Servers`.

## No export data
**Symptom:** Test 3 fails — no alerts/recommendations land in `MDC Continuous Export – Workspace – Prod`.
**Cause:** Continuous export is not configured for the pilot subscription, the wrong workspace/target is selected, or no alerts have fired yet.
**Fix:** Confirm **Environment settings → Continuous export** targets the workspace and exports **Security alerts**; confirm workspace permissions; allow warm-up and generate a benign alert (Test 7). Re-run `MDCWP-Validate.ps1 -Plan Export`.

## No workload alerts
**Symptom:** Test 6 fails — `MDCWP-Hunt.ps1` returns no alerts.
**Cause:** Plans newly enabled and still warming up, no threats/tests have occurred, or export is not flowing.
**Fix:** Confirm plans are On (Test 1) and export flowing (Test 3); allow warm-up; trigger the sample alert (Test 7). Re-run `MDCWP-Hunt.ps1`.

## Benign alert does not fire
**Symptom:** Test 7 fails — the sample alert or EICAR-style storage test produces nothing.
**Cause:** The relevant plan is off (e.g. Defender for Storage for the storage test), the test targeted an unprotected resource, or not enough time has passed.
**Fix:** Confirm the specific plan for the tested resource type is On; run the Microsoft **sample alert** feature which does not depend on a real threat; ensure the storage test targets a protected account; allow the alert to surface in **Security alerts**. Re-check with `MDCWP-Hunt.ps1`.

## Alert noise / too many alerts
**Symptom:** The pilot alert queue is overwhelming.
**Cause:** No alert tuning yet, or a benign workload behavior repeatedly triggers a detection.
**Fix:** Create **scoped, documented** suppression rules (`MDC Alert Suppression – Benign FP – Prod`) only for genuinely benign patterns, set the notification severity threshold, and fix the underlying misconfiguration where possible (CSPM). Re-run `MDCWP-Report.ps1 -Section Alerts`.

## Unexpected cost
**Symptom:** Test 8 shows spend higher than the approved estimate.
**Cause:** Plans were enabled at the management-group level (covering more subscriptions/resources than intended), or a high-count resource type (e.g. many storage accounts) was included.
**Fix:** Scope enablement to `MDC Workload Plans – Pilot Subscription – Pilot` only; reconcile protected-resource counts (`MDCWP-Report.ps1 -Section Cost`); disable plans on out-of-scope resources. *Verify current pricing.* Expand deliberately.

## Response workflow auto-remediated
**Symptom:** A workload was changed automatically during the pilot.
**Cause:** `MDC Workload Response – Tenant – Prod` was configured to remediate rather than notify.
**Fix:** Reset the workflow/Logic App to **notify / ticket-only** (Implementation Step 6), confirm with the SOC, and re-validate (`MDCWP-Validate.ps1 -Plan Workflow`). *The auto-remediation decision is the security team's.*

## Script cannot authenticate
**Symptom:** `MDCWP-*.ps1` fails on connect or returns access-denied.
**Cause:** The Az / Microsoft.Graph modules are missing, the account is not signed in to the right subscription/tenant, or it lacks Security Reader.
**Fix:** Let the script install the modules (it checks on run); `Connect-AzAccount` and `Set-AzContext` to the pilot subscription; confirm Security Reader (or higher). Re-run the script.
