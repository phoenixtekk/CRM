<#
.SYNOPSIS
    DGORACLE-Report.ps1 — Scan status + classification/owner coverage report for Oracle assets (read-only).
.DESCRIPTION
    PURPOSE
        Reports how the Oracle governance pilot is doing: for the Oracle source(s), the latest scan run
        status, the assets returned into the Data Map (schemas/tables/columns), how many carry a
        classification vs are unclassified, and how many carry an owner/steward. Read-only — it queries
        the Purview data-plane REST API and changes nothing. Use it after a pilot scan and after each
        expansion scope to confirm classification and ownership coverage.
    HOW TO RUN
        powershell -ExecutionPolicy Bypass -File .\DGORACLE-Report.ps1 -PurviewAccount contoso-purview
        Optional: -SourceName oracle-oradb01 to focus on one source.
        Requires Az.Accounts and Connect-AzAccount with at least Data reader on the collection. Acquires
        a data-plane token (resource https://purview.azure.net); no secret is stored in the script.
    EXPECTED RESULTS
        Per Oracle source: latest scan run status (ideally Succeeded), asset count, classified vs
        unclassified counts, and owner-coverage count — a coverage snapshot to check against the pass/fail
        gate (scan Succeeded, classification coverage > 0, every asset owned).
.NOTES
    Purview — Oracle Data Governance. Read-only. Verify the current scan/search API versions and the
    search filter fields for your tenant — the Data Governance search surface is evolving.
#>
[CmdletBinding()]
param(
    [Parameter(Mandatory = $true)][string]$PurviewAccount,
    [string]$SourceName,                                      # optional: focus on one Oracle source
    [string]$Endpoint = "https://$PurviewAccount.purview.azure.com"
)

Import-Module Az.Accounts -ErrorAction Stop
if (-not (Get-AzContext)) { Write-Host "Not signed in. Run Connect-AzAccount first." -ForegroundColor Yellow; return }
$token = (Get-AzAccessToken -ResourceUrl 'https://purview.azure.net').Token
$headers = @{ Authorization = "Bearer $token"; 'Content-Type' = 'application/json' }

function Invoke-Purview([string]$Path, [string]$Method = 'GET', $Body) {
    $u = ("{0}{1}" -f $Endpoint, $Path)
    if ($Body) { Invoke-RestMethod -Method $Method -Uri $u -Headers $headers -Body $Body -ErrorAction Stop }
    else       { Invoke-RestMethod -Method $Method -Uri $u -Headers $headers -ErrorAction Stop }
}

Write-Host "`n=== Purview Oracle Data Governance — scan + classification coverage ===" -ForegroundColor Cyan

# 1) Enumerate Oracle sources
$sources = @()
try {
    $all = @((Invoke-Purview '/scan/datasources?api-version=2018-12-01-preview').value)
    $sources = @($all | Where-Object { $_.kind -match 'Oracle' })
    if ($SourceName) { $sources = @($sources | Where-Object { $_.name -eq $SourceName }) }
} catch {
    Write-Host ("Could not read data sources: {0}" -f $_.Exception.Message) -ForegroundColor Yellow; return
}
if ($sources.Count -eq 0) { Write-Host "No Oracle sources found. Register one with DGORACLE-Register-OracleSource.ps1." -ForegroundColor Yellow; return }

# 2) Latest scan run status per source
foreach ($s in $sources) {
    Write-Host ("`nSource           : {0}" -f $s.name) -ForegroundColor White
    try {
        $scans = @((Invoke-Purview ("/scan/datasources/{0}/scans?api-version=2018-12-01-preview" -f $s.name)).value)
        foreach ($sc in $scans) {
            try {
                $runs = @((Invoke-Purview ("/scan/datasources/{0}/scans/{1}/runs?api-version=2018-12-01-preview" -f $s.name, $sc.name)).value)
                $latest = $runs | Sort-Object { $_.startTime } -Descending | Select-Object -First 1
                $status = if ($latest) { $latest.status } else { '(no runs yet)' }
                $col = if ($status -eq 'Succeeded') { 'Green' } elseif ($status -match 'Failed') { 'Red' } else { 'Yellow' }
                Write-Host ("  Scan {0,-28}: latest run {1}" -f $sc.name, $status) -ForegroundColor $col
            } catch {
                Write-Host ("  Scan {0,-28}: (run read skipped: {1})" -f $sc.name, $_.Exception.Message) -ForegroundColor DarkGray
            }
        }
        if ($scans.Count -eq 0) { Write-Host "  (no scans configured — configure one with DGORACLE-Register-OracleSource.ps1 -ConfigureScan)" -ForegroundColor DarkGray }
    } catch {
        Write-Host ("  (scan read skipped: {0})" -f $_.Exception.Message) -ForegroundColor DarkGray
    }
}

# 3) Classification + owner coverage via catalog search (verify the current search API + filter fields)
Write-Host "`nClassification/owner coverage (catalog search):" -ForegroundColor Cyan
try {
    $searchBody = @{ keywords = $null; filter = @{ 'and' = @(@{ 'assetType' = 'Oracle' }) }; limit = 100 } | ConvertTo-Json -Depth 6
    $res = Invoke-Purview '/catalog/api/search/query?api-version=2022-08-01-preview' 'POST' $searchBody
    $assets = @($res.value)
    if ($assets.Count -eq 0) {
        Write-Host "  No Oracle assets returned by search yet — allow time after a Succeeded scan, or verify the search filter/API for your tenant." -ForegroundColor DarkGray
    } else {
        $classified   = @($assets | Where-Object { $_.classification -and @($_.classification).Count -gt 0 }).Count
        $unclassified = $assets.Count - $classified
        $owned        = @($assets | Where-Object { $_.owner -or $_.contact -or $_.ownerId }).Count
        Write-Host ("  Assets (sampled): {0}" -f $assets.Count) -ForegroundColor White
        Write-Host ("  Classified      : {0}" -f $classified) -ForegroundColor ($(if($classified -gt 0){'Green'}else{'Yellow'}))
        Write-Host ("  Unclassified    : {0} (review with the data owner — expected for non-sensitive columns)" -f $unclassified) -ForegroundColor DarkGray
        Write-Host ("  With owner      : {0} of {1} (every governed asset should be owned)" -f $owned, $assets.Count) -ForegroundColor ($(if($owned -eq $assets.Count){'Green'}else{'Yellow'}))
    }
} catch {
    Write-Host ("  Search coverage skipped: {0}" -f $_.Exception.Message) -ForegroundColor DarkGray
    Write-Host "  Verify the current Data Governance catalog search API + filter fields for your tenant." -ForegroundColor DarkGray
}

Write-Host "`nGate check: scan Succeeded, classification coverage > 0, and every scanned asset owned. Remediate GAPs before expanding scope." -ForegroundColor Cyan
