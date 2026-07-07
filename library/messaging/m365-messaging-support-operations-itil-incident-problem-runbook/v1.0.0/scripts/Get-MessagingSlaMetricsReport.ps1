<#
.SYNOPSIS
  SLA / ticket-metric rollup report (read-only). From an exported ticket CSV, computes SLA attainment
  per priority, First-Call-Resolution, CSAT, and reopen rate.
.DESCRIPTION
  Reads a CSV export from any ITSM tool and rolls up the four managed messaging-support metrics. Column
  names vary by tool, so a -ColumnMap hashtable overrides the defaults. Reads only the CSV - it makes no
  Microsoft 365 connection and changes nothing. Deterministic: the same CSV yields the same numbers.
.EXAMPLE
  .\Get-MessagingSlaMetricsReport.ps1 -TicketCsv .\tickets.csv
  # Uses default column names; prints per-priority SLA attainment, FCR, CSAT, reopen rate.
.EXAMPLE
  .\Get-MessagingSlaMetricsReport.ps1 -TicketCsv .\tickets.csv -ColumnMap @{ Priority='urgency'; SlaMet='sla_flag' }
  # (PowerShell 5.1+/7+. No tenant access required.)
.NOTES
  Expected results: a metrics table (SLA attainment %, FCR %, CSAT avg, reopen %) overall and by
  priority. PASS = numbers match a manual spot-check of the same CSV (Testing T7).
#>

[CmdletBinding()]
param(
    [Parameter(Mandatory = $true)]
    [string]$TicketCsv,

    [hashtable]$ColumnMap = @{},

    # A ticket counts as SLA-met when the mapped SlaMet column equals one of these (case-insensitive).
    [string[]]$SlaMetTrueValues = @('true', 'yes', 'met', '1'),
    [string[]]$FcrTrueValues     = @('true', 'yes', '1'),
    [string[]]$ReopenTrueValues  = @('true', 'yes', '1')
)

$ErrorActionPreference = 'Stop'

if (-not (Test-Path -LiteralPath $TicketCsv)) { Write-Error "CSV not found: $TicketCsv"; return }

# Default column names -> override any via -ColumnMap.
$col = @{
    Priority = 'Priority'
    SlaMet   = 'SlaMet'
    Fcr      = 'FirstCallResolved'
    Csat     = 'Csat'
    Reopened = 'Reopened'
}
foreach ($k in $ColumnMap.Keys) { $col[$k] = $ColumnMap[$k] }

$rows = Import-Csv -LiteralPath $TicketCsv
if (-not $rows) { Write-Warning "CSV has no data rows."; return }

$headers = ($rows[0].psobject.Properties.Name)
foreach ($needed in $col.Values) {
    if ($headers -notcontains $needed) {
        Write-Warning "Column '$needed' not found in CSV. Available: $($headers -join ', '). Use -ColumnMap to map it."
    }
}

function Test-Flag([string]$value, [string[]]$trueSet) {
    if ($null -eq $value) { return $false }
    return ($trueSet -contains $value.Trim().ToLower())
}

function Get-Metrics($set) {
    $total = @($set).Count
    if ($total -eq 0) { return $null }
    $slaMet = @($set | Where-Object { Test-Flag $_.($col.SlaMet) $SlaMetTrueValues }).Count
    $fcr    = @($set | Where-Object { Test-Flag $_.($col.Fcr) $FcrTrueValues }).Count
    $reopen = @($set | Where-Object { Test-Flag $_.($col.Reopened) $ReopenTrueValues }).Count
    $csatVals = $set | ForEach-Object { $_.($col.Csat) } |
        Where-Object { $_ -match '^\s*-?\d+(\.\d+)?\s*$' } | ForEach-Object { [double]$_ }
    $csatAvg = if ($csatVals) { [math]::Round(($csatVals | Measure-Object -Average).Average, 2) } else { $null }

    [pscustomobject]@{
        Tickets       = $total
        SlaAttainPct  = [math]::Round(100.0 * $slaMet / $total, 1)
        FcrPct        = [math]::Round(100.0 * $fcr / $total, 1)
        CsatAvg       = $csatAvg
        ReopenPct     = [math]::Round(100.0 * $reopen / $total, 1)
    }
}

Write-Host "`n=== Messaging Support Metrics — overall ===" -ForegroundColor Cyan
$overall = Get-Metrics $rows
$overall | Format-Table -AutoSize

Write-Host "=== By priority ===" -ForegroundColor Cyan
$rows | Group-Object { $_.($col.Priority) } | Sort-Object Name | ForEach-Object {
    $m = Get-Metrics $_.Group
    [pscustomobject]@{
        Priority     = $_.Name
        Tickets      = $m.Tickets
        SlaAttainPct = $m.SlaAttainPct
        FcrPct       = $m.FcrPct
        CsatAvg      = $m.CsatAvg
        ReopenPct    = $m.ReopenPct
    }
} | Format-Table -AutoSize

Write-Host "Set SLA targets in your Priority Matrix and compare SlaAttainPct against them per priority." -ForegroundColor DarkGray
