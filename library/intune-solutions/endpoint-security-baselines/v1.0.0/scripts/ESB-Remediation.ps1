<#
.SYNOPSIS
    ESB-Remediation.ps1 — force a policy sync so the security baseline re-applies.
.DESCRIPTION
    PURPOSE
        Triggers an Intune/MDM sync and restarts the relevant scheduled task so a pending or
        not-yet-applied baseline is re-evaluated. It does not change settings directly.
    HOW TO RUN
        powershell -ExecutionPolicy Bypass -File .\ESB-Remediation.ps1
    EXPECTED RESULTS
        MDM sync requested; re-run ESB-Validation.ps1 after a policy cycle.
.NOTES
    Phoenixtekk Workplace Marketplace — Intune Solutions.
#>
[CmdletBinding()] param()
Write-Host "=== Baseline Remediation — $($env:COMPUTERNAME) ===" -ForegroundColor Cyan
Start-Process -FilePath "$env:WINDIR\System32\deviceenroller.exe" -ArgumentList "/c /AutoEnrollMDM" -WindowStyle Hidden
Get-ScheduledTask -TaskPath '\Microsoft\Windows\EnterpriseMgmt\*' -ErrorAction SilentlyContinue |
    Where-Object { $_.TaskName -match 'Schedule' } | Start-ScheduledTask -ErrorAction SilentlyContinue
Write-Host "MDM sync requested. Re-run ESB-Validation.ps1 after a policy cycle." -ForegroundColor Green
Write-Host "If settings still won't apply, check Intune per-setting status for Conflict (ESB-ConflictCheck.ps1)." -ForegroundColor Gray
