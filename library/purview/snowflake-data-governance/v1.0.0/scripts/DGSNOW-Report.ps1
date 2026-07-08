<#
.SYNOPSIS
    DGSNOW-Report.ps1 — Produce the Snowflake governance coverage report (read-only; optional CSV export).
.DESCRIPTION
    PURPOSE
        Builds 'Snowflake - Coverage Report' — the registered Snowflake source, its scans, and each scan's
        most recent run status — as the management evidence artifact. Uses the Purview Data Map REST API with
        a token acquired at runtime. Read-only; stores no secret; writing a CSV is opt-in.
    HOW TO RUN
        .\DGSNOW-Report.ps1 -PurviewAccount "<your-purview-account>"
        .\DGSNOW-Report.ps1 -PurviewAccount "<your-purview-account>" -CsvPath .\SnowflakeReport.csv
        PowerShell 5.1+/7+. Connect first with Connect-AzAccount. No secret is stored in the script.
    EXPECTED RESULTS
        A table (and optional CSV) of the source, its scans, and last-run status — re-runnable on a schedule.
        (Deep classification counts are reviewed in the catalog UI.) Makes no configuration change.
.NOTES
    Purview — Snowflake Data Governance. Read-only reporting. Verify your licensing/tenant: the run-status
    schema + API version evolve.
#>
[CmdletBinding()]
param(
    [Parameter(Mandatory)] [string]$PurviewAccount,
    [string]$SourceName = 'Snowflake - Source',
    [string]$ApiVersion = '2022-07-01-preview',
    [string]$CsvPath
)

function Get-PurviewToken {
    try { return (Get-AzAccessToken -ResourceUrl 'https://purview.azure.net' -ErrorAction Stop).Token }
    catch { Write-Host "Could not acquire a Purview token. Run Connect-AzAccount first." -ForegroundColor Yellow; return $null }
}

$token = Get-PurviewToken
if (-not $token) { return }
$headers = @{ Authorization = "Bearer $token" }
$base = "https://$PurviewAccount.purview.azure.com"
function Invoke-Pv([string]$Path) {
    try { return Invoke-RestMethod -Method GET -Uri ("{0}{1}" -f $base, $Path) -Headers $headers -ErrorAction Stop }
    catch { return $null }
}

Write-Host "`n=== Snowflake Data Governance — coverage report (read-only) ===" -ForegroundColor Cyan

$src = Invoke-Pv ("/scan/datasources/{0}?api-version={1}" -f $SourceName, $ApiVersion)
if (-not $src) { Write-Host ("Source '{0}' not found — register it first." -f $SourceName) -ForegroundColor Yellow; return }

$scans = Invoke-Pv ("/scan/datasources/{0}/scans?api-version={1}" -f $SourceName, $ApiVersion)
$rows = if ($scans -and $scans.value) {
    foreach ($sc in $scans.value) {
        $runs = Invoke-Pv ("/scan/datasources/{0}/scans/{1}/runs?api-version={2}" -f $SourceName, $sc.name, $ApiVersion)
        $last = if ($runs -and $runs.value) { $runs.value | Select-Object -First 1 } else { $null }
        [pscustomobject]@{
            Source        = $SourceName
            Scan          = $sc.name
            Kind          = $sc.kind
            LastRunStatus = if ($last) { "$($last.status)" } else { '(no runs)' }
            LastRunTime   = if ($last) { "$($last.startTime)" } else { '' }
        }
    }
} else {
    @([pscustomobject]@{ Source=$SourceName; Scan='(none)'; Kind=''; LastRunStatus=''; LastRunTime='' })
}

$rows | Format-Table -AutoSize
Write-Host "Review classification counts per asset in the Purview catalog UI (not summarized via this API here)." -ForegroundColor DarkGray

if ($CsvPath) {
    try { $rows | Export-Csv -Path $CsvPath -NoTypeInformation -Encoding UTF8; Write-Host ("Report written: {0}" -f (Resolve-Path $CsvPath)) -ForegroundColor Green }
    catch { Write-Host ("Could not write CSV: {0}" -f $_.Exception.Message) -ForegroundColor Red }
} else {
    Write-Host "INFO  Console-only. Pass -CsvPath to export 'Snowflake - Coverage Report'." -ForegroundColor DarkGray
}
