<#
.SYNOPSIS
    INCIDENTG-Report.ps1 — Incident timeline / metrics report (MTTA / MTTR) to CSV for a GCC High program.
.DESCRIPTION
    PURPOSE
        Reads an exported set of incident records (from the PSA / Incident Record Template) and computes
        the program metrics that prove the runbook is working on the GCC High estate: per-incident MTTA
        (Detected to Acknowledged) and MTTR (Detected to Resolved), plus per-severity counts and average
        MTTA/MTTR. Output is a metrics CSV plus a console dashboard. This script is fully offline — it only
        reads the input file and needs no tenant access or US Gov endpoint, so it never leaves the boundary.
    HOW TO RUN
        powershell -ExecutionPolicy Bypass -File .\INCIDENTG-Report.ps1 -InputCsv ".\Incidents - Export - Lifecycle.csv"
        The input CSV needs at least these columns (ISO-8601 UTC timestamps; ResolvedUtc may be blank):
        IncidentId, Severity, DetectedUtc, AcknowledgedUtc, ResolvedUtc
        (No Graph scopes and no -Environment flag are required — this tool does not connect to any cloud.)
    EXPECTED RESULTS
        A CSV 'Incident Metrics - Program - Review.csv' with per-incident MTTA/MTTR (minutes) and a console
        summary of counts and average MTTA/MTTR by severity. Pass = the metrics CSV is written and the
        per-severity summary prints.
.NOTES
    White-label — the repeatable way. Read-only against Microsoft Graph US Gov endpoints.
#>

[CmdletBinding()]
param(
    [Parameter(Mandatory)][string]$InputCsv,
    [string]$OutputCsv = ".\Incident Metrics - Program - Review.csv"
)

$ErrorActionPreference = 'Stop'
if (-not (Test-Path $InputCsv)) { throw "Input CSV not found: $InputCsv" }

$rows = Import-Csv -Path $InputCsv
$out  = New-Object System.Collections.Generic.List[object]

function To-DateOrNull { param($s) if ([string]::IsNullOrWhiteSpace($s)) { return $null } try { [datetime]::Parse($s, $null, [System.Globalization.DateTimeStyles]::AssumeUniversal) } catch { $null } }
function MinutesBetween { param($a, $b) if ($a -and $b) { [math]::Round((New-TimeSpan -Start $a -End $b).TotalMinutes, 1) } else { $null } }

foreach ($r in $rows) {
    $det = To-DateOrNull $r.DetectedUtc
    $ack = To-DateOrNull $r.AcknowledgedUtc
    $res = To-DateOrNull $r.ResolvedUtc
    $out.Add([pscustomobject]@{
        IncidentId  = $r.IncidentId
        Severity    = $r.Severity
        MTTA_Min    = MinutesBetween $det $ack
        MTTR_Min    = MinutesBetween $det $res
        Status      = if ($res) { 'Resolved' } else { 'Open' }
        DetectedUtc = $r.DetectedUtc
    })
}

$out | Export-Csv -Path $OutputCsv -NoTypeInformation -Encoding UTF8
Write-Host ("Exported {0} incident metric rows to {1}" -f $out.Count, $OutputCsv) -ForegroundColor Green

Write-Host "`n=== Metrics by severity ===" -ForegroundColor Cyan
$out | Group-Object Severity | Sort-Object Name | ForEach-Object {
    $g = $_.Group
    $avgMtta = ($g | Where-Object { $_.MTTA_Min -ne $null } | Measure-Object MTTA_Min -Average).Average
    $avgMttr = ($g | Where-Object { $_.MTTR_Min -ne $null } | Measure-Object MTTR_Min -Average).Average
    Write-Host ("  {0,-6} Count={1,-4} AvgMTTA={2,-8} AvgMTTR={3,-8} Open={4}" -f `
        $_.Name, $g.Count,
        $(if($avgMtta){[math]::Round($avgMtta,1)}else{'n/a'}),
        $(if($avgMttr){[math]::Round($avgMttr,1)}else{'n/a'}),
        ($g | Where-Object Status -eq 'Open').Count)
}

$overallMttr = ($out | Where-Object { $_.MTTR_Min -ne $null } | Measure-Object MTTR_Min -Average).Average
Write-Host ("`nOverall avg MTTR (min): {0}" -f $(if($overallMttr){[math]::Round($overallMttr,1)}else{'n/a'})) -ForegroundColor Green
