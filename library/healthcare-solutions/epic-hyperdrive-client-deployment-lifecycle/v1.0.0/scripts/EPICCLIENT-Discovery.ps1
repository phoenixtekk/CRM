<#
.SYNOPSIS
    EPICCLIENT-Discovery.ps1 — Inventories the installed Epic client (Hyperdrive/Hyperspace) version and health.

.DESCRIPTION
    PURPOSE
        Reports, on the device it runs on, which Epic client is installed (Hyperdrive and/or
        Hyperspace), its version, install path, and basic health (executable present, WebView2
        runtime present for Hyperdrive). Use during Assess (Implementation Step 2) to capture the
        detection values, and at any time to inventory a device. Read-only.

    HOW TO RUN
        On the device, in a normal PowerShell window:
            powershell -ExecutionPolicy Bypass -File .\EPICCLIENT-Discovery.ps1
        Optionally point it at the known install path / executable from your Epic build team:
            .\EPICCLIENT-Discovery.ps1 -InstallDir "C:\Program Files\Epic" -Exe "Hyperdrive.exe"

    EXPECTED RESULTS
        A table of any detected Epic client(s) with version, path, and WebView2 status. If nothing is
        detected, confirm the Epic client is installed and that -InstallDir/-Exe match your build
        team's values, then re-run. Use the reported version as the detection value when packaging.

.NOTES
    Healthcare Solutions — read-only. Makes no changes. Reports device/app state only; never captures
    patient data.
    Epic install path, executable, and registry naming are environment-specific — obtain the exact
    values from your Epic build team / Epic UserWeb and pass them via -InstallDir / -Exe / -DisplayNameLike.
#>
[CmdletBinding()]
param(
    [string]$InstallDir,
    [string]$Exe,
    # Display-name pattern used to match the Epic client in the uninstall registry.
    [string]$DisplayNameLike = 'Epic|Hyperdrive|Hyperspace'
)

function Get-FileVersionSafe($path) {
    try { (Get-Item $path -ErrorAction Stop).VersionInfo.ProductVersion } catch { $null }
}

$results = New-Object System.Collections.Generic.List[object]

# 1) Registry uninstall keys (HKLM 64/32-bit) matching the Epic client display name pattern.
$uninstRoots = @(
    'HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall\*',
    'HKLM:\SOFTWARE\WOW6432Node\Microsoft\Windows\CurrentVersion\Uninstall\*'
)
foreach ($root in $uninstRoots) {
    Get-ItemProperty $root -ErrorAction SilentlyContinue |
        Where-Object { $_.DisplayName -and $_.DisplayName -match $DisplayNameLike } |
        ForEach-Object {
            $results.Add([pscustomobject]@{
                Source         = 'Registry'
                Name           = $_.DisplayName
                Version        = $_.DisplayVersion
                InstallLocation= $_.InstallLocation
                UninstallString= $_.UninstallString
            })
        }
}

# 2) Explicit file path, if the caller provided the build team's install dir + exe.
if ($InstallDir -and $Exe) {
    $full = Join-Path $InstallDir $Exe
    if (Test-Path $full) {
        $results.Add([pscustomobject]@{
            Source          = 'File'
            Name            = $Exe
            Version         = (Get-FileVersionSafe $full)
            InstallLocation = $InstallDir
            UninstallString = $null
        })
    }
}

# 3) WebView2 runtime (Hyperdrive prerequisite).
$wv2Roots = @(
    'HKLM:\SOFTWARE\WOW6432Node\Microsoft\EdgeUpdate\Clients\{F3017226-FE2A-4295-8BDF-00C3A9A7E4C5}',
    'HKLM:\SOFTWARE\Microsoft\EdgeUpdate\Clients\{F3017226-FE2A-4295-8BDF-00C3A9A7E4C5}'
)
$wv2 = $null
foreach ($k in $wv2Roots) { $p = Get-ItemProperty $k -ErrorAction SilentlyContinue; if ($p.pv) { $wv2 = $p.pv; break } }

Write-Host "`n=== Epic Client Discovery ($($env:COMPUTERNAME)) ===" -ForegroundColor Cyan
if ($results.Count -gt 0) {
    $results | Sort-Object Source, Name | Format-Table -AutoSize
} else {
    Write-Host "No Epic client detected. Confirm it is installed and pass -InstallDir/-Exe/-DisplayNameLike from your Epic build team." -ForegroundColor Yellow
}
Write-Host ("WebView2 Runtime (Hyperdrive prerequisite): " + ($(if ($wv2) { "PRESENT (v$wv2)" } else { 'NOT DETECTED' }))) -ForegroundColor ($(if ($wv2) { 'Green' } else { 'Yellow' }))
