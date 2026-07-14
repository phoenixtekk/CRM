<#
.SYNOPSIS
    TUNGW-Discovery.ps1 — inventory Microsoft Tunnel Sites, Server Configurations, servers/health, and
    VPN connection profiles in Intune. READ-ONLY.
.DESCRIPTION
    PURPOSE
        Establishes the "what exists today" baseline before you deploy or change a Tunnel Gateway:
          1. Lists Microsoft Tunnel Sites (the FQDN a Site fronts).
          2. Lists Tunnel Server Configurations (routing type, listener port, DNS, client address
             pool, split-tunnel include/exclude routes).
          3. Lists Tunnel servers and their reported health/last check-in per Site.
          4. Lists VPN configuration profiles whose connection type is Microsoft Tunnel, per platform.
        Use it so you do not collide with existing Sites/configs and to confirm objects after changes.
    HOW TO RUN
        Install the Graph SDK once:  Install-Module Microsoft.Graph -Scope CurrentUser
        Then:  powershell -ExecutionPolicy Bypass -File .\TUNGW-Discovery.ps1
        Sign in when prompted (read scopes only).
    EXPECTED RESULTS
        A printed inventory of Tunnel Sites, Server Configurations, servers + health, and Tunnel VPN
        profiles. No changes are made.
.NOTES
    White-label. Read-only. Uses documented Microsoft Graph deviceManagement endpoints via
    Invoke-MgGraphRequest. Several Microsoft Tunnel resources are exposed on the Graph BETA endpoint
    (microsoftTunnelSite / microsoftTunnelConfiguration / microsoftTunnelServer) — clearly noted where
    used. Verify current Graph coverage for your tenant/cloud (Commercial vs Government differ).
#>
[CmdletBinding()] param()

Import-Module Microsoft.Graph.Authentication -ErrorAction Stop
# Read-only scopes for discovery.
Connect-MgGraph -Scopes 'DeviceManagementConfiguration.Read.All','DeviceManagementServiceConfig.Read.All' -NoWelcome

Write-Host "`n=== Microsoft Tunnel Gateway — Discovery (read-only) ===" -ForegroundColor Cyan

# Helper: GET with graceful failure (returns .value array or $null).
function Get-Graph($uri) {
    try { (Invoke-MgGraphRequest -Method GET -Uri $uri).value }
    catch { Write-Host ("  Query failed: {0}`n    {1}" -f $uri, $_.Exception.Message) -ForegroundColor Yellow; $null }
}

$beta = 'https://graph.microsoft.com/beta/deviceManagement'

# 1. Tunnel Sites.
Write-Host "`n[1] Microsoft Tunnel Sites:" -ForegroundColor Cyan
$sites = Get-Graph "$beta/microsoftTunnelSites"
if ($sites) {
    $sites | ForEach-Object {
        Write-Host ("  - Site: {0} | FQDN/PublicAddress: {1} | Id: {2}" -f `
            $_.displayName, $_.publicAddress, $_.id)
    }
} else { Write-Host "  (none found or resource unavailable — verify Graph beta coverage)" -ForegroundColor Yellow }

# 2. Tunnel Server Configurations (routing, ports, DNS, address pool, routes).
Write-Host "`n[2] Tunnel Server Configurations:" -ForegroundColor Cyan
$configs = Get-Graph "$beta/microsoftTunnelConfigurations"
if ($configs) {
    $configs | ForEach-Object {
        Write-Host ("  - Config: {0}" -f $_.displayName)
        Write-Host ("      ListenerPort: {0} | ClientIPPool(network/mask): {1}/{2}" -f `
            $_.listenPort, $_.network, $_.subnetSize)
        Write-Host ("      DNS servers: {0}" -f (($_.dnsServers) -join ', '))
        Write-Host ("      Include (split-tunnel) routes: {0}" -f (($_.splitDns) -join ', '))
        Write-Host ("      Included routes: {0}" -f (($_.routesInclude) -join ', '))
        Write-Host ("      Excluded routes: {0}" -f (($_.routesExclude) -join ', '))
        Write-Host ("      NOTE: an empty include-route set with all-traffic routing = FULL tunnel.") -ForegroundColor DarkGray
    }
} else { Write-Host "  (none found or resource unavailable)" -ForegroundColor Yellow }

# 3. Tunnel servers + health per configuration/site.
Write-Host "`n[3] Tunnel servers + health:" -ForegroundColor Cyan
if ($sites) {
    foreach ($s in $sites) {
        $servers = Get-Graph "$beta/microsoftTunnelSites/$($s.id)/microsoftTunnelServers"
        Write-Host ("  Site '{0}':" -f $s.displayName)
        if ($servers) {
            $servers | ForEach-Object {
                $colour = if ($_.tunnelServerHealthStatus -match 'healthy|up') { 'Green' } else { 'Yellow' }
                Write-Host ("    - Server: {0} | Health: {1} | LastCheckIn: {2} | AgentVersion: {3}" -f `
                    $_.displayName, $_.tunnelServerHealthStatus, $_.lastCheckinDateTime, $_.agentImageDigest) -ForegroundColor $colour
            }
        } else { Write-Host "    (no servers joined this Site yet)" -ForegroundColor Yellow }
    }
} else { Write-Host "  (no Sites to enumerate servers for)" -ForegroundColor Yellow }

# 4. VPN profiles whose connection type is Microsoft Tunnel (per platform).
Write-Host "`n[4] VPN connection profiles (Microsoft Tunnel type):" -ForegroundColor Cyan
$profiles = Get-Graph 'https://graph.microsoft.com/v1.0/deviceManagement/deviceConfigurations'
if ($profiles) {
    $vpn = $profiles | Where-Object {
        $_.'@odata.type' -match 'VpnConfiguration' -or $_.'@odata.type' -match 'Vpn'
    }
    if ($vpn) {
        $vpn | ForEach-Object {
            $type = ($_.'@odata.type' -replace '#microsoft.graph.','')
            $mt = if ($_.connectionType -match 'microsoftTunnel' -or $_.microsoftTunnelSiteId) { ' [Microsoft Tunnel]' } else { '' }
            Write-Host ("  - {0}  [{1}]{2}" -f $_.displayName, $type, $mt)
        }
        Write-Host "  (Confirm the connection type = Microsoft Tunnel and the Site it targets in the profile.)" -ForegroundColor DarkGray
    } else { Write-Host "  (no VPN profiles found)" -ForegroundColor Yellow }
}

Write-Host "`nDiscovery complete (read-only)." -ForegroundColor Green
Disconnect-MgGraph | Out-Null
