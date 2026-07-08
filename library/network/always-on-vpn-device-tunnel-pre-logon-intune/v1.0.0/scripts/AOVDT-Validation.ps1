<#
.SYNOPSIS
    AOVDT-Validation.ps1 — confirm the Always On VPN device tunnel + machine cert are present on THIS device.
.DESCRIPTION
    PURPOSE
        Local, read-only validation run ON a pilot Windows device. Confirms the 'AOVPN Device Tunnel'
        VPN profile is present at the machine level (Get-VpnConnection -AllUserConnection), reports its
        ConnectionStatus, checks that a valid machine certificate with a Client Authentication EKU is in
        Cert:\LocalMachine\My, and best-effort reports whether DeviceTunnel/AlwaysOn are set. Prints a
        clear PASS/FAIL so a pilot device can be counted as validated. Makes NO changes.
    HOW TO RUN
        powershell -ExecutionPolicy Bypass -File .\AOVDT-Validation.ps1
        Optional: -GatewayFqdn vpn.your-company.com to check the profile targets a specific gateway.
        Run in an elevated (admin) PowerShell so LocalMachine store + rasphone are readable.
        No Microsoft Graph scopes needed — this inspects the local device only.
    EXPECTED RESULTS
        A checklist: device-tunnel profile present (yes/no + status), machine certificate present
        (yes/no, Client Auth EKU), DeviceTunnel/AlwaysOn best-effort. Overall PASS when the
        'AOVPN Device Tunnel' profile exists AND a valid machine cert with Client Auth EKU is present;
        otherwise FAIL with the missing item.
.NOTES
    White-label — the repeatable way. Read-only local inspection. VPN gateway head-end internals deferred to vendor docs.
#>

[CmdletBinding()]
param(
    [string] $ProfileName = 'AOVPN Device Tunnel',
    [string] $GatewayFqdn = ''
)

$ErrorActionPreference = 'Continue'

Write-Host "=== Always On VPN Device Tunnel — On-Device Validation ===" -ForegroundColor Cyan
Write-Host "Device: $env:COMPUTERNAME`n"

$results = [ordered]@{}

# --- 1. Device-tunnel VPN profile present (machine level)? -------------------
$vpn = $null
try {
    $vpn = Get-VpnConnection -AllUserConnection -ErrorAction SilentlyContinue |
        Where-Object { $_.Name -eq $ProfileName }
} catch {}
if ($vpn) {
    $status = $vpn.ConnectionStatus
    $results["Device-tunnel profile '$ProfileName'"] = "PASS (present; status $status)"
} else {
    $results["Device-tunnel profile '$ProfileName'"] = 'FAIL — not found at machine level'
}

# --- 2. DeviceTunnel / AlwaysOn best-effort ----------------------------------
if ($vpn) {
    $dt = if ($null -ne $vpn.DeviceTunnel) { $vpn.DeviceTunnel } else { 'unknown' }
    $ao = if ($null -ne $vpn.AlwaysOn)     { $vpn.AlwaysOn }     else { 'unknown' }
    $results['DeviceTunnel / AlwaysOn'] = "DeviceTunnel=$dt; AlwaysOn=$ao"
    if ($GatewayFqdn) {
        $srvMatch = ($vpn.ServerAddress -match [regex]::Escape($GatewayFqdn))
        $results["Gateway '$GatewayFqdn' targeted"] = if ($srvMatch) { 'PASS' } else { "WARN — profile server is '$($vpn.ServerAddress)'" }
    }
}

# --- 3. Machine certificate with Client Authentication EKU? ------------------
$clientAuthOid = '1.3.6.1.5.5.7.3.2'
$certs = @()
try {
    $certs = Get-ChildItem Cert:\LocalMachine\My -ErrorAction SilentlyContinue | Where-Object {
        $_.NotAfter -gt (Get-Date) -and (
            ($_.EnhancedKeyUsageList | Where-Object { $_.ObjectId -eq $clientAuthOid -or $_.FriendlyName -match 'Client Authentication' })
        )
    }
} catch {}
$results['Machine cert (Client Auth EKU) in LocalMachine\My'] = if ($certs.Count -gt 0) {
    "PASS ($($certs.Count) valid cert(s))"
} else { 'FAIL — no valid machine cert with Client Authentication EKU' }

# --- Report ------------------------------------------------------------------
Write-Host "Validation results:" -ForegroundColor Cyan
foreach ($k in $results.Keys) {
    $v = $results[$k]
    $color = if ($v -like 'PASS*') { 'Green' } elseif ($v -like 'WARN*') { 'Yellow' } elseif ($v -like 'FAIL*') { 'Red' } else { 'Gray' }
    Write-Host ("  {0,-52} {1}" -f $k, $v) -ForegroundColor $color
}

# Overall: device-tunnel profile present AND a valid machine cert are the mandatory gates.
$overallPass = ($results["Device-tunnel profile '$ProfileName'"] -like 'PASS*') -and
               ($results['Machine cert (Client Auth EKU) in LocalMachine\My'] -like 'PASS*')

Write-Host ""
if ($overallPass) {
    Write-Host "OVERALL: PASS — this device has the device-tunnel profile and a valid machine certificate." -ForegroundColor Green
    Write-Host "Confirm the tunnel is Connected BEFORE logon (reboot test) per 05-testing.md T5." -ForegroundColor Green
    exit 0
} else {
    Write-Host "OVERALL: FAIL — resolve the FAIL item(s) above, then re-run (see 06-troubleshooting.md)." -ForegroundColor Red
    exit 1
}
