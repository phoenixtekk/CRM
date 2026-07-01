# 6. Troubleshooting Guide — Windows Updates for Business

Use **`WUFB-Validation.ps1`** / **`WUFB-Discovery.ps1`** for device state and
**`WUFB-ComplianceReport.ps1`** for fleet status, **`WUFB-Remediation.ps1`** for safe fixes.

## A. Updates not installing / stuck
| Symptom | Cause | Remediation |
|---|---|---|
| Device never updates | Not synced, deferral too long, or paused | Run `WUFB-Remediation.ps1` (sync + USO scan); check deferral/deadline; ensure not paused |
| "Some settings managed" but no updates | Conflicting WSUS/GPO authority | Run `WUFB-Discovery.ps1` (flags `WUServer`); remove WSUS/GPO; for co-management set update workload to Intune |
| Ring shows Error | Device not enrolled/checked in | Confirm enrollment and group membership; sync |

## B. Surprise / unwanted restarts
- Tune **active hours** and the **auto-restart / deadline grace** in the ring; communicate the deadline to users.
- For sensitive groups, lengthen the grace period or allow user-scheduled restart.

## C. Feature update issues
| Symptom | Cause | Remediation |
|---|---|---|
| Device jumped to an unexpected version | No feature update profile pinning the version | Create/assign a Feature update profile with the target version |
| Feature update won't offer | Safeguard hold, or device below target | Check compatibility/safeguard holds; confirm the target version and rollout setting |

## D. Expedite not working
- Expedite requires the Windows Update service healthy and a supported build; confirm the device isn't paused and the Update Health Tools are present (they install automatically on supported builds).

## E. Bandwidth / Delivery Optimization
- WAN saturated on feature-update day → set Delivery Optimization download mode to LAN/peer and cap foreground/background bandwidth; stage feature rollout gradually.

## F. Diagnostics quick reference
```powershell
Get-ComputerInfo | Select WindowsProductName, OsBuildNumber, WindowsVersion
Get-ItemProperty 'HKLM:\SOFTWARE\Policies\Microsoft\Windows\WindowsUpdate' -EA SilentlyContinue   # deferral/WSUS settings
usoclient StartScan        # trigger an update scan
Get-DeliveryOptimizationStatus    # DO peer/LAN usage
```
Update logs: `Get-WindowsUpdateLog` (generates a merged log on the desktop).

## G. When to escalate
If the ring shows Succeeded, no WSUS/GPO conflict exists, the device is synced and not paused, and
updates still won't install after a USO scan, collect `Get-WindowsUpdateLog` output and open a Microsoft support case.
