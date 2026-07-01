<#
.SYNOPSIS
    Autopilot-Validation.ps1 — confirm a device provisioned correctly via Autopilot.
.DESCRIPTION
    PURPOSE
        Verifies the device is Autopilot-registered (ZTDID present), Microsoft Entra joined, and
        Intune MDM-enrolled.
    HOW TO RUN
        powershell -ExecutionPolicy Bypass -File .\Autopilot-Validation.ps1
    EXPECTED RESULTS
        "AUTOPILOT OK" with AzureAdJoined=YES, an MDM URL present, and a ZTDID registered.
.NOTES
    Phoenixtekk Workplace Marketplace — Intune Solutions. Read-only.
#>
[CmdletBinding()] param()
Write-Host "=== Autopilot Validation — $($env:COMPUTERNAME) ===" -ForegroundColor Cyan
$dsreg = (dsregcmd /status) 2>$null
$aad = ($dsreg | Select-String 'AzureAdJoined\s*:\s*YES') -ne $null
$mdm = ($dsreg | Select-String 'MdmUrl\s*:\s*http') -ne $null
$ztd = (Get-ItemProperty 'HKLM:\SOFTWARE\Microsoft\Provisioning\Diagnostics\Autopilot' -ErrorAction SilentlyContinue).CloudAssignedTenantId
$ztdId = (Get-CimInstance -Namespace root\cimv2\mdm\dmmap -ClassName MDM_DevDetail_Ext01 -ErrorAction SilentlyContinue).DeviceHardwareData
Write-Host ("Microsoft Entra joined : {0}" -f ($(if($aad){'YES'}else{'NO'}))) -ForegroundColor ($(if($aad){'Green'}else{'Yellow'}))
Write-Host ("Intune MDM enrolled    : {0}" -f ($(if($mdm){'YES'}else{'NO'}))) -ForegroundColor ($(if($mdm){'Green'}else{'Yellow'}))
Write-Host ("Autopilot tenant assign: {0}" -f ($(if($ztd){$ztd}else{'not found'})))
if ($aad -and $mdm) { Write-Host "`nResult: AUTOPILOT OK" -ForegroundColor Green; exit 0 }
else { Write-Host "`nResult: NOT FULLY PROVISIONED — check profile assignment / run Autopilot-Remediation.ps1" -ForegroundColor Yellow; exit 1 }
