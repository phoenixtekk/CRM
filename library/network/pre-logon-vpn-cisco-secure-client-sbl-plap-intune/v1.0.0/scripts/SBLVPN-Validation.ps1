<#
.SYNOPSIS
    SBLVPN-Validation.ps1 — confirm Cisco Secure Client + Start Before Logon (SBL/PLAP) are applied on THIS device.
.DESCRIPTION
    PURPOSE
        Local, read-only validation run ON a pilot Windows device. Confirms the Cisco Secure Client
        software is installed, the Start Before Logon / PLAP credential provider is present
        (vpnplap64.dll and/or the PLAP registration), the deployed VPN client profile XML enables SBL
        (<UseStartBeforeLogon>true</UseStartBeforeLogon>), and (if cert auth) a device certificate is
        in the LocalMachine store. Prints a clear PASS/FAIL so a pilot device can be counted as
        validated. Makes NO changes.
    HOW TO RUN
        powershell -ExecutionPolicy Bypass -File .\SBLVPN-Validation.ps1
        Optional: -GatewayFqdn vpn.your-company.com to check for a specific gateway entry.
        Optional: -RequireCertificate to also require a valid device certificate in LocalMachine\My.
        No Microsoft Graph scopes needed — this inspects the local device only.
    EXPECTED RESULTS
        A checklist: client installed (yes/no + version), SBL/PLAP present (yes/no), VPN profile XML
        present with UseStartBeforeLogon=true (yes/no), gateway entry present (yes/no), certificate
        present (yes/no if checked). Overall PASS when the client is installed AND SBL/PLAP is present
        AND UseStartBeforeLogon is true; otherwise FAIL with the missing item.
.NOTES
    White-label — the repeatable way. Read-only local inspection. Cisco-specific internals deferred to vendor docs.
#>

[CmdletBinding()]
param(
    [string] $GatewayFqdn = '',
    [switch] $RequireCertificate
)

$ErrorActionPreference = 'Continue'

Write-Host "=== Pre-Logon VPN (Cisco SBL/PLAP) — On-Device Validation ===" -ForegroundColor Cyan
Write-Host "Device: $env:COMPUTERNAME   User: $env:USERNAME`n"

$results = [ordered]@{}

# --- 1. Client installed? ----------------------------------------------------
$installed = $false
$version   = $null
$clientDir = $null
$uninstallKeys = @(
    'HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall\*',
    'HKLM:\SOFTWARE\WOW6432Node\Microsoft\Windows\CurrentVersion\Uninstall\*'
)
foreach ($k in $uninstallKeys) {
    $apps = Get-ItemProperty $k -ErrorAction SilentlyContinue |
        Where-Object { $_.DisplayName -match 'Cisco (Secure Client|AnyConnect)' }
    if ($apps) {
        $installed = $true
        $version   = ($apps | Select-Object -First 1).DisplayVersion
        break
    }
}
$binPaths = @(
    "$env:ProgramFiles\Cisco\Cisco Secure Client",
    "${env:ProgramFiles(x86)}\Cisco\Cisco Secure Client",
    "$env:ProgramFiles\Cisco\Cisco AnyConnect Secure Mobility Client",
    "${env:ProgramFiles(x86)}\Cisco\Cisco AnyConnect Secure Mobility Client"
)
foreach ($p in $binPaths) { if (Test-Path $p) { $installed = $true; if (-not $clientDir) { $clientDir = $p } } }
$results['Client installed'] = if ($installed) { "PASS (version $version)" } else { 'FAIL — not found' }

# --- 2. Start Before Logon / PLAP present? -----------------------------------
# (a) the PLAP DLL on disk (64-bit: vpnplap64.dll; 32-bit: vpnplap.dll)
$plapDll = $false
$plapCandidates = @()
foreach ($p in $binPaths) {
    $plapCandidates += (Join-Path $p 'vpnplap64.dll')
    $plapCandidates += (Join-Path $p 'vpnplap.dll')
}
foreach ($dll in $plapCandidates) { if (Test-Path $dll) { $plapDll = $true; break } }

# (b) a Cisco PLAP credential-provider registration
$plapReg = $false
$cpRoot = 'HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Authentication\Credential Providers'
try {
    $providers = Get-ChildItem $cpRoot -ErrorAction SilentlyContinue
    foreach ($cp in $providers) {
        $val = (Get-ItemProperty $cp.PSPath -ErrorAction SilentlyContinue).'(default)'
        if ($val -and $val -match 'Cisco|AnyConnect|PLAP|Secure Client') { $plapReg = $true; break }
    }
} catch {}

$sblPresent = $plapDll -or $plapReg
$results['Start Before Logon / PLAP present'] = if ($sblPresent) {
    "PASS (dll=$plapDll, registration=$plapReg)"
} else { 'FAIL — vpnplap64.dll and PLAP registration both absent (SBL module missing)' }

# --- 3. VPN client profile (XML) present AND SBL-enabled? --------------------
$profileDirs = @(
    "$env:ProgramData\Cisco\Cisco Secure Client\VPN\Profile",
    "$env:ProgramData\Cisco\Cisco AnyConnect Secure Mobility Client\Profile"
)
$profileXml = @()
foreach ($d in $profileDirs) {
    if (Test-Path $d) { $profileXml += Get-ChildItem -Path $d -Filter *.xml -Recurse -ErrorAction SilentlyContinue }
}
$results['VPN profile (XML) present'] = if ($profileXml.Count -gt 0) {
    "PASS ($($profileXml.Count) profile file(s))"
} else { 'FAIL — no VPN profile XML found' }

# UseStartBeforeLogon must be true in at least one deployed profile.
$sblEnabled = $false
foreach ($xml in $profileXml) {
    try {
        $content = Get-Content -Raw -Path $xml.FullName -ErrorAction SilentlyContinue
        if ($content -match '(?i)<UseStartBeforeLogon>\s*true\s*</UseStartBeforeLogon>') { $sblEnabled = $true; break }
    } catch {}
}
$results['UseStartBeforeLogon = true'] = if ($sblEnabled) { 'PASS' } else { 'FAIL — not set to true in any profile XML' }

# --- 4. Gateway entry present? (optional targeted check) ---------------------
if ($GatewayFqdn) {
    $found = $false
    foreach ($xml in $profileXml) {
        try {
            $content = Get-Content -Raw -Path $xml.FullName -ErrorAction SilentlyContinue
            if ($content -match [regex]::Escape($GatewayFqdn)) { $found = $true; break }
        } catch {}
    }
    $results["Gateway '$GatewayFqdn' referenced"] = if ($found) { 'PASS' } else { 'WARN — not found in profile XML' }
}

# --- 5. Device certificate present? (if cert auth) ---------------------------
if ($RequireCertificate) {
    $certs = Get-ChildItem Cert:\LocalMachine\My -ErrorAction SilentlyContinue |
        Where-Object { $_.NotAfter -gt (Get-Date) }
    $results['Device certificate present (LocalMachine\My)'] = if ($certs.Count -gt 0) {
        "PASS ($($certs.Count) valid machine cert(s))"
    } else { 'FAIL — no valid device certificate' }
}

# --- Report ------------------------------------------------------------------
Write-Host "Validation results:" -ForegroundColor Cyan
foreach ($k in $results.Keys) {
    $v = $results[$k]
    $color = if ($v -like 'PASS*') { 'Green' } elseif ($v -like 'WARN*') { 'Yellow' } else { 'Red' }
    Write-Host ("  {0,-46} {1}" -f $k, $v) -ForegroundColor $color
}

# Overall: client installed AND SBL/PLAP present AND UseStartBeforeLogon true are the mandatory gates.
$overallPass = ($results['Client installed'] -like 'PASS*') -and
               ($results['Start Before Logon / PLAP present'] -like 'PASS*') -and
               ($results['UseStartBeforeLogon = true'] -like 'PASS*')
if ($RequireCertificate) { $overallPass = $overallPass -and ($results['Device certificate present (LocalMachine\My)'] -like 'PASS*') }

Write-Host ""
if ($overallPass) {
    Write-Host "OVERALL: PASS — this device has Secure Client + Start Before Logon and the profile enables SBL." -ForegroundColor Green
    exit 0
} else {
    Write-Host "OVERALL: FAIL — resolve the FAIL item(s) above, then re-run (see 06-troubleshooting.md)." -ForegroundColor Red
    exit 1
}
