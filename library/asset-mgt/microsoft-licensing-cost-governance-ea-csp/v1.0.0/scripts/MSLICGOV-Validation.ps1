<#
.SYNOPSIS
    MSLICGOV-Validation.ps1 — forecast EA true-up exposure (assigned vs committed baseline).
.DESCRIPTION
    PURPOSE
        Reads the tenant's consumed (assigned) units per SKU via Microsoft Graph and compares each
        to the committed EA baseline you supply (from the agreement), producing the per-SKU true-up
        delta = assigned minus baseline. A positive delta is the forecast true-up quantity; a
        negative delta cannot be trued down mid-term (record it for renewal). Read-only.
    HOW TO RUN
        Provide a baseline CSV with columns: SkuPartNumber,Baseline,Channel
            powershell -ExecutionPolicy Bypass -File .\MSLICGOV-Validation.ps1 -BaselineCsv C:\Temp\baseline.csv
        Requires the Microsoft Graph PowerShell SDK and the Organization.Read.All scope.
        Baselines come from the EA agreement; CSP rows (Channel=CSP) are excluded from true-up.
    EXPECTED RESULTS
        A per-EA-SKU table: assigned, baseline, true-up delta. CSP SKUs reported as no-true-up.
        No tenant changes are made.
.NOTES
    Workplace Marketplace — Asset Mgt. Read-only against Microsoft Graph.
#>
[CmdletBinding()] param([Parameter(Mandatory)][string]$BaselineCsv)

if (-not (Test-Path $BaselineCsv)) { Write-Host "Baseline CSV not found: $BaselineCsv (columns: SkuPartNumber,Baseline,Channel)" -ForegroundColor Red; exit 2 }
$baselines = Import-Csv $BaselineCsv

if (-not (Get-Module -ListAvailable -Name Microsoft.Graph.Authentication)) {
    Install-Module Microsoft.Graph -Scope CurrentUser -Force -AllowClobber
}
Import-Module Microsoft.Graph.Authentication -ErrorAction Stop
Connect-MgGraph -Scopes 'Organization.Read.All' -NoWelcome

$skus = (Invoke-MgGraphRequest -Method GET -Uri '/v1.0/subscribedSkus').value
$assignedBy = @{}
foreach ($s in $skus) { $assignedBy[$s.skuPartNumber] = [int]$s.consumedUnits }

Write-Host "`n=== True-up exposure (EA) — assigned vs committed baseline ===" -ForegroundColor Cyan
$rows = foreach ($b in $baselines) {
    $assigned = if ($assignedBy.ContainsKey($b.SkuPartNumber)) { $assignedBy[$b.SkuPartNumber] } else { 0 }
    $channel  = if ($b.Channel) { $b.Channel } else { 'EA' }
    $baseline = [int]$b.Baseline
    $delta    = $assigned - $baseline
    [pscustomobject]@{
        SkuPartNumber = $b.SkuPartNumber
        Channel       = $channel
        Assigned      = $assigned
        Baseline      = $baseline
        TrueUpDelta   = if ($channel -eq 'CSP') { 'n/a (no true-up)' } else { $delta }
    }
}
$rows | Format-Table SkuPartNumber, Channel, Assigned, Baseline, TrueUpDelta -AutoSize

$eaExposure = ($rows | Where-Object { $_.Channel -ne 'CSP' -and $_.TrueUpDelta -gt 0 } | Measure-Object -Property TrueUpDelta -Sum).Sum
Write-Host ("Forecast EA true-up units (sum of positive deltas): {0}" -f ([int]$eaExposure)) -ForegroundColor Yellow
Write-Host "Negative deltas are NOT trued down mid-term — record them in the renewal decision log." -ForegroundColor DarkYellow
Write-Host "Confirm the true-up window and process with your agreement/partner before reporting." -ForegroundColor DarkYellow

Disconnect-MgGraph | Out-Null
