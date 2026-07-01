<#
.SYNOPSIS
    MDE-Remediation.ps1 — safe remediation for Defender for Endpoint onboarding/sensor issues.
.DESCRIPTION
    PURPOSE
        Restarts the Sense service, forces an Intune/MDM sync (to re-apply the onboarding policy),
        and runs a quick Defender antivirus scan.
    HOW TO RUN
        Elevated: powershell -ExecutionPolicy Bypass -File .\MDE-Remediation.ps1
    EXPECTED RESULTS
        Sense restarted; MDM sync requested; quick scan started. Re-run MDE-Validation.ps1.
.NOTES
    Phoenixtekk Workplace Marketplace — Intune Solutions.
#>
[CmdletBinding(SupportsShouldProcess=$true)] param()
Write-Host "=== MDE Remediation — $($env:COMPUTERNAME) ===" -ForegroundColor Cyan
$sense = Get-Service Sense -ErrorAction SilentlyContinue
if ($sense) {
    if ($PSCmdlet.ShouldProcess('Sense','Restart')) { try { Restart-Service Sense -Force -ErrorAction Stop; Write-Host "  Sense restarted." -ForegroundColor Green } catch { Write-Host "  Could not restart Sense (may be service-protected): $($_.Exception.Message)" -ForegroundColor Yellow } }
} else { Write-Host "  Sense service not present — device is not onboarded; sync the onboarding policy." -ForegroundColor Yellow }
Start-Process -FilePath "$env:WINDIR\System32\deviceenroller.exe" -ArgumentList "/c /AutoEnrollMDM" -WindowStyle Hidden
Write-Host "  MDM sync requested (re-applies onboarding policy)." -ForegroundColor Green
try { Start-MpScan -ScanType QuickScan -ErrorAction SilentlyContinue; Write-Host "  Quick AV scan started." -ForegroundColor Green } catch {}
Write-Host "`nRe-run MDE-Validation.ps1 after a policy cycle." -ForegroundColor Green
