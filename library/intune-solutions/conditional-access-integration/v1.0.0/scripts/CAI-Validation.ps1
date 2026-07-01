<#
.SYNOPSIS
    CAI-Validation.ps1 — confirm this device will satisfy device-based Conditional Access controls.
.DESCRIPTION
    PURPOSE
        Checks that the device is Microsoft Entra joined and has a Primary Refresh Token (PRT),
        the conditions a "require compliant / Entra-joined device" CA policy depends on.
    HOW TO RUN
        powershell -ExecutionPolicy Bypass -File .\CAI-Validation.ps1
    EXPECTED RESULTS
        "DEVICE CA-READY" when Entra joined and PRT present.
.NOTES
    Phoenixtekk Workplace Marketplace — Intune Solutions. Read-only. Compliance state is authoritative in Intune.
#>
[CmdletBinding()] param()
Write-Host "=== Conditional Access Validation — $($env:COMPUTERNAME) ===" -ForegroundColor Cyan
$dsreg = (dsregcmd /status) 2>$null
$aad = ($dsreg | Select-String 'AzureAdJoined\s*:\s*YES') -ne $null
$prt = ($dsreg | Select-String 'AzureAdPrt\s*:\s*YES') -ne $null
$mdm = ($dsreg | Select-String 'MdmUrl\s*:\s*http') -ne $null
Write-Host ("Entra joined : {0}" -f ($(if($aad){'YES'}else{'NO'}))) -ForegroundColor ($(if($aad){'Green'}else{'Yellow'}))
Write-Host ("PRT present  : {0}" -f ($(if($prt){'YES'}else{'NO'}))) -ForegroundColor ($(if($prt){'Green'}else{'Yellow'}))
Write-Host ("MDM enrolled : {0}" -f ($(if($mdm){'YES'}else{'NO'})))
if ($aad -and $prt) { Write-Host "`nResult: DEVICE CA-READY" -ForegroundColor Green; exit 0 }
else { Write-Host "`nResult: NOT CA-READY — device-based CA policies will challenge/block this device" -ForegroundColor Yellow; exit 1 }
