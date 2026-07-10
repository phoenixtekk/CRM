<#
.SYNOPSIS
    SENTCOST-Tiering.ps1 — tiering recommendations that protect detection coverage.
.DESCRIPTION
    PURPOSE
        Ranks tables by billable GB (like the audit) and cross-references them against the list of tables
        your active analytics rules / hunts actually query. Flags each top table as SAFE-TO-RETIER (high
        volume, not used by any rule) or KEEP-ON-ANALYTICS (a detection depends on it). Read-only.
    HOW TO RUN
        Connect-AzAccount first, then:
        powershell -ExecutionPolicy Bypass -File .\SENTCOST-Tiering.ps1 -ResourceGroup <rg> -WorkspaceName "..." -RuleTables "SecurityEvent,SigninLogs,DeviceEvents" -Days 31
        -RuleTables is the comma-separated list of tables your analytics rules/hunting/workbooks use
        (build it from Microsoft Sentinel > Analytics > Active rules — Implementation Step 2).
        Requires modules: Az.Accounts, Az.OperationalInsights.
    EXPECTED RESULTS
        A ranked list with a SAFE-TO-RETIER / KEEP flag per table, so you can pick a pilot table that is
        high-volume and not queried by any detection.
.NOTES
    Sentinel Solutions. Read-only. The recommendation is advisory — verify tier eligibility in your tenant.
#>
[CmdletBinding()]
param(
    [Parameter(Mandatory)] [string]$ResourceGroup,
    [Parameter(Mandatory)] [string]$WorkspaceName,
    [string]$RuleTables = '',
    [int]$Days = 31,
    [int]$Top = 15
)

Write-Host "=== SENTCOST Tiering — safe-to-retier analysis ===" -ForegroundColor Cyan
$ruleSet = @($RuleTables -split '[,; ]+' | Where-Object { $_ } | ForEach-Object { $_.Trim() })
if ($ruleSet.Count -eq 0) { Write-Host "WARNING: no -RuleTables supplied — everything will be flagged safe. Supply your detection tables (Requirement 2.4)." -ForegroundColor Yellow }
else { Write-Host ("Detection-dependent tables (KEEP): {0}" -f ($ruleSet -join ', ')) }

$ws = Get-AzOperationalInsightsWorkspace -ResourceGroupName $ResourceGroup -Name $WorkspaceName -ErrorAction SilentlyContinue
if (-not $ws) { Write-Host "Workspace NOT FOUND." -ForegroundColor Yellow; return }

$q = @"
Usage
| where TimeGenerated > ago(${Days}d)
| where IsBillable == true
| summarize BillableGB = round(sum(Quantity)/1000.0, 2) by DataType
| top ${Top} by BillableGB desc
"@
try { $rows = (Invoke-AzOperationalInsightsQuery -WorkspaceId $ws.CustomerId -Query $q -ErrorAction Stop).Results }
catch { Write-Host ("Query failed: {0}" -f $_.Exception.Message) -ForegroundColor Yellow; return }
if (-not $rows) { Write-Host "No billable usage returned." -ForegroundColor Yellow; return }

Write-Host ("`n{0,-42} {1,12}  {2}" -f 'DataType (table)', 'BillableGB', 'Recommendation') -ForegroundColor Cyan
Write-Host ("-" * 78)
foreach ($r in $rows) {
    $isDep = $ruleSet -contains $r.DataType
    if ($isDep) {
        Write-Host ("{0,-42} {1,12}  KEEP-ON-ANALYTICS (a detection queries this)" -f $r.DataType, $r.BillableGB) -ForegroundColor Red
    } else {
        Write-Host ("{0,-42} {1,12}  SAFE-TO-RETIER (candidate for Basic/Auxiliary or DCR filter)" -f $r.DataType, $r.BillableGB) -ForegroundColor Green
    }
}
Write-Host "`nPick the highest-volume SAFE-TO-RETIER table as your pilot (Implementation Step 3)."
Write-Host "Verify each candidate table is actually eligible for Basic/Auxiliary in your tenant before moving it." -ForegroundColor Yellow
