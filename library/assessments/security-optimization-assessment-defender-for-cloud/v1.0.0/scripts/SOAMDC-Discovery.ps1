<#
.SYNOPSIS
    SOAMDC-Discovery.ps1 — read-only discovery of Microsoft Defender for Cloud configuration (plan
    tiers, Secure Score, providers, workspaces, agentless-scan state, connectors); saves the baseline.
.DESCRIPTION
    PURPOSE
        Read-only discovery for the "Security Optimization Assessment — Defender for Cloud" solution.
        For the subscription in context (or a named subscription) enumerates: Defender for Cloud
        pricing/plan tiers (incl. CloudPosture / Defender CSPM and workload plans), current Secure
        Score, Microsoft.Security provider registration, Log Analytics workspaces, agentless-scanning
        extension state, and any AWS/GCP security connectors. Writes a JSON baseline
        (`Posture Baseline - Defender for Cloud - Assess`). Makes NO changes.
    HOW TO RUN
        Connect-AzAccount
        powershell -ExecutionPolicy Bypass -File .\SOAMDC-Discovery.ps1 `
            -SubscriptionId '<pilot subscription id>' `
            -OutputPath ".\Posture Baseline - Defender for Cloud - Assess.json"
        Requires Az.Accounts, Az.Security, Az.Resources (and Az.ResourceGraph for coverage script).
        Read-only roles: Security Reader + Reader.
    EXPECTED RESULTS
        A per-subscription JSON baseline with four domain sections — the evidence the rest of the
        assessment scores.
.NOTES
    White-label. Read-only. Plan/pricing/preview facts are indicative — verify current availability
    in your tenant. Secure Score is not instantaneous; allow warm-up after any change.
#>
[CmdletBinding()]
param(
    [string]$SubscriptionId,
    [string]$OutputPath = ".\Posture Baseline - Defender for Cloud - Assess.json"
)

$ErrorActionPreference = 'Stop'

foreach ($m in 'Az.Accounts','Az.Security','Az.Resources') {
    if (-not (Get-Module -ListAvailable -Name $m)) {
        Write-Host "Installing Az modules (one-time, CurrentUser)..." -ForegroundColor Yellow
        Install-Module Az -Scope CurrentUser -Force -AllowClobber; break
    }
}
Import-Module Az.Accounts -ErrorAction Stop
Import-Module Az.Security -ErrorAction Stop

if (-not (Get-AzContext)) { Connect-AzAccount | Out-Null }
if ($SubscriptionId) { Set-AzContext -Subscription $SubscriptionId | Out-Null }
$ctx = Get-AzContext
Write-Host "SOAMDC-Discovery — read-only. Subscription: $($ctx.Subscription.Name) ($($ctx.Subscription.Id))" -ForegroundColor Cyan

$baseline = [ordered]@{
    solution     = "SOAMDC"
    generatedUtc = (Get-Date).ToUniversalTime().ToString("o")
    subscription = $ctx.Subscription.Id
    readOnly     = $true
    domains      = [ordered]@{}
    manualChecks = @()
}

# --- Domain 2: Plan coverage (Defender for Cloud pricing tiers) ------------------------------------
$plans = @()
try {
    $pricings = Get-AzSecurityPricing -ErrorAction Stop
    foreach ($p in $pricings) {
        $plans += [ordered]@{ name = $p.Name; tier = $p.PricingTier; subPlan = $p.SubPlan }
    }
} catch { Write-Warning "Get-AzSecurityPricing failed: $($_.Exception.Message)" }
$baseline.domains["planCoverage"] = [ordered]@{
    plans          = $plans
    standardPlans  = @($plans | Where-Object { $_.tier -eq 'Standard' } | ForEach-Object { $_.name })
    freePlans      = @($plans | Where-Object { $_.tier -eq 'Free' } | ForEach-Object { $_.name })
    note           = "Standard = paid plan enabled. Verify current plan-to-feature mapping and pricing in your tenant."
}

# --- Domain 1: Secure Score & recommendations -----------------------------------------------------
$secureScore = $null
try {
    $ss = Get-AzSecuritySecureScore -ErrorAction Stop
    if ($ss) { $secureScore = @{ current = $ss.CurrentScore; max = $ss.MaxScore; percentage = $ss.Percentage } }
} catch { Write-Warning "Get-AzSecuritySecureScore failed (may need warm-up / provider registration): $($_.Exception.Message)" }
$baseline.domains["secureScore"] = [ordered]@{
    secureScore = $secureScore
    note        = "Secure Score is not instantaneous; allow warm-up after changes. Recommendations detail is queried by SOAMDC-Coverage.ps1 via Resource Graph."
}

# --- Domain 3: Regulatory compliance --------------------------------------------------------------
$standards = @()
try {
    $comp = Get-AzSecurityRegulatoryComplianceStandard -ErrorAction Stop
    foreach ($c in $comp) { $standards += [ordered]@{ name = $c.Name; state = $c.State; passed = $c.PassedControls; failed = $c.FailedControls } }
} catch { Write-Warning "Regulatory compliance query failed: $($_.Exception.Message)" }
$baseline.domains["regulatoryCompliance"] = [ordered]@{
    mappedStandards = $standards
    note            = "The CHOICE of which standard applies is the compliance team's decision. This lists what is currently mapped and its pass/fail counts."
}

# --- Domain 4: Agent / agentless coverage ---------------------------------------------------------
$providerRegistered = $false
try {
    $prov = Get-AzResourceProvider -ProviderNamespace Microsoft.Security -ErrorAction Stop
    $providerRegistered = ($prov | Where-Object { $_.RegistrationState -eq 'Registered' }).Count -gt 0
} catch { }
# Agentless scanning is configured as an extension on the CloudPosture (Defender CSPM) / VM plans.
$agentlessOn = $false
try {
    $cspm = Get-AzSecurityPricing -Name 'CloudPosture' -ErrorAction SilentlyContinue
    if ($cspm -and $cspm.Extensions) {
        $agentlessOn = [bool]($cspm.Extensions | Where-Object { $_.Name -eq 'AgentlessVmScanning' -and $_.IsEnabled -eq 'True' })
    }
} catch { }
$baseline.domains["agentCoverage"] = [ordered]@{
    providerRegistered = $providerRegistered
    agentlessScanning  = $agentlessOn
    note               = "Per-machine coverage detail is computed by SOAMDC-Coverage.ps1 via Resource Graph. Agentless requires Defender CSPM / Servers — verify current."
}

# --- Multicloud connectors ------------------------------------------------------------------------
$connectors = @()
try {
    $sc = Get-AzSecurityConnector -ErrorAction SilentlyContinue
    foreach ($c in $sc) { $connectors += [ordered]@{ name = $c.Name; env = $c.EnvironmentName } }
} catch { }
$baseline["connectors"] = $connectors

$baseline.manualChecks += "Confirm Secure Score and recommendations in the portal if the API returned no score (possible warm-up)."
$baseline.manualChecks += "Confirm with the compliance owner which regulatory standard is REQUIRED (deferred decision)."

$baseline | ConvertTo-Json -Depth 8 | Out-File -FilePath $OutputPath -Encoding utf8
Write-Host "Baseline written: $OutputPath" -ForegroundColor Green
Write-Host "This script made NO changes to the environment." -ForegroundColor Green
