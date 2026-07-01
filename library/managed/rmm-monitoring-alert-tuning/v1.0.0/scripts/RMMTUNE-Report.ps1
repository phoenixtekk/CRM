<#
.SYNOPSIS
    RMMTUNE-Report — Produce a noise / actionability / MTTA / MTTR report to CSV.

.DESCRIPTION
    Part of the "RMM Monitoring & Alert Tuning — Noise Reduction & Actionable Alerting" solution
    (Validate / Operate phases). Computes the current-window metrics — alerts/endpoint/day,
    % actionable, MTTA, MTTR — from an alert export and writes a flat CSV report. This drives the
    named object "Tuning Baseline Report – Noise & Actionability – Validate" when paired with the
    Assess baseline.

    Read-only: reads the export and writes a CSV report. It does not touch the RMM or endpoints.

.PARAMETER ExportPath
    Path to the alert/event export (CSV) for the reporting window.

.PARAMETER EndpointCount
    In-scope endpoint count for the reporting window.

.PARAMETER OutputPath
    CSV report path. Default: .\RMMTUNE-report.csv in the export folder.

.PARAMETER Label
    A label for the row (e.g. "post-tune", "2026-06 monthly"). Default: "current".

.PARAMETER TimestampColumn
    Timestamp column. Default: "Timestamp".

.PARAMETER AcknowledgedColumn
    Acknowledge-time column. Default: "Acknowledged".

.PARAMETER ResolvedColumn
    Resolve-time column. Default: "Resolved".

.PARAMETER ActionableColumn
    Actionable flag column. Default: "Actionable".

.EXAMPLE
    .\RMMTUNE-Report.ps1 -ExportPath .\alerts-post.csv -EndpointCount 420 -Label "post-tune"

.NOTES
    Managed — read-only.
#>

[CmdletBinding()]
param(
    [Parameter(Mandatory = $true)]
    [string]$ExportPath,

    [Parameter(Mandatory = $true)]
    [int]$EndpointCount,

    [string]$OutputPath,
    [string]$Label = "current",

    [string]$TimestampColumn    = "Timestamp",
    [string]$AcknowledgedColumn = "Acknowledged",
    [string]$ResolvedColumn     = "Resolved",
    [string]$ActionableColumn   = "Actionable"
)

$ErrorActionPreference = "Stop"

if (-not (Test-Path -LiteralPath $ExportPath)) { throw "Export not found: $ExportPath" }
if ($EndpointCount -le 0) { throw "EndpointCount must be greater than zero." }
if (-not $OutputPath) {
    $OutputPath = Join-Path (Split-Path -Parent (Resolve-Path -LiteralPath $ExportPath)) "RMMTUNE-report.csv"
}

$rows = Import-Csv -LiteralPath $ExportPath
if (-not $rows -or $rows.Count -eq 0) { throw "Export contained no rows." }
$cols = $rows[0].PSObject.Properties.Name
$total = $rows.Count

function Get-MeanMinutes {
    param($rows, $startCol, $endCol, $cols)
    if (($cols -notcontains $startCol) -or ($cols -notcontains $endCol)) { return $null }
    $spans = foreach ($r in $rows) {
        $s = $null; $e = $null
        if ([datetime]::TryParse($r.$startCol, [ref]$s) -and [datetime]::TryParse($r.$endCol, [ref]$e) -and $e -ge $s) {
            ($e - $s).TotalMinutes
        }
    }
    if ($spans) { [math]::Round(($spans | Measure-Object -Average).Average, 2) } else { $null }
}

$tss = (foreach ($r in $rows) { $t = $null; if ([datetime]::TryParse($r.$TimestampColumn, [ref]$t)) { $t } }) | Sort-Object
$days = if ($tss.Count -ge 2) { [math]::Max(1, [math]::Round((($tss[-1]) - ($tss[0])).TotalDays, 2)) } else { 1 }

$alertsPerEndpointPerDay = [math]::Round($total / $EndpointCount / $days, 3)

$pctActionable = $null
if ($cols -contains $ActionableColumn) {
    $act = ($rows | Where-Object { $_.$ActionableColumn -match '^(1|true|yes|y)$' }).Count
    $pctActionable = [math]::Round(($act / $total) * 100, 2)
}

$mtta = Get-MeanMinutes -rows $rows -startCol $TimestampColumn -endCol $AcknowledgedColumn -cols $cols
$mttr = Get-MeanMinutes -rows $rows -startCol $TimestampColumn -endCol $ResolvedColumn   -cols $cols

$report = [pscustomobject]@{
    Label                   = $Label
    GeneratedUtc            = (Get-Date).ToUniversalTime().ToString("o")
    WindowDays              = $days
    TotalAlerts             = $total
    EndpointCount           = $EndpointCount
    AlertsPerEndpointPerDay = $alertsPerEndpointPerDay
    PctActionable           = $pctActionable
    MTTA_Minutes            = $mtta
    MTTR_Minutes            = $mttr
}

Write-Host "RMMTUNE-Report — metrics for label '$Label' (read-only):" -ForegroundColor Cyan
$report | Format-List

# Append if the report exists so before/after rows accumulate
if (Test-Path -LiteralPath $OutputPath) {
    $report | Export-Csv -LiteralPath $OutputPath -NoTypeInformation -Append
} else {
    $report | Export-Csv -LiteralPath $OutputPath -NoTypeInformation
}
Write-Host "Report written to: $OutputPath" -ForegroundColor Green
