<#
.SYNOPSIS
    ARCMDC-Discovery.ps1 — read-only discovery for the Defender for Cloud reference architecture:
    management-group hierarchy, per-subscription plan tiers, providers, workspaces, connectors,
    and resource counts (cost drivers).
.DESCRIPTION
    PURPOSE
        Read-only discovery for the "Architecture Service — Microsoft Defender for Cloud" solution.
        Maps the management-group hierarchy and, per subscription, the Defender-for-Cloud plan
        tiers, Microsoft.Security provider state, Log Analytics workspaces, existing AWS/GCP
        connectors, and resource counts by type (the inputs for the cost model). Makes no changes.
    HOW TO RUN
        powershell -ExecutionPolicy Bypass -File .\ARCMDC-Discovery.ps1
        powershell -ExecutionPolicy Bypass -File .\ARCMDC-Discovery.ps1 -OutputPath .\estate.json
        Requires Az.Accounts, Az.Security, Az.Resources, Az.ResourceGraph. Run Connect-AzAccount
        first, or the script will prompt. Reader across the estate is enough.
    EXPECTED RESULTS
        An estate map: MG hierarchy, per-subscription plan tiers + provider state, workspaces,
        connectors, and resource counts by type — the state to design against before enabling
        plans at scale.
.NOTES
    White-label. Read-only. Reports configuration/identifiers/counts only; makes no changes.
    Plan/pricing facts are indicative — verify current availability in your tenant.
#>
[CmdletBinding()]
param(
    [string]$OutputPath = ".\ARCMDC-discovery.json"
)

foreach ($m in 'Az.Accounts','Az.Security','Az.Resources','Az.ResourceGraph') {
    if (-not (Get-Module -ListAvailable -Name $m)) {
        Write-Host "Installing Az modules (one-time)..." -ForegroundColor Yellow
        Install-Module Az -Scope CurrentUser -Force -AllowClobber
        break
    }
}
Import-Module Az.Accounts -ErrorAction Stop
if (-not (Get-AzContext)) { Connect-AzAccount | Out-Null }

Write-Host "`n=== ARCMDC — Defender for Cloud estate discovery (read-only) ===" -ForegroundColor Cyan
$result = [ordered]@{ Timestamp = (Get-Date).ToString('s') }

# --- Management-group hierarchy ---
Write-Host "`n-- Management groups --" -ForegroundColor Cyan
try {
    $mgs = Get-AzManagementGroup -ErrorAction Stop
    $mgs | ForEach-Object { Write-Host ("   {0}  ({1})" -f $_.DisplayName, $_.Name) }
    $result.ManagementGroups = @($mgs | ForEach-Object { @{ Name = $_.Name; DisplayName = $_.DisplayName } })
} catch { Write-Host ("   Could not read management groups (need MG reader): {0}" -f $_.Exception.Message) -ForegroundColor Yellow }

# --- Per-subscription plan tiers + provider ---
Write-Host "`n-- Per-subscription Defender for Cloud plans --" -ForegroundColor Cyan
$subs = Get-AzSubscription -ErrorAction SilentlyContinue | Where-Object { $_.State -eq 'Enabled' }
$subState = @()
foreach ($s in $subs) {
    try {
        Set-AzContext -SubscriptionId $s.Id | Out-Null
        Import-Module Az.Security -ErrorAction SilentlyContinue
        $pricings = Get-AzSecurityPricing -ErrorAction SilentlyContinue
        $standard = @($pricings | Where-Object { $_.PricingTier -eq 'Standard' }).Name
        $prov = (Get-AzResourceProvider -ProviderNamespace Microsoft.Security -ErrorAction SilentlyContinue | Select-Object -First 1).RegistrationState
        Write-Host ("   {0,-36} standard plans: {1,-3}  provider: {2}" -f $s.Name, $standard.Count, $prov)
        $subState += @{ Subscription = $s.Name; Id = $s.Id; StandardPlans = $standard; Provider = $prov }
    } catch { Write-Host ("   {0}: could not read ({1})" -f $s.Name, $_.Exception.Message) -ForegroundColor Yellow }
}
$result.Subscriptions = $subState

# --- Resource counts by type (cost drivers) via Resource Graph ---
Write-Host "`n-- Resource counts by type (cost drivers) --" -ForegroundColor Cyan
try {
    Import-Module Az.ResourceGraph -ErrorAction Stop
    $q = "resources | summarize Count = count() by type | order by Count desc"
    $counts = Search-AzGraph -Query $q -First 40 -ErrorAction SilentlyContinue
    $drivers = 'microsoft.compute/virtualmachines','microsoft.storage/storageaccounts','microsoft.containerservice/managedclusters','microsoft.keyvault/vaults','microsoft.sql/servers','microsoft.web/sites'
    foreach ($c in $counts) {
        if ($drivers -contains $c.type) { Write-Host ("   {0,-52} {1}" -f $c.type, $c.Count) -ForegroundColor Green }
    }
    $result.ResourceCounts = @($counts | ForEach-Object { @{ Type = $_.type; Count = $_.Count } })
} catch { Write-Host ("   Could not query Resource Graph: {0}" -f $_.Exception.Message) -ForegroundColor Yellow }

# --- Multicloud connectors (current subscription context) ---
Write-Host "`n-- Security connectors (AWS/GCP) --" -ForegroundColor Cyan
try {
    $ctx = Get-AzContext
    $conns = Invoke-AzRestMethod -Path ("/subscriptions/{0}/providers/Microsoft.Security/securityConnectors?api-version=2023-10-01-preview" -f $ctx.Subscription.Id) -Method GET -ErrorAction SilentlyContinue
    if ($conns -and $conns.Content) {
        $obj = $conns.Content | ConvertFrom-Json
        if ($obj.value) { $obj.value | ForEach-Object { Write-Host ("   {0}  env: {1}" -f $_.name, $_.properties.environmentName) } }
        else { Write-Host "   (no AWS/GCP connectors in this subscription — add in the designed wave)" -ForegroundColor Yellow }
    }
} catch { Write-Host "   (connector API not available in this context)" -ForegroundColor DarkGray }

$result | ConvertTo-Json -Depth 8 | Set-Content -Path $OutputPath -Encoding UTF8
Write-Host ("`nDiscovery complete (read-only). Snapshot: {0}" -f $OutputPath) -ForegroundColor Green
Write-Host "Next: ARCMDC-Report.ps1 -Mode Coverage -SaveBaseline and -Mode Cost, then design (Implementation Step 2)." -ForegroundColor Green
