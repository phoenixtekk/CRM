# 6. Troubleshooting Guide — WSUS to Windows Update for Business Migration

Use `WSUSM-Validation.ps1` / `WSUSM-Discovery.ps1` for device state, `WSUSM-Report.ps1` for fleet
status, and `WSUSM-Remediation.ps1` for safe fixes (default `-WhatIf`).

## A. Device still scans WSUS after cutover
| Symptom | Cause | Remediation |
|---|---|---|
| Device ignores the Intune ring | `WUServer`/`UseWUServer` still set | Run `WSUSM-Discovery.ps1` (flags them); remove the **Specify intranet Microsoft update service location** GPO; `gpupdate /force`; clear residual values with `WSUSM-Remediation.ps1` |
| "Some settings managed" but no online updates | `DoNotConnectToWindowsUpdateInternetLocations` enabled | Remove the **Do not connect to any Windows Update Internet locations** GPO; clear the value with `WSUSM-Remediation.ps1`; re-scan |
| GPO removed but pointer persists | Cached registry/Group Policy not refreshed | `gpupdate /force`, then `WSUSM-Remediation.ps1`; confirm with `WSUSM-Validation.ps1` |

## B. Updates not installing / stuck
| Symptom | Cause | Remediation |
|---|---|---|
| Device never updates | Not synced, deferral too long, or paused | Sync policy; run a USO scan (`usoclient StartScan`); check the ring deferral/deadline; ensure not paused |
| Ring shows Error | Device not enrolled/checked in | Confirm enrollment and group membership; sync |

## C. Surprise / unwanted restarts
- Tune **active hours** and the **auto-restart / deadline grace** in the ring; communicate the
  deadline to users during the cutover.
- For sensitive groups, lengthen the grace period or allow user-scheduled restart.

## D. Feature update issues
| Symptom | Cause | Remediation |
|---|---|---|
| Device jumped to an unexpected version | No feature update policy pinning the version | Create/assign `WUfB – Feature Update – Target` with the target version |
| Feature update won't offer | Safeguard hold, or device below target | Check compatibility/safeguard holds; confirm the target version and rollout setting |

## E. Bandwidth / Delivery Optimization
- WAN saturated on the first cloud feature-update day (WSUS no longer caches content) → set Delivery
  Optimization download mode to LAN/peer and cap foreground/background bandwidth; stage the rollout
  gradually.

## F. Diagnostics quick reference
```powershell
Get-ComputerInfo | Select WindowsProductName, OsBuildNumber, WindowsVersion
Get-ItemProperty 'HKLM:\SOFTWARE\Policies\Microsoft\Windows\WindowsUpdate' -EA SilentlyContinue      # WUServer / DoNotConnect...
Get-ItemProperty 'HKLM:\SOFTWARE\Policies\Microsoft\Windows\WindowsUpdate\AU' -EA SilentlyContinue   # UseWUServer
usoclient StartScan                # trigger an update scan
Get-DeliveryOptimizationStatus     # DO peer/LAN usage
```
Update logs: `Get-WindowsUpdateLog` (generates a merged log on the desktop).

## G. When to escalate
If the WSUS pointer is removed, the ring shows Succeeded, the device is synced and not paused, and
updates still won't install from Microsoft after a USO scan, collect `Get-WindowsUpdateLog` output
and open a Microsoft support case.
