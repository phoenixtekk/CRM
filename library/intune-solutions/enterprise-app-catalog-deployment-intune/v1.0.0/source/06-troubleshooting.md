# 6. Troubleshooting Guide — Enterprise App Catalog Deployment in Microsoft Intune

Use `ENTAPPCAT-Discovery.ps1` to see catalog apps + assignments + update settings,
`ENTAPPCAT-Test-Install.ps1` for on-device IME + install state, `ENTAPPCAT-Validate.ps1` for the
PASS/FAIL pilot gate, and `ENTAPPCAT-Report.ps1` for fleet status. The Intune Management Extension log
on the device is `C:\ProgramData\Microsoft\IntuneManagementExtension\Logs\IntuneManagementExtension.log`.

> These are the **catalog-specific first steps**. For deep, cross-cutting Win32/LOB/Store break/fix,
> hand off to the existing **"Intune App Deployment Troubleshooting & Failure Remediation
> (Win32/LOB/Store)"** product.

## A. The app I want isn't in the catalog
| Symptom | Cause | Remediation |
|---|---|---|
| `Sample App` doesn't appear in the Enterprise App Catalog picker | The app is not curated by Microsoft, or catalog contents changed | Confirm the exact name; the catalog's contents are Microsoft-defined and change over time (*verify against current documentation*). If it's genuinely absent, use another lane: hand-package it as Win32, or use the winget/Store product |
| Only some versions are offered | Version availability is Microsoft-defined | Select an offered version, or rely on update management to track the latest |

## B. App shows Not applicable
| Symptom | Cause | Remediation |
|---|---|---|
| Device never gets the app, shows Not applicable | The device isn't in the assigned group, or a requirement supplied by the package excludes it (architecture / min OS) | Confirm the device is in `Catalog Apps – Pilot Devices – Ring 1`; confirm it meets the package's requirements; re-sync |
| Whole ring is Not applicable | Assignment targets the wrong group | Re-check the assignment (`ENTAPPCAT-Discovery.ps1`) and re-assign to the correct ring |

## C. Install fails outright
| Symptom | Cause | Remediation |
|---|---|---|
| App reports Failed on the device | Content download blocked, or an in-use file / prerequisite issue | Confirm network access to Microsoft's content-delivery endpoints (Requirement 2.7); sync; review the IME log for the exit code |
| Content download / CDN error | Proxy/firewall blocking Intune / Delivery Optimization endpoints | Allow Microsoft's published Intune/DO/CDN URL & IP ranges (*verify current list*); retry |
| Fails only on some devices | Device-specific (disk space, pending reboot, competing installer) | Check the device; re-sync; escalate to the app-troubleshooting product if it persists |

## D. Update isn't applying (app stays on the old version)
| Symptom | Cause | Remediation |
|---|---|---|
| Deployed version doesn't advance | Update management not enabled, or the update cycle hasn't run yet | Confirm update management is **enabled** on `Catalog App – Sample App – Prod` (Implementation Step 6 / `ENTAPPCAT-Validate.ps1`); allow a full policy/update cycle |
| Version pinned intentionally | A version pin was set instead of auto-update | Confirm the intended choice; switch to update management if you want auto-update |
| Still not advancing after a full cycle | Update cadence/behavior is Microsoft-defined | *Verify the current update-management behavior against Microsoft documentation* before concluding it's broken; then escalate |

## E. Detection mismatch (installed but shows Failed, or vice-versa)
- Catalog apps use **Microsoft's built-in detection rule**, so this is uncommon. Confirm on-device
  with `ENTAPPCAT-Test-Install.ps1` and compare to Intune's **Device install status**. If they
  disagree, capture the IME log and escalate — do **not** hand-author a detection rule over the
  catalog app unless Microsoft support directs it.

## F. Assignment scope / nothing deploys
| Symptom | Cause | Remediation |
|---|---|---|
| App assigned but no device installs | Assigned to an empty or wrong group | `ENTAPPCAT-Discovery.ps1` to see the bound groups; confirm `Catalog Apps – Pilot Devices – Ring 1` has members; use `ENTAPPCAT-Set-Assignment.ps1` (preview first) to (re)assign |
| IME not present | Enrollment/IME issue | The IME installs automatically once a Win32/catalog app or script is assigned; confirm enrollment, sync, and that the `Microsoft Intune Management Extension` service is running (`ENTAPPCAT-Test-Install.ps1`) |

## G. Government / national-cloud differences
- Enterprise App Catalog availability, portal URLs (e.g. `endpoint.microsoft.us`), and update
  behavior can **differ or lag** in GCC / GCC High / DoD. If a step or catalog app behaves
  differently, confirm you are using the correct portal and *verify catalog availability and behavior
  for your national cloud against current Microsoft documentation.*

## H. Diagnostics quick reference
```powershell
Get-Service -Name 'Microsoft Intune Management Extension'   # IME present/running
Get-ItemProperty 'HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall\*',
                 'HKLM:\SOFTWARE\WOW6432Node\Microsoft\Windows\CurrentVersion\Uninstall\*' |
  Select-Object DisplayName, DisplayVersion | Where-Object DisplayName -like '*Sample App*'
```
The IME log (`IntuneManagementExtension.log`) shows the download, install command, exit code, and
detection result per app — the first place to look.

## I. When to escalate
If the catalog app is present, assigned to the correct ring, the device is enrolled with a healthy
IME and synced, network endpoints are reachable, but Intune still reports Failed (or an update won't
apply) after a full policy/update cycle, collect the `IntuneManagementExtension.log` and open a
Microsoft support case — and use the "Intune App Deployment Troubleshooting & Failure Remediation"
product for the deep-dive break/fix workflow.
