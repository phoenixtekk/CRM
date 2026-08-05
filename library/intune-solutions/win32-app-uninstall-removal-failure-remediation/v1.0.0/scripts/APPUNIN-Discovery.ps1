<#
.SYNOPSIS
    APPUNIN-Discovery.ps1 — on-device uninstall-readiness discovery for a Win32 app.
.DESCRIPTION
    PURPOSE
        Runs LOCALLY on a failing Windows device (elevated) to establish the on-disk
        truth an Intune uninstall depends on. For the target app it resolves:
          - the real MSI ProductCode(s) actually installed (HKLM and WOW6432Node),
          - the registered UninstallString / QuietUninstallString,
          - whether the app is registered per-machine (HKLM) or per-user (HKCU),
          - whether the cached MSI still exists under C:\Windows\Installer,
          - any running processes / services owned by the app (which block removal).
        This is what you compare against the app's Intune Uninstall command and
        detection rule in Diagnostic Playbook branches B, C, D, E, F, and G.
    HOW TO RUN
        Open an ELEVATED PowerShell on the device, then:
          powershell -ExecutionPolicy Bypass -File .\APPUNIN-Discovery.ps1 -DisplayNameLike "Contoso LOB"
        Optional: -CsvPath C:\ProgramData\APPUNIN\Evidence\discovery.csv to save the result.
        No Microsoft Graph and no external modules are required.
    EXPECTED RESULTS
        A per-registration table (DisplayName, Version, Scope HKLM/HKCU, ProductCode,
        UninstallString, CachedMsiPresent) plus a list of running processes/services.
        Pass = the ProductCode and UninstallString match the Intune Uninstall command.
        Fail = they differ (Branch D/E), the app is HKCU-only (Branch F), the cached
        MSI is missing (Branch E last-resort), or a process/service is running (Branch G).
.NOTES
    Intune Solutions — read-only, local. The repeatable way. Makes no changes.
#>

[CmdletBinding()]
param(
    [Parameter(Mandatory)][string] $DisplayNameLike,
    [string] $CsvPath
)

$ErrorActionPreference = 'Stop'

$uninstallRoots = @(
    @{ Scope = 'HKLM';      Path = 'HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall\*' },
    @{ Scope = 'HKLM-Wow64'; Path = 'HKLM:\SOFTWARE\WOW6432Node\Microsoft\Windows\CurrentVersion\Uninstall\*' },
    @{ Scope = 'HKCU';      Path = 'HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall\*' }
)

Write-Host "Searching uninstall registrations for '*$DisplayNameLike*' ..." -ForegroundColor Cyan

$rows = foreach ($root in $uninstallRoots) {
    Get-ItemProperty -Path $root.Path -ErrorAction SilentlyContinue |
        Where-Object { $_.DisplayName -like "*$DisplayNameLike*" } |
        ForEach-Object {
            $keyName = $_.PSChildName
            $isGuid  = $keyName -match '^\{[0-9A-Fa-f-]{36}\}$'
            $cached  = $false
            if ($isGuid) {
                # A cached MSI is required to run "msiexec /x {GUID}" when the source installer is gone.
                $cached = [bool](Get-ChildItem 'C:\Windows\Installer\*.msi' -ErrorAction SilentlyContinue |
                                 Where-Object { $_.Length -gt 0 } | Select-Object -First 1)
            }
            [pscustomobject]@{
                DisplayName          = $_.DisplayName
                DisplayVersion       = $_.DisplayVersion
                Scope                = $root.Scope
                ProductCode          = if ($isGuid) { $keyName } else { '(non-MSI)' }
                UninstallString      = $_.UninstallString
                QuietUninstallString = $_.QuietUninstallString
                InstallLocation      = $_.InstallLocation
                CachedMsiPresent     = $cached
            }
        }
}

if (-not $rows) {
    Write-Host "No uninstall registration found for '*$DisplayNameLike*'." -ForegroundColor Yellow
    Write-Host "If Intune still reports the app INSTALLED, the detection rule is likely matching a remnant (Branch C) or the app is per-user under a different profile (Branch F)." -ForegroundColor Yellow
} else {
    $rows | Format-List DisplayName, DisplayVersion, Scope, ProductCode, UninstallString, QuietUninstallString, InstallLocation, CachedMsiPresent
    $hkcuOnly = ($rows | Where-Object Scope -eq 'HKCU') -and -not ($rows | Where-Object { $_.Scope -like 'HKLM*' })
    if ($hkcuOnly) {
        Write-Host "NOTE: app is registered ONLY under HKCU (per-user). A SYSTEM-context uninstall cannot see it -> Branch F." -ForegroundColor Yellow
    }
    if ($rows | Where-Object { $_.ProductCode -match '^\{' -and -not $_.CachedMsiPresent }) {
        Write-Host "NOTE: no cached MSI detected under C:\Windows\Installer for at least one product -> plan a last-resort removal path (Branch E)." -ForegroundColor Yellow
    }
}

# Running processes / services that would block removal (Branch G).
Write-Host "`nRunning processes matching the app name:" -ForegroundColor Cyan
$procs = Get-Process -ErrorAction SilentlyContinue | Where-Object { $_.Name -like "*$DisplayNameLike*" }
if ($procs) { $procs | Format-Table -AutoSize Name, Id, Path } else { Write-Host "  (none)" -ForegroundColor Green }

Write-Host "Services matching the app name:" -ForegroundColor Cyan
$svcs = Get-Service -ErrorAction SilentlyContinue | Where-Object { $_.DisplayName -like "*$DisplayNameLike*" -or $_.Name -like "*$DisplayNameLike*" }
if ($svcs) { $svcs | Format-Table -AutoSize Name, Status, DisplayName } else { Write-Host "  (none)" -ForegroundColor Green }

if ($CsvPath -and $rows) {
    $dir = Split-Path -Parent $CsvPath
    if ($dir -and -not (Test-Path $dir)) { New-Item -ItemType Directory -Path $dir -Force | Out-Null }
    $rows | Export-Csv -Path $CsvPath -NoTypeInformation -Encoding UTF8
    Write-Host "`nSaved discovery to $CsvPath" -ForegroundColor Green
}
