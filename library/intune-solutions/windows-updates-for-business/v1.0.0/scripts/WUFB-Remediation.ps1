<#
.SYNOPSIS
    WUFB-Remediation.ps1 — force a policy sync and a Windows Update scan.
.DESCRIPTION
    PURPOSE
        Triggers an Intune/MDM sync so the update ring re-applies, then kicks a Windows Update scan
        (USO) so the device re-evaluates available updates. Reports a WSUS conflict if present.
    HOW TO RUN
        Elevated: powershell -ExecutionPolicy Bypass -File .\WUFB-Remediation.ps1
    EXPECTED RESULTS
        MDM sync + update scan requested. Re-run WUFB-Validation.ps1 after a policy cycle.
.NOTES
    White-label — Intune Solutions.
#>
[CmdletBinding()] param()
Write-Host "=== WUfB Remediation — $($env:COMPUTERNAME) ===" -ForegroundColor Cyan
$wsus = (Get-ItemProperty 'HKLM:\SOFTWARE\Policies\Microsoft\Windows\WindowsUpdate\AU' -EA SilentlyContinue).UseWUServer
if ($wsus -eq 1) { Write-Host "  WARNING: WSUS authority present — cloud WUfB updates will be blocked until it is removed." -ForegroundColor Yellow }
Start-Process -FilePath "$env:WINDIR\System32\deviceenroller.exe" -ArgumentList "/c /AutoEnrollMDM" -WindowStyle Hidden
Write-Host "  MDM sync requested." -ForegroundColor Green
try {
    if (Test-Path "$env:WINDIR\System32\UsoClient.exe") { & "$env:WINDIR\System32\UsoClient.exe" StartScan; Write-Host "  Windows Update scan (USO) started." -ForegroundColor Green }
    else { (New-Object -ComObject Microsoft.Update.AutoUpdate).DetectNow(); Write-Host "  Update detection triggered." -ForegroundColor Green }
} catch { Write-Host "  Scan trigger skipped: $($_.Exception.Message)" -ForegroundColor Yellow }
Write-Host "`nRe-run WUFB-Validation.ps1 after a policy cycle." -ForegroundColor Green
