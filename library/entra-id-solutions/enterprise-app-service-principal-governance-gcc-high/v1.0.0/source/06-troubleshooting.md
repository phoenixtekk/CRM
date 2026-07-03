# 6. Troubleshooting Guide — Enterprise App & Service Principal Governance (Government / GCC High)

Use `APPGOVG-Discovery.ps1` for inventory, `APPGOVG-Report.ps1` for over-permission and
expiring-secret status, `APPGOVG-Validation.ps1` for policy state, and `APPGOVG-Remediation.ps1`
(preview first) for safe fixes. All connect to US Gov Microsoft Graph (`-Environment USGov`); all
portal steps are at `https://entra.microsoft.us`.

## A. Wrong cloud / GCC High connection problems (check this first)
| Symptom | Cause | Remediation |
|---|---|---|
| `Connect-MgGraph` signs in but returns no tenant data, or the wrong tenant | Connected to the Commercial Global endpoint instead of USGov | Reconnect with `Connect-MgGraph -Environment USGov`; confirm `(Get-MgContext).Environment` is `USGov` |
| Sign-in fails / "account not recognized" on the portal | Used the Commercial `entra.microsoft.com` with a GCC High account | Use `https://entra.microsoft.us`; GCC High credentials are only valid on `.us` endpoints (tokens are not interchangeable across clouds) |
| Redirect or "wrong authority" error from Graph PowerShell | SDK defaulted to `login.microsoftonline.com` | Ensure `-Environment USGov` (authority `login.microsoftonline.us`, Graph `graph.microsoft.us`); update the Microsoft.Graph module if old |
| You wanted to poke the API in Graph Explorer | Graph Explorer is **not supported** in GCC High | Use the PowerShell scripts (they target `graph.microsoft.us`) — there is no browser Graph Explorer for the sovereign cloud |

## B. Discovery or report returns nothing / errors
| Symptom | Cause | Remediation |
|---|---|---|
| `Connect-MgGraph` fails or scopes are missing | SDK not installed, or consent to read scopes not granted | `Install-Module Microsoft.Graph -Scope CurrentUser`; re-run with `-Environment USGov` and accept the `Application.Read.All`, `Directory.Read.All`, `Policy.Read.All` scopes |
| Empty results | Signed in to the wrong tenant/cloud, or an app-read role missing | Confirm USGov (section A) and the tenant; ensure the operator holds `Application Administrator` / `Cloud Application Administrator` |
| Owners show as blank | The app genuinely has no owner | Expected — flag it; assign an owner (see C) |

## C. Unowned or unknown apps
- An app with no owner and unclear purpose is the highest-priority review item. Check its
  `passwordCredentials` / `keyCredentials` and recent sign-ins, identify the vendor from the app name
  or publisher, assign an owner, and if it is unused remove it (`entra.microsoft.us -> Enterprise
  apps ->` app `-> Properties -> Delete`).

## D. A legitimate app broke after remediation
| Symptom | Cause | Remediation |
|---|---|---|
| Integration fails after a grant was revoked | The revoked permission was actually in use | Re-add the permission on the app's `Permissions` blade (or re-grant admin consent); revert is immediate. Always run `APPGOVG-Remediation.ps1` in `-WhatIf` first and confirm with the owner |
| App-only job fails at a certain date | The client secret or certificate expired | Rotate the credential in `App registrations -> Certificates & secrets`; track future expiry with `APPGOVG-Report.ps1` |

## E. User-consent policy not taking effect
- After changing `User consent settings`, confirm you saved and that you edited the tenant-wide
  setting under `Consent and permissions` on `entra.microsoft.us`, not a single app. Run
  `APPGOVG-Validation.ps1` to read back the effective `authorizationPolicy` consent setting; the
  change is tenant-wide and near-immediate.

## F. Admin-consent requests not reaching reviewers
- Confirm `Admin consent settings -> Users can request admin consent...` is `Yes`, the reviewer group
  `App Governance Consent Reviewers - Tenant - Steady` is set as reviewers, and notifications are
  enabled. Reviewers must hold a role able to grant tenant-wide consent (for example Global
  Administrator) to approve Microsoft Graph application permissions.

## G. Consent-phishing still succeeding
- If a user still consented to a broad app, a high-risk delegated permission is likely classified as
  low-risk. Review `Consent and permissions -> Permission classifications` and remove anything but
  genuinely low-risk scopes (for example keep only `openid`, `profile`, `User.Read`,
  `offline_access`). Revoke the bad grant with `APPGOVG-Remediation.ps1`.

## H. A feature you saw in Commercial is missing in GCC High
- GCC High parity is close but not total. Confirmed gaps that affect this area: **Microsoft Entra
  threat intelligence** (an ID Protection risk detection) is not available, **Graph Explorer** is not
  supported, and Defender for Cloud Apps app-governance features can trail Commercial by up to ~3
  months. Check `gcc-high-parity-notes.md`; for anything marked "verify for GCC High," trust the live
  `entra.microsoft.us` portal over a Commercial screenshot. Do not build a runbook step on a feature
  that is not present.

## I. Diagnostics quick reference (US Gov)
```powershell
Connect-MgGraph -Environment USGov -Scopes 'Application.Read.All','Directory.Read.All','Policy.Read.All' -NoWelcome
(Get-MgContext).Environment   # must be USGov
# effective user-consent policy
(Invoke-MgGraphRequest -Method GET -Uri '/v1.0/policies/authorizationPolicy').defaultUserRolePermissions
# an app's granted application permissions and delegated grants (use your service principal object id)
Get-MgServicePrincipalAppRoleAssignment -ServicePrincipalId your-sp-object-id
Get-MgOauth2PermissionGrant -Filter "clientId eq 'your-sp-object-id'"
# an app's credentials
(Get-MgServicePrincipal -ServicePrincipalId your-sp-object-id).PasswordCredentials
(Get-MgServicePrincipal -ServicePrincipalId your-sp-object-id).KeyCredentials
```

## J. When to escalate
If an app cannot be attributed to any owner or vendor, holds tenant-wide application permissions, and
shows unexpected sign-in activity, treat it as a potential compromise: revoke its grants and
credentials, disable the service principal (`AccountEnabled` false), and engage your incident-response
process. On a CUI/ITAR tenant, follow your spill/incident procedure — an over-permissioned compromised
app may constitute a controlled-data exposure.
