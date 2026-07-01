# 6. Troubleshooting Guide — Endpoint PowerShell Deployment & Patch Automation Toolkit

Use `PSAUTO-Discovery.ps1` for admin-workstation/automation readiness, `PSAUTO-Validation.ps1` to
test detection on a device, `PSAUTO-Remediation.ps1` for a safe fix, and `PSAUTO-Report.ps1` for
fleet status.

## A. Remediation never runs / no results
| Symptom | Cause | Remediation |
|---|---|---|
| Device shows no detection result | Not synced, or not in the assigned group | Force a sync (Settings → Accounts → Access work or school → Info → Sync); confirm group membership |
| Remediation blade missing | Missing Remediations entitlement | Assign a qualifying license (see Requirements 2.1) |
| Script never fires | Schedule not set on the assignment | Edit the assignment and set `Endpoint Automation Schedule – Windows – Daily` |

## B. Detection always reports non-compliant
- The script is running 32-bit, so registry/file paths differ — set `Run script in 64-bit PowerShell`
  to `Yes` on the remediation.
- The desired-state values at the top of `PSAUTO-Validation.ps1` do not match your standard — correct
  them and re-upload the detection script.
- The check assumes the logged-on user's context but runs as SYSTEM — adjust the path or run as the
  logged-on user only if the task truly requires it.

## C. Remediation does not change anything
- It is running with the default `-WhatIf` (report-only). Re-run with `-WhatIf:$false` (or `-Apply`),
  or set that default before uploading the remediation script.
- The remediation exits before acting because the device is already compliant — confirm with
  `PSAUTO-Validation.ps1` that detection returns `1`.

## D. Script blocked from running
| Symptom | Cause | Remediation |
|---|---|---|
| Unsigned-script error | Execution policy is `AllSigned` | Sign the `.ps1` (Requirements 2.5), or set the remediation `Enforce script signature check = No` where policy allows |
| Access denied to a path/registry key | Running as the wrong context | Run as SYSTEM (default) for machine-wide paths; reserve logged-on-user for user-scope tasks |

## E. Fleet report errors
- `PSAUTO-Report.ps1` fails to connect — install the Graph SDK (Requirements 2.2) and consent to
  `DeviceManagementManagedDevices.Read.All` and `DeviceManagementConfiguration.Read.All`.
- The report is empty — confirm the remediation is assigned and has run at least one cycle.

## F. Deployment / cleanup runner issues
- Nothing installed/removed — it ran with the default `-WhatIf`; re-run with `-WhatIf:$false`.
- No log written — set `-LogPath` to a destination writable by the run context (Requirements 2.6).
- Cleanup left files — confirm the paths in the runner match the failed install's leftovers.

## G. Diagnostics quick reference
```powershell
Get-ExecutionPolicy -List                                    # execution policy per scope
[Environment]::Is64BitProcess                                # confirm 64-bit host
Get-Module -ListAvailable Microsoft.Graph.Authentication     # Graph SDK present?
Get-Content "$env:ProgramData\Microsoft\IntuneManagementExtension\Logs\AgentExecutor.log" -Tail 50
```
The IntuneManagementExtension `AgentExecutor.log` and `IntuneManagementExtension.log` on the device
record remediation script output and exit codes.

## H. When to escalate
If a device is enrolled, in the assigned group, synced, the remediation is assigned with a schedule,
and the script still does not run, collect the `IntuneManagementExtension` logs above and open a
Microsoft support case.
