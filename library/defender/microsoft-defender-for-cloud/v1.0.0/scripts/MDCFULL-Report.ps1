<#
.SYNOPSIS
    MDCFULL-Report.ps1 — read-only coverage, cost, and alert reporting for Microsoft Defender for Cloud,
    with a saveable baseline for drift tracking.
.DESCRIPTION
    PURPOSE
        Read-only reporting for the "Microsoft Defender for Cloud" (complete) solution:
          -Mode Coverage : which plans are On across the scoped subscriptions (coverage picture); with
                           -SaveBaseline records a baseline, and -BaselinePath compares against it.
          -Mode Cost     : counts protected resources per plan (the cost drivers) for an INDICATIVE
                           estimate — pricing is version-dependent; verify current pricing.
          -Mode Alerts   : the current Defender for Cloud security-alert inventory and any suppression
                           posture, so tuning can be reviewed.
        Makes no changes — reads state only.
    HOW TO RUN
        powershell -ExecutionPolicy Bypass -File .\MDCFULL-Report.ps1 -Mode Coverage -SaveBaseline
        powershell -ExecutionPolicy Bypass -File .\MDCFULL-Report.ps1 -Mode Coverage -BaselinePath .\mdcfull-baseline.json
        powershell -ExecutionPolicy Bypass -File .\MDCFULL-Report.ps1 -Mode Cost
        powershell -ExecutionPolicy Bypass -File .\MDCFULL-Report.ps1 -Mode Alerts
        Requires Az.Accounts, Az.Security, Az.Resources. Sign in first. Read-only.
    EXPECTED RESULTS
        A printed report and a JSON artifact (coverage baseline / cost drivers / alert inventory).
.NOTES
    White-label. Read-only. Cost figures are INDICATIVE only — verify current pricing/plan availability.
    Whether a cost is acceptable is finance's decision; this report only informs it.
#>
[CmdletBinding()]
param(
    [ValidateSet('Coverage','Cost','Alerts')]
    [string]$Mode = 'Coverage',
    [string[]]$SubscriptionId,
    [switch]$SaveBaseline,
    [string]$BaselinePath,
    [string]$OutputPath = ".\MDCFULL-report.json"
)

foreach ($m in 'Az.Accounts','Az.Security','Az.Resources') {
    if (-not (Get-Module -ListAvailable -Name $m)) { Install-Module Az -Scope CurrentUser -Force -AllowClobber; break }
}
Import-Module Az.Accounts -ErrorAction Stop; Import-Module Az.Security -ErrorAction Stop
if (-not (Get-AzContext)) { Connect-AzAccount | Out-Null }

$subs = if ($SubscriptionId) { Get-AzSubscription | Where-Object { $_.Id -in $SubscriptionId } } else { Get-AzSubscription }
$report = [ordered]@{ Timestamp = (Get-Date).ToString('s'); Mode = $Mode; Subscriptions = @() }

Write-Host ("`n=== Defender for Cloud — {0} report (read-only) ===" -f $Mode) -ForegroundColor Cyan

foreach ($s in $subs) {
    Set-AzContext -SubscriptionId $s.Id | Out-Null
    $entry = [ordered]@{ Name = $s.Name; Id = $s.Id }
    Write-Host ("`n-- {0} ({1}) --" -f $s.Name, $s.Id) -ForegroundColor Cyan

    if ($Mode -eq 'Coverage') {
        $pricings = @(); try { $pricings = Get-AzSecurityPricing -ErrorAction Stop } catch {}
        $on = @($pricings | Where-Object { $_.PricingTier -eq 'Standard' } | ForEach-Object { $_.Name })
        $entry.PlansOn = $on
        $entry.PlansOnCount = $on.Count
        Write-Host ("   plans On ({0}): {1}" -f $on.Count, ($on -join ', ')) -ForegroundColor Green
    }
    elseif ($Mode -eq 'Cost') {
        $pricings = @(); try { $pricings = Get-AzSecurityPricing -ErrorAction Stop } catch {}
        $on = @($pricings | Where-Object { $_.PricingTier -eq 'Standard' } | ForEach-Object { $_.Name })
        # Indicative protected-resource counts per common plan (drivers, not a price).
        $drivers = [ordered]@{}
        $map = @{ VirtualMachines='Microsoft.Compute/virtualMachines'; StorageAccounts='Microsoft.Storage/storageAccounts'; SqlServers='Microsoft.Sql/servers'; KeyVaults='Microsoft.KeyVault/vaults'; AppServices='Microsoft.Web/sites'; Containers='Microsoft.ContainerService/managedClusters' }
        foreach ($plan in $map.Keys) {
            $cnt = 0; try { $cnt = (Get-AzResource -ResourceType $map[$plan] -ErrorAction SilentlyContinue | Measure-Object).Count } catch {}
            $drivers[$plan] = @{ ProtectedResourceCount = $cnt; PlanOn = ($on -contains $plan) }
            Write-Host ("   {0,-18} resources={1,-4} planOn={2}" -f $plan, $cnt, ($on -contains $plan)) -ForegroundColor DarkGray
        }
        $entry.CostDrivers = $drivers
        Write-Host "   NOTE: counts are cost DRIVERS, not a price. Verify current per-resource pricing in your tenant." -ForegroundColor Yellow
    }
    elseif ($Mode -eq 'Alerts') {
        $alerts = @(); try { $alerts = Get-AzSecurityAlert -ErrorAction SilentlyContinue } catch {}
        $bySev = $alerts | Group-Object { $_.AlertSeverity } | ForEach-Object { "$($_.Name)=$($_.Count)" }
        $entry.AlertCount = $alerts.Count
        $entry.BySeverity = ($bySev -join ', ')
        Write-Host ("   alerts: {0}  ({1})" -f $alerts.Count, ($bySev -join ', ')) -ForegroundColor Green
        Write-Host "   Confirm 'MDC Alert Suppression - Benign FP - Prod' is scoped/documented (Environment settings -> Alert suppression rules)." -ForegroundColor DarkGray
    }

    $report.Subscriptions += $entry
}

if ($Mode -eq 'Coverage' -and $BaselinePath -and (Test-Path $BaselinePath)) {
    try {
        $base = Get-Content $BaselinePath -Raw | ConvertFrom-Json
        Write-Host "`n-- Coverage drift vs baseline --" -ForegroundColor Cyan
        foreach ($e in $report.Subscriptions) {
            $b = $base.Subscriptions | Where-Object { $_.Id -eq $e.Id } | Select-Object -First 1
            $delta = if ($b) { $e.PlansOnCount - $b.PlansOnCount } else { 'n/a' }
            Write-Host ("   {0}: plansOn now={1} baseline={2} delta={3}" -f $e.Name, $e.PlansOnCount, $(if ($b) { $b.PlansOnCount } else { 'n/a' }), $delta) -ForegroundColor $(if ($delta -is [int] -and $delta -ge 0) { 'Green' } else { 'Yellow' })
        }
    } catch { Write-Host ("   Baseline compare skipped: {0}" -f $_.Exception.Message) -ForegroundColor Yellow }
}

$out = if ($SaveBaseline -and $Mode -eq 'Coverage') { ".\mdcfull-baseline.json" } else { $OutputPath }
$report | ConvertTo-Json -Depth 8 | Set-Content -Path $out -Encoding UTF8
Write-Host ("`nReport complete (read-only). Artifact: {0}" -f $out) -ForegroundColor Green
