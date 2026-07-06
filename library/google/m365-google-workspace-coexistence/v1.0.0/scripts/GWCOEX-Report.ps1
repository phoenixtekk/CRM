<#
.SYNOPSIS
    GWCOEX-Report.ps1 — Coexistence coverage report for M365 ↔ Google Workspace.
.DESCRIPTION
    PURPOSE
        Roll up per-user interop validation into a coexistence coverage report. Reads
        a validation CSV produced by GWCOEX-Validation.ps1 (or re-derives per-pillar
        status) and produces a single coverage view: how many users are green on mail
        routing, free/busy, and directory, plus an overall coverage percentage and a
        per-user detail table. Read-only reporting — makes no changes.
    HOW TO RUN
        powershell -ExecutionPolicy Bypass -File .\GWCOEX-Report.ps1 -ValidationCsv .\validation\validation-<stamp>.csv
        (No Graph scopes required when reading an existing validation CSV.)
    EXPECTED RESULTS
        A console coverage summary and an HTML + CSV report in -OutputFolder. PASS = the
        overall coverage percentage meets or exceeds -Threshold (default 100). No changes.
.NOTES
    White-label — the repeatable way. Read-only against Microsoft Graph.
#>

[CmdletBinding()]
param(
    [Parameter(Mandatory = $true)]
    [string] $ValidationCsv,
    [int]    $Threshold = 100,
    [string] $OutputFolder = ".\reports"
)

$ErrorActionPreference = 'Stop'

if (-not (Test-Path $ValidationCsv)) { throw "Validation CSV not found: $ValidationCsv" }
if (-not (Test-Path $OutputFolder))  { New-Item -ItemType Directory -Path $OutputFolder | Out-Null }
$stamp = Get-Date -Format 'yyyyMMdd-HHmmss'

$rows = Import-Csv $ValidationCsv
$total = ($rows | Measure-Object).Count
if ($total -eq 0) { throw "Validation CSV has no rows." }

function Pct { param($n) [math]::Round(($n / $total) * 100, 1) }

$mailOk  = ($rows | Where-Object MailRoute -eq 'PASS' | Measure-Object).Count
$fbOk    = ($rows | Where-Object FreeBusy  -eq 'PASS' | Measure-Object).Count
$dirOk   = ($rows | Where-Object Directory -eq 'PASS' | Measure-Object).Count
$allOk   = ($rows | Where-Object Overall   -eq 'PASS' | Measure-Object).Count
$coverage = Pct $allOk

# ---- Console ----------------------------------------------------------------
Write-Host ""
Write-Host "==== COEXISTENCE COVERAGE REPORT ====" -ForegroundColor Green
Write-Host ("Users evaluated          : {0}" -f $total)
Write-Host ("Mail routing OK          : {0} ({1}%)" -f $mailOk, (Pct $mailOk))
Write-Host ("Free/busy OK             : {0} ({1}%)" -f $fbOk,   (Pct $fbOk))
Write-Host ("Directory OK             : {0} ({1}%)" -f $dirOk,  (Pct $dirOk))
Write-Host ("OVERALL COVERAGE         : {0}% ({1}/{2} users all-green)" -f $coverage, $allOk, $total) -ForegroundColor Cyan
$verdict = if ($coverage -ge $Threshold) { 'PASS' } else { 'FAIL' }
$color = if ($verdict -eq 'PASS') { 'Green' } else { 'Yellow' }
Write-Host ("VERDICT (threshold {0}%) : {1}" -f $Threshold, $verdict) -ForegroundColor $color

# ---- Failing users ----------------------------------------------------------
$failing = $rows | Where-Object Overall -ne 'PASS'
if ($failing) {
    Write-Host ""
    Write-Host "Users missing a pillar:" -ForegroundColor Yellow
    $failing | Select-Object UserPrincipalName, Platform, MailRoute, FreeBusy, Directory | Format-Table -AutoSize
}

# ---- CSV + HTML -------------------------------------------------------------
$csvOut = Join-Path $OutputFolder "coverage-$stamp.csv"
$rows | Export-Csv $csvOut -NoTypeInformation -Encoding UTF8

$style = "<style>body{font-family:Segoe UI,Arial,sans-serif} table{border-collapse:collapse} " +
         "th,td{border:1px solid #ccc;padding:6px 10px;text-align:left} " +
         ".p{color:#137333;font-weight:600}.f{color:#a50e0e;font-weight:600}</style>"
$head = "<h2>Coexistence Coverage Report</h2><p>Generated $stamp</p>" +
        "<p>Overall coverage: <b>$coverage%</b> ($allOk/$total users all-green) — verdict <b>$verdict</b> (threshold $Threshold%).</p>"
$table = ($rows | ConvertTo-Html -Property UserPrincipalName,Platform,MailRoute,FreeBusy,Directory,Overall -Fragment) `
            -replace '<td>PASS</td>','<td class="p">PASS</td>' -replace '<td>FAIL</td>','<td class="f">FAIL</td>'
$htmlOut = Join-Path $OutputFolder "coverage-$stamp.html"
"$style$head$table" | Set-Content -Path $htmlOut -Encoding UTF8

Write-Host ""
Write-Host "Report written:" -ForegroundColor Green
Write-Host "  $csvOut"
Write-Host "  $htmlOut"
