<#
.SYNOPSIS
    SENTLOGG-Report.ps1 — log-coverage and retention report for the audit-telemetry workspace (GCC High).
.DESCRIPTION
    PURPOSE
        Summarizes what telemetry the Azure Government workspace is holding: per-table ingestion volume
        over a window, and the configured retention for the key tables — so you can see coverage gaps and
        check retention against the compliance decision. Read-only. Use your-resource-group and
        your-workspace-name; optional your-report-path for CSV.
    HOW TO RUN
        Connect-AzAccount -Environment AzureUSGovernment first, then:
        powershell -ExecutionPolicy Bypass -File .\SENTLOGG-Report.ps1 -ResourceGroup your-resource-group -WorkspaceName "Security Telemetry - Tenant - Workspace" -Days 7 -CsvPath your-report-path.csv
        Requires modules: Az.Accounts, Az.OperationalInsights.
    EXPECTED RESULTS
        A volume-by-table breakdown (GB over the window) and the retention (interactive/total days) per
        key table, optionally exported to CSV. Pass = coverage and retention match the plan.
.NOTES
    White-label — the repeatable way. Read-only against Microsoft Graph/Azure US Gov endpoints.
#>
[CmdletBinding()]
param(
    [Parameter(Mandatory)] [string]$ResourceGroup,
    [Parameter(Mandatory)] [string]$WorkspaceName,
    [int]$Days = 7,
    [string[]]$KeyTables = @('SigninLogs','AuditLogs','IntuneAuditLogs'),
    [string]$CsvPath
)

Write-Host "=== SENTLOGG Report — coverage & retention (GCC High / Azure Government) ===" -ForegroundColor Cyan

$ctx = Get-AzContext -ErrorAction SilentlyContinue
if (-not $ctx) { Write-Host "Not connected. Run: Connect-AzAccount -Environment AzureUSGovernment" -ForegroundColor Yellow; return }
if ($ctx.Environment.Name -ne 'AzureUSGovernment') {
    Write-Host ("WARNING: Az environment is '{0}', not 'AzureUSGovernment'." -f $ctx.Environment.Name) -ForegroundColor Yellow
}

$ws = Get-AzOperationalInsightsWorkspace -ResourceGroupName $ResourceGroup -Name $WorkspaceName -ErrorAction Stop

# Ingestion volume by data type
Write-Host ("`n--- Ingestion volume (last {0}d) ---" -f $Days) -ForegroundColor Cyan
$kql = "Usage | where TimeGenerated > ago(${Days}d) | summarize GB=round(sum(Quantity)/1000,3) by DataType | order by GB desc"
$rows = @()
try {
    $r = Invoke-AzOperationalInsightsQuery -WorkspaceId $ws.CustomerId -Query $kql -ErrorAction Stop
    $rows = $r.Results | ForEach-Object { [pscustomobject]@{ DataType=$_.DataType; GB=[double]$_.GB } }
    $rows | Format-Table -AutoSize
    Write-Host ("Total GB over window: {0}" -f ([math]::Round(($rows | Measure-Object GB -Sum).Sum,3))) -ForegroundColor Cyan
} catch {
    Write-Host ("Usage query failed: {0}" -f $_.Exception.Message) -ForegroundColor Yellow
}

# Retention per key table
Write-Host "`n--- Retention (key tables) ---" -ForegroundColor Cyan
$ret = @()
foreach ($t in $KeyTables) {
    try {
        $tbl = Get-AzOperationalInsightsTable -ResourceGroupName $ResourceGroup -WorkspaceName $WorkspaceName -TableName $t -ErrorAction Stop
        $obj = [pscustomobject]@{ Table=$t; InteractiveDays=$tbl.RetentionInDays; TotalDays=$tbl.TotalRetentionInDays }
    } catch {
        $obj = [pscustomobject]@{ Table=$t; InteractiveDays='n/a'; TotalDays='n/a' }
    }
    $ret += $obj
}
$ret | Format-Table -AutoSize
Write-Host ("Workspace default retention: {0} days" -f $ws.RetentionInDays)
Write-Host "(Confirm retention meets your compliance mandate — CMMC / DFARS 7012 / FedRAMP audit-log retention.)"

if ($CsvPath) {
    $rows | Export-Csv -Path $CsvPath -NoTypeInformation
    Write-Host ("Saved volume report to {0}" -f $CsvPath) -ForegroundColor Green
}
