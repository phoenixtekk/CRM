<#
.SYNOPSIS
    RHELP-Remediation.ps1 — force an app/policy sync to (re)install the Remote Help app.
.DESCRIPTION
    PURPOSE
        Triggers an Intune/MDM sync so a pending Remote Help app assignment installs, and reports
        whether the app is present afterward. It does not install the app directly (Intune does).
    HOW TO RUN
        powershell -ExecutionPolicy Bypass -File .\RHELP-Remediation.ps1
    EXPECTED RESULTS
        MDM sync requested; re-run RHELP-Validation.ps1 after the app delivers.
.NOTES
    White-label — Intune Solutions.
#>
[CmdletBinding()] param()
Write-Host "=== Remote Help Remediation — $($env:COMPUTERNAME) ===" -ForegroundColor Cyan
Start-Process -FilePath "$env:WINDIR\System32\deviceenroller.exe" -ArgumentList "/c /AutoEnrollMDM" -WindowStyle Hidden
Write-Host "  MDM sync requested (delivers the Remote Help app assignment)." -ForegroundColor Green
$app = @("$env:ProgramFiles\Remote help\remotehelp.exe","${env:ProgramFiles(x86)}\Remote help\remotehelp.exe") | Where-Object { Test-Path $_ } | Select-Object -First 1
Write-Host ("  Remote Help app currently: {0}" -f ($(if($app){'installed'}else{'not yet installed'})))
Write-Host "`nIf still missing after a sync cycle, confirm the app is assigned (Required) to this device's group in Intune > Apps." -ForegroundColor Gray
