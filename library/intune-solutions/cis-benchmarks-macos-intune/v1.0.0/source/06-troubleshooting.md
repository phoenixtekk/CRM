# 6. Troubleshooting Guide — CIS Benchmarks for macOS (Microsoft Intune)

Use `CISMAC-Discovery.ps1` / `CISMAC-Validation.ps1` for tenant/device state, `CISMAC-Report.ps1` for
fleet posture and drift, `CISMAC-Remediation.ps1` for safe reapply (default `-WhatIf`), and
`CISMAC-Compare-BenchmarkVersion.ps1` when working a version update.

## A. Policy/profile not applying / device not compliant
| Symptom | Cause | Remediation |
|---|---|---|
| Settings-catalog policy shows Error on a Mac | Mac not enrolled / not synced / not in the assigned group | Confirm enrollment (`CISMAC-Discovery.ps1`) and group membership; force a sync (Company Portal → Check status); re-check **Per-setting status** |
| Nothing applies to any Mac | Apple MDM Push (APNs) certificate missing or expired | Intune → **Devices → Enrollment → Apple → Apple MDM Push certificate**; renew with the same Apple ID (Requirement 2.2) |
| Some settings Succeeded, others Error | A control's Apple payload is unavailable on that macOS version | Confirm the macOS version matches the CIS benchmark; deliver the control via custom `.mobileconfig` or shell script instead |
| Mac drifts back after applying | A conflicting Intune profile sets the same payload differently | Find the conflict (`CISMAC-Report.ps1` + Intune per-setting status) and resolve it at the profile level, not by repeated remediation |

## B. Hardening broke an app or login
- Identify the offending control from the app/login behavior and `CISMAC-Validation.ps1`.
- **Fastest safe rollback:** remove the profile/policy/script assignment from the affected group, or set that single control to **Not configured** (or disable the shell script), then sync; the Mac reverts on the next policy cycle.
- Record the rollback as a documented break-glass exception (control, reason, compensating control, owner, review date).

## C. Custom `.mobileconfig` profile not taking effect
| Symptom | Cause | Remediation |
|---|---|---|
| Custom profile assigned but payload absent | Wrong deployment channel, malformed `.mobileconfig`, or a required user approval not granted | Re-upload a valid `.mobileconfig`; confirm the deployment channel; on the Mac check **System Settings → Privacy & Security → Profiles** |
| Catalog setting and custom profile fight | The same payload set in two places | Keep each control in one surface only — prefer the settings catalog, remove the duplicate from the custom profile |

## D. macOS shell-script control not enforcing
| Symptom | Cause | Remediation |
|---|---|---|
| Script shows failed in Device status | Script error, or not run as root | Open **Devices → macOS → Shell scripts →** script → review the error; set **Run script as signed-in user = No** (run as root); fix the command |
| Control reverts after a user change | Run frequency too infrequent to re-enforce | Increase the shell script's run frequency so it re-applies the control on a schedule |

## E. Compliance policy reports noncompliant unexpectedly
- Confirm the compliance rules match controls the Mac can actually meet (minimum OS version, FileVault, firewall).
- Allow the grace period to elapse and let the Mac re-evaluate; sync if needed.
- Cross-check with `CISMAC-Validation.ps1` to confirm whether it is a real gap or a reporting lag.

## F. Benchmark-version update issues
| Symptom | Cause | Remediation |
|---|---|---|
| `CISMAC-Compare-BenchmarkVersion.ps1` shows huge unexpected diff | Comparing against the wrong export, or baseline not exported correctly | Re-export the current live baseline and the new benchmark; confirm you are diffing the right two files |
| New L1 control breaks Macs fleet-wide after promotion | Promoted to production without a full pilot soak | Roll back that control (unassign / Not configured / disable script); re-pilot per Maintenance Part B before promoting again |
| Controls missing after a macOS major upgrade | The benchmark (and some Apple payloads) changed for the new macOS release | Obtain the new macOS release's benchmark and run the full Maintenance Part B lifecycle |

## G. Graph scripts fail to connect
- `CISMAC-Report.ps1` needs Microsoft Graph PowerShell and `DeviceManagementConfiguration.Read.All`; consent the scope on first `Connect-MgGraph`.
- If module load fails, run `Install-Module Microsoft.Graph -Scope CurrentUser`.

## H. Diagnostics quick reference
```powershell
Get-MgContext   # confirm Graph scopes
```
On the Mac (Terminal, for local checks of CIS-relevant state):
```bash
sw_vers                                  # macOS product version / build
fdesetup status                          # FileVault on/off
profiles list                            # installed configuration profiles
```
Intune-side: device → **Device configuration** shows each profile's apply status; policy →
**Per-setting status** shows which CIS settings succeeded or errored; **Shell scripts → Device
status** shows script results.

## I. When to escalate
If the profile shows Succeeded, the Mac is enrolled, synced, and in the right group, the APNs
certificate is valid, no conflicting profile exists, and a control still will not apply, capture the
per-setting status, the shell-script result, and the on-device `profiles list` output and open a
Microsoft support case.
