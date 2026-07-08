<#
.SYNOPSIS
    AOVUT-Validation.ps1 — confirm the Always On VPN user tunnel + user certificate are applied on THIS device.
.DESCRIPTION
    PURPOSE
        Local, read-only validation run ON a pilot Windows device, signed in as the pilot user. Confirms
        the user-tunnel VPN connection ('AOVPN User Tunnel') is present and Always On, reports its
        connection status, and confirms a valid USER certificate is in the current user's personal store
        (Cert:\CurrentUser\My). Prints a clear PASS/FAIL so a pilot device can be counted as validated.
        Makes NO changes.
    HOW TO RUN
        powershell -ExecutionPolicy Bypass -File .\AOVUT-Validation.ps1
        Optional: -GatewayFqdn vpn.your-company.com to check the connection's server address.
        No Microsoft Graph scopes needed — this inspects the local device only.
    EXPECTED RESULTS
        A checklist: user-tunnel VPN connection present (yes/no), Always On (yes/no), connection status,
        and a valid user certificate present (yes/no). Overall PASS when the VPN connection exists AND a
        valid user certificate is present; otherwise FAIL with the missing item.
.NOTES
    White-label — the repeatable way. Read-only local inspection. VPN gateway / head-end internals deferred to vendor docs.
#>

[CmdletBinding()]
param(
    [string] $ConnectionName = 'AOVPN User Tunnel',
    [string] $GatewayFqdn = ''
)

$ErrorActionPreference = 'Continue'

Write-Host "=== Always On VPN User Tunnel — On-Device Validation ===" -ForegroundColor Cyan
Write-Host "Device: $env:COMPUTERNAME   User: $env:USERNAME`n"

$results = [ordered]@{}

# --- 1. User-tunnel VPN connection present? ----------------------------------
$vpn = $null
try {
    $vpn = Get-VpnConnection -Name $ConnectionName -ErrorAction SilentlyContinue
    if (-not $vpn) {
        # Fall back to an all-user lookup in case the connection is provisioned all-user.
        $vpn = Get-VpnConnection -AllUserConnection -ErrorAction SilentlyContinue |
            Where-Object { $_.Name -eq $ConnectionName }
    }
} catch { $vpn = $null }

$results["VPN connection '$ConnectionName' present"] = if ($vpn) { 'PASS' } else { 'FAIL — connection not found' }

# --- 2. Always On + connection status ----------------------------------------
if ($vpn) {
    $alwaysOn = $false
    try { $alwaysOn = [bool]$vpn.AlwaysOn } catch { $alwaysOn = $false }
    $results['Always On enabled'] = if ($alwaysOn) { 'PASS' } else { 'WARN — Always On not set (tunnel will not auto-connect)' }
    $results['Connection status'] = "$($vpn.ConnectionStatus)"

    # --- 3. Gateway server address (optional targeted check) -----------------
    if ($GatewayFqdn) {
        $match = ($vpn.ServerAddress -and ($vpn.ServerAddress -join ',') -match [regex]::Escape($GatewayFqdn))
        $results["Gateway '$GatewayFqdn' referenced"] = if ($match) { 'PASS' } else { 'WARN — not found in ServerAddress' }
    }
}

# --- 4. User certificate present in CurrentUser\My ---------------------------
$userCerts = @()
try {
    $userCerts = Get-ChildItem Cert:\CurrentUser\My -ErrorAction SilentlyContinue |
        Where-Object { $_.NotAfter -gt (Get-Date) -and $_.NotBefore -le (Get-Date) }
} catch { $userCerts = @() }

# Prefer a cert with the Client Authentication EKU (1.3.6.1.5.5.7.3.2) if any are present.
$clientAuth = $userCerts | Where-Object {
    $_.EnhancedKeyUsageList -and ($_.EnhancedKeyUsageList.ObjectId -contains '1.3.6.1.5.5.7.3.2')
}
$results['User certificate present'] = if ($clientAuth.Count -gt 0) {
    "PASS ($($clientAuth.Count) client-auth cert(s) in CurrentUser\My)"
} elseif ($userCerts.Count -gt 0) {
    "WARN ($($userCerts.Count) user cert(s), none with Client Authentication EKU)"
} else {
    'FAIL — no valid user certificate in CurrentUser\My'
}

# --- Report ------------------------------------------------------------------
Write-Host "Validation results:" -ForegroundColor Cyan
foreach ($k in $results.Keys) {
    $v = $results[$k]
    $color = if ($v -like 'PASS*') { 'Green' } elseif ($v -like 'WARN*') { 'Yellow' } else { 'Red' }
    Write-Host ("  {0,-36} {1}" -f $k, $v) -ForegroundColor $color
}

# Overall: VPN connection present AND a valid user certificate are the mandatory gates.
$overallPass = ($results["VPN connection '$ConnectionName' present"] -like 'PASS*') -and
               ($results['User certificate present'] -like 'PASS*')

Write-Host ""
if ($overallPass) {
    Write-Host "OVERALL: PASS — this device has the user-tunnel VPN connection and a valid user certificate." -ForegroundColor Green
    exit 0
} else {
    Write-Host "OVERALL: FAIL — resolve the FAIL item(s) above, then re-run (see 06-troubleshooting.md)." -ForegroundColor Red
    exit 1
}
