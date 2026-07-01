<#
.SYNOPSIS
    LICRPT-Report.ps1 — produce the license KPI set independently of Power BI.
.DESCRIPTION
    PURPOSE
        Builds the License KPI Set - Software Assets - v1 (deployment rate, active usage rate,
        cost-per-seat, and reharvesting savings) from Microsoft Graph subscribed-SKU data joined to an
        optional cost/renewal baseline, so you can verify the Power BI dashboard against an
        independent source. Read-only.
    HOW TO RUN
        powershell -ExecutionPolicy Bypass -File .\LICRPT-Report.ps1 -CostCsv C:\Temp\costs.csv -CsvPath C:\Temp\licrpt-kpis.csv
        Optional CostCsv columns: SkuPartNumber, AnnualUnitCost, RenewalDate.
        Requires the Microsoft Graph SDK and Organization.Read.All.
    EXPECTED RESULTS
        A per-SKU table of entitled, assigned, deployment rate, cost-per-seat, days-to-expiration, and
        reharvesting savings, with an optional CSV export for comparison against the dashboard.
.NOTES
    Software Asset Management — License Reporting. Read-only against Microsoft Graph.
#>
[CmdletBinding()] param(
    [string]$CostCsv,
    [string]$CsvPath
)

if (-not (Get-Module -ListAvailable -Name Microsoft.Graph.Authentication)) {
    Install-Module Microsoft.Graph -Scope CurrentUser -Force -AllowClobber
}
Import-Module Microsoft.Graph.Authentication -ErrorAction Stop
Connect-MgGraph -Scopes 'Organization.Read.All' -NoWelcome

$cost = @{}
if ($CostCsv -and (Test-Path $CostCsv)) {
    Import-Csv $CostCsv | ForEach-Object { $cost[$_.SkuPartNumber] = $_ }
}

$skus = (Invoke-MgGraphRequest -Method GET -Uri '/v1.0/subscribedSkus').value
$report = foreach ($s in $skus) {
    $entitled = [int]$s.prepaidUnits.enabled
    $assigned = [int]$s.consumedUnits          # assigned/deployed seats
    $deployRate = if ($entitled) { [math]::Round($assigned / $entitled, 3) } else { 0 }
    $c = $cost[$s.skuPartNumber]
    $unitCost = if ($c) { [double]$c.AnnualUnitCost } else { $null }
    $idle = [math]::Max(0, $entitled - $assigned)   # unassigned entitlements = reclaimable on renewal
    $savings = if ($unitCost) { [math]::Round($idle * $unitCost, 2) } else { $null }
    $dte = if ($c -and $c.RenewalDate) { (New-TimeSpan -Start (Get-Date) -End ([datetime]$c.RenewalDate)).Days } else { $null }
    [pscustomobject]@{
        SkuPartNumber   = $s.skuPartNumber
        Entitled        = $entitled
        Assigned        = $assigned
        DeploymentRate  = $deployRate
        AnnualUnitCost  = $unitCost
        DaysToExpiration= $dte
        UnassignedSeats = $idle
        ReharvestSavings= $savings
    }
}

Write-Host "`n=== License KPI Set - Software Assets - v1 ===" -ForegroundColor Cyan
$report | Sort-Object SkuPartNumber | Format-Table -AutoSize
$totalSavings = ($report | Where-Object { $_.ReharvestSavings } | Measure-Object ReharvestSavings -Sum).Sum
if ($totalSavings) { Write-Host ("Total reclaimable spend (unassigned x unit cost): {0:C}" -f $totalSavings) -ForegroundColor Green }
if ($CsvPath) { $report | Export-Csv -Path $CsvPath -NoTypeInformation; Write-Host "Saved $CsvPath" -ForegroundColor Green }
Write-Host "Note: 'Assigned' is license assignment; pair with usage activity for the active-usage KPI." -ForegroundColor DarkGray
Disconnect-MgGraph | Out-Null
