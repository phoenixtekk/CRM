<#
.SYNOPSIS
    WSMDC-Discovery.ps1 — read-only posture discovery for the Defender for Cloud workshop: plan
    tiers, Secure Score, provider state, workspaces, and multicloud connectors.
.DESCRIPTION
    PURPOSE
        Read-only environment discovery for the "Workshop — Microsoft Defender for Cloud" enablement
        package. For the pilot subscription (in context or named), lists the Defender for Cloud
        pricing/plan tiers (CSPM/CloudPosture and the CWPP plans), the current Secure Score, whether
        the Microsoft.Security provider is registered, available Log Analytics workspaces, and any
        AWS/GCP security connectors. Makes NO changes.
    HOW TO RUN
        powershell -ExecutionPolicy Bypass -File .\WSMDC-Discovery.ps1
        powershell -ExecutionPolicy Bypass -File .\WSMDC-Discovery.ps1 -SubscriptionId '<pilot sub id>'
        Requires Az.Accounts, Az.Security, Az.Resources, Az.OperationalInsights. Run Connect-AzAccount
        first, or the script will prompt.
    EXPECTED RESULTS
        A per-subscription readiness picture used in Lab 0: plan tiers, Secure Score, provider state,
        workspaces, and connectors.
.NOTES
    White-label. Read-only. Reports configuration/identifiers only; makes no changes.
    Plan/pricing facts are indicative — verify current availability in your tenant.
#>
[CmdletBinding()]
param(
    [string]$SubscriptionId,
    [string]$OutputPath = ".\wsmdc-discovery.json"
)

$ErrorActionPreference = 'Continue'
foreach ($m in 'Az.Accounts','Az.Security','Az.Resources','Az.OperationalInsights') {
    if (-not (Get-Module -ListAvailable -Name $m)) {
        Write-Host "Installing Az modules (one-time)..." -ForegroundColor Yellow
        Install-Module Az -Scope CurrentUser -Force -AllowClobber; break
    }
}
Import-Module Az.Accounts -ErrorAction Stop
Import-Module Az.Security -ErrorAction Stop

if (-not (Get-AzContext)) { Connect-AzAccount | Out-Null }
if ($SubscriptionId) { Set-AzContext -SubscriptionId $SubscriptionId | Out-Null }
$ctx = Get-AzContext

Write-Host "`n=== Defender for Cloud workshop — posture discovery (read-only) ===" -ForegroundColor Cyan
Write-Host ("Subscription: {0} ({1})" -f $ctx.Subscription.Name, $ctx.Subscription.Id)
$result = [ordered]@{ Timestamp = (Get-Date).ToString('s'); SubscriptionId = $ctx.Subscription.Id }

# --- Plan tiers ---
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
    $onCount = ($plans | Where-Object { $_.Tier -eq 'Standard' }).Count
    Write-Host ("   -> {0} plan(s) On (Standard). At least one is needed for the alerts lab (R3)." -f $onCount) -ForegroundColor Cyan
} catch { Write-Host "   Could not read plans: $($_.Exception.Message)" -ForegroundColor Yellow }

# --- Secure Score ---
Write-Host "`n-- Secure Score --" -ForegroundColor Cyan
try {
    $score = Get-AzSecuritySecureScore -ErrorAction Stop | Where-Object { $_.Name -eq 'ascScore' } | Select-Object -First 1
    if ($score) {
        $pct = if ($score.Max -gt 0) { [math]::Round(100 * $score.Current / $score.Max, 1) } else { 0 }
        Write-Host ("   Secure Score: {0}/{1} ({2}%)" -f $score.Current, $score.Max, $pct) -ForegroundColor Green
        $result.SecureScore = @{ Current = $score.Current; Max = $score.Max; Percent = $pct }
    } else { Write-Host "   Secure Score not yet populated (allow warm-up — R2)." -ForegroundColor Yellow }
} catch { Write-Host "   Could not read Secure Score: $($_.Exception.Message)" -ForegroundColor Yellow }

# --- Provider registration ---
Write-Host "`n-- Microsoft.Security provider --" -ForegroundColor Cyan
try {
    $prov = Get-AzResourceProvider -ProviderNamespace 'Microsoft.Security' -ErrorAction Stop | Select-Object -First 1
    Write-Host ("   Registration: {0}" -f $prov.RegistrationState) -ForegroundColor ($(if($prov.RegistrationState -eq 'Registered'){'Green'}else{'Yellow'}))
    $result.MicrosoftSecurityProvider = $prov.RegistrationState
} catch { Write-Host "   Could not read provider: $($_.Exception.Message)" -ForegroundColor Yellow }

# --- Workspaces ---
Write-Host "`n-- Log Analytics workspaces --" -ForegroundColor Cyan
try {
    Import-Module Az.OperationalInsights -ErrorAction Stop
    $ws = Get-AzOperationalInsightsWorkspace -ErrorAction Stop
    Write-Host ("   {0} workspace(s) found." -f ($ws | Measure-Object).Count) -ForegroundColor Green
    $result.Workspaces = @($ws | Select-Object -First 10 | ForEach-Object { $_.Name })
} catch { Write-Host "   Could not enumerate workspaces: $($_.Exception.Message)" -ForegroundColor Yellow }

# --- Multicloud connectors ---
Write-Host "`n-- AWS/GCP connectors --" -ForegroundColor Cyan
try {
    $connectors = Get-AzSecurityConnector -ErrorAction Stop
    if ($connectors) {
        foreach ($c in $connectors) { Write-Host ("   Connector: {0} ({1})" -f $c.Name, $c.EnvironmentName) -ForegroundColor Green }
        $result.Connectors = @($connectors | ForEach-Object { @{ Name = $_.Name; Env = $_.EnvironmentName } })
    } else { Write-Host "   No AWS/GCP connectors (Lab 4 runs as a concept walk-through — R7)." -ForegroundColor Yellow }
} catch { Write-Host "   Could not read connectors (cmdlet/version may differ): $($_.Exception.Message)" -ForegroundColor Yellow }

$result | ConvertTo-Json -Depth 6 | Out-File -FilePath $OutputPath -Encoding UTF8
Write-Host "`nSaved discovery to $OutputPath" -ForegroundColor Cyan
Write-Host "This script is READ-ONLY — it changed nothing." -ForegroundColor Green
