<#
.SYNOPSIS
    RMMTUNE-Remediation — Flag noisy alert sources for tuning. Read-only / -WhatIf by default.

.DESCRIPTION
    Part of the "RMM Monitoring & Alert Tuning — Noise Reduction & Actionable Alerting" solution
    (Operate phase). Analyzes an alert export and flags alert sources (types and devices) whose
    volume exceeds noise thresholds, so they can be added to the next tuning pass. By default it
    only REPORTS the flagged sources (read-only / -WhatIf semantics). With -Apply it writes a
    "tuning candidate" worklist file for the technician to act on in the RMM; it never edits the RMM
    or any endpoint itself.

    Safety: read-only by default. -Apply only writes a local worklist CSV — there is no destructive
    or live-RMM action in this script.

.PARAMETER ExportPath
    Path to the alert/event export (CSV).

.PARAMETER TypeNoiseThreshold
    Flag an alert TYPE when its share of total alerts exceeds this percent. Default 5.

.PARAMETER DeviceNoiseThreshold
    Flag a DEVICE when its share of total alerts exceeds this percent. Default 5.

.PARAMETER WorklistPath
    Where -Apply writes the tuning-candidate worklist CSV. Default: .\RMMTUNE-tuning-candidates.csv.

.PARAMETER Apply
    Write the worklist file. Without it, the script only reports (read-only).

.PARAMETER TypeColumn
    Alert type column. Default: "AlertType".

.PARAMETER DeviceColumn
    Device column. Default: "Device".

.EXAMPLE
    .\RMMTUNE-Remediation.ps1 -ExportPath .\alerts.csv            # read-only report

.EXAMPLE
    .\RMMTUNE-Remediation.ps1 -ExportPath .\alerts.csv -Apply     # write worklist

.NOTES
    Managed — read-only.
#>

[CmdletBinding(SupportsShouldProcess = $true)]
param(
    [Parameter(Mandatory = $true)]
    [string]$ExportPath,

    [double]$TypeNoiseThreshold   = 5,
    [double]$DeviceNoiseThreshold = 5,

    [string]$WorklistPath,

    [switch]$Apply,

    [string]$TypeColumn   = "AlertType",
    [string]$DeviceColumn = "Device"
)

$ErrorActionPreference = "Stop"

if (-not (Test-Path -LiteralPath $ExportPath)) { throw "Export not found: $ExportPath" }
if (-not $WorklistPath) {
    $WorklistPath = Join-Path (Split-Path -Parent (Resolve-Path -LiteralPath $ExportPath)) "RMMTUNE-tuning-candidates.csv"
}

$rows = Import-Csv -LiteralPath $ExportPath
if (-not $rows -or $rows.Count -eq 0) { throw "Export contained no rows." }
$cols = $rows[0].PSObject.Properties.Name
foreach ($needed in @($TypeColumn, $DeviceColumn)) {
    if ($cols -notcontains $needed) {
        throw "Expected column '$needed' not found. Available: $($cols -join ', ')."
    }
}
$total = $rows.Count

$flaggedTypes = $rows | Group-Object $TypeColumn |
    ForEach-Object {
        $pct = [math]::Round(($_.Count / $total) * 100, 2)
        if ($pct -ge $TypeNoiseThreshold) {
            [pscustomobject]@{ SourceKind = "AlertType"; Source = $_.Name; Count = $_.Count; PctOfTotal = $pct }
        }
    } | Sort-Object PctOfTotal -Descending

$flaggedDevices = $rows | Group-Object $DeviceColumn |
    ForEach-Object {
        $pct = [math]::Round(($_.Count / $total) * 100, 2)
        if ($pct -ge $DeviceNoiseThreshold) {
            [pscustomobject]@{ SourceKind = "Device"; Source = $_.Name; Count = $_.Count; PctOfTotal = $pct }
        }
    } | Sort-Object PctOfTotal -Descending

$candidates = @($flaggedTypes) + @($flaggedDevices)

Write-Host "RMMTUNE-Remediation — noisy sources flagged (read-only analysis):" -ForegroundColor Cyan
if ($candidates.Count -eq 0) {
    Write-Host "  No sources exceed the noise thresholds. Nothing to flag." -ForegroundColor Green
    return
}
$candidates | Format-Table -AutoSize

if ($Apply) {
    if ($PSCmdlet.ShouldProcess($WorklistPath, "Write tuning-candidate worklist")) {
        $candidates | Export-Csv -LiteralPath $WorklistPath -NoTypeInformation
        Write-Host "Worklist written to: $WorklistPath" -ForegroundColor Green
        Write-Host "Feed these into the next Tune-thresholds pass (Implementation Phase C)." -ForegroundColor Green
    }
}
else {
    Write-Host "`nRead-only mode (default). Re-run with -Apply to write the worklist CSV." -ForegroundColor Yellow
}
