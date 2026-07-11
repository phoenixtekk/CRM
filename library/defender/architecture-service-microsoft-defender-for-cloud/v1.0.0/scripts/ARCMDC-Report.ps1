<#
.SYNOPSIS
    ARCMDC-Report.ps1 — coverage report (with drift vs a saved baseline) and an indicative cost
    model from discovered resource counts. Read-only.
.DESCRIPTION
    PURPOSE
        Read-only reporting for the "Architecture Service — Microsoft Defender for Cloud" solution.
        -Mode Coverage summarizes how many subscriptions have CSPM / workload plans enabled (and,
        with -SaveBaseline / -BaselinePath, the drift). -Mode Cost produces an INDICATIVE paid-plan
        cost estimate from resource counts (VMs, storage accounts, container nodes, SQL, Key Vaults,
        App Service) using per-unit rates you supply/confirm. Makes no changes.
    HOW TO RUN
        # Coverage baseline (Implementation Step 1) and later delta (Step 6):
        powershell -ExecutionPolicy Bypass -File .\ARCMDC-Report.ps1 -Mode Coverage -SaveBaseline
        powershell -ExecutionPolicy Bypass -File .\ARCMDC-Report.ps1 -Mode Coverage -BaselinePath .\arcmdc-baseline.json
        # Indicative cost model from discovered resource counts:
        powershell -ExecutionPolicy Bypass -File .\ARCMDC-Report.ps1 -Mode Cost
        Requires Az.Accounts, Az.Security, Az.ResourceGraph. Reader across the estate is enough.
    EXPECTED RESULTS
        Coverage: plan-coverage across subscriptions (+ drift vs baseline).
        Cost: an indicative monthly estimate per plan and total — NOT A QUOTE. Verify current
        pricing in your tenant; whether the cost is acceptable is finance's decision.
.NOTES
    White-label. Read-only. The per-unit rates below are PLACEHOLDERS — replace with current
    verified pricing for your region/tenant before using the estimate for a decision.
#>
[CmdletBinding()]
param(
    [ValidateSet('Coverage','Cost')] [string]$Mode = 'Coverage',
    [switch]$SaveBaseline,
    [string]$BaselinePath,
    [string]$OutFile = ".\arcmdc-baseline.json"
)

foreach ($m in 'Az.Accounts','Az.Security','Az.ResourceGraph') {
    if (-not (Get-Module -ListAvailable -Name $m)) { Install-Module Az -Scope CurrentUser -Force -AllowClobber; break }
}
Import-Module Az.Accounts -ErrorAction Stop
if (-not (Get-AzContext)) { Connect-AzAccount | Out-Null }

if ($Mode -eq 'Coverage') {
    Write-Host "`n=== ARCMDC coverage report (read-only) ===" -ForegroundColor Cyan
    Import-Module Az.Security -ErrorAction SilentlyContinue
    $subs = Get-AzSubscription -ErrorAction SilentlyContinue | Where-Object { $_.State -eq 'Enabled' }
    $total = $subs.Count; $withCspm = 0; $withWorkload = 0
    foreach ($s in $subs) {
        try {
            Set-AzContext -SubscriptionId $s.Id | Out-Null
            $p = Get-AzSecurityPricing -ErrorAction SilentlyContinue
            if (($p | Where-Object { $_.Name -eq 'CloudPosture' -and $_.PricingTier -eq 'Standard' })) { $withCspm++ }
            if (($p | Where-Object { $_.Name -ne 'CloudPosture' -and $_.PricingTier -eq 'Standard' })) { $withWorkload++ }
        } catch {}
    }
    $cspmPct = if ($total) { [math]::Round(100.0 * $withCspm / $total, 1) } else { 0 }
    $wlPct   = if ($total) { [math]::Round(100.0 * $withWorkload / $total, 1) } else { 0 }
    Write-Host ("   Subscriptions ................. {0}" -f $total)
    Write-Host ("   With Defender CSPM ............ {0} ({1}%)" -f $withCspm, $cspmPct)
    Write-Host ("   With >=1 workload plan ....... {0} ({1}%)" -f $withWorkload, $wlPct)
    $metrics = [ordered]@{ Timestamp = (Get-Date).ToString('s'); Subscriptions = $total; CspmCoveragePct = $cspmPct; WorkloadCoveragePct = $wlPct }

    if ($SaveBaseline) {
        $metrics | ConvertTo-Json -Depth 6 | Set-Content -Path $OutFile -Encoding UTF8
        Write-Host ("`nBaseline saved: {0}" -f $OutFile) -ForegroundColor Green
    } elseif ($BaselinePath -and (Test-Path $BaselinePath)) {
        $base = Get-Content $BaselinePath -Raw | ConvertFrom-Json
        Write-Host "`n-- Coverage delta vs baseline (higher is better) --" -ForegroundColor Cyan
        Write-Host ("   CSPM coverage %:     {0} -> {1}" -f $base.CspmCoveragePct, $cspmPct) -ForegroundColor $(if ($cspmPct -ge $base.CspmCoveragePct) { 'Green' } else { 'Yellow' })
        Write-Host ("   Workload coverage %: {0} -> {1}" -f $base.WorkloadCoveragePct, $wlPct) -ForegroundColor $(if ($wlPct -ge $base.WorkloadCoveragePct) { 'Green' } else { 'Yellow' })
    }
    return
}

# --- Cost mode: indicative estimate from resource counts. Rates are PLACEHOLDERS — verify current. ---
Write-Host "`n=== ARCMDC indicative cost model (read-only) ===" -ForegroundColor Cyan
Write-Host "NOTE: per-unit rates below are PLACEHOLDERS. Replace with current verified pricing before" -ForegroundColor Yellow
Write-Host "      using this for a decision. This is an estimate, NOT a quote." -ForegroundColor Yellow

# Placeholder monthly per-unit rates (USD) — VERIFY current pricing in your tenant/region.
$rates = @{
    'microsoft.compute/virtualmachines'          = @{ Plan = 'Defender for Servers'; Unit = 'server';    Rate = 15.00 }
    'microsoft.storage/storageaccounts'          = @{ Plan = 'Defender for Storage'; Unit = 'account';   Rate = 10.00 }
    'microsoft.containerservice/managedclusters' = @{ Plan = 'Defender for Containers'; Unit = 'cluster'; Rate = 0.00 }  # billed per vCore-hour — verify
    'microsoft.keyvault/vaults'                  = @{ Plan = 'Defender for Key Vault'; Unit = 'vault';    Rate = 0.00 }  # per-transaction — verify
    'microsoft.sql/servers'                      = @{ Plan = 'Defender for SQL'; Unit = 'server';         Rate = 15.00 }
    'microsoft.web/sites'                        = @{ Plan = 'Defender for App Service'; Unit = 'instance'; Rate = 0.02 }
}

try {
    Import-Module Az.ResourceGraph -ErrorAction Stop
    $counts = Search-AzGraph -Query "resources | summarize Count = count() by type" -First 200 -ErrorAction SilentlyContinue
    $total = 0.0
    Write-Host ""
    foreach ($t in $rates.Keys) {
        $c = ($counts | Where-Object { $_.type -eq $t }).Count
        if (-not $c) { $c = 0 }
        $line = $rates[$t]
        $est = [math]::Round($c * $line.Rate, 2)
        $total += $est
        Write-Host ("   {0,-26} {1,6} {2,-9} x `$${3,-7} => ~`$${4}/mo" -f $line.Plan, $c, $line.Unit, $line.Rate, $est)
    }
    Write-Host ("`n   INDICATIVE TOTAL: ~`$${0}/mo  (PLACEHOLDER rates — verify current pricing)" -f ([math]::Round($total, 2))) -ForegroundColor Cyan
    Write-Host "   Whether this cost is acceptable is the finance/budget owner's decision." -ForegroundColor DarkGray
} catch { Write-Host ("   Could not query Resource Graph: {0}" -f $_.Exception.Message) -ForegroundColor Yellow }
