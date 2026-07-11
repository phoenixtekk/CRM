<#
.SYNOPSIS
    MDCWP-Report.ps1 — alert inventory + protected-resource (cost) report for Defender for Cloud
    workload plans, with baseline drift.
.DESCRIPTION
    PURPOSE
        Read-only reporting for the "Microsoft Defender for Cloud — Workload Protection Plans"
        solution. Summarizes the current Defender for Cloud security alerts and suppression posture
        (-Section Alerts) and the protected-resource counts per enabled plan as a cost proxy
        (-Section Cost). With -SaveBaseline, records a baseline so later runs show drift.
    HOW TO RUN
        powershell -ExecutionPolicy Bypass -File .\MDCWP-Report.ps1 -SubscriptionId <sub> -Section All -SaveBaseline
        -Section accepts: Alerts | Cost | All (default All).
        Requires Az.Accounts, Az.Security, Az.Resources. Sign in with Connect-AzAccount first.
    EXPECTED RESULTS
        An alert summary by severity, the enabled plans and rough protected-resource counts (cost
        proxy), and drift versus the saved baseline. Understand cost BEFORE expanding scope.
.NOTES
    White-label. Read-only. Cost here is a resource-count proxy — verify actual pricing in the
    Azure pricing calculator / Cost Management. Response actions stay approval-gated.
#>
[CmdletBinding()]
param(
    [Parameter(Mandatory)] [string]$SubscriptionId,
    [ValidateSet('Alerts','Cost','All')] [string]$Section = 'All',
    [switch]$SaveBaseline,
    [string]$BaselinePath = ".\MDCWP-baseline.json"
)

Import-Module Az.Accounts -ErrorAction Stop
if (-not (Get-AzContext)) { Connect-AzAccount | Out-Null }
Set-AzContext -SubscriptionId $SubscriptionId | Out-Null
Import-Module Az.Security -ErrorAction Stop
Write-Host "`n=== Defender for Cloud — workload report ($Section) on $SubscriptionId ===" -ForegroundColor Cyan
$alertCount = $null; $protectedCount = $null

if ($Section -in 'Alerts','All') {
    Write-Host "`n-- Security alerts by severity --" -ForegroundColor Cyan
    try {
        $alerts = Get-AzSecurityAlert -ErrorAction Stop
        $alertCount = ($alerts | Measure-Object).Count
        $alerts | Group-Object AlertSeverity | ForEach-Object { Write-Host ("   {0,-8} {1}" -f $_.Name, $_.Count) }
        Write-Host ("   Total active alerts: {0}" -f $alertCount) -ForegroundColor Green
    } catch { Write-Host ("   Could not read alerts: {0}" -f $_.Exception.Message) -ForegroundColor Yellow }
    Write-Host "   Suppression: confirm 'MDC Alert Suppression - Benign FP - Prod' is scoped/documented (portal)." -ForegroundColor DarkGray
}

if ($Section -in 'Cost','All') {
    Write-Host "`n-- Enabled plans + protected-resource counts (cost proxy) --" -ForegroundColor Cyan
    try {
        $pricings = Get-AzSecurityPricing | Where-Object { $_.PricingTier -eq 'Standard' }
        $pricings | ForEach-Object { Write-Host ("   PLAN ON: {0}" -f $_.Name) -ForegroundColor Green }
        Import-Module Az.Resources -ErrorAction SilentlyContinue
        $vm  = (Get-AzResource -ResourceType 'Microsoft.Compute/virtualMachines' -ErrorAction SilentlyContinue | Measure-Object).Count
        $st  = (Get-AzResource -ResourceType 'Microsoft.Storage/storageAccounts' -ErrorAction SilentlyContinue | Measure-Object).Count
        $kv  = (Get-AzResource -ResourceType 'Microsoft.KeyVault/vaults' -ErrorAction SilentlyContinue | Measure-Object).Count
        $sql = (Get-AzResource -ResourceType 'Microsoft.Sql/servers' -ErrorAction SilentlyContinue | Measure-Object).Count
        Write-Host ("   VMs={0}  Storage={1}  KeyVaults={2}  SqlServers={3}" -f $vm,$st,$kv,$sql) -ForegroundColor Cyan
        $protectedCount = $vm + $st + $kv + $sql
        Write-Host ("   Approx protected-resource count (proxy): {0}  — verify actual pricing." -f $protectedCount) -ForegroundColor Yellow
    } catch { Write-Host ("   Could not read resources: {0}" -f $_.Exception.Message) -ForegroundColor Yellow }
}

$now = [ordered]@{ Timestamp = (Get-Date).ToString('s'); AlertCount = $alertCount; ProtectedResourceProxy = $protectedCount }
if ($SaveBaseline) { $now | ConvertTo-Json | Set-Content -Path $BaselinePath -Encoding UTF8; Write-Host ("`nBaseline saved: {0}" -f $BaselinePath) -ForegroundColor Green }
elseif (Test-Path $BaselinePath) {
    $base = Get-Content $BaselinePath -Raw | ConvertFrom-Json
    if ($null -ne $protectedCount -and $null -ne $base.ProtectedResourceProxy) { Write-Host ("`nProtected-resource drift vs baseline ({0}): {1}" -f $base.Timestamp, ($protectedCount - $base.ProtectedResourceProxy)) -ForegroundColor Cyan }
} else { Write-Host "`n(no baseline yet — run with -SaveBaseline to create one)" -ForegroundColor DarkGray }
Write-Host "Report complete (read-only)." -ForegroundColor Green
