# 6. Troubleshooting Guide — Entra Identity Protection & Advanced Conditional Access

Use `ENTIDP-Validate.ps1` / `ENTIDP-Discovery.ps1` for current configuration state,
`ENTIDP-Report.ps1` for the risk-and-coverage picture, and `ENTIDP-Set-PolicyState.ps1` (default
`-WhatIf`) to flip a policy back to report-only fast.

## A. Risk signal / Identity Protection not showing
| Symptom | Cause | Remediation |
|---|---|---|
| Risky users/sign-ins reports empty | Entra ID P2 not assigned to in-scope users | Assign P2 to in-scope users; wait for signal; run `ENTIDP-Report.ps1`. *Verify P2 availability.* |
| Risk condition greyed out in a CA policy | No P2, or the policy uses an unsupported combination | Confirm P2; ensure the policy targets users/apps that support the risk condition |
| No detections ever appear | Traffic genuinely low-risk, or legacy auth bypassing evaluation | Confirm legacy auth is blocked (`ENTIDP-Report.ps1`); risk detections are event-driven, not guaranteed |

## B. Users unexpectedly blocked or challenged
| Symptom | Cause | Remediation |
|---|---|---|
| Pilot users blocked after an enforcement flip | Policy moved to On before report-only was clean, or a required method not registered | Set the policy back to report-only (`ENTIDP-Set-PolicyState.ps1`); confirm the required method is registered (`ENTIDP-Report.ps1`); re-read report-only before re-enforcing |
| Risk-based MFA loops | User has no strong method, or user-risk password change not completed | Register MFA; complete the secure password change to clear user risk |
| Step-up prompts on every sign-in | Authentication context mapped too broadly, or context applied at app level unintentionally | Narrow the context to the specific sensitive app/action; confirm `CA – Step-Up Sensitive Apps – Pilot` targets the context, not all apps |

## C. Break-glass / lockout risk
- Confirm `CA Break-Glass Exclusion` (both cloud-only break-glass accounts) is on the Exclude tab of all four policies; run `ENTIDP-Validate.ps1`.
- If a risk or enforcement change locks out administrators, sign in with a break-glass account, set the offending policy to report-only, and investigate. Never add break-glass accounts to a risk or enforcement policy.

## D. Token protection issues
| Symptom | Cause | Remediation |
|---|---|---|
| Token protection "would block" supported users unexpectedly | Policy scope includes unsupported clients/platforms | Restrict the policy to the supported Windows scenario/clients; *verify current supported clients* |
| Token protection never applies | Targeting an unsupported app, or client not in the supported scenario | Target a supported workload (for example Exchange/SharePoint); confirm client support with `ENTIDP-Validate.ps1` |
| Preview-related inconsistency | Feature or scenario still in preview | Verify current availability in your tenant; keep the policy report-only until preview status is confirmed |

## E. CAE not revoking as expected
- CAE revocation is honoured by supported resource providers (Exchange Online, SharePoint Online, Graph) and takes minutes, not seconds. If a session persists, confirm the app/client is CAE-capable and that CAE is not disabled by a "customize continuous access evaluation" session control.
- Legacy-auth or non-CAE clients do not honour CAE — confirm legacy auth is blocked.

## F. Authentication strength problems
| Symptom | Cause | Remediation |
|---|---|---|
| Strength policy blocks users who "have MFA" | Strength requires a specific (phishing-resistant) method they have not registered | Register FIDO2/passkey/WHfB for those users, or relax the strength to standard MFA for now |
| Custom strength not selectable | Method not enabled tenant-wide in Authentication methods | Enable the method in `Authentication methods -> Policies` first |

## G. Diagnostics quick reference
```powershell
Connect-MgGraph -Scopes 'Policy.Read.All','IdentityRiskyUser.Read.All','IdentityRiskEvent.Read.All'
# Conditional Access policies and their state
Get-MgIdentityConditionalAccessPolicy -All | Select-Object DisplayName, State
# Risky users / risk detections
Invoke-MgGraphRequest -Method GET -Uri '/v1.0/identityProtection/riskyUsers?$top=20'
Invoke-MgGraphRequest -Method GET -Uri '/v1.0/identityProtection/riskDetections?$top=20'
# Authentication strengths and named locations
Invoke-MgGraphRequest -Method GET -Uri '/v1.0/policies/authenticationStrengthPolicies'
Invoke-MgGraphRequest -Method GET -Uri '/v1.0/identity/conditionalAccess/namedLocations'
```

## H. When to escalate
If P2 is assigned, break-glass is excluded, required methods are registered, and a policy still
misbehaves after a clean report-only read, capture `ENTIDP-Report.ps1` output and the affected
sign-in's report-only detail and open a Microsoft support case.
