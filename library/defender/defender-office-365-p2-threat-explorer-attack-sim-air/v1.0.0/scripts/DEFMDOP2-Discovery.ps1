<#
.SYNOPSIS
    DEFMDOP2-Discovery.ps1 — inventory Defender for Office 365 Plan 2 readiness for post-delivery detect/hunt/simulate/respond (read-only).
.DESCRIPTION
    PURPOSE
        Inventories the post-delivery readiness so the build starts from reality: whether the
        Defender for Office 365 Plan 2 service plan is assigned, whether the email Advanced Hunting
        tables have recent data, the current pilot-group membership, and how many actions are already
        pending in the Action center. Read-only — it changes nothing.
    HOW TO RUN
        pwsh -File .\DEFMDOP2-Discovery.ps1 -PilotGroup "Grp-MDO-Pilot-Users"

        Prereqs: Microsoft.Graph modules and (optionally) ExchangeOnlineManagement; sign in with an
        MFA-capable admin holding at least Security Reader. Government cloud: pass -Environment
        (e.g. USGov / USGovDoD) and verify endpoints for your cloud. Some attack-simulation Graph
        endpoints are beta — verify current availability.
    EXPECTED RESULTS
        Sections for: Plan 2 licensing presence, email-table freshness (EmailEvents etc.),
        pilot-group membership, and pending Action center count. PASS = the tenant resolves and the
        inventory completes without error.
.NOTES
    White-label. Read-only. Microsoft.Graph (security) + Exchange Online / Security & Compliance. KQL
    via Graph runHuntingQuery. No credentials in code.
#>

[CmdletBinding()]
param(
    [string] $PilotGroup = 'Grp-MDO-Pilot-Users',
    [string[]] $EmailTables = @('EmailEvents','EmailAttachmentInfo','EmailUrlInfo','EmailPostDeliveryEvents','UrlClickInfo'),
    [ValidateSet('Global','USGov','USGovDoD')] [string] $Environment = 'Global'
)

$ErrorActionPreference = 'Stop'
function Write-Section([string] $Title) { Write-Host ''; Write-Host ("=== {0} ===" -f $Title) -ForegroundColor Cyan }

# --- Connect (interactive; least-privilege scopes) --------------------------------------------------
try {
    Connect-MgGraph -Scopes 'Organization.Read.All','Group.Read.All','ThreatHunting.Read.All','SecurityEvents.Read.All' `
        -Environment $Environment -NoWelcome -ErrorAction Stop
    Write-Host 'Connected to Microsoft Graph.' -ForegroundColor Green
}
catch { Write-Error ("Failed to connect to Graph: {0}" -f $_.Exception.Message); return }

# --- Plan 2 licensing presence ----------------------------------------------------------------------
Write-Section 'Defender for Office 365 Plan 2 — licensing presence'
try {
    # THREAT_INTELLIGENCE is the service plan historically associated with MDO Plan 2. Verify current
    # service-plan naming/GUIDs in your tenant — Microsoft renames these periodically.
    $subs = Get-MgSubscribedSku -All
    $p2 = $subs | Where-Object { $_.ServicePlans.ServicePlanName -match 'THREAT_INTELLIGENCE|ATP_ENTERPRISE|Defender.*Office.*Plan.*2' }
    if ($p2) {
        Write-Host 'A Plan-2-capable service plan appears present on a subscribed SKU:' -ForegroundColor Green
        $p2 | Select-Object SkuPartNumber,
            @{n='ConsumedUnits';e={$_.ConsumedUnits}},
            @{n='Enabled';e={$_.PrepaidUnits.Enabled}} | Format-Table -AutoSize
    }
    else { Write-Host 'No obvious Plan-2 service plan found — verify licensing (R1) and service-plan naming.' -ForegroundColor Yellow }
}
catch { Write-Warning ("Could not read subscribed SKUs: {0}" -f $_.Exception.Message) }

# --- Email Advanced Hunting table freshness ---------------------------------------------------------
Write-Section 'Email Advanced Hunting tables — freshness (rules/hunts can only find what is present)'
foreach ($t in $EmailTables) {
    try {
        $q = "$t | where Timestamp > ago(24h) | count"
        $body = @{ Query = $q }
        $r = Invoke-MgGraphRequest -Method POST -Uri 'https://graph.microsoft.com/v1.0/security/runHuntingQuery' -Body ($body | ConvertTo-Json)
        $n = if ($r.results) { [int]($r.results[0].Count) } else { 0 }
        if ($n -gt 0) { Write-Host ("  OK: {0} = {1} rows (24h)." -f $t, $n) -ForegroundColor Green }
        else { Write-Host ("  EMPTY: {0} has no data in 24h — confirm Plan 2 provisioned and mail flowing." -f $t) -ForegroundColor Red }
    }
    catch { Write-Host ("  {0}: query failed / table not present — verify schema for your tenant/cloud." -f $t) -ForegroundColor Yellow }
}

# --- Pilot group membership -------------------------------------------------------------------------
Write-Section ("Pilot group membership: {0}" -f $PilotGroup)
try {
    $grp = Get-MgGroup -Filter "displayName eq '$PilotGroup'" -ErrorAction Stop
    if (-not $grp) { Write-Host ("  Group '{0}' not found — create it (Step 1.1)." -f $PilotGroup) -ForegroundColor Yellow }
    else {
        $members = Get-MgGroupMember -GroupId $grp.Id -All
        Write-Host ("  {0} members in {1}." -f $members.Count, $PilotGroup) -ForegroundColor Green
    }
}
catch { Write-Warning ("Could not read pilot group: {0}" -f $_.Exception.Message) }

# --- Pending Action center actions (approval posture signal) ----------------------------------------
Write-Section 'Action center — pending actions (should hold, not auto-apply, during pilot)'
Write-Host '  Review Actions & submissions -> Action center -> Pending in the portal.'
Write-Host '  A healthy pilot shows AIR-recommended actions PENDING (approval-required), not applied.'
Write-Host '  (Programmatic read of pending actions varies by API surface — verify current endpoint.)' -ForegroundColor DarkGray

Write-Section 'Discovery complete'
Write-Host 'Next: DEFMDOP2-Hunt.ps1 (run the KQL library), then configure per 03-implementation.md.'
