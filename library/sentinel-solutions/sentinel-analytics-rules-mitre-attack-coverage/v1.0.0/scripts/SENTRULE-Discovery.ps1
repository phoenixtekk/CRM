<#
.SYNOPSIS
    SENTRULE-Discovery.ps1 — inventory enabled analytics rules, available templates, watchlists and detection-table freshness (read-only).
.DESCRIPTION
    PURPOSE
        Inventories the detection surface so tuning starts from reality: enabled analytics rules (with
        type and MITRE tactics/techniques where present), available rule templates from installed
        Content hub solutions, existing watchlists, and which expected detection tables have recent
        data. Read-only — it changes nothing.
    HOW TO RUN
        pwsh -File .\SENTRULE-Discovery.ps1 -ResourceGroup RG-Security-Sentinel `
             -WorkspaceName "Security Telemetry - Tenant - Workspace"

        Prereqs: Az modules (Az.Accounts, Az.SecurityInsights, Az.OperationalInsights) and at least
        Microsoft Sentinel Reader on the workspace. Sign in with an MFA-capable admin. Government cloud:
        pass -Environment AzureUSGovernment (verify endpoints for your cloud).
    EXPECTED RESULTS
        Tables of enabled rules (name/kind/enabled/tactics), rule templates available, watchlists, and a
        freshness check for expected detection tables. PASS = the workspace resolves and the inventory
        completes without error.
.NOTES
    White-label. Read-only. Az / Microsoft Sentinel PowerShell + KQL. No credentials in code.
#>

[CmdletBinding()]
param(
    [Parameter(Mandatory)] [string] $ResourceGroup,
    [Parameter(Mandatory)] [string] $WorkspaceName,
    [string[]] $ExpectedTables = @('SigninLogs','AuditLogs','AzureActivity','OfficeActivity','SecurityAlert','CommonSecurityLog'),
    [ValidateSet('AzureCloud','AzureUSGovernment')] [string] $Environment = 'AzureCloud'
)

$ErrorActionPreference = 'Stop'
function Write-Section([string] $Title) { Write-Host ''; Write-Host ("=== {0} ===" -f $Title) -ForegroundColor Cyan }

try {
    if (-not (Get-AzContext)) { Connect-AzAccount -Environment $Environment | Out-Null }
    $ws = Get-AzOperationalInsightsWorkspace -ResourceGroupName $ResourceGroup -Name $WorkspaceName -ErrorAction Stop
    $wsId = $ws.CustomerId
    Write-Host ("Workspace resolved: {0}" -f $WorkspaceName) -ForegroundColor Green
}
catch { Write-Error ("Failed to resolve workspace: {0}" -f $_.Exception.Message); return }

# --- Enabled analytics rules ------------------------------------------------------------------------
Write-Section 'Enabled analytics rules (with MITRE tactics where present)'
try {
    $rules = @(Get-AzSentinelAlertRule -ResourceGroupName $ResourceGroup -WorkspaceName $WorkspaceName -ErrorAction Stop)
    if ($rules.Count -eq 0) { Write-Host 'No analytics rules configured yet.' -ForegroundColor Yellow }
    else {
        $rules | Select-Object DisplayName, Kind, Enabled,
            @{n='Tactics';e={ ($_.Tactic -join ',') }},
            @{n='Techniques';e={ ($_.Technique -join ',') }} | Sort-Object DisplayName | Format-Table -AutoSize
        Write-Host ("Total rules: {0}  (Enabled: {1})" -f $rules.Count, (@($rules | Where-Object Enabled).Count))
    }
    Write-Host 'Expected pilot rules: Rule-BruteForce-Entra-Pilot, Rule-AtypicalTravel-Entra-Pilot, Rule-NewAdminRole-Entra-Pilot.'
}
catch { Write-Warning ("Could not enumerate analytics rules: {0}" -f $_.Exception.Message) }

# --- Rule templates ---------------------------------------------------------------------------------
Write-Section 'Available rule templates (from installed Content hub solutions)'
try {
    $templates = @(Get-AzSentinelAlertRuleTemplate -ResourceGroupName $ResourceGroup -WorkspaceName $WorkspaceName -ErrorAction SilentlyContinue)
    if ($templates.Count -eq 0) { Write-Host 'No rule templates found — install Content hub solutions (R3).' -ForegroundColor Yellow }
    else { Write-Host ("Rule templates available: {0} (Analytics -> Rule templates in the portal for detail)." -f $templates.Count) }
}
catch { Write-Warning ("Could not enumerate rule templates: {0}" -f $_.Exception.Message) }

# --- Watchlists -------------------------------------------------------------------------------------
Write-Section 'Watchlists (enrichment)'
try {
    $wl = @(Get-AzSentinelWatchlist -ResourceGroupName $ResourceGroup -WorkspaceName $WorkspaceName -ErrorAction SilentlyContinue)
    if ($wl.Count -eq 0) { Write-Host 'No watchlists found — import the enrichment set (Phase 1, Step 1).' -ForegroundColor Yellow }
    else { $wl | Select-Object DisplayName, Alias, ItemsSearchKey | Format-Table -AutoSize }
    Write-Host 'Expected: WL-VIPUsers-Tenant, WL-AuthorizedAdminIPs-Tenant, WL-TerminatedUsers-Tenant, WL-HighValueAssets-Tenant.'
}
catch { Write-Warning ("Could not enumerate watchlists: {0}" -f $_.Exception.Message) }

# --- Detection-table freshness ----------------------------------------------------------------------
Write-Section 'Detection-table freshness (rules can only detect what is present)'
foreach ($t in $ExpectedTables) {
    try {
        $q = "$t | where TimeGenerated > ago(24h) | count"
        $r = (Invoke-AzOperationalInsightsQuery -WorkspaceId $wsId -Query $q -ErrorAction Stop).Results
        $n = if ($r) { [int]$r[0].Count } else { 0 }
        if ($n -gt 0) { Write-Host ("  OK: {0} = {1} rows (24h)." -f $t, $n) -ForegroundColor Green }
        else { Write-Host ("  EMPTY: {0} has no data in 24h — do not build rules on it yet." -f $t) -ForegroundColor Red }
    }
    catch { Write-Host ("  {0}: not present / query failed (connect the source first)." -f $t) -ForegroundColor Yellow }
}

Write-Section 'Discovery complete'
Write-Host 'Next: SENTRULE-Coverage.ps1 (ATT&CK map + gaps), then enable + tune per 03-implementation.md.'
