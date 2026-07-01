# 6. Troubleshooting Guide — Remote Help

Use **`RHELP-Validation.ps1`** / **`RHELP-Discovery.ps1`** for app state and
**`RHELP-SettingsCheck.ps1`** for tenant settings, **`RHELP-Remediation.ps1`** for safe fixes.

## A. Remote Help won't enable
| Symptom | Cause | Remediation |
|---|---|---|
| "Enable" greyed out / error | No Remote Help license | Confirm Intune Suite / Remote Help add-on is purchased and assigned; `RHELP-SettingsCheck.ps1` |
| Enabled but options missing | Tenant not refreshed | Wait/refresh; re-open Tenant administration → Remote Help |

## B. App not present
| Symptom | Cause | Remediation |
|---|---|---|
| `RHELP-Validation.ps1` says not installed | App not deployed/assigned, or not synced | Confirm the app assignment (Required) to the device's group; `RHELP-Remediation.ps1` forces a sync; check Intune → Apps install status |
| Old app version | Auto-update off | Redeploy the current Remote Help app via Intune |

## C. Can't start a session
| Symptom | Cause | Remediation |
|---|---|---|
| Helper can't "Give help" | Missing RBAC role | Assign Help Desk Operator (or a role with Remote Help permissions) to the helper |
| Connection fails | Network/endpoints blocked | Allow Remote Help service URLs through proxy/firewall; avoid SSL inspection of those endpoints |
| Unenrolled device refused | Policy disallows unenrolled | Expected if "allow unenrolled" = No; change the setting or enroll the device |

## D. Control/compliance issues
- Helper can view but not control → "Allow remote control" is off, or the role/role-scope doesn't grant control. Adjust the Remote Help setting and the RBAC role.
- Compliance shows unknown → the device hasn't reported compliance; ensure it's enrolled and evaluated (Device Compliance solution).

## E. Diagnostics quick reference
```powershell
Get-Process remotehelp -ErrorAction SilentlyContinue        # is the app running?
Test-Path 'C:\Program Files\Remote help\remotehelp.exe'      # is it installed?
dsregcmd /status                                             # Entra state (auth for sessions)
```
Tenant setting + usage: Intune → **Tenant administration → Remote Help** (status + usage report).

## F. When to escalate
If the license is assigned, Remote Help is enabled, the app is installed, RBAC is correct, and
sessions still fail to connect, capture the app version and a session error and open a Microsoft Intune support case.
