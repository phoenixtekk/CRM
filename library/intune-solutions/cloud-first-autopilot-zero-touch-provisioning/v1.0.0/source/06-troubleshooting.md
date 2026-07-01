# 6. Troubleshooting Guide — Cloud-First Autopilot Zero-Touch Provisioning

Use `CFAP-Discovery.ps1` / `CFAP-Validation.ps1` for device state, `CFAP-Report.ps1` for fleet status,
and `CFAP-Remediation.ps1` (default `-WhatIf`) for safe fixes.

## A. Device does not start Autopilot at OOBE
| Symptom | Cause | Remediation |
|---|---|---|
| OOBE shows a normal consumer setup, no branding | Device not registered, or profile not yet assigned | Confirm under Devices → Enrollment → Windows → Windows Autopilot → Devices; Sync; wait for profile status Assigned; re-OOBE |
| Device never reaches the cloud | No internet at OOBE | Provide Wi-Fi/DHCP and allow the Autopilot/Intune/Entra endpoints; retry |
| Registered but no profile applies | Not in the dynamic group, or rule wrong | Run `CFAP-Set-AutopilotTargeting.ps1`; verify the `[ZTDId]` membership rule and group assignment |

## B. Enrollment Status Page errors or hangs
| Symptom | Cause | Remediation |
|---|---|---|
| ESP stuck on app install | A required app is large or failing | Trim the ESP blocking set; check the app's install status; run `CFAP-Remediation.ps1` to re-trigger install |
| ESP times out | Timeout too short or app dependency missing | Raise the ESP timeout; confirm app dependencies/supersedence; re-provision |
| ESP shows error, device unusable | Required app/profile failed | Allow reset on error in the ESP; fix the failing app; reset and re-provision |

## C. Wrong join type
| Symptom | Cause | Remediation |
|---|---|---|
| Device is hybrid/domain joined unexpectedly | A hybrid profile or GPO matched the device | Confirm the device is in the cloud-first group only; ensure no hybrid profile/Connector targets it; reset and re-provision with `Autopilot Profile – Entra Join – Provisioning` |
| `dsregcmd /status` shows `DomainJoined: YES` for a default device | Exception profile mis-scoped | Re-scope the hybrid exception to its own group; keep the default profile Entra-join only |

## D. Apps or baseline missing after provisioning
- Confirm the apps and `Security Baseline – Cloud-First – Provisioning` are assigned to
  `Autopilot Devices – All Cloud-First – Provisioning` (device-targeted, Required).
- Sync the device (Settings → Accounts → Access work or school → Info → Sync) or run
  `CFAP-Remediation.ps1` to force a sync and re-evaluation.

## E. On-prem resource unreachable from an Entra-joined device
- This is expected for pure cloud join. Prefer Microsoft Entra Kerberos / Cloud Kerberos Trust for
  SMB/Kerberos resource access before considering domain join.
- Only if a named dependency cannot be met that way, follow the documented exception path
  (Implementation Step 11) using a separate hybrid profile and group.

## F. Diagnostics quick reference
```powershell
dsregcmd /status                 # join state: AzureAdJoined / DomainJoined / MDM enrollment
Get-ComputerInfo | Select-Object WindowsProductName, OsBuildNumber, WindowsEditionId
# Autopilot diagnostics during/after OOBE:
mdmdiagnosticstool.exe -area Autopilot -cab C:\Temp\AutopilotDiag.cab
Get-ItemProperty 'HKLM:\SOFTWARE\Microsoft\Provisioning\Diagnostics\Autopilot' -EA SilentlyContinue
```
During OOBE you can press Shift+F10 for a command prompt to run `dsregcmd /status`.

## G. When to escalate
If the device is registered, in the dynamic group, the profile shows Assigned, internet is available at
OOBE, and provisioning still fails after a re-sync and re-provision, collect the Autopilot diagnostics
cab (`mdmdiagnosticstool.exe -area Autopilot`) and open a Microsoft support case.
