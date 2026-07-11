<#
.SYNOPSIS
    WSKQL-Discovery.ps1 — inventory workshop readiness for Advanced KQL for SecOps (read-only).
.DESCRIPTION
    PURPOSE
        Confirms the environment can support the labs before the cohort arrives: which Defender XDR
        advanced-hunting tables have recent data, whether a Microsoft Sentinel / Log Analytics
        workspace is reachable for the cross-tool labs, and the learner cohort-group membership.
        Read-only — it changes nothing.
    HOW TO RUN
        pwsh -File .\WSKQL-Discovery.ps1
        pwsh -File .\WSKQL-Discovery.ps1 -Cohort "Grp-KQLWorkshop-Cohort" -Environment USGov

        Prereqs: Microsoft.Graph modules; sign in with an MFA-capable account holding at least a
        read/hunt role (e.g. Security Reader + hunting, or Security Operator). Government cloud: pass
        -Environment (USGov / USGovDoD) and verify endpoints for your cloud.
    EXPECTED RESULTS
        Sections for: Defender XDR table freshness, Sentinel workspace reachability (informational),
        and cohort membership. PASS = the tenant resolves and the inventory completes without error.
.NOTES
    White-label. Read-only. Microsoft.Graph (security) + KQL via Graph runHuntingQuery. Sentinel
    reachability is a manual/portal check where the Az path is unavailable. No credentials in code.
#>

[CmdletBinding()]
param(
    [string]   $Cohort = 'Grp-KQLWorkshop-Cohort',
    [string[]] $Tables = @('DeviceProcessEvents','DeviceNetworkEvents','IdentityLogonEvents','EmailEvents','AlertEvidence'),
    [ValidateSet('Global','USGov','USGovDoD')] [string] $Environment = 'Global'
)

$ErrorActionPreference = 'Stop'
function Write-Section([string] $Title) { Write-Host ''; Write-Host ("=== {0} ===" -f $Title) -ForegroundColor Cyan }

# --- Connect (interactive; least-privilege read/hunt scopes) ----------------------------------------
try {
    Connect-MgGraph -Scopes 'ThreatHunting.Read.All','Group.Read.All','Organization.Read.All' `
        -Environment $Environment -NoWelcome -ErrorAction Stop
    Write-Host 'Connected to Microsoft Graph.' -ForegroundColor Green
}
catch { Write-Error ("Failed to connect to Graph: {0}" -f $_.Exception.Message); return }

# --- Defender XDR advanced-hunting table freshness --------------------------------------------------
Write-Section 'Defender XDR advanced-hunting tables — freshness (labs need data to hunt on)'
foreach ($t in $Tables) {
    try {
        $q = "$t | where Timestamp > ago(24h) | count"
        $body = @{ Query = $q } | ConvertTo-Json
        $r = Invoke-MgGraphRequest -Method POST -Uri 'https://graph.microsoft.com/v1.0/security/runHuntingQuery' -Body $body
        $n = if ($r.results) { [int]($r.results[0].Count) } else { 0 }
        if ($n -gt 0) { Write-Host ("  OK:    {0} = {1} rows (24h) — usable in labs." -f $t, $n) -ForegroundColor Green }
        else { Write-Host ("  EMPTY: {0} has no data in 24h — onboard the pillar or run labs on a live table." -f $t) -ForegroundColor Yellow }
    }
    catch { Write-Host ("  N/A:   {0} — table not present / query failed; verify schema for your cloud." -f $t) -ForegroundColor Yellow }
}

# --- Sentinel workspace reachability (informational) ------------------------------------------------
Write-Section 'Microsoft Sentinel workspace — reachability (for the cross-tool labs, R3)'
Write-Host '  The Sentinel labs run KQL against a Log Analytics workspace (SigninLogs, SecurityEvent, ...).'
Write-Host '  Verify in the portal: Sentinel -> Logs -> run  SigninLogs | where TimeGenerated > ago(24h) | count'
Write-Host '  If no workspace exists, run the Defender-only labs in full and defer Lab 5b (see R3).' -ForegroundColor DarkGray

# --- Cohort membership ------------------------------------------------------------------------------
Write-Section ("Learner cohort membership: {0}" -f $Cohort)
try {
    $grp = Get-MgGroup -Filter "displayName eq '$Cohort'" -ErrorAction Stop
    if (-not $grp) { Write-Host ("  Group '{0}' not found — create it (Step 0.2)." -f $Cohort) -ForegroundColor Yellow }
    else {
        $members = Get-MgGroupMember -GroupId $grp.Id -All
        Write-Host ("  {0} learners in {1}." -f $members.Count, $Cohort) -ForegroundColor Green
    }
}
catch { Write-Warning ("Could not read cohort group: {0}" -f $_.Exception.Message) }

Write-Section 'Discovery complete'
Write-Host 'Next: load WSKQL-Labs.kql and run the labs (03-implementation.md). Try: WSKQL-RunLab.ps1 -Lab 1'
