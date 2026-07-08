<#
.SYNOPSIS
    PREVPN-Validation.ps1 — confirm THIS device has a working pre-logon path to a domain controller.
.DESCRIPTION
    PURPOSE
        Local, read-only validation run ON a pilot Windows device. Detects the device join type
        (dsregcmd /status), whether a pre-logon tunnel exists (an Always On VPN DEVICE tunnel via
        Get-VpnConnection -AllUserConnection, OR the Cisco Secure Client Start Before Logon credential
        provider vpnplap64.dll), whether a machine/device certificate is present (LocalMachine\My),
        and a best-effort domain-controller reachability check. Prints a clear PASS/FAIL so a pilot
        device can be counted as pre-logon-ready. Makes NO changes.
    HOW TO RUN
        powershell -ExecutionPolicy Bypass -File .\PREVPN-Validation.ps1
        Optional:
            -DcFqdn dc01.your-domain.com   check reachability to a specific DC (port 389)
            -RequireCertificate            require a LocalMachine\My cert (device-tunnel deployments)
        No Microsoft Graph scopes needed — this inspects the local device only.
    EXPECTED RESULTS
        A checklist: join type (hybrid / domain-joined / Entra-joined), pre-logon path present
        (device tunnel or PLAP), machine cert present (if checked), and a DC reachable. Overall PASS
        when a pre-logon capability is present AND a domain controller is reachable through it. On an
        Entra-joined (cloud-only) device the script reports that no pre-logon tunnel is needed.
.NOTES
    White-label — the repeatable way. Read-only local inspection. Vendor internals deferred to vendor docs.
#>

[CmdletBinding()]
param(
    [string] $DcFqdn = '',
    [switch] $RequireCertificate
)

$ErrorActionPreference = 'Continue'

Write-Host "=== Pre-Logon VPN — On-Device Validation ===" -ForegroundColor Cyan
Write-Host "Device: $env:COMPUTERNAME   User: $env:USERNAME`n"

$results = [ordered]@{}

# --- 1. Join type (dsregcmd /status) -----------------------------------------
$joinType = 'Unknown'
$azureAd = $false; $domain = $false; $enterprise = $false
try {
    $ds = & dsregcmd /status 2>$null
    if ($ds -match 'AzureAdJoined\s*:\s*YES')     { $azureAd = $true }
    if ($ds -match 'DomainJoined\s*:\s*YES')      { $domain = $true }
    if ($ds -match 'EnterpriseJoined\s*:\s*YES')  { $enterprise = $true }
    if     ($domain -and $azureAd) { $joinType = 'Entra hybrid-joined' }
    elseif ($domain)               { $joinType = 'Domain-joined' }
    elseif ($azureAd)              { $joinType = 'Entra-joined (cloud-only)' }
    elseif ($enterprise)           { $joinType = 'Entra hybrid-joined (enterprise)' }
} catch {}
$results['Join type'] = $joinType

$needsDcPath = ($joinType -like '*hybrid*') -or ($joinType -eq 'Domain-joined')

# --- 2. Pre-logon path present? ----------------------------------------------
# (a) Always On VPN device tunnel (all-user connection with device tunnel enabled)
$deviceTunnel = $false
try {
    $vpns = Get-VpnConnection -AllUserConnection -ErrorAction SilentlyContinue
    foreach ($v in $vpns) {
        # A device tunnel is an all-user connection; DeviceTunnel property is present on supported OS.
        if ($v.PSObject.Properties.Name -contains 'DeviceTunnel' -and $v.DeviceTunnel) { $deviceTunnel = $true; break }
        if (-not ($v.PSObject.Properties.Name -contains 'DeviceTunnel')) { $deviceTunnel = $true } # older OS: all-user VPN present
    }
} catch {}

# (b) Cisco Secure Client Start Before Logon (PLAP) credential provider present
$plap = $false
$plapPaths = @(
    "$env:ProgramFiles\Cisco\Cisco Secure Client\vpnplap64.dll",
    "${env:ProgramFiles(x86)}\Cisco\Cisco Secure Client\vpnplap64.dll",
    "$env:ProgramFiles\Cisco\Cisco AnyConnect Secure Mobility Client\vpnplap64.dll",
    "${env:ProgramFiles(x86)}\Cisco\Cisco AnyConnect Secure Mobility Client\vpnplap64.dll",
    "$env:SystemRoot\System32\vpnplap64.dll"
)
foreach ($p in $plapPaths) { if (Test-Path $p) { $plap = $true; break } }

$prelogon = $deviceTunnel -or $plap
$capDesc = @()
if ($deviceTunnel) { $capDesc += 'device tunnel' }
if ($plap)         { $capDesc += 'SBL/PLAP' }
$results['Pre-logon path present'] = if ($prelogon) { "PASS ($($capDesc -join ' + '))" } else { 'FAIL — no device tunnel or PLAP provider found' }

# --- 3. Machine/device certificate (device-tunnel deployments) ---------------
if ($RequireCertificate) {
    $certs = Get-ChildItem Cert:\LocalMachine\My -ErrorAction SilentlyContinue |
        Where-Object { $_.NotAfter -gt (Get-Date) }
    $results['Machine certificate present'] = if ($certs.Count -gt 0) {
        "PASS ($($certs.Count) valid cert(s) in LocalMachine\My)"
    } else { 'FAIL — no valid machine certificate' }
}

# --- 4. Domain-controller reachability ---------------------------------------
$dcReachable = $false
if ($needsDcPath -or $DcFqdn) {
    if ($DcFqdn) {
        try {
            $t = Test-NetConnection -ComputerName $DcFqdn -Port 389 -WarningAction SilentlyContinue
            $dcReachable = [bool]$t.TcpTestSucceeded
        } catch {}
        $results["DC '$DcFqdn' reachable (LDAP 389)"] = if ($dcReachable) { 'PASS' } else { 'FAIL — cannot reach DC on 389' }
    } else {
        # Best-effort DC locate via nltest.
        try {
            $nl = & nltest /dsgetdc: 2>$null
            if ($LASTEXITCODE -eq 0 -and $nl -match 'DC:\s*\\\\') { $dcReachable = $true }
        } catch {}
        $results['Domain controller locatable (nltest)'] = if ($dcReachable) { 'PASS' } else { 'WARN — no DC located (bring the tunnel up first, or pass -DcFqdn)' }
    }
}

# --- Report ------------------------------------------------------------------
Write-Host "Validation results:" -ForegroundColor Cyan
foreach ($k in $results.Keys) {
    $v = "$($results[$k])"
    $color = if ($v -like 'PASS*') { 'Green' } elseif ($v -like 'WARN*') { 'Yellow' } elseif ($v -like 'FAIL*') { 'Red' } else { 'Gray' }
    Write-Host ("  {0,-36} {1}" -f $k, $v) -ForegroundColor $color
}

Write-Host ""
if ($joinType -eq 'Entra-joined (cloud-only)') {
    Write-Host "NOTE: This device is Entra-joined (cloud-only). It authenticates against Entra in the cloud" -ForegroundColor Cyan
    Write-Host "      and does NOT need a pre-logon tunnel for first logon or password change. Use SSPR/TAP." -ForegroundColor Cyan
    Write-Host "OVERALL: N/A — no pre-logon VPN required for this device." -ForegroundColor Green
    exit 0
}

# Overall: for hybrid/domain-joined, need a pre-logon path AND a reachable DC.
$overallPass = $prelogon
if ($needsDcPath) { $overallPass = $overallPass -and $dcReachable }
if ($RequireCertificate) { $overallPass = $overallPass -and ($results['Machine certificate present'] -like 'PASS*') }

if ($overallPass) {
    Write-Host "OVERALL: PASS — this device has a pre-logon path and a domain controller is reachable." -ForegroundColor Green
    exit 0
} else {
    Write-Host "OVERALL: FAIL — resolve the FAIL/WARN item(s) above, then re-run (see 06-troubleshooting.md)." -ForegroundColor Red
    exit 1
}
