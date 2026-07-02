<#
.SYNOPSIS
    Autopilot-Remediation.ps1 — safe remediation for Autopilot enrollment/sync issues.
.DESCRIPTION
    PURPOSE
        Forces an Intune/MDM policy sync and re-triggers auto-enrollment. Optionally (gated)
        initiates a remote Autopilot reset path note for stuck devices.
    HOW TO RUN
        Standard (safe): powershell -ExecutionPolicy Bypass -File .\Autopilot-Remediation.ps1
    EXPECTED RESULTS
        MDM sync requested; device should re-evaluate enrollment/policies at next cycle.
.NOTES
    White-label — Intune Solutions.
#>
[CmdletBinding()] param()
Write-Host "=== Autopilot Remediation — $($env:COMPUTERNAME) ===" -ForegroundColor Cyan
Write-Host "Triggering Intune/MDM policy sync..."
try {
    Start-Process -FilePath "$env:WINDIR\System32\deviceenroller.exe" -ArgumentList "/c /AutoEnrollMDM" -WindowStyle Hidden
    Write-Host "  MDM sync requested." -ForegroundColor Green
} catch { Write-Host "  Sync step skipped: $($_.Exception.Message)" -ForegroundColor Yellow }
# kick the scheduled enrollment task if present
Get-ScheduledTask -TaskPath '\Microsoft\Windows\EnterpriseMgmt\*' -ErrorAction SilentlyContinue |
    Start-ScheduledTask -ErrorAction SilentlyContinue
Write-Host "`nStandard remediation complete. Re-run Autopilot-Validation.ps1 after a policy cycle." -ForegroundColor Green
Write-Host "If the device is unrecoverable, use Intune > Device > Autopilot reset, or reset and re-provision." -ForegroundColor Gray
