<#
.SYNOPSIS
    WINGETSTORE-Test-Install.ps1 — confirm a pilot Store/winget app is installed and detected on the
    local device (read-only).
.DESCRIPTION
    PURPOSE
        Run ON a pilot device after an assignment applies (or after a Company Portal self-service
        install) to prove the app is really present. Checks two independent signals, read-only:
          * the Intune Management Extension service is present (the installer of Store/winget apps), and
          * the app is detected locally — via winget (if available) and via the Windows uninstall
            registry (DisplayName + DisplayVersion) so you can see the installed version.
        Makes no changes.
    HOW TO RUN
        powershell -ExecutionPolicy Bypass -File .\WINGETSTORE-Test-Install.ps1 -AppName "VLC"
        powershell -ExecutionPolicy Bypass -File .\WINGETSTORE-Test-Install.ps1 -AppName "Acrobat Reader" -WingetId "Adobe.Acrobat.Reader.64-bit"
        Runs locally; no Microsoft Graph or scopes required.
    GRAPH SCOPES
        None (local device queries only).
    EXPECTED RESULTS
        PRESENT with the detected DisplayName + version if the app is installed; NOT DETECTED otherwise.
        The exact winget package id is verify-with-winget; the registry check works regardless of id.
.NOTES
    Intune Solutions — read-only, local. Run in an elevated session to read machine-scope installs.
#>
[CmdletBinding()]
param(
    [Parameter(Mandatory)] [string]$AppName,   # display-name substring, e.g. "VLC" or "Acrobat Reader"
    [string]$WingetId                           # optional exact winget id (verify-with-winget)
)

Write-Host "=== Local install check: $AppName ===" -ForegroundColor Cyan

# 1) IME present (installer of Store/winget apps)
$ime = Get-Service -Name 'Microsoft Intune Management Extension' -ErrorAction SilentlyContinue
if ($ime) { Write-Host ("  IME service: {0}" -f $ime.Status) -ForegroundColor Green }
else      { Write-Host "  IME service: NOT FOUND (Store/winget apps are installed by the IME)" -ForegroundColor Yellow }

# 2) winget detection (if winget is available)
$winget = Get-Command winget -ErrorAction SilentlyContinue
if ($winget) {
    Write-Host "`n  winget list:" -ForegroundColor Cyan
    if ($WingetId) { winget list --id $WingetId 2>$null } else { winget list --name $AppName 2>$null }
} else {
    Write-Host "`n  winget command not available on this device (App Installer may be missing)." -ForegroundColor Yellow
}

# 3) Registry uninstall detection (authoritative, id-independent) — reports the installed version
$paths = @(
    'HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall\*',
    'HKLM:\SOFTWARE\WOW6432Node\Microsoft\Windows\CurrentVersion\Uninstall\*'
)
$hits = foreach ($p in $paths) {
    Get-ItemProperty $p -ErrorAction SilentlyContinue |
        Where-Object { $_.DisplayName -like "*$AppName*" } |
        Select-Object DisplayName, DisplayVersion, Publisher
}
if ($hits) {
    Write-Host "`n  PRESENT — detected via registry:" -ForegroundColor Green
    $hits | Format-Table -AutoSize
} else {
    Write-Host "`n  NOT DETECTED via registry for '*$AppName*'." -ForegroundColor Yellow
}
