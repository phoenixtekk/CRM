<#
.SYNOPSIS
    ENTGSA-TrafficLogs.ps1 — focused KQL for GSA blocked/denied flows and Private Access outcomes (read-only).
.DESCRIPTION
    PURPOSE
        A diagnostic companion to ENTGSA-Report.ps1 for the two things you troubleshoot most: (1) which
        flows the Secure Web Gateway is blocking (to catch over-filtering or confirm a block works), and
        (2) Private Access connection outcomes for a given user or destination (to diagnose reachability).
        Filter by -UserPrincipalName and/or -DestinationLike to zero in on a report.
    HOW TO RUN
        Connect-AzAccount   # once per session
        powershell -ExecutionPolicy Bypass -File .\ENTGSA-TrafficLogs.ps1 `
            -WorkspaceId <guid> -UserPrincipalName user@contoso.com -Hours 6 -CsvPath C:\Temp\entgsa-flows.csv
    EXPECTED RESULTS
        Per-flow rows (time, user, destination, action, traffic type). Use it to prove a category is
        blocked (testing gate G3) or to see why a private app is unreachable (segment/DNS mismatch).
.NOTES
    White-label — Entra ID Solutions. Read-only (KQL). No credentials stored; uses interactive Connect-AzAccount.
    GSA log table/field names evolve with preview — adjust the KQL to your tenant's current schema.
.EXAMPLE
    .\ENTGSA-TrafficLogs.ps1 -WorkspaceId 00000000-0000-0000-0000-000000000000 -BlockedOnly
#>
[CmdletBinding()]
param(
    [Parameter(Mandatory=$true)][string]$WorkspaceId,
    [string]$UserPrincipalName,
    [string]$DestinationLike,
    [int]$Hours = 6,
    [switch]$BlockedOnly,
    [switch]$PrivateOnly,
    [string]$CsvPath
)

if (-not (Get-Module -ListAvailable -Name Az.OperationalInsights)) {
    Install-Module Az.OperationalInsights -Scope CurrentUser -Force -AllowClobber
}
Import-Module Az.OperationalInsights -ErrorAction Stop
if (-not (Get-AzContext)) { Write-Host "Run Connect-AzAccount first." -ForegroundColor Yellow; Connect-AzAccount | Out-Null }

$where = @("TimeGenerated > ago(${Hours}h)")
if ($UserPrincipalName) { $where += "UserPrincipalName == '$UserPrincipalName'" }
if ($DestinationLike)   { $where += "DestinationFqdn has '$DestinationLike'" }
if ($BlockedOnly)       { $where += "(Action == 'block' or Action == 'blocked')" }
if ($PrivateOnly)       { $where += "TrafficType == 'Private'" }
$filter = ($where -join "`n| where ")

$query = @"
NetworkAccessTraffic
| where $filter
| project TimeGenerated, UserPrincipalName, DestinationFqdn, DestinationPort, TrafficType, Action, TransactionId
| order by TimeGenerated desc
| take 200
"@

Write-Host "`n=== GSA traffic flows (last $Hours h) ===" -ForegroundColor Cyan
Write-Host $query -ForegroundColor DarkGray
try {
    $res = Invoke-AzOperationalInsightsQuery -WorkspaceId $WorkspaceId -Query $query -ErrorAction Stop
    $rows = $res.Results
    if ($rows) { $rows | Format-Table -AutoSize } else { Write-Host "  (no matching flows)" -ForegroundColor Yellow }
    if ($CsvPath -and $rows) { $rows | Export-Csv -Path $CsvPath -NoTypeInformation; Write-Host "  saved $CsvPath" -ForegroundColor Green }
} catch { Write-Host "  Query failed: $($_.Exception.Message)" -ForegroundColor Yellow }
