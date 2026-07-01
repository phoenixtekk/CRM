# 6. Troubleshooting Guide — Group Policy to Intune Settings Migration

Use **`GPOM-Discovery.ps1`** for GPO inventory and conflicting-authority detection,
**`GPOM-Validation.ps1`** for settings parity and precedence state, **`GPOM-Report.ps1`** for
coverage/gaps, and **`GPOM-Remediation.ps1`** (`-WhatIf` first) for safe conflict resolution.

## A. Migrated settings don't apply (GPO still winning)
| Symptom | Cause | Remediation |
|---|---|---|
| Intune policy shows Succeeded but the device behaves per the old GPO | `MDMWinsOverGP` not set — GPO wins by default | Deploy `GPO Migration – MDM Wins Over GP – All Migrated` (Step 7); re-run `GPOM-Validation.ps1` |
| A migrated setting is still controlled by AD | Legacy GPO still scoped to the device | Scope/unlink the legacy GPO from migrated devices; `GPOM-Discovery.ps1` flags it |
| Mixed results across devices | Device not synced / not in the ring group | Sync the device; confirm membership in `GPO Migration – Devices – Pilot Ring` |

## B. Group Policy analytics import / readiness issues
| Symptom | Cause | Remediation |
|---|---|---|
| Import fails or shows nothing | Wrong export type (not a GPO backup) | Re-export with **GPMC → Back Up** or `GPOM-Discovery.ps1` (`Get-GPOReport`), then re-import |
| Readiness % lower than expected | GPO has many preferences/scripts/security settings | Expected — handle the unsupported settings in Step 6; `GPOM-Report.ps1` lists them |
| Setting shows "Needs review" | Analytics can't auto-map it | Review the source value and re-implement in the settings catalog or another surface |

## C. Unsupported settings (no direct Intune equivalent)
- **Group Policy Preferences** (drive maps, registry items, printers) → re-implement via a
  **platform script** (Devices → Scripts), a **proactive remediation**, Universal Print, or retire.
- **Logon/startup scripts** → replace with a platform script or proactive remediation.
- **Some security settings** → use an **endpoint security** profile or the security baseline instead
  of the settings catalog. Record every decision in the gap report.

## D. Settings catalog / imported ADMX problems
| Symptom | Cause | Remediation |
|---|---|---|
| ADMX setting can't be found in the catalog | Vendor ADMX not imported | **Import ADMX** (Step 5); wait for **Available**, then add the imported template policy |
| Policy error / conflict on device | Two Intune policies set the same setting differently | Consolidate; remove the duplicate; `GPOM-Validation.ps1` highlights the mismatch |
| Imported ADMX stuck "Uploading" | Mismatched/old `.admx`/`.adml` pair | Re-import a matching ADMX+ADML pair from the current vendor package |

## E. Coexistence drift (double authority)
- A setting owned by **both** GPO and Intune long-term causes flapping. Fix by enforcing one
  authority: keep `MDMWinsOverGP` on **and** scope the legacy GPO away for that area. Run
  `GPOM-Remediation.ps1 -WhatIf` to preview the precedence fix before applying.

## F. Diagnostics quick reference
```powershell
Get-GPO -All | Select-Object DisplayName, Id, GpoStatus          # GPO inventory (GroupPolicy module)
Get-GPOReport -Name 'Your GPO' -ReportType Xml -Path .\gpo.xml   # export a GPO for analytics
Get-ItemProperty 'HKLM:\SOFTWARE\Microsoft\PolicyManager\current\device\ControlPolicyConflict' -EA SilentlyContinue  # MDMWinsOverGP
gpresult /h gpresult.html                                        # what GPO is still applying on the device
```
MDM diagnostics: **Settings → Accounts → Access work or school → Info → Create report**, or
`mdmdiagnosticstool.exe -area DeviceEnrollment -cab C:\Temp\mdm.cab`.

## G. When to escalate
If the Intune policy shows Succeeded, `MDMWinsOverGP` is confirmed, the legacy GPO is scoped away,
the device is synced and in the correct ring group, and a migrated setting still won't take effect,
collect `GPOM-Validation.ps1` output plus `gpresult /h` and the MDM diagnostics CAB and open a
Microsoft support case.
