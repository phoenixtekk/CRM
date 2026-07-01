# 6. Troubleshooting Guide — Endpoint Privilege Management (EPM)

Work top to bottom. Most field issues are a **missing EPM license**, a base policy that hasn't
synced, or an elevation rule whose certificate/hash doesn't match the binary. Use
**`EPM-Discovery.ps1`** / **`EPM-Validation.ps1`** to confirm state and **`EPM-Remediation.ps1`** for
the safe fixes.

## A. License & availability issues
| Symptom | Likely cause | Remediation |
|---|---|---|
| EPM node shows only a **purchase/trial** prompt | No Intune Suite / EPM add-on owned | Purchase EPM (Requirements §2.1); confirm in **M365 admin → Billing** |
| Policy targets a user but **never applies** | User has **no EPM license** | Assign the **Intune Suite / EPM** license to the user (or a licensing group); allow propagation |
| Worked for some users, not others | License assigned to only part of the pilot | Confirm every pilot user is licensed; re-sync the device |

## B. Client (extension) install issues
| Symptom | Cause | Remediation |
|---|---|---|
| `Get-Service EPMAgent` not found / agent folder missing | Base policy not applied yet | Confirm `EPM - Base - Pilot` is assigned and **Succeeded**; force sync with **`EPM-Remediation.ps1`** |
| Service present but **Stopped** | Transient / client unhealthy | Run **`EPM-Remediation.ps1`** (restarts the service); reboot; re-check with **`EPM-Discovery.ps1`** |
| Client never reports data | Network blocking EPM/Intune endpoints | Allow Microsoft Intune/EPM URLs through proxy/firewall (Requirements §2.5) |

## C. Policy not applying
| Symptom | Cause | Remediation |
|---|---|---|
| Base/rules policy shows **Error** or **Conflict** | Two policies set conflicting EPM defaults | Keep **one** authoritative base policy; resolve the conflicting setting |
| Settings apply to nobody | Wrong assignment | Confirm `EPM-Pilot` is under **Included groups** and the user/device is a member |
| Changes don't take effect | Device not synced | **`EPM-Remediation.ps1`** forces an MDM sync; confirm in **Devices → All devices** |

## D. Elevation rule not matching (app won't elevate)
- Confirm the **file name** in the rule exactly matches the executable.
- Re-run **`New-EpmElevationRule.ps1 -Path "<app.exe>"`** and compare the **certificate**/**SHA-256
  hash** to the rule — a single byte difference (e.g. after an app update) breaks a **hash** rule.
  Switch signed apps to a **certificate** rule so updates keep working.
- Confirm the rules policy is **assigned** and shows **Succeeded** for the device.
- Make sure the user used **Run with elevated access** (right-click), not a plain double-click.

## E. App elevates when it shouldn't (too permissive)
- Find the offending rule — an over-broad **Automatic** rule or a wildcard match. Tighten it to a
  specific signer/hash and switch to **User confirmed**.
- Set the **default elevation response** to **Deny all requests** so only explicit rules elevate.
- Restrict **child process** behavior so an elevated installer can't spawn an admin shell.

## F. Support-approved requests stuck
| Symptom | Cause | Remediation |
|---|---|---|
| User's request never approved | No admin reviewing the queue | Approve in Intune → **Endpoint Privilege Management** → the elevation request; assign an approver role |
| Approval granted but app still blocked | Device hasn't synced the approval | Force sync (**`EPM-Remediation.ps1`**); retry the elevation |

## G. Reporting gaps
- No elevations in **Reports** → confirm the base policy has **Send elevation data for reporting:
  Yes** and a **reporting scope** that includes the events you expect.
- `EPM-ElevationReport.ps1` returns nothing → confirm Graph permissions/consent and that reporting
  has had time to upload (allow for the reporting interval).

## H. Diagnostics quick reference
```powershell
Get-Service EPMAgent                       # EPM client service state
Test-Path "C:\Program Files\Microsoft EPM Agent"   # client installed?
dsregcmd /status                           # Entra join / device state
net localgroup administrators              # who is still a local admin
.\EPM-Discovery.ps1                        # full readiness/health summary
.\EPM-Remediation.ps1                      # force sync + restart client
```
Event logs: **Applications and Services Logs → Microsoft → Windows → AAD** (device registration) and
the EPM client logs under the agent folder.

## I. When to escalate
If a device passes **`EPM-Discovery.ps1`** (licensed, client running, Entra joined), the base/rules
policies show **Succeeded**, the rule's certificate/hash matches, and an approved app still fails to
elevate, collect the EPM client logs and the policy check-in status and open a Microsoft support case.
