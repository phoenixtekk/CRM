# 6. Troubleshooting Guide — Entra Privileged Identity Management (PIM)

Use `ENTPIMG-Discovery.ps1` for standing-access inventory, `ENTPIMG-Validate.ps1` for activation-policy
state, `ENTPIMG-Report.ps1` for activation audit and access-review status, `ENTPIMG-Alerting.ps1` for
break-glass and alert state, and `ENTPIMG-Set-EligibleAssignments.ps1` (preview first) for safe
conversion. Keep a break-glass account available.

## A. PIM is not available / features greyed out
| Symptom | Cause | Remediation |
|---|---|---|
| No PIM node, or eligible assignments unavailable | Tenant lacks Entra ID P2, or the user is unlicensed | Assign Microsoft Entra ID P2 to the operator and PIM users (*verify availability in your tenant*); sign out and back in |
| Cannot edit role settings or create assignments | Operator lacks `Privileged Role Administrator` | Assign `Privileged Role Administrator` (or use `Global Administrator` for first-time onboarding) |

## B. Discovery or report errors / returns nothing
| Symptom | Cause | Remediation |
|---|---|---|
| `Connect-MgGraph` fails or scopes missing | SDK not installed, or PIM read scopes not consented | `Install-Module Microsoft.Graph -Scope CurrentUser`; re-run and accept `RoleManagement.Read.All`, `PrivilegedAccess.Read.AzureAD`, `Directory.Read.All` |
| Auth/endpoint errors, or connects to the wrong tenant/cloud | Connected to the commercial cloud instead of US Gov | Use `Connect-MgGraph -Environment USGov` (GCC High → `login.microsoftonline.us` / `graph.microsoft.us`). For DoD (IL5) use `-Environment USGovDoD` (`dod-graph.microsoft.us`). *Verify the correct cloud for your tenant.* |
| Azure resource roles missing from discovery | Subscription not onboarded to PIM, or no Azure RBAC on the scope | Onboard the subscription (`PIM -> Azure resources -> Discover resources`); grant `User Access Administrator`; re-run with `-IncludeAzureResources` |
| Empty results | Signed in to the wrong tenant | Confirm the tenant; re-run |

## C. A user cannot activate a role
| Symptom | Cause | Remediation |
|---|---|---|
| No eligible role shows under `My roles` | The eligible assignment was not created, or it expired | Create/renew the eligible assignment (`Eligible assignments -> Add`); confirm with `ENTPIMG-Discovery.ps1` |
| Activation blocked at MFA | The user has no registered MFA method | Register an MFA method; break-glass excepted, all admins should have phishing-resistant MFA |
| Activation stuck "pending approval" | No approver available or approver not notified | Ensure `PIM Privileged Role Approvers - Tenant - Steady` has active members and notifications are on; an approver approves in `PIM -> Approve requests` |

## D. Admin got locked out after removing standing access
- Sign in with a break-glass account (`bg-admin-01@contoso.onmicrosoft.com`). Re-add the needed
  assignment under `Active assignments -> Add`, or create/adjust the eligible assignment and relax the
  activation policy. This is exactly why break-glass accounts are created first and kept excluded.

## E. Break-glass account is at risk
| Symptom | Cause | Remediation |
|---|---|---|
| `ENTPIMG-Alerting.ps1` flags a break-glass account as PIM-eligible or policy-covered | It was onboarded to PIM or swept into a CA/MFA policy by mistake | Remove it from PIM eligibility, exclude it from the broad CA/MFA policies, and confirm it is permanently active with a sign-in alert |
| Unexpected break-glass sign-in | Possible compromise or an untracked use | Investigate immediately via the sign-in alert; rotate the credential; confirm the second break-glass account is intact |

## F. Activation policy not enforcing
- After editing `Role settings`, confirm you saved and edited the correct role. Policy applies to the
  **next** activation, not existing active sessions. Run `ENTPIMG-Validate.ps1` to read back the
  effective MFA/justification/approval/duration for each role.

## G. Access review not removing stale eligibility
- Confirm the review has `auto-apply results` enabled; without it, decisions are recorded but not
  enforced. Check reviewers are responding, and that the review scope includes the roles you expect.
  Run `ENTPIMG-Report.ps1 -AccessReviews`.

## H. Diagnostics quick reference
```powershell
# US Government cloud (GCC High). For DoD (IL5) use -Environment USGovDoD (dod-graph.microsoft.us).
Connect-MgGraph -Environment USGov -Scopes 'RoleManagement.Read.All','PrivilegedAccess.Read.AzureAD','Directory.Read.All' -NoWelcome
# active (standing) directory-role assignments
Get-MgRoleManagementDirectoryRoleAssignmentScheduleInstance -All
# eligible directory-role assignments
Get-MgRoleManagementDirectoryRoleEligibilityScheduleInstance -All
# activation history (audit)
Get-MgRoleManagementDirectoryRoleAssignmentScheduleRequest -All
# role settings (activation policy) for a role
Get-MgPolicyRoleManagementPolicyAssignment -Filter "scopeId eq '/' and scopeType eq 'DirectoryRole'"
```

## I. When to escalate
If a privileged account activated a role in an unexpected pattern (odd hours, no matching change
ticket, from an unfamiliar location) — or a break-glass account signed in unexpectedly — treat it as a
potential compromise: revoke the account's eligibility and any active assignment, disable the account,
rotate its credentials, and engage your incident-response process.
