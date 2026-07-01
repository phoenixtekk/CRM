<#
.SYNOPSIS
    ASR-Remediation.ps1 — ensure Defender AV is active and force a policy sync so ASR applies.
.DESCRIPTION
    PURPOSE
        ASR rules only work when Defender Antivirus is active with real-time protection. This
        re-enables real-time protection if off and forces an Intune/MDM sync. It does not change
        ASR rule actions (those are set by Intune policy).
    HOW TO RUN
        Elevated: powershell -ExecutionPolicy Bypass -File .\ASR-Remediation.ps1
    EXPECTED RESULTS
        Real-time protection on; MDM sync requested. Re-run ASR-Validation.ps1.
.NOTES
    Phoenixtekk Workplace Marketplace — Intune Solutions.
#>
[CmdletBinding(SupportsShouldProcess=$true)] param()
Write-Host "=== ASR Remediation — $($env:COMPUTERNAME) ===" -ForegroundColor Cyan
try {
    if (-not (Get-MpComputerStatus).RealTimeProtectionEnabled) {
        if ($PSCmdlet.ShouldProcess('Defender','Enable real-time protection')) { Set-MpPreference -DisableRealtimeMonitoring $false; Write-Host "  Real-time protection enabled." -ForegroundColor Green }
    } else { Write-Host "  Real-time protection already on." }
    if (-not (Get-MpComputerStatus).AMRunning) { Write-Host "  WARNING: Defender AV is not the active AV — ASR requires Defender active (or EDR block mode via MDE)." -ForegroundColor Yellow }
} catch { Write-Host "  Defender check skipped: $($_.Exception.Message)" -ForegroundColor Yellow }
Start-Process -FilePath "$env:WINDIR\System32\deviceenroller.exe" -ArgumentList "/c /AutoEnrollMDM" -WindowStyle Hidden
Write-Host "  MDM sync requested." -ForegroundColor Green
Write-Host "`nRe-run ASR-Validation.ps1 after a policy cycle." -ForegroundColor Green
