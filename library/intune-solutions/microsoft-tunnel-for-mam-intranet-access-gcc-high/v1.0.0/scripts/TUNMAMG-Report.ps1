<#
.SYNOPSIS
    TUNMAMG-Report.ps1 — Produce a point-in-time report of Microsoft Tunnel for MAM on a GCC High / DoD tenant.
.DESCRIPTION
    PURPOSE
        Read-only reporting for Microsoft Tunnel for MAM on a US sovereign-cloud (GCC High / DoD)
        tenant. Summarizes Tunnel sites, server configurations, server health, the Tunnel-for-MAM
        app configuration and app protection policies, and target groups into a console summary and
        optional CSV/JSON export for audit evidence and change records. Replace placeholders like
        your-tenant-id with real values.
    HOW TO RUN
        powershell -ExecutionPolicy Bypass -File .\TUNMAMG-Report.ps1
        powershell -ExecutionPolicy Bypass -File .\TUNMAMG-Report.ps1 -OutputPath .\TUNMAMG-report
        (Graph scopes: DeviceManagementConfiguration.Read.All, DeviceManagementApps.Read.All,
         Group.Read.All. Uses -Environment USGov for GCC High; pass -Environment USGovDoD for DoD.)
    EXPECTED RESULTS
        A formatted console report. With -OutputPath, a .csv and .json are written next to that path.
        PASS = report generated. FAIL = Graph connection error.
.NOTES
    White-label — the repeatable way. Read-only against Microsoft Graph US Gov endpoints.
#>

[CmdletBinding()]
param(
    [ValidateSet('USGov', 'USGovDoD')]
    [string]$Environment = 'USGov',

    [string]$OutputPath
)

$ErrorActionPreference = 'Stop'

function Connect-GovGraph {
    param([string]$Env)
    $scopes = @('DeviceManagementConfiguration.Read.All', 'DeviceManagementApps.Read.All', 'Group.Read.All')
    if (-not (Get-Module -ListAvailable -Name Microsoft.Graph.Authentication)) {
        throw "Microsoft.Graph PowerShell SDK not found. Install-Module Microsoft.Graph -Scope CurrentUser"
    }
    Import-Module Microsoft.Graph.Authentication -ErrorAction Stop
    Write-Host "Connecting to Microsoft Graph (US Gov environment: $Env)..." -ForegroundColor Cyan
    Connect-MgGraph -Environment $Env -Scopes $scopes | Out-Null
    return Get-MgContext
}

function Invoke-GraphGet {
    param([string]$Uri)
    try { return Invoke-MgGraphRequest -Method GET -Uri $Uri -ErrorAction Stop }
    catch { Write-Warning "GET $Uri failed: $($_.Exception.Message)"; return $null }
}

try {
    $ctx  = Connect-GovGraph -Env $Environment
    $base = if ($Environment -eq 'USGovDoD') { 'https://dod-graph.microsoft.us/beta' } else { 'https://graph.microsoft.us/beta' }

    $report = [ordered]@{
        generatedUtc = (Get-Date).ToUniversalTime().ToString('o')
        tenantId     = $ctx.TenantId
        environment  = $ctx.Environment
        graphBase    = $base
        sites        = @()
        serverConfigs= @()
        appConfigs   = @()
        appProtection= @()
        groups       = @()
    }

    $sites = Invoke-GraphGet "$base/deviceManagement/microsoftTunnelSites"
    foreach ($s in ($sites.value)) {
        $servers = Invoke-GraphGet "$base/deviceManagement/microsoftTunnelSites/$($s.id)/microsoftTunnelServers"
        $report.sites += [pscustomobject]@{
            name          = $s.displayName
            id            = $s.id
            publicAddress = $s.publicAddress
            serverCount   = @($servers.value).Count
            serverHealth  = (@($servers.value | ForEach-Object { "$($_.displayName)=$($_.tunnelServerHealthStatus)" }) -join '; ')
        }
    }

    $sc = Invoke-GraphGet "$base/deviceManagement/microsoftTunnelConfigurations"
    foreach ($c in ($sc.value)) {
        $report.serverConfigs += [pscustomobject]@{ name = $c.displayName; id = $c.id; network = $c.network; defaultDomainSuffix = $c.defaultDomainSuffix }
    }

    $appCfg = Invoke-GraphGet "$base/deviceAppManagement/targetedManagedAppConfigurations"
    foreach ($a in ($appCfg.value | Where-Object { $_.displayName -match 'TUNMAMG' -or $_.displayName -match 'Tunnel' })) {
        $report.appConfigs += [pscustomobject]@{ name = $a.displayName; id = $a.id }
    }

    foreach ($t in @('androidManagedAppProtections', 'iosManagedAppProtections')) {
        $ap = Invoke-GraphGet "$base/deviceAppManagement/$t"
        foreach ($p in ($ap.value | Where-Object { $_.displayName -match 'TUNMAMG' -or $_.displayName -match 'Tunnel' })) {
            $report.appProtection += [pscustomobject]@{ platform = $t; name = $p.displayName; id = $p.id }
        }
    }

    $gbase = if ($Environment -eq 'USGovDoD') { 'https://dod-graph.microsoft.us/v1.0' } else { 'https://graph.microsoft.us/v1.0' }
    $grp = Invoke-GraphGet "$gbase/groups?`$filter=startswith(displayName,'GRP-TUNMAMG')"
    foreach ($g in ($grp.value)) { $report.groups += [pscustomobject]@{ name = $g.displayName; id = $g.id } }

    # Console output
    Write-Host "`n================ TUNMAMG Report ================" -ForegroundColor Cyan
    Write-Host ("Generated (UTC): {0}" -f $report.generatedUtc)
    Write-Host ("Tenant: {0}   Environment: {1}" -f $report.tenantId, $report.environment)
    Write-Host "`n-- Tunnel Sites --" -ForegroundColor Yellow
    if ($report.sites) { $report.sites | Format-Table -AutoSize } else { Write-Host " (none)" }
    Write-Host "-- Server Configurations --" -ForegroundColor Yellow
    if ($report.serverConfigs) { $report.serverConfigs | Format-Table -AutoSize name, id } else { Write-Host " (none)" }
    Write-Host "-- App Configuration Policies --" -ForegroundColor Yellow
    if ($report.appConfigs) { $report.appConfigs | Format-Table -AutoSize } else { Write-Host " (none)" }
    Write-Host "-- App Protection Policies --" -ForegroundColor Yellow
    if ($report.appProtection) { $report.appProtection | Format-Table -AutoSize } else { Write-Host " (none)" }
    Write-Host "-- Groups --" -ForegroundColor Yellow
    if ($report.groups) { $report.groups | Format-Table -AutoSize } else { Write-Host " (none)" }

    if ($OutputPath) {
        $json = "$OutputPath.json"
        $report | ConvertTo-Json -Depth 6 | Out-File -FilePath $json -Encoding UTF8
        $csv = "$OutputPath.csv"
        $flat = @()
        $flat += $report.sites         | ForEach-Object { [pscustomobject]@{ type='site';        name=$_.name; detail="$($_.publicAddress) health=$($_.serverHealth)" } }
        $flat += $report.serverConfigs | ForEach-Object { [pscustomobject]@{ type='serverConfig'; name=$_.name; detail=$_.id } }
        $flat += $report.appConfigs    | ForEach-Object { [pscustomobject]@{ type='appConfig';    name=$_.name; detail=$_.id } }
        $flat += $report.appProtection | ForEach-Object { [pscustomobject]@{ type="appProtection/$($_.platform)"; name=$_.name; detail=$_.id } }
        $flat += $report.groups        | ForEach-Object { [pscustomobject]@{ type='group';        name=$_.name; detail=$_.id } }
        $flat | Export-Csv -Path $csv -NoTypeInformation -Encoding UTF8
        Write-Host "`nSaved: $json" -ForegroundColor Green
        Write-Host "Saved: $csv"   -ForegroundColor Green
    }

    Write-Host "`nReport complete." -ForegroundColor Green
}
catch {
    Write-Error "Report failed: $($_.Exception.Message)"
    exit 1
}
finally {
    if (Get-MgContext -ErrorAction SilentlyContinue) { Disconnect-MgGraph | Out-Null }
}
