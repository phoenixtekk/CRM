<#
.SYNOPSIS
    DGLINE-Report.ps1 — read-only data-lineage coverage report (assets with vs. without lineage). No changes.
.DESCRIPTION
    PURPOSE
        Enumerates the in-scope catalog assets (optionally filtered by keyword/collection) and reports
        lineage COVERAGE — how many assets have at least one lineage edge vs. none — so gaps are explicit
        and can be closed deliberately (missing scan, missing connection, or a custom Process to push).
        Read-only. Makes no changes. Writes "Data Lineage Coverage - DGLINE - Report".
    HOW TO RUN
        powershell -File .\DGLINE-Report.ps1 -Account <acct> [-Keyword '<filter>'] [-Limit 200] -CsvPath .\LineageCoverage.csv
        PowerShell 5.1+ or 7+. Requires Az.Accounts. Data curator/reader role on the in-scope collection.
    EXPECTED RESULTS
        A per-asset table (asset, type, has-lineage) and a summary (with-lineage / without-lineage counts),
        plus an optional CSV. PASS = a dated coverage snapshot exists and each without-lineage asset is a
        known follow-up item.
.NOTES
    Purview — Data Lineage Implementation (DGLINE). Read-only. No secrets in code.
    Catalog search + Atlas lineage endpoints + api-version are cited as of authoring and evolving — verify in your tenant.
    Coverage is measured against the governance team's target; they own which paths MUST be traceable.
#>
[CmdletBinding()]
param(
    [Parameter(Mandatory)][string]$Account,
    [string]$Keyword = '*',
    [int]$Limit = 200,
    [string]$CsvPath,
    [string]$ResourceUrl   = 'https://purview.azure.net',
    [string]$CatalogApiVer = '2022-03-01-preview',
    [string]$ReportName    = 'Data Lineage Coverage - DGLINE - Report'
)

$ErrorActionPreference = 'Stop'
$endpoint = "https://$Account.purview.azure.com"
Write-Host ("=== {0} — {1} ===" -f $ReportName, $endpoint) -ForegroundColor Cyan

if (-not (Get-Module -ListAvailable -Name Az.Accounts)) {
    Install-Module Az.Accounts -Scope CurrentUser -Force -AllowClobber
}
Import-Module Az.Accounts -ErrorAction Stop
if (-not (Get-AzContext)) { Connect-AzAccount | Out-Null }
$token   = (Get-AzAccessToken -ResourceUrl $ResourceUrl).Token
$headers = @{ Authorization = "Bearer $token"; 'Content-Type' = 'application/json' }

# --- Enumerate in-scope assets (read-only search) ---
$searchUri  = "$endpoint/catalog/api/search/query?api-version=$CatalogApiVer"
$searchBody = @{ keywords = $Keyword; limit = $Limit } | ConvertTo-Json
$assets = @()
try { $assets = @((Invoke-RestMethod -Method POST -Uri $searchUri -Headers $headers -Body $searchBody).value) }
catch { throw "Catalog search failed: $($_.Exception.Message). Verify the account, api-version, and your role." }

Write-Host ("In-scope assets returned: {0} (limit {1})" -f $assets.Count, $Limit) -ForegroundColor Cyan

function Test-HasLineage([string]$guid) {
    if (-not $guid) { return $false }
    try {
        $uri = "$endpoint/catalog/api/atlas/v2/lineage/$guid?depth=1&direction=BOTH&api-version=$CatalogApiVer"
        $lin = Invoke-RestMethod -Method GET -Uri $uri -Headers $headers
        return (@($lin.relations).Count -gt 0)
    } catch { return $false }
}

$rows = foreach ($a in $assets) {
    $has = Test-HasLineage $a.id
    [pscustomobject]@{
        Asset         = $a.qualifiedName
        Type          = $a.entityType
        Collection    = $a.collectionId
        HasLineage    = $has
    }
}

$rows | Sort-Object HasLineage, Type, Asset | Format-Table Asset, Type, HasLineage -AutoSize

$with    = @($rows | Where-Object { $_.HasLineage }).Count
$without = @($rows | Where-Object { -not $_.HasLineage }).Count
$total   = $rows.Count
$pct     = if ($total) { [math]::Round(100.0 * $with / $total, 1) } else { 0 }

Write-Host '--- Coverage summary ---' -ForegroundColor Cyan
Write-Host ("  With lineage   : {0}" -f $with)
Write-Host ("  Without lineage: {0}" -f $without) -ForegroundColor $(if ($without) {'Yellow'} else {'Green'})
Write-Host ("  Coverage       : {0}% of {1} assets" -f $pct, $total) -ForegroundColor Cyan

if ($CsvPath) {
    $rows | Export-Csv -Path $CsvPath -NoTypeInformation
    Write-Host ("Saved '{0}' to {1}" -f $ReportName, $CsvPath) -ForegroundColor Green
}
Write-Host 'Coverage report complete (read-only). Treat each without-lineage asset as a follow-up (scan / connect / push custom lineage).' -ForegroundColor Green
