# 6. Troubleshooting Guide — Intune Custom Compliance & Configuration Items (Scripted)

Use `CUSTCOMP-Discovery.ps1` for device-side values, `CUSTCOMP-Validation.ps1` for the script/rule
pairing, `CUSTCOMP-Report.ps1` for fleet status, and `CUSTCOMP-Remediation.ps1` for a safe sync.

## A. Custom compliance shows Error (not pass/fail)
| Symptom | Cause | Remediation |
|---|---|---|
| Device shows Error on the custom rule | Detection script threw, or returned invalid JSON | Run `CUSTCOMP-Discovery.ps1`; confirm the script returns valid single-line JSON; run `CUSTCOMP-Validation.ps1` |
| "Setting not found" style result | Rule setting name not emitted by the script | Align the rule `SettingName` values with the script's JSON property names |
| Script never runs | Signature check on, script unsigned; or not 64-bit | Sign the script or adjust the signature setting; ensure `Run in 64-bit PowerShell` = Yes |

## B. Rule always fails (or always passes)
| Symptom | Cause | Remediation |
|---|---|---|
| Value looks right but rule fails | Wrong `DataType`/`Operator` (e.g. Version vs String) | Match the rule `DataType` to what the script returns; use `Version` for app versions |
| Rule passes when it shouldn't | Script returns null/empty and the operator tolerates it | Have the script return a definite value; test with a device that should fail |

## C. Config item not taking effect
- Confirm `SecuritySetting – Config Item – Pilot` shows Succeeded under Device status; the setting the
  custom rule checks must be applied by the config item (or otherwise present) before the rule can pass.
- Sync the device (`CUSTCOMP-Remediation.ps1`) and allow a policy cycle before re-evaluating.

## D. Compliance state not updating
- Custom compliance re-evaluates on the device's schedule; force a sync with `CUSTCOMP-Remediation.ps1`
  and wait a policy cycle. Confirm the device is enrolled, checked in, and in the assigned group.

## E. Conditional Access not blocking / over-blocking
- If a noncompliant device is not blocked, confirm the Conditional Access policy is On (not
  Report-only) and targets the right users, and that it requires a compliant device.
- If devices are blocked unexpectedly, move the CA policy back to Report-only and fix the failing rule
  first; a custom-rule Error counts as noncompliant.

## F. Diagnostics quick reference
```powershell
Get-ComputerInfo | Select WindowsProductName, OsBuildNumber, WindowsVersion
Get-ItemProperty 'HKLM:\SOFTWARE\Contoso\Security' -EA SilentlyContinue   # the checked registry value
Get-ExecutionPolicy -List                                                 # signing/execution posture
Start-Process "$env:WINDIR\System32\deviceenroller.exe" -ArgumentList "/c /AutoEnrollMDM"   # MDM sync
```
IME logs (device-side script/compliance execution): `C:\ProgramData\Microsoft\IntuneManagementExtension\Logs`.

## G. When to escalate
If the script returns valid JSON locally, the rule pairing validates, the config item shows
Succeeded, and the device is synced and in the assigned group but the custom result still shows Error
after a policy cycle, collect the IntuneManagementExtension logs and open a Microsoft support case.
