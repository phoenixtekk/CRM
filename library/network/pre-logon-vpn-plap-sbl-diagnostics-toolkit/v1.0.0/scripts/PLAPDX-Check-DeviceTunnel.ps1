<#
.SYNOPSIS
    PLAPDX-Check-DeviceTunnel.ps1 — focused Windows Always On VPN device-tunnel precondition check.
.DESCRIPTION
    PURPOSE
        Checks, with PASS/FAIL per precondition, everything a device tunnel needs to establish before
        logon: an eligible OS SKU (Windows Enterprise/Education) and join type (domain-joined or
        hybrid-joined), EXACTLY ONE device tunnel (only one is allowed per device), the connection is
        IKEv2, DeviceTunnel=true and AlwaysOn=true are set, and a valid machine certificate backs it.
        Prints the exact remedy for each FAIL. Read-only: it never starts, stops, or reconfigures a
        tunnel — it reads Get-VpnConnection -AllUserConnection, the OS/join state, and the cert store.
    HOW TO RUN
        Run ELEVATED (needs to read all-user VPN connections and LocalMachine\My):
            powershell -ExecutionPolicy Bypass -File .\PLAPDX-Check-DeviceTunnel.ps1
        No Microsoft Graph scopes needed — this inspects the local device only.
    EXPECTED RESULTS
        A PASS/FAIL line per precondition with a remedy for each FAIL (fix SKU/join, remove the extra
        device tunnel, reissue as IKEv2, set the flags, fix the machine cert). All PASS => the device
        tunnel should connect at boot (see 06-troubleshooting.md).
.NOTES
    White-label — the repeatable way. Read-only local inspection. VPN head-end / gateway internals deferred to vendor docs.
#>

[CmdletBinding()]
param()

$ErrorActionPreference = 'Continue'
Write-Host "=== Pre-Logon VPN — Device Tunnel Check ===" -ForegroundColor Cyan
Write-Host "Device: $env:COMPUTERNAME`n"

$results = [System.Collections.Generic.List[object]]::new()
function Add-Result {
    param([string]$Name, [bool]$Pass, [string]$Detail, [string]$Remedy)
    $results.Add([pscustomobject]@{ Check = $Name; Result = $(if ($Pass) { 'PASS' } else { 'FAIL' }); Detail = $Detail; Remedy = $Remedy })
}

# 1. OS SKU eligible (Enterprise/Education).
$os = Get-CimInstance Win32_OperatingSystem -ErrorAction SilentlyContinue
$isEntEd = ($os.Caption -match 'Enterprise|Education')
Add-Result 'OS SKU is Enterprise/Education' $isEntEd `
    $os.Caption `
    'The device tunnel requires Windows Enterprise or Education. On Pro/Home, use SBL instead or change the SKU.'

# 2. Join type eligible (domain-joined or hybrid-joined).
$joinAzureAd = $false; $joinDomain = $false
try {
    foreach ($l in (dsregcmd /status 2>$null)) {
        if ($l -match 'AzureAdJoined\s*:\s*YES') { $joinAzureAd = $true }
        if ($l -match 'DomainJoined\s*:\s*YES')  { $joinDomain = $true }
    }
} catch {}
Add-Result 'Domain-joined or hybrid-joined' $joinDomain `
    ("DomainJoined={0}; AzureADJoined={1}" -f $joinDomain, $joinAzureAd) `
    'The device tunnel needs a domain-joined or hybrid-joined machine (an Entra-only join is not supported).'

# 3. Exactly one device tunnel.
$allTunnels = @(); $deviceTunnels = @()
try {
    $allTunnels = Get-VpnConnection -AllUserConnection -ErrorAction SilentlyContinue
    $deviceTunnels = @($allTunnels | Where-Object { $_.DeviceTunnel -eq $true })
} catch {}
Add-Result 'Exactly one device tunnel exists' ($deviceTunnels.Count -eq 1) `
    ("device tunnels found: {0}" -f $deviceTunnels.Count) `
    'Windows allows only ONE device tunnel. Remove the extra tunnel(s); if none exist, deploy Pre-Logon VPN - Device Tunnel - Profile.'

$dt = $deviceTunnels | Select-Object -First 1

# 4. IKEv2.
$isIkev2 = ($dt -and $dt.TunnelType -match 'Ikev2')
Add-Result 'Device tunnel is IKEv2' $isIkev2 `
    ("TunnelType: {0}" -f $(if ($dt) { $dt.TunnelType } else { 'n/a — no device tunnel' })) `
    'Device tunnels support IKEv2 only. Reissue Pre-Logon VPN - Device Tunnel - Profile as IKEv2.'

# 5. AlwaysOn = true (DeviceTunnel already confirmed by the filter above).
$alwaysOn = ($dt -and $dt.AlwaysOn -eq $true)
Add-Result 'DeviceTunnel + AlwaysOn set' $alwaysOn `
    ("DeviceTunnel=True; AlwaysOn={0}" -f $(if ($dt) { $dt.AlwaysOn } else { 'n/a' })) `
    'Set DeviceTunnel=true and AlwaysOn=true in the VPNv2 CSP ProfileXML so it auto-connects at boot.'

# 6. Valid machine certificate present.
$clientAuthOid = '1.3.6.1.5.5.7.3.2'
$usable = @()
foreach ($c in (Get-ChildItem Cert:\LocalMachine\My -ErrorAction SilentlyContinue)) {
    $hasClientAuth = $false
    foreach ($eku in $c.EnhancedKeyUsageList) { if ($eku.ObjectId -eq $clientAuthOid -or $eku.FriendlyName -eq 'Client Authentication') { $hasClientAuth = $true } }
    if ($hasClientAuth -and $c.HasPrivateKey -and $c.NotAfter -gt (Get-Date)) { $usable += $c }
}
Add-Result 'Valid machine certificate present' ($usable.Count -gt 0) `
    ("usable client-auth machine cert(s) in LocalMachine\My: {0}" -f $usable.Count) `
    'Fix Pre-Logon VPN - Device Cert (SCEP) (Client Auth EKU, not expired, private key) after Pre-Logon VPN - Trusted Root. Deep-check: PLAPDX-Check-Certificate.ps1.'

# --- Report ------------------------------------------------------------------
$results | Format-Table Check, Result, Detail -AutoSize -Wrap
$fails = @($results | Where-Object { $_.Result -eq 'FAIL' })
Write-Host ""
if ($fails.Count -eq 0) {
    Write-Host "OVERALL: PASS — all device-tunnel preconditions met; the tunnel should connect at boot." -ForegroundColor Green
} else {
    Write-Host "OVERALL: FAIL — remedy each item below, then re-run:" -ForegroundColor Red
    foreach ($f in $fails) { Write-Host ("  [{0}] {1}" -f $f.Check, $f.Remedy) -ForegroundColor Yellow }
    Write-Host "See 06-troubleshooting.md (Device tunnel)." -ForegroundColor Yellow
}
