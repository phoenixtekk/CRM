<#
.SYNOPSIS
    DGLINE-Validate.ps1 — read-only query of the Purview lineage graph for a named asset (no changes).
.DESCRIPTION
    PURPOSE
        Resolves an asset by qualified name and queries the Purview catalog Atlas LINEAGE endpoint,
        reporting the upstream and downstream related entities and the edge count for that asset — so you
        can confirm a lineage path renders (and is correct) after connecting a source or pushing custom
        lineage. Read-only. Makes no changes. Stores no secrets.
    HOW TO RUN
        powershell -File .\DGLINE-Validate.ps1 -Account <acct> -Asset '<qualified-name>' [-Depth 3]
        PowerShell 5.1+ or 7+. Requires Az.Accounts. Data curator/reader role on the in-scope collection.
    EXPECTED RESULTS
        The asset's GUID, plus tables of upstream and downstream related entities and the total edge count.
        PASS = the expected upstream source(s) and downstream consumer(s) are listed (verify correctness
        with a data owner — presence alone is not correctness).
.NOTES
    Purview — Data Lineage Implementation (DGLINE). Read-only. No secrets in code.
    Catalog search + Atlas lineage endpoints + api-version are cited as of authoring and evolving — verify in your tenant.
#>
[CmdletBinding()]
param(
    [Parameter(Mandatory)][string]$Account,
    [Parameter(Mandatory)][string]$Asset,
    [int]$Depth = 3,
    [string]$ResourceUrl   = 'https://purview.azure.net',
    [string]$CatalogApiVer = '2022-03-01-preview'
)

$ErrorActionPreference = 'Stop'
$endpoint = "https://$Account.purview.azure.com"
Write-Host ("=== DGLINE Validate — asset '{0}' on {1} ===" -f $Asset, $endpoint) -ForegroundColor Cyan

if (-not (Get-Module -ListAvailable -Name Az.Accounts)) {
    Install-Module Az.Accounts -Scope CurrentUser -Force -AllowClobber
}
Import-Module Az.Accounts -ErrorAction Stop
if (-not (Get-AzContext)) { Connect-AzAccount | Out-Null }
$token   = (Get-AzAccessToken -ResourceUrl $ResourceUrl).Token
$headers = @{ Authorization = "Bearer $token"; 'Content-Type' = 'application/json' }

# --- Resolve the asset GUID by qualified name (read-only search) ---
$searchUri = "$endpoint/catalog/api/search/query?api-version=$CatalogApiVer"
$searchBody = @{ keywords = $Asset; limit = 5 } | ConvertTo-Json
$hits = @()
try { $hits = @((Invoke-RestMethod -Method POST -Uri $searchUri -Headers $headers -Body $searchBody).value) }
catch { throw "Catalog search failed: $($_.Exception.Message). Verify the account, api-version, and your role." }

$match = $hits | Where-Object { $_.qualifiedName -eq $Asset } | Select-Object -First 1
if (-not $match) { $match = $hits | Select-Object -First 1 }
if (-not $match) { throw "No catalog asset matched '$Asset'. Confirm the asset is scanned and the qualified name is exact." }

$guid = $match.id
Write-Host ("Resolved asset -> GUID {0}  ({1})" -f $guid, $match.qualifiedName) -ForegroundColor Green

# --- Query the lineage graph (read-only) ---
$lineageUri = "$endpoint/catalog/api/atlas/v2/lineage/$guid?depth=$Depth&direction=BOTH&api-version=$CatalogApiVer"
try {
    $lin = Invoke-RestMethod -Method GET -Uri $lineageUri -Headers $headers
} catch {
    throw "Lineage query failed: $($_.Exception.Message). Verify the lineage endpoint/api-version in your tenant."
}

$relations = @($lin.relations)
$entities  = $lin.guidEntityMap
Write-Host ("Lineage edges (relations): {0}" -f $relations.Count) -ForegroundColor Cyan

function Resolve-Name([string]$g) {
    if ($entities -and $entities.$g) {
        $e = $entities.$g
        return ("{0} [{1}]" -f ($e.attributes.qualifiedName), $e.typeName)
    }
    return $g
}

$upstream   = @($relations | Where-Object { $_.toEntityId   -eq $guid } | ForEach-Object { Resolve-Name $_.fromEntityId })
$downstream = @($relations | Where-Object { $_.fromEntityId -eq $guid } | ForEach-Object { Resolve-Name $_.toEntityId })

Write-Host '--- Upstream (sources feeding this asset) ---' -ForegroundColor Cyan
if ($upstream.Count) { $upstream | ForEach-Object { Write-Host "  $_" } } else { Write-Host "  (none)" -ForegroundColor Yellow }
Write-Host '--- Downstream (consumers of this asset) ---' -ForegroundColor Cyan
if ($downstream.Count) { $downstream | ForEach-Object { Write-Host "  $_" } } else { Write-Host "  (none)" -ForegroundColor Yellow }

$pass = ($relations.Count -gt 0)
Write-Host ("RESULT: {0} — {1} lineage edge(s) found for the asset." -f $(if ($pass){'PASS'}else{'NO LINEAGE'}), $relations.Count) -ForegroundColor $(if ($pass){'Green'}else{'Yellow'})
Write-Host 'Validation complete (read-only). Confirm correctness (not just presence) with a data owner.' -ForegroundColor Green
