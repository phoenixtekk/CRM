<#
.SYNOPSIS
    LICCOMP-Report.ps1 — produce the Effective License Position summary and the gap list.
.DESCRIPTION
    PURPOSE
        Reconciles the entitlement baseline against the deployment inventory and reports, per product
        line, the Effective License Position (entitled minus consumed) and the resulting gaps. Writes
        the gap list for the "Gap Register - <Publisher/Product> - Reconciled". Read-only — it derives
        a report from your inputs and changes nothing.
    HOW TO RUN
        powershell -ExecutionPolicy Bypass -File .\LICCOMP-Report.ps1 `
          -EntitlementCsv .\entitlements.csv -DeploymentCsv .\deployment.csv -CsvPath .\gap-register.csv
        Entitlement CSV columns: Product, Edition, Metric, Quantity, ProofRef
        Deployment  CSV columns: Product (one row per install/assignment/counted unit)
    EXPECTED RESULTS
        A per-product table (Entitled, Consumed, Position) and a gap CSV listing each shortfall
        (negative position) and surplus (positive position) for the gap register.
.NOTES
    Workplace Marketplace — Asset Mgt. Read-only. Generic CSV in / CSV out.
#>
[CmdletBinding()]
param(
    [Parameter(Mandatory)] [string]$EntitlementCsv,
    [Parameter(Mandatory)] [string]$DeploymentCsv,
    [string]$CsvPath
)

if (-not (Test-Path $EntitlementCsv)) { throw "Entitlement CSV not found: $EntitlementCsv" }
if (-not (Test-Path $DeploymentCsv))  { throw "Deployment CSV not found: $DeploymentCsv" }

$ent = Import-Csv -Path $EntitlementCsv
$dep = Import-Csv -Path $DeploymentCsv

function Key([string]$s){ ($s).Trim().ToLower() }

# Entitled quantity per normalized product.
$entitled = @{}
foreach ($e in $ent) {
    $k = Key $e.Product
    $q = 0; [void][int]::TryParse(($e.Quantity), [ref]$q)
    if ($entitled.ContainsKey($k)) { $entitled[$k] += $q } else { $entitled[$k] = $q }
}
# Consumed count per normalized product (one row = one counted unit).
$consumed = @{}
foreach ($d in $dep) {
    $k = Key $d.Product
    if ($consumed.ContainsKey($k)) { $consumed[$k] += 1 } else { $consumed[$k] = 1 }
}

$allKeys = @($entitled.Keys + $consumed.Keys | Sort-Object -Unique)
$report = foreach ($k in $allKeys) {
    $en = if ($entitled.ContainsKey($k)) { $entitled[$k] } else { 0 }
    $co = if ($consumed.ContainsKey($k)) { $consumed[$k] } else { 0 }
    $pos = $en - $co
    [pscustomobject]@{
        Product  = $k
        Entitled = $en
        Consumed = $co
        Position = $pos
        Status   = if ($pos -lt 0) { 'SHORTFALL' } elseif ($pos -gt 0) { 'Surplus' } else { 'Balanced' }
    }
}

Write-Host "`n=== Effective License Position ===" -ForegroundColor Cyan
$report | Sort-Object Position | Format-Table -AutoSize
$short = @($report | Where-Object { $_.Status -eq 'SHORTFALL' })
Write-Host ("Shortfalls (exposure): {0}   Surpluses (reharvest): {1}" -f $short.Count, @($report | Where-Object { $_.Status -eq 'Surplus' }).Count) -ForegroundColor Cyan
if ($short.Count -gt 0) { Write-Host "ATTENTION: shortfalls found — record in the Gap Register and assign owners/actions." -ForegroundColor Yellow }

if ($CsvPath) {
    $gaps = $report | Where-Object { $_.Status -ne 'Balanced' }
    $gaps | Export-Csv -Path $CsvPath -NoTypeInformation
    Write-Host "Saved gap list: $CsvPath" -ForegroundColor Green
}
