<#
.SYNOPSIS
    NETDX-Report.ps1 — roll validation results into a connectivity-coverage report.
.DESCRIPTION
    PURPOSE
        Reads a NETDX-Validation results file (CSV or JSON) and produces a connectivity-coverage
        summary: overall pass rate, a breakdown of failures by first-failing layer (DNS / Port / Url),
        and a per-target detail list. Read-only; summarizes existing results and writes an HTML/CSV
        report you can attach to a ticket as evidence.
    HOW TO RUN
        powershell -ExecutionPolicy Bypass -File .\NETDX-Report.ps1 -ResultsFile .\netdx-validation-20260701-120000.csv
        powershell -ExecutionPolicy Bypass -File .\NETDX-Report.ps1 -ResultsFile .\results.json -OutputPath C:\Temp\netdx
        (no special scopes)
    EXPECTED RESULTS
        A console summary (pass rate, first-failing-layer counts) plus an HTML report
        (netdx-report-TIMESTAMP.html) and a summary CSV.
        Pass = all targets reachable (100 percent). Any shortfall lists which targets failed and at
        which layer, so you can escalate the right layer to the right team.
.NOTES
    White-label — the repeatable way. Read-only for discovery/validation.
#>

[CmdletBinding()]
param(
    [Parameter(Mandatory = $true)]
    [string]$ResultsFile,

    [string]$OutputPath = (Join-Path -Path $env:TEMP -ChildPath 'netdx')
)

$ErrorActionPreference = 'Stop'

if (-not (Test-Path -Path $ResultsFile)) {
    throw "Results file not found: $ResultsFile"
}
if (-not (Test-Path -Path $OutputPath)) {
    New-Item -Path $OutputPath -ItemType Directory -Force | Out-Null
}

# --- load results (CSV or JSON) ---
$ext = [System.IO.Path]::GetExtension($ResultsFile).ToLowerInvariant()
if ($ext -eq '.json') {
    $rows = Get-Content -Path $ResultsFile -Raw | ConvertFrom-Json
}
else {
    $rows = Import-Csv -Path $ResultsFile
}
if (-not $rows) { throw "Results file '$ResultsFile' contained no rows." }

$rows = @($rows)
$total = $rows.Count

function Test-TargetPass {
    param($row)
    # A target passes when it has no first-failing layer recorded.
    return [string]::IsNullOrWhiteSpace([string]$row.FirstFail)
}

$passed = @($rows | Where-Object { Test-TargetPass $_ })
$failed = @($rows | Where-Object { -not (Test-TargetPass $_) })
$passRate = if ($total -gt 0) { [math]::Round(($passed.Count / $total) * 100, 1) } else { 0 }

# --- breakdown by first-failing layer ---
$byLayer = $failed | Group-Object FirstFail | Sort-Object Count -Descending |
    Select-Object @{ n = 'Layer'; e = { $_.Name } }, Count

# --- console summary ---
Write-Host ''
Write-Host '=== Connectivity Coverage Report ===' -ForegroundColor Cyan
Write-Host ("  Targets tested : {0}" -f $total)
Write-Host ("  Passed         : {0}" -f $passed.Count) -ForegroundColor Green
Write-Host ("  Failed         : {0}" -f $failed.Count) -ForegroundColor ($(if ($failed.Count -gt 0) { 'Yellow' } else { 'Green' }))
Write-Host ("  Pass rate      : {0}%" -f $passRate)
Write-Host ''
Write-Host 'First-failing-layer breakdown:'
if ($byLayer) { $byLayer | Format-Table -AutoSize | Out-String | Write-Host }
else { Write-Host '  (none — all targets reachable)' -ForegroundColor Green }

if ($failed.Count -gt 0) {
    Write-Host 'Failing targets:'
    $failed | Select-Object Name, Host, Port, FirstFail, Detail | Format-Table -AutoSize | Out-String | Write-Host
}

# --- HTML report ---
$stamp = (Get-Date).ToString('yyyyMMdd-HHmmss')
$htmlFile = Join-Path -Path $OutputPath -ChildPath ("netdx-report-{0}.html" -f $stamp)
$csvFile = Join-Path -Path $OutputPath -ChildPath ("netdx-report-summary-{0}.csv" -f $stamp)

$style = @'
<style>
body{font-family:Segoe UI,Arial,sans-serif;margin:24px;color:#222}
h1{font-size:20px}h2{font-size:15px;margin-top:24px}
table{border-collapse:collapse;margin-top:8px}
th,td{border:1px solid #ccc;padding:6px 10px;font-size:13px;text-align:left}
th{background:#f2f2f2}
.pass{color:#1a7f37;font-weight:bold}.fail{color:#b42318;font-weight:bold}
.kpi{font-size:16px;margin:4px 0}
</style>
'@

$rowsHtml = ($rows | ForEach-Object {
    $cls = if (Test-TargetPass $_) { 'pass' } else { 'fail' }
    $verdict = if (Test-TargetPass $_) { 'PASS' } else { 'FAIL' }
    "<tr><td>$($_.Name)</td><td>$($_.Host)</td><td>$($_.Port)</td><td>$($_.ResolvedIP)</td><td class='$cls'>$verdict</td><td>$($_.FirstFail)</td><td>$($_.Detail)</td></tr>"
}) -join "`n"

$layerHtml = ($byLayer | ForEach-Object { "<tr><td>$($_.Layer)</td><td>$($_.Count)</td></tr>" }) -join "`n"

$html = @"
<html><head>$style</head><body>
<h1>Connectivity Coverage Report</h1>
<p class='kpi'>Generated: $(Get-Date -Format 'yyyy-MM-dd HH:mm')</p>
<p class='kpi'>Targets tested: <b>$total</b> &middot; Passed: <b>$($passed.Count)</b> &middot; Failed: <b>$($failed.Count)</b> &middot; Pass rate: <b>$passRate%</b></p>
<h2>First-failing-layer breakdown</h2>
<table><tr><th>Layer</th><th>Count</th></tr>
$layerHtml
</table>
<h2>Per-target detail</h2>
<table><tr><th>Name</th><th>Host</th><th>Port</th><th>Resolved IP</th><th>Verdict</th><th>First fail</th><th>Detail</th></tr>
$rowsHtml
</table>
</body></html>
"@

Set-Content -Path $htmlFile -Value $html -Encoding UTF8

# --- summary CSV ---
[pscustomobject]@{
    TargetsTested = $total
    Passed        = $passed.Count
    Failed        = $failed.Count
    PassRatePct   = $passRate
    FailDNS       = @($failed | Where-Object { $_.FirstFail -eq 'DNS' }).Count
    FailPort      = @($failed | Where-Object { $_.FirstFail -eq 'Port' }).Count
    FailUrl       = @($failed | Where-Object { $_.FirstFail -eq 'Url' }).Count
} | Export-Csv -Path $csvFile -NoTypeInformation -Encoding UTF8

Write-Host ''
Write-Host "Report saved to:" -ForegroundColor Green
Write-Host "  $htmlFile"
Write-Host "  $csvFile"
