<#
.SYNOPSIS
    GPORAT-Validation.ps1 — rationalization coverage check (every GPO has a disposition).
.DESCRIPTION
    PURPOSE
        Reads the rationalization register seeded by GPORAT-Discovery.ps1 and confirms that EVERY
        GPO has a valid disposition (keep / retire / consolidate / replace). Reports the
        rationalization-coverage percentage and lists any unclassified GPOs, plus consistency checks
        (consolidate rows must name a surviving GPO; replace rows should name a re-implementation
        surface; keep/consolidate rows should have an intent and owner). Read-only.
    HOW TO RUN
        powershell -ExecutionPolicy Bypass -File .\GPORAT-Validation.ps1 -RegisterPath .\GPO-Export\GPORAT-Rationalization-Register.csv
    EXPECTED RESULTS
        A coverage % (classified / total), a table of any unclassified GPOs, and a warnings list for
        rows missing required detail. Coverage must reach 100% before the pilot-scope gate.
.NOTES
    Workplace Marketplace — Migrations. Read-only.
#>
[CmdletBinding()]
param(
    [string] $RegisterPath = ".\GPO-Export\GPORAT-Rationalization-Register.csv"
)

Write-Host "`n=== Rationalization coverage validation ===" -ForegroundColor Cyan
if (-not (Test-Path $RegisterPath)) {
    Write-Host "Register not found: $RegisterPath. Run GPORAT-Discovery.ps1 first." -ForegroundColor Yellow
    return
}

$rows  = Import-Csv -Path $RegisterPath
$valid = 'keep','retire','consolidate','replace'
$total = @($rows).Count
if ($total -eq 0) { Write-Host "Register is empty." -ForegroundColor Yellow; return }

$classified   = @($rows | Where-Object { $valid -contains ($_.Disposition).ToString().Trim().ToLower() })
$unclassified = @($rows | Where-Object { $valid -notcontains ($_.Disposition).ToString().Trim().ToLower() })
$coverage     = [math]::Round((@($classified).Count / $total) * 100, 0)

Write-Host ("GPOs total       : {0}" -f $total)
Write-Host ("Classified       : {0}" -f @($classified).Count)
Write-Host ("Coverage         : {0}%" -f $coverage) -ForegroundColor $(if ($coverage -eq 100) { 'Green' } else { 'Yellow' })

if (@($unclassified).Count) {
    Write-Host "`nUnclassified GPOs (assign a disposition):" -ForegroundColor Yellow
    $unclassified | Select-Object DisplayName, GpoStatus, Links, ModifiedTime | Format-Table -AutoSize
}

# Disposition breakdown
Write-Host "`nDisposition breakdown:" -ForegroundColor Cyan
$classified | Group-Object { ($_.Disposition).ToString().Trim().ToLower() } | Sort-Object Name |
    ForEach-Object { Write-Host ("  {0,-12} {1}" -f $_.Name, $_.Count) }

# Consistency warnings
$warn = New-Object System.Collections.Generic.List[string]
foreach ($r in $classified) {
    $d = ($r.Disposition).ToString().Trim().ToLower()
    if ($d -eq 'consolidate' -and -not ($r.ConsolidateInto).ToString().Trim()) { $warn.Add("consolidate without ConsolidateInto: $($r.DisplayName)") }
    if ($d -eq 'replace'     -and -not ($r.ReplaceSurface).ToString().Trim())  { $warn.Add("replace without ReplaceSurface: $($r.DisplayName)") }
    if (($d -eq 'keep' -or $d -eq 'consolidate')) {
        if (-not ($r.Intent).ToString().Trim()) { $warn.Add("keep/consolidate without Intent: $($r.DisplayName)") }
        if (-not ($r.Owner).ToString().Trim())  { $warn.Add("keep/consolidate without Owner: $($r.DisplayName)") }
    }
}
if ($warn.Count) {
    Write-Host "`nWarnings (fill before the gate):" -ForegroundColor Yellow
    $warn | ForEach-Object { Write-Host ("  - {0}" -f $_) }
} else {
    Write-Host "`nNo detail warnings." -ForegroundColor Green
}

if ($coverage -eq 100 -and $warn.Count -eq 0) {
    Write-Host "`nPASS: full rationalization coverage with complete detail." -ForegroundColor Green
} else {
    Write-Host "`nNOT YET: complete classification and detail before the pilot-scope gate." -ForegroundColor Yellow
}
