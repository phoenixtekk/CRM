<#
.SYNOPSIS
    WINPERF-Report.ps1 — fleet-wide performance and reliability roll-up from collected results.
.DESCRIPTION
    PURPOSE
        Aggregates the JSON result files produced by WINPERF-Discovery.ps1 and WINPERF-Validation.ps1
        across many devices into a single fleet view: how many devices pass each gate, which devices
        are slow or unstable, and the FAIL rows that need attention. Read-only: it only reads the
        result files you point it at and writes a report.
    HOW TO RUN
        powershell -ExecutionPolicy Bypass -File .\WINPERF-Report.ps1 -InputFolder .\results

        Optional: -OutFile fleet-perf-report.html   to write an HTML report (CSV also produced).
    EXPECTED RESULTS
        A console summary (device count, pass rate per branch, worst offenders) plus a written
        CSV/HTML report. Any unexplained FAIL row is a device to troubleshoot with the playbook. A
        rising FAIL trend across runs means a problem is forming fleet-wide.
.NOTES
    White-label — the repeatable way. Read-only for discovery/validation.
#>

[CmdletBinding()]
param(
    [Parameter(Mandatory=$true)]
    [string]$InputFolder,
    [string]$OutFile = "fleet-perf-report.html"
)

$ErrorActionPreference = 'Stop'

if (-not (Test-Path $InputFolder)) { throw "Input folder not found: $InputFolder" }

$files = Get-ChildItem -Path $InputFolder -Filter *.json -File -ErrorAction SilentlyContinue
if (-not $files) { Write-Warning "No .json result files found in $InputFolder"; return }

Write-Host "=== WINPERF Fleet Report — $(Get-Date -Format s) ===" -ForegroundColor Cyan
Write-Host ("Reading {0} result file(s) from {1}" -f $files.Count, $InputFolder)

$rows = @()
foreach ($f in $files) {
    try { $data = Get-Content -Raw -LiteralPath $f.FullName | ConvertFrom-Json } catch { Write-Warning "Skip $($f.Name): $_"; continue }
    $computer = $data.Computer
    if ($data.Findings) {
        # Validation-style file
        foreach ($fd in $data.Findings) {
            $rows += [PSCustomObject]@{
                Computer = $computer
                Branch   = $fd.Branch
                Metric   = $fd.Metric
                Value    = $fd.Value
                Result   = $fd.Result
                Note     = $fd.Note
            }
        }
    } else {
        # Discovery-style snapshot
        $rows += [PSCustomObject]@{ Computer=$computer; Branch='Discovery'; Metric='BootTimeMs'; Value=$data.BootTimeMs; Result=''; Note='' }
        $rows += [PSCustomObject]@{ Computer=$computer; Branch='Discovery'; Metric='Bugchecks14d'; Value=$data.Bugchecks14d; Result=''; Note='' }
        $rows += [PSCustomObject]@{ Computer=$computer; Branch='Discovery'; Metric='SystemFreePct'; Value=$data.SystemFreePct; Result=''; Note='' }
    }
}

$devices = $rows.Computer | Select-Object -Unique
$fails   = @($rows | Where-Object { $_.Result -eq 'FAIL' })

Write-Host "`n--- Fleet summary ---" -ForegroundColor Cyan
Write-Host ("Devices reporting : {0}" -f $devices.Count)
Write-Host ("Total FAIL rows   : {0}" -f $fails.Count)

Write-Host "`nPass rate by branch:" -ForegroundColor Cyan
$rows | Where-Object { $_.Result -in 'PASS','FAIL' } | Group-Object Branch | ForEach-Object {
    $tot = $_.Count
    $pass = @($_.Group | Where-Object { $_.Result -eq 'PASS' }).Count
    Write-Host ("  {0,-14} {1,3}/{2,-3} PASS" -f $_.Name, $pass, $tot)
}

if ($fails.Count) {
    Write-Host "`nDevices with failing gates:" -ForegroundColor Yellow
    $fails | Group-Object Computer | Sort-Object Count -Descending | ForEach-Object {
        Write-Host ("  {0}  ({1} FAIL)" -f $_.Name, $_.Count)
    }
}

# --- Write CSV + HTML ---
$csvPath = [System.IO.Path]::ChangeExtension($OutFile, 'csv')
$rows | Export-Csv -Path $csvPath -NoTypeInformation -Encoding UTF8

$style = "<style>body{font-family:Segoe UI,Arial,sans-serif;margin:20px} table{border-collapse:collapse;width:100%} th,td{border:1px solid #ccc;padding:6px;font-size:13px;text-align:left} th{background:#f0f0f0} tr.fail{background:#fde8e8} tr.pass{background:#e8f6ec}</style>"
$body = "<h1>Fleet Performance &amp; Reliability Report</h1><p>Generated $(Get-Date -Format s) — $($devices.Count) device(s), $($fails.Count) failing gate(s).</p>"
$rowsHtml = foreach ($r in ($rows | Sort-Object @{e='Result';Descending=$true}, Computer, Branch)) {
    $cls = switch ($r.Result) { 'FAIL' {'fail'} 'PASS' {'pass'} default {''} }
    "<tr class='$cls'><td>$($r.Computer)</td><td>$($r.Branch)</td><td>$($r.Metric)</td><td>$($r.Value)</td><td>$($r.Result)</td><td>$($r.Note)</td></tr>"
}
$html = "<html><head>$style</head><body>$body<table><tr><th>Computer</th><th>Branch</th><th>Metric</th><th>Value</th><th>Result</th><th>Note</th></tr>$($rowsHtml -join '')</table></body></html>"
$html | Out-File -FilePath $OutFile -Encoding UTF8

Write-Host "`nWrote report: $OutFile" -ForegroundColor Green
Write-Host "Wrote data  : $csvPath" -ForegroundColor Green
