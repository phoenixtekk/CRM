# 6. Troubleshooting Guide — Technical Blocker Mitigation: Defender for Cloud

The four blocker classes in **symptom → cause → fix** form, plus escalation. Run `TBMMDC-Discovery.ps1` and `TBMMDC-Coverage.ps1` first — most causes surface there. This *is* the troubleshooting solution, so this guide is the core reference.

## Plan will not enable / reverts to Free
**Symptom:** A Defender plan for a subscription in `MDC Blocker Triage – Affected Scope – Diagnose` will not turn **On**, or reverts to **Free** after saving.
**Cause:** An **Azure Policy / deny assignment** or management-group setting overrides the plan, a required **resource provider** is not registered, or the account lacks the rights to change pricing.
**Fix:** In **Environment settings → Defender plans**, set the plan **On** and save. If it reverts, check for a policy/deny assignment or MG setting forcing Free, and register the required resource providers. Confirm you have Security Admin/Owner-delegated rights. *Enabling a paid plan has cost impact — change-approved.* Re-run `TBMMDC-Discovery.ps1`.

## Agent / agentless coverage gap
**Symptom:** The plan is **On**, but machines report **no data** and appear as coverage gaps.
**Cause:** **Auto-provisioning** of the agent/extension is off, the agent's **Log Analytics workspace** is unreachable/unlinked, or **agentless scanning** is not enabled.
**Fix:** Run `TBMMDC-Coverage.ps1` to separate an agent-provisioning gap from an agentless gap. Turn on auto-provisioning of the required agent/extension (or relink the workspace per `global-requirements-defender.md` G7), or enable agentless scanning in the plan settings. Allow provisioning time, then re-run `TBMMDC-Coverage.ps1`.

## AWS/GCP connector failure
**Symptom:** A multicloud connector never finishes onboarding or shows **not connected / not syncing**; AWS/GCP resources are unassessed.
**Cause:** The **CloudFormation role** (AWS) or **service account / Terraform** (GCP) has the wrong permissions, onboarding did not complete, or credentials rotated.
**Fix:** In **Environment settings**, re-run the connector onboarding — correct the AWS role/permissions or the GCP service account and re-apply the CloudFormation/Terraform artifacts. Confirm the connector returns to **connected / syncing**. *Verify current multicloud onboarding requirements.* Re-run `TBMMDC-Validate.ps1`.

## Recommendations not populating
**Symptom:** Secure Score and assessments stay empty even though plans are On and machines are covered.
**Cause:** The **Microsoft cloud security benchmark** policy assignment is missing or failing at the scope, resource providers are not registered, or assessments have not had time to evaluate.
**Fix:** Confirm the benchmark policy assignment exists and is evaluating at the affected scope (`TBMMDC-Discovery.ps1` reports it); register required resource providers; trigger/await a compliance evaluation and allow assessments to populate (hours). Re-run `TBMMDC-Validate.ps1`.

## Script cannot authenticate / read
**Symptom:** `TBMMDC-*.ps1` fails on `Connect-AzAccount`, or `Get-AzSecurityPricing` returns access-denied.
**Cause:** The Az modules are missing, the wrong tenant/subscription context is selected, or the account lacks Security Reader / Reader.
**Fix:** `Install-Module Az`; `Connect-AzAccount` and `Set-AzContext` to the correct tenant/subscription; confirm Security Reader / Reader. Re-run.

## When to escalate to Microsoft support
Escalate — and attach `MDC Support Bundle – <case> – Escalate` — when **all** of the following hold:
- The required plan is set **On** (and not overridden by policy/MG) with providers registered.
- Auto-provisioning / agentless scanning is enabled and the workspace is reachable.
- The AWS/GCP connector role/permissions are correct.
- The benchmark policy is assigned and evaluating.
- The correct documented fix was applied and warm-up time elapsed, yet the blocker persists.
In that case the root cause is likely a **service-side issue**, not your configuration. Run `TBMMDC-SupportBundle.ps1`, open the case, and attach the bundle. *Incident-response and cost decisions remain the customer's; this is a service-support escalation.*
