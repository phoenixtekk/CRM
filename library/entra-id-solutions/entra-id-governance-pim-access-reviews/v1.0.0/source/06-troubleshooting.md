# 6. Troubleshooting Guide — Entra ID Governance (PIM, Access Reviews & Entitlement Management)

Use `IGA-Validation.ps1` / `IGA-Discovery.ps1` for current governance state and `IGA-Report.ps1`
for standing-privilege and coverage, `IGA-Remediation.ps1` for safe fixes.

## A. PIM activation problems
| Symptom | Cause | Remediation |
|---|---|---|
| Admin cannot activate a role | No eligible assignment, or activation blocked by policy | Confirm an Eligible assignment exists in PIM; check activation policy (MFA/approval); run `IGA-Validation.ps1` |
| Activation stuck waiting for approval | No available approver, or approver group empty | Confirm the approver group has 2+ members; add coverage with `IGA-Set-ScopeTargeting.ps1` |
| Activation fails MFA | Admin has no strong method registered | Register a multi-factor method for the admin, then retry activation |

## B. Break-glass and lockout risk
- Confirm the two break-glass accounts hold permanent active `Global Administrator` and are excluded from PIM activation and from broad Conditional Access/MFA policies; run `IGA-Discovery.ps1`.
- If PIM/approval is misconfigured tenant-wide, sign in with a break-glass account to restore access, then correct the policy. Never onboard break-glass accounts to PIM.

## C. Access review issues
| Symptom | Cause | Remediation |
|---|---|---|
| Review removed access unexpectedly | "If reviewers do not respond" set to Remove access and no decision recorded | Set the no-response action to Take recommendations or No change; re-grant via PIM/access package; re-run the review |
| Review has no reviewer | Manager attribute empty, or owner not set | Populate the `Manager` attribute or assign a named reviewer; recreate the review |
| Decisions not applied | Auto apply results disabled | Enable Auto apply results, or apply the review manually |

## D. Entitlement-management / access-package issues
| Symptom | Cause | Remediation |
|---|---|---|
| User cannot request a package | Requestor not in the request policy scope | Add the user to the scope group (for example the pilot scope) or widen the request policy |
| Request not approved | Approver group empty or approver unavailable | Confirm approver coverage; add members with `IGA-Set-ScopeTargeting.ps1` |
| Access did not expire | No expiry / no review on the package lifecycle | Set an access-package expiry or a periodic review in the package lifecycle settings |

## E. Licensing / feature not visible
- If `Identity governance`, PIM, or access reviews are not visible, confirm Entra ID Governance / P2 licensing is assigned; run `IGA-Discovery.ps1`. Assign P2/Governance to administrators, reviewers, and access-package users.

## F. Diagnostics quick reference
```powershell
Connect-MgGraph -Scopes 'RoleManagement.Read.Directory','AccessReview.Read.All','EntitlementManagement.Read.All'
# Eligible vs active Entra role assignments (PIM)
Get-MgRoleManagementDirectoryRoleEligibilitySchedule -All
Get-MgRoleManagementDirectoryRoleAssignmentSchedule -All
# Access reviews and access packages
Get-MgIdentityGovernanceAccessReviewDefinition -All
Get-MgEntitlementManagementAccessPackage -All
```

## G. When to escalate
If roles are correctly eligible, the approver group has coverage, MFA is registered, and activation
or an access review still fails, capture the output of `IGA-Report.ps1` and the PIM audit log for the
affected role and open a Microsoft support case.
