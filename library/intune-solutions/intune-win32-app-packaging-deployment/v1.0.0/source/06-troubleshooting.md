# 6. Troubleshooting Guide — Intune Win32 Application Packaging & Deployment

Use `WIN32-Validation.ps1` for on-device install + detection state, `WIN32-Report.ps1` for fleet
status, and `WIN32-Remediation.ps1` (default `-WhatIf`) for safe fixes. The Intune Management
Extension log on the device is `C:\ProgramData\Microsoft\IntuneManagementExtension\Logs\IntuneManagementExtension.log`.

## A. App shows Failed (but seems installed) or loops reinstalling
| Symptom | Cause | Remediation |
|---|---|---|
| Reports Failed though the app is on the device | Detection rule does not match what the installer wrote | Fix the detection rule (correct MSI product code / file path + version / registry value); confirm with `WIN32-Validation.ps1` |
| App reinstalls every cycle | Detection rule never matches after install | Same as above — make detection deterministic; re-sync |
| Reports Installed but app is missing | Detection rule matches the wrong artifact | Tighten the detection rule to a unique value (product code or versioned file) |

## B. App shows Not applicable
| Symptom | Cause | Remediation |
|---|---|---|
| Device never gets the app, shows Not applicable | A requirement rule excludes it (architecture / min OS) | Confirm the device meets the requirement; correct the requirement rule if too strict (e.g. wrong min OS build) |
| Targeted group is correct but still N/A | Custom requirement script returns non-matching output | Review the requirement script's expected output and exit handling |

## C. Install fails outright
| Symptom | Cause | Remediation |
|---|---|---|
| Non-zero exit from the installer | Wrong/interactive command line | Re-test the silent command on a clean VM; ensure `/qn` (MSI) or the vendor silent switch; expect exit `0` |
| Exit `1603` | Generic MSI failure (in-use files, missing prerequisite) | Check the dependency installed first; review the MSI verbose log; confirm system context |
| Content download / size error | `.intunewin` too large or corrupt | Rebuild with `WIN32-New-IntuneWinPackage.ps1`; reduce source size; re-upload |

## D. Dependencies install out of order
- Confirm the runtime is a separate Win32 app declared as a **dependency** with **Automatically
  install = Yes**, not merely assigned alongside. Re-sync and re-check `WIN32-Report.ps1`.

## E. Supersedence didn't replace the old version
- Confirm the new app's **Supersedence** tab references the prior app and the **Uninstall previous
  version** choice is correct; allow a policy cycle. Duplicate entries usually mean supersedence was
  not configured (a second app was deployed instead).

## F. IME not present / nothing installs
- The Intune Management Extension installs automatically once a Win32 app or PowerShell script is
  assigned. Confirm the device is enrolled, sync, and check that the `Microsoft Intune Management
  Extension` service is running (`WIN32-Validation.ps1` flags this).

## G. Diagnostics quick reference
```powershell
Get-Service -Name 'Microsoft Intune Management Extension'   # IME present/running
Get-CimInstance Win32_Product | Where-Object Name -like '*Contoso*'   # installed MSI products (slow)
Get-ItemProperty 'HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall\*' |
  Select-Object DisplayName, DisplayVersion   # registry-based detection check
```
The IME log (`IntuneManagementExtension.log`) shows the install command, exit code, and detection
result per app — the first place to look.

## H. When to escalate
If detection is correct, requirements pass, the command line succeeds with exit `0` on a clean VM,
the IME is healthy and synced, but Intune still reports Failed after a policy cycle, collect the
`IntuneManagementExtension.log` and the installer's own verbose log and open a Microsoft support case.
