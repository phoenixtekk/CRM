# 6. Troubleshooting Guide — Windows Autopilot

Use **`Autopilot-Validation.ps1`** to confirm state and **`Autopilot-Remediation.ps1`** for safe fixes.

## A. Device doesn't get the Autopilot experience
| Symptom | Cause | Remediation |
|---|---|---|
| OOBE looks generic (no branding) | Device not registered, or profile not assigned | Confirm the hardware hash is imported and **Profile status = Assigned**; re-image/reset and retry |
| Profile stuck "Assigning" | Dynamic group hasn't picked up the device | Wait for group processing; confirm the dynamic rule `[ZTDId]`; force a group refresh |
| Wrong tenant prompt | Company branding missing/incorrect | Configure Entra **Company branding** |

## B. OOBE / network failures
| Symptom | Cause | Remediation |
|---|---|---|
| "Something went wrong" at OOBE | No internet / blocked endpoints | Provide OOBE network; allow Autopilot/Entra/Intune URLs; avoid pre-logon 802.1X |
| Sign-in fails | Licensing or auto-enrollment not set | Confirm user license and **MDM user scope = All** |

## C. Enrollment Status Page issues
- **ESP times out** → too many/large required apps. Reduce required apps for the pilot; raise the timeout; mark non-critical apps as not blocking.
- **ESP blocks on a failing app** → fix or remove the failing required app from the ESP scope.

## D. Hardware hash / import
- **Import errors** → ensure the CSV is the unmodified `Get-AutopilotHash.ps1` output (correct columns); remove duplicates already registered.
- **Device not appearing** → Sync (**Devices → Enrollment → Devices → Sync**) and wait.

## E. Diagnostics quick reference
```powershell
dsregcmd /status                     # Entra join / MDM state
Get-WindowsAutopilotInfo -Online     # (admin) view/register this device's hash
```
OOBE diagnostics: press **Shift+F10** during OOBE for a command prompt; collect MDM diagnostics via **Settings → Accounts → Access work or school → Export**.

## F. When to escalate
If the device is registered, the profile shows **Assigned**, networking is open, and OOBE still
fails, collect the Autopilot/MDM diagnostic logs and open a Microsoft support case.
