<#
.SYNOPSIS
    DEFCSPM-Discovery.ps1 — read-only posture discovery for Microsoft Defender for Cloud: plan
    tiers, Secure Score, providers, workspaces, and multicloud connectors.
.DESCRIPTION
    PURPOSE
        Read-only discovery for the "Microsoft Defender for Cloud — CSPM & Secure Score
        Remediation" solution. For the subscription in context (or a named subscription), lists
        the Defender for Cloud pricing/plan tiers (incl. CloudPosture / Defender CSPM), the current
        Secure Score, whether the Microsoft.Security provider is registered, available Log Analytics
        workspaces, and any existing AWS/GCP security connectors. Makes no changes.
    HOW TO RUN
        powershell -ExecutionPolicy Bypass -File .\DEFCSPM-Discovery.ps1
        powershell -ExecutionPolicy Bypass -File .\DEFCSPM-Discovery.ps1 -SubscriptionId '<sub id>'
        Requires Az.Accounts, Az.Security, Az.Resources, Az.OperationalInsights. Run Connect-AzAccount
        first, or the script will prompt.
    EXPECTED RESULTS
        A per-subscription readiness picture: plan tiers, Secure Score, provider state, workspaces,
        and connectors — the state to confirm before enabling Defender CSPM and remediating.
.NOTES
    White-label. Read-only. Reports configuration/identifiers only; makes no changes.
    Plan/pricing facts are indicative — verify current availability in your tenant.
#>
[CmdletBinding()]
param(
    [string]$SubscriptionId,
    [string]$OutputPath = ".\DEFCSPM-discovery.json"
)

foreach ($m in 'Az.Accounts','Az.Security','Az.Resources','Az.OperationalInsights') {
    if (-not (Get-Module -ListAvailable -Name $m)) {
        Write-Host "Installing Az modules (one-time)..." -ForegroundColor Yellow
        Install-Module Az -Scope CurrentUser -Force -AllowClobber
        break
    }
}
Import-Module Az.Accounts -ErrorAction Stop
Import-Module Az.Security -ErrorAction Stop

if (-not (Get-AzContext)) { Connect-AzAccount | Out-Null }
if ($SubscriptionId) { Set-AzContext -SubscriptionId $SubscriptionId | Out-Null }
$ctx = Get-AzContext

Write-Host "`n=== Microsoft Defender for Cloud — posture discovery (read-only) ===" -ForegroundColor Cyan
Write-Host ("Subscription: {0} ({1})" -f $ctx.Subscription.Name, $ctx.Subscription.Id)
$result = [ordered]@{ Timestamp = (Get-Date).ToString('s'); SubscriptionId = $ctx.Subscription.Id }

# --- Defender for Cloud plan tiers ---
Write-Host "`n-- Defender for Cloud plans (CloudPosture = Defender CSPM) --" -ForegroundColor Cyan
try {
    $pricings = Get-AzSecurityPricing -ErrorAction Stop
    $plans = @()
    foreach ($p in $pricings) {
        $color = if ($p.PricingTier -eq 'Standard') { 'Green' } else { 'Yellow' }
        Write-Host ("   Plan {0,-24} tier: {1}" -f $p.Name, $p.PricingTier) -ForegroundColor $color
        $plans += @{ Name = $p.Name; Tier = $p.PricingTier }
    }
    $result.Plans = $plans
    $cspm = $pricings | Where-Object { $_.Name -eq 'CloudPosture' } | Select-Object -First 1
    if ($cspm) { Write-Host ("   -> Defender CSPM (CloudPosture): {0}" -f $cspm.PricingTier) -ForegroundColor Cyan }
} catch { Write-Host ("   Could not read plans: {0}" -f $_.Exception.Message) -ForegroundColor Yellow }

# --- Secure Score ---
Write-Host "`n-- Secure Score --" -ForegroundColor Cyan
try {
    $score = Get-AzSecuritySecureScore -ErrorAction SilentlyContinue | Select-Object -First 1
    if ($score) {
        $pct = [math]::Round($score.Percentage * 100)
        Write-Host ("   Secure Score: {0}% ({1}/{2})" -f $pct, $score.CurrentScore, $score.MaxScore) -ForegroundColor Green
        $result.SecureScorePct = $pct
    } else { Write-Host "   Secure Score not available yet (allow time after enabling)." -ForegroundColor Yellow }
} catch { Write-Host ("   Could not read Secure Score: {0}" -f $_.Exception.Message) -ForegroundColor Yellow }

# --- Provider registration ---
Write-Host "`n-- Resource provider (Microsoft.Security) --" -ForegroundColor Cyan
try {
    $prov = Get-AzResourceProvider -ProviderNamespace Microsoft.Security -ErrorAction Stop | Select-Object -First 1
    $state = $prov.RegistrationState
    Write-Host ("   Microsoft.Security: {0}" -f $state) -ForegroundColor $(if ($state -eq 'Registered') { 'Green' } else { 'Yellow' })
    $result.MicrosoftSecurityProvider = $state
} catch { Write-Host ("   Could not read provider: {0}" -f $_.Exception.Message) -ForegroundColor Yellow }

# --- Log Analytics workspaces (export destinations) ---
Write-Host "`n-- Log Analytics workspaces --" -ForegroundColor Cyan
try {
    Import-Module Az.OperationalInsights -ErrorAction Stop
    $ws = Get-AzOperationalInsightsWorkspace -ErrorAction SilentlyContinue
    if ($ws) { $ws | ForEach-Object { Write-Host ("   {0}  ({1})" -f $_.Name, $_.ResourceGroupName) } }
    else { Write-Host "   (none found — provision one for continuous export)" -ForegroundColor Yellow }
} catch { Write-Host ("   Could not read workspaces: {0}" -f $_.Exception.Message) -ForegroundColor Yellow }

# --- Multicloud connectors ---
Write-Host "`n-- Security connectors (AWS/GCP) --" -ForegroundColor Cyan
try {
    $conns = Invoke-AzRestMethod -Path ("/subscriptions/{0}/providers/Microsoft.Security/securityConnectors?api-version=2023-10-01-preview" -f $ctx.Subscription.Id) -Method GET -ErrorAction SilentlyContinue
    if ($conns -and $conns.Content) {
        $obj = $conns.Content | ConvertFrom-Json
        if ($obj.value) { $obj.value | ForEach-Object { Write-Host ("   {0}  env: {1}" -f $_.name, $_.properties.environmentName) } }
        else { Write-Host "   (no AWS/GCP connectors — optional, add after Azure pilot)" -ForegroundColor Yellow }
    }
} catch { Write-Host "   (connector API not available — optional)" -ForegroundColor DarkGray }

$result | ConvertTo-Json -Depth 6 | Set-Content -Path $OutputPath -Encoding UTF8
Write-Host ("`nDiscovery complete (read-only). Snapshot: {0}" -f $OutputPath) -ForegroundColor Green
