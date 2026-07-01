# 6. Troubleshooting Guide — SCCM Application Migration to Intune Win32

Use `SCCMAPP-Discovery.ps1` to re-read the SCCM source, `SCCMAPP-Validation.ps1` for per-device
install + detection parity, `SCCMAPP-Report.ps1` for coverage + deployment success, and
`SCCMAPP-Remediation.ps1` (default `-WhatIf`) for safe fixes.

## A. App installs but Intune reports Failed / not detected
| Symptom | Cause | Remediation |
|---|---|---|
| Device has the app, Intune says Failed | Detection rule does not match how the app really installs | Re-check the detection rule against the SCCM detection method (`SCCMAPP-Discovery.ps1`); fix the MSI product code / file path / registry / script to match; re-sync |
| Detection never true | Wrong product code or 32/64-bit path/registry view | Confirm the exact MSI product code; use the correct `Program Files` / registry hive for the app's bitness |

## B. Install fails on the device
| Symptom | Cause | Remediation |
|---|---|---|
| Exit code non-zero | Wrong silent switches carried over, or missing dependency | Confirm the install command matches the SCCM deployment type; ensure the dependency app auto-installs first; run `SCCMAPP-Remediation.ps1` |
| Needs a runtime | Dependency not declared in Intune | Package/create the dependency app and add it under `Dependencies` with `Automatically install = Yes` |

## C. App offered to the wrong devices
- Requirement rules don't match SCCM → re-check architecture / minimum OS / custom rules against the
  Step 1 export so `Not applicable` devices match SCCM's behavior.
- Ring targeting wrong → run `SCCMAPP-Set-AppRingTargeting.ps1`; confirm the pilot ring holds the
  same devices that received the SCCM deployment.

## D. Supersedence / upgrade problems
| Symptom | Cause | Remediation |
|---|---|---|
| Old and new versions both present | Supersedence not configured or set to in-place when a clean replace was needed | Add supersedence to the prior app; set `Uninstall previous version = Yes` to match SCCM's replace behavior |
| Upgrade removed the app | `Uninstall previous version = Yes` when an in-place upgrade was expected | Set it to `No` for in-place upgrades per the installer |

## E. Both SCCM and Intune fighting over the app
- During coexistence, keep SCCM deploying but do not let both authorities enforce a conflicting state
  on the same device. Retire the SCCM deployment for a ring only after the Intune app is validated
  there. If a conflict is seen, remove/disable the SCCM `Deployment` for those devices.

## F. Rollback
- If a migrated app misbehaves on the pilot, re-enable / keep the SCCM deployment for those devices
  and remove the Intune assignment for the ring — coexistence means the app never disappears. Fix the
  package and re-validate before retrying cutover.

## G. Diagnostics quick reference
```powershell
Get-CMApplication | Select-Object LocalizedDisplayName, NumberOfDeploymentTypes
Get-CMDeploymentType -ApplicationName 'LOB Reader'   # detection, install command, requirements
Get-ItemProperty 'HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall\*' |
    Select-Object DisplayName, DisplayVersion         # verify detection evidence on the device
Get-Content "$env:ProgramData\Microsoft\IntuneManagementExtension\Logs\IntuneManagementExtension.log" -Tail 200
```
The Intune Management Extension log (`IntuneManagementExtension.log`) records Win32 app install and
detection results on the device.

## H. When to escalate
If the install command matches SCCM, the dependency installs, the detection rule matches the on-disk
evidence, and Intune still reports Failed after a sync and a re-evaluation, collect the Intune
Management Extension log and the app's `Device install status` details and open a Microsoft support
case.
