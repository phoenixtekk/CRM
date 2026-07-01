<#
.SYNOPSIS
    LICRPT-Validation.ps1 — reconcile reported license counts against the source (the reconciliation gate).
.DESCRIPTION
    PURPOSE
        Compares the entitlement (prepaid) and assigned (consumed) counts that Microsoft Graph reports
        for each subscribed SKU against a baseline export from your entitlement system of record, and
        reports the per-product variance versus an allowed tolerance. This is the gate that must pass
        before the Power BI dashboard is distributed broadly. Read-only.
    HOW TO RUN
        powershell -ExecutionPolicy Bypass -File .\LICRPT-Validation.ps1 -BaselineCsv C:\Temp\entitlements.csv -TolerancePct 2
        The baseline CSV must have columns: SkuPartNumber, Entitled, Assigned.
        Requires the Microsoft Graph SDK and Organization.Read.All.
    EXPECTED RESULTS
        A per-SKU table of source vs. Graph counts with variance %, and an overall PASS or REVIEW
        result against the tolerance. Exit code 0 = PASS, 1 = REVIEW.
.NOTES
    Software Asset Management — License Reporting. Read-only against Microsoft Graph.
#>
[CmdletBinding()] param(
    [Parameter(Mandatory)][string]$BaselineCsv,
    [double]$TolerancePct = 2
)

if (-not (Test-Path $BaselineCsv)) { Write-Host "Baseline CSV not found: $BaselineCsv" -ForegroundColor Red; exit 1 }
if (-not (Get-Module -ListAvailable -Name Microsoft.Graph.Authentication)) {
    Install-Module Microsoft.Graph -Scope CurrentUser -Force -AllowClobber
}
Import-Module Microsoft.Graph.Authentication -ErrorAction Stop
Connect-MgGraph -Scopes 'Organization.Read.All' -NoWelcome

$baseline = Import-Csv $BaselineCsv
$skus = (Invoke-MgGraphRequest -Method GET -Uri '/v1.0/subscribedSkus').value

$rows = foreach ($b in $baseline) {
    $g = $skus | Where-Object { $_.skuPartNumber -eq $b.SkuPartNumber } | Select-Object -First 1
    $gEnt = if ($g) { [int]$g.prepaidUnits.enabled } else { 0 }
    $gAsn = if ($g) { [int]$g.consumedUnits } else { 0 }
    $srcEnt = [int]$b.Entitled
    $var = if ($srcEnt -ne 0) { [math]::Round((($gEnt - $srcEnt) / $srcEnt) * 100, 2) } else { 0 }
    [pscustomobject]@{
        SkuPartNumber = $b.SkuPartNumber
        SourceEntitled = $srcEnt
        GraphEntitled  = $gEnt
        SourceAssigned = [int]$b.Assigned
        GraphAssigned  = $gAsn
        VariancePct    = $var
        Status         = if ([math]::Abs($var) -le $TolerancePct) { 'OK' } else { 'OVER TOLERANCE' }
    }
}

Write-Host "`n=== License reconciliation (tolerance +/- $TolerancePct%) ===" -ForegroundColor Cyan
$rows | Format-Table -AutoSize
$bad = @($rows | Where-Object Status -ne 'OK')
if ($bad.Count -eq 0) {
    Write-Host "`nResult: PASS — all SKUs within tolerance. Safe to distribute." -ForegroundColor Green
    Disconnect-MgGraph | Out-Null; exit 0
} else {
    Write-Host ("`nResult: REVIEW — {0} SKU(s) over tolerance. Do not distribute until reconciled." -f $bad.Count) -ForegroundColor Yellow
    Disconnect-MgGraph | Out-Null; exit 1
}
