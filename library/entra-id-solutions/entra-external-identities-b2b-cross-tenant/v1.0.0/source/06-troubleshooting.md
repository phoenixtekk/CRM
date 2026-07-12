# 6. Troubleshooting Guide — Entra External Identities (B2B) & Cross-Tenant Access

Use `ENTB2B-Discovery.ps1` / `ENTB2B-Validate.ps1` for current state, `ENTB2B-Report.ps1` for the
guest lifecycle, and the two change scripts (`ENTB2B-Set-CrossTenantAccess.ps1`,
`ENTB2B-CleanupStaleGuests.ps1`, default `-WhatIf`) for safe fixes. Do portal work at
`https://entra.microsoft.com`.

## A. Guest invitation / onboarding problems
| Symptom | Cause | Remediation |
|---|---|---|
| Cannot invite a guest ("not allowed") | Guest invite settings restrict who can invite, or the domain is blocked | `External Identities -> External collaboration settings`; confirm invite permissions and that the partner domain is allowed (not on the deny list) |
| Partner user cannot request the access package | Requestor not scoped, or connected organization missing | Confirm `Partner Access – Project X – Pilot` request policy targets `Connected Org – Contoso – Pilot`; add the partner to the connected organization |
| Guest created but has no access | Package resource roles empty, or approval pending | Confirm the package grants a resource role; confirm an approver in `Partner Approvers – B2B – Pilot` approved the request |
| Self-service sign-up not offered | User flow not created/attached, or feature is preview/limited | Create the user flow under `External Identities -> User flows`; *verify current availability* of the identity providers you selected |

## B. Cross-tenant access / trust problems
| Symptom | Cause | Remediation |
|---|---|---|
| Guest is re-prompted to register MFA in your tenant | Partner's MFA claims are not trusted | In the partner's `Organizational settings -> Trust settings`, enable `Trust multi-factor authentication from Microsoft Entra tenants` (only for the vetted partner) |
| Teams shared channel with partner does not work | B2B direct connect blocked | Enable B2B direct connect **inbound/outbound** for that partner's organizational setting only (not the default) |
| A new/unknown partner has more access than expected | Default policy too permissive | Tighten `Cross-tenant access settings -> Default settings`; run `ENTB2B-Validate.ps1` to confirm defaults are conservative |
| `ENTB2B-Set-CrossTenantAccess.ps1` reports no change | Ran in default `-WhatIf` preview | Review the preview; re-run with `-WhatIf:$false` once correct |

## C. Break-glass and lockout risk
- Confirm the two break-glass accounts are excluded from `Require MFA – Guest Users – Pilot` and from broad Conditional Access; run `ENTB2B-Validate.ps1`.
- Break-glass accounts are internal cloud-only administrators — never scope the guest policy to include them, and never include them in stale-guest cleanup. If a guest/CA change causes broad impact, disable the new policy and sign in with a break-glass account to correct it.

## D. Conditional Access (guest policy) issues
| Symptom | Cause | Remediation |
|---|---|---|
| Guest policy blocks internal users | Policy scoped too broadly (not `Guest or external users`) | Re-scope Users to `Guest or external users` only; keep it in report-only until the sign-in logs show only external users affected |
| Policy has no effect | Still in report-only | Set `Enable policy = On` after confirming impact in `Insights and reporting` |
| Trusted-partner guest still challenged for MFA | Trust settings not enabled for that partner, or claim not satisfied | Enable trust for the partner organization; confirm the partner actually asserts the MFA claim |
| Legitimate external sign-in blocked | Grant control too strict for the scenario | Adjust the grant (for example allow trusted-partner MFA claim); re-test in report-only |

## E. Access review / lifecycle issues
| Symptom | Cause | Remediation |
|---|---|---|
| Review removed guests unexpectedly | `If reviewers don't respond` set to Remove with no decision | Set it to `Take recommendations` for early cycles; re-grant via the access package; re-run the review |
| Review has no reviewer | Sponsor/owner not set, or manager attribute empty | Assign `Partner Approvers – B2B – Pilot` as sponsor or a named reviewer; recreate the review |
| Stale guests not being removed | No review/expiry on the guests, or cleanup only run in preview | Add a recurring guest access review and package expiry; run `ENTB2B-CleanupStaleGuests.ps1` and, after reviewing the preview, re-run with `-WhatIf:$false` |
| Guests never expire | Access package has no expiry/lifecycle | Set a package expiry or periodic review in the package lifecycle settings |

## F. Licensing / feature not visible — verify
- If `Identity governance` (access reviews / entitlement management) is not visible, confirm **Entra ID P2 / Entra ID Governance** is assigned; if cross-tenant trust settings or Conditional Access are unavailable, confirm **Entra ID P1**. Run `ENTB2B-Discovery.ps1`. *Verify current licensing in your tenant.*
- If a capability appears in Microsoft docs but not in your tenant, it may be **preview** or vary by cloud (for example some self-service identity providers or cross-tenant sync options) — *verify current availability in your tenant* before depending on it.

## G. Diagnostics quick reference
```powershell
Connect-MgGraph -Scopes 'Policy.Read.All','CrossTenantInformation.ReadBasic.All','User.Read.All','EntitlementManagement.Read.All','AccessReview.Read.All'
# Default + partner (organizational) cross-tenant access settings
Invoke-MgGraphRequest -Method GET -Uri '/v1.0/policies/crossTenantAccessPolicy/default'
Invoke-MgGraphRequest -Method GET -Uri '/v1.0/policies/crossTenantAccessPolicy/partners'
# Guest users
Invoke-MgGraphRequest -Method GET -Uri "/v1.0/users?`$filter=userType eq 'Guest'&`$select=displayName,userPrincipalName,signInActivity,createdDateTime"
# Guest-scoped Conditional Access policies
Invoke-MgGraphRequest -Method GET -Uri '/v1.0/identity/conditionalAccess/policies'
```

## H. When to escalate
If cross-tenant settings are correct, the partner is trusted, the guest policy is scoped to external
users and excludes break-glass, connectivity is confirmed (Test 0), and onboarding or MFA still fails,
capture `ENTB2B-Report.ps1` output and the guest's sign-in log entry and open a Microsoft support case,
confirming whether the partner tenant's outbound cross-tenant settings permit the collaboration.
