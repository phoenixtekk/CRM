<#
.SYNOPSIS
    LICRPT-Export-Scheduled.ps1 — export the license/usage extract that feeds the Power BI dataset.
.DESCRIPTION
    PURPOSE
        Produces the recurring extract the Power BI dataset 'License Usage & Cost - Software Assets -
        Dataset' consumes: per-SKU entitled/assigned counts (subscribed SKUs) plus per-user license
        activity (last activity date) from the Microsoft 365 usage reports. Intended to be run on a
        schedule (Task Scheduler) so the dashboard always has a fresh source file.
    HOW TO RUN
        Dry run (default — reports what it WOULD write, writes nothing):
            powershell -ExecutionPolicy Bypass -File .\LICRPT-Export-Scheduled.ps1
        Real export (writes the CSVs):
            powershell -ExecutionPolicy Bypass -File .\LICRPT-Export-Scheduled.ps1 -Run -OutDir C:\LicReporting
        Requires the Microsoft Graph SDK and the read scopes Organization.Read.All and Reports.Read.All.
    EXPECTED RESULTS
        Dry run: counts of SKUs and usage rows that would be exported, and the target file paths.
        Real run: licrpt-skus.csv and licrpt-usage.csv written to -OutDir for Power BI to refresh from.
.NOTES
    Software Asset Management — License Reporting. Defaults to a single dry run; -Run performs the export.
#>
[CmdletBinding()] param(
    [switch]$Run,
    [string]$OutDir = "$env:TEMP\LicReporting",
    [ValidateSet('D7','D30','D90','D180')][string]$Period = 'D30'
)

if (-not (Get-Module -ListAvailable -Name Microsoft.Graph.Authentication)) {
    Install-Module Microsoft.Graph -Scope CurrentUser -Force -AllowClobber
}
Import-Module Microsoft.Graph.Authentication -ErrorAction Stop
Connect-MgGraph -Scopes 'Organization.Read.All','Reports.Read.All' -NoWelcome

$mode = if ($Run) { 'EXPORT' } else { 'DRY RUN' }
Write-Host "`n=== License/usage extract — $mode (period $Period) ===" -ForegroundColor Cyan

# 1) Subscribed SKUs (entitled vs. assigned)
$skus = (Invoke-MgGraphRequest -Method GET -Uri '/v1.0/subscribedSkus').value
$skuRows = $skus | ForEach-Object {
    [pscustomobject]@{
        SkuPartNumber = $_.skuPartNumber
        Entitled      = $_.prepaidUnits.enabled
        Assigned      = $_.consumedUnits
    }
}
Write-Host ("Subscribed SKUs   : {0} row(s)" -f $skuRows.Count)

# 2) Per-user license activity (usage signal). Graph returns CSV text for report endpoints.
$usageRows = @()
try {
    $csv = Invoke-MgGraphRequest -Method GET -Uri "/v1.0/reports/getOffice365ActiveUserDetail(period='$Period')" -OutputType HttpResponseMessage
    $text = $csv.Content.ReadAsStringAsync().Result
    $usageRows = $text | ConvertFrom-Csv
    Write-Host ("Usage activity    : {0} row(s)" -f $usageRows.Count)
} catch {
    Write-Host ("Usage report not retrieved: {0}" -f $_.Exception.Message) -ForegroundColor Yellow
}

$skuPath   = Join-Path $OutDir 'licrpt-skus.csv'
$usagePath = Join-Path $OutDir 'licrpt-usage.csv'

if ($Run) {
    if (-not (Test-Path $OutDir)) { New-Item -ItemType Directory -Path $OutDir -Force | Out-Null }
    $skuRows | Export-Csv -Path $skuPath -NoTypeInformation
    if ($usageRows.Count) { $usageRows | Export-Csv -Path $usagePath -NoTypeInformation }
    Write-Host "`nWrote:" -ForegroundColor Green
    Write-Host "  $skuPath"
    if ($usageRows.Count) { Write-Host "  $usagePath" }
    Write-Host "Point the Power BI dataset's source at these files, then refresh." -ForegroundColor Cyan
} else {
    Write-Host "`nDRY RUN — nothing written. Would write:" -ForegroundColor Yellow
    Write-Host "  $skuPath"
    Write-Host "  $usagePath"
    Write-Host "Re-run with -Run -OutDir <path> to perform the export." -ForegroundColor Yellow
}
Disconnect-MgGraph | Out-Null
