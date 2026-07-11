<#
.SYNOPSIS
    TBMMDC-Coverage.ps1 — read-only agent / agentless coverage analysis for a stalled Defender for
    Cloud rollout.
.DESCRIPTION
    PURPOSE
        A "plan is On but nothing is protected" blocker is a coverage gap. This script reports, for the
        affected subscriptions, the VM/compute inventory and whether machines are instrumented — the
        Log Analytics / Azure Monitor agent extension and the Defender extension — separating an
        AGENT-PROVISIONING gap (auto-provisioning off / workspace unreachable) from an AGENTLESS gap.
        Makes NO changes.
    HOW TO RUN
        Connect-AzAccount ; then:
        powershell -ExecutionPolicy Bypass -File .\TBMMDC-Coverage.ps1 -SubscriptionIds "sub1,sub2"
        Requires Az.Accounts, Az.Compute, Az.Security. Read-only (Reader).
    EXPECTED RESULTS
        A per-subscription coverage summary (machines total vs instrumented) and a flagged gap list,
        written to MDC-coverage.json. The gap type points at the matching fix.
.NOTES
    White-label. Read-only — enumerates resources/extensions only; changes nothing.
    Extension names/agents evolve (AMA/MMA, agentless) — verify the current coverage model in your tenant.
#>
[CmdletBinding()]
param(
    [string]$SubscriptionIds = "",
    [string]$OutputPath = ".\MDC-coverage.json"
)

foreach ($m in 'Az.Accounts','Az.Compute','Az.Security') {
    if (-not (Get-Module -ListAvailable -Name $m)) { Install-Module $m -Scope CurrentUser -Force -AllowClobber }
}
Import-Module Az.Accounts -ErrorAction Stop
if (-not (Get-AzContext)) { Connect-AzAccount | Out-Null }
$subs = if ($SubscriptionIds) { $SubscriptionIds.Split(',') | ForEach-Object { $_.Trim() } } else { @((Get-AzContext).Subscription.Id) }

Write-Host "`n=== TBMMDC — agent / agentless coverage analysis (read-only) ===" -ForegroundColor Cyan
$result = [ordered]@{ Timestamp=(Get-Date).ToString('s'); Subscriptions=@() }

# Agent extension name hints (verify current names for your tenant).
$agentHints = 'MicrosoftMonitoringAgent|AzureMonitorWindowsAgent|AzureMonitorLinuxAgent|OmsAgentForLinux'
$defenderHints = 'MDE\.Windows|MDE\.Linux|AzureSecurityWindowsAgent|AzureSecurityLinuxAgent'

foreach ($sid in $subs) {
    Write-Host ("`n### Subscription: {0}" -f $sid) -ForegroundColor Cyan
    try { Set-AzContext -Subscription $sid -ErrorAction Stop | Out-Null } catch { Write-Host ("   Cannot set context: {0}" -f $_.Exception.Message) -ForegroundColor Yellow; continue }

    $vms = @()
    try { $vms = Get-AzVM -Status -ErrorAction Stop } catch { Write-Host ("   Could not enumerate VMs: {0}" -f $_.Exception.Message) -ForegroundColor Yellow }
    $total = ($vms | Measure-Object).Count
    $withAgent = 0; $withDefender = 0; $gaps = @()

    foreach ($vm in $vms) {
        $exts = @()
        try { $exts = (Get-AzVMExtension -ResourceGroupName $vm.ResourceGroupName -VMName $vm.Name -ErrorAction SilentlyContinue) } catch { }
        $names = ($exts | ForEach-Object { $_.Name + ' ' + $_.Publisher + ' ' + $_.ExtensionType }) -join ' '
        $hasAgent = $names -match $agentHints
        $hasDef   = $names -match $defenderHints
        if ($hasAgent) { $withAgent++ }
        if ($hasDef)   { $withDefender++ }
        if (-not $hasAgent -and -not $hasDef) { $gaps += $vm.Name }
    }

    Write-Host ("   VMs: {0}  with monitoring agent: {1}  with Defender ext: {2}" -f $total, $withAgent, $withDefender)
    if ($gaps.Count -gt 0) {
        Write-Host ("   COVERAGE GAP — {0} VM(s) with no agent AND no Defender extension:" -f $gaps.Count) -ForegroundColor Yellow
        $gaps | Select-Object -First 15 | ForEach-Object { Write-Host ("     - {0}" -f $_) -ForegroundColor Yellow }
        Write-Host "   If auto-provisioning is off / workspace unreachable => agent-provisioning gap." -ForegroundColor DarkGray
        Write-Host "   If auto-provisioning is on but still gapped => consider agentless scanning enablement." -ForegroundColor DarkGray
    } else { Write-Host "   No agent+Defender coverage gaps detected on enumerated VMs." -ForegroundColor Green }

    $result.Subscriptions += [ordered]@{ SubscriptionId=$sid; VMTotal=$total; WithAgent=$withAgent; WithDefenderExt=$withDefender; GapVMs=$gaps }
}

$result | ConvertTo-Json -Depth 8 | Set-Content -Path $OutputPath -Encoding UTF8
Write-Host ("`nCoverage snapshot: {0}" -f $OutputPath) -ForegroundColor Green
Write-Host "Note: agentless scanning also covers machines without an in-guest agent — confirm in plan settings." -ForegroundColor DarkGray
