<#
.SYNOPSIS
    CSCVPN-Validation.ps1 — confirm the Cisco Secure Client + VPN profile are applied on THIS device.
.DESCRIPTION
    PURPOSE
        Local, read-only validation run ON a pilot Windows device. Confirms the Cisco Secure Client
        software is installed, the VPN client profile is present, a VPN connection entry for the
        gateway exists, and (if cert auth) a matching device certificate is in the store. Prints a
        clear PASS/FAIL so a pilot device can be counted as validated. Makes NO changes.
    HOW TO RUN
        powershell -ExecutionPolicy Bypass -File .\CSCVPN-Validation.ps1
        Optional: -GatewayFqdn vpn.your-company.com to check for a specific gateway entry.
        No Microsoft Graph scopes needed — this inspects the local device only.
    EXPECTED RESULTS
        A checklist: client installed (yes/no + version), VPN profile XML present (yes/no),
        gateway entry present (yes/no), certificate present (yes/no if checked). Overall PASS when
        the client is installed AND the VPN profile is present; otherwise FAIL with the missing item.
.NOTES
    White-label — the repeatable way. Read-only local inspection. Cisco-specific internals deferred to vendor docs.
#>

[CmdletBinding()]
param(
    [string] $GatewayFqdn = '',
    [switch] $RequireCertificate
)

$ErrorActionPreference = 'Continue'

Write-Host "=== Cisco Secure Client VPN — On-Device Validation ===" -ForegroundColor Cyan
Write-Host "Device: $env:COMPUTERNAME   User: $env:USERNAME`n"

$results = [ordered]@{}

# --- 1. Client installed? ----------------------------------------------------
$installed = $false
$version   = $null
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
# Fallback: binary presence
if (-not $installed) {
    $binPaths = @(
        "$env:ProgramFiles\Cisco\Cisco Secure Client",
        "${env:ProgramFiles(x86)}\Cisco\Cisco Secure Client",
        "$env:ProgramFiles\Cisco\Cisco AnyConnect Secure Mobility Client"
    )
    foreach ($p in $binPaths) { if (Test-Path $p) { $installed = $true; break } }
}
$results['Client installed'] = if ($installed) { "PASS (version $version)" } else { 'FAIL — not found' }

# --- 2. VPN client profile (XML) present? ------------------------------------
$profileDirs = @(
    "$env:ProgramData\Cisco\Cisco Secure Client\VPN\Profile",
    "$env:ProgramData\Cisco\Cisco AnyConnect Secure Mobility Client\Profile"
)
$profileXml = @()
foreach ($d in $profileDirs) {
    if (Test-Path $d) { $profileXml += Get-ChildItem -Path $d -Filter *.xml -ErrorAction SilentlyContinue }
}
$results['VPN profile (XML) present'] = if ($profileXml.Count -gt 0) {
    "PASS ($($profileXml.Count) profile file(s))"
} else { 'FAIL — no VPN profile XML found' }

# --- 3. Gateway entry present? (optional targeted check) ---------------------
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

# --- 4. Certificate present? (if cert auth) ----------------------------------
if ($RequireCertificate) {
    $certs = Get-ChildItem Cert:\LocalMachine\My -ErrorAction SilentlyContinue |
        Where-Object { $_.NotAfter -gt (Get-Date) }
    $results['Device certificate present'] = if ($certs.Count -gt 0) {
        "PASS ($($certs.Count) valid cert(s) in LocalMachine\My)"
    } else { 'FAIL — no valid device certificate' }
}

# --- Report ------------------------------------------------------------------
Write-Host "Validation results:" -ForegroundColor Cyan
foreach ($k in $results.Keys) {
    $v = $results[$k]
    $color = if ($v -like 'PASS*') { 'Green' } elseif ($v -like 'WARN*') { 'Yellow' } else { 'Red' }
    Write-Host ("  {0,-32} {1}" -f $k, $v) -ForegroundColor $color
}

# Overall: client installed AND profile present are the mandatory gates.
$overallPass = ($results['Client installed'] -like 'PASS*') -and ($results['VPN profile (XML) present'] -like 'PASS*')
if ($RequireCertificate) { $overallPass = $overallPass -and ($results['Device certificate present'] -like 'PASS*') }

Write-Host ""
if ($overallPass) {
    Write-Host "OVERALL: PASS — this device has the Secure Client and its VPN profile." -ForegroundColor Green
    exit 0
} else {
    Write-Host "OVERALL: FAIL — resolve the FAIL item(s) above, then re-run (see 06-troubleshooting.md)." -ForegroundColor Red
    exit 1
}
