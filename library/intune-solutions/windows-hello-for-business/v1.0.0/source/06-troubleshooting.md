# 6. Troubleshooting Guide — Windows Hello for Business

Work top to bottom. Most field issues are an unsynced policy, a TPM that isn't ready, or a
hybrid device missing Microsoft Entra Kerberos. Use **`WHfB-Validation.ps1`** to confirm state
and **`WHfB-Remediation.ps1`** for the safe fixes.

## A. Common deployment issues
| Symptom | Likely cause | Remediation |
|---|---|---|
| Policy shows **Conflict** in Intune | The tenant-wide enrollment setting **and** the Account protection policy both configure WHfB | Set **Devices → Windows enrollment → Windows Hello for Business** to **Not configured**; keep only the targeted policy |
| Policy never reaches device | Device not synced / not enrolled | Run **`WHfB-Remediation.ps1`** (forces MDM sync); confirm device in **Devices → All devices** |
| Settings apply to nobody | Wrong assignment | Confirm the pilot group is under the policy's **Included groups** and users/devices are members |

## B. Enrollment failures
| Symptom | Cause | Remediation |
|---|---|---|
| No "Set up a PIN" prompt at sign-in | Policy not yet applied, or user already enrolled | Sync (**`WHfB-Remediation.ps1`**), then sign out/in; check `NgcSet : YES` via `dsregcmd /status` |
| "Something went wrong" during PIN setup | TPM not ready, or transient | Run **`WHfB-Discovery.ps1`** to confirm TPM ready; reboot; retry |
| Error code **0x801c03ed** | MFA not satisfied / registration blocked | Ensure the user has completed MFA registration; check Conditional Access isn't blocking device registration |

## C. PIN provisioning failures
- Confirm **Minimum PIN length** policy matches what the user is typing (this solution sets 6).
- If PIN setup loops, run **`WHfB-Remediation.ps1 -ResetContainer`** to clear the local Hello container, then sign out/in.
- Verify the user has a valid Intune + Entra license assigned.

## D. TPM issues
- **`Get-Tpm`** shows `TpmReady : False` → enable/clear TPM in UEFI (Intel **PTT** / AMD **fTPM**); allow it to initialize.
- TPM "in a reduced functionality state" → in `tpm.msc` choose **Clear TPM** (warns it will reset TPM-protected keys; coordinate with BitLocker — have the recovery key first).
- No TPM at all → policy requires TPM (we set **Use TPM: Yes**), so the device will not provision; remediate hardware or exclude the device.

## E. Policy conflicts
- Only **one** WHfB source should be authoritative. Do not mix the tenant-wide enrollment setting, a legacy GPO, and the Intune Account protection policy.
- Legacy on-prem **GPO** "Use Windows Hello for Business" can override Intune on hybrid devices — disable the GPO or scope it away from Intune-managed devices.

## F. Hybrid identity issues (Cloud Kerberos Trust)
| Symptom | Cause | Remediation |
|---|---|---|
| WHfB sign-in works, but **on-prem shares/printers prompt** or fail | Microsoft Entra Kerberos not enabled for the domain | Run **`Enable-EntraKerberos.ps1`** once per domain; confirm with `Get-AzureADKerberosServer` |
| `klist` shows no TGT after resource access | Device has no line-of-sight to a DC | Connect to corporate network/VPN; verify `nltest /dsgetdc:<domain>` |
| Cloud Kerberos Trust setting not applied | Policy/OS build too old | Ensure Win10 21H2+/Win11 with current updates and the **Cloud Kerberos Trust** setting **Enabled** |

## G. Diagnostics quick reference
```powershell
dsregcmd /status            # Device State + NgcSet (WHfB key) + SSO state
Get-Tpm                     # TPM presence/readiness
certutil -deletehellocontainer   # clear local Hello container (forces re-enroll)
klist                       # Kerberos tickets (hybrid)
```
Event logs: **Applications and Services Logs → Microsoft → Windows → User Device Registration**
and **… → HelloForBusiness**.

## H. When to escalate
If a device passes **`WHfB-Discovery.ps1`** (TPM ready, supported OS, Entra joined), the policy
shows **Succeeded**, and enrollment still fails after a container reset, collect the
**HelloForBusiness** and **User Device Registration** event logs and open a Microsoft support case.
