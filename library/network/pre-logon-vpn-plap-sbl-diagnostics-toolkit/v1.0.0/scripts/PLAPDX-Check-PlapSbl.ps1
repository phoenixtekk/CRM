<#
.SYNOPSIS
    PLAPDX-Check-PlapSbl.ps1 — focused Cisco Start Before Logon (SBL/PLAP) precondition check on this device.
.DESCRIPTION
    PURPOSE
        Checks, with PASS/FAIL per precondition, everything the Windows "Network sign-in" (PLAP) tile
        needs to appear: the Start Before Logon module installed (Core VPN first), the 64-bit PLAP
        component vpnplap64.dll present, the PLAP credential provider registered under
        HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Authentication\Credential Providers, the Cisco
        Secure Client VPN profile present, and <UseStartBeforeLogon>true</UseStartBeforeLogon> set in
        that profile. Prints the exact remedy for each FAIL. Read-only: it never changes anything.
    HOW TO RUN
        Run ELEVATED (needs to read the Credential Providers registry key):
            powershell -ExecutionPolicy Bypass -File .\PLAPDX-Check-PlapSbl.ps1
        No Microsoft Graph scopes needed — this inspects the local device only.
    EXPECTED RESULTS
        A PASS/FAIL line per precondition. The first FAIL is almost always why the tile is missing;
        each FAIL prints its remedy (deploy the SBL module, set UseStartBeforeLogon, repair the module
        so vpnplap64.dll registers). All PASS => the tile should appear (see 06-troubleshooting.md).
.NOTES
    White-label — the repeatable way. Read-only local inspection. VPN head-end / gateway internals deferred to vendor docs.
#>

[CmdletBinding()]
param()

$ErrorActionPreference = 'Continue'
Write-Host "=== Pre-Logon VPN — SBL / PLAP Check ===" -ForegroundColor Cyan
Write-Host "Device: $env:COMPUTERNAME`n"

$results = [System.Collections.Generic.List[object]]::new()
function Add-Result {
    param([string]$Name, [bool]$Pass, [string]$Detail, [string]$Remedy)
    $results.Add([pscustomobject]@{ Check = $Name; Result = $(if ($Pass) { 'PASS' } else { 'FAIL' }); Detail = $Detail; Remedy = $Remedy })
}

# 1. Start Before Logon module installed (Secure Client present + PLAP DLL is the module marker).
$scInstalled = $false
foreach ($k in @('HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall\*',
                 'HKLM:\SOFTWARE\WOW6432Node\Microsoft\Windows\CurrentVersion\Uninstall\*')) {
    if (Get-ItemProperty $k -ErrorAction SilentlyContinue | Where-Object { $_.DisplayName -match 'Cisco (Secure Client|AnyConnect)' }) { $scInstalled = $true; break }
}

# 2. vpnplap64.dll present (the 64-bit PLAP component the SBL module installs).
$dllCandidates = @(
    "$env:ProgramFiles\Cisco\Cisco Secure Client\vpnplap64.dll",
    "${env:ProgramFiles(x86)}\Cisco\Cisco Secure Client\vpnplap64.dll",
    "${env:ProgramFiles(x86)}\Cisco\Cisco AnyConnect Secure Mobility Client\vpnplap64.dll"
)
$dllPath = $dllCandidates | Where-Object { Test-Path $_ } | Select-Object -First 1
$dllPresent = [bool]$dllPath

Add-Result 'Start Before Logon module installed' ($scInstalled -and $dllPresent) `
    ("Secure Client: {0}; vpnplap64.dll: {1}" -f $(if ($scInstalled) { 'installed' } else { 'not found' }), $(if ($dllPresent) { $dllPath } else { 'not found' })) `
    'Deploy Pre-Logon VPN - SBL Module - Win32 (Core VPN first) to the device group; then re-sync.'

Add-Result 'vpnplap64.dll (64-bit PLAP component) present' $dllPresent `
    $(if ($dllPresent) { $dllPath } else { 'no vpnplap64.dll under the Cisco Secure Client folder' }) `
    'Repair/reinstall the SBL module so the 64-bit vpnplap64.dll is installed (a stale 32-bit vpnplap.dll will not render the tile).'

# 3. PLAP credential provider registered.
$plapRegistered = $false; $plapClsid = $null
$cpRoot = 'HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Authentication\Credential Providers'
try {
    foreach ($cp in (Get-ChildItem $cpRoot -ErrorAction SilentlyContinue)) {
        $inproc = "HKLM:\SOFTWARE\Classes\CLSID\$($cp.PSChildName)\InprocServer32"
        if (Test-Path $inproc) {
            $dll = (Get-ItemProperty $inproc -ErrorAction SilentlyContinue).'(default)'
            if ($dll -match 'vpnplap64\.dll') { $plapRegistered = $true; $plapClsid = $cp.PSChildName; break }
        }
    }
} catch {}
Add-Result 'PLAP credential provider registered' $plapRegistered `
    $(if ($plapRegistered) { "CLSID $plapClsid -> vpnplap64.dll" } else { 'no Credential Providers CLSID references vpnplap64.dll' }) `
    'Repair/reinstall the SBL module so it registers the PLAP credential provider under HKLM Credential Providers.'

# 4. Secure Client VPN profile present.
$profileDirs = @(
    "$env:ProgramData\Cisco\Cisco Secure Client\VPN\Profile",
    "$env:ProgramData\Cisco\Cisco AnyConnect Secure Mobility Client\Profile"
)
$profiles = @()
foreach ($dir in $profileDirs) { if (Test-Path $dir) { $profiles += Get-ChildItem $dir -Filter *.xml -ErrorAction SilentlyContinue } }
Add-Result 'Cisco Secure Client VPN profile present' ($profiles.Count -gt 0) `
    ("{0} profile XML file(s)" -f $profiles.Count) `
    'Confirm Pre-Logon VPN - SBL - Profile is assigned to the device and has arrived; force a sync.'

# 5. UseStartBeforeLogon = true.
$sblFlag = $null
foreach ($f in $profiles) {
    try {
        $raw = Get-Content -Raw -Path $f.FullName -ErrorAction SilentlyContinue
        if ($raw -match '(?i)<UseStartBeforeLogon>\s*true\s*</UseStartBeforeLogon>') { $sblFlag = 'true'; break }
        elseif ($raw -match '(?i)<UseStartBeforeLogon>\s*false\s*</UseStartBeforeLogon>') { $sblFlag = 'false' }
    } catch {}
}
Add-Result 'UseStartBeforeLogon = true' ($sblFlag -eq 'true') `
    ("value found: {0}" -f $(if ($sblFlag) { $sblFlag } else { 'not present' })) `
    'Set <UseStartBeforeLogon>true</UseStartBeforeLogon> in Pre-Logon VPN - SBL - Profile and re-push.'

# --- Report ------------------------------------------------------------------
$results | Format-Table Check, Result, Detail -AutoSize -Wrap
$fails = @($results | Where-Object { $_.Result -eq 'FAIL' })
Write-Host ""
if ($fails.Count -eq 0) {
    Write-Host "OVERALL: PASS — all SBL/PLAP preconditions met; the Network sign-in tile should appear." -ForegroundColor Green
} else {
    Write-Host "OVERALL: FAIL — remedy each item below, then re-run:" -ForegroundColor Red
    foreach ($f in $fails) { Write-Host ("  [{0}] {1}" -f $f.Check, $f.Remedy) -ForegroundColor Yellow }
    Write-Host "See 06-troubleshooting.md (SBL/PLAP)." -ForegroundColor Yellow
}
