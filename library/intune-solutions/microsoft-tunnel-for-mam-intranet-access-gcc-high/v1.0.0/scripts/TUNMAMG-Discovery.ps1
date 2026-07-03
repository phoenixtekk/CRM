<#
.SYNOPSIS
    TUNMAMG-Discovery.ps1 — Inventory Microsoft Tunnel for MAM configuration on a GCC High / DoD tenant.
.DESCRIPTION
    PURPOSE
        Read-only discovery for Microsoft Tunnel for MAM on a US sovereign-cloud (GCC High / DoD)
        Intune tenant. Inventories Tunnel sites, server configurations, Tunnel-for-MAM app
        configuration and app protection policies, and target groups. Confirms the Microsoft Graph
        context is a US Government endpoint. Replace placeholders like your-tenant-id with real values.
    HOW TO RUN
        powershell -ExecutionPolicy Bypass -File .\TUNMAMG-Discovery.ps1
        (Graph scopes: DeviceManagementConfiguration.Read.All, DeviceManagementApps.Read.All,
         Group.Read.All. Uses -Environment USGov for GCC High; pass -Environment USGovDoD for DoD.)
    EXPECTED RESULTS
        A console inventory of Tunnel sites/server configs and MAM policies. The admin sees whether
        the expected objects exist. PASS = Graph context host ends in .us and the inventory returns.
        FAIL = Commercial (.com) context, or a Graph connection error.
.NOTES
    White-label — the repeatable way. Read-only against Microsoft Graph US Gov endpoints.
#>

[CmdletBinding()]
param(
    [ValidateSet('USGov', 'USGovDoD')]
    [string]$Environment = 'USGov',

    [string]$SolPrefix = 'TUNMAMG'
)

$ErrorActionPreference = 'Stop'

function Connect-GovGraph {
    param([string]$Env)
    $scopes = @(
        'DeviceManagementConfiguration.Read.All',
        'DeviceManagementApps.Read.All',
        'Group.Read.All'
    )
    Write-Host "Connecting to Microsoft Graph (US Gov environment: $Env)..." -ForegroundColor Cyan
    if (-not (Get-Module -ListAvailable -Name Microsoft.Graph.Authentication)) {
        throw "Microsoft.Graph PowerShell SDK not found. Install-Module Microsoft.Graph -Scope CurrentUser"
    }
    Import-Module Microsoft.Graph.Authentication -ErrorAction Stop
    Connect-MgGraph -Environment $Env -Scopes $scopes | Out-Null
    $ctx = Get-MgContext
    Write-Host "Connected. Tenant: $($ctx.TenantId)  Environment: $($ctx.Environment)" -ForegroundColor Green
    return $ctx
}

function Assert-GovEndpoint {
    param($Context)
    # US Gov Graph hosts end in .us (graph.microsoft.us / dod-graph.microsoft.us).
    if ($Context.Environment -notmatch 'USGov') {
        Write-Warning "Graph environment is '$($Context.Environment)', not a US Gov cloud. Reconnect with -Environment USGov or USGovDoD."
    } else {
        Write-Host "[PASS] Graph context is a US Government cloud ($($Context.Environment))." -ForegroundColor Green
    }
}

function Invoke-GraphGet {
    param([string]$Uri)
    try { return Invoke-MgGraphRequest -Method GET -Uri $Uri -ErrorAction Stop }
    catch { Write-Warning "GET $Uri failed: $($_.Exception.Message)"; return $null }
}

try {
    $ctx = Connect-GovGraph -Env $Environment
    Assert-GovEndpoint -Context $ctx

    # Graph beta is used for Microsoft Tunnel resources.
    $base = 'https://graph.microsoft.us/beta'
    if ($Environment -eq 'USGovDoD') { $base = 'https://dod-graph.microsoft.us/beta' }

    Write-Host "`n=== Microsoft Tunnel — Sites ===" -ForegroundColor Yellow
    $sites = Invoke-GraphGet "$base/deviceManagement/microsoftTunnelSites"
    if ($sites.value) {
        $sites.value | ForEach-Object { Write-Host (" - {0}  (id: {1})  publicAddress: {2}" -f $_.displayName, $_.id, $_.publicAddress) }
    } else { Write-Host " (none found)" }

    Write-Host "`n=== Microsoft Tunnel — Server configurations ===" -ForegroundColor Yellow
    $sc = Invoke-GraphGet "$base/deviceManagement/microsoftTunnelConfigurations"
    if ($sc.value) {
        $sc.value | ForEach-Object { Write-Host (" - {0}  (id: {1})" -f $_.displayName, $_.id) }
    } else { Write-Host " (none found)" }

    Write-Host "`n=== Microsoft Tunnel — Servers (health) ===" -ForegroundColor Yellow
    if ($sites.value) {
        foreach ($s in $sites.value) {
            $servers = Invoke-GraphGet "$base/deviceManagement/microsoftTunnelSites/$($s.id)/microsoftTunnelServers"
            if ($servers.value) {
                $servers.value | ForEach-Object { Write-Host ("   [{0}] server: {1}  health: {2}" -f $s.displayName, $_.displayName, $_.tunnelServerHealthStatus) }
            } else { Write-Host ("   [{0}] no servers registered" -f $s.displayName) }
        }
    }

    Write-Host "`n=== App configuration policies (managed apps) ===" -ForegroundColor Yellow
    $appCfg = Invoke-GraphGet "$base/deviceAppManagement/targetedManagedAppConfigurations"
    if ($appCfg.value) {
        $appCfg.value | Where-Object { $_.displayName -match $SolPrefix -or $_.displayName -match 'Tunnel' } |
            ForEach-Object { Write-Host (" - {0}  (id: {1})" -f $_.displayName, $_.id) }
    } else { Write-Host " (none found)" }

    Write-Host "`n=== App protection policies (Android + iOS) ===" -ForegroundColor Yellow
    foreach ($t in @('androidManagedAppProtections', 'iosManagedAppProtections')) {
        $ap = Invoke-GraphGet "$base/deviceAppManagement/$t"
        if ($ap.value) {
            $ap.value | Where-Object { $_.displayName -match $SolPrefix -or $_.displayName -match 'Tunnel' } |
                ForEach-Object { Write-Host (" - [$t] {0}  (id: {1})" -f $_.displayName, $_.id) }
        }
    }

    Write-Host "`n=== Target groups ($SolPrefix) ===" -ForegroundColor Yellow
    $grp = Invoke-GraphGet "https://graph.microsoft.us/v1.0/groups?`$filter=startswith(displayName,'GRP-$SolPrefix')"
    if ($Environment -eq 'USGovDoD') {
        $grp = Invoke-GraphGet "https://dod-graph.microsoft.us/v1.0/groups?`$filter=startswith(displayName,'GRP-$SolPrefix')"
    }
    if ($grp.value) {
        $grp.value | ForEach-Object { Write-Host (" - {0}  (id: {1})" -f $_.displayName, $_.id) }
    } else { Write-Host " (none found — create with TUNMAMG-Set-ScopeTargeting.ps1)" }

    Write-Host "`nDiscovery complete." -ForegroundColor Green
}
catch {
    Write-Error "Discovery failed: $($_.Exception.Message)"
    exit 1
}
finally {
    if (Get-MgContext -ErrorAction SilentlyContinue) { Disconnect-MgGraph | Out-Null }
}
