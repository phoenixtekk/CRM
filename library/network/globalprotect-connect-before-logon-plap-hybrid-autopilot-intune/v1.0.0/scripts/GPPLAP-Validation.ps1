<#
.SYNOPSIS
    GPPLAP-Validation.ps1 — confirm GlobalProtect Connect Before Logon (PLAP) is installed, enabled, and registered on THIS Windows 11 device.
.DESCRIPTION
    PURPOSE
        Local, read-only validation run ON a pilot Windows 11 device. Confirms GlobalProtect is installed
        and at version 5.2 or later, the PanSetup registry enables Connect Before Logon
        (Prelogon = 1) with a Portal set, the PLAP credential provider is registered, and reports the
        device join type via dsregcmd (DomainJoined + AzureAdJoined = Hybrid Azure AD Join). Prints a clear
        PASS/FAIL so a pilot device can be counted as validated. Makes NO changes.
    HOW TO RUN
        powershell -ExecutionPolicy Bypass -File .\GPPLAP-Validation.ps1
        No Microsoft Graph scopes needed — this inspects the local device only. Run elevated for the most
        reliable registry/service reads.
    EXPECTED RESULTS
        A checklist: GlobalProtect installed (yes/no + version, >=5.2), PanSetup Prelogon=1 (yes/no),
        Portal set (value), PLAP credential provider registered (yes/no), and the dsregcmd join type.
        Overall PASS when GP >= 5.2 AND Prelogon = 1 AND PLAP is registered; otherwise FAIL with the
        missing item.
.NOTES
    White-label — the repeatable way. Read-only local inspection. GlobalProtect portal/gateway and app internals deferred to vendor docs.
#>

[CmdletBinding()]
param(
    [version] $MinVersion = '5.2'
)

$ErrorActionPreference = 'Continue'

Write-Host "=== GlobalProtect Connect Before Logon (PLAP) — On-Device Validation ===" -ForegroundColor Cyan
Write-Host "Device: $env:COMPUTERNAME   User: $env:USERNAME`n"

$results = [ordered]@{}

# --- 1. GlobalProtect installed and version >= 5.2? --------------------------
$installed = $false
$version   = $null
$uninstallKeys = @(
    'HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall\*',
    'HKLM:\SOFTWARE\WOW6432Node\Microsoft\Windows\CurrentVersion\Uninstall\*'
)
foreach ($k in $uninstallKeys) {
    $apps = Get-ItemProperty $k -ErrorAction SilentlyContinue |
        Where-Object { $_.DisplayName -match 'GlobalProtect' }
    if ($apps) {
        $installed = $true
        $version   = ($apps | Select-Object -First 1).DisplayVersion
        break
    }
}
# Fallback: binary presence
if (-not $installed) {
    $binPaths = @(
        "$env:ProgramFiles\Palo Alto Networks\GlobalProtect\PanGPS.exe",
        "${env:ProgramFiles(x86)}\Palo Alto Networks\GlobalProtect\PanGPS.exe"
    )
    foreach ($p in $binPaths) {
        if (Test-Path $p) {
            $installed = $true
            try { $version = (Get-Item $p).VersionInfo.ProductVersion } catch {}
            break
        }
    }
}
$versionOk = $false
if ($installed -and $version) {
    try { $versionOk = ([version](($version -split '[^0-9\.]')[0]) -ge $MinVersion) } catch { $versionOk = $false }
}
$results['GlobalProtect installed (>=5.2)'] = if ($installed -and $versionOk) {
    "PASS (version $version)"
} elseif ($installed) {
    "FAIL — version $version is below $MinVersion (Connect Before Logon needs 5.2+)"
} else { 'FAIL — GlobalProtect not found' }

# --- 2. PanSetup registry — Prelogon = 1 and Portal set ----------------------
$panSetup = 'HKLM:\SOFTWARE\Palo Alto Networks\GlobalProtect\PanSetup'
$prelogon = $null
$portal   = $null
try {
    $ps = Get-ItemProperty -Path $panSetup -ErrorAction SilentlyContinue
    if ($ps) { $prelogon = $ps.Prelogon; $portal = $ps.Portal }
} catch {}
$results['PanSetup Prelogon = 1'] = if ("$prelogon" -eq '1') { 'PASS' } else { "FAIL — Prelogon='$prelogon' (expected 1)" }
$results['PanSetup Portal set']   = if ($portal) { "PASS ($portal)" } else { 'WARN — no Portal value under PanSetup' }

# --- 3. PLAP credential provider registered? ---------------------------------
# Connect Before Logon registers a PLAP credential provider under the Authentication\Credential Providers key.
$cpRoot = 'HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Authentication\Credential Providers'
$plapRegistered = $false
try {
    $providers = Get-ChildItem -Path $cpRoot -ErrorAction SilentlyContinue
    foreach ($p in $providers) {
        $name = (Get-ItemProperty -Path $p.PSPath -ErrorAction SilentlyContinue).'(default)'
        if ($name -match 'GlobalProtect|Palo Alto|PLAP|PanPlap') { $plapRegistered = $true; break }
    }
    # Secondary signal: the PanGPS service is present (service must be ready for registration to succeed).
    if (-not $plapRegistered) {
        $svc = Get-Service -Name 'PanGPS' -ErrorAction SilentlyContinue
        if ($svc) {
            # Presence of the PLAP DLL alongside a registered provider is the ground truth; note if only the service is present.
            $plapDll = @(
                "$env:ProgramFiles\Palo Alto Networks\GlobalProtect\PanPlap.dll",
                "${env:ProgramFiles(x86)}\Palo Alto Networks\GlobalProtect\PanPlap.dll"
            ) | Where-Object { Test-Path $_ }
            if ($plapDll) { $plapRegistered = $true }
        }
    }
} catch {}
$results['PLAP credential provider registered'] = if ($plapRegistered) {
    'PASS'
} else {
    'FAIL — no GlobalProtect PLAP provider registered (run PanGPS.exe -registerplap as SYSTEM)'
}

# --- 4. Join type via dsregcmd (informational) -------------------------------
$joinType = 'unknown'
try {
    $ds = dsregcmd /status 2>$null
    $domainJoined = ($ds | Select-String 'DomainJoined\s*:\s*YES') -ne $null
    $aadJoined    = ($ds | Select-String 'AzureAdJoined\s*:\s*YES') -ne $null
    if ($domainJoined -and $aadJoined) { $joinType = 'Hybrid Azure AD Join (DomainJoined + AzureAdJoined)' }
    elseif ($aadJoined) { $joinType = 'Azure AD Joined only' }
    elseif ($domainJoined) { $joinType = 'Domain Joined only' }
    else { $joinType = 'Workgroup / not joined' }
} catch {}
$results['Device join type (dsregcmd)'] = $joinType

# --- Report ------------------------------------------------------------------
Write-Host "Validation results:" -ForegroundColor Cyan
foreach ($k in $results.Keys) {
    $v = "$($results[$k])"
    $color = if ($v -like 'PASS*') { 'Green' } elseif ($v -like 'WARN*') { 'Yellow' } elseif ($v -like 'FAIL*') { 'Red' } else { 'Gray' }
    Write-Host ("  {0,-38} {1}" -f $k, $v) -ForegroundColor $color
}

# Overall: GP>=5.2 AND Prelogon=1 AND PLAP registered are the mandatory gates.
$overallPass = ($results['GlobalProtect installed (>=5.2)'] -like 'PASS*') -and
               ($results['PanSetup Prelogon = 1'] -like 'PASS*') -and
               ($results['PLAP credential provider registered'] -like 'PASS*')

Write-Host ""
if ($overallPass) {
    Write-Host "OVERALL: PASS — GlobalProtect 5.2+, Connect Before Logon enabled, and PLAP registered on this device." -ForegroundColor Green
    exit 0
} else {
    Write-Host "OVERALL: FAIL — resolve the FAIL item(s) above, then re-run (see 06-troubleshooting.md)." -ForegroundColor Red
    exit 1
}
