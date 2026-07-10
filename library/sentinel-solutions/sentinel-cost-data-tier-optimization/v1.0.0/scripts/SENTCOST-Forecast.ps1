<#
.SYNOPSIS
    SENTCOST-Forecast.ps1 — monthly cost forecast: pay-as-you-go vs commitment tiers.
.DESCRIPTION
    PURPOSE
        Given your steady daily billable GB (from SENTCOST-Audit.ps1) and your region's per-GB rate,
        projects the monthly Analytics ingestion cost pay-as-you-go and compares it against a set of
        commitment (capacity) tiers you supply, recommending the cheapest option. Read-only — a model,
        not a live billing call. Verify all rates/thresholds in the Azure Pricing Calculator.
    HOW TO RUN
        powershell -ExecutionPolicy Bypass -File .\SENTCOST-Forecast.ps1 -DailyGB 180 -PerGBRate 2.30 -CommitmentTiers "100,200,300,400,500" -CommitmentDiscount 0.15
        -DailyGB      steady billable GB/day (from the audit's "Average billable GB/day").
        -PerGBRate    pay-as-you-go Analytics per-GB price for your region.
        -CommitmentTiers  candidate daily-GB commitment levels to compare.
        -CommitmentDiscount  approximate effective discount at commitment (verify per tier/region).
    EXPECTED RESULTS
        A table: pay-as-you-go monthly cost, each commitment tier's effective monthly cost, and the
        recommended (cheapest) option, plus current-vs-optimized framing. Model only — verify pricing.
.NOTES
    Sentinel Solutions. Read-only model. All pricing must be verified in the Azure Pricing Calculator.
#>
[CmdletBinding()]
param(
    [Parameter(Mandatory)] [double]$DailyGB,
    [Parameter(Mandatory)] [double]$PerGBRate,
    [string]$CommitmentTiers = '100,200,300,400,500',
    [double]$CommitmentDiscount = 0.15,
    [double]$OptimizedDailyGB = 0
)

Write-Host "=== SENTCOST Forecast — monthly cost model ===" -ForegroundColor Cyan
Write-Host "MODEL ONLY — verify per-GB rate, tier thresholds, and discounts in the Azure Pricing Calculator." -ForegroundColor Yellow

$daysInMonth = 30.4
$payg = $DailyGB * $daysInMonth * $PerGBRate
Write-Host ("`nSteady volume            : {0:N1} GB/day" -f $DailyGB)
Write-Host ("Pay-as-you-go            : {0:N2} /month  (at {1:N2}/GB)" -f $payg, $PerGBRate) -ForegroundColor Cyan

$tiers = @($CommitmentTiers -split '[,; ]+' | Where-Object { $_ } | ForEach-Object { [double]$_ })
$best = [pscustomobject]@{ Name = 'Pay-as-you-go'; Monthly = $payg }

Write-Host ("`n{0,-22} {1,14} {2,16}" -f 'Option', 'CommitGB/day', 'Est. $/month') -ForegroundColor Cyan
Write-Host ("-" * 56)
Write-Host ("{0,-22} {1,14} {2,16:N2}" -f 'Pay-as-you-go', '-', $payg)
foreach ($tier in ($tiers | Sort-Object)) {
    # Commitment bills the committed GB/day at a discounted effective rate; overage (if any) at payg rate.
    $effRate = $PerGBRate * (1 - $CommitmentDiscount)
    $committedMonthly = $tier * $daysInMonth * $effRate
    $overageGB = [math]::Max(0, $DailyGB - $tier)
    $overageMonthly = $overageGB * $daysInMonth * $PerGBRate
    $total = $committedMonthly + $overageMonthly
    $flag = if ($DailyGB -lt $tier) { '(over-committed)' } else { '' }
    $color = if ($total -lt $best.Monthly) { 'Green' } else { 'Gray' }
    Write-Host ("{0,-22} {1,14} {2,16:N2}  {3}" -f ("Commit {0}" -f $tier), $tier, $total, $flag) -ForegroundColor $color
    if ($total -lt $best.Monthly) { $best = [pscustomobject]@{ Name = ("Commit {0} GB/day" -f $tier); Monthly = $total } }
}

Write-Host ("`nRecommended option       : {0}  (~{1:N2}/month)" -f $best.Name, $best.Monthly) -ForegroundColor Green

if ($OptimizedDailyGB -gt 0) {
    $optPayg = $OptimizedDailyGB * $daysInMonth * $PerGBRate
    $saving = $payg - $optPayg
    Write-Host ("`nCurrent vs optimized (pay-as-you-go):") -ForegroundColor Cyan
    Write-Host ("  Current   : {0:N1} GB/day  -> {1:N2}/month" -f $DailyGB, $payg)
    Write-Host ("  Optimized : {0:N1} GB/day  -> {1:N2}/month" -f $OptimizedDailyGB, $optPayg)
    Write-Host ("  Monthly saving from tiering/filtering : {0:N2}  ({1:P0})" -f $saving, ($(if($payg -gt 0){$saving/$payg}else{0}))) -ForegroundColor Green
}

Write-Host "`nRecord this as 'Cost Forecast - Workspace - Pilot'. Do not commit a tier until the pilot proves the savings (Implementation Step 6)." -ForegroundColor Cyan
