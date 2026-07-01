<#
.SYNOPSIS
    RMMTUNE-Discovery — Parse an RMM alert export and baseline alert volume by type, device, and hour.

.DESCRIPTION
    Part of the "RMM Monitoring & Alert Tuning — Noise Reduction & Actionable Alerting" solution
    (Assess phase). Reads a vendor-agnostic alert/event export (NinjaOne, Datto RMM, ConnectWise
    Automate, etc.), normalizes the columns, and profiles the alert stream so the noisiest alert
    types and devices are identified. Produces the first part of the named object
    "Alert Inventory & Baseline – RMM Estate – Assess".

    Read-only: this script only reads the export and writes summary CSVs. It never touches the RMM
    or any endpoint.

.PARAMETER ExportPath
    Path to the exported alert/event log (CSV).

.PARAMETER OutputDir
    Directory for the discovery output CSVs. Defaults to the export's folder.

.PARAMETER TimestampColumn
    Name of the timestamp column in the export. Default: "Timestamp".

.PARAMETER DeviceColumn
    Name of the device/endpoint column. Default: "Device".

.PARAMETER TypeColumn
    Name of the alert type/source column. Default: "AlertType".

.PARAMETER SeverityColumn
    Name of the severity column (optional). Default: "Severity".

.EXAMPLE
    .\RMMTUNE-Discovery.ps1 -ExportPath .\alerts-30d.csv

.EXAMPLE
    .\RMMTUNE-Discovery.ps1 -ExportPath .\datto.csv -TypeColumn "Monitor" -DeviceColumn "Hostname"

.NOTES
    Managed — read-only.
#>

[CmdletBinding()]
param(
    [Parameter(Mandatory = $true)]
    [string]$ExportPath,

    [string]$OutputDir,

    [string]$TimestampColumn = "Timestamp",
    [string]$DeviceColumn    = "Device",
    [string]$TypeColumn      = "AlertType",
    [string]$SeverityColumn  = "Severity"
)

$ErrorActionPreference = "Stop"

if (-not (Test-Path -LiteralPath $ExportPath)) {
    throw "Export not found: $ExportPath"
}
if (-not $OutputDir) { $OutputDir = Split-Path -Parent (Resolve-Path -LiteralPath $ExportPath) }
if (-not (Test-Path -LiteralPath $OutputDir)) { New-Item -ItemType Directory -Path $OutputDir | Out-Null }

Write-Host "RMMTUNE-Discovery — parsing alert export (read-only)..." -ForegroundColor Cyan

$rows = Import-Csv -LiteralPath $ExportPath
if (-not $rows -or $rows.Count -eq 0) { throw "Export contained no rows." }

$cols = $rows[0].PSObject.Properties.Name
foreach ($needed in @($TimestampColumn, $DeviceColumn, $TypeColumn)) {
    if ($cols -notcontains $needed) {
        throw "Expected column '$needed' not found. Available columns: $($cols -join ', '). Re-run with the matching -*Column parameter."
    }
}
$hasSeverity = $cols -contains $SeverityColumn

# Normalize rows
$norm = foreach ($r in $rows) {
    $ts = $null
    [void][datetime]::TryParse($r.$TimestampColumn, [ref]$ts)
    [pscustomobject]@{
        Timestamp = $ts
        Device    = ($r.$DeviceColumn).ToString().Trim()
        AlertType = ($r.$TypeColumn).ToString().Trim()
        Severity  = if ($hasSeverity) { ($r.$SeverityColumn).ToString().Trim() } else { "" }
    }
}

$total = $norm.Count
$devices = ($norm | Select-Object -ExpandProperty Device | Sort-Object -Unique).Count
$span = $norm | Where-Object { $_.Timestamp } | Sort-Object Timestamp
$days = if ($span.Count -ge 2) {
    [math]::Max(1, [math]::Round((($span[-1].Timestamp) - ($span[0].Timestamp)).TotalDays, 2))
} else { 1 }

Write-Host ("  Total alerts : {0}" -f $total)
Write-Host ("  Distinct devices : {0}" -f $devices)
Write-Host ("  Window (days) : {0}" -f $days)

# By type
$byType = $norm | Group-Object AlertType |
    Sort-Object Count -Descending |
    Select-Object @{N="AlertType";E={$_.Name}},
                  @{N="Count";E={$_.Count}},
                  @{N="PctOfTotal";E={[math]::Round(($_.Count / $total) * 100, 2)}}

# By device
$byDevice = $norm | Group-Object Device |
    Sort-Object Count -Descending |
    Select-Object @{N="Device";E={$_.Name}}, @{N="Count";E={$_.Count}}

# By hour of day
$byHour = $norm | Where-Object { $_.Timestamp } | Group-Object { $_.Timestamp.Hour } |
    Sort-Object { [int]$_.Name } |
    Select-Object @{N="Hour";E={[int]$_.Name}}, @{N="Count";E={$_.Count}}

$byType   | Export-Csv -LiteralPath (Join-Path $OutputDir "RMMTUNE-discovery-by-type.csv")   -NoTypeInformation
$byDevice | Export-Csv -LiteralPath (Join-Path $OutputDir "RMMTUNE-discovery-by-device.csv") -NoTypeInformation
$byHour   | Export-Csv -LiteralPath (Join-Path $OutputDir "RMMTUNE-discovery-by-hour.csv")   -NoTypeInformation

Write-Host "`nTop noise sources (alert types):" -ForegroundColor Yellow
$byType | Select-Object -First 10 | Format-Table -AutoSize

Write-Host "Discovery written to: $OutputDir" -ForegroundColor Green
Write-Host "Feed these into RMMTUNE-Set-AlertBaseline.ps1 to finalize the baseline." -ForegroundColor Green
