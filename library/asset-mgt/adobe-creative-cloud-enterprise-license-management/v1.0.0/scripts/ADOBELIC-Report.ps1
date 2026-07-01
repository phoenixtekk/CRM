<#
.SYNOPSIS
    ADOBELIC-Report.ps1 — Adobe seat-and-cost summary per product profile.
.DESCRIPTION
    PURPOSE
        Summarizes assigned versus active seats per product profile and estimates the cost of idle and
        over-provisioned seats, using the seat inventory, the right-sizing register, and the
        product-profile map (which carries per-seat cost). This is the business case for reclamation.
        Read-only — it never changes an assignment.
    HOW TO RUN
        powershell -ExecutionPolicy Bypass -File .\ADOBELIC-Report.ps1 `
            -InventoryPath .\Seat-Inventory-Pilot-Assess.csv `
            -RegisterPath  .\Right-Sizing-Register-Pilot-Validate.csv `
            -ProfileMapPath .\Product-Profile-Map.csv
    EXPECTED RESULTS
        A per-profile table (assigned, active, idle, over-provisioned, quota, est. recoverable cost)
        written to ADOBELIC-Seat-Cost-Report.csv, plus a console summary.
.NOTES
    White-label SAM tooling. Read-only.
    Adobe specifics: per-seat cost comes from your entitlement record / product-profile map, not Adobe.
#>
[CmdletBinding()]
param(
    [Parameter(Mandatory)][string]$InventoryPath,
    [Parameter(Mandatory)][string]$RegisterPath,
    [string]$ProfileMapPath,
    [string]$OutPath = ".\ADOBELIC-Seat-Cost-Report.csv"
)

if (-not (Test-Path $InventoryPath)) { throw "Inventory not found: $InventoryPath" }
if (-not (Test-Path $RegisterPath))  { throw "Register not found: $RegisterPath" }
$inv = Import-Csv -Path $InventoryPath
$reg = Import-Csv -Path $RegisterPath

# Product-Profile Map carries quota and per-seat cost. Columns: ProductProfile, Quota, SeatCost.
$map = @{}
if ($ProfileMapPath -and (Test-Path $ProfileMapPath)) {
    foreach ($m in Import-Csv -Path $ProfileMapPath) { if ($m.ProductProfile) { $map[$m.ProductProfile] = $m } }
} else {
    Write-Host "No product-profile map supplied — cost columns will be blank (supply -ProfileMapPath for cost)." -ForegroundColor Yellow
}

$report = foreach ($g in ($inv | Group-Object ProductProfile)) {
    $profile = $g.Name
    $assigned = $g.Count
    $rowsForProfile = $reg | Where-Object { $_.ProductProfile -eq $profile }
    $idle  = ($rowsForProfile | Where-Object { $_.RecommendedAction -eq 'reclaim' }).Count
    $over  = ($rowsForProfile | Where-Object { $_.RecommendedAction -eq 'downsize' }).Count
    $active = $assigned - $idle - $over
    $seatCost = 0; $quota = ''
    if ($map.ContainsKey($profile)) {
        $quota = $map[$profile].Quota
        [decimal]::TryParse(($map[$profile].SeatCost -replace '[^\d.]',''), [ref]$seatCost) | Out-Null
    }
    [pscustomobject]@{
        ProductProfile      = $profile
        Quota               = $quota
        Assigned            = $assigned
        Active              = $active
        Idle                = $idle
        OverProvisioned     = $over
        SeatCost            = $seatCost
        RecoverableCost     = [math]::Round($seatCost * ($idle + $over), 2)
    }
}

$report = $report | Sort-Object RecoverableCost -Descending
$report | Export-Csv -Path $OutPath -NoTypeInformation
Write-Host "=== Adobe seat-and-cost report ===" -ForegroundColor Cyan
$report | Format-Table ProductProfile, Quota, Assigned, Active, Idle, OverProvisioned, RecoverableCost -AutoSize
$total = ($report | Measure-Object RecoverableCost -Sum).Sum
Write-Host ("Estimated recoverable cost (idle + over-provisioned): {0}" -f $total) -ForegroundColor Green
Write-Host ("Report written to {0}" -f $OutPath) -ForegroundColor Green
