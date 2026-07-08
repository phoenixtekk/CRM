<#
.SYNOPSIS
    DGINSIGHT-Scope-Health.ps1 — Estate-health coverage helper for a governance domain (read-only).
.DESCRIPTION
    PURPOSE
        Reports estate-health coverage gaps for a governance domain, so a governed estate does not
        degrade quietly: data products without a named owner, critical data elements without a
        data-quality rule, and stale scans (last scored beyond a staleness window). Read-only — it
        queries the Purview data-plane REST and changes nothing. Reports the SAME coverage checks whether
        or not the tenant's Health management / health-controls surface is enabled, so it works even
        where that feature is preview/unavailable.
    HOW TO RUN
        powershell -ExecutionPolicy Bypass -File .\DGINSIGHT-Scope-Health.ps1 `
            -PurviewAccount contoso-purview -Domain DGI-Domain-Pilot -StaleDays 30
        Requires Az.Accounts + Connect-AzAccount with at least a catalog/Data Governance reader role.
    EXPECTED RESULTS
        A coverage report per data product in the domain: owner PASS/GAP, CDEs-with-rules count,
        last-score age vs -StaleDays, and a rolled-up gap count you can record against DGI-Health-Controls-Pilot.
.NOTES
    Purview — Data Estate Insights & Data Quality. Read-only. API versions below are EXAMPLES — verify
    current Unified Catalog / Data Quality API versions for your tenant (parts may be preview).
#>
[CmdletBinding()]
param(
    [Parameter(Mandatory = $true)][string]$PurviewAccount,
    [Parameter(Mandatory = $true)][string]$Domain,
    [int]$StaleDays = 30,
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

Write-Host "`n=== Estate-health coverage — domain: $Domain ===" -ForegroundColor Cyan
Write-Host ("Staleness window : {0} days" -f $StaleDays)

$gapCount = 0; $dpCount = 0
try {
    # Example endpoint — verify the current Unified Catalog data-products API for your tenant.
    $dps = @((Invoke-Purview ("/datagovernance/catalog/dataproducts?domainId={0}&api-version=2024-02-01-preview" -f $Domain)).value)
    if ($dps.Count -eq 0) { Write-Host "No data products found in this domain — verify the domain id and your reader role." -ForegroundColor Yellow; return }

    foreach ($dp in $dps) {
        $dpCount++
        $name = if ($dp.name) { $dp.name } else { $dp.id }
        Write-Host ("`nData product     : {0}" -f $name)

        # 1) Ownership
        $hasOwner = [bool]($dp.owners -or $dp.contacts -or $dp.owner)
        if ($hasOwner) { Write-Host "  Owner          : PASS" -ForegroundColor Green }
        else { Write-Host "  Owner          : GAP — no named owner" -ForegroundColor Yellow; $gapCount++ }

        # 2) CDEs with a data-quality rule
        $cdeWithRules = 0; $cdeTotal = 0
        try {
            $rs = Invoke-Purview ("/datagovernance/quality/dataproducts/{0}/rulesets?api-version=2024-02-01-preview" -f $dp.id)
            $rules = @($rs.value.rules)
            $cdeWithRules = @($rules | Select-Object -ExpandProperty targetCde -ErrorAction SilentlyContinue | Sort-Object -Unique).Count
            $cdeTotal = @($dp.criticalDataElements).Count
        } catch { Write-Host "  DQ rules       : (Data Quality surface unavailable — verify licensing/preview)" -ForegroundColor DarkGray }
        if ($cdeTotal -gt 0) {
            $col = if ($cdeWithRules -ge $cdeTotal) { 'Green' } else { 'Yellow' }
            Write-Host ("  CDEs with rule : {0}/{1}" -f $cdeWithRules, $cdeTotal) -ForegroundColor $col
            if ($cdeWithRules -lt $cdeTotal) { $gapCount++ }
        } else {
            Write-Host ("  CDEs with rule : {0} rule(s) present (CDE list not returned)" -f $cdeWithRules) -ForegroundColor DarkGray
        }

        # 3) Stale scan (last score age)
        try {
            $sc = Invoke-Purview ("/datagovernance/quality/dataproducts/{0}/scores?api-version=2024-02-01-preview" -f $dp.id)
            if ($sc.lastRunTime) {
                $age = (New-TimeSpan -Start ([datetime]$sc.lastRunTime) -End (Get-Date)).Days
                if ($age -le $StaleDays) { Write-Host ("  Last score age : {0}d PASS" -f $age) -ForegroundColor Green }
                else { Write-Host ("  Last score age : {0}d GAP — beyond {1}d window" -f $age, $StaleDays) -ForegroundColor Yellow; $gapCount++ }
            } else {
                Write-Host "  Last score age : GAP — never scored" -ForegroundColor Yellow; $gapCount++
            }
        } catch { Write-Host "  Last score age : (unavailable — verify Data Quality availability)" -ForegroundColor DarkGray }
    }
} catch {
    Write-Host ("Could not enumerate data products: {0}" -f $_.Exception.Message) -ForegroundColor Yellow
    Write-Host "Verify the Unified Catalog API version/availability for your tenant and your reader role." -ForegroundColor DarkGray
    return
}

Write-Host ("`n=== Coverage summary: {0} data product(s), {1} gap(s) against DGI-Health-Controls-Pilot ===" -f $dpCount, $gapCount) -ForegroundColor ($(if ($gapCount -eq 0) { 'Green' } else { 'Yellow' }))
Write-Host "Health controls checked: every data product has an owner; every CDE has a rule; no stale scan. Remediation of gaps is the data owner's action." -ForegroundColor Cyan
Write-Host "Note: API versions above are EXAMPLES — verify current Purview / Data Quality API versions for your tenant." -ForegroundColor DarkGray
