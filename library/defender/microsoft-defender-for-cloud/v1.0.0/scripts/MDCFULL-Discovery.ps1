<#
.SYNOPSIS
    MDCFULL-Discovery.ps1 — read-only estate readiness for the complete Microsoft Defender for Cloud
    solution (architecture, workload plans, enablement, and PoC).
.DESCRIPTION
    PURPOSE
        Read-only discovery for the "Microsoft Defender for Cloud" (complete) solution. Reports, without
        changing anything: the signed-in Azure context and the running account's rights, the management-
        group hierarchy, the subscriptions onboarded to Defender for Cloud and their current Defender plan
        (pricing) state, Microsoft.Security provider registration, Log Analytics workspaces available for
        continuous export, any AWS/GCP security connectors, and resource counts by type (the cost drivers).
        The state to confirm — and the cost to estimate — before designing, enabling, or proving.
    HOW TO RUN
        powershell -ExecutionPolicy Bypass -File .\MDCFULL-Discovery.ps1
        powershell -ExecutionPolicy Bypass -File .\MDCFULL-Discovery.ps1 -SubscriptionId '<pilot sub id>'
        Requires the Az modules (Az.Accounts, Az.Security, Az.Resources, Az.OperationalInsights).
        Sign in with Connect-AzAccount first (the script prompts if not connected). Read-only.
    EXPECTED RESULTS
        A readiness picture: context, MG hierarchy, subscriptions, per-plan on/off state, providers,
        workspaces, connectors, and resource counts — plus a JSON snapshot. Makes no changes.
.NOTES
    White-label. Read-only. Reports configuration/identifiers only; makes no changes.
    Workload plans and Defender CSPM are PAID per resource — pricing/tier facts are indicative; verify
    current pricing and plan availability in your tenant.
#>
[CmdletBinding()]
param(
    [string]$OutputPath = ".\MDCFULL-discovery.json",
    [string[]]$SubscriptionId
)

foreach ($m in 'Az.Accounts','Az.Security','Az.Resources') {
    if (-not (Get-Module -ListAvailable -Name $m)) { Write-Host "Installing Az modules (one-time)..." -ForegroundColor Yellow; Install-Module Az -Scope CurrentUser -Force -AllowClobber; break }
}
Import-Module Az.Accounts -ErrorAction Stop
if (-not (Get-AzContext)) { Connect-AzAccount | Out-Null }
Import-Module Az.Security -ErrorAction Stop

Write-Host "`n=== Defender for Cloud — complete-solution readiness (read-only) ===" -ForegroundColor Cyan
$ctx = Get-AzContext
Write-Host ("Account: {0}" -f $ctx.Account.Id)
$result = [ordered]@{ Timestamp = (Get-Date).ToString('s'); Account = $ctx.Account.Id; ManagementGroups = @(); Subscriptions = @(); Workspaces = @() }

# --- Management-group hierarchy (for the architecture design) ---
Write-Host "`n-- Management groups (architecture scope) --" -ForegroundColor Cyan
try {
    $mgs = Get-AzManagementGroup -ErrorAction SilentlyContinue
    if ($mgs) { foreach ($mg in $mgs) { Write-Host ("   {0}  ({1})" -f $mg.DisplayName, $mg.Name); $result.ManagementGroups += @{ Name = $mg.Name; DisplayName = $mg.DisplayName } } }
    else { Write-Host "   (none enumerable — confirm MG reader rights; design the hierarchy first)" -ForegroundColor Yellow }
} catch { Write-Host "   MG enumeration skipped (rights?)." -ForegroundColor DarkGray }

# --- Per-subscription Defender plan state + providers + cost drivers ---
$subs = if ($SubscriptionId) { Get-AzSubscription | Where-Object { $_.Id -in $SubscriptionId } } else { Get-AzSubscription }
foreach ($s in $subs) {
    Set-AzContext -SubscriptionId $s.Id | Out-Null
    Write-Host ("`n-- Subscription: {0} ({1}) --" -f $s.Name, $s.Id) -ForegroundColor Cyan
    $subEntry = [ordered]@{ Name = $s.Name; Id = $s.Id; Plans = @(); SecurityProvider = 'Unknown'; ResourceCounts = @{} }

    try {
        $pricings = Get-AzSecurityPricing -ErrorAction Stop
        foreach ($p in $pricings) {
            $color = if ($p.PricingTier -eq 'Standard') { 'Green' } else { 'DarkGray' }
            Write-Host ("   plan {0,-22} {1}" -f $p.Name, $p.PricingTier) -ForegroundColor $color
            $subEntry.Plans += @{ Plan = $p.Name; Tier = $p.PricingTier }
        }
    } catch { Write-Host ("   Could not read Defender pricing: {0}" -f $_.Exception.Message) -ForegroundColor Yellow }

    try {
        $rp = Get-AzResourceProvider -ProviderNamespace Microsoft.Security -ErrorAction SilentlyContinue | Select-Object -First 1
        $subEntry.SecurityProvider = if ($rp) { $rp.RegistrationState } else { 'NotFound' }
        Write-Host ("   Microsoft.Security provider: {0}" -f $subEntry.SecurityProvider) -ForegroundColor $(if ($subEntry.SecurityProvider -eq 'Registered') { 'Green' } else { 'Yellow' })
    } catch { Write-Host "   Provider state unread." -ForegroundColor DarkGray }

    # Cost drivers — counts by type (indicative; verify current pricing)
    try {
        $counts = Get-AzResource | Group-Object ResourceType | Sort-Object Count -Descending | Select-Object -First 12
        foreach ($c in $counts) { $subEntry.ResourceCounts[$c.Name] = $c.Count }
        Write-Host ("   resource types (top): {0}" -f (($counts | ForEach-Object { "$($_.Name)=$($_.Count)" }) -join ', ')) -ForegroundColor DarkGray
    } catch { Write-Host "   Resource enumeration skipped." -ForegroundColor DarkGray }

    # AWS/GCP connectors (multicloud)
    try {
        $conns = Get-AzSecurityConnector -ErrorAction SilentlyContinue
        if ($conns) { $subEntry.Connectors = @($conns | ForEach-Object { $_.Name }); Write-Host ("   multicloud connectors: {0}" -f ($subEntry.Connectors -join ', ')) -ForegroundColor Green }
    } catch { }

    $result.Subscriptions += $subEntry
}

Write-Host "`n-- Log Analytics workspaces (for continuous export) --" -ForegroundColor Cyan
try {
    Import-Module Az.OperationalInsights -ErrorAction SilentlyContinue
    $ws = Get-AzOperationalInsightsWorkspace -ErrorAction SilentlyContinue
    if ($ws) { $ws | ForEach-Object { Write-Host ("   {0} ({1})" -f $_.Name, $_.ResourceGroupName); $result.Workspaces += @{ Name = $_.Name; ResourceGroup = $_.ResourceGroupName } } }
    else { Write-Host "   (none found — provision one for export)" -ForegroundColor Yellow }
} catch { Write-Host "   Workspace enumeration skipped." -ForegroundColor DarkGray }

Write-Host "`nNOTE: 'Standard' tier = a plan is ON (paid). 'Free' = CSPM only (no workload protection)." -ForegroundColor DarkGray
$result | ConvertTo-Json -Depth 8 | Set-Content -Path $OutputPath -Encoding UTF8
Write-Host ("`nDiscovery complete (read-only). Snapshot: {0}" -f $OutputPath) -ForegroundColor Green
Write-Host "Next: estimate cost (MDCFULL-Report.ps1 -Mode Cost) and validate readiness (MDCFULL-Validate.ps1)." -ForegroundColor Green
