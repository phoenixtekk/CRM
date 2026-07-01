<#
.SYNOPSIS
    W11HC-Remediation.ps1 - safe remediation; force an MDM sync so the baseline re-applies.
.DESCRIPTION
    PURPOSE
        Triggers an Intune/MDM sync so the Windows 11 baseline profiles, security baseline, update
        ring, and power profile re-evaluate and re-apply on the device. Warns if a legacy update
        authority is present (which would block the cloud baseline). This script changes device state
        only by requesting a sync, so it defaults to -WhatIf - re-run with -Confirm:$false to act.
    HOW TO RUN
        Preview (default): powershell -ExecutionPolicy Bypass -File .\W11HC-Remediation.ps1
        Apply:             powershell -ExecutionPolicy Bypass -File .\W11HC-Remediation.ps1 -Confirm:$false
    EXPECTED RESULTS
        In preview, the actions it would take. When applied, an MDM sync is requested; re-run
        W11HC-Validation.ps1 after a policy cycle.
.NOTES
    Healthcare Solutions - Windows 11 endpoint baseline. Defaults to -WhatIf.
#>
[CmdletBinding(SupportsShouldProcess=$true, ConfirmImpact='Medium')]
param()
$PSDefaultParameterValues['*:WhatIf'] = $true
Write-Host "=== W11HC Remediation - $($env:COMPUTERNAME) ===" -ForegroundColor Cyan
$useWsus = (Get-ItemProperty 'HKLM:\SOFTWARE\Policies\Microsoft\Windows\WindowsUpdate\AU' -ErrorAction SilentlyContinue).UseWUServer
if ($useWsus -eq 1) { Write-Host "  WARNING: legacy update authority present - the cloud baseline update ring will be blocked until it is removed." -ForegroundColor Yellow }
if ($PSCmdlet.ShouldProcess($env:COMPUTERNAME, "Request MDM sync to re-apply the Windows 11 baseline")) {
    Start-Process -FilePath "$env:WINDIR\System32\deviceenroller.exe" -ArgumentList "/c /AutoEnrollMDM" -WindowStyle Hidden
    Write-Host "  MDM sync requested." -ForegroundColor Green
    Write-Host "  Re-run W11HC-Validation.ps1 after a policy cycle." -ForegroundColor Green
} else {
    Write-Host "  [WhatIf] Would request an MDM sync (deviceenroller.exe /c /AutoEnrollMDM)." -ForegroundColor Yellow
    Write-Host "  Re-run with -Confirm:`$false to apply." -ForegroundColor Yellow
}
