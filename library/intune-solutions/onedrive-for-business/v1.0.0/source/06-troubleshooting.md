# 6. Troubleshooting Guide — OneDrive for Business

Work top to bottom. Most field issues are an unsynced policy, a missing/old OneDrive client, or a
KFM policy with the wrong (or missing) Tenant ID. Use **`ODFB-Validation.ps1`** to confirm state
and **`ODFB-Remediation.ps1`** for the safe fixes.

## A. Common deployment issues
| Symptom | Likely cause | Remediation |
|---|---|---|
| Profile shows **Error/Conflict** in Intune | Another OneDrive policy (GPO or second profile) conflicts | Keep one authoritative Settings Catalog profile; remove duplicate GPO/profile |
| Policy never reaches device | Device not synced / not enrolled | Run **`ODFB-Remediation.ps1`** (forces MDM sync); confirm device in **Devices → All devices** |
| Settings apply to nobody | Wrong assignment | Confirm `ODFB-Pilot` is under the profile's **Included groups** and users are members |

## B. Silent Sign-In failures
| Symptom | Cause | Remediation |
|---|---|---|
| OneDrive prompts the user to sign in | `SilentAccountConfig` not applied, or device not Entra joined | Confirm `dsregcmd /status` shows `AzureAdJoined : YES`; sync policy; check `SilentAccountConfig = 1` |
| Signs in to the wrong/personal account | Personal sync allowed | Enable **Prevent users from syncing personal OneDrive accounts** |
| Nothing happens at all | OneDrive client missing or outdated | Deploy/update the client (Implementation Step 9); run **`ODFB-Discovery.ps1`** |

## C. Known Folder Move (KFM) not applied
- **KFM policy value missing/blank** → the policy needs the **Tenant ID** GUID. Retrieve it with **`Get-TenantId.ps1`** and set it in the policy.
- **Folders still local** → confirm `KFMSilentOptIn` shows your Tenant ID (`ODFB-Validation.ps1`); a folder containing a OneDrive-incompatible item (e.g. a PST, OneNote, or a path too long) can block the move — resolve the blocking item, then re-sync.
- **"Make sure files are saved" / blocked** → an open file or unsupported file type in a known folder. Close apps; OneDrive retries automatically.

## D. Sync problems
- Run **`ODFB-Remediation.ps1`** (restart). If still broken, **`ODFB-Remediation.ps1 -ResetSync`** (re-initializes sync; cloud files are not deleted).
- Check the OneDrive activity center (cloud tray icon) for specific file errors (path too long >400 chars, invalid characters, file > size limit).
- Ensure the network/proxy is **not SSL-inspecting** OneDrive traffic — Microsoft does not support it and it breaks sync.

## E. Files On-Demand issues
- Status column not showing cloud badges → confirm `FilesOnDemandEnabled = 1` and a current client; Files On-Demand requires the modern client and NTFS.
- Users complain files won't open offline → teach **right-click → Always keep on this device** for must-have-offline files.

## F. Policy conflicts
- Only **one** OneDrive configuration source should be authoritative. Do not mix a legacy on-prem **GPO** (`HKLM\SOFTWARE\Policies\Microsoft\OneDrive`) and the Intune Settings Catalog profile — disable the GPO or scope it away from Intune-managed devices.

## G. Diagnostics quick reference
```powershell
dsregcmd /status                                   # Entra join (needed for Silent config + Tenant ID)
Get-ItemProperty 'HKLM:\SOFTWARE\Policies\Microsoft\OneDrive'   # applied OneDrive policy values
%LOCALAPPDATA%\Microsoft\OneDrive\OneDrive.exe /reset           # re-initialize sync (no cloud deletion)
```
Logs: `%LOCALAPPDATA%\Microsoft\OneDrive\logs`. Event logs: **Applications and Services Logs → Microsoft → Windows → Shell-Core / User Device Registration**.

## H. When to escalate
If a device passes **`ODFB-Discovery.ps1`** (supported OS, client present, Entra joined), the
profile shows **Succeeded**, the Tenant ID is correct, and KFM still won't apply after a sync
reset, collect the OneDrive logs and open a Microsoft 365 support case.
