<#
.SYNOPSIS
    DGLINE-Discovery.ps1 — read-only inventory of Purview data sources, scans, and lineage capability (no changes).
.DESCRIPTION
    PURPOSE
        Enumerates the registered data sources in the Microsoft Purview Data Map, reports each source's
        last-scan status, and flags — per source — whether it produces lineage AUTOMATICALLY (Azure Data
        Factory, Synapse, Data Share, Power BI) or will need CUSTOM lineage pushed via the Atlas API.
        Read-only. Makes no changes. Writes the export "Data Lineage Source Inventory - DGLINE - Discovery".
    HOW TO RUN
        powershell -ExecutionPolicy Bypass -File .\DGLINE-Discovery.ps1 -Account <purview-account-name> -CsvPath .\LineageDiscovery.csv
        PowerShell 5.1+ or 7+. Requires Az.Accounts (Connect-AzAccount). Uses the Purview data-plane
        scanning API. Read data-plane role (Data source admin / Data reader) on the in-scope collections.
    EXPECTED RESULTS
        A table of sources with kind, last-scan status, and lineage capability, plus an optional CSV.
        PASS = every in-scope source is listed as "registered + scanned" with automatic/custom flagged.
.NOTES
    Purview — Data Lineage Implementation (DGLINE). Read-only. No secrets in code.
    Data lineage is a Data Map / Unified Catalog capability; source kinds, portal paths, and REST
    api-version values are evolving — verify against your tenant. api-version below is a placeholder.
#>
[CmdletBinding()]
param(
    [Parameter(Mandatory)][string]$Account,
    [string]$CsvPath,
    [string]$ResourceUrl  = 'https://purview.azure.net',
    [string]$ScanApiVer   = '2022-02-01-preview',
    [string]$ReportName   = 'Data Lineage Source Inventory - DGLINE - Discovery'
)

$ErrorActionPreference = 'Stop'
$endpoint = "https://$Account.purview.azure.com"
Write-Host ("=== {0} — {1} ===" -f $ReportName, $endpoint) -ForegroundColor Cyan

# Source kinds that report lineage automatically (indicative — verify against Microsoft's current connector docs).
$autoLineageKinds = @('AzureDataFactory','AdfAccount','AzureSynapseWorkspace','Synapse',
    'AzureSynapseAnalytics','PowerBI','AzureDataShare','DataShare')

if (-not (Get-Module -ListAvailable -Name Az.Accounts)) {
    Install-Module Az.Accounts -Scope CurrentUser -Force -AllowClobber
}
Import-Module Az.Accounts -ErrorAction Stop
if (-not (Get-AzContext)) { Connect-AzAccount | Out-Null }
$token   = (Get-AzAccessToken -ResourceUrl $ResourceUrl).Token
$headers = @{ Authorization = "Bearer $token" }

# --- Enumerate registered data sources (read-only) ---
$dsUri  = "$endpoint/scan/datasources?api-version=$ScanApiVer"
$sources = @()
try { $sources = @((Invoke-RestMethod -Method GET -Uri $dsUri -Headers $headers).value) }
catch { throw "Could not list data sources at $dsUri : $($_.Exception.Message). Verify the account, api-version, and your data-plane role." }

Write-Host ("Registered data sources: {0}" -f $sources.Count) -ForegroundColor Cyan

$rows = foreach ($ds in $sources) {
    $name = $ds.name
    $kind = $ds.kind
    $auto = @($autoLineageKinds | Where-Object { $kind -like "*$_*" }).Count -gt 0

    # Last-scan status (best-effort; scan sub-resource shape varies by kind — verify in your tenant).
    $lastScan = 'unknown'
    try {
        $scanUri  = "$endpoint/scan/datasources/$name/scans?api-version=$ScanApiVer"
        $scans    = @((Invoke-RestMethod -Method GET -Uri $scanUri -Headers $headers).value)
        if ($scans.Count -gt 0) {
            $runUri = "$endpoint/scan/datasources/$name/scans/$($scans[0].name)/runs?api-version=$ScanApiVer"
            $runs   = @((Invoke-RestMethod -Method GET -Uri $runUri -Headers $headers).value)
            if ($runs.Count -gt 0) { $lastScan = $runs[0].status }
            else { $lastScan = 'no runs' }
        } else { $lastScan = 'no scans' }
    } catch { $lastScan = 'not readable' }

    [pscustomobject]@{
        Source          = $name
        Kind            = $kind
        LastScan        = $lastScan
        LineageCapture  = $(if ($auto) { 'Automatic (connector)' } else { 'Custom lineage (Atlas API)' })
    }
}

$rows | Sort-Object LineageCapture, Source | Format-Table -AutoSize

if ($CsvPath) {
    $rows | Export-Csv -Path $CsvPath -NoTypeInformation
    Write-Host ("Saved '{0}' to {1}" -f $ReportName, $CsvPath) -ForegroundColor Green
}
Write-Host 'Discovery complete (read-only). Sources flagged Custom need lineage pushed via DGLINE-Configure.ps1.' -ForegroundColor Green
