<#
.SYNOPSIS
    SENTSOAR-Report.ps1 — playbook and automation-rule run-history report.
.DESCRIPTION
    PURPOSE
        Summarizes recent Logic App run history for each playbook (succeeded/failed/running counts) as
        a cost and reliability signal, and flags any run of the response playbook so you can confirm no
        ENFORCED (non-simulate) containment ran during the pilot. Read-only — no changes.
    HOW TO RUN
        Connect-AzAccount first, then:
        powershell -ExecutionPolicy Bypass -File .\SENTSOAR-Report.ps1 -SoarResourceGroup rg-sentinel-soar -Days 7
        Requires modules: Az.Accounts, Az.LogicApp.
    EXPECTED RESULTS
        A per-playbook table of run counts by status over the window, and a highlighted list of any
        'Response - Contain - Pilot' runs for manual review. Use run counts as a Logic App cost proxy.
.NOTES
    Sentinel Solutions. Read-only.
#>
[CmdletBinding()]
param(
    [string]$SoarResourceGroup = 'rg-sentinel-soar',
    [int]$Days = 7,
    [string]$ResponsePlaybook = 'Response - Contain - Pilot'
)

Write-Host "=== SENTSOAR Report — playbook run history (last {0} days) ===" -f $Days -ForegroundColor Cyan
$since = (Get-Date).AddDays(-$Days)

$apps = Get-AzLogicApp -ResourceGroupName $SoarResourceGroup -ErrorAction SilentlyContinue
if (-not $apps) { Write-Host ("No Logic Apps found in {0}." -f $SoarResourceGroup) -ForegroundColor Yellow; return }

$totalRuns = 0
foreach ($app in $apps) {
    $runs = @()
    try { $runs = Get-AzLogicAppRunHistory -ResourceGroupName $SoarResourceGroup -Name $app.Name -ErrorAction Stop |
        Where-Object { $_.StartTime -gt $since } } catch {}
    $succeeded = @($runs | Where-Object { $_.Status -eq 'Succeeded' }).Count
    $failed    = @($runs | Where-Object { $_.Status -eq 'Failed' }).Count
    $other     = @($runs).Count - $succeeded - $failed
    $totalRuns += @($runs).Count
    $color = ($(if($failed -gt 0){'Yellow'}else{'Green'}))
    Write-Host ("  {0,-34} runs={1,-4} ok={2,-4} failed={3,-4} other={4}" -f $app.Name, @($runs).Count, $succeeded, $failed, $other) -ForegroundColor $color
}
Write-Host ("`nTotal playbook runs in window : {0}  (Logic App Consumption bills per action — use this as a cost proxy)" -f $totalRuns)

# Response playbook runs — surface for manual audit
Write-Host "`n--- Response playbook runs (audit) ---" -ForegroundColor Cyan
$resp = $apps | Where-Object { $_.Name -eq $ResponsePlaybook }
if ($resp) {
    $rr = @()
    try { $rr = Get-AzLogicAppRunHistory -ResourceGroupName $SoarResourceGroup -Name $ResponsePlaybook -ErrorAction Stop |
        Where-Object { $_.StartTime -gt $since } } catch {}
    if (@($rr).Count -eq 0) { Write-Host "  No response-playbook runs in the window." -ForegroundColor Green }
    else {
        Write-Host ("  {0} run(s) — REVIEW each in the incident comments to confirm it was SIMULATE only:" -f @($rr).Count) -ForegroundColor Yellow
        $rr | ForEach-Object { Write-Host ("    {0}  status={1}" -f $_.StartTime, $_.Status) }
        Write-Host "  During the pilot, every one of these should have made NO platform change (SimulateMode=true)." -ForegroundColor Yellow
    }
} else {
    Write-Host ("  '{0}' not found in {1}." -f $ResponsePlaybook, $SoarResourceGroup) -ForegroundColor Yellow
}
