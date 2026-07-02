<#
.SYNOPSIS
    EGRESS-Report.ps1 — produce an allow-list coverage / gap report from the required set and validation results.
.DESCRIPTION
    PURPOSE
        Combines the required-set file (EGRESS-Discovery.ps1) with the validation results
        (EGRESS-Validation.ps1) into a single coverage/gap report showing which required endpoints
        are reachable and which are gaps. Read-only: it reads the two input files and writes a report;
        it changes nothing on any device or allow-list.
    HOW TO RUN
        powershell -ExecutionPolicy Bypass -File .\EGRESS-Report.ps1 -RequiredSetPath .\EGRESS-Output\egress-required-set.json -ValidationResultsPath .\EGRESS-Output -OutputPath .\EGRESS-Output
        No internet access or admin rights required; operates on local input files.
    EXPECTED RESULTS
        Writes egress-coverage-report.html (and a JSON summary) and prints a coverage summary. PASS =
        zero gaps in the required + Optimize + Allow set; FAIL = one or more required endpoints are gaps.
.NOTES
    White-label — the repeatable way. Read-only for discovery/validation.
#>

[CmdletBinding()]
param(
    [Parameter(Mandatory = $true)]
    [string]$RequiredSetPath,

    [Parameter(Mandatory = $true)]
    [string]$ValidationResultsPath,

    [string]$OutputPath = '.\EGRESS-Output'
)

$ErrorActionPreference = 'Stop'

if (-not (Test-Path -LiteralPath $RequiredSetPath)) { throw "Required-set file not found: $RequiredSetPath. Run EGRESS-Discovery.ps1 first." }

# Accept either a folder or a direct file for the validation results.
$resultsFile = $ValidationResultsPath
if (Test-Path -LiteralPath $ValidationResultsPath -PathType Container) {
    $resultsFile = Join-Path $ValidationResultsPath 'egress-validation-results.json'
}
if (-not (Test-Path -LiteralPath $resultsFile)) { throw "Validation results not found: $resultsFile. Run EGRESS-Validation.ps1 first." }
if (-not (Test-Path -LiteralPath $OutputPath)) { New-Item -ItemType Directory -Path $OutputPath -Force | Out-Null }

$requiredSet = Get-Content -LiteralPath $RequiredSetPath -Raw | ConvertFrom-Json
$validation  = Get-Content -LiteralPath $resultsFile -Raw | ConvertFrom-Json

# Build coverage rows: for each tested endpoint, PASS = covered/reachable, FAIL = gap.
$rows = foreach ($r in $validation.results) {
    [pscustomobject]@{
        serviceArea = $r.serviceArea
        category    = $r.category
        endpoint    = $r.sourcePattern
        host        = $r.host
        port        = $r.port
        reachable   = ($r.status -eq 'PASS')
        coverage    = if ($r.status -eq 'PASS') { 'Covered' } else { 'GAP' }
        detail      = $r.detail
    }
}

$total     = $rows.Count
$covered   = ($rows | Where-Object { $_.reachable }).Count
$gaps      = ($rows | Where-Object { -not $_.reachable })
$gapCount  = $gaps.Count
$coveragePct = if ($total -gt 0) { [math]::Round(($covered / $total) * 100, 1) } else { 0 }

# --- HTML report ------------------------------------------------------------
$rowsHtml = ($rows | Sort-Object coverage, serviceArea, host | ForEach-Object {
    $cls = if ($_.reachable) { 'ok' } else { 'gap' }
    "<tr class='$cls'><td>$($_.serviceArea)</td><td>$($_.category)</td><td>$([System.Web.HttpUtility]::HtmlEncode($_.endpoint))</td><td>$([System.Web.HttpUtility]::HtmlEncode($_.host))</td><td>$($_.port)</td><td>$($_.coverage)</td><td>$([System.Web.HttpUtility]::HtmlEncode($_.detail))</td></tr>"
}) -join "`n"

Add-Type -AssemblyName System.Web -ErrorAction SilentlyContinue

$gate = if ($gapCount -eq 0) { 'PASS' } else { 'FAIL' }
$gateColor = if ($gapCount -eq 0) { '#137333' } else { '#b00020' }

$html = @"
<!DOCTYPE html>
<html><head><meta charset='utf-8'><title>Egress Allow-List Coverage Report</title>
<style>
body{font-family:Segoe UI,Arial,sans-serif;margin:24px;color:#202124}
h1{font-size:20px}
.summary{margin:12px 0;padding:12px;border:1px solid #ddd;border-radius:6px;background:#fafafa}
.gatebox{display:inline-block;padding:6px 14px;border-radius:4px;color:#fff;font-weight:bold;background:$gateColor}
table{border-collapse:collapse;width:100%;font-size:13px;margin-top:12px}
th,td{border:1px solid #e0e0e0;padding:6px 8px;text-align:left}
th{background:#f1f3f4}
tr.gap td{background:#fdecea}
tr.ok td{background:#e8f5e9}
.small{color:#666;font-size:12px}
</style></head><body>
<h1>Egress Allow-List Coverage / Gap Report</h1>
<div class='summary'>
<p><span class='gatebox'>GATE T3: $gate</span></p>
<p>Instance: <b>$($requiredSet.instance)</b> &nbsp; Web service version: <b>$($requiredSet.webServiceVersion)</b></p>
<p>Tested from: <b>$($validation.testedFrom)</b> &nbsp; Generated: <b>$(Get-Date -Format 'u')</b></p>
<p>Coverage: <b>$covered / $total</b> checks reachable (<b>$coveragePct%</b>) &nbsp; Gaps: <b>$gapCount</b></p>
<p class='small'>Target: zero gaps in the required + Optimize + Allow set. Any GAP row is a required endpoint that is not reachable and must be added to the allow-list.</p>
</div>
<table>
<tr><th>Service area</th><th>Category</th><th>Endpoint</th><th>Test host</th><th>Port</th><th>Coverage</th><th>Detail</th></tr>
$rowsHtml
</table>
</body></html>
"@

$reportPath = Join-Path $OutputPath 'egress-coverage-report.html'
$html | Set-Content -LiteralPath $reportPath -Encoding UTF8

$summary = [pscustomobject]@{
    generatedAt       = (Get-Date).ToString('o')
    instance          = $requiredSet.instance
    webServiceVersion = $requiredSet.webServiceVersion
    totalChecks       = $total
    covered           = $covered
    coveragePct       = $coveragePct
    gapCount          = $gapCount
    gate              = $gate
    gaps              = $gaps
}
$summaryPath = Join-Path $OutputPath 'egress-coverage-summary.json'
$summary | ConvertTo-Json -Depth 6 | Set-Content -LiteralPath $summaryPath -Encoding UTF8

Write-Host ''
Write-Host "EGRESS Coverage Report" -ForegroundColor Cyan
Write-Host ('-' * 60)
Write-Host "Coverage : $covered / $total ($coveragePct%)"
Write-Host "Gaps     : $gapCount"
if ($gapCount -gt 0) {
    Write-Host "GATE T3: FAIL — required-set gaps present:" -ForegroundColor Red
    $gaps | Format-Table serviceArea, host, port, detail -AutoSize | Out-Host
}
else {
    Write-Host "GATE T3: PASS — zero required-set gaps." -ForegroundColor Green
}
Write-Host "HTML report : $reportPath" -ForegroundColor Gray
Write-Host "JSON summary: $summaryPath" -ForegroundColor Gray
