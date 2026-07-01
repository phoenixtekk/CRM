# 6. Troubleshooting Guide — Azure Virtual Desktop Remote Access

Use `AVD-Validation.ps1` / `AVD-Discovery.ps1` for host-pool and readiness state, `AVD-Report.ps1` for usage and assignment, and `AVD-Remediation.ps1` (defaults to `-WhatIf`) for safe host fixes.

## A. Workspace or desktop does not appear in the client
| Symptom | Cause | Remediation |
|---|---|---|
| User sees no workspace | User not assigned, or assigned to the wrong application group | Confirm the user is in `AVD – Users – Pilot` and that group is assigned to `AVD – App Group – Desktop` |
| Workspace appears but is empty | Application group not registered to the workspace | Register `AVD – App Group – Desktop` to `AVD – Workspace – Core` (Implementation Step 4) |
| Subscribe URL fails | Wrong feed URL or stale cache | Use the ARM feed `https://client.wvd.microsoft.com/arm/webclient/index.html`; sign out and re-subscribe |

## B. Session host unavailable or won't accept connections
| Symptom | Cause | Remediation |
|---|---|---|
| `avdsh-` host shows Unavailable | Agent/host stopped or deallocated | Run `AVD-Validation.ps1`; start the VM; use `AVD-Remediation.ps1` (drop `-WhatIf` to act) to drain/restart |
| Status `Needs assistance` | AVD agent or boot-loader unhealthy | Restart the host; if persistent, reinstall the AVD agent or rebuild from the image |
| Pooled pool refuses new sessions | Drain mode on, or at max session limit | Turn off drain mode; add session-host capacity |

## C. Sign-in fails after authentication
- For Entra-joined hosts, confirm users hold the **Virtual Machine User Login** role on the host-pool resource group.
- For hybrid hosts, confirm Entra Connect sync is healthy and the host has line-of-sight to a domain controller.
- A blocked sign-in right after MFA usually means a Conditional Access grant the user can't satisfy — review `AVD – Conditional Access – MFA`.

## D. Conditional Access locking everyone out
- Confirm the break-glass account is **excluded** from `AVD – Conditional Access – MFA`.
- Use **Conditional Access → Insights and reporting** (What If) to confirm the policy targets only the intended users and the AVD cloud apps.

## E. FSLogix / profile problems
| Symptom | Cause | Remediation |
|---|---|---|
| Slow logon / temp profile | Share unreachable or permissions wrong | Confirm `AVD – FSLogix Share – Core` is reachable and users have Modify rights; check `VHDLocations` |
| Profile not roaming | FSLogix not enabled on the host | Confirm `Enabled = 1` and `VHDLocations` under `HKLM:\SOFTWARE\FSLogix\Profiles` |
| Container in use / locked | Stale session holding the VHD | Sign the user fully out of all hosts; clear the lock per FSLogix guidance |

## F. macOS client specifics
- If the Mac client cannot add the workspace, confirm the latest **Windows App** / **Microsoft Remote Desktop** from the Mac App Store and use the same ARM feed URL as Windows.
- macOS sign-in uses the same Entra ID account and MFA as Windows; a Mac-only failure with a working Windows client points to an outdated Mac client or a clock/keychain issue on the Mac.

## G. Diagnostics quick reference
```powershell
Get-AzWvdHostPool -ResourceGroupName 'AVD - Resource Group - Core'
Get-AzWvdSessionHost -ResourceGroupName 'AVD - Resource Group - Core' -HostPoolName 'AVD - Host Pool - Pilot'
Get-AzWvdUserSession -ResourceGroupName 'AVD - Resource Group - Core' -HostPoolName 'AVD - Host Pool - Pilot'
Get-ItemProperty 'HKLM:\SOFTWARE\FSLogix\Profiles' -ErrorAction SilentlyContinue
```
The **AVD Insights** workbook (Azure Monitor) gives connection success, latency, and host-health detail.

## H. When to escalate
If the host pool is healthy, the user is assigned and licensed, Conditional Access permits the sign-in, and the client still cannot connect after re-subscribing and a host restart, collect the AVD Insights connection diagnostics and the client error code and open a Microsoft support case.
