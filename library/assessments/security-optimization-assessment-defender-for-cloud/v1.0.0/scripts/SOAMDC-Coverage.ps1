<#
.SYNOPSIS
    SOAMDC-Coverage.ps1 — read-only Azure Resource Graph (KQL) analysis of Defender for Cloud plan
    coverage per resource type and machine agent/agentless coverage.
.DESCRIPTION
    PURPOSE
        Uses Azure Resource Graph (KQL) against the securityresources / resources tables to produce
        the coverage evidence behind the plan-coverage and agent/agentless domains: which resource
        types exist, and Defender for Cloud recommendations/assessments indicating unassessed or
        uncovered machines. Read-only — runs KQL queries only, changes nothing.
    HOW TO RUN
        Connect-AzAccount
        powershell -ExecutionPolicy Bypass -File .\SOAMDC-Coverage.ps1 `
            -SubscriptionId '<pilot subscription id>' -OutputPath ".\coverage.json"
        Requires Az.ResourceGraph. Read-only roles: Security Reader + Reader.
    EXPECTED RESULTS
        A JSON coverage summary: resource-type counts, and machines flagged by coverage-related
        recommendations. An empty machine set (with a note) is valid when no machines are in scope.
.NOTES
    White-label. Read-only. The KQL below targets Resource Graph tables that evolve — verify current
    table/column names against Microsoft docs if a query returns unexpected columns.
#>
[CmdletBinding()]
param(
    [string]$SubscriptionId,
    [string]$OutputPath = ".\coverage.json"
)

$ErrorActionPreference = 'Stop'
foreach ($m in 'Az.Accounts','Az.ResourceGraph') {
    if (-not (Get-Module -ListAvailable -Name $m)) {
        Write-Host "Installing $m (one-time, CurrentUser)..." -ForegroundColor Yellow
        Install-Module $m -Scope CurrentUser -Force -AllowClobber
    }
}
Import-Module Az.Accounts -ErrorAction Stop
Import-Module Az.ResourceGraph -ErrorAction Stop
if (-not (Get-AzContext)) { Connect-AzAccount | Out-Null }
if ($SubscriptionId) { Set-AzContext -Subscription $SubscriptionId | Out-Null }

$subs = if ($SubscriptionId) { @($SubscriptionId) } else { @((Get-AzContext).Subscription.Id) }
Write-Host "SOAMDC-Coverage — read-only KQL over Resource Graph. Subscriptions: $($subs -join ', ')" -ForegroundColor Cyan

function Invoke-Graph {
    param([string]$Query)
    try { return Search-AzGraph -Query $Query -Subscription $subs -First 1000 -ErrorAction Stop }
    catch { Write-Warning "Resource Graph query failed: $($_.Exception.Message)"; return @() }
}

# Resource-type inventory (what needs covering).
$kqlResourceTypes = @"
resources
| summarize count() by type
| order by count_ desc
"@
$resourceTypes = Invoke-Graph $kqlResourceTypes

# Defender for Cloud assessments that are Unhealthy and relate to coverage/agent onboarding.
$kqlCoverage = @"
securityresources
| where type == 'microsoft.security/assessments'
| extend status = tostring(properties.status.code), displayName = tostring(properties.displayName)
| where status == 'Unhealthy'
| where displayName has_any ('agent','Log Analytics','Defender','monitoring','endpoint protection','vulnerability')
| project displayName, status, resourceId = tostring(properties.resourceDetails.Id)
| summarize count() by displayName
| order by count_ desc
"@
$coverageGaps = Invoke-Graph $kqlCoverage

$out = [ordered]@{
    solution      = "SOAMDC"
    generatedUtc  = (Get-Date).ToUniversalTime().ToString("o")
    readOnly      = $true
    subscriptions = $subs
    resourceTypes = @($resourceTypes | Select-Object type, count_)
    coverageGaps  = @($coverageGaps | Select-Object displayName, count_)
    note          = if ((@($coverageGaps)).Count -eq 0) { "No unhealthy coverage/agent assessments returned (or no machines in scope / warm-up pending)." } else { "Unhealthy assessments indicate machines/resources not covered or not onboarded to Defender." }
}
$out | ConvertTo-Json -Depth 8 | Out-File -FilePath $OutputPath -Encoding utf8

Write-Host ("Resource types: {0}; coverage-gap assessment groups: {1}" -f @($resourceTypes).Count, @($coverageGaps).Count) -ForegroundColor Green
@($coverageGaps) | Select-Object -First 15 | ForEach-Object { Write-Host ("  {0}  x{1}" -f $_.displayName, $_.count_) -ForegroundColor Yellow }
Write-Host "Written: $OutputPath (read-only; no changes made)." -ForegroundColor Green
