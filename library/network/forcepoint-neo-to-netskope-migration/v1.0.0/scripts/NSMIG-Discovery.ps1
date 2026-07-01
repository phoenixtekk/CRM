<#
.SYNOPSIS
    NSMIG-Discovery.ps1 — detect the Forcepoint Neo agent and current web-steering state (read-only).
.DESCRIPTION
    PURPOSE
        Reports whether the legacy Forcepoint Neo agent is installed on this device (service and
        installed-product detection), its version if found, and whether a Netskope client is also
        present — the inputs you need to build the Legacy Estate - Forcepoint Neo - Inventory group
        and plan coexistence. Netskope/Forcepoint console steering specifics are deferred to vendor
        docs; this script reports only locally observable agent state.
    HOW TO RUN
        Elevated: powershell -ExecutionPolicy Bypass -File .\NSMIG-Discovery.ps1
    EXPECTED RESULTS
        Forcepoint Neo present (yes/no) + version, Netskope client present (yes/no), and a coexistence
        note if both are installed. Read-only; makes no changes.
.NOTES
    Network Solutions. Read-only. Netskope/Forcepoint console specifics deferred to vendor docs.
#>
[CmdletBinding()] param()
Write-Host "`n=== Forcepoint Neo -> Netskope migration — discovery ($($env:COMPUTERNAME)) ===" -ForegroundColor Cyan

function Get-InstalledMatch([string]$pattern) {
    $keys = @(
        'HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall\*',
        'HKLM:\SOFTWARE\WOW6432Node\Microsoft\Windows\CurrentVersion\Uninstall\*'
    )
    Get-ItemProperty $keys -ErrorAction SilentlyContinue |
        Where-Object { $_.DisplayName -match $pattern } |
        Select-Object DisplayName, DisplayVersion
}

# Forcepoint Neo agent detection (installed product and/or service)
$fpProduct = Get-InstalledMatch 'Forcepoint|Neo'
$fpSvc = Get-Service -ErrorAction SilentlyContinue | Where-Object { $_.DisplayName -match 'Forcepoint' -or $_.Name -match 'Forcepoint' }
$fpPresent = [bool]($fpProduct -or $fpSvc)
if ($fpPresent) {
    $ver = ($fpProduct | Select-Object -First 1).DisplayVersion
    Write-Host ("Forcepoint Neo agent : PRESENT  (version {0})" -f ($(if($ver){$ver}else{'unknown'}))) -ForegroundColor Yellow
    if ($fpSvc) { Write-Host ("  service(s)         : {0}" -f (($fpSvc.Name) -join ', ')) }
} else {
    Write-Host "Forcepoint Neo agent : not detected" -ForegroundColor Green
}

# Netskope client detection
$nsProduct = Get-InstalledMatch 'Netskope'
$nsSvc = Get-Service -ErrorAction SilentlyContinue | Where-Object { $_.DisplayName -match 'Netskope' -or $_.Name -match 'stagent|Netskope' }
$nsPresent = [bool]($nsProduct -or $nsSvc)
Write-Host ("Netskope client      : {0}" -f ($(if($nsPresent){'PRESENT'}else{'not detected'}))) -ForegroundColor ($(if($nsPresent){'Cyan'}else{'Gray'}))

# Coexistence note
if ($fpPresent -and $nsPresent) {
    Write-Host "COEXISTENCE: both agents present — ensure only ONE is steering/enforcing (passive vs enforce)." -ForegroundColor Yellow
}
Write-Host ("`nDevice: {0}  Forcepoint={1}  Netskope={2}" -f $env:COMPUTERNAME, $fpPresent, $nsPresent) -ForegroundColor Cyan
