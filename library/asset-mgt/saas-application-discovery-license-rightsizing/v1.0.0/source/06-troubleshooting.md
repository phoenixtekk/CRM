# 6. Troubleshooting Guide — SaaS Application Discovery & License Right-Sizing

Use `SAASLIC-Validation.ps1` for connectivity/scopes, `SAASLIC-Discovery.ps1` for the inventory and
sign-in activity, `SAASLIC-Report.ps1` for seat utilization, and `SAASLIC-Remediation.ps1` (default
`-WhatIf`) to flag reclaim candidates.

## A. Discovery returns no apps or no sign-ins
| Symptom | Cause | Remediation |
|---|---|---|
| Empty app list | Read access missing | Confirm Reports Reader + Application Reader (or Global Reader); re-run `SAASLIC-Validation.ps1` |
| Apps listed, zero sign-ins | Audit/sign-in scope not consented, or no recent activity | Re-consent `AuditLog.Read.All`; widen the window; confirm the app is SSO-integrated |
| Known app is missing | App bought outside SSO (not federated) | Add it to `App Inventory – SaaS – Discovered` manually from expense/procurement data |

## B. Connect-MgGraph or scope errors
- `SAASLIC-Validation.ps1` reports a missing scope: reconnect with
  `Connect-MgGraph -Scopes 'Application.Read.All','AuditLog.Read.All','Directory.Read.All'` and consent.
- Module not found: `Install-Module Microsoft.Graph -Scope CurrentUser -Force`.

## C. Usage window too short
| Symptom | Cause | Remediation |
|---|---|---|
| Few events / window incomplete | Sign-in log retention shorter than the dormancy window | Use a shorter window, or export sign-in logs to a Log Analytics workspace and query there (Requirement 2.4) |

## D. Suspected wrongful reclaim
- A reclaimed user complains: confirm the user's sign-in history in `SAASLIC-Report.ps1` for the window;
  if they did sign in, the dormancy threshold was too tight — lengthen it and restore the seat in the
  app's console.

## E. Report seat counts look wrong
- Entitled seats come from your spend baseline (`Owner Map – SaaS – Mapped`), not from Entra ID — verify
  the entitled-seat figure against the vendor invoice/console. Sign-in-derived active users only count
  authentications, not feature use; confirm downgrade candidates in the app's admin console.

## F. Remediation made a change you did not expect
- `SAASLIC-Remediation.ps1` is read-only/flag-only by default (`-WhatIf`); it writes a candidate file
  but does not touch vendor seats. Actual seat removal happens in each SaaS app's own console — review
  the candidate file with the owner before acting there.

## G. When to escalate
If discovery, validation, and reporting all run clean, the scopes are consented, and the inventory still
omits an app you can see in the portal, capture the `SAASLIC-Discovery.ps1` output and the app's
properties from Enterprise applications and open a Microsoft support case.
