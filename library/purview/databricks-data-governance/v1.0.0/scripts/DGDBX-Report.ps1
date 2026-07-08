<#
.SYNOPSIS
    DGDBX-Report.ps1 — Export Databricks scan status, classification, and lineage coverage to CSV (read-only).
.DESCRIPTION
    PURPOSE
        Reports the health of the governed Databricks estate for a scope and exports it to CSV: latest scan
        run status per Azure Databricks source, counts of classified vs unclassified lakehouse assets,
        ownership coverage, and lineage coverage (assets that have lineage relationships). Read-only — it
        queries the Purview data-plane REST / catalog search and changes nothing. Use it to review the pilot
        (Testing Guide) and to track coverage as the metastore is expanded.
    HOW TO RUN
        powershell -ExecutionPolicy Bypass -File .\DGDBX-Report.ps1 -PurviewAccount contoso-purview `
            -Collection DGDBX-Collection-Pilot -OutFile .\dgdbx-report.csv
        Requires Az.Accounts + Connect-AzAccount with at least Data reader on the collection.
    EXPECTED RESULTS
        A console coverage summary AND a CSV (default .\dgdbx-report.csv) with one row per scanned asset —
        name, type, qualified name, classifications, owner, and whether lineage is present — plus a printed
        classification-, ownership-, and lineage-coverage percentage. PASS/GAP flags you can record against
        the pass/fail gate.
.NOTES
    Purview — Databricks Data Governance. Read-only. Verify current search/scan/lineage API versions for
    your tenant; the Data Governance experience and its endpoints are evolving, and lineage depth is
    connector-dependent.
#>
[CmdletBinding()]
param(
    [Parameter(Mandatory = $true)][string]$PurviewAccount,
    [string]$Collection,
    [string]$OutFile = '.\dgdbx-report.csv',
    [string]$Endpoint = "https://$PurviewAccount.purview.azure.com"
)

Import-Module Az.Accounts -ErrorAction Stop
if (-not (Get-AzContext)) { Write-Host "Not signed in. Run Connect-AzAccount first." -ForegroundColor Yellow; return }
$token = (Get-AzAccessToken -ResourceUrl 'https://purview.azure.net').Token
$headers = @{ Authorization = "Bearer $token"; 'Content-Type' = 'application/json' }

function Invoke-Purview([string]$Path, [string]$Method = 'GET', $Body = $null) {
    $p = @{ Method = $Method; Uri = ("{0}{1}" -f $Endpoint, $Path); Headers = $headers; ErrorAction = 'Stop' }
    if ($Body) { $p.Body = ($Body | ConvertTo-Json -Depth 6) }
    Invoke-RestMethod @p
}

Write-Host "`n=== Purview Databricks Data Governance — coverage & health report ===" -ForegroundColor Cyan

# 1) Scan run status per Databricks source
try {
    $sources = @((Invoke-Purview '/scan/datasources?api-version=2018-12-01-preview').value)
    $dbx = @($sources | Where-Object { $_.kind -match 'Databricks|UnityCatalog|Hive' })
    Write-Host ("`nDatabricks src   : {0} registered (of {1} total)" -f $dbx.Count, $sources.Count)
    if ($dbx.Count -eq 0) { Write-Host "    (no Databricks source — register with DGDBX-Register-DatabricksSource.ps1)" -ForegroundColor Yellow }
    foreach ($s in $dbx) {
        try {
            $scans = @((Invoke-Purview ("/scan/datasources/{0}/scans?api-version=2018-12-01-preview" -f $s.name)).value)
            foreach ($sc in $scans) {
                $hist = @((Invoke-Purview ("/scan/datasources/{0}/scans/{1}/runs?api-version=2018-12-01-preview" -f $s.name, $sc.name)).value)
                $last = $hist | Sort-Object { $_.startTime } -Descending | Select-Object -First 1
                $st = if ($last) { $last.status } else { 'No runs' }
                $col = switch ($st) { 'Succeeded' {'Green'} 'Failed' {'Red'} default {'Yellow'} }
                Write-Host ("    {0} [{1}] / {2} : last run {3}" -f $s.name, $s.kind, $sc.name, $st) -ForegroundColor $col
            }
        } catch { Write-Host ("    {0} : (scan history unavailable)" -f $s.name) -ForegroundColor DarkGray }
    }
} catch {
    Write-Host ("Databricks src   : could not read ({0})" -f $_.Exception.Message) -ForegroundColor Yellow
}

# 2) Asset-level classification / ownership / lineage coverage via catalog search
$rows = @()
try {
    $search = @{ keywords = '*'; limit = 1000 }
    if ($Collection) { $search.filter = @{ collectionId = $Collection } }
    $res = Invoke-Purview '/catalog/api/search/query?api-version=2022-03-01-preview' 'POST' $search
    $rows = @($res.value | Where-Object { $_.assetType -match 'Databricks|Hive|databricks' -or $_.qualifiedName -match 'databricks|unity|metastore' })
    if ($rows.Count -eq 0) { $rows = @($res.value) }   # fall back to all in-scope assets if the Databricks filter matches none
} catch {
    Write-Host ("`nCatalog search   : unavailable ({0})" -f $_.Exception.Message) -ForegroundColor Yellow
}

# Build per-asset CSV rows. Lineage presence is checked per asset (verify current lineage API version).
$report = @()
foreach ($a in $rows) {
    $classes = @($a.classification) -join ';'
    $owner   = @($a.owner, $a.contact, $a.experts | Where-Object { $_ }) -join ';'
    $hasLineage = $false
    if ($a.id) {
        try {
            $lin = Invoke-Purview ("/catalog/api/atlas/v2/lineage/{0}?depth=1&direction=BOTH" -f $a.id)
            $rel = @($lin.relations)
            $hasLineage = $rel.Count -gt 0
        } catch { $hasLineage = $false }   # lineage read is best-effort; verify the current lineage API for your tenant
    }
    $report += [pscustomobject]@{
        Name           = $a.name
        AssetType      = $a.assetType
        QualifiedName  = $a.qualifiedName
        Classified     = [bool]$classes
        Classifications= $classes
        Owner          = $owner
        HasLineage     = $hasLineage
    }
}

$total = $report.Count
if ($total -gt 0) {
    $classified = @($report | Where-Object { $_.Classified }).Count
    $owned      = @($report | Where-Object { $_.Owner }).Count
    $withLin    = @($report | Where-Object { $_.HasLineage }).Count
    $pct    = [math]::Round(($classified / $total) * 100, 1)
    $ownPct = [math]::Round(($owned / $total) * 100, 1)
    $linPct = [math]::Round(($withLin / $total) * 100, 1)

    $report | Export-Csv -Path $OutFile -NoTypeInformation -Encoding UTF8

    Write-Host ("`nAssets (scanned) : {0}" -f $total)
    Write-Host ("  Classified     : {0} ({1}%)" -f $classified, $pct) -ForegroundColor ($(if($pct -gt 0){'Green'}else{'Yellow'}))
    Write-Host ("  Unclassified   : {0}" -f ($total - $classified)) -ForegroundColor ($(if(($total-$classified) -eq 0){'Green'}else{'Yellow'}))
    Write-Host ("  With owner     : {0} ({1}%)" -f $owned, $ownPct) -ForegroundColor ($(if($ownPct -gt 0){'Green'}else{'Yellow'}))
    Write-Host ("  With lineage   : {0} ({1}%)" -f $withLin, $linPct) -ForegroundColor ($(if($linPct -gt 0){'Green'}else{'Yellow'}))
    Write-Host ("`nCSV written      : {0}" -f (Resolve-Path $OutFile)) -ForegroundColor Green
} else {
    Write-Host "`nAssets (scanned) : 0 returned — run a scan or widen the search scope. No CSV written." -ForegroundColor Yellow
}

Write-Host "`nGate check: pilot passes when the Databricks scan(s) Succeeded, classification coverage > 0, and every scanned asset has an owner. Lineage coverage is connector-dependent — verify." -ForegroundColor Cyan
Write-Host "Note: API versions above are examples — verify current Purview data-plane API versions for your tenant." -ForegroundColor DarkGray
