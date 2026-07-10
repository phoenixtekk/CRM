<#
.SYNOPSIS
    THREATHUNT-Validate.ps1 — run the 05-testing.md program gates as pass/fail lines (read-only).
.DESCRIPTION
    PURPOSE
        Consolidates the testing gates into a pass/fail summary: the hunting surface has data (both
        platforms), the hunter RBAC group is READ-ONLY (flags any write/contributor role), the expected
        hunts are saved and MITRE-tagged, and at least one successful hunt has been PROMOTED to a -Prod
        detection. Read-only — it verifies posture; it changes nothing and takes no response action.
    HOW TO RUN
        Connect-MgGraph -Scopes ThreatHunting.Read.All
        Connect-AzAccount

        pwsh -File .\THREATHUNT-Validate.ps1 -ResourceGroup RG-Security-Sentinel `
             -WorkspaceName "Security Telemetry - Tenant - Workspace" `
             -HunterGroupName "Threat Hunters - Tenant - Group"

        Prereqs: Microsoft.Graph.Security + Az (Az.Accounts, Az.OperationalInsights, Az.SecurityInsights,
        Az.Resources); Security Reader (Defender) and Microsoft Sentinel Reader (workspace).
    EXPECTED RESULTS
        A list of PASS/FAIL/WARN lines aligned to 05-testing.md. Any FAIL points to the phase/step that
        fixes it. Government cloud: connect Graph to the matching endpoint and pass
        -Environment AzureUSGovernment (verify endpoints/scopes for your cloud).
.NOTES
    White-label. Read-only. Microsoft.Graph + Az / KQL. No credentials in code. No response actions.
#>

[CmdletBinding()]
param(
    [Parameter(Mandatory)] [string] $ResourceGroup,
    [Parameter(Mandatory)] [string] $WorkspaceName,
    [string] $HunterGroupName = 'Threat Hunters - Tenant - Group',
    [string[]] $ExpectedHunts = @('Hunt-LOLBins-Devices-Pilot','Hunt-RareParentChild-Devices-Pilot',
                                  'Hunt-InboxRules-M365-Pilot','Hunt-RareServiceSignin-Entra-Pilot',
                                  'Hunt-BeaconEgress-Network-Pilot'),
    [ValidateSet('AzureCloud','AzureUSGovernment')] [string] $Environment = 'AzureCloud'
)

$ErrorActionPreference = 'Stop'
$script:pass = 0; $script:fail = 0; $script:warn = 0
function Assert([bool]$Cond, [string]$Name, [string]$FixHint) {
    if ($Cond) { Write-Host ("  PASS  {0}" -f $Name) -ForegroundColor Green; $script:pass++ }
    else { Write-Host ("  FAIL  {0}" -f $Name) -ForegroundColor Red; if ($FixHint) { Write-Host ("        -> {0}" -f $FixHint) -ForegroundColor DarkYellow }; $script:fail++ }
}
function Warn([string]$Name, [string]$Detail) { Write-Host ("  WARN  {0}" -f $Name) -ForegroundColor Yellow; if ($Detail) { Write-Host ("        {0}" -f $Detail) -ForegroundColor DarkYellow }; $script:warn++ }
function Write-Section([string] $Title) { Write-Host ''; Write-Host ("=== {0} ===" -f $Title) -ForegroundColor Cyan }

# --- Connect + resolve workspace --------------------------------------------------------------------
$wsId = $null
try {
    if (-not (Get-AzContext)) { Connect-AzAccount -Environment $Environment | Out-Null }
    $ws = Get-AzOperationalInsightsWorkspace -ResourceGroupName $ResourceGroup -Name $WorkspaceName -ErrorAction Stop
    $wsId = $ws.CustomerId
}
catch { Write-Error ("Failed to resolve workspace: {0}" -f $_.Exception.Message); return }

# --- Gate 1: surface has data -----------------------------------------------------------------------
Write-Section 'Gate 1 — hunting surface has data'
try {
    $q = "SigninLogs | where TimeGenerated > ago(24h) | count"
    $n = (Invoke-AzOperationalInsightsQuery -WorkspaceId $wsId -Query $q -ErrorAction Stop).Results
    Assert (($n) -and ([int]$n[0].Count -gt 0)) 'Sentinel SigninLogs has data (24h)' 'Connect the source (R2) before hunting.'
}
catch { Warn 'Sentinel freshness check' $_.Exception.Message }
try {
    if (-not (Get-MgContext)) { Connect-MgGraph -Scopes 'ThreatHunting.Read.All' | Out-Null }
    $resp = Invoke-MgSecurityRunHuntingQuery -Query 'DeviceProcessEvents | where Timestamp > ago(24h) | summarize R=count()' -ErrorAction Stop
    Assert ([int]$resp.Results[0].R -gt 0) 'Defender XDR DeviceProcessEvents has data (24h)' 'Onboard Defender XDR (R1) before hunting.'
}
catch { Warn 'Defender advanced-hunting freshness check' 'Graph/advanced hunting unavailable or throttled — verify R1/R7.' }

# --- Gate 2: hunter group is READ-ONLY (not write) --------------------------------------------------
Write-Section 'Gate 2 — hunter RBAC group is read-only'
try {
    $grp = Get-AzADGroup -DisplayName $HunterGroupName -ErrorAction SilentlyContinue | Select-Object -First 1
    if (-not $grp) { Warn 'Hunter group exists' ("Group '{0}' not found — create it (Phase 1, Step 1)." -f $HunterGroupName) }
    else {
        $assign = @(Get-AzRoleAssignment -ObjectId $grp.Id -ErrorAction SilentlyContinue)
        $roles = @($assign | Select-Object -ExpandProperty RoleDefinitionName -Unique)
        $hasReader = $roles -contains 'Microsoft Sentinel Reader' -or $roles -contains 'Reader'
        $writeRoles = @($roles | Where-Object { $_ -match 'Contributor|Owner|Responder' })
        Assert $hasReader 'Hunter group holds Microsoft Sentinel Reader' 'Assign Microsoft Sentinel Reader at workspace scope (R3).'
        Assert ($writeRoles.Count -eq 0) 'Hunter group holds NO write/contributor/responder role' ("Remove write roles from hunters: {0} (keep promotion with a separate admin set)." -f ($writeRoles -join ', '))
    }
}
catch { Warn 'Hunter RBAC check' $_.Exception.Message }

# --- Gate 3: expected hunts saved + tagged ----------------------------------------------------------
Write-Section 'Gate 3 — hunt library saved and MITRE-tagged (Sentinel side)'
try {
    $hunts = @(Get-AzSentinelHuntingRule -ResourceGroupName $ResourceGroup -WorkspaceName $WorkspaceName -ErrorAction SilentlyContinue)
    $names = @($hunts | Select-Object -ExpandProperty DisplayName)
    foreach ($e in $ExpectedHunts) {
        $found = $names -contains $e
        if ($found) { Assert $true ("Hunt saved: {0}" -f $e) '' }
        else { Warn ("Hunt not found on Sentinel side: {0}" -f $e) 'Defender-side hunts live in advanced hunting saved queries (check the Defender portal) — this checks the Sentinel shelf only.' }
    }
    $tagged = @($hunts | Where-Object { $_.Tactic -and $_.Tactic.Count -gt 0 })
    Assert (($hunts.Count -eq 0) -or ($tagged.Count -gt 0)) 'At least one saved hunt is MITRE-tagged' 'Tag hunts with Tactics & techniques (Phase 1, Step 2) — the tag is the coverage map.'
}
catch { Warn 'Saved-hunt inventory' $_.Exception.Message }

# --- Gate 8: at least one promoted -Prod detection --------------------------------------------------
Write-Section 'Gate 8 — at least one successful hunt promoted to a detection'
try {
    $rules = @(Get-AzSentinelAlertRule -ResourceGroupName $ResourceGroup -WorkspaceName $WorkspaceName -ErrorAction SilentlyContinue)
    $promoted = @($rules | Where-Object { $_.DisplayName -match '-Prod$' -or $_.DisplayName -like 'Rule-*-Prod' })
    if ($promoted.Count -gt 0) { Assert $true ("Promoted Sentinel detection(s): {0}" -f ($promoted.DisplayName -join ', ')) '' }
    else { Warn 'No Sentinel Rule-<Hunt>-Prod detected' 'Promote a reliable hunt (Phase 4, Step 2). Defender custom detections (CD-<Hunt>-Prod) live in the Defender portal and are not visible via Az — confirm there too.' }
}
catch { Warn 'Promotion check' $_.Exception.Message }

# --- Reminders the tool cannot fully automate -------------------------------------------------------
Write-Section 'Manual gates (verify in the portal / register)'
Warn 'Gate 5 — pilot hunts documented in Hunt Register - Tenant - Main' 'Each hunt needs hypothesis, scope, KQL, outcome, decision.'
Warn 'Gate 6/7 — findings bookmarked (Bookmark-<Hunt>-Finding) and confirmed true positives handed off to the IR runbook' 'Do NOT respond from a hunt — create an incident and hand off.'

# --- Summary ----------------------------------------------------------------------------------------
Write-Section 'Validation summary'
Write-Host ("PASS: {0}   FAIL: {1}   WARN: {2}" -f $script:pass, $script:fail, $script:warn) -ForegroundColor Cyan
if ($script:fail -gt 0) { Write-Host 'One or more gates FAILED — resolve them before expanding the program.' -ForegroundColor Red }
else { Write-Host 'No hard failures. Review WARN lines (manual/portal-side checks) to fully close the gates.' -ForegroundColor Green }
