# 6. Troubleshooting Guide — Workspace ONE to Intune Application Rebuild & Repackaging

Use `WS1APP-Validation.ps1` for local install/detection state, `WS1APP-Discovery.ps1` for the
source-vs-target gap, `WS1APP-Report.ps1` for fleet deployment status (Microsoft Graph), and
`WS1APP-Remediation.ps1` (default `-WhatIf`) for safe fixes.

## A. App not installing on the device
| Symptom | Cause | Remediation |
|---|---|---|
| App never installs | Device not synced, or not in the assigned group | Run `WS1APP-Remediation.ps1`; confirm group membership and the assignment intent |
| Win32 install fails | Wrong silent install command or return-code handling | Recreate the source silent command; verify return codes on the Program tab |
| Dependency missing | Runtime not rebuilt or not auto-installed | Rebuild the dependency app first; set Automatically install = Yes in the main app's Dependencies tab |

## B. Detection problems (reinstall loop or false "installed")
| Symptom | Cause | Remediation |
|---|---|---|
| App reinstalls every cycle | Detection rule does not match what the installer leaves | Re-capture the MSI product code / file version / registry value and fix the detection rule (one authoritative rule) |
| Reported Installed but app absent | Detection rule too loose (matches an unrelated path/key) | Tighten the rule to a unique, authoritative signal |
| Reported Failed but app present | Detection signal differs from the build (e.g. wrong product code) | Align the detection value to the actual installed app |

## C. Assignment parity issues
| Symptom | Cause | Remediation |
|---|---|---|
| Wrong users/devices get the app | Source-to-Entra group mapping wrong | Correct the Entra group mapping (Requirement 2.7); re-run `WS1APP-Report.ps1` to confirm parity |
| App not removed when expected | Missing Uninstall assignment | Add an Uninstall assignment where the source workflow removed the app |

## D. Store and managed mobile apps
| Symptom | Cause | Remediation |
|---|---|---|
| Wrong store app selected | Similar-named apps in the store | Reselect by exact publisher and bundle/package ID |
| iOS/Android app will not deploy | Platform channel not Active | Confirm Apple VPP/ABM + APNs or managed Google Play is Active (Requirement 2.5 / global G5); re-sync |

## E. Double-install or conflict during coexistence
- A device managed by both platforms is served the app twice. Retire the Workspace ONE assignment for
  that app only after the Intune install is confirmed healthy (Implementation Step 13); validate one
  authority delivers the app.

## F. Win32 repackaging
- `.intunewin` build fails or uploads but never installs. Confirm the source folder is clean and the
  setup file named in the wrap matches the install command; re-wrap with the Win32 Content Prep Tool
  (Requirement 2.3) from the original media (Requirement 2.4).

## G. Diagnostics quick reference
```powershell
Get-Package | Where-Object { $_.Name -like '*Acme*' }    # confirm an MSI/EXE app is present + its version
Get-ItemProperty 'HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall\*' | Select-Object DisplayName, DisplayVersion
Start-Process -FilePath "$env:WINDIR\System32\deviceenroller.exe" -ArgumentList "/c /AutoEnrollMDM"   # MDM sync
```
Intune-side: open the app to Device install status to read per-device result, or run `WS1APP-Report.ps1`.

## H. When to escalate
If the assignment is correct, the device is enrolled and synced, the detection rule matches a
manual install, and the app still will not deploy, collect the Intune Management Extension logs
(`C:\ProgramData\Microsoft\IntuneManagementExtension\Logs`) for Win32 apps and open a Microsoft
support case. Source-side app-export questions are deferred to VMware documentation.
