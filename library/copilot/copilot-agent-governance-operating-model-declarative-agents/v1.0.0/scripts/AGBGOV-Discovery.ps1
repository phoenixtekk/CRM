<#
.SYNOPSIS
    AGBGOV-Discovery.ps1 — Governance baseline of declarative agents in the tenant.

.DESCRIPTION
    Purpose:
        Produces a one-time GOVERNANCE BASELINE of the declarative "Agent Builder" (and Copilot
        Studio) agents in the tenant: name, id, build platform, owner, and sharing posture. This is
        the seed for the "AGBGOV - Agent Register" and the "before" picture the Agent Review Board
        holds the sponsor's attention with. It is READ-ONLY.

        This is a lightweight baseline, NOT the deep, repeatable inventory/sharing export — that
        lives in the sibling product "Copilot Agent Builder - Inventory, Sharing Governance &
        Export", which owns the Graph endpoint diagnostic. Use this to start; use the sibling for
        ongoing, exhaustive export.

    How to run:
        # Commercial tenant, Graph path (requires AI Administrator + CopilotPackages.Read.All + a
        # Microsoft Agent 365 license):
        powershell -ExecutionPolicy Bypass -File .\AGBGOV-Discovery.ps1 -CsvPath .\AgentEstate-Baseline.csv

        # Government tenant, or where the Graph API is unavailable — export the agent list from
        # Microsoft 365 admin center (Agents > All agents > Registry > Export) and pass it in:
        powershell -ExecutionPolicy Bypass -File .\AGBGOV-Discovery.ps1 -RegistryCsv .\ExportedAgents.csv -CsvPath .\AgentEstate-Baseline.csv -Environment USGov

    Expected results:
        A CSV at -CsvPath with one row per declarative agent (AgentName, AgentId, Platform,
        ElementType, Owner, AvailableTo, DeployedTo, IsBlocked, LastModified) plus a summary of the
        five baseline metrics printed to the console. No changes are made to the tenant.

.NOTES
    Copilot category - governance - READ-ONLY. Requires the Microsoft.Graph PowerShell SDK.
    The copilotPackages Package Management API (GET /copilot/admin/catalog/packages) is
    preview/license-gated and is NOT available in US Gov (L4/L5); this script degrades to the
    Agent Registry CSV export automatically. Verify current API availability against Microsoft docs.
#>

[CmdletBinding()]
param(
    [Parameter(Mandatory = $true)]
    [string]$CsvPath,

    # Fallback / Government path: a CSV exported from Microsoft 365 admin center
    # (Agents > All agents > Registry > Export). When supplied, the Graph API is skipped.
    [string]$RegistryCsv,

    [ValidateSet('Global', 'USGov', 'USGovDoD')]
    [string]$Environment = 'Global'
)

$ErrorActionPreference = 'Stop'

# Map the friendly cloud name to the Connect-MgGraph environment name and the Graph base URL.
$graphEnv = switch ($Environment) {
    'USGov'    { 'USGov' }        # GCC High  - https://graph.microsoft.us
    'USGovDoD' { 'USGovDoD' }     # DoD (L5)  - https://dod-graph.microsoft.us
    default    { 'Global' }       # Commercial - https://graph.microsoft.com
}

# Returns the value of the first present (non-empty) property name, else $default.
# Written without the PS7 ternary operator so it also runs on Windows PowerShell 5.1.
function Get-FirstProp {
    param($Row, [string[]]$Names, $Default = '')
    foreach ($n in $Names) {
        if ($Row.PSObject.Properties[$n]) {
            $v = "$($Row.$n)"
            if (-not [string]::IsNullOrWhiteSpace($v)) { return $Row.$n }
        }
    }
    return $Default
}

function Read-AgentsFromRegistryCsv {
    param([string]$Path)
    if (-not (Test-Path $Path)) { throw "Registry CSV not found: $Path" }
    Write-Host "Reading agents from Agent Registry export: $Path" -ForegroundColor Cyan
    $rows = Import-Csv -Path $Path
    # The admin-center export column names can vary; map defensively.
    foreach ($r in $rows) {
        $status = Get-FirstProp $r @('Status')
        [pscustomobject]@{
            AgentName    = Get-FirstProp $r @('Name', 'DisplayName')
            AgentId      = Get-FirstProp $r @('Id', 'AgentId')
            Platform     = Get-FirstProp $r @('Platform')
            ElementType  = Get-FirstProp $r @('ElementType', 'Type')
            Owner        = Get-FirstProp $r @('Owner')
            AvailableTo  = Get-FirstProp $r @('AvailableTo', 'Availability')
            DeployedTo   = Get-FirstProp $r @('DeployedTo')
            IsBlocked    = if ($status) { [bool]($status -match 'block') } else { '' }
            LastModified = Get-FirstProp $r @('Last Modified', 'LastModified')
            Source       = 'RegistryExport'
        }
    }
}

function Read-AgentsFromGraph {
    # Attempts the copilotPackages Package Management API. Returns $null on any failure so the
    # caller can degrade to the CSV export. NEVER fabricates a response shape.
    try {
        Import-Module Microsoft.Graph.Authentication -ErrorAction Stop | Out-Null
        Write-Host "Connecting to Microsoft Graph ($graphEnv) with CopilotPackages.Read.All ..." -ForegroundColor Cyan
        Connect-MgGraph -Environment $graphEnv -Scopes 'CopilotPackages.Read.All' -NoWelcome -ErrorAction Stop

        # v1.0 endpoint; filter to agents surfaced in Copilot. This API requires a Microsoft
        # Agent 365 license and is not available in US Gov clouds. It is preview-adjacent -
        # verify current availability against Microsoft documentation.
        $uri = "/v1.0/copilot/admin/catalog/packages?`$filter=supportedHosts/any(h:h eq 'Copilot')"
        $all = @()
        do {
            $resp = Invoke-MgGraphRequest -Method GET -Uri $uri -ErrorAction Stop
            if ($resp.value) { $all += $resp.value }
            $uri = $resp.'@odata.nextLink'
        } while ($uri)

        Write-Host ("Retrieved {0} package(s) from Graph." -f $all.Count) -ForegroundColor Green
        foreach ($p in $all) {
            [pscustomobject]@{
                AgentName    = $p.displayName
                AgentId      = $p.id
                Platform     = ($p.platform)
                ElementType  = ($p.elementTypes -join ';')
                Owner        = if ($p.PSObject.Properties['owner']) { $p.owner } else { '' }
                AvailableTo  = $p.availableTo
                DeployedTo   = $p.deployedTo
                IsBlocked    = $p.isBlocked
                LastModified = $p.lastModifiedDateTime
                Source       = 'GraphPackagesApi'
            }
        }
    }
    catch {
        Write-Warning ("Graph copilotPackages API not available or not authorized: {0}" -f $_.Exception.Message)
        Write-Warning "This is expected in Government tenants and in tenants without a Microsoft Agent 365 license."
        Write-Host    "Fallback: export the agent list from Microsoft 365 admin center (Agents > All agents > Registry > Export)" -ForegroundColor Yellow
        Write-Host    "then re-run with:  -RegistryCsv .\ExportedAgents.csv" -ForegroundColor Yellow
        return $null
    }
}

# --- Acquire the agent set ---------------------------------------------------
$agents = $null
if ($RegistryCsv) {
    $agents = Read-AgentsFromRegistryCsv -Path $RegistryCsv
}
else {
    $agents = Read-AgentsFromGraph
    if ($null -eq $agents) {
        throw "No agent data available. Re-run with -RegistryCsv pointing at an admin-center Agent Registry export."
    }
}

# --- Emit + summarize --------------------------------------------------------
$agents | Sort-Object AgentName | Export-Csv -Path $CsvPath -NoTypeInformation -Encoding UTF8
Write-Host "`nGovernance baseline written to: $CsvPath" -ForegroundColor Green

$declarative = $agents | Where-Object { $_.ElementType -match 'DeclarativeAgent' -or $_.ElementType -eq '' }
$orgWide     = $agents | Where-Object { "$($_.AvailableTo)" -match 'all' }
$noOwner     = $agents | Where-Object { [string]::IsNullOrWhiteSpace("$($_.Owner)") }
$builder     = $agents | Where-Object { "$($_.Platform)" -match 'Agent Builder' }

Write-Host "`n===== AGBGOV baseline summary =====" -ForegroundColor Cyan
Write-Host ("Total agents (Copilot host).......... {0}" -f @($agents).Count)
Write-Host ("Declarative agents................... {0}" -f @($declarative).Count)
Write-Host ("Shared org-wide (AvailableTo=all).... {0}" -f @($orgWide).Count)
Write-Host ("No owner recorded.................... {0}" -f @($noOwner).Count)
Write-Host ("Built in Agent Builder (gap surface). {0}" -f @($builder).Count)
Write-Host "==================================`n"
Write-Host "Next: seed 'AGBGOV - Agent Register' from this CSV (Implementation Step 3), and review"
Write-Host "the Agents without owners / Unmanaged / Agents at risk tiles in the admin center."
