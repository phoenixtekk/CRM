<#
.SYNOPSIS
    THREATHUNT-Discovery.ps1 — inventory the hunting surface across Defender XDR and Sentinel (read-only).
.DESCRIPTION
    PURPOSE
        Establishes reality before hunting: which Defender XDR advanced-hunting tables and which Sentinel
        workspace tables have recent data, plus the existing Sentinel hunt queries, bookmarks, and custom
        detection rules. Read-only — it changes nothing and takes no response action.
    HOW TO RUN
        # Defender XDR side (advanced hunting via Microsoft Graph):
        Connect-MgGraph -Scopes ThreatHunting.Read.All
        # Sentinel side (Az):
        Connect-AzAccount

        pwsh -File .\THREATHUNT-Discovery.ps1 -ResourceGroup RG-Security-Sentinel `
             -WorkspaceName "Security Telemetry - Tenant - Workspace"

        Prereqs: Microsoft.Graph.Security + Az (Az.Accounts, Az.OperationalInsights, Az.SecurityInsights);
        Security Reader (Defender) and Microsoft Sentinel Reader (workspace). Sign in with an MFA-capable
        admin. Government cloud: connect Graph to the matching national-cloud endpoint and pass
        -Environment AzureUSGovernment (verify endpoints/scopes for your cloud).
    EXPECTED RESULTS
        Freshness tables for expected advanced-hunting and Sentinel tables, plus lists of existing hunt
        queries, bookmarks, and custom detection rules. PASS = both platforms resolve and the inventory
        completes without error.
.NOTES
    White-label. Read-only. Microsoft.Graph (runHuntingQuery) + Az / KQL. No credentials in code.
    No response actions.
#>

[CmdletBinding()]
param(
    [Parameter(Mandatory)] [string] $ResourceGroup,
    [Parameter(Mandatory)] [string] $WorkspaceName,
    [string[]] $AdvancedHuntingTables = @('DeviceProcessEvents','DeviceNetworkEvents','DeviceFileEvents',
                                          'IdentityLogonEvents','EmailEvents','CloudAppEvents','AlertEvidence'),
    [string[]] $SentinelTables = @('SigninLogs','AuditLogs','OfficeActivity','CommonSecurityLog','SecurityAlert'),
    [ValidateSet('AzureCloud','AzureUSGovernment')] [string] $Environment = 'AzureCloud'
)

$ErrorActionPreference = 'Stop'
function Write-Section([string] $Title) { Write-Host ''; Write-Host ("=== {0} ===" -f $Title) -ForegroundColor Cyan }

# --- Defender XDR advanced-hunting freshness (via Graph runHuntingQuery) -----------------------------
Write-Section 'Defender XDR advanced-hunting table freshness (via Graph runHuntingQuery)'
try {
    if (-not (Get-MgContext)) { Connect-MgGraph -Scopes 'ThreatHunting.Read.All' | Out-Null }
    foreach ($t in $AdvancedHuntingTables) {
        try {
            $kql  = "$t | where Timestamp > ago(24h) | summarize Rows = count()"
            $resp = Invoke-MgSecurityRunHuntingQuery -Query $kql -ErrorAction Stop
            $rows = [int]($resp.Results[0].Rows)
            if ($rows -gt 0) { Write-Host ("  OK: {0} = {1} rows (24h)." -f $t, $rows) -ForegroundColor Green }
            else { Write-Host ("  EMPTY: {0} has no data in 24h — do not hunt it yet." -f $t) -ForegroundColor Red }
        }
        catch { Write-Host ("  {0}: query failed / table absent (onboard the workload, or verify schema)." -f $t) -ForegroundColor Yellow }
    }
}
catch { Write-Warning ("Graph / advanced hunting unavailable: {0}" -f $_.Exception.Message) }

# --- Sentinel workspace + table freshness -----------------------------------------------------------
Write-Section 'Sentinel workspace table freshness'
$wsId = $null
try {
    if (-not (Get-AzContext)) { Connect-AzAccount -Environment $Environment | Out-Null }
    $ws = Get-AzOperationalInsightsWorkspace -ResourceGroupName $ResourceGroup -Name $WorkspaceName -ErrorAction Stop
    $wsId = $ws.CustomerId
    Write-Host ("Workspace resolved: {0}" -f $WorkspaceName) -ForegroundColor Green
    foreach ($t in $SentinelTables) {
        try {
            $q = "$t | where TimeGenerated > ago(24h) | count"
            $r = (Invoke-AzOperationalInsightsQuery -WorkspaceId $wsId -Query $q -ErrorAction Stop).Results
            $n = if ($r) { [int]$r[0].Count } else { 0 }
            if ($n -gt 0) { Write-Host ("  OK: {0} = {1} rows (24h)." -f $t, $n) -ForegroundColor Green }
            else { Write-Host ("  EMPTY: {0} has no data in 24h — connect the source first." -f $t) -ForegroundColor Red }
        }
        catch { Write-Host ("  {0}: not present / query failed." -f $t) -ForegroundColor Yellow }
    }
}
catch { Write-Warning ("Failed to resolve workspace: {0}" -f $_.Exception.Message) }

# --- Existing Sentinel hunt queries -----------------------------------------------------------------
Write-Section 'Existing Sentinel hunt (saved) queries'
try {
    $hunts = @(Get-AzSentinelHuntingRule -ResourceGroupName $ResourceGroup -WorkspaceName $WorkspaceName -ErrorAction SilentlyContinue)
    if ($hunts.Count -eq 0) { Write-Host 'No saved hunt queries — import Hunt Library - Tenant - Main (Phase 1, Step 2).' -ForegroundColor Yellow }
    else { $hunts | Select-Object DisplayName, @{n='Tactics';e={ ($_.Tactic -join ',') }} | Sort-Object DisplayName | Format-Table -AutoSize }
    Write-Host 'Expected pilot hunts: Hunt-LOLBins-Devices-Pilot, Hunt-RareParentChild-Devices-Pilot, Hunt-InboxRules-M365-Pilot, Hunt-RareServiceSignin-Entra-Pilot, Hunt-BeaconEgress-Network-Pilot.'
}
catch { Write-Warning ("Could not enumerate hunt queries: {0}" -f $_.Exception.Message) }

# --- Existing bookmarks (evidence of prior findings) ------------------------------------------------
Write-Section 'Existing bookmarks (preserved findings)'
try {
    $bm = @(Get-AzSentinelBookmark -ResourceGroupName $ResourceGroup -WorkspaceName $WorkspaceName -ErrorAction SilentlyContinue)
    if ($bm.Count -eq 0) { Write-Host 'No bookmarks yet — findings are preserved as Bookmark-<Hunt>-Finding (Phase 2, Step 5).' -ForegroundColor Yellow }
    else { $bm | Select-Object DisplayName, Created | Sort-Object Created -Descending | Format-Table -AutoSize }
}
catch { Write-Warning ("Could not enumerate bookmarks: {0}" -f $_.Exception.Message) }

# --- Existing analytics rules (promotion targets already in place) ----------------------------------
Write-Section 'Existing analytics rules (promoted detections would appear here as Rule-<Hunt>-Prod)'
try {
    $rules = @(Get-AzSentinelAlertRule -ResourceGroupName $ResourceGroup -WorkspaceName $WorkspaceName -ErrorAction SilentlyContinue)
    if ($rules.Count -eq 0) { Write-Host 'No analytics rules yet.' -ForegroundColor Yellow }
    else { Write-Host ("Analytics rules present: {0}. Custom detection rules live in the Defender portal (Hunting -> Custom detection rules)." -f $rules.Count) }
}
catch { Write-Warning ("Could not enumerate analytics rules: {0}" -f $_.Exception.Message) }

Write-Section 'Discovery complete'
Write-Host 'Next: THREATHUNT-RunHuntLibrary.ps1 to execute the library read-only, then triage + document per 03-implementation.md.'
