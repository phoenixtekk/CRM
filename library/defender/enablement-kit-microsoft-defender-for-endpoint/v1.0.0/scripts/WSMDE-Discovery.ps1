<#
.SYNOPSIS
    WSMDE-Discovery.ps1 — inventory workshop readiness for Microsoft Defender for Endpoint (read-only).
.DESCRIPTION
    PURPOSE
        Confirms the environment can support the labs before the cohort arrives: how many devices are
        onboarded and reporting, whether the endpoint advanced-hunting tables have recent data, and the
        learner cohort membership. Live Response / advanced-feature enablement is surfaced as a portal
        check. Read-only — it changes nothing.
    HOW TO RUN
        pwsh -File .\WSMDE-Discovery.ps1
        pwsh -File .\WSMDE-Discovery.ps1 -Cohort "Grp-MDEWorkshop-Cohort" -Environment USGov

        Prereqs: Microsoft.Graph modules; sign in with an MFA-capable account holding at least a
        read/hunt role. Government cloud: pass -Environment and verify endpoints for your cloud.
    EXPECTED RESULTS
        Sections for: onboarded device count, endpoint-table freshness, Live Response / advanced-feature
        reminder, and cohort membership. PASS = the tenant resolves and the inventory completes.
.NOTES
    White-label. Read-only. Microsoft.Graph (security) + KQL via Graph runHuntingQuery. No credentials
    in code.
#>

[CmdletBinding()]
param(
    [string]   $Cohort = 'Grp-MDEWorkshop-Cohort',
    [string[]] $Tables = @('DeviceProcessEvents','DeviceNetworkEvents','DeviceFileEvents','DeviceLogonEvents','DeviceEvents'),
    [ValidateSet('Global','USGov','USGovDoD')] [string] $Environment = 'Global'
)

$ErrorActionPreference = 'Stop'
function Write-Section([string] $Title) { Write-Host ''; Write-Host ("=== {0} ===" -f $Title) -ForegroundColor Cyan }

try {
    Connect-MgGraph -Scopes 'ThreatHunting.Read.All','Group.Read.All' -Environment $Environment -NoWelcome -ErrorAction Stop
    Write-Host 'Connected to Microsoft Graph.' -ForegroundColor Green
}
catch { Write-Error ("Failed to connect to Graph: {0}" -f $_.Exception.Message); return }

# --- Onboarded device count (via DeviceInfo) --------------------------------------------------------
Write-Section 'Onboarded devices (labs need real device telemetry)'
try {
    $q = "DeviceInfo | where Timestamp > ago(24h) | summarize by DeviceId | count"
    $body = @{ Query = $q } | ConvertTo-Json
    $r = Invoke-MgGraphRequest -Method POST -Uri 'https://graph.microsoft.com/v1.0/security/runHuntingQuery' -Body $body
    $n = if ($r.results) { [int]($r.results[0].Count) } else { 0 }
    if ($n -gt 0) { Write-Host ("  OK: {0} devices seen in DeviceInfo (24h)." -f $n) -ForegroundColor Green }
    else { Write-Host '  No devices seen in 24h — onboard devices (MDE onboarding accelerator, R1).' -ForegroundColor Yellow }
}
catch { Write-Host '  DeviceInfo query failed — verify schema / onboarding for your tenant.' -ForegroundColor Yellow }

# --- Endpoint table freshness -----------------------------------------------------------------------
Write-Section 'Endpoint advanced-hunting tables — freshness'
foreach ($t in $Tables) {
    try {
        $q = "$t | where Timestamp > ago(24h) | count"
        $body = @{ Query = $q } | ConvertTo-Json
        $r = Invoke-MgGraphRequest -Method POST -Uri 'https://graph.microsoft.com/v1.0/security/runHuntingQuery' -Body $body
        $n = if ($r.results) { [int]($r.results[0].Count) } else { 0 }
        if ($n -gt 0) { Write-Host ("  OK:    {0} = {1} rows (24h)." -f $t, $n) -ForegroundColor Green }
        else { Write-Host ("  EMPTY: {0} has no data in 24h." -f $t) -ForegroundColor Yellow }
    }
    catch { Write-Host ("  N/A:   {0} — table not present / query failed; verify schema/plan." -f $t) -ForegroundColor Yellow }
}

# --- Live Response / advanced features reminder (portal check) --------------------------------------
Write-Section 'Live Response & advanced features (P2) — portal check'
Write-Host '  Confirm in: Settings -> Endpoints -> Advanced features -> Live Response = On.'
Write-Host '  EDR, advanced hunting, Live Response, and custom detections require Defender for Endpoint Plan 2 (verify).' -ForegroundColor DarkGray

# --- Cohort membership ------------------------------------------------------------------------------
Write-Section ("Learner cohort membership: {0}" -f $Cohort)
try {
    $grp = Get-MgGroup -Filter "displayName eq '$Cohort'" -ErrorAction Stop
    if (-not $grp) { Write-Host ("  Group '{0}' not found — create it (Step 0.2)." -f $Cohort) -ForegroundColor Yellow }
    else { Write-Host ("  {0} learners in {1}." -f @(Get-MgGroupMember -GroupId $grp.Id -All).Count, $Cohort) -ForegroundColor Green }
}
catch { Write-Warning ("Could not read cohort group: {0}" -f $_.Exception.Message) }

Write-Section 'Discovery complete'
Write-Host 'Next: load WSMDE-Labs.kql and run the labs (03-implementation.md). Try: WSMDE-RunLab.ps1 -Lab 1'
