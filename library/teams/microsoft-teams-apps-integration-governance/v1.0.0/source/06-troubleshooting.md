# 6. Troubleshooting Guide — Microsoft Teams Apps & Integration Governance

Use `TEAMSAPPS-Discovery.ps1` for posture, `TEAMSAPPS-ConsentReport.ps1` for consented permissions,
`TEAMSAPPS-Validation.ps1` for assignment state, and `TEAMSAPPS-Configure.ps1` /
`TEAMSAPPS-Set-ScopeTargeting.ps1` (`-WhatIf` first) for safe changes.

## A. Connection / permission errors
| Symptom | Cause | Remediation |
|---|---|---|
| `Connect-MicrosoftTeams` fails | MicrosoftTeams module missing/outdated, or MFA not completed | `Install-Module MicrosoftTeams -Scope CurrentUser`; complete the modern-auth/MFA prompt; confirm the Teams Administrator role (Requirement 2.1) |
| `Connect-MgGraph` scope denied | Read scopes not consented, or admin consent required | Re-run and accept the prompt; have an admin grant `AppCatalog.Read.All`, `Directory.Read.All`, `Application.Read.All`, `DelegatedPermissionGrant.Read.All`, `AppRoleAssignment.Read.All` once in Entra (Requirement 2.3) |
| `Grant-CsTeamsAppPermissionPolicy` access denied | Insufficient role for assignment | Confirm Teams Administrator; retry `TEAMSAPPS-Set-ScopeTargeting.ps1 -Commit` |

## B. A policy change "didn't take effect" for users
- Policy assignment and Teams client propagation take time. Confirm the assignment with `TEAMSAPPS-Validation.ps1`; then allow for propagation (assignment can take up to a few hours to surface in the client — **verify current timing in your tenant**) and have the user sign out/in of Teams.
- Confirm you assigned the **named** policy, not left the user on the **Global (Org-wide default)**. `Get-CsUserPolicyAssignment -Identity <upn> -PolicyType TeamsAppPermissionPolicy` shows the effective policy.

## C. A blocked app is still available (or a vetted app is missing)
| Symptom | Cause | Remediation |
|---|---|---|
| Blocked app still installable | App is Allowed org-wide on the Manage apps page, overriding intent, or the user is on a permissive policy | Block the app on `Manage apps`; confirm the user's permission policy uses `AllowedAppList` for that class, not `AllApps` |
| Vetted app not available | App not on the allowed list in the permission policy, or blocked org-wide | Add the app ID to `App Allow List – Vetted – Prod` and re-run `TEAMSAPPS-Configure.ps1 -Commit`; ensure it is Allowed on the Manage apps page |

## D. Org-wide toggle can't be set from PowerShell
- The org-wide app settings (third-party on/off, custom apps on/off) and individual-app allow/block on the Manage apps page are **admin-center-driven**; PowerShell/Graph parity is partial and version-dependent. Set these in the Teams admin center (`Teams apps → Manage apps → Org-wide app settings`) and **verify any cmdlet/endpoint in your tenant** before scripting — do not assume a cmdlet exists.

## E. Custom/LOB app can't be uploaded (or can, unexpectedly)
- Custom-app upload is gated by **both** the org-wide custom-apps setting **and** the setup policy's sideloading allowance (`AllowSideLoading`). If upload is blocked when it should be allowed, enable custom apps org-wide and set `AllowSideLoading=$true` on the user's setup policy; if upload is possible when it should be blocked, turn the org-wide custom-apps setting off and set `AllowSideLoading=$false` (Requirement 2.7 / Implementation Step 4).

## F. Consent report shows a high-risk permission you didn't expect
- An app holds a high-risk delegated or application permission. This is a **security/compliance decision, not an automatic action** — hand `Consent Review – Teams Apps – Report` to your stakeholders. If they decide to revoke, do it in Entra (`Enterprise applications → the app → Permissions`), not by editing Teams policy. Blocking the app in Teams stops its use but does not by itself revoke a standing Graph consent grant.

## G. `New-CsTeamsAppPermissionPolicyApp` / policy cmdlet not found
- The app-object helper cmdlets and the exact permission-policy parameter set are **module-version-dependent**, and Microsoft is converging permission policies with the Manage apps availability model. Update the module (`Update-Module MicrosoftTeams`), run `Get-Command *CsTeamsAppPermissionPolicy*` to confirm the available cmdlets, and **verify the current parameter names in your tenant** — do not assume a parameter that your module version doesn't expose.

## H. Diagnostics quick reference
```powershell
Connect-MicrosoftTeams
Get-CsTeamsAppPermissionPolicy | Select Identity, GlobalCatalogAppsType, PrivateCatalogAppsType
Get-CsTeamsAppSetupPolicy | Select Identity, AllowUserPinning, AllowSideLoading
Get-CsUserPolicyAssignment -Identity user@contoso.com -PolicyType TeamsAppPermissionPolicy
Connect-MgGraph -Scopes 'AppCatalog.Read.All' -NoWelcome
(Invoke-MgGraphRequest -Method GET -Uri "/v1.0/appCatalogs/teamsApps?`$top=5").value | Select id, distributionMethod
```

## I. When to escalate
If the role is Teams Administrator, Graph scopes are consented, and `TEAMSAPPS-Validation.ps1` confirms
the correct policy is assigned but the client behavior is still wrong after propagation, capture the
`Get-CsUserPolicyAssignment` output, the app's ID and distribution method, and the Manage-apps allow/block
state, and open a Microsoft support case. For a consented-permission concern, route through your
security/app-governance stakeholders before revoking anything.
