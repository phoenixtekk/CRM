# 6. Troubleshooting Guide — Azure Security Baseline & Governance

Use `AZSEC-Validation.ps1` / `AZSEC-Discovery.ps1` for scope state and `AZSEC-Report.ps1` for posture and drift, `AZSEC-Remediation.ps1` for safe fixes. Objects are referenced by their `<Purpose> – <Scope> – <Stage>` names.

## A. Policy assignment not taking effect
| Symptom | Cause | Remediation |
|---|---|---|
| Compliance shows blank / no resources | Evaluation hasn't run yet | Trigger a compliance scan (`Start-AzPolicyComplianceScan`); allow time — new assignments evaluate over minutes to hours |
| Assignment missing at scope | Assigned at the wrong node, or insufficient rights | Confirm scope with `AZSEC-Set-ScopeTargeting.ps1`; reassign at the management-group node; confirm Resource Policy Contributor |
| Provider errors | `Microsoft.PolicyInsights` not registered | `Register-AzResourceProvider -ProviderNamespace Microsoft.PolicyInsights`; re-run `AZSEC-Validation.ps1` |

## B. Deny blocks legitimate work
- This is why the model audits first. Create a scoped, justified, time-boxed **Exemption** for the specific resource — do not weaken the policy for everyone.
- If the block is broad or urgent, **roll back:** set the guardrail effect back to **Audit** (or remove the deny assignment). Resources already created are unaffected.

## C. Deny didn't clean up existing resources
- Expected — deny only blocks *new* non-compliant resources. Remediate pre-existing ones with a **remediation task** (for DeployIfNotExists/Modify policies) or `AZSEC-Remediation.ps1`; audit-only findings must be fixed at the resource.

## D. RBAC change broke automation or access
| Symptom | Cause | Remediation |
|---|---|---|
| A service principal or user lost access | Standing Owner was removed too broadly | Reassign the custom role `Resource Operator LeastPriv – Pilot Sub – Prod` (or a scoped built-in role) at the needed scope; prefer PIM eligible |
| Cannot assign roles | Missing User Access Administrator/Owner | Grant the operating account the role at the target scope; re-run `AZSEC-Validation.ps1` |

## E. Defender for Cloud secure score not showing / not improving
- Confirm the plan is enabled on the subscription (**Environment settings**); foundational CSPM must be on for secure score and recommendations.
- Score updates on Defender's own cadence — allow time after remediating; re-run `AZSEC-Report.ps1` to capture the new score and remaining top recommendations.

## F. Diagnostics quick reference
```powershell
Get-AzContext | Select-Object Subscription, Tenant
Get-AzPolicyAssignment -Scope '<scope>'                       # assignments at a scope
Get-AzPolicyState -Filter "ComplianceState eq 'NonCompliant'" # non-compliant resources
Get-AzRoleAssignment -Scope '<scope>' | Where-Object RoleDefinitionName -eq 'Owner'  # standing Owner
Register-AzResourceProvider -ProviderNamespace Microsoft.PolicyInsights  # if unregistered
```

## G. When to escalate
If the assignment is present at the correct scope, the provider is registered, a compliance scan has run, and compliance state or Defender secure score still does not populate after the normal evaluation window, collect `AZSEC-Report.ps1` output and the assignment/scope details and open a Microsoft support case.
