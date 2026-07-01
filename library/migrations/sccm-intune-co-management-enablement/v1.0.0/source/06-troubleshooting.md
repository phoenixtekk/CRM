# 6. Troubleshooting Guide — Configuration Manager and Intune Co-Management Enablement

Use `COMGMT-Validation.ps1` / `COMGMT-Discovery.ps1` for device state and `COMGMT-Report.ps1` for
fleet status, `COMGMT-Remediation.ps1` for safe fixes.

## A. Device not enrolling into Intune
| Symptom | Cause | Remediation |
|---|---|---|
| Pilot device never appears in Intune | Client not in the pilot collection, or policy not retrieved | Confirm membership of `Co-Management – Pilot Collection – Stage 1`; trigger Machine Policy Retrieval; run `COMGMT-Remediation.ps1` |
| Enrollment fails | Device not hybrid Entra joined / no Entra identity | Run `dsregcmd /status`; fix hybrid Entra join and Entra Connect sync |
| Enrollment fails | Automatic enrollment (MDM scope) not enabled | Entra to Mobility (MDM and MAM) to Microsoft Intune; set MDM user scope to Some/All |

## B. Co-management not enabling
| Symptom | Cause | Remediation |
|---|---|---|
| Co-management wizard blocked | Cloud attach (tenant attach) not connected | Console to Administration to Cloud Services to Cloud Attach; run the wizard and sign in as tenant admin |
| Configuration Manager too old | Unsupported branch | Update via Administration to Updates and Servicing; run `COMGMT-Discovery.ps1` |

## C. Workload moved but capability lapsed
- A workload set to Intune is owned by Intune. If no equivalent Intune policy is assigned, that
  capability is gone. Author and assign the Intune policy, then re-validate with `COMGMT-Report.ps1`.
- Roll back by moving the slider back to Configuration Manager (or Pilot Intune) while you build the
  policy.

## D. Workload authority looks wrong
- Run `COMGMT-Validation.ps1` on the device and `COMGMT-Report.ps1` for the fleet to see the
  authority per workload. Confirm the slider position in Co-management Properties to Workloads
  matches what you intended (Configuration Manager / Pilot Intune / Intune).

## E. Client health blocking onboarding
- Co-management depends on a healthy Configuration Manager client. In the console, check Client = Yes
  and Client Activity = Active; repair the client; run `COMGMT-Discovery.ps1`.

## F. Diagnostics quick reference
```powershell
dsregcmd /status                                  # Entra join + MDM URL
Get-ItemProperty 'HKLM:\SOFTWARE\Microsoft\CCM\CoManagementFlags' -EA SilentlyContinue   # co-management flags
Get-ComputerInfo | Select WindowsProductName, OsBuildNumber, WindowsVersion
```
Client logs: `CoManagementHandler.log` and `ComanagementWorkloadStatus` on the client
(`C:\Windows\CCM\Logs`).

## G. When to escalate
If co-management is enabled, the device is in the pilot collection, identity is healthy
(`dsregcmd /status` good), automatic enrollment is on, and the device still will not enroll after a
policy retrieval and `COMGMT-Remediation.ps1`, collect the client `CoManagementHandler.log` and open
a Microsoft support case.
