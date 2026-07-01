# 6. Troubleshooting Guide — DISA STIG Compliance for Windows 10 & 11 (Microsoft Intune)

Use `STIG-Discovery.ps1` / `STIG-Validation.ps1` for device state, `STIG-Report.ps1` for fleet posture
and drift, `STIG-Remediation.ps1` for safe reapply (default `-WhatIf`), and
`STIG-Compare-StigVersion.ps1` when working a release update.

## A. Policy not applying / device not compliant
| Symptom | Cause | Remediation |
|---|---|---|
| Settings-catalog policy shows Error on a device | Device not enrolled / not synced / not in the assigned group | Confirm enrollment (`STIG-Discovery.ps1`) and group membership; sync the device; re-check Per-setting status |
| Some settings Succeeded, others Error | A specific setting unsupported on that edition/build | Confirm a supported Windows 10/11 edition/build; remove or scope the unsupported rule |
| Device drifts back after applying | A conflicting Intune policy sets the same rule differently | Find the conflict (`STIG-Report.ps1` + Intune per-setting status) and resolve it at the policy level, not by repeated remediation |

## B. Hardening broke a mission app
- Identify the offending rule from the app behavior and `STIG-Validation.ps1`.
- Fastest safe rollback: remove the policy assignment from the affected group, or set that single rule to Not configured, then sync; the device reverts on the next policy cycle.
- Record the rollback as a documented POA&M item (Rule/Vuln ID, CAT, risk, compensating control, owner, remediation milestone).

## C. Imported ADMX settings not taking effect
| Symptom | Cause | Remediation |
|---|---|---|
| ADMX policy assigned but setting absent | ADMX/ADML not fully imported, or wrong language file | Intune → Import ADMX; confirm status Available and the matching `.adml`; recreate the template policy if needed |
| Template setting greyed out / unavailable | Rule belongs in the settings catalog, not ADMX | Configure it as a settings-catalog setting instead |

## D. Compliance policy reports noncompliant unexpectedly
- Confirm the compliance rules match rules the device can actually meet (OS build, BitLocker, Defender, Secure Boot).
- Allow the grace period to elapse and let the device re-evaluate; sync if needed.
- Cross-check with `STIG-Validation.ps1` to confirm whether it is a real gap or a reporting lag.

## E. SCAP / STIG Viewer scan disagrees with Intune
| Symptom | Cause | Remediation |
|---|---|---|
| Intune shows Succeeded but SCAP marks a rule Open | The rule maps to a different setting/registry value than the one applied, or a manual/procedural check | Re-check the rule's check text in the STIG Viewer; confirm the settings-catalog entry matches the required value; manual-check rules are handled procedurally, not by Intune |
| Open finding with no matching POA&M | A rule was deferred without being recorded | Add a POA&M item (Rule/Vuln ID, risk, compensating control, owner, milestone) or implement the rule |

## F. STIG-release update issues
| Symptom | Cause | Remediation |
|---|---|---|
| `STIG-Compare-StigVersion.ps1` shows huge unexpected diff | Comparing against the wrong export, or baseline not exported correctly | Re-export the current live baseline and the new STIG; confirm you are diffing the right two files |
| New CAT I rule breaks devices fleet-wide after promotion | Promoted to production without a full pilot soak | Roll back that rule (unassign / Not configured); re-pilot per Maintenance Part B before promoting again |

## G. Graph scripts fail to connect
- `STIG-Report.ps1` needs Microsoft Graph PowerShell and `DeviceManagementConfiguration.Read.All`; consent the scope on first `Connect-MgGraph`.
- If module load fails, run `Install-Module Microsoft.Graph -Scope CurrentUser`.

## H. Diagnostics quick reference
```powershell
Get-ComputerInfo | Select-Object WindowsProductName, OsBuildNumber, WindowsVersion   # edition/build
Get-MgContext                                                                          # confirm Graph scopes
gpresult /h "$env:TEMP\stig.html"                                                      # resultant settings report
```
Intune-side: device → Device configuration shows each profile's apply status; policy → Per-setting
status shows which STIG settings succeeded or errored.

## I. When to escalate
If the policy shows Succeeded, the device is enrolled, synced, and in the right group, no conflicting
policy exists, and a rule still will not apply, capture the per-setting status, a `gpresult` report,
and the SCAP scan result, and open a Microsoft support case.
