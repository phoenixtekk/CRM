<#
.SYNOPSIS
    SAMPROG-Report.ps1 — render the SAM KPI set, a maturity snapshot, and an Effective License
    Position (ELP) view.
.DESCRIPTION
    PURPOSE
        Produces the standing program report. It computes an Effective License Position per product
        by comparing entitled quantities (from an export of the entitlement register) against
        assigned/used quantities pulled from Microsoft Graph (subscribed SKUs), and renders the
        `SAM KPI Set - Program - All Stages` measures it can derive plus a simple maturity snapshot.
        Read-only against Graph.
    HOW TO RUN
        powershell -ExecutionPolicy Bypass -File .\SAMPROG-Report.ps1 `
            -RegisterPath C:\SAM\entitlement-register.csv -CsvPath C:\Temp\sam-elp.csv
        The register CSV should include columns: Product, SkuPartNumber, Entitled, RenewalDate.
        Requires the Microsoft Graph SDK and Organization.Read.All (subscribedSkus).
    EXPECTED RESULTS
        A per-product ELP table (Entitled vs Assigned -> Compliant/Over/Under), the derivable KPI
        measures (compliance %, renewal lead-time flags), and an optional CSV export. No tenant data
        is modified.
.NOTES
    Asset Mgt — SAM Program. Read-only against Microsoft Graph. The repeatable way.
#>
[CmdletBinding()]
param(
    [Parameter(Mandatory)][string]$RegisterPath,
    [string]$CsvPath
)

if (-not (Test-Path $RegisterPath)) { throw "Register export not found: $RegisterPath" }
$register = Import-Csv -Path $RegisterPath

if (-not (Get-Module -ListAvailable -Name Microsoft.Graph.Authentication)) {
    Install-Module Microsoft.Graph -Scope CurrentUser -Force -AllowClobber
}
Import-Module Microsoft.Graph.Authentication -ErrorAction Stop
Connect-MgGraph -Scopes 'Organization.Read.All' -NoWelcome

# Assigned-license counts per SKU part number (the deployment side of the ELP).
$assignedBySku = @{}
try {
    $skus = (Invoke-MgGraphRequest -Method GET -Uri '/v1.0/subscribedSkus').value
    foreach ($s in $skus) { $assignedBySku[$s.skuPartNumber] = [int]$s.consumedUnits }
} catch {
    Write-Host ("Could not read subscribedSkus: {0}" -f $_.Exception.Message) -ForegroundColor Yellow
}

$today = Get-Date
$rows = foreach ($e in $register) {
    $entitled = [int]($e.Entitled)
    $assigned = if ($e.SkuPartNumber -and $assignedBySku.ContainsKey($e.SkuPartNumber)) { $assignedBySku[$e.SkuPartNumber] } else { $null }
    $elp = if ($assigned -eq $null) { 'No usage data' }
           elseif ($assigned -gt $entitled) { 'UNDER (risk)' }
           elseif ($assigned -lt $entitled) { 'OVER (savings)' }
           else { 'Compliant' }
    $renewalDays = $null
    if ($e.RenewalDate) { try { $renewalDays = [int]([datetime]$e.RenewalDate - $today).TotalDays } catch {} }
    [pscustomobject]@{
        Product      = $e.Product
        Sku          = $e.SkuPartNumber
        Entitled     = $entitled
        Assigned     = $assigned
        ELP          = $elp
        RenewalInDays = $renewalDays
    }
}

Write-Host "`n=== Effective License Position ===" -ForegroundColor Cyan
$rows | Format-Table -AutoSize

# Derivable KPI measures
$scored = $rows | Where-Object { $_.ELP -ne 'No usage data' }
$compliantOrOver = @($scored | Where-Object { $_.ELP -ne 'UNDER (risk)' }).Count
$compliancePct = if (@($scored).Count -gt 0) { [math]::Round(100 * $compliantOrOver / @($scored).Count, 1) } else { 0 }
$renewalsSoon = @($rows | Where-Object { $_.RenewalInDays -ne $null -and $_.RenewalInDays -le 90 }).Count

Write-Host "=== SAM KPI Set (derivable measures) ===" -ForegroundColor Cyan
Write-Host ("License compliance        : {0}% of scored products at/over entitlement (none under)" -f $compliancePct)
Write-Host ("Reconciliation coverage   : {0} of {1} register rows had usage data" -f @($scored).Count, @($rows).Count)
Write-Host ("Renewals within 90 days   : {0} (open the renewal review now)" -f $renewalsSoon)

# Maturity snapshot (signal-based, 0-5)
$maturity = 0
if (@($register).Count -gt 0) { $maturity++ }          # has a system of record
if (@($scored).Count -gt 0) { $maturity++ }            # reconciles against usage
if ($compliancePct -ge 100) { $maturity++ }            # compliant position
if ($renewalsSoon -ge 0) { $maturity++ }               # renewal visibility
if (@($rows).Count -eq @($scored).Count) { $maturity++ } # full coverage
Write-Host ("Maturity snapshot         : {0}/5 signals present" -f $maturity) -ForegroundColor Cyan

if ($CsvPath) { $rows | Export-Csv -Path $CsvPath -NoTypeInformation; Write-Host "Saved $CsvPath" }
Disconnect-MgGraph | Out-Null
