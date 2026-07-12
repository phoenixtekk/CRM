<#
.SYNOPSIS
    ENTGSA-Report.ps1 — export Global Secure Access traffic evidence via KQL against Log Analytics (read-only).
.DESCRIPTION
    PURPOSE
        The audit/go-live evidence tool. Runs KQL against the Log Analytics workspace that receives the
        GSA traffic logs (diagnostic setting 'ENTGSA - Diag - TrafficLogs') and exports: top destinations,
        allowed vs blocked internet flows, and per-user Private Access connections. Use it to prove the
        pilot works and to keep an ongoing record of what GSA is carrying.
    HOW TO RUN
        Connect-AzAccount   # once per session
        powershell -ExecutionPolicy Bypass -File .\ENTGSA-Report.ps1 `
            -WorkspaceId <log-analytics-workspace-guid> -Hours 24 -CsvFolder C:\Temp\entgsa
        Requires the Az.OperationalInsights module and Log Analytics Reader on the workspace.
    EXPECTED RESULTS
        Console tables + optional CSVs for allowed/blocked traffic and private-access connections. PASS =
        rows appear for pilot users' flows once logging is on. NOTE: GSA log table/field names evolve with
        preview — adjust the KQL to your tenant's current schema if a column is missing.
.NOTES
    White-label — Entra ID Solutions. Read-only (KQL). No credentials stored; uses interactive Connect-AzAccount.
.EXAMPLE
    .\ENTGSA-Report.ps1 -WorkspaceId 00000000-0000-0000-0000-000000000000
#>
[CmdletBinding()]
param(
    [Parameter(Mandatory=$true)][string]$WorkspaceId,
    [int]$Hours = 24,
    [string]$CsvFolder
)

if (-not (Get-Module -ListAvailable -Name Az.OperationalInsights)) {
    Install-Module Az.OperationalInsights -Scope CurrentUser -Force -AllowClobber
}
Import-Module Az.OperationalInsights -ErrorAction Stop
if (-not (Get-AzContext)) { Write-Host "Run Connect-AzAccount first." -ForegroundColor Yellow; Connect-AzAccount | Out-Null }

function Invoke-Kql([string]$Title, [string]$Query, [string]$CsvName) {
    Write-Host "`n=== $Title ===" -ForegroundColor Cyan
    try {
        $res = Invoke-AzOperationalInsightsQuery -WorkspaceId $WorkspaceId -Query $Query -ErrorAction Stop
        $rows = $res.Results
        if ($rows) { $rows | Format-Table -AutoSize } else { Write-Host "  (no rows — generate pilot traffic / check the diagnostic setting)" -ForegroundColor Yellow }
        if ($CsvFolder -and $rows) {
            if (-not (Test-Path $CsvFolder)) { New-Item -ItemType Directory -Path $CsvFolder | Out-Null }
            $p = Join-Path $CsvFolder "$CsvName.csv"; $rows | Export-Csv -Path $p -NoTypeInformation
            Write-Host "  saved $p" -ForegroundColor Green
        }
    } catch { Write-Host "  Query failed: $($_.Exception.Message)" -ForegroundColor Yellow }
}

Write-Host "Querying Log Analytics workspace $WorkspaceId over the last $Hours h" -ForegroundColor White

Invoke-Kql "Top internet destinations (allowed vs blocked)" @"
NetworkAccessTraffic
| where TimeGenerated > ago(${Hours}h)
| summarize Flows = count() by Action, DestinationFqdn
| order by Flows desc
| take 50
"@ 'top-destinations'

Invoke-Kql "Blocked / denied flows by user" @"
NetworkAccessTraffic
| where TimeGenerated > ago(${Hours}h)
| where Action == 'block' or Action == 'blocked'
| summarize Blocked = count() by UserPrincipalName, DestinationFqdn
| order by Blocked desc
| take 50
"@ 'blocked-flows'

Invoke-Kql "Private Access connections by user + app segment" @"
NetworkAccessTraffic
| where TimeGenerated > ago(${Hours}h)
| where TrafficType == 'Private'
| summarize Connections = count() by UserPrincipalName, DestinationFqdn, Action
| order by Connections desc
| take 50
"@ 'private-access'

Write-Host "`nReport complete. Attach the CSVs as your go-live / audit evidence." -ForegroundColor Cyan
