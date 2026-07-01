<#
.SYNOPSIS
    TUNMAM-Discovery.ps1 — inventory Microsoft Tunnel sites/servers/configs + Tunnel (MAM) config (Graph).
.DESCRIPTION
    PURPOSE
        Read-only readiness discovery. Enumerates Microsoft Tunnel sites, servers, and server
        configurations, and the app protection / app configuration (Tunnel for MAM) policies with
        their assigned groups, so you can confirm what exists before deploying.
    HOW TO RUN
        powershell -ExecutionPolicy Bypass -File .\TUNMAM-Discovery.ps1
        Requires the Microsoft Graph PowerShell SDK. Consents to read-only scopes.
    EXPECTED RESULTS
        A printed inventory of Tunnel sites/servers/configurations and the MAM app configuration /
        app protection policies with their target group IDs. No changes are made.
.NOTES
    Intune Solutions — Microsoft Tunnel for MAM. Read-only against Microsoft Graph.
#>
[CmdletBinding()] param()

if (-not (Get-Module -ListAvailable -Name Microsoft.Graph.Authentication)) {
    Install-Module Microsoft.Graph -Scope CurrentUser -Force -AllowClobber
}
Import-Module Microsoft.Graph.Authentication -ErrorAction Stop
Connect-MgGraph -Scopes 'DeviceManagementConfiguration.Read.All','DeviceManagementApps.Read.All' -NoWelcome

function Get-Val($uri) { try { (Invoke-MgGraphRequest -Method GET -Uri $uri).value } catch { @() } }

Write-Host "=== Microsoft Tunnel — Sites ===" -ForegroundColor Cyan
$sites = Get-Val '/beta/deviceManagement/microsoftTunnelSites'
foreach ($s in $sites) { Write-Host ("  {0}  (id: {1})  publicAddress: {2}" -f $s.displayName, $s.id, $s.publicAddress) }
if (-not $sites) { Write-Host "  (none found)" -ForegroundColor Yellow }

Write-Host "=== Microsoft Tunnel — Servers ===" -ForegroundColor Cyan
$servers = Get-Val '/beta/deviceManagement/microsoftTunnelServers'
foreach ($srv in $servers) { Write-Host ("  {0}  health: {1}  lastCheckIn: {2}" -f $srv.displayName, $srv.tunnelServerHealthStatus, $srv.lastCheckinDateTime) }
if (-not $servers) { Write-Host "  (none found)" -ForegroundColor Yellow }

Write-Host "=== Microsoft Tunnel — Server configurations ===" -ForegroundColor Cyan
$configs = Get-Val '/beta/deviceManagement/microsoftTunnelConfigurations'
foreach ($c in $configs) { Write-Host ("  {0}  DNS: {1}  network: {2}  splitDNS: {3}" -f $c.displayName, ($c.defaultDomainSuffix), ($c.network), ($c.splitDNS -join ',')) }
if (-not $configs) { Write-Host "  (none found)" -ForegroundColor Yellow }

function Assignments($uri) { try { (Invoke-MgGraphRequest -Method GET -Uri $uri).value | ForEach-Object { $_.target.groupId } | Where-Object { $_ } } catch { @() } }

Write-Host "=== App protection policies (MAM) ===" -ForegroundColor Cyan
$ios = Get-Val '/beta/deviceAppManagement/iosManagedAppProtections'
$and = Get-Val '/beta/deviceAppManagement/androidManagedAppProtections'
foreach ($p in @($ios + $and)) { Write-Host ("  {0}  (id: {1})" -f $p.displayName, $p.id) }
if (-not ($ios -or $and)) { Write-Host "  (none found)" -ForegroundColor Yellow }

Write-Host "=== Managed-app configuration policies (Tunnel for MAM) ===" -ForegroundColor Cyan
$appcfg = Get-Val '/beta/deviceAppManagement/targetedManagedAppConfigurations'
foreach ($a in $appcfg) {
    $grp = Assignments "/beta/deviceAppManagement/targetedManagedAppConfigurations/$($a.id)/assignments"
    Write-Host ("  {0}  [groups: {1}]" -f $a.displayName, ($grp -join ', '))
}
if (-not $appcfg) { Write-Host "  (none found)" -ForegroundColor Yellow }

Disconnect-MgGraph | Out-Null
