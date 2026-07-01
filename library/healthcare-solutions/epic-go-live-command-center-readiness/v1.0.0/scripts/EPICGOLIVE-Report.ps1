<#
.SYNOPSIS
    EPICGOLIVE-Report — readiness scorecard for an Epic go-live.

.DESCRIPTION
    Rolls per-device validation results into the "Readiness Scorecard - Clinical Fleet -
    Validation" and exports it to CSV. Produces per-device PASS/FAIL with reasons and roll-ups
    by device class / unit and overall percentage ready. Read-only: it consumes validation
    output (or re-runs validation read-only) and writes a CSV — it changes no device state.

    The export contains device and posture metadata only (no ePHI), satisfying the
    HIPAA/HITRUST data-handling requirement.

.PARAMETER InputCsv
    Path to a CSV produced by EPICGOLIVE-Validation.ps1. If supplied, the scorecard is built
    from it (no Graph calls needed).

.PARAMETER GroupId
    If no InputCsv is supplied, the readiness group to validate against (the report will invoke
    the same read-only checks inline). Requires -TargetEpicVersion.

.PARAMETER TargetEpicVersion
    Target Epic client version string (only needed when validating inline via -GroupId).

.PARAMETER ClassProperty
    Optional property name on the input rows that carries the device class / unit for roll-ups
    (e.g. a tag column). If absent, only the overall roll-up is produced.

.PARAMETER OutputPath
    Path to write the scorecard CSV. Default: .\readiness-scorecard.csv

.EXAMPLE
    .\EPICGOLIVE-Report.ps1 -InputCsv .\validation-results.csv -OutputPath .\scorecard.csv

.NOTES
    Healthcare Solutions — read-only.
#>

[CmdletBinding(DefaultParameterSetName = 'FromCsv')]
param(
    [Parameter(ParameterSetName = 'FromCsv', Mandatory)] [string] $InputCsv,
    [Parameter(ParameterSetName = 'Inline',  Mandatory)] [string] $GroupId,
    [Parameter(ParameterSetName = 'Inline',  Mandatory)] [string] $TargetEpicVersion,
    [string] $ClassProperty,
    [string] $OutputPath = ".\readiness-scorecard.csv"
)

Write-Host "EPICGOLIVE-Report — building readiness scorecard (read-only)..." -ForegroundColor Cyan

#-------------------------------------------------------------------------------
# Acquire per-device results
#-------------------------------------------------------------------------------
if ($PSCmdlet.ParameterSetName -eq 'FromCsv') {
    if (-not (Test-Path $InputCsv)) { throw "Input CSV not found: $InputCsv" }
    $rows = Import-Csv -Path $InputCsv
} else {
    $validation = Join-Path $PSScriptRoot 'EPICGOLIVE-Validation.ps1'
    if (-not (Test-Path $validation)) { throw "EPICGOLIVE-Validation.ps1 not found next to this script." }
    $rows = & $validation -GroupId $GroupId -TargetEpicVersion $TargetEpicVersion
}

if (-not $rows -or $rows.Count -eq 0) {
    Write-Warning "No device rows to report. Confirm the readiness group is populated and validation ran."
    return
}

#-------------------------------------------------------------------------------
# Overall roll-up
#-------------------------------------------------------------------------------
$total = $rows.Count
$pass  = ($rows | Where-Object { $_.Result -eq 'PASS' }).Count
$fail  = $total - $pass
$pct   = if ($total) { [math]::Round(($pass / $total) * 100, 1) } else { 0 }

Write-Host ("Overall — Devices: {0}  PASS: {1}  FAIL: {2}  Ready: {3}%" -f $total, $pass, $fail, $pct) -ForegroundColor Green

#-------------------------------------------------------------------------------
# Per-class / per-unit roll-up (optional)
#-------------------------------------------------------------------------------
$classRollup = @()
if ($ClassProperty -and ($rows[0].PSObject.Properties.Name -contains $ClassProperty)) {
    $classRollup = $rows | Group-Object -Property $ClassProperty | ForEach-Object {
        $g = $_.Group
        $p = ($g | Where-Object { $_.Result -eq 'PASS' }).Count
        [pscustomobject]@{
            Scope       = "Class:$($_.Name)"
            DeviceCount = $g.Count
            Pass        = $p
            Fail        = $g.Count - $p
            ReadyPct    = if ($g.Count) { [math]::Round(($p / $g.Count) * 100, 1) } else { 0 }
        }
    }
}

#-------------------------------------------------------------------------------
# Compose scorecard: summary row(s) + per-device detail
#-------------------------------------------------------------------------------
$summary = [pscustomobject]@{
    Scope = 'Overall'; DeviceCount = $total; Pass = $pass; Fail = $fail; ReadyPct = $pct
}

$scorecard = @()
$scorecard += $summary
$scorecard += $classRollup

# Per-device detail (metadata only — no ePHI).
$detail = $rows | Select-Object DeviceName, Result, FailedChecks, EpicVersionFound,
    Enrolled, Compliant, ImprivataOK, CheckedInRecently, Printing, Peripherals, LoginTime

$scorecard | Export-Csv -Path $OutputPath -NoTypeInformation -Encoding UTF8
$detailPath = [System.IO.Path]::ChangeExtension($OutputPath, $null) + 'detail.csv'
$detail | Export-Csv -Path $detailPath -NoTypeInformation -Encoding UTF8

Write-Host "Scorecard summary written to $OutputPath" -ForegroundColor Green
Write-Host "Per-device detail written to $detailPath" -ForegroundColor Green
Write-Host "Verify the export contains no ePHI before sharing (device/posture metadata only)." -ForegroundColor Yellow
