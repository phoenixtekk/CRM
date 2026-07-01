# 6. Troubleshooting Guide — Windows 11 Healthcare Endpoint Baseline

Use `W11HC-Validation.ps1` and `W11HC-Discovery.ps1` for device state, `W11HC-Report.ps1` for fleet
status, and `W11HC-Remediation.ps1` for a safe sync.

## A. Profile shows Error or Not applicable
| Symptom | Cause | Remediation |
|---|---|---|
| Profile shows Error | Device not enrolled or not checked in | Confirm enrollment and group membership; run `W11HC-Remediation.ps1` to sync |
| Profile shows Not applicable | Device not in the assigned group, or wrong platform | Confirm the device is in the correct `W11 Baseline – <Scope> – <Stage>` group |
| Settings not present on device | Policy not yet synced | Run `W11HC-Remediation.ps1`; re-check after a policy cycle with `W11HC-Validation.ps1` |

## B. Security baseline shows Conflict
- A Conflict means two policies set the same security value. Keep `W11 Security Baseline – All – Baseline`
  authoritative for security settings and remove that value from `W11 Settings Catalog – All – Baseline`
  (or from any legacy GPO). Re-sync and re-check.

## C. Shared clinical device still sleeps mid-shift
| Symptom | Cause | Remediation |
|---|---|---|
| Device sleeps or display blanks | `W11 Power – Clinical – AlwaysOn` not applied, or device on battery | Confirm the profile is assigned and Succeeded; on battery-only devices set on-battery timeouts too; verify with `powercfg /q` |
| Power profile shows Conflict | A second power profile or GPO also setting power | Remove the duplicate; keep one power profile per scope |

## D. Updates not installing or restarting at the wrong time
- Confirm the device is in the correct update-ring group and the ring shows Succeeded; check the
  deferral and active-hours values match the maintenance window. Run `W11HC-Remediation.ps1` to sync,
  then let a policy cycle pass.

## E. Conflicting configuration authority
- An on-prem GPO (for example a `WUServer` value) or a second overlapping Intune profile will fight
  the baseline. Run `W11HC-Discovery.ps1` to flag it, then remove or scope away the conflicting
  source so the baseline is authoritative.

## F. Diagnostics quick reference
```powershell
Get-ComputerInfo | Select-Object WindowsProductName, OsBuildNumber, WindowsVersion
(Get-Tpm).TpmPresent, (Confirm-SecureBootUEFI)
Get-MpComputerStatus | Select-Object RealTimeProtectionEnabled, AntivirusEnabled
powercfg /q                       # current power scheme timeouts
dsregcmd /status                  # Entra join + MDM enrollment state
```

## G. When to escalate
If the profiles show Succeeded, no conflict exists, the device is synced and in the right group, and
a setting still will not apply after a policy cycle, collect `dsregcmd /status` and the Intune device
configuration status, then open a Microsoft support case.
