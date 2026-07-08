<#
.SYNOPSIS
    DGINSIGHT-Discovery.ps1 — Insights & Data Quality readiness report (read-only).
.DESCRIPTION
    PURPOSE
        Reports whether a Microsoft Purview estate is ready for Data Estate Insights and Data Quality:
        the account endpoint is reachable, how many assets are catalogued, which governance domains and
        data products exist, whether the Data Quality surface responds (feature available for the
        tenant), and least-privilege role coverage. Read-only — it queries the Purview data-plane REST
        and changes nothing. Use it in Implementation Step 1 to record gaps against the Requirements
        checklist.
    HOW TO RUN
        powershell -ExecutionPolicy Bypass -File .\DGINSIGHT-Discovery.ps1 -PurviewAccount contoso-purview
        Requires the Az.Accounts module and Connect-AzAccount with at least a catalog/Data Governance
        reader role. No secrets are stored or requested.
    EXPECTED RESULTS
        A readiness summary: endpoint PASS/GAP, catalogued asset count, governance-domain and
        data-product counts, a Data-Quality-surface PASS/GAP (feature available?), and role coverage.
        GAP lines are what you remediate before authoring rules.
.NOTES
    Purview — Data Estate Insights & Data Quality. Read-only. API versions below are EXAMPLES — verify
    current Purview data-plane / Unified Catalog / Data Quality API versions and availability for your
    tenant; the experience is evolving and parts may be in preview.
#>
[CmdletBinding()]
param(
    [Parameter(Mandatory = $true)][string]$PurviewAccount,
    [string]$Endpoint = "https://$PurviewAccount.purview.azure.com"
)

Import-Module Az.Accounts -ErrorAction Stop
if (-not (Get-AzContext)) { Write-Host "Not signed in. Run Connect-AzAccount first." -ForegroundColor Yellow; return }
$token = (Get-AzAccessToken -ResourceUrl 'https://purview.azure.net').Token
$headers = @{ Authorization = "Bearer $token"; 'Content-Type' = 'application/json' }

function Invoke-Purview([string]$Path, [string]$Method = 'GET', $Body = $null) {
    $p = @{ Method = $Method; Uri = ("{0}{1}" -f $Endpoint, $Path); Headers = $headers; ErrorAction = 'Stop' }
    if ($Body) { $p.Body = ($Body | ConvertTo-Json -Depth 8) }
    Invoke-RestMethod @p
}

Write-Host "`n=== Purview — Insights & Data Quality readiness ===" -ForegroundColor Cyan
Write-Host ("Account          : {0}" -f $PurviewAccount)
Write-Host ("Endpoint         : {0}" -f $Endpoint)

# 1) Endpoint reachable + catalogued asset count (via catalog search)
$assetCount = 0
try {
    $res = Invoke-Purview '/catalog/api/search/query?api-version=2022-03-01-preview' 'POST' @{ keywords = '*'; limit = 1 }
    $assetCount = [int]($res.'@search.count')
    if (-not $assetCount) { $assetCount = @($res.value).Count }
    Write-Host ("Endpoint         : PASS (catalog reachable)") -ForegroundColor Green
    Write-Host ("Catalogued assets: {0}" -f $assetCount) -ForegroundColor ($(if ($assetCount -gt 0) { 'Green' } else { 'Yellow' }))
} catch {
    Write-Host ("Endpoint         : GAP — catalog not reachable ({0})" -f $_.Exception.Message) -ForegroundColor Yellow
}

# 2) Governance domains + data products (Unified Catalog) — availability varies, so probe gracefully
foreach ($probe in @(
    @{ Label = 'Governance domains'; Path = '/datagovernance/catalog/businessdomains?api-version=2024-02-01-preview' },
    @{ Label = 'Data products    '; Path = '/datagovernance/catalog/dataproducts?api-version=2024-02-01-preview' }
)) {
    try {
        $r = Invoke-Purview $probe.Path
        $c = @($r.value).Count
        Write-Host ("{0}: {1}" -f $probe.Label, $c) -ForegroundColor ($(if ($c -gt 0) { 'Green' } else { 'Yellow' }))
    } catch {
        Write-Host ("{0}: (unavailable — verify Unified Catalog API version/availability)" -f $probe.Label) -ForegroundColor DarkGray
    }
}

# 3) Data Quality surface responds? (feature availability / preview gate)
try {
    $null = Invoke-Purview '/datagovernance/quality/health?api-version=2024-02-01-preview'
    Write-Host ("Data Quality     : PASS (surface responds)") -ForegroundColor Green
} catch {
    $code = $_.Exception.Response.StatusCode.value__ 2>$null
    if ($code -eq 401 -or $code -eq 403) {
        Write-Host ("Data Quality     : reachable but access denied — assign the Data Quality steward role") -ForegroundColor Yellow
    } else {
        Write-Host ("Data Quality     : GAP — surface did not respond. Verify Data Quality is licensed/enabled (may be preview) for your tenant.") -ForegroundColor Yellow
    }
}

# 4) Role coverage hint (best-effort; role model + names are evolving — verify in portal)
try {
    $roles = Invoke-Purview '/catalog/api/atlas/v2/admin/metrics?api-version=2022-03-01-preview'
    Write-Host ("Roles/metrics    : reachable (verify least-privilege role assignments in the portal)") -ForegroundColor Green
} catch {
    Write-Host ("Roles/metrics    : verify role assignments in the Purview portal (Roles & scopes / governance domain roles)") -ForegroundColor DarkGray
}

Write-Host "`nGate: proceed only when the catalog is reachable with assets, at least one governance domain + data product exist, and the Data Quality surface responds (or is recorded as deferred where unavailable)." -ForegroundColor Cyan
Write-Host "Note: API versions above are EXAMPLES — verify current Purview / Unified Catalog / Data Quality API versions for your tenant." -ForegroundColor DarkGray
