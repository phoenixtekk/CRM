<#
.SYNOPSIS
    MDCWP-Discovery.ps1 — read-only readiness for enabling Microsoft Defender for Cloud workload
    protection plans (Servers/Containers/Databases/Storage/KeyVault/AppService).
.DESCRIPTION
    PURPOSE
        Read-only discovery for the "Microsoft Defender for Cloud — Workload Protection Plans"
        solution. Reports the signed-in Azure context, the subscriptions onboarded to Defender for
        Cloud, the current Defender plan (pricing) state per subscription, the running account's
        rights, and Log Analytics workspaces available for continuous export. Makes no changes.
    HOW TO RUN
        powershell -ExecutionPolicy Bypass -File .\MDCWP-Discovery.ps1
        Requires the Az modules (Az.Accounts, Az.Security, Az.Resources, Az.OperationalInsights).
        Sign in with Connect-AzAccount first (the script prompts if not connected). Read-only.
    EXPECTED RESULTS
        A readiness picture: context, subscriptions, per-plan on/off state, roles, and workspaces —
        the state to confirm (and cost to estimate) before enabling. JSON snapshot.
.NOTES
    White-label. Read-only. Reports configuration/identifiers only; makes no changes.
    Workload plans are PAID per resource — pricing/tier facts are indicative; verify current pricing.
#>
[CmdletBinding()]
param(
    [string]$OutputPath = ".\MDCWP-discovery.json",
    [string[]]$SubscriptionId
)

foreach ($m in 'Az.Accounts','Az.Security','Az.Resources') {
    if (-not (Get-Module -ListAvailable -Name $m)) { Write-Host "Installing Az modules (one-time)..." -ForegroundColor Yellow; Install-Module Az -Scope CurrentUser -Force -AllowClobber; break }
}
Import-Module Az.Accounts -ErrorAction Stop
if (-not (Get-AzContext)) { Connect-AzAccount | Out-Null }
Import-Module Az.Security -ErrorAction Stop

Write-Host "`n=== Defender for Cloud — workload-plan readiness (read-only) ===" -ForegroundColor Cyan
$ctx = Get-AzContext
Write-Host ("Account: {0}" -f $ctx.Account.Id)
$result = [ordered]@{ Timestamp = (Get-Date).ToString('s'); Account = $ctx.Account.Id; Subscriptions = @() }

$subs = if ($SubscriptionId) { Get-AzSubscription | Where-Object { $_.Id -in $SubscriptionId } } else { Get-AzSubscription }
foreach ($s in $subs) {
    Set-AzContext -SubscriptionId $s.Id | Out-Null
    Write-Host ("`n-- Subscription: {0} ({1}) --" -f $s.Name, $s.Id) -ForegroundColor Cyan
    $subEntry = [ordered]@{ Name = $s.Name; Id = $s.Id; Plans = @() }
    try {
        $pricings = Get-AzSecurityPricing -ErrorAction Stop
        foreach ($p in $pricings) {
            $color = if ($p.PricingTier -eq 'Standard') { 'Green' } else { 'DarkGray' }
            Write-Host ("   {0,-24} {1}" -f $p.Name, $p.PricingTier) -ForegroundColor $color
            $subEntry.Plans += @{ Plan = $p.Name; Tier = $p.PricingTier }
        }
    } catch { Write-Host ("   Could not read Defender pricing: {0}" -f $_.Exception.Message) -ForegroundColor Yellow }
    $result.Subscriptions += $subEntry
}

Write-Host "`n-- Log Analytics workspaces (for continuous export) --" -ForegroundColor Cyan
try {
    Import-Module Az.OperationalInsights -ErrorAction SilentlyContinue
    $ws = Get-AzOperationalInsightsWorkspace -ErrorAction SilentlyContinue
    if ($ws) { $ws | ForEach-Object { Write-Host ("   {0} ({1})" -f $_.Name, $_.ResourceGroupName) } } else { Write-Host "   (none found — provision one for export)" -ForegroundColor Yellow }
} catch { Write-Host "   Workspace enumeration skipped." -ForegroundColor DarkGray }

Write-Host "`nNOTE: 'Standard' tier = a workload plan is ON (paid). 'Free' = CSPM only (no workload protection)." -ForegroundColor DarkGray
$result | ConvertTo-Json -Depth 8 | Set-Content -Path $OutputPath -Encoding UTF8
Write-Host ("`nDiscovery complete (read-only). Snapshot: {0}" -f $OutputPath) -ForegroundColor Green
Write-Host "Estimate cost for the pilot scope before enabling (MDCWP-Report.ps1 -Section Cost)." -ForegroundColor Green
