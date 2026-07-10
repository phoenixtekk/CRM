# 6. Troubleshooting Guide — Microsoft Defender for Cloud: CSPM & Secure Score Remediation

Common field issues, in **symptom → cause → fix** form. Run `DEFCSPM-Discovery.ps1` and `DEFCSPM-Validate.ps1` first — most causes surface there.

## Defender CSPM not enabling
**Symptom:** The Defender CSPM plan stays **Off/Free** after saving, or the save fails.
**Cause:** The account lacks **Security Admin / Owner** at the subscription, the **Microsoft.Security** provider is not registered, or the plan is not available in the region/tenant.
**Fix:** Confirm the running account's rights at `CSPM Scope – Pilot Sub – Pilot`; register the provider (`Register-AzResourceProvider -ProviderNamespace Microsoft.Security`); *verify Defender CSPM availability and pricing in your tenant*. Preview with `DEFCSPM-Enable-CSPM.ps1 -WhatIf`, then `-Apply`, and re-run `DEFCSPM-Validate.ps1`.

## No agentless scan results
**Symptom:** Agentless scanning is enabled but no machine vulnerability/misconfiguration assessments appear.
**Cause:** Not enough time has passed for the first scan, Defender CSPM is not actually active, or the scanning permissions/scope are missing.
**Fix:** Allow warm-up time (scans populate over hours); confirm Defender CSPM is on (Test 1); *verify current agentless scanning requirements* and re-enable in the plan settings. Re-run `DEFCSPM-Validate.ps1`.

## Compliance dashboard empty
**Symptom:** **Regulatory compliance** shows no controls or no standard.
**Cause:** No standard is assigned to the subscription, or assessments have not populated yet.
**Fix:** Assign the Microsoft cloud security benchmark (and any standard the compliance team specifies) under **Manage compliance policies** (Implementation Step 4); allow assessment time. *The choice of standard is the compliance team's.*

## Secure Score not moving
**Symptom:** After remediating recommendations, Secure Score is unchanged.
**Cause:** The fix has not been re-assessed yet, the "fixed" resource still fails a related control, or the remediated recommendation carries little score weight.
**Fix:** Allow re-assessment time; confirm the fix in **Recommendations** shows the resource as healthy; prioritize **higher-weight / attack-path** recommendations (they move the score more). Re-run `DEFCSPM-Report.ps1 -BaselinePath .\defcspm-baseline.json`.

## No attack-path data
**Symptom:** `DEFCSPM-Hunt.ps1 -Mode AttackPaths` returns nothing.
**Cause:** **Defender CSPM** is not enabled (attack paths are a Defender CSPM feature), or the security graph has not built yet.
**Fix:** Confirm Defender CSPM is on (Test 1); allow warm-up time for the cloud security graph; re-run the hunt. If still empty, verify the plan in the portal.

## Exemption without expiry
**Symptom:** A recommendation is exempted permanently or without justification.
**Cause:** An exemption was created without an expiry/justification, creating a silent blind spot.
**Fix:** Edit the exemption to add a justification and an **expiry**, and name it `CSPM Exemption – <recommendation> – Prod`. Review exemptions on a cadence. *Whether the exemption is acceptable is the security/compliance team's decision.*

## Continuous export no data
**Symptom:** The Log Analytics workspace receives no recommendation/Secure Score data.
**Cause:** The export `CSPM Continuous Export – Pilot Sub – Prod` is misconfigured, points at the wrong workspace, or the identity lacks write permission.
**Fix:** Confirm the export config, workspace, and exported data types (recommendations + Secure Score); confirm workspace permissions; allow ingestion time. Re-run `DEFCSPM-Validate.ps1` and query the workspace.

## Secure Score empty
**Symptom:** `DEFCSPM-Report.ps1 -SaveBaseline` returns no Secure Score.
**Cause:** Assessments are too recent to compute a score, or the account lacks **Security Reader**.
**Fix:** Allow assessment warm-up; confirm the account has at least Security Reader; re-run. If still empty, verify CSPM is enabled on the subscription.

## Script cannot authenticate or query Resource Graph
**Symptom:** `DEFCSPM-*.ps1` fails on connect, or the Resource Graph hunt errors.
**Cause:** The Az modules (`Az.Accounts`, `Az.Security`, `Az.ResourceGraph`) are missing, the account is not signed in, or it lacks read access at scope.
**Fix:** Let the script install the modules (it checks on run); `Connect-AzAccount` and `Set-AzContext` to the pilot subscription; confirm Security Reader (or higher). Re-run the script.
