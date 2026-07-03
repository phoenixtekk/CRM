# 6. Troubleshooting Guide — Intune Administrative Governance (RBAC & Multi-Admin Approval) — Government (GCC High)

Use `RBACGOVG-Discovery.ps1` and `RBACGOVG-Validation.ps1` for current state,
`RBACGOVG-Report.ps1` for coverage/over-privilege, and `RBACGOVG-Remediation.ps1` (`-WhatIf` by
default) for safe fixes. All scripts connect to **US Gov Graph** (`-Environment USGov`).

## A. Sign-in / wrong-cloud errors (GCC High specific — check this first)
| Symptom | Cause | Remediation |
|---|---|---|
| Portal rejects your government account / redirect loop | You opened a Commercial `*.com` portal | Use the sovereign `*.us` URL: `intune.microsoft.us`, `entra.microsoft.us`, `portal.office365.us/adminportal/` |
| `Connect-MgGraph` fails auth or returns no data | Missing `-Environment USGov`; module hit `login.microsoftonline.com` | Add `-Environment USGov` (DoD: `-Environment USGovDoD`); confirm it targets `graph.microsoft.us` |
| Graph calls time out behind proxy | US Gov endpoints or `*.manage.microsoft.us` blocked / TLS-inspected | Allow US Government Intune/Graph URLs; **do not SSL-inspect** `*.manage.microsoft.us` |

## B. Admin can see/do too much or too little
| Symptom | Cause | Remediation |
|---|---|---|
| Admin sees objects they should not | Object missing the scope tag, or assignment carries the wrong tag | Apply `Region A – Devices – Prod` to the object; confirm the assignment's scope tag with `RBACGOVG-Validation.ps1` |
| Admin cannot see objects they should manage | Object not tagged, or admin in the wrong group | Tag the object; confirm membership of `Intune Admins – Region A – Prod` |
| Admin can perform actions outside their role | Over-broad custom role or a second, wider assignment | Run `RBACGOVG-Report.ps1` to find over-privilege; tighten with `RBACGOVG-Remediation.ps1` |

## C. Multi-admin approval not gating changes
| Symptom | Cause | Remediation |
|---|---|---|
| Gated change applies without approval | Access policy missing or wrong resource type, or not yet **Completed** | Confirm `App Deploy Approval – All – Prod` / `Script Deploy Approval – All – Prod` exist, target the right type, and were finalized with **Complete** — `RBACGOVG-Validation.ps1` |
| No approvers can act | Approver group empty, not a security group, or not added to a role | Populate `Change Approvers – Apps – Prod`; ensure it is a **security group** added to an Intune role assignment as a member group |
| Approver membership keeps disappearing | Approver group not added to any Intune role assignment (Intune strips it periodically) | Add the approver group to a role assignment as a member group |
| Requester can self-approve | Requester is also in the approver group | An admin cannot approve their own request; a **different** approver must act — keep requesters and approvers distinct |
| Multi Admin Approval node not present | MAA not surfaced on this tenant | Run `RBACGOVG-Discovery.ps1`; if `operationApprovalPolicies` errors or the node is absent, treat MAA as **[verify for GCC High]** and open a Microsoft support case |

## D. GCC-High-specific gotchas
- **No Change Review Agent / Copilot column.** Security Copilot is not available in GCC High/DoD, so
  the MAA node has no Agent Response suggestions — approvals are fully manual. This is expected, not a
  bug.
- **No notifications.** Intune never emails on new/changed requests; if an approval seems ignored,
  the approver simply wasn't told — escalate out-of-band per your SLA.
- **Requests expire in 3 days.** A "stuck" request that passed 3 days is **Expired** and must be
  resubmitted.
- **"Allow access to unlicensed admins" is irreversible.** If an approver lost access after you
  toggled licensing, review the unlicensed-admin limits; you cannot turn the setting back off.

## E. Locked out (no one can make changes)
- Symptom: every admin is blocked by the approval gate or by an over-tight role, or a **Role**-type
  access policy deadlocked RBAC.
- Remediation: sign in with the break-glass Global Administrator (excluded from the gate) at
  `intune.microsoft.us`. For a Role-policy deadlock: Tenant administration → Multi Admin Approval →
  Access policies → delete the **Role** policy, wait 3–5 minutes, complete the RBAC assignment
  (add the approver group), then re-create the Role policy if desired. This is why the break-glass
  account in requirement 2.4 is mandatory.

## F. Pending approval requests stuck
- Approvers not responding within the SLA → escalate per the change-control process (requirement
  2.8); confirm the approver group is populated and someone with **Approval for Multi Admin
  Approval** permission is available. Remember there are no notifications and a 3-day expiry.

## G. Scripts cannot read governance data
- The discovery/validation/report scripts need **US Gov** Microsoft Graph access and the right read
  scopes (for example `DeviceManagementRBAC.Read.All`, `DeviceManagementConfiguration.Read.All`).
  Confirm the operator consented to the requested scopes, that `-Environment USGov` is in effect, and
  that the workstation can reach `https://graph.microsoft.us`.

## H. Diagnostics quick reference (US Gov)
```powershell
Connect-MgGraph -Environment USGov -Scopes 'DeviceManagementRBAC.Read.All' -NoWelcome
(Invoke-MgGraphRequest -Method GET -Uri '/beta/deviceManagement/roleDefinitions').value | Select-Object displayName, isBuiltIn
(Invoke-MgGraphRequest -Method GET -Uri '/beta/deviceManagement/roleScopeTags').value | Select-Object displayName, id
(Invoke-MgGraphRequest -Method GET -Uri '/beta/deviceManagement/operationApprovalPolicies').value | Select-Object displayName, policyType
```
If `operationApprovalPolicies` returns an error on your GCC High tenant, MAA may not be surfaced —
capture the error and open a Microsoft support case.

## I. When to escalate
If roles, scope tags, and access policies match the design (confirmed by `RBACGOVG-Validation.ps1`),
the approver group is a security group added to a role and populated, and the break-glass path works,
but approvals still do not behave as expected, capture the `RBACGOVG-Report.ps1` output and open a
Microsoft support case referencing your GCC High / DoD tenant.
