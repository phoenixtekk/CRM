<#
.SYNOPSIS
    SWRENEW-Report.ps1 — build the renewal calendar (with tiered lead-time alerts) and a cost rollup.
.DESCRIPTION
    PURPOSE
        Produces the Renewal Calendar (date-ordered, with each upcoming renewal placed in a lead-time
        alert tier: T-120 / T-90 / T-60 / T-30) and a cost rollup (annual cost by vendor and total),
        from the Contract & Entitlement Repository CSV. OEM bundles are collapsed to one row per
        BundleId so a bundle is a single renewal decision. Read-only: it never edits the repository.
    HOW TO RUN
        powershell -ExecutionPolicy Bypass -File .\SWRENEW-Report.ps1 -CsvPath .\repository.csv -OutDir .\reports
    EXPECTED RESULTS
        Two CSVs in -OutDir: renewal-calendar.csv (sorted by RenewalDate, with an AlertTier column)
        and cost-rollup.csv (annual cost by vendor + grand total). A console summary of due-soon
        counts per tier and the grand total cost.
.NOTES
    Software Asset Management — repeatable renewal/contract process. Read-only.
#>
[CmdletBinding()] param(
    [Parameter(Mandatory)][string]$CsvPath,
    [string]$OutDir = '.\reports'
)

Write-Host "=== Software Renewals — Calendar & Cost Report ===" -ForegroundColor Cyan
if (-not (Test-Path $CsvPath)) { Write-Host "Repository not found: $CsvPath" -ForegroundColor Red; exit 1 }
if (-not (Test-Path $OutDir)) { New-Item -ItemType Directory -Path $OutDir -Force | Out-Null }

$today = Get-Date
$rows = @(Import-Csv $CsvPath)

function Get-Tier([int]$days) {
    if ($days -lt 0)   { return 'PAST-DUE' }
    if ($days -le 30)  { return 'T-30' }
    if ($days -le 60)  { return 'T-60' }
    if ($days -le 90)  { return 'T-90' }
    if ($days -le 120) { return 'T-120' }
    return 'beyond-120'
}

# Collapse bundles: one calendar row per BundleId (use the bundle's earliest renewal as the anchor)
$calendar = @()
$bundled  = $rows | Where-Object { $_.BundleId }
$single   = $rows | Where-Object { -not $_.BundleId }

foreach ($g in ($bundled | Group-Object BundleId)) {
    $anchor = $g.Group | Where-Object { $_.RenewalDate } | Sort-Object { [datetime]$_.RenewalDate } | Select-Object -First 1
    if (-not $anchor) { continue }
    $sum = ($g.Group | Measure-Object -Property AnnualCost -Sum).Sum
    $calendar += [pscustomobject]@{
        Vendor=$anchor.Vendor; Product=("BUNDLE:{0} ({1} items)" -f $g.Name, $g.Count)
        Quantity=''; AnnualCost=$sum; RenewalDate=$anchor.RenewalDate
        NoticePeriodDays=$anchor.NoticePeriodDays; AutoRenew=$anchor.AutoRenew; Owner=$anchor.Owner
    }
}
foreach ($r in $single) {
    if (-not $r.RenewalDate) { continue }
    $calendar += [pscustomobject]@{
        Vendor=$r.Vendor; Product=$r.Product; Quantity=$r.Quantity; AnnualCost=$r.AnnualCost
        RenewalDate=$r.RenewalDate; NoticePeriodDays=$r.NoticePeriodDays; AutoRenew=$r.AutoRenew; Owner=$r.Owner
    }
}

$calendar = $calendar | ForEach-Object {
    $days = [int]([datetime]$_.RenewalDate - $today).TotalDays
    $_ | Add-Member -NotePropertyName DaysToRenewal -NotePropertyValue $days -PassThru |
         Add-Member -NotePropertyName AlertTier -NotePropertyValue (Get-Tier $days) -PassThru
} | Sort-Object { [datetime]$_.RenewalDate }

$calPath = Join-Path $OutDir 'renewal-calendar.csv'
$calendar | Select-Object Vendor,Product,Quantity,AnnualCost,RenewalDate,DaysToRenewal,AlertTier,NoticePeriodDays,AutoRenew,Owner |
    Export-Csv -Path $calPath -NoTypeInformation

# Cost rollup by vendor + grand total
$rollup = $rows | Group-Object Vendor | ForEach-Object {
    [pscustomobject]@{ Vendor=$_.Name; Contracts=$_.Count; AnnualCost=([math]::Round((($_.Group | Measure-Object AnnualCost -Sum).Sum),2)) }
} | Sort-Object AnnualCost -Descending
$total = [math]::Round((($rows | Measure-Object AnnualCost -Sum).Sum),2)
$rollupPath = Join-Path $OutDir 'cost-rollup.csv'
$rollup | Export-Csv -Path $rollupPath -NoTypeInformation

# Console summary
Write-Host "Due-soon by alert tier:" -ForegroundColor Cyan
$calendar | Where-Object { $_.AlertTier -in 'PAST-DUE','T-30','T-60','T-90','T-120' } |
    Group-Object AlertTier | Select-Object @{n='Tier';e={$_.Name}}, Count | Format-Table -AutoSize
Write-Host ("Grand total annual cost: {0}" -f $total) -ForegroundColor Cyan
Write-Host ("Saved: {0}" -f $calPath) -ForegroundColor Green
Write-Host ("Saved: {0}" -f $rollupPath) -ForegroundColor Green
