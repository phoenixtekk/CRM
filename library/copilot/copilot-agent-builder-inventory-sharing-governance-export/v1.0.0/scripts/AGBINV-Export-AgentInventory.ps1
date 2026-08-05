<#
.SYNOPSIS
    AGBINV-Export-AgentInventory.ps1 — export an inventory of Copilot Agent Builder (declarative)
    agents to CSV, filtered to exclude Copilot Studio and other agent types.
.DESCRIPTION
    PURPOSE
        Lists Copilot packages via GET /copilot/admin/catalog/packages, filtered to the Agent Builder
        platform, and keeps only declarative agents. Writes one row per agent (name, owner-adjacent
        fields, status, dates, publish state). This is the inventory backbone of the governance
        register. Read-only; changes nothing.
    HOW TO RUN
        pwsh -File .\AGBINV-Export-AgentInventory.ps1 -Environment Global `
             -OutputPath C:\AgentGovernance\Exports
        Government clouds:  -Environment USGov | USGovDoD  (NOTE: the Package API is Global-only today;
        in Government clouds use the admin center export — Path A. The script reports if unavailable.)
        Required scope: CopilotPackages.Read.All
    EXPECTED RESULTS
        AgentBuilder-Inventory_<yyyyMMdd-HHmm>.csv in -OutputPath — one row per Agent Builder agent
        with Id, DisplayName, Type, Publisher, Platform, ElementTypes, IsBlocked, AvailableTo,
        DeployedTo, LastModifiedDateTime, Version. AvailableTo/DeployedTo are all/some/none summaries;
        the per-recipient sharing comes from AGBINV-Export-AgentSharing.ps1.
.NOTES
    Copilot Solutions — the repeatable way. Read-only against Microsoft Graph. Uses v1.0; falls back to
    beta only if v1.0 returns 404 for the resource. Preview-volatile — verify against current docs.
#>

[CmdletBinding()]
param(
    [ValidateSet('Global','USGov','USGovDoD')]
    [string] $Environment = 'Global',
    [string] $OutputPath = '.',
    # The exact platform string the API uses for Agent Builder agents. Verify against current docs if
    # the filter returns nothing (Microsoft may adjust the literal).
    [string] $AgentBuilderPlatform = 'Microsoft 365 Copilot Agent Builder'
)

$ErrorActionPreference = 'Stop'

$graphEnv = switch ($Environment) {
    'USGov'    { @{ Env = 'USGov';    Base = 'https://graph.microsoft.us' } }
    'USGovDoD' { @{ Env = 'USGovDoD'; Base = 'https://dod-graph.microsoft.us' } }
    default    { @{ Env = 'Global';   Base = 'https://graph.microsoft.com' } }
}
$base = "$($graphEnv.Base)/v1.0"

function Connect-Graph {
    if (-not (Get-Module -ListAvailable -Name Microsoft.Graph.Authentication)) {
        throw "Microsoft Graph SDK not found. Run: Install-Module Microsoft.Graph -Scope CurrentUser"
    }
    Import-Module Microsoft.Graph.Authentication -ErrorAction Stop
    if (-not (Get-MgContext)) { Connect-MgGraph -Environment $graphEnv.Env -Scopes 'CopilotPackages.Read.All' | Out-Null }
}

function Invoke-GraphGet {
    param([Parameter(Mandatory)][string] $Uri)
    $items = @(); $next = $Uri
    while ($next) {
        $resp = Invoke-MgGraphRequest -Method GET -Uri $next
        if ($resp.value) { $items += $resp.value } elseif ($resp) { $items += $resp }
        $next = $resp.'@odata.nextLink'
    }
    return $items
}

Connect-Graph
if ($Environment -ne 'Global') {
    Write-Host "NOTE: the Copilot Package Management API is documented as Global-only. In $Environment it may return 404 — if so, use Path A (admin center export). Verify for GCC High." -ForegroundColor Yellow
}

# Server-side filter to Agent Builder; if the literal changes, we still client-side filter below.
$filter = [uri]::EscapeDataString("platform eq '$AgentBuilderPlatform'")
$uri = "$base/copilot/admin/catalog/packages?`$filter=$filter"
Write-Host "Listing Agent Builder packages from $base ..." -ForegroundColor Cyan

$packages = @()
try {
    $packages = Invoke-GraphGet -Uri $uri
}
catch {
    Write-Host "Filtered list failed (the platform literal may differ). Retrying unfiltered and filtering client-side ..." -ForegroundColor Yellow
    try {
        $all = Invoke-GraphGet -Uri "$base/copilot/admin/catalog/packages"
        $packages = $all | Where-Object { "$($_.platform)" -eq $AgentBuilderPlatform }
    }
    catch {
        Write-Host "Could not read packages. Run AGBINV-Connect-Preflight.ps1 to decode the failure (401/403/404)." -ForegroundColor Red
        throw
    }
}

# Keep only declarative agents (exclude custom-engine / add-ins / bots-only, and any residual studio).
$agents = $packages | Where-Object {
    $et = @($_.elementTypes) | ForEach-Object { "$_".ToLower() }
    ($et -contains 'declarativeagent') -and ("$($_.platform)" -eq $AgentBuilderPlatform)
}

if (-not $agents) {
    Write-Host "No Agent Builder declarative agents returned. Either none exist, or the filter excluded them (T8). Check the admin center Registry (Platform = '$AgentBuilderPlatform')." -ForegroundColor Yellow
    return
}

$rows = foreach ($a in $agents) {
    [pscustomobject]@{
        SnapshotUtc          = (Get-Date).ToUniversalTime().ToString('s')
        Id                   = $a.id
        DisplayName          = $a.displayName
        Type                 = $a.type
        Publisher            = $a.publisher
        Platform             = $a.platform
        ElementTypes         = (@($a.elementTypes) -join ';')
        IsBlocked            = $a.isBlocked
        AvailableTo          = $a.availableTo
        DeployedTo           = $a.deployedTo
        Version              = $a.version
        LastModifiedDateTime = $a.lastModifiedDateTime
    }
}

if (-not (Test-Path $OutputPath)) { New-Item -ItemType Directory -Path $OutputPath -Force | Out-Null }
$stamp = (Get-Date).ToString('yyyyMMdd-HHmm')
$csv = Join-Path $OutputPath "AgentBuilder-Inventory_$stamp.csv"
$rows | Export-Csv -Path $csv -NoTypeInformation -Encoding UTF8
Write-Host ("Wrote {0}  ({1} Agent Builder agents)" -f $csv, $rows.Count) -ForegroundColor Green
