# 6. Troubleshooting Guide — Entra ID Governance (PIM, Access Reviews & Entitlement Management) — Government (GCC High)

Use `IGAG-Validation.ps1` / `IGAG-Discovery.ps1` for current governance state and `IGAG-Report.ps1`
for standing-privilege and coverage, `IGAG-Remediation.ps1` for safe fixes. All scripts connect to
US Gov Graph with **`-Environment USGov`** (use `USGovDoD` on the DoD cloud); do portal work at
**`https://entra.microsoft.us`**.

## A. Sovereign endpoint / connection problems (GCC High-specific — check first)
| Symptom | Cause | Remediation |
|---|---|---|
| `Connect-MgGraph` redirects or throws a "wrong environment"/AADSTS error | `-Environment USGov` was omitted, so the SDK targeted the Commercial endpoint | Reconnect with `-Environment USGov` (or `USGovDoD` for DoD); set `$PSDefaultParameterValues['Connect-MgGraph:Environment']='USGov'` in the profile |
| GCC High account not recognized at the portal | Signed in at a Commercial `*.com` portal | Use `entra.microsoft.us` / `portal.azure.us`; sign-in is `login.microsoftonline.us` |
| Graph Explorer will not open the tenant | Graph Explorer is not supported for `graph.microsoft.us` / `dod-graph.microsoft.us` | Use PowerShell (`-Environment USGov`) instead of Graph Explorer |
| Scripts return empty/forbidden results | Consent granted in the wrong cloud, or missing scopes | Re-consent in the GCC High tenant; confirm the read-only scopes each script requests |

## B. PIM activation problems
| Symptom | Cause | Remediation |
|---|---|---|
| Admin cannot activate a role | No eligible assignment, or activation blocked by policy | Confirm an Eligible assignment exists in PIM; check activation policy (MFA/approval); run `IGAG-Validation.ps1` |
| Activation stuck waiting for approval | No available approver, or approver group empty | Confirm the approver group has 2+ members; add coverage with `IGAG-Set-ScopeTargeting.ps1` |
| Activation fails MFA | Admin has no strong method registered | Register a multi-factor method for the admin, then retry activation |

## C. Break-glass and lockout risk
- Confirm the two break-glass accounts hold permanent active `Global Administrator` and are excluded from PIM activation and from broad Conditional Access/MFA policies; run `IGAG-Discovery.ps1`.
- If PIM/approval is misconfigured tenant-wide, sign in with a break-glass account (at `login.microsoftonline.us`) to restore access, then correct the policy. Never onboard break-glass accounts to PIM.

## D. Access review issues
| Symptom | Cause | Remediation |
|---|---|---|
| Review removed access unexpectedly | "If reviewers do not respond" set to Remove access and no decision recorded | Set the no-response action to Take recommendations or No change; re-grant via PIM/access package; re-run the review |
| Review has no reviewer | Manager attribute empty, or owner not set | Populate the `Manager` attribute or assign a named reviewer; recreate the review |
| Decisions not applied | Auto apply results disabled | Enable Auto apply results, or apply the review manually |
| ML review recommendations not offered | ML decision helpers may lag in GCC High (Preview in Commercial) | Verify for GCC High; use owner/manager reviewers as the dependable default |

## E. Entitlement-management / access-package issues
| Symptom | Cause | Remediation |
|---|---|---|
| User cannot request a package | Requestor not in the request policy scope | Add the user to the scope group (for example the pilot scope) or widen the request policy |
| Request not approved | Approver group empty or approver unavailable | Confirm approver coverage; add members with `IGAG-Set-ScopeTargeting.ps1` |
| Access did not expire | No expiry / no review on the package lifecycle | Set an access-package expiry or a periodic review in the package lifecycle settings |
| External / cross-cloud requestor cannot be added | Connected-organization / cross-cloud collaboration differs across clouds and parts are preview in GCC High | Verify for GCC High; keep the pilot to in-tenant requestors; add cross-cloud external access only after confirming behavior |

## F. Licensing / feature not visible
- If `Identity governance`, PIM, or access reviews are not visible, confirm the **Government** Entra ID Governance / P2 SKUs are assigned; run `IGAG-Discovery.ps1`. Assign **Microsoft Entra ID P2** and, where used, **Microsoft Entra ID Governance for Government** or the **Add-on for Entra ID P2 for Government** to administrators, reviewers, and access-package users.
- If a capability is present in Commercial docs but missing in your GCC High tenant, check the GCC High parity notes — it may be Partial, unavailable, or preview-only in the sovereign cloud (verify for GCC High).

## G. Diagnostics quick reference
```powershell
# GCC High: always specify the US Gov environment (USGovDoD for DoD)
Connect-MgGraph -Environment USGov -Scopes 'RoleManagement.Read.Directory','AccessReview.Read.All','EntitlementManagement.Read.All'
# Eligible vs active Entra role assignments (PIM)
Invoke-MgGraphRequest -Method GET -Uri '/v1.0/roleManagement/directory/roleEligibilityScheduleInstances'
Invoke-MgGraphRequest -Method GET -Uri '/v1.0/roleManagement/directory/roleAssignmentScheduleInstances'
# Access reviews and access packages
Invoke-MgGraphRequest -Method GET -Uri '/v1.0/identityGovernance/accessReviews/definitions'
Invoke-MgGraphRequest -Method GET -Uri '/v1.0/identityGovernance/entitlementManagement/accessPackages'
```

## H. When to escalate
If roles are correctly eligible, the approver group has coverage, MFA is registered, connectivity is
confirmed on `graph.microsoft.us` (Test 0), and activation or an access review still fails, capture the
output of `IGAG-Report.ps1` and the PIM audit log for the affected role and open a Microsoft support
case for the GCC High tenant.
