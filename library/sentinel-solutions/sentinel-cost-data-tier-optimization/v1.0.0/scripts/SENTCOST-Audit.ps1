<#
.SYNOPSIS
    SENTCOST-Audit.ps1 — ingestion-cost audit: rank Log Analytics tables by billable volume and cost.
.DESCRIPTION
    PURPOSE
        Queries the workspace Usage table for the last N days and ranks tables (DataType) by billable GB,
        with an estimated cost at a per-GB rate you supply and a per-day total trend. This is the "find
        the money" step. Read-only — makes no changes.
    HOW TO RUN
        Connect-AzAccount first, then:
        powershell -ExecutionPolicy Bypass -File .\SENTCOST-Audit.ps1 -ResourceGroup <rg> -WorkspaceName "Security Telemetry - Tenant - Workspace" -Days 31 -PerGBRate 2.30
        -PerGBRate is your region's Analytics per-GB ingestion price (verify in the Azure Pricing Calculator).
        Requires modules: Az.Accounts, Az.OperationalInsights.
    EXPECTED RESULTS
        A ranked table of billable GB per DataType with estimated monthly cost, the daily total trend,
        and the top contributors highlighted as optimization targets. Save the output as your baseline.
.NOTES
    Sentinel Solutions. Read-only.
#>
[CmdletBinding()]
param(
    [Parameter(Mandatory)] [string]$ResourceGroup,
    [Parameter(Mandatory)] [string]$WorkspaceName,
    [int]$Days = 31,
    [double]$PerGBRate = 0
)

Write-Host "=== SENTCOST Audit — top tables by billable volume (last {0} days) ===" -f $Days -ForegroundColor Cyan

$ws = Get-AzOperationalInsightsWorkspace -ResourceGroupName $ResourceGroup -Name $WorkspaceName -ErrorAction SilentlyContinue
if (-not $ws) { Write-Host ("Workspace NOT FOUND ({0}/{1})." -f $ResourceGroup, $WorkspaceName) -ForegroundColor Yellow; return }
$wsId = $ws.CustomerId

# Per-table billable GB
$q = @"
Usage
| where TimeGenerated > ago(${Days}d)
| where IsBillable == true
| summarize BillableGB = round(sum(Quantity) / 1000.0, 2) by DataType
| order by BillableGB desc
"@
try {
    $res = Invoke-AzOperationalInsightsQuery -WorkspaceId $wsId -Query $q -ErrorAction Stop
    $rows = $res.Results
} catch {
    Write-Host ("Query failed: {0}" -f $_.Exception.Message) -ForegroundColor Yellow
    Write-Host "Confirm Log Analytics Reader on the workspace (Requirement 2.2)." -ForegroundColor Yellow
    return
}

if (-not $rows) { Write-Host "No billable usage returned for the window." -ForegroundColor Yellow; return }

$monthFactor = 30.0 / $Days
Write-Host ("`n{0,-42} {1,12} {2,16}" -f 'DataType (table)', 'BillableGB', 'Est. $/month') -ForegroundColor Cyan
Write-Host ("-" * 72)
$rank = 0
foreach ($r in $rows) {
    $rank++
    $gb = [double]$r.BillableGB
    $estMonth = if ($PerGBRate -gt 0) { '{0:N2}' -f ($gb * $monthFactor * $PerGBRate) } else { 'set -PerGBRate' }
    $color = if ($rank -le 5) { 'Yellow' } else { 'Gray' }
    Write-Host ("{0,-42} {1,12} {2,16}" -f $r.DataType, $gb, $estMonth) -ForegroundColor $color
}
Write-Host ("`nTop 5 tables (highlighted) are your first optimization targets. Save this as your baseline.")

# Daily total trend
$qTrend = @"
Usage
| where TimeGenerated > ago(${Days}d)
| where IsBillable == true
| summarize GB = round(sum(Quantity)/1000.0, 2) by bin(TimeGenerated, 1d)
| order by TimeGenerated asc
"@
try {
    $t = (Invoke-AzOperationalInsightsQuery -WorkspaceId $wsId -Query $qTrend -ErrorAction Stop).Results
    if ($t) {
        $daily = ($t | Measure-Object -Property GB -Average).Average
        Write-Host ("`nAverage billable GB/day over window : {0:N2}  (use this as steady volume for SENTCOST-Forecast.ps1)" -f $daily) -ForegroundColor Green
    }
} catch {}

Write-Host "`nNext: SENTCOST-Tiering.ps1 to flag which top tables are safe to retier." -ForegroundColor Cyan
