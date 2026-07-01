# 6. Troubleshooting Guide — Third-Party Application Patching with Intune

Use `TPP-Discovery.ps1` / `TPP-Validation.ps1` for device state, `TPP-Report.ps1` for fleet exposure,
and `TPP-Remediation.ps1` (default `-WhatIf`) for safe fixes.

## A. Update not applying / app stays on old version
| Symptom | Cause | Remediation |
|---|---|---|
| Device never updates the app | Not synced, or assignment not received | Run `TPP-Remediation.ps1` (sync + app re-evaluation); confirm group membership |
| Win32 update shows "Installed" but version is old | Detection rule matches too loosely (not version-aware) | Re-key detection to `DisplayVersion` / file version greater-than-or-equal-to the target |
| Old version not removed | Supersedence not set, or set to install-alongside | Edit the new package supersedence to **Update/replace** the prior package |

## B. Update re-installs every cycle (never "done")
- The detection rule does not recognize the version it just installed. Confirm the rule reads the same
  `DisplayVersion` / file path the installer actually writes, with the correct operator and value.

## C. Catalog app issues
| Symptom | Cause | Remediation |
|---|---|---|
| Catalog app not updating to new version | Auto-update not enabled on the app | Edit the Enterprise App Catalog app and enable automatic update |
| App not found in catalog | App not covered by the Enterprise App Catalog | Use the packaged Win32 path (Implementation Step 4) |

## D. Install fails because the app is open
- Installers that require the app closed will fail in system context while the user has it running.
  Use the vendor's in-use / silent-update switches, or schedule the update for a maintenance window and
  communicate the restart to users.

## E. Conflicting updater
- An app with its own auto-updater can fight Intune (versions bounce, false "out of date"). Decide one
  authority per app: disable the app's updater where Intune owns patching, or exclude that app from
  Intune patching where its own updater owns it.

## F. False exposure in the report
- `TPP-Report.ps1` compares installed versions to the target you supply. A wrong target string, or an
  app whose `DisplayVersion` format differs, can show false exposure. Confirm the target and the
  observed `DisplayVersion` with `TPP-Discovery.ps1`.

## G. Diagnostics quick reference
```powershell
# installed third-party apps + versions (both registry hives)
Get-ItemProperty 'HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall\*','HKLM:\SOFTWARE\WOW6432Node\Microsoft\Windows\CurrentVersion\Uninstall\*' -EA SilentlyContinue |
  Where-Object DisplayName | Select-Object DisplayName, DisplayVersion, Publisher
# force a management sync so assignments re-apply
Start-Process "$env:WINDIR\System32\deviceenroller.exe" -ArgumentList "/c /AutoEnrollMDM" -WindowStyle Hidden
```
Win32 app logs: `C:\ProgramData\Microsoft\IntuneManagementExtension\Logs\IntuneManagementExtension.log`.

## H. When to escalate
If the assignment is received, supersedence is set, detection is version-aware, the device is synced,
and the update still will not apply, collect the IntuneManagementExtension log and open a Microsoft
support case.
