<#
.SYNOPSIS
    WDAC-Discovery.ps1 — App Control (WDAC) readiness and current code-integrity status.
.DESCRIPTION
    PURPOSE
        Reports OS support for App Control for Business and the device's current Device Guard /
        code-integrity enforcement status.
    HOW TO RUN
        Elevated: powershell -ExecutionPolicy Bypass -File .\WDAC-Discovery.ps1
    EXPECTED RESULTS
        OS support verdict and the current code-integrity enforcement state.
.NOTES
    Phoenixtekk Workplace Marketplace — Intune Solutions. Read-only.
#>
[CmdletBinding()] param()
Write-Host "`n=== WDAC / App Control Readiness ($($env:COMPUTERNAME)) ===" -ForegroundColor Cyan
$os = Get-CimInstance Win32_OperatingSystem
$osOk = [version]$os.Version -ge [version]'10.0.18362'  # 1903+
Write-Host ("OS supported (1903+/Win11): {0}  ({1} {2})" -f $osOk, $os.Caption, $os.Version) -ForegroundColor ($(if($osOk){'Green'}else{'Yellow'}))
try {
    $dg = Get-CimInstance -Namespace root\Microsoft\Windows\DeviceGuard -ClassName Win32_DeviceGuard -ErrorAction Stop
    $map = @{ 0='Off'; 1='Audit'; 2='Enforced' }
    Write-Host ("Code Integrity enforcement: {0}" -f $map[[int]$dg.CodeIntegrityPolicyEnforcementStatus])
    Write-Host ("UMCI enforcement          : {0}" -f $map[[int]$dg.UsermodeCodeIntegrityPolicyEnforcementStatus])
} catch { Write-Host "DeviceGuard WMI not available." -ForegroundColor Yellow }
# active policies (Windows 11 citool)
$citool = "$env:WINDIR\System32\citool.exe"
if (Test-Path $citool) {
    Write-Host "`nActive App Control policies (citool):" -ForegroundColor Cyan
    & $citool --list-policies 2>$null | Select-String 'PolicyID|FriendlyName|IsEnforced' | ForEach-Object { Write-Host "  $($_.Line.Trim())" }
} else { Write-Host "`n(citool not present — Windows 10; use WDAC-Validation.ps1 for policy state.)" -ForegroundColor Gray }
