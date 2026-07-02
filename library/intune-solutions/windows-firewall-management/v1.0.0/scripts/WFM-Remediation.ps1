<#
.SYNOPSIS
    WFM-Remediation.ps1 — re-enable firewall profiles and force a policy sync.
.DESCRIPTION
    PURPOSE
        Turns the firewall back on for any profile found disabled and triggers an Intune/MDM sync
        so the managed firewall policy re-applies. It does not delete or add firewall rules.
    HOW TO RUN
        Elevated: powershell -ExecutionPolicy Bypass -File .\WFM-Remediation.ps1
    EXPECTED RESULTS
        All profiles enabled; MDM sync requested. Re-run WFM-Validation.ps1.
.NOTES
    White-label — Intune Solutions.
#>
[CmdletBinding(SupportsShouldProcess=$true)] param()
Write-Host "=== Firewall Remediation — $($env:COMPUTERNAME) ===" -ForegroundColor Cyan
$off = Get-NetFirewallProfile | Where-Object Enabled -eq $false
if ($off) {
    if ($PSCmdlet.ShouldProcess(($off.Name -join ','),'Enable firewall profiles')) {
        Set-NetFirewallProfile -All -Enabled True
        Write-Host ("  Enabled profiles: {0}" -f ($off.Name -join ', ')) -ForegroundColor Green
    }
} else { Write-Host "  All profiles already enabled." }
Start-Process -FilePath "$env:WINDIR\System32\deviceenroller.exe" -ArgumentList "/c /AutoEnrollMDM" -WindowStyle Hidden
Write-Host "  MDM sync requested (re-applies managed firewall policy)." -ForegroundColor Green
Write-Host "`nRe-run WFM-Validation.ps1 after a policy cycle." -ForegroundColor Green
