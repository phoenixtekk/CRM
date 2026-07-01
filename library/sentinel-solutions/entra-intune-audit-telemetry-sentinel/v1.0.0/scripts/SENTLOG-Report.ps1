<#
.SYNOPSIS
    SENTLOG-Report.ps1 — log-coverage and retention report for the audit-telemetry workspace.
.DESCRIPTION
    PURPOSE
        Summarizes what telemetry the workspace is actually holding: per-table ingestion volume over a
        window, and the configured retention for the key tables — so you can see coverage gaps and check
        retention against the compliance decision. Read-only.
    HOW TO RUN
        Connect-AzAccount first, then:
        powershell -ExecutionPolicy Bypass -File .\SENTLOG-Report.ps1 -ResourceGroup <rg> -WorkspaceName "Security Telemetry - Tenant - Workspace" -Days 7 -CsvPath C:\Temp\sentlog.csv
        Requires modules: Az.Accounts, Az.OperationalInsights.
    EXPECTED RESULTS
        A volume-by-table breakdown (GB over the window) and the retention (interactive/total days) per
        key table, optionally exported to CSV.
.NOTES
    Sentinel Solutions. Read-only.
#>
[CmdletBinding()]
param(
    [Parameter(Mandatory)] [string]$ResourceGroup,
    [Parameter(Mandatory)] [string]$WorkspaceName,
    [int]$Days = 7,
    [string[]]$KeyTables = @('SigninLogs','AuditLogs'),
    [string]$CsvPath
)

Write-Host "=== SENTLOG Report — coverage & retention ===" -ForegroundColor Cyan
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

if ($CsvPath) {
    $rows | Export-Csv -Path $CsvPath -NoTypeInformation
    Write-Host ("Saved volume report to {0}" -f $CsvPath) -ForegroundColor Green
}
