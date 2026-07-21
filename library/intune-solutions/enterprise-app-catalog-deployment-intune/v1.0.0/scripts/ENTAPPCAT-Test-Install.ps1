<#
.SYNOPSIS
    ENTAPPCAT-Test-Install.ps1 — on-device check of IME health and a catalog app's install/detection state.
.DESCRIPTION
    PURPOSE
        Read-only check, run ON a pilot device, that confirms (a) the Intune Management Extension (IME)
        is present and healthy and (b) the deployed catalog app is actually installed on this device —
        by matching its display name against installed programs (the built-in detection rule is
        Microsoft's; this confirms the on-device result). No changes are made.
    HOW TO RUN
        powershell -ExecutionPolicy Bypass -File .\ENTAPPCAT-Test-Install.ps1 -AppDisplayName "Sample App"
    GRAPH SCOPES
        None — runs locally on the device; does not call Microsoft Graph.
    EXPECTED RESULTS
        IME service status, and INSTALLED / NOT INSTALLED for the app based on the machine's installed-
        programs registry. Read-only.
.NOTES
    Intune Solutions. Read-only; no system changes. Run on a targeted pilot device.
#>
[CmdletBinding()]
param(
    [Parameter(Mandatory)] [string]$AppDisplayName
)

Write-Host "=== Catalog App Install Test — $($env:COMPUTERNAME) ===" -ForegroundColor Cyan

# 1) IME present/healthy
$ime = Get-Service -Name 'Microsoft Intune Management Extension' -ErrorAction SilentlyContinue
if ($ime) { Write-Host ("  IME service: {0}" -f $ime.Status) -ForegroundColor Green }
else      { Write-Host "  IME service: NOT FOUND — catalog/Win32 apps will not install until it is present." -ForegroundColor Yellow }

# 2) Installed-programs check (both 64-bit and 32-bit uninstall hives)
$hives = @(
    'HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall\*',
    'HKLM:\SOFTWARE\WOW6432Node\Microsoft\Windows\CurrentVersion\Uninstall\*'
)
$match = Get-ItemProperty $hives -ErrorAction SilentlyContinue |
         Where-Object { $_.DisplayName -like "*$AppDisplayName*" } |
         Select-Object DisplayName, DisplayVersion

if ($match) {
    Write-Host "`n  INSTALLED:" -ForegroundColor Green
    $match | ForEach-Object { Write-Host ("    {0}  (version {1})" -f $_.DisplayName, $_.DisplayVersion) }
    Write-Host "`nRESULT: '$AppDisplayName' is INSTALLED on this device." -ForegroundColor Green
} else {
    Write-Host "`nRESULT: '$AppDisplayName' NOT INSTALLED (not found in installed programs)." -ForegroundColor Yellow
    Write-Host "  If Intune reports it Installed, review the IME log:" -ForegroundColor Yellow
    Write-Host "  C:\ProgramData\Microsoft\IntuneManagementExtension\Logs\IntuneManagementExtension.log"
}
