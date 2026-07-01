<#
.SYNOPSIS
    WUFB-Validation.ps1 — confirm an Intune update ring policy has applied to this device.
.DESCRIPTION
    PURPOSE
        Verifies the Windows Update for Business policy is present (deferral/deadline values written
        by the Intune update ring) and that no WSUS authority is overriding it.
    HOW TO RUN
        Elevated: powershell -ExecutionPolicy Bypass -File .\WUFB-Validation.ps1
    EXPECTED RESULTS
        "UPDATE RING APPLIED" when deferral/deadline policy is present and no WSUS conflict exists.
.NOTES
    Phoenixtekk Workplace Marketplace — Intune Solutions. Read-only.
#>
[CmdletBinding()] param()
Write-Host "=== WUfB Validation — $($env:COMPUTERNAME) ===" -ForegroundColor Cyan
$wu = 'HKLM:\SOFTWARE\Policies\Microsoft\Windows\WindowsUpdate'
$p = Get-ItemProperty $wu -ErrorAction SilentlyContinue
$hasPolicy = $p -and (($p.PSObject.Properties.Name -contains 'DeferQualityUpdatesPeriodInDays') -or ($p.PSObject.Properties.Name -contains 'SetEDURestart') -or $p.DeferFeatureUpdatesPeriodInDays -ne $null)
$wsus = (Get-ItemProperty "$wu\AU" -ErrorAction SilentlyContinue).UseWUServer
Write-Host ("Update policy present : {0}" -f ($(if($hasPolicy){'YES'}else{'NO'}))) -ForegroundColor ($(if($hasPolicy){'Green'}else{'Yellow'}))
Write-Host ("Quality deferral      : {0} days" -f ($(if($p){$p.DeferQualityUpdatesPeriodInDays}else{'-'})))
Write-Host ("Feature deferral      : {0} days" -f ($(if($p){$p.DeferFeatureUpdatesPeriodInDays}else{'-'})))
Write-Host ("WSUS conflict         : {0}" -f ($(if($wsus -eq 1){'YES (remove)'}else{'none'}))) -ForegroundColor ($(if($wsus -eq 1){'Yellow'}else{'Green'}))
if ($hasPolicy -and $wsus -ne 1) { Write-Host "`nResult: UPDATE RING APPLIED" -ForegroundColor Green; exit 0 }
else { Write-Host "`nResult: NOT FULLY APPLIED — sync (WUFB-Remediation.ps1) / remove WSUS / check assignment" -ForegroundColor Yellow; exit 1 }
