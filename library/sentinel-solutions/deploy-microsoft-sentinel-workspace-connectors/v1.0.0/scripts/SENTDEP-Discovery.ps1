<#
.SYNOPSIS
    SENTDEP-Discovery.ps1 — discover the current Sentinel workspace, connectors, DCRs, tables and retention (read-only).
.DESCRIPTION
    PURPOSE
        Inventories the current Microsoft Sentinel / Log Analytics state so the build starts from
        reality: whether the target workspace exists (name/region/resource group), whether Sentinel is
        enabled on it, which data connectors and Data Collection Rules (DCRs) are present, per-table log
        tier and retention, and existing diagnostic settings that could indicate duplicate ingestion.
        Read-only — it changes nothing.
    HOW TO RUN
        pwsh -File .\SENTDEP-Discovery.ps1 -ResourceGroup RG-Security-Sentinel `
             -WorkspaceName "Security Telemetry - Tenant - Workspace"
        pwsh -File .\SENTDEP-Discovery.ps1 -ResourceGroup RG-Security-Sentinel `
             -WorkspaceName "Security Telemetry - Tenant - Workspace" -Environment AzureUSGovernment

        Prereqs: Az modules (Az.Accounts, Az.OperationalInsights, Az.Monitor, Az.SecurityInsights) and
        at least Microsoft Sentinel Reader on the workspace. Sign in with an MFA-capable admin. For
        Government cloud pass -Environment AzureUSGovernment (verify endpoints for your cloud).
    EXPECTED RESULTS
        A discovery summary: workspace name/region/RG, Sentinel onboarding state, a table of enabled
        data connectors, a list of DCRs, per-table tier/retention, and existing diagnostic settings on
        the subscription/Entra. PASS = the workspace resolves and the inventory completes without error.
.NOTES
    White-label. Read-only. Az / Microsoft Sentinel PowerShell. No credentials in code.
#>

[CmdletBinding()]
param(
    [Parameter(Mandatory)] [string] $ResourceGroup,
    [Parameter(Mandatory)] [string] $WorkspaceName,
    [string] $SubscriptionId,
    [ValidateSet('AzureCloud','AzureUSGovernment')] [string] $Environment = 'AzureCloud'
)

$ErrorActionPreference = 'Stop'
function Write-Section([string] $Title) { Write-Host ''; Write-Host ("=== {0} ===" -f $Title) -ForegroundColor Cyan }

try {
    if (-not (Get-AzContext)) { Connect-AzAccount -Environment $Environment | Out-Null }
    if ($SubscriptionId) { Set-AzContext -Subscription $SubscriptionId | Out-Null }
    Write-Host ("Signed in to subscription: {0}" -f (Get-AzContext).Subscription.Name) -ForegroundColor Green
}
catch {
    Write-Error ("Failed to connect to Azure: {0}" -f $_.Exception.Message)
    Write-Host 'Install the Az modules and run Connect-AzAccount with an MFA-capable admin, then retry.'
    return
}

# --- Workspace --------------------------------------------------------------------------------------
Write-Section 'Log Analytics workspace'
$ws = $null
try {
    $ws = Get-AzOperationalInsightsWorkspace -ResourceGroupName $ResourceGroup -Name $WorkspaceName -ErrorAction Stop
    $ws | Select-Object Name, Location, ResourceGroupName, Sku, @{n='RetentionDays';e={$_.retentionInDays}} | Format-List
    Write-Host ('Workspace resolved. Region (residency) = {0}' -f $ws.Location) -ForegroundColor Green
}
catch {
    Write-Warning ("Workspace '{0}' not found in RG '{1}': {2}" -f $WorkspaceName, $ResourceGroup, $_.Exception.Message)
    Write-Host 'Create it per 03-implementation.md Phase 1 (region is fixed for the life of the workspace).'
    return
}

# --- Sentinel onboarding ----------------------------------------------------------------------------
Write-Section 'Microsoft Sentinel enablement'
try {
    $onboard = Get-AzSentinelOnboardingState -ResourceGroupName $ResourceGroup -WorkspaceName $WorkspaceName -ErrorAction SilentlyContinue
    if ($onboard) { Write-Host 'Sentinel is ENABLED on this workspace.' -ForegroundColor Green }
    else { Write-Host 'Sentinel does not appear enabled. Enable it (Phase 1, Step 2).' -ForegroundColor Yellow }
}
catch { Write-Warning ("Could not read Sentinel onboarding state: {0}" -f $_.Exception.Message) }

# --- Data connectors --------------------------------------------------------------------------------
Write-Section 'Data connectors'
try {
    $connectors = @(Get-AzSentinelDataConnector -ResourceGroupName $ResourceGroup -WorkspaceName $WorkspaceName -ErrorAction Stop)
    if ($connectors.Count -eq 0) { Write-Host 'No data connectors configured yet.' -ForegroundColor Yellow }
    else { $connectors | Select-Object Name, Kind | Format-Table -AutoSize }
    Write-Host 'Expected high-value set: Entra ID, Defender XDR, Office 365, Azure Activity, Syslog/CEF via AMA.'
}
catch { Write-Warning ("Could not enumerate data connectors: {0}" -f $_.Exception.Message) }

# --- Data Collection Rules --------------------------------------------------------------------------
Write-Section 'Data Collection Rules (DCRs) — where ingestion is filtered'
try {
    $dcrs = @(Get-AzDataCollectionRule -ResourceGroupName $ResourceGroup -ErrorAction SilentlyContinue)
    if ($dcrs.Count -eq 0) { Write-Host 'No DCRs in this resource group.' -ForegroundColor Yellow }
    else { $dcrs | Select-Object Name, Location | Format-Table -AutoSize }
    Write-Host 'Expected: DCR-AzureActivity-Subscription-Pilot, DCR-Syslog-Linux-Pilot, DCR-CEF-Appliances-Pilot.'
    Write-Host 'Review each syslog/CEF DCR for facility/severity FILTERING (all-facilities = cost risk).'
}
catch { Write-Warning ("Could not enumerate DCRs: {0}" -f $_.Exception.Message) }

# --- Table tiers / retention ------------------------------------------------------------------------
Write-Section 'Table tiers and retention'
try {
    $tables = @(Get-AzOperationalInsightsTable -ResourceGroupName $ResourceGroup -WorkspaceName $WorkspaceName -ErrorAction SilentlyContinue)
    if ($tables.Count -eq 0) { Write-Host 'No custom/known tables reported yet (data may not have arrived).' -ForegroundColor Yellow }
    else {
        $tables | Select-Object Name, @{n='Plan';e={$_.Plan}}, @{n='RetentionDays';e={$_.RetentionInDays}},
            @{n='TotalRetentionDays';e={$_.TotalRetentionInDays}} | Sort-Object Name | Format-Table -AutoSize
    }
    Write-Host 'Detection-driving tables -> Analytics; high-volume low-signal -> Basic/Auxiliary (verify eligibility).'
}
catch { Write-Warning ("Could not read table plan: {0}" -f $_.Exception.Message) }

# --- Diagnostic settings (duplicate-ingestion check) ------------------------------------------------
Write-Section 'Diagnostic settings on the subscription (duplicate-ingestion check)'
try {
    $subId = (Get-AzContext).Subscription.Id
    $diag = @(Get-AzDiagnosticSetting -ResourceId ("/subscriptions/{0}" -f $subId) -ErrorAction SilentlyContinue)
    if ($diag.Count -eq 0) { Write-Host 'No subscription-level diagnostic settings found.' }
    else { $diag | Select-Object Name, @{n='Workspace';e={$_.WorkspaceId}} | Format-Table -AutoSize }
    Write-Host 'Confirm no two settings route the SAME categories to this workspace (double billing).'
}
catch { Write-Warning ("Could not read diagnostic settings: {0}" -f $_.Exception.Message) }

Write-Section 'Discovery complete'
Write-Host 'Next: run SENTDEP-Validate.ps1 for pass/fail gates and SENTDEP-Report.ps1 for volume/cost/health.'
