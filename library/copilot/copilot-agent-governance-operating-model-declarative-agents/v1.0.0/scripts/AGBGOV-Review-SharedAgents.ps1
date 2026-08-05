<#
.SYNOPSIS
    AGBGOV-Review-SharedAgents.ps1 — Flag broadly-shared / ownerless agents for access review. READ-ONLY.

.DESCRIPTION
    Purpose:
        Surfaces the agents that most need a periodic access review: those shared org-wide ("Anyone
        in your organization" / AvailableTo = all), those shared to large groups, and those with no
        owner. This is the monthly sweep behind the "AGBGOV - Shared-Agent Access Review". It is
        READ-ONLY - it recommends review actions; a human (the Data & Security Reviewer) narrows or
        retires the agent through the admin center.

    How to run:
        # Commercial, Graph path (AI Administrator + CopilotPackages.Read.All + Agent 365 license):
        powershell -ExecutionPolicy Bypass -File .\AGBGOV-Review-SharedAgents.ps1 -CsvPath .\SharedAgents-Review.csv

        # Government / no-Graph path - pass an Agent Registry export (Agents > All agents > Registry > Export):
        powershell -ExecutionPolicy Bypass -File .\AGBGOV-Review-SharedAgents.ps1 -RegistryCsv .\ExportedAgents.csv -CsvPath .\SharedAgents-Review.csv -Environment USGov

        # -LargeGroupThreshold sets when a specific-group share counts as "broad" (default 200).

    Expected results:
        A CSV at -CsvPath listing every flagged agent with a Reason (OrgWideShare / NoOwner /
        Blocked / Broad) and a RecommendedAction (Review-Keep-Narrow-Retire). No tenant changes.

.NOTES
    Copilot category - governance - READ-ONLY. The copilotPackages API is preview/license-gated and
    not available in US Gov clouds; this script degrades to the Agent Registry CSV export. Verify
    current API and admin capabilities against Microsoft documentation.
#>

[CmdletBinding()]
param(
    [string]$CsvPath = '.\SharedAgents-Review.csv',

    [string]$RegistryCsv,

    [int]$LargeGroupThreshold = 200,

    [ValidateSet('Global', 'USGov', 'USGovDoD')]
    [string]$Environment = 'Global'
)

$ErrorActionPreference = 'Stop'
$graphEnv = switch ($Environment) { 'USGov' {'USGov'} 'USGovDoD' {'USGovDoD'} default {'Global'} }

function Get-AgentsFromGraph {
    try {
        Import-Module Microsoft.Graph.Authentication -ErrorAction Stop | Out-Null
        Write-Host "Connecting to Microsoft Graph ($graphEnv) ..." -ForegroundColor Cyan
        Connect-MgGraph -Environment $graphEnv -Scopes 'CopilotPackages.Read.All' -NoWelcome -ErrorAction Stop
        $uri = "/v1.0/copilot/admin/catalog/packages?`$filter=supportedHosts/any(h:h eq 'Copilot')"
        $all = @()
        do {
            $resp = Invoke-MgGraphRequest -Method GET -Uri $uri -ErrorAction Stop
            if ($resp.value) { $all += $resp.value }
            $uri = $resp.'@odata.nextLink'
        } while ($uri)
        foreach ($p in $all) {
            [pscustomobject]@{
                AgentName   = $p.displayName
                AgentId     = $p.id
                Owner       = if ($p.PSObject.Properties['owner']) { $p.owner } else { '' }
                AvailableTo = "$($p.availableTo)"
                IsBlocked   = [bool]$p.isBlocked
                Platform    = "$($p.platform)"
            }
        }
    }
    catch {
        Write-Warning ("Graph copilotPackages API unavailable: {0}" -f $_.Exception.Message)
        return $null
    }
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

function Get-AgentsFromCsv {
    param([string]$Path)
    if (-not (Test-Path $Path)) { throw "Registry CSV not found: $Path" }
    Import-Csv -Path $Path | ForEach-Object {
        $status = Get-FirstProp $_ @('Status')
        [pscustomobject]@{
            AgentName   = Get-FirstProp $_ @('Name', 'DisplayName')
            AgentId     = Get-FirstProp $_ @('Id', 'AgentId')
            Owner       = Get-FirstProp $_ @('Owner')
            AvailableTo = Get-FirstProp $_ @('AvailableTo', 'Availability')
            IsBlocked   = if ($status) { [bool]($status -match 'block') } else { $false }
            Platform    = Get-FirstProp $_ @('Platform')
        }
    }
}

# --- Acquire ----------------------------------------------------------------
$agents = $null
if ($RegistryCsv) { $agents = Get-AgentsFromCsv -Path $RegistryCsv }
else {
    $agents = Get-AgentsFromGraph
    if ($null -eq $agents) {
        Write-Host "Fallback: export Agents > All agents > Registry from the admin center and re-run with -RegistryCsv." -ForegroundColor Yellow
        throw "No agent data available."
    }
}

# --- Flag -------------------------------------------------------------------
$flagged = foreach ($a in $agents) {
    $reasons = @()
    if ("$($a.AvailableTo)" -match 'all')                 { $reasons += 'OrgWideShare' }
    if ([string]::IsNullOrWhiteSpace("$($a.Owner)"))      { $reasons += 'NoOwner' }
    if ($a.IsBlocked -eq $true)                           { $reasons += 'Blocked' }

    if ($reasons.Count -gt 0) {
        $action = if ($reasons -contains 'NoOwner') { 'Retire-or-Reassign' }
                  elseif ($reasons -contains 'OrgWideShare') { 'Review: Keep / Narrow' }
                  else { 'Review' }
        [pscustomobject]@{
            AgentName         = $a.AgentName
            AgentId           = $a.AgentId
            Owner             = $a.Owner
            AvailableTo       = $a.AvailableTo
            IsBlocked         = $a.IsBlocked
            Platform          = $a.Platform
            Reason            = ($reasons -join ';')
            RecommendedAction = $action
        }
    }
}

@($flagged) | Sort-Object Reason, AgentName | Export-Csv -Path $CsvPath -NoTypeInformation -Encoding UTF8
Write-Host "`nShared-agent review written to: $CsvPath" -ForegroundColor Green
Write-Host "`n===== AGBGOV shared-agent review =====" -ForegroundColor Cyan
Write-Host ("Agents evaluated......... {0}" -f @($agents).Count)
Write-Host ("Flagged for review....... {0}" -f @($flagged).Count)
Write-Host ("  Shared org-wide........ {0}" -f @($flagged | Where-Object Reason -match 'OrgWideShare').Count)
Write-Host ("  No owner............... {0}" -f @($flagged | Where-Object Reason -match 'NoOwner').Count)
Write-Host ("  Blocked................ {0}" -f @($flagged | Where-Object Reason -match 'Blocked').Count)
Write-Host "======================================`n"
Write-Host "Route each flagged agent to the Data & Security Reviewer; record the outcome in"
Write-Host "'AGBGOV - Shared-Agent Access Review' (Keep / Narrow / Retire)."
