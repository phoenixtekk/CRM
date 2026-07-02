<#
.SYNOPSIS
    DCP-Remediation.ps1 — safe remediation for common compliance failures.
.DESCRIPTION
    PURPOSE
        Forces an Intune/MDM sync and fixes the two most common compliance failures it can safely
        address locally: Windows Firewall off and Defender real-time protection off. BitLocker and
        Secure Boot are reported (not auto-changed) because they need care/reboot.
    HOW TO RUN
        Elevated: powershell -ExecutionPolicy Bypass -File .\DCP-Remediation.ps1
    EXPECTED RESULTS
        Firewall/Defender re-enabled where off; MDM sync requested; re-run DCP-Validation.ps1.
.NOTES
    White-label — Intune Solutions.
#>
[CmdletBinding(SupportsShouldProcess=$true)] param()
Write-Host "=== Compliance Remediation — $($env:COMPUTERNAME) ===" -ForegroundColor Cyan
# firewall
if ((Get-NetFirewallProfile).Enabled -contains $false) {
    if ($PSCmdlet.ShouldProcess('Windows Firewall','Enable all profiles')) { Set-NetFirewallProfile -All -Enabled True; Write-Host "  Firewall enabled." -ForegroundColor Green }
} else { Write-Host "  Firewall already on." }
# defender real-time
try { if (-not (Get-MpComputerStatus).RealTimeProtectionEnabled) {
    if ($PSCmdlet.ShouldProcess('Defender','Enable real-time protection')) { Set-MpPreference -DisableRealtimeMonitoring $false; Write-Host "  Defender real-time enabled." -ForegroundColor Green }
} else { Write-Host "  Defender real-time already on." } } catch { Write-Host "  Defender check skipped: $($_.Exception.Message)" -ForegroundColor Yellow }
# report-only for BitLocker/Secure Boot
try { if (-not (Confirm-SecureBootUEFI)) { Write-Host "  NOTE: Secure Boot is OFF — enable in UEFI (manual)." -ForegroundColor Yellow } } catch {}
if (((manage-bde -status $env:SystemDrive) -notmatch 'Protection On')) { Write-Host "  NOTE: BitLocker not protecting C: — deploy the BitLocker solution / enable encryption." -ForegroundColor Yellow }
# MDM sync
Start-Process -FilePath "$env:WINDIR\System32\deviceenroller.exe" -ArgumentList "/c /AutoEnrollMDM" -WindowStyle Hidden
Write-Host "`nMDM sync requested. Re-run DCP-Validation.ps1 after a policy cycle." -ForegroundColor Green
