# 6. Troubleshooting Guide — CIS Benchmarks for Windows 11 (Microsoft Intune)

Use `CIS11-Discovery.ps1` / `CIS11-Validation.ps1` for device state, `CIS11-Report.ps1` for fleet
posture and drift, `CIS11-Remediation.ps1` for safe reapply (default `-WhatIf`), and
`CIS11-Compare-BenchmarkVersion.ps1` when working a version update.

## A. Policy not applying / device not compliant
| Symptom | Cause | Remediation |
|---|---|---|
| Settings-catalog policy shows Error on a device | Device not enrolled / not synced / not in the assigned group | Confirm enrollment (`CIS11-Discovery.ps1`) and group membership; sync the device; re-check **Per-setting status** |
| Some settings Succeeded, others Error | A specific setting unsupported on that edition/build | Confirm a supported Windows 11 edition/build; remove or scope the unsupported control |
| Device drifts back after applying | A conflicting Intune policy sets the same control differently | Find the conflict (`CIS11-Report.ps1` + Intune per-setting status) and resolve it at the policy level, not by repeated remediation |

## B. Hardening broke a business app
- Identify the offending control from the app behavior and `CIS11-Validation.ps1`.
- **Fastest safe rollback:** remove the policy assignment from the affected group, or set that single control to **Not configured**, then sync; the device reverts on the next policy cycle.
- Record the rollback as a documented break-glass exception (control, reason, compensating control, owner, review date).

## C. Imported ADMX settings not taking effect
| Symptom | Cause | Remediation |
|---|---|---|
| ADMX policy assigned but setting absent | ADMX/ADML not fully imported, or wrong language file | Intune → **Import ADMX**; confirm status **Available** and the matching `.adml`; recreate the template policy if needed |
| Template setting greyed out / unavailable | Control belongs in the settings catalog, not ADMX | Configure it as a settings-catalog setting instead |

## D. Compliance policy reports noncompliant unexpectedly
- Confirm the compliance rules match controls the device can actually meet (OS build, BitLocker, Defender).
- Allow the grace period to elapse and let the device re-evaluate; sync if needed.
- Cross-check with `CIS11-Validation.ps1` to confirm whether it is a real gap or a reporting lag.

## E. Benchmark-version update issues
| Symptom | Cause | Remediation |
|---|---|---|
| `CIS11-Compare-BenchmarkVersion.ps1` shows huge unexpected diff | Comparing against the wrong export, or baseline not exported correctly | Re-export the current live baseline and the new benchmark; confirm you are diffing the right two files |
| New L1 control breaks devices fleet-wide after promotion | Promoted to production without a full pilot soak | Roll back that control (unassign / Not configured); re-pilot per Maintenance Part B before promoting again |

## F. Graph scripts fail to connect
- `CIS11-Report.ps1` needs Microsoft Graph PowerShell and `DeviceManagementConfiguration.Read.All`; consent the scope on first `Connect-MgGraph`.
- If module load fails, run `Install-Module Microsoft.Graph -Scope CurrentUser`.

## G. Diagnostics quick reference
```powershell
Get-ComputerInfo | Select-Object WindowsProductName, OsBuildNumber, WindowsVersion   # edition/build
Get-MgContext                                                                          # confirm Graph scopes
gpresult /h "$env:TEMP\cis.html"                                                       # resultant settings report
```
Intune-side: device → **Device configuration** shows each profile's apply status; policy → **Per-setting status** shows which CIS settings succeeded or errored.

## H. When to escalate
If the policy shows Succeeded, the device is enrolled, synced, and in the right group, no conflicting
policy exists, and a control still will not apply, capture the per-setting status and a `gpresult`
report and open a Microsoft support case.
