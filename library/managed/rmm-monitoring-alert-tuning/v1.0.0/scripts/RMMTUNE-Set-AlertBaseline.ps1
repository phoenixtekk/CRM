<#
.SYNOPSIS
    RMMTUNE-Set-AlertBaseline — Compute and store the alerts/endpoint/day baseline and supporting metrics.

.DESCRIPTION
    Part of the "RMM Monitoring & Alert Tuning — Noise Reduction & Actionable Alerting" solution
    (Assess phase). Computes the canonical baseline metrics from a normalized alert export —
    alerts/endpoint/day, % actionable, MTTA, and MTTR — and persists them as the named object
    "Alert Inventory & Baseline – RMM Estate – Assess" (a JSON baseline file). Later phases measure
    against this baseline; nothing should be tuned before it is committed and signed off.

    Read-only with respect to the RMM and endpoints. It only reads the export and writes a baseline
    file. Use -WhatIf to preview the computed baseline without writing it.

.PARAMETER ExportPath
    Path to the alert/event export (CSV).

.PARAMETER EndpointCount
    The agreed in-scope endpoint count (from the CMDB / RMM inventory). Required for alerts/endpoint/day.

.PARAMETER BaselinePath
    Where to write the baseline JSON. Default: .\RMMTUNE-baseline.json in the export folder.

.PARAMETER TimestampColumn
    Timestamp column name. Default: "Timestamp".

.PARAMETER AcknowledgedColumn
    Acknowledge-time column (optional, for MTTA). Default: "Acknowledged".

.PARAMETER ResolvedColumn
    Resolve-time column (optional, for MTTR). Default: "Resolved".

.PARAMETER ActionableColumn
    Column indicating whether an alert was actionable (optional, for % actionable). Default: "Actionable".

.EXAMPLE
    .\RMMTUNE-Set-AlertBaseline.ps1 -ExportPath .\alerts-30d.csv -EndpointCount 420 -WhatIf

.EXAMPLE
    .\RMMTUNE-Set-AlertBaseline.ps1 -ExportPath .\alerts-30d.csv -EndpointCount 420

.NOTES
    Managed — read-only.
#>

[CmdletBinding(SupportsShouldProcess = $true)]
param(
    [Parameter(Mandatory = $true)]
    [string]$ExportPath,

    [Parameter(Mandatory = $true)]
    [int]$EndpointCount,

    [string]$BaselinePath,

    [string]$TimestampColumn    = "Timestamp",
    [string]$AcknowledgedColumn = "Acknowledged",
    [string]$ResolvedColumn     = "Resolved",
    [string]$ActionableColumn   = "Actionable"
)

$ErrorActionPreference = "Stop"

if (-not (Test-Path -LiteralPath $ExportPath)) { throw "Export not found: $ExportPath" }
if ($EndpointCount -le 0) { throw "EndpointCount must be greater than zero." }
if (-not $BaselinePath) {
    $BaselinePath = Join-Path (Split-Path -Parent (Resolve-Path -LiteralPath $ExportPath)) "RMMTUNE-baseline.json"
}

$rows = Import-Csv -LiteralPath $ExportPath
if (-not $rows -or $rows.Count -eq 0) { throw "Export contained no rows." }
$cols = $rows[0].PSObject.Properties.Name

function Get-MeanMinutes {
    param($rows, $startCol, $endCol)
    if (($cols -notcontains $startCol) -or ($cols -notcontains $endCol)) { return $null }
    $spans = foreach ($r in $rows) {
        $s = $null; $e = $null
        if ([datetime]::TryParse($r.$startCol, [ref]$s) -and [datetime]::TryParse($r.$endCol, [ref]$e) -and $e -ge $s) {
            ($e - $s).TotalMinutes
        }
    }
    if ($spans) { [math]::Round(($spans | Measure-Object -Average).Average, 2) } else { $null }
}

$total = $rows.Count

# Window in days
$tss = foreach ($r in $rows) { $t = $null; if ([datetime]::TryParse($r.$TimestampColumn, [ref]$t)) { $t } }
$tss = $tss | Sort-Object
$days = if ($tss.Count -ge 2) { [math]::Max(1, [math]::Round((($tss[-1]) - ($tss[0])).TotalDays, 2)) } else { 1 }

$alertsPerEndpointPerDay = [math]::Round($total / $EndpointCount / $days, 3)

# % actionable
$pctActionable = $null
if ($cols -contains $ActionableColumn) {
    $act = ($rows | Where-Object { $_.$ActionableColumn -match '^(1|true|yes|y)$' }).Count
    $pctActionable = [math]::Round(($act / $total) * 100, 2)
}

$mtta = Get-MeanMinutes -rows $rows -startCol $TimestampColumn -endCol $AcknowledgedColumn
$mttr = Get-MeanMinutes -rows $rows -startCol $TimestampColumn -endCol $ResolvedColumn

$baseline = [ordered]@{
    Object                  = "Alert Inventory & Baseline - RMM Estate - Assess"
    GeneratedUtc            = (Get-Date).ToUniversalTime().ToString("o")
    ExportFile              = (Resolve-Path -LiteralPath $ExportPath).Path
    WindowDays              = $days
    TotalAlerts             = $total
    EndpointCount           = $EndpointCount
    AlertsPerEndpointPerDay = $alertsPerEndpointPerDay
    PctActionable           = $pctActionable
    MTTA_Minutes            = $mtta
    MTTR_Minutes            = $mttr
}

Write-Host "RMMTUNE-Set-AlertBaseline — computed baseline:" -ForegroundColor Cyan
$baseline.GetEnumerator() | ForEach-Object { Write-Host ("  {0,-24}: {1}" -f $_.Key, $_.Value) }

if ($PSCmdlet.ShouldProcess($BaselinePath, "Write baseline JSON")) {
    $baseline | ConvertTo-Json -Depth 4 | Set-Content -LiteralPath $BaselinePath -Encoding UTF8
    Write-Host "`nBaseline written to: $BaselinePath" -ForegroundColor Green
    Write-Host "Sign this off before any threshold/routing change (Implementation Step 4)." -ForegroundColor Green
}
else {
    Write-Host "`n-WhatIf: baseline NOT written. Re-run without -WhatIf to commit." -ForegroundColor Yellow
}
