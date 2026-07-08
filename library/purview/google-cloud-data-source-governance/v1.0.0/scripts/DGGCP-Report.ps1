<#
.SYNOPSIS
    DGGCP-Report.ps1 — Google BigQuery scan + classification coverage report (read-only).
.DESCRIPTION
    PURPOSE
        Reports the health of the governed Google Cloud estate for a scope: latest scan run status per
        BigQuery source, counts of classified vs unclassified assets, and owner coverage. Read-only —
        it queries the Purview data-plane REST / catalog search and changes nothing. Use it to review
        the pilot (Testing Guide) and to track coverage as the estate expands.
    HOW TO RUN
        powershell -ExecutionPolicy Bypass -File .\DGGCP-Report.ps1 -PurviewAccount contoso-purview `
            -Collection DGGCP-Collection-Pilot
        Requires Az.Accounts + Connect-AzAccount with at least Data reader on the collection.
    EXPECTED RESULTS
        A coverage summary: per-source last scan status (Succeeded/Failed/Running), classified vs
        unclassified asset counts with a classification-coverage %, and owner coverage — PASS/GAP flags
        you can record against the pass/fail gate.
.NOTES
    Purview — Data Governance (Google BigQuery). Read-only. Verify current search/scan API versions for
    your tenant; the Data Governance experience and its endpoints are evolving.
#>
[CmdletBinding()]
param(
    [Parameter(Mandatory = $true)][string]$PurviewAccount,
    [string]$Collection,
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

Write-Host "`n=== Purview — Google BigQuery coverage & health report ===" -ForegroundColor Cyan

# 1) Scan run status per source (BigQuery sources)
try {
    $sources = @((Invoke-Purview '/scan/datasources?api-version=2018-12-01-preview').value)
    $bq = @($sources | Where-Object { $_.kind -match 'BigQuery' })
    Write-Host ("`nSources          : {0} registered ({1} Google BigQuery)" -f $sources.Count, $bq.Count)
    foreach ($s in $bq) {
        try {
            $scans = @((Invoke-Purview ("/scan/datasources/{0}/scans?api-version=2018-12-01-preview" -f $s.name)).value)
            foreach ($sc in $scans) {
                $hist = @((Invoke-Purview ("/scan/datasources/{0}/scans/{1}/runs?api-version=2018-12-01-preview" -f $s.name, $sc.name)).value)
                $last = $hist | Sort-Object { $_.startTime } -Descending | Select-Object -First 1
                $st = if ($last) { $last.status } else { 'No runs' }
                $col = switch ($st) { 'Succeeded' {'Green'} 'Failed' {'Red'} default {'Yellow'} }
                Write-Host ("    {0} / {1} : last run {2}" -f $s.name, $sc.name, $st) -ForegroundColor $col
            }
        } catch { Write-Host ("    {0} : (scan history unavailable)" -f $s.name) -ForegroundColor DarkGray }
    }
} catch {
    Write-Host ("Sources          : could not read ({0})" -f $_.Exception.Message) -ForegroundColor Yellow
}

# 2) Classification + owner coverage via catalog search
$total = 0; $classified = 0; $owned = 0
try {
    $search = @{ keywords = '*'; limit = 1000 }
    if ($Collection) { $search.filter = @{ collectionId = $Collection } }
    $res = Invoke-Purview '/catalog/api/search/query?api-version=2022-03-01-preview' 'POST' $search
    $rows = @($res.value)
    $total = $rows.Count
    $classified = @($rows | Where-Object { $_.classification -and @($_.classification).Count -gt 0 }).Count
    $owned = @($rows | Where-Object { $_.owner -or $_.experts -or $_.contact }).Count
} catch {
    Write-Host ("`nClassification   : catalog search unavailable ({0})" -f $_.Exception.Message) -ForegroundColor Yellow
}

if ($total -gt 0) {
    $pct = [math]::Round(($classified / $total) * 100, 1)
    $ownPct = [math]::Round(($owned / $total) * 100, 1)
    Write-Host ("`nAssets (scanned) : {0}" -f $total)
    Write-Host ("  Classified     : {0} ({1}%)" -f $classified, $pct) -ForegroundColor ($(if($pct -gt 0){'Green'}else{'Yellow'}))
    Write-Host ("  Unclassified   : {0}" -f ($total - $classified)) -ForegroundColor ($(if(($total-$classified) -eq 0){'Green'}else{'Yellow'}))
    Write-Host ("  With owner     : {0} ({1}%)" -f $owned, $ownPct) -ForegroundColor ($(if($ownPct -gt 0){'Green'}else{'Yellow'}))
} else {
    Write-Host "`nAssets (scanned) : 0 returned — run a scan or widen the search scope." -ForegroundColor Yellow
}

Write-Host "`nGate check: pilot passes when the BigQuery scan Succeeded, classification coverage > 0, and every scanned asset has an owner." -ForegroundColor Cyan
Write-Host "Note: API versions above are examples — verify current Purview data-plane API versions for your tenant." -ForegroundColor DarkGray
