<#
.SYNOPSIS
    DGINSIGHT-Report.ps1 — Data Estate Insights + data-quality scoring report (read-only).
.DESCRIPTION
    PURPOSE
        Produces the estate's health-and-quality picture for a scope: from Data Estate Insights, the
        catalogued asset total, classification distribution, and ownership coverage %; from Data
        Quality, the per-rule and per-data-product quality scores vs threshold. Read-only — it queries
        the Purview data-plane REST and changes nothing. Use it to capture DGI-Insights-Baseline and to
        track the delta as the estate expands.
    HOW TO RUN
        powershell -ExecutionPolicy Bypass -File .\DGINSIGHT-Report.ps1 -PurviewAccount contoso-purview `
            -DataProduct DGI-DataProduct-Pilot
        Requires Az.Accounts + Connect-AzAccount with at least a catalog/Data Governance reader role.
    EXPECTED RESULTS
        An insights summary (assets, classified %, owned %) and, where Data Quality is available, a
        scores table (rule, dimension, score, threshold, PASS/BELOW). PASS/GAP flags map to the pass/fail
        gate. Where Data Quality is unavailable, the DQ section is reported as deferred, not failed.
.NOTES
    Purview — Data Estate Insights & Data Quality. Read-only. API versions below are EXAMPLES — verify
    current Purview / Unified Catalog / Data Quality API versions for your tenant (parts may be preview).
#>
[CmdletBinding()]
param(
    [Parameter(Mandatory = $true)][string]$PurviewAccount,
    [string]$DataProduct,
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

Write-Host "`n=== Data Estate Insights + Data Quality report ===" -ForegroundColor Cyan

# --- Data Estate Insights: assets, classification distribution, ownership coverage ---
$total = 0; $classified = 0; $owned = 0
try {
    $res = Invoke-Purview '/catalog/api/search/query?api-version=2022-03-01-preview' 'POST' @{ keywords = '*'; limit = 1000 }
    $rows = @($res.value)
    $total = $rows.Count
    $classified = @($rows | Where-Object { $_.classification -and @($_.classification).Count -gt 0 }).Count
    $owned = @($rows | Where-Object { $_.owner -or $_.experts -or $_.contact }).Count
} catch {
    Write-Host ("Insights         : catalog search unavailable ({0})" -f $_.Exception.Message) -ForegroundColor Yellow
}

if ($total -gt 0) {
    $cPct = [math]::Round(($classified / $total) * 100, 1)
    $oPct = [math]::Round(($owned / $total) * 100, 1)
    Write-Host ("`n[Insights] baseline: DGI-Insights-Baseline")
    Write-Host ("  Assets (scanned): {0}" -f $total)
    Write-Host ("  Classified      : {0} ({1}%)" -f $classified, $cPct) -ForegroundColor ($(if ($cPct -gt 0) { 'Green' } else { 'Yellow' }))
    Write-Host ("  With owner      : {0} ({1}%)" -f $owned, $oPct) -ForegroundColor ($(if ($oPct -gt 0) { 'Green' } else { 'Yellow' }))
    Write-Host ("  Unowned         : {0}" -f ($total - $owned)) -ForegroundColor ($(if (($total - $owned) -eq 0) { 'Green' } else { 'Yellow' }))
} else {
    Write-Host "`n[Insights] 0 assets returned — confirm the estate is scanned/catalogued or widen the search scope." -ForegroundColor Yellow
}

# --- Data Quality: per-rule / per-data-product scores vs threshold ---
if ($DataProduct) {
    Write-Host ("`n[Data Quality] scores for {0}" -f $DataProduct)
    try {
        # Example endpoint — verify the current Data Quality scores API for your tenant.
        $dq = Invoke-Purview ("/datagovernance/quality/dataproducts/{0}/scores?api-version=2024-02-01-preview" -f $DataProduct)
        $rules = @($dq.rules)
        if ($rules.Count -eq 0) {
            Write-Host "  No rule scores yet — author rules and run a scoring scan (DGINSIGHT-Configure-Quality.ps1)." -ForegroundColor Yellow
        } else {
            foreach ($r in $rules) {
                $score = $r.score; $thr = $r.threshold
                $flag = if ($null -ne $score -and $null -ne $thr -and $score -ge $thr) { 'PASS' } else { 'BELOW' }
                $col = if ($flag -eq 'PASS') { 'Green' } else { 'Yellow' }
                Write-Host ("  {0,-38} {1,-12} score={2,-6} threshold={3,-6} {4}" -f $r.name, $r.dimension, $score, $thr, $flag) -ForegroundColor $col
            }
            if ($null -ne $dq.overallScore) {
                Write-Host ("  ---> Data-product overall score: {0}" -f $dq.overallScore) -ForegroundColor Cyan
            }
        }
    } catch {
        Write-Host "  Data Quality scores unavailable — verify Data Quality is enabled/licensed for your tenant (may be preview). Recorded as DEFERRED." -ForegroundColor DarkGray
    }
} else {
    Write-Host "`n[Data Quality] pass -DataProduct DGI-DataProduct-Pilot to include quality scores." -ForegroundColor DarkGray
}

Write-Host "`nGate: pilot passes when the insights baseline is captured and (where Data Quality is available) the scan Succeeded with a per-rule and data-product score the owner has reviewed." -ForegroundColor Cyan
Write-Host "Note: API versions above are EXAMPLES — verify current Purview / Data Quality API versions for your tenant." -ForegroundColor DarkGray
