# 6. Troubleshooting Guide — AppLocker to WDAC (App Control for Business) Migration

Use `WDACMIG-Discovery.ps1` / `WDACMIG-Validation.ps1` for device state, `WDACMIG-Report.ps1` for
audit events and tenant coverage, and `WDACMIG-Remediation.ps1` (default -WhatIf) for a safe revert
to audit mode.

## A. Policy not applying
| Symptom | Cause | Remediation |
|---|---|---|
| No WDAC policy on device | Not assigned, not synced, or wrong group | Confirm `App Control – Fleet – Audit` is assigned to the device's ring group; sync; run `WDACMIG-Validation.ps1` |
| `App Control – Fleet – Audit` shows Error | Device not enrolled / not checked in | Confirm enrollment and ring-group membership; sync |
| Windows 10 shows no policy via citool | `citool` is Windows 11 only | Use `WDACMIG-Validation.ps1` (DeviceGuard WMI) for Windows 10 state |

## B. Legitimate app would be blocked (audit) or is blocked (enforce)
- Audit phase (Code Integrity 3076): expected — that is the point. Run `WDACMIG-Report.ps1`, then add
  trust: deploy the app via Intune (managed installer), rely on ISG, or add a translated signer/hash
  rule to `App Control – Migrated from AppLocker – Base`. Re-audit until clean.
- Enforce phase (Code Integrity 3077, app actually blocked): you enforced before the audit gate was
  clean. Roll back: unassign `App Control – Fleet – Enforce`, re-assign `App Control – Fleet – Audit`,
  run `WDACMIG-Remediation.ps1`, fix trust, then re-enforce.

## C. AppLocker still blocking after WDAC migration
| Symptom | Cause | Remediation |
|---|---|---|
| App blocked even though WDAC trusts it | AppLocker (coexisting) still denies it — most restrictive wins | This is expected during coexistence; once WDAC enforcement is validated on the ring, retire AppLocker (Step 8); until then, add an AppLocker allow rule or accept the block |
| Apps break right after AppLocker retirement | A gap WDAC did not cover that AppLocker had | Re-deploy AppLocker temporarily for coverage, run `WDACMIG-Report.ps1`, close the WDAC gap, then retire AppLocker again |

## D. Over-strict enforced policy / lockout risk
- Unassign `App Control – Fleet – Enforce` in Intune, re-assign `App Control – Fleet – Audit`, and run
  `WDACMIG-Remediation.ps1` (omit -WhatIf to apply) to revert the device to audit mode. A reboot may
  be required to fully clear a persistent policy.
- If the device cannot boot to a usable state, boot to recovery and remove the active policy from
  `%WINDIR%\System32\CodeIntegrity\CiPolicies\Active` (advanced), then re-sync.

## E. Managed-installer trust not taking effect
- Confirm the managed installer is enabled in the App Control for Business settings and the app was
  installed by Intune after that setting applied — files installed before tagging are not
  retroactively trusted. Re-deploy the app via Intune.

## F. Diagnostics quick reference
```powershell
Get-AppLockerPolicy -Effective -Xml                                  # current AppLocker policy
Get-CimInstance -Namespace root\Microsoft\Windows\DeviceGuard -ClassName Win32_DeviceGuard | Select CodeIntegrityPolicyEnforcementStatus, UsermodeCodeIntegrityPolicyEnforcementStatus
& "$env:WINDIR\System32\citool.exe" --list-policies                  # Windows 11 active policies
Get-WinEvent -FilterHashtable @{ LogName='Microsoft-Windows-CodeIntegrity/Operational'; Id=3076,3077 } -MaxEvents 50
Start-Process "$env:WINDIR\System32\deviceenroller.exe" -ArgumentList "/c /AutoEnrollMDM"   # MDM sync
```

## G. When to escalate
If the policy shows applied, the audit log is clean, the device is synced, and a legitimate app is
still blocked under enforcement after adding managed-installer/ISG/signer trust, collect the Code
Integrity 3077 events (`WDACMIG-Report.ps1 -CsvPath`) and the policy XML and open a Microsoft support
case.
