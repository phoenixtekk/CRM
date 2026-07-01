<#
.SYNOPSIS
    CAI-Discovery.ps1 — local device/identity state relevant to Conditional Access.
.DESCRIPTION
    PURPOSE
        Reports the local facts CA decisions depend on: Microsoft Entra join/registration state,
        device compliance hint, and whether the work account SSO state is present.
    HOW TO RUN
        powershell -ExecutionPolicy Bypass -File .\CAI-Discovery.ps1
    EXPECTED RESULTS
        A summary of join state and SSO; use it to predict how CA "device" controls will treat the device.
.NOTES
    Phoenixtekk Workplace Marketplace — Intune Solutions. Read-only.
#>
[CmdletBinding()] param()
Write-Host "=== Conditional Access — device state ($($env:COMPUTERNAME)) ===" -ForegroundColor Cyan
$dsreg = (dsregcmd /status) 2>$null
foreach ($k in 'AzureAdJoined','DomainJoined','WorkplaceJoined','MdmUrl','AzureAdPrt') {
    $line = ($dsreg | Select-String "^\s*$k\s*:") | Select-Object -First 1
    if ($line) { Write-Host ("  {0}" -f $line.Line.Trim()) }
}
$aad = ($dsreg | Select-String 'AzureAdJoined\s*:\s*YES') -ne $null
$prt = ($dsreg | Select-String 'AzureAdPrt\s*:\s*YES') -ne $null
Write-Host ""
Write-Host ("Entra joined : {0}" -f ($(if($aad){'YES'}else{'NO'}))) -ForegroundColor ($(if($aad){'Green'}else{'Yellow'}))
Write-Host ("PRT present  : {0} (needed for seamless SSO + device-based CA)" -f ($(if($prt){'YES'}else{'NO'}))) -ForegroundColor ($(if($prt){'Green'}else{'Yellow'}))
if (-not $aad) { Write-Host "Device is not Entra joined — 'require compliant/joined device' CA policies will block it." -ForegroundColor Yellow }
