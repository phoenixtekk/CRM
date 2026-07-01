# 6. Troubleshooting Guide — New-Site Endpoint Rollout Playbook

Use `NEWSITE-Discovery.ps1` for site readiness, `NEWSITE-Validation.ps1` for per-device state,
`NEWSITE-Report.ps1` for site-wide status, and `NEWSITE-Remediation.ps1` (default `-WhatIf`) for
safe fixes. Work the stages in dependency order — a failure in an early stage cascades into later
ones, so fix the earliest failing stage first.

## A. Site network / identity not ready
| Symptom | Cause | Remediation |
|---|---|---|
| Devices cannot enroll at the site | Site firewall/proxy blocks Microsoft endpoints | Have the network team allow Microsoft 365 / Intune URL and IP ranges; re-run `NEWSITE-Discovery.ps1` |
| Sign-in fails or times out | DNS or time skew at the site | Confirm DNS resolves `login.microsoftonline.com` and the device clock is in sync; correct then retry |

## B. Provisioning / enrollment issues
| Symptom | Cause | Remediation |
|---|---|---|
| Device not in Intune | Enrollment method not applied | Confirm the Autopilot profile or automatic enrollment is configured (Requirement 2.2); re-run OOBE or re-join to Entra ID |
| Device enrolled but not in the site group | Group membership not synced | Add the device (or fix the dynamic rule), then run `NEWSITE-Set-SiteGroupTargeting.ps1` to reconcile membership |

## C. Baseline not applying
| Symptom | Cause | Remediation |
|---|---|---|
| Device shows Not compliant | Compliance policy not assigned to the site group, or not yet synced | Confirm the policy is assigned to the site group (Implementation Step 4); sync, then re-check |
| Security baseline shows Error | Conflicting configuration profile | Identify the conflicting setting in Intune → Endpoint security → device status; resolve the conflict and re-sync |

## D. Apps not installing
| Symptom | Cause | Remediation |
|---|---|---|
| Site app missing on device | App not assigned as Required to the site group | Add a Required assignment to the site group (Step 5); run `NEWSITE-Remediation.ps1` to trigger a sync |
| App install fails | Dependency or detection rule issue | Check Intune → Apps → Monitor → App install status for the error code; correct the app's requirements/detection rule |

## E. Printers not appearing
| Symptom | Cause | Remediation |
|---|---|---|
| Site printer absent | Printer configuration not assigned to the site group | Assign your Universal Print / connector configuration to the site group (Step 6); sync |
| Printer present but cannot print | Network path or driver issue at the site | Confirm the print path (Universal Print connector or print server) is reachable from the site; print a test page |

## F. Diagnostics quick reference
```powershell
Test-NetConnection login.microsoftonline.com -Port 443          # cloud reachability
Get-MgDeviceManagementManagedDevice -Filter "..."               # device state via Graph
Get-Printer | Select Name, DriverName, PortName                 # printers present on the device
dsregcmd /status                                                # Entra join + MDM enrollment state
```

## G. When to escalate
If the site is reachable, devices are enrolled and in the site group, the baseline and apps are
assigned and synced, and devices still fail `NEWSITE-Validation.ps1` after running
`NEWSITE-Remediation.ps1` and a policy cycle, collect `dsregcmd /status` and the relevant Intune
install/compliance error codes and open a Microsoft support case.
