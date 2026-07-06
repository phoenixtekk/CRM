<#
.SYNOPSIS
    GWARB-Validation.ps1 — check submitted designs for conformance to the approved standards baseline.
.DESCRIPTION
    PURPOSE
        Compares each design's declared attributes against the ARB-approved standards baseline (the
        target-architecture standards the board ratified) and reports per-design conformance:
        conformant, conditional (has an approved exception), or non-conformant (drift). Each
        non-conformance is a gate finding the board must adjudicate before approval. Read-only.
        The baseline and each design's attributes are supplied as data — this script never invents a
        standard; it enforces the ones your board has approved.
    HOW TO RUN
        powershell -ExecutionPolicy Bypass -File .\GWARB-Validation.ps1 -DesignsCsv C:\Temp\designs.csv -BaselineCsv C:\Temp\baseline.csv
        Optional approved-exceptions register:
            ... -ExceptionsCsv C:\Temp\exceptions.csv
        BaselineCsv columns:  Standard,ExpectedValue
        DesignsCsv columns:   DesignId,Standard,ActualValue
        ExceptionsCsv columns: DesignId,Standard  (an ARB-approved deviation)
        No live-system scopes are required; runs entirely on the supplied registers.
    EXPECTED RESULTS
        A per-design, per-standard conformance table and a conformance rate. Pass = every design at or
        past its gate is conformant or has an approved exception; any Non-Conformant row is drift that
        blocks approval until adjudicated. No system is changed.
.NOTES
    White-label — the repeatable way. Read-only where it reads live systems.
#>
[CmdletBinding()]
param(
    [Parameter(Mandatory)][string]$DesignsCsv,
    [Parameter(Mandatory)][string]$BaselineCsv,
    [string]$ExceptionsCsv
)

foreach ($p in @($DesignsCsv, $BaselineCsv)) {
    if (-not (Test-Path $p)) { Write-Host "File not found: $p" -ForegroundColor Red; exit 2 }
}
$designs  = Import-Csv $DesignsCsv
$baseline = @{}
foreach ($b in (Import-Csv $BaselineCsv)) { $baseline[$b.Standard] = $b.ExpectedValue }

$exceptions = @{}
if ($ExceptionsCsv -and (Test-Path $ExceptionsCsv)) {
    foreach ($e in (Import-Csv $ExceptionsCsv)) { $exceptions["$($e.DesignId)|$($e.Standard)"] = $true }
}

Write-Host "`n=== Conformance to approved standards baseline ===" -ForegroundColor Cyan
$results = foreach ($d in $designs) {
    $expected = $baseline[$d.Standard]
    $status =
        if (-not $baseline.ContainsKey($d.Standard)) { 'No-Baseline' }
        elseif ($d.ActualValue -eq $expected)        { 'Conformant' }
        elseif ($exceptions.ContainsKey("$($d.DesignId)|$($d.Standard)")) { 'Conditional (approved exception)' }
        else { 'Non-Conformant' }
    [pscustomobject]@{
        DesignId = $d.DesignId
        Standard = $d.Standard
        Expected = $expected
        Actual   = $d.ActualValue
        Status   = $status
    }
}
$results | Sort-Object DesignId, Standard | Format-Table DesignId, Standard, Expected, Actual, Status -AutoSize

$total       = $results.Count
$conformant  = ($results | Where-Object { $_.Status -eq 'Conformant' }).Count
$conditional = ($results | Where-Object { $_.Status -like 'Conditional*' }).Count
$drift       = ($results | Where-Object { $_.Status -eq 'Non-Conformant' })
$noBaseline  = ($results | Where-Object { $_.Status -eq 'No-Baseline' })

$rate = if ($total) { [math]::Round((($conformant + $conditional) / $total) * 100, 1) } else { 0 }
Write-Host ("`nConformance rate (conformant + approved exceptions): {0}%  ({1}/{2})" -f $rate, ($conformant + $conditional), $total) -ForegroundColor Cyan
Write-Host ("Non-conformant (drift) findings: {0}" -f $drift.Count) -ForegroundColor $(if ($drift.Count) { 'Red' } else { 'Green' })

if ($drift.Count) {
    Write-Host "`n--- Drift findings the ARB must adjudicate before approval ---" -ForegroundColor Yellow
    $drift | Format-Table DesignId, Standard, Expected, Actual -AutoSize
}
if ($noBaseline.Count) {
    Write-Host "`nStandards with no baseline entry — add them to the approved baseline or remove from designs:" -ForegroundColor DarkYellow
    $noBaseline | Select-Object Standard -Unique | Format-Table -AutoSize
}
Write-Host "A design may not pass its gate while a Non-Conformant finding is open without an approved exception." -ForegroundColor DarkYellow
