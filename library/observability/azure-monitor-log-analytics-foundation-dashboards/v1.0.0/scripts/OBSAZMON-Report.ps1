<#
.SYNOPSIS
    OBSAZMON-Report.ps1 — diagnostics coverage + ingestion/cost report (read-only).
.DESCRIPTION
    PURPOSE
        Produces the governance/cost evidence for the foundation: the percentage of in-scope resources
        that have a diagnostic setting routing to the workspace (coverage — before/after remediation),
        the diagnostics policy's compliance state, and the estimated billable ingestion by data type
        (the top ingesters that drive cost). Read-only — makes no changes.
    HOW TO RUN
        powershell -ExecutionPolicy Bypass -File .\OBSAZMON-Report.ps1 `
            -WorkspaceName log-obsazmon-platform -WorkspaceRG rg-obsazmon-monitor -CsvFolder C:\Temp\obsazmon
        Requires Az PowerShell (incl. Az.OperationalInsights) + Connect-AzAccount.
    EXPECTED RESULTS
        Console summary + optional CSVs: coverage %, policy compliance, and billable GB by DataType
        (last 24h). Compare coverage before vs after each remediation wave; watch the top ingesters
        against your cost plan.
.NOTES
    White-label. Read-only. No credentials stored. Ingestion figures are estimates — VERIFY against
    Cost Management / current pricing.
.EXAMPLE
    .\OBSAZMON-Report.ps1 -WorkspaceName log-obsazmon-platform -WorkspaceRG rg-obsazmon-monitor
#>
[CmdletBinding()] param(
    [Parameter(Mandatory)] [string]$WorkspaceName,
    [Parameter(Mandatory)] [string]$WorkspaceRG,
    [string]$CsvFolder
)

foreach ($m in 'Az.Accounts','Az.Resources','Az.Monitor','Az.OperationalInsights') {
    if (-not (Get-Module -ListAvailable -Name $m)) { Install-Module $m -Scope CurrentUser -Force -AllowClobber }
    Import-Module $m -ErrorAction Stop
}
if (-not (Get-AzContext)) { Connect-AzAccount | Out-Null }

function Save-Csv($rows, $name) {
    if ($CsvFolder -and $rows) {
        if (-not (Test-Path $CsvFolder)) { New-Item -ItemType Directory -Path $CsvFolder | Out-Null }
        $p = Join-Path $CsvFolder "$name.csv"; $rows | Export-Csv -Path $p -NoTypeInformation
        Write-Host "  saved $p" -ForegroundColor Green
    }
}

$ws = Get-AzOperationalInsightsWorkspace -ResourceGroupName $WorkspaceRG -Name $WorkspaceName -ErrorAction Stop

# --- Diagnostics coverage ------------------------------------------------------
Write-Host "`n=== Diagnostics coverage ===" -ForegroundColor Cyan
$res = Get-AzResource
$covered = 0; $total = 0
foreach ($r in $res) {
    try {
        $ds = Get-AzDiagnosticSetting -ResourceId $r.ResourceId -ErrorAction Stop
        $total++
        if ($ds | Where-Object { $_.WorkspaceId -eq $ws.ResourceId }) { $covered++ }
    } catch { }   # resource type without diagnostic-setting support — skip from denominator
}
$pct = if ($total) { [math]::Round(($covered / $total) * 100, 1) } else { 0 }
Write-Host ("  Resources routing to {0}: {1}/{2} ({3}%)" -f $WorkspaceName,$covered,$total,$pct) -ForegroundColor Green

# --- Diagnostics policy compliance --------------------------------------------
Write-Host "`n=== Diagnostics policy compliance ===" -ForegroundColor Cyan
try {
    $states = Get-AzPolicyState -Filter "PolicyAssignmentName eq 'OBSAZMON-Policy-Diagnostics-Subscription'" -ErrorAction Stop
    $summary = $states | Group-Object ComplianceState | ForEach-Object { [pscustomobject]@{ State=$_.Name; Count=$_.Count } }
    $summary | Format-Table -AutoSize
    Save-Csv $summary 'policy-compliance'
} catch { Write-Host "  (policy state not available yet — allow time to evaluate)" -ForegroundColor Yellow }

# --- Billable ingestion by DataType (last 24h) --------------------------------
Write-Host "`n=== Billable ingestion by DataType (last 24h, estimate) ===" -ForegroundColor Cyan
$kql = @"
Usage
| where TimeGenerated > ago(24h)
| where IsBillable == true
| summarize BillableGB = round(sum(Quantity)/1000,3) by DataType
| order by BillableGB desc
"@
try {
    $q = Invoke-AzOperationalInsightsQuery -WorkspaceId $ws.CustomerId -Query $kql -ErrorAction Stop
    $rows = $q.Results | ForEach-Object { [pscustomobject]@{ DataType=$_.DataType; BillableGB=$_.BillableGB } }
    $rows | Format-Table -AutoSize
    Save-Csv $rows 'ingestion-by-datatype'
    $totalGb = ($rows | Measure-Object BillableGB -Sum).Sum
    Write-Host ("  Total billable (24h): {0} GB — VERIFY against Cost Management / current pricing." -f $totalGb) -ForegroundColor Yellow
} catch { Write-Host "  (no ingestion data yet — telemetry may not be flowing)" -ForegroundColor Yellow }

Write-Host "`nReport complete. Track coverage % upward per remediation wave; keep top ingesters within the cost plan." -ForegroundColor Cyan
