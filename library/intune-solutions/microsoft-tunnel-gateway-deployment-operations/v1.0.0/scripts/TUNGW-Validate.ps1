<#
.SYNOPSIS
    TUNGW-Validate.ps1 — validate a device's Microsoft Tunnel VPN profile assignment and resolve the
    Site / Server Configuration it points at. READ-ONLY.
.DESCRIPTION
    PURPOSE
        Answers "is this device correctly set up for the Tunnel?" without changing anything:
          1. Resolves the managed device by name and confirms it is enrolled and (optionally) compliant.
          2. Lists the Tunnel VPN configuration profile(s) targeting the device's groups and the
             per-device apply state (Succeeded / Error / Pending).
          3. Resolves the Site + Server Configuration the profile points at and prints the effective
             routing (listener port, DNS, client address pool, include/exclude routes) and auth method.
        Use it during the Pilot gate (Implementation Step 8/9) and whenever a single device won't
        connect.
    HOW TO RUN
        powershell -ExecutionPolicy Bypass -File .\TUNGW-Validate.ps1 -DeviceName 'iPad-Pilot-01'
        Sign in when prompted (read scopes only).
    EXPECTED RESULTS
        A per-device report: enrollment/compliance, the assigned Tunnel VPN profile(s) + apply state,
        and the resolved Site/Server Configuration routing + auth. No changes are made.
.NOTES
    White-label. Read-only. Documented Microsoft Graph deviceManagement endpoints; Tunnel Site/Config
    resources are on Graph BETA (noted). Verify current Graph coverage for your cloud.
#>
[CmdletBinding()] param(
    [Parameter(Mandatory)] [string] $DeviceName
)

Import-Module Microsoft.Graph.Authentication -ErrorAction Stop
Connect-MgGraph -Scopes 'DeviceManagementConfiguration.Read.All','DeviceManagementManagedDevices.Read.All','DeviceManagementServiceConfig.Read.All' -NoWelcome

function Get-Graph($uri) {
    try { (Invoke-MgGraphRequest -Method GET -Uri $uri).value }
    catch { Write-Host ("  Query failed: {0}`n    {1}" -f $uri, $_.Exception.Message) -ForegroundColor Yellow; $null }
}
$beta = 'https://graph.microsoft.com/beta/deviceManagement'
$v1   = 'https://graph.microsoft.com/v1.0/deviceManagement'

Write-Host "`n=== Tunnel VPN — Device Validation (read-only): $DeviceName ===" -ForegroundColor Cyan

# 1. Resolve the managed device.
$devEnc = [uri]::EscapeDataString($DeviceName)
$device = Get-Graph "$v1/managedDevices?`$filter=deviceName eq '$devEnc'" | Select-Object -First 1
if (-not $device) { Write-Host "Device '$DeviceName' not found in Intune." -ForegroundColor Red; Disconnect-MgGraph | Out-Null; return }
$colour = if ($device.complianceState -eq 'compliant') { 'Green' } else { 'Yellow' }
Write-Host ("`n[1] Device: {0} | OS: {1} {2} | Enrolled: {3} | Compliance: {4}" -f `
    $device.deviceName, $device.operatingSystem, $device.osVersion, $device.enrolledDateTime, $device.complianceState) -ForegroundColor $colour

# 2. Tunnel VPN profiles + per-device apply state.
Write-Host "`n[2] Tunnel VPN profile apply-state for this device:" -ForegroundColor Cyan
$profiles = Get-Graph "$v1/deviceConfigurations"
$vpn = $profiles | Where-Object { $_.'@odata.type' -match 'Vpn' }
$found = $false
foreach ($p in $vpn) {
    $statuses = Get-Graph "$v1/deviceConfigurations/$($p.id)/deviceStatuses"
    $mine = $statuses | Where-Object { $_.deviceDisplayName -eq $DeviceName }
    if ($mine) {
        $found = $true
        $sc = if ($mine.status -eq 'compliant' -or $mine.status -eq 'succeeded') { 'Green' } else { 'Yellow' }
        Write-Host ("  - Profile: {0} | State: {1} | LastReport: {2}" -f $p.displayName, $mine.status, $mine.lastReportedDateTime) -ForegroundColor $sc
        if ($p.microsoftTunnelSiteId) { Write-Host ("      -> targets Tunnel SiteId: {0}" -f $p.microsoftTunnelSiteId) -ForegroundColor DarkGray }
        if ($p.authenticationMethod) { Write-Host ("      -> auth method: {0}" -f $p.authenticationMethod) -ForegroundColor DarkGray }
    }
}
if (-not $found) { Write-Host "  (no Tunnel VPN profile reports a state for this device — check assignment + sync)" -ForegroundColor Yellow }

# 3. Resolve Site + Server Configuration routing for any Tunnel-targeted profile.
Write-Host "`n[3] Resolved Site / Server Configuration routing:" -ForegroundColor Cyan
$sites = Get-Graph "$beta/microsoftTunnelSites"
$mtProfiles = $vpn | Where-Object { $_.microsoftTunnelSiteId }
if ($mtProfiles) {
    foreach ($p in $mtProfiles) {
        $site = $sites | Where-Object { $_.id -eq $p.microsoftTunnelSiteId } | Select-Object -First 1
        if ($site) {
            Write-Host ("  Profile '{0}' -> Site '{1}' (FQDN {2})" -f $p.displayName, $site.displayName, $site.publicAddress)
            $cfgId = $site.microsoftTunnelConfiguration.id
            if ($cfgId) {
                $cfg = Get-Graph "$beta/microsoftTunnelConfigurations/$cfgId" 2>$null
                if ($cfg) {
                    Write-Host ("    Listener port: {0} | Client pool: {1}/{2}" -f $cfg.listenPort, $cfg.network, $cfg.subnetSize)
                    Write-Host ("    DNS: {0}" -f (($cfg.dnsServers) -join ', '))
                    Write-Host ("    Include routes: {0}" -f (($cfg.routesInclude) -join ', '))
                    Write-Host ("    Exclude routes: {0}" -f (($cfg.routesExclude) -join ', '))
                }
            }
        }
    }
} else { Write-Host "  (no Microsoft Tunnel-typed VPN profile resolved for this device)" -ForegroundColor Yellow }

Write-Host "`nValidation complete (read-only)." -ForegroundColor Green
Disconnect-MgGraph | Out-Null
