# 6. Troubleshooting Guide — Intune Administrative Governance (RBAC & Multi-Admin Approval)

Use `RBACGOV-Discovery.ps1` and `RBACGOV-Validation.ps1` for current state,
`RBACGOV-Report.ps1` for coverage/over-privilege, and `RBACGOV-Remediation.ps1` (`-WhatIf` by
default) for safe fixes.

## A. Admin can see/do too much or too little
| Symptom | Cause | Remediation |
|---|---|---|
| Admin sees objects they should not | Object missing the scope tag, or assignment carries the wrong tag | Apply `Region A – Devices – Prod` to the object; confirm the assignment's scope tag with `RBACGOV-Validation.ps1` |
| Admin cannot see objects they should manage | Object not tagged, or admin in the wrong group | Tag the object; confirm membership of `Intune Admins – Region A – Prod` |
| Admin can perform actions outside their role | Over-broad custom role or a second, wider assignment | Run `RBACGOV-Report.ps1` to find over-privilege; tighten with `RBACGOV-Remediation.ps1` |

## B. Multi-admin approval not gating changes
| Symptom | Cause | Remediation |
|---|---|---|
| Gated change applies without approval | Access policy missing or wrong resource type | Confirm `App Deploy Approval – All – Prod` / `Script Deploy Approval – All – Prod` exist and target the right type — `RBACGOV-Validation.ps1` |
| No approvers can act | Approver group empty or wrong group selected | Populate `Change Approvers – Apps – Prod`; confirm the policy targets it |
| Requester can self-approve | Requester is also in the approver group | Remove requesters from the approver group — separation of duties requires distinct people |

## C. Locked out (no one can make changes)
- Symptom: every admin is blocked by the approval gate or by an over-tight role.
- Remediation: sign in with the break-glass Global Administrator (excluded from the gate), then loosen
  or remove the offending access policy or assignment. This is why the break-glass account in
  requirement 2.4 is mandatory.

## D. Pending approval requests stuck
- Approvers not responding within the SLA → escalate per the change-control process (requirement
  2.8); confirm the approver group is populated and notifications reach approvers.

## E. Scripts cannot read governance data
- The discovery/validation/report scripts need Microsoft Graph access and the right read scopes
  (for example `DeviceManagementRBAC.Read.All`, `DeviceManagementConfiguration.Read.All`). Confirm
  the operator consented to the requested scopes and can reach `https://graph.microsoft.com`.

## F. Diagnostics quick reference
```powershell
Connect-MgGraph -Scopes 'DeviceManagementRBAC.Read.All'
(Invoke-MgGraphRequest -Method GET -Uri '/beta/deviceManagement/roleDefinitions').value | Select-Object displayName, isBuiltIn
(Invoke-MgGraphRequest -Method GET -Uri '/beta/deviceManagement/roleScopeTags').value | Select-Object displayName, id
(Invoke-MgGraphRequest -Method GET -Uri '/beta/deviceManagement/operationApprovalPolicies').value | Select-Object displayName, policyType
```

## G. When to escalate
If roles, scope tags, and access policies match the design (confirmed by `RBACGOV-Validation.ps1`),
the approver group is populated, and the break-glass path works, but approvals still do not behave as
expected, capture the `RBACGOV-Report.ps1` output and open a Microsoft support case.
