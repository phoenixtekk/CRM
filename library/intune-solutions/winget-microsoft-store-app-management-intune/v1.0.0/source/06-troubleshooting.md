# 6. Troubleshooting Guide — Winget & Microsoft Store App Management with Microsoft Intune

Use `WINGETSTORE-Discovery.ps1` to see what's deployed and how it's assigned, `WINGETSTORE-Validate.ps1`
for the pilot PASS/FAIL state, `WINGETSTORE-Report.ps1` for fleet install/update status, and
`WINGETSTORE-Test-Install.ps1` **on the device** to confirm a local install + detected version. The
Intune Management Extension log on the device is
`C:\ProgramData\Microsoft\IntuneManagementExtension\Logs\IntuneManagementExtension.log`. For deep
break/fix beyond this table, use the *Intune App Deployment Troubleshooting & Failure Remediation
(Win32/LOB/Store)* product.

## A. A Required Store app is not installing
| Symptom | Cause | Remediation |
|---|---|---|
| `Adobe Acrobat Reader – Store – Required` never installs on a targeted device | Assignment missing or scoped to the wrong group | Run `WINGETSTORE-Validate.ps1`; confirm the Required assignment targets `Store & Winget Apps – Pilot – Ring 1`; fix with `WINGETSTORE-Set-Assignment.ps1` |
| Device shows the app as Pending forever | IME not present / device not synced | Confirm enrollment; sync (**Settings → Accounts → Access work or school → Sync**); check the IME service with `WINGETSTORE-Test-Install.ps1` |
| App shows **Not applicable** | Device doesn't meet the app's requirements (OS/architecture) or the new Store app type isn't supported on that build | Confirm the supported Windows baseline (Requirement 2.6); **verify the new Store app type's minimum build with Microsoft** |
| Wrong app installed | A look-alike catalog listing was added | Re-add the app confirming the **publisher** (e.g. **Adobe Inc.**) and package identifier (Requirement 2.5) |

## B. A winget app won't detect, or shows the wrong version
| Symptom | Cause | Remediation |
|---|---|---|
| App is on the device but Intune/report shows not installed | Detection/reporting lag, or (for a winget-wrapped Win32) a wrong detection rule | Confirm locally with `WINGETSTORE-Test-Install.ps1` (registry check is id-independent); for a Win32 wrapper fix the detection rule per the Win32 packaging product |
| `winget list` finds it but the wrapper reports Failed | The winget id or scope is wrong in the install command | **Verify the exact winget `--id` and `--scope machine` behavior with winget/Microsoft docs**; re-test the command in system context |
| Version differs from expected | Store/winget installs "latest"; you assumed a pinned version | If you must pin a version, use a custom Win32 package (see the Win32 product) rather than the Store lane |

## C. A self-service (Available) app isn't appearing in Company Portal
| Symptom | Cause | Remediation |
|---|---|---|
| `VLC media player – Winget – Available` not visible to the user | The assignment intent is not **Available**, or it's scoped to devices/another group | Run `WINGETSTORE-Validate.ps1`; ensure the app is assigned **available** to the user's group; fix with `WINGETSTORE-Set-Assignment.ps1 -Intent available` |
| No apps show in Company Portal at all | Company Portal not installed, or user not signed in | Deploy Company Portal (Requirement 2.4); confirm the user is signed in with their work account |
| App appears but won't install on click | winget/App Installer prerequisites missing | Confirm App Installer is present (Requirement 2.7); **verify the required winget prerequisites with Microsoft** |

## D. Updates are lagging
| Symptom | Cause | Remediation |
|---|---|---|
| Installed apps stay on an older version | Store/winget update cadence is service-managed, not instant | **Confirm the expected update cadence with Microsoft (verify-with-Microsoft)** before treating a lag as a failure; allow the documented window, then re-check with `WINGETSTORE-Report.ps1` (Version column) |
| A specific app never updates | It's a version-pinned Win32 wrapper, not a Store/winget app | Deploy the new version (or a scheduled winget upgrade) — pinned apps do not auto-update |
| Some devices update, others don't | Sync / connectivity gaps | Sync the device; confirm network access to Microsoft endpoints (Global Requirement G7) |

## E. Uninstall behavior isn't what you expected
| Symptom | Cause | Remediation |
|---|---|---|
| Removing an app didn't uninstall it | No **Uninstall** assignment was added; removing the Available/Required assignment alone may not remove an installed app | Add an **Uninstall** intent assignment (`WINGETSTORE-Set-Assignment.ps1 -Intent uninstall`) to actively remove it |
| User re-installs a removed app | It's still **Available** in Company Portal | Remove the Available assignment (or replace with Uninstall) so it no longer offers the app |
| Uninstall leaves remnants | The publisher's uninstaller is incomplete | For thorough removal of a winget-wrapped app, use a custom Win32 uninstall command (see the Win32 product) |

## F. Scripts
| Script | Use it to |
|---|---|
| `WINGETSTORE-Discovery.ps1` | List every Store (new) / winget app and its assignments (Required / Available / Uninstall) — read-only |
| `WINGETSTORE-Validate.ps1` | PASS/FAIL the pilot: the Required app + the Available (self-service) app are assigned to the pilot group — read-only |
| `WINGETSTORE-Report.ps1` | Export per-app / per-device Installed / Failed / Not applicable + detected version to CSV — read-only |
| `WINGETSTORE-Test-Install.ps1` | Confirm a local install and its version on a pilot device (IME + winget + registry) — read-only |
| `WINGETSTORE-Set-Assignment.ps1` | Add a Required / Available / Uninstall assignment — the only state-changer, **defaults to `-WhatIf`** |

```powershell
Get-Service -Name 'Microsoft Intune Management Extension'        # IME present/running
Get-Command winget                                               # winget/App Installer available?
Get-ItemProperty 'HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall\*',
  'HKLM:\SOFTWARE\WOW6432Node\Microsoft\Windows\CurrentVersion\Uninstall\*' |
  Select-Object DisplayName, DisplayVersion   # installed app + version (id-independent detection)
```
The IME log (`IntuneManagementExtension.log`) shows the install action and result per app — the first
place to look.

## G. When to escalate
If the assignment is correct, the device is enrolled, synced, and healthy, the app is confirmed in the
catalog with the right publisher, and Intune still reports Failed after the documented policy/update
cycle, collect the `IntuneManagementExtension.log` and open a Microsoft support case. Because catalog
availability, the new Store app type, and update behavior change over time, **verify the current
expected behavior against Microsoft documentation for your cloud** (Commercial vs Government may differ)
before concluding it is a defect.
