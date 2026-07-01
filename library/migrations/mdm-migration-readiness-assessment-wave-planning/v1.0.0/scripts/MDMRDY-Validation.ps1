<#
.SYNOPSIS
    MDMRDY-Validation.ps1 — check estate inventory data completeness before scoring.
.DESCRIPTION
    PURPOSE
        Validates the "Estate Inventory - MDM Migration - Assess" for completeness: missing/blank
        required fields, unknown platform values, and stale check-ins. Gates the assessment so you do
        not score readiness/risk on bad data. Read-only — reports issues, changes nothing.
    HOW TO RUN
        powershell -ExecutionPolicy Bypass -File .\MDMRDY-Validation.ps1 -InventoryCsv C:\MDMRDY\estate-inventory.csv -OutputFolder C:\MDMRDY
        Optional: -StaleDays 90 (default) sets the stale check-in threshold.
    EXPECTED RESULTS
        Prints a completeness summary and writes validation-report.csv listing every flagged row and
        reason. A clean run (no blanks, known platforms) means the inventory is ready to score.
.NOTES
    Migrations — vendor-neutral pre-migration assessment. Read-only.
#>
[CmdletBinding()]
param(
    [Parameter(Mandatory)][string]$InventoryCsv,
    [string]$OutputFolder = (Join-Path $PWD 'MDMRDY'),
    [int]$StaleDays = 90
)

$ErrorActionPreference = 'Stop'
if (-not (Test-Path $InventoryCsv)) { throw "Inventory CSV not found: $InventoryCsv" }
if (-not (Test-Path $OutputFolder)) { New-Item -ItemType Directory -Path $OutputFolder -Force | Out-Null }

$required      = 'DeviceName','Platform','OSVersion','Owner','EnrollmentType'
$knownPlatform = 'Windows','iOS','iPadOS','macOS','Android'
$rows = Import-Csv -Path $InventoryCsv
$issues = New-Object System.Collections.Generic.List[object]
$staleCutoff = (Get-Date).AddDays(-$StaleDays)

foreach ($r in $rows) {
    $name = if ($r.DeviceName) { $r.DeviceName } else { '(unnamed)' }
    foreach ($f in $required) {
        if ([string]::IsNullOrWhiteSpace($r.$f)) {
            $issues.Add([pscustomobject]@{ DeviceName=$name; Field=$f; Issue='Missing required value' })
        }
    }
    if ($r.Platform -and ($knownPlatform -notcontains $r.Platform)) {
        $issues.Add([pscustomobject]@{ DeviceName=$name; Field='Platform'; Issue=("Unknown platform '{0}'" -f $r.Platform) })
    }
    if ($r.LastCheckIn) {
        $dt = $null
        if ([datetime]::TryParse($r.LastCheckIn,[ref]$dt) -and $dt -lt $staleCutoff) {
            $issues.Add([pscustomobject]@{ DeviceName=$name; Field='LastCheckIn'; Issue=("Stale (> $StaleDays days): {0}" -f $r.LastCheckIn) })
        }
    }
}

$reportFile = Join-Path $OutputFolder 'validation-report.csv'
$issues | Export-Csv -Path $reportFile -NoTypeInformation -Encoding UTF8

$total = $rows.Count
$flagged = ($issues | Select-Object -ExpandProperty DeviceName -Unique).Count
$completeness = if ($total -gt 0) { [math]::Round((($total - $flagged) / $total) * 100, 1) } else { 0 }

Write-Host "=== Inventory completeness ===" -ForegroundColor Cyan
Write-Host ("Devices             : {0}" -f $total)
Write-Host ("Devices with issues : {0}" -f $flagged)
Write-Host ("Issues total        : {0}" -f $issues.Count)
Write-Host ("Completeness        : {0}%" -f $completeness) -ForegroundColor $(if ($completeness -ge 95) { 'Green' } else { 'Yellow' })
Write-Host ("Report              : {0}" -f $reportFile) -ForegroundColor Green
if ($issues.Count -gt 0) {
    Write-Host "Run MDMRDY-Remediation.ps1 (-WhatIf first) to fill gaps before scoring." -ForegroundColor Yellow
}
