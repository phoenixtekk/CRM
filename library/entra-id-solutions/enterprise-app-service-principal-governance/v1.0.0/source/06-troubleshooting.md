# 6. Troubleshooting Guide — Enterprise App & Service Principal Governance

Use `APPGOV-Discovery.ps1` for inventory, `APPGOV-Report.ps1` for over-permission and expiring-secret
status, `APPGOV-Validation.ps1` for policy state, and `APPGOV-Remediation.ps1` (preview first) for
safe fixes.

## A. Discovery or report returns nothing / errors
| Symptom | Cause | Remediation |
|---|---|---|
| `Connect-MgGraph` fails or scopes are missing | SDK not installed, or consent to read scopes not granted | `Install-Module Microsoft.Graph -Scope CurrentUser`; re-run and accept the `Application.Read.All`, `Directory.Read.All`, `Policy.Read.All` scopes |
| Empty results | Signed in to the wrong tenant, or an app-read role missing | Confirm the tenant; ensure the operator holds `Application Administrator` / `Cloud Application Administrator` |
| Owners show as blank | The app genuinely has no owner | Expected — flag it; assign an owner (see B) |

## B. Unowned or unknown apps
- An app with no owner and unclear purpose is the highest-priority review item. Check its
  `passwordCredentials` / `keyCredentials` and recent sign-ins, identify the vendor from the app name
  or publisher, assign an owner, and if it is unused remove it (`Enterprise applications ->` app
  `-> Properties -> Delete`).

## C. A legitimate app broke after remediation
| Symptom | Cause | Remediation |
|---|---|---|
| Integration fails after a grant was revoked | The revoked permission was actually in use | Re-add the permission on the app's `Permissions` blade (or re-grant admin consent); revert is immediate. Always run `APPGOV-Remediation.ps1` in `-WhatIf` first and confirm with the owner |
| App-only job fails at a certain date | The client secret or certificate expired | Rotate the credential in `App registrations -> Certificates & secrets`; track future expiry with `APPGOV-Report.ps1` |

## D. User-consent policy not taking effect
- After changing `User consent settings`, confirm you saved and that you edited the tenant-wide
  setting under `Consent and permissions`, not a single app. Run `APPGOV-Validation.ps1` to read back
  the effective `authorizationPolicy` consent setting; the change is tenant-wide and near-immediate.

## E. Admin-consent requests not reaching reviewers
- Confirm `Admin consent settings -> Users can request admin consent...` is `Yes`, the reviewer group
  `App Governance Consent Reviewers - Tenant - Steady` is set as reviewers, and notifications are
  enabled. Reviewers must hold a role able to grant tenant-wide consent.

## F. Consent-phishing still succeeding
- If a user still consented to a broad app, a high-risk delegated permission is likely classified as
  low-risk. Review `Consent and permissions -> Permission classifications` and remove anything but
  genuinely low-risk scopes (for example keep only `openid`, `profile`, `User.Read`,
  `offline_access`). Revoke the bad grant with `APPGOV-Remediation.ps1`.

## G. Diagnostics quick reference
```powershell
Connect-MgGraph -Scopes 'Application.Read.All','Directory.Read.All','Policy.Read.All' -NoWelcome
# effective user-consent policy
(Invoke-MgGraphRequest -Method GET -Uri '/v1.0/policies/authorizationPolicy').defaultUserRolePermissions
# an app's granted application permissions and delegated grants
Get-MgServicePrincipalAppRoleAssignment -ServicePrincipalId <id>
Get-MgOauth2PermissionGrant -Filter "clientId eq '<id>'"
# an app's credentials
(Get-MgServicePrincipal -ServicePrincipalId <id>).PasswordCredentials
(Get-MgServicePrincipal -ServicePrincipalId <id>).KeyCredentials
```

## H. When to escalate
If an app cannot be attributed to any owner or vendor, holds tenant-wide application permissions, and
shows unexpected sign-in activity, treat it as a potential compromise: revoke its grants and
credentials, disable the service principal (`AccountEnabled` false), and engage your incident-response
process.
