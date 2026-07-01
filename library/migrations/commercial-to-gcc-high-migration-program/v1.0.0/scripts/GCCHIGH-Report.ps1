<#
.SYNOPSIS
    GCCHIGH-Report.ps1 - Program / workstream status report for a Commercial-to-GCC High migration.

    PURPOSE:
        Produces a program dashboard from a status CSV: per-workstream % complete, wave progress, and
        GB moved vs. total. Use it to track the program across Exchange, SharePoint/OneDrive, Teams,
        Servers, PaaS, AVD, and Identity.

    HOW TO RUN:
        .\GCCHIGH-Report.ps1 -StatusCsv ".\Migration-Status - Program - Program.csv" `
                             -OutputCsv ".\Status-Report - Program - Program.csv"

        The input status CSV is expected to contain (at minimum) these columns:
            Wave, Workstream, ObjectName, Status, SizeGB
        where Status is one of: NotStarted | InProgress | Completed | Failed

    EXPECTED RESULTS:
        A console summary (per-workstream and per-wave roll-ups) and an exported roll-up CSV. The
        script only reads the status CSV and writes a report - it makes no changes to any tenant.

.NOTES
    Azure Solutions - read-only.
#>

[CmdletBinding()]
param(
    [Parameter(Mandatory)][string]$StatusCsv,
    [string]$OutputCsv = ".\Status-Report - Program - Program.csv"
)

$ErrorActionPreference = 'Stop'
if (-not (Test-Path $StatusCsv)) { throw "Status CSV not found: $StatusCsv" }
$rows = Import-Csv $StatusCsv
if (-not $rows) { throw "Status CSV is empty: $StatusCsv" }

function Pct { param($done,$total) if ($total -le 0) { 0 } else { [math]::Round(($done / $total) * 100, 1) } }

# --- Per-workstream roll-up ---
$report = New-Object System.Collections.Generic.List[object]
Write-Host "=== Per-workstream status ===" -ForegroundColor Cyan
foreach ($g in ($rows | Group-Object Workstream | Sort-Object Name)) {
    $total      = $g.Count
    $completed  = ($g.Group | Where-Object Status -eq 'Completed').Count
    $inprogress = ($g.Group | Where-Object Status -eq 'InProgress').Count
    $failed     = ($g.Group | Where-Object Status -eq 'Failed').Count
    $gbTotal    = [math]::Round((($g.Group | Measure-Object SizeGB -Sum).Sum), 2)
    $gbMoved    = [math]::Round((($g.Group | Where-Object Status -eq 'Completed' | Measure-Object SizeGB -Sum).Sum), 2)
    $obj = [pscustomobject]@{
        Workstream   = $g.Name
        Total        = $total
        Completed    = $completed
        InProgress   = $inprogress
        Failed       = $failed
        PercentDone  = (Pct $completed $total)
        GBMoved      = $gbMoved
        GBTotal      = $gbTotal
        GBPercent    = (Pct $gbMoved $gbTotal)
    }
    $report.Add($obj)
    Write-Host ("  {0,-22} {1,5}% complete  ({2}/{3} objects)  GB {4}/{5} ({6}%)  Failed={7}" -f `
        $obj.Workstream, $obj.PercentDone, $completed, $total, $gbMoved, $gbTotal, $obj.GBPercent, $failed) `
        -ForegroundColor $(if ($failed -gt 0) { 'Yellow' } else { 'Gray' })
}

# --- Per-wave roll-up ---
Write-Host "`n=== Per-wave status ===" -ForegroundColor Cyan
foreach ($w in ($rows | Group-Object Wave | Sort-Object Name)) {
    $completed = ($w.Group | Where-Object Status -eq 'Completed').Count
    Write-Host ("  {0,-14} {1,5}% complete ({2}/{3})" -f $w.Name, (Pct $completed $w.Count), $completed, $w.Count)
}

# --- Overall ---
$totObj  = $rows.Count
$totDone = ($rows | Where-Object Status -eq 'Completed').Count
$totFail = ($rows | Where-Object Status -eq 'Failed').Count
$gbAll   = [math]::Round((($rows | Measure-Object SizeGB -Sum).Sum), 2)
$gbDone  = [math]::Round((($rows | Where-Object Status -eq 'Completed' | Measure-Object SizeGB -Sum).Sum), 2)

Write-Host "`n=== Program total ===" -ForegroundColor Cyan
Write-Host ("  Objects: {0}/{1} ({2}%)  GB: {3}/{4} ({5}%)  Failed: {6}" -f `
    $totDone, $totObj, (Pct $totDone $totObj), $gbDone, $gbAll, (Pct $gbDone $gbAll), $totFail) `
    -ForegroundColor Green

$report | Export-Csv -Path $OutputCsv -NoTypeInformation -Encoding UTF8
Write-Host ("`nReport written to {0}" -f $OutputCsv) -ForegroundColor Green
