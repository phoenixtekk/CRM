<#
.SYNOPSIS
    MDOFULL-Discovery.ps1 — inventory readiness to operate, enable, and prove Microsoft Defender for Office 365 (read-only).
.DESCRIPTION
    PURPOSE
        Confirms the environment can support the enablement labs and the proof-of-concept before you
        start: whether MDO Plan 2 is present, whether the email advanced-hunting tables have recent
        data, the pilot-user-group membership, and a reminder to confirm the AIR approval posture.
        Read-only — it changes nothing. Prevention-policy CONFIGURATION is the cross-referenced Mail
        Hygiene solution; this only checks that the pieces exist.
    HOW TO RUN
        pwsh -File .\MDOFULL-Discovery.ps1
        pwsh -File .\MDOFULL-Discovery.ps1 -PilotGroup "Grp-MDOFULL-PilotUsers-Pilot" -Environment USGov

        Prereqs: Microsoft.Graph modules; sign in with an MFA-capable account holding at least a
        read/hunt role. Government cloud: pass -Environment and verify endpoints for your cloud.
    EXPECTED RESULTS
        Sections for: Plan 2 licensing presence, email-table freshness, pilot-group membership, and the
        AIR/Action center posture reminder. PASS = the tenant resolves and the inventory completes.
.NOTES
    White-label. Read-only. Microsoft.Graph (security) + KQL via Graph runHuntingQuery. No credentials
    in code. Some attack-simulation Graph endpoints are beta — verify current availability. Table/column
    names and service-plan GUIDs evolve and can differ by cloud (P1/P2, GCC/GCC High) — verify.
#>

[CmdletBinding()]
param(
    [string]   $PilotGroup  = 'Grp-MDOFULL-PilotUsers-Pilot',
    [string]   $Cohort      = 'Grp-MDOFULL-Cohort-Pilot',
    [string[]] $EmailTables = @('EmailEvents','EmailAttachmentInfo','EmailUrlInfo','EmailPostDeliveryEvents','UrlClickInfo'),
    [ValidateSet('Global','USGov','USGovDoD')] [string] $Environment = 'Global'
)

$ErrorActionPreference = 'Stop'
function Write-Section([string] $Title) { Write-Host ''; Write-Host ("=== {0} ===" -f $Title) -ForegroundColor Cyan }

try {
    Connect-MgGraph -Scopes 'Organization.Read.All','Group.Read.All','ThreatHunting.Read.All' -Environment $Environment -NoWelcome -ErrorAction Stop
    Write-Host 'Connected to Microsoft Graph.' -ForegroundColor Green
}
catch { Write-Error ("Failed to connect to Graph: {0}" -f $_.Exception.Message); return }

# --- MDO Plan 2 licensing presence ------------------------------------------------------------------
Write-Section 'Defender for Office 365 Plan 2 — licensing presence'
try {
    # THREAT_INTELLIGENCE / ATP_ENTERPRISE are the service plans historically tied to MDO Plan 2.
    # Verify current service-plan naming/GUIDs in your tenant — Microsoft renames these periodically.
    $subs = Get-MgSubscribedSku -All
    $p2 = $subs | Where-Object { $_.ServicePlans.ServicePlanName -match 'THREAT_INTELLIGENCE|ATP_ENTERPRISE' }
    if ($p2) { Write-Host 'A Plan-2-capable service plan appears present on a subscribed SKU.' -ForegroundColor Green }
    else { Write-Host 'No obvious Plan-2 service plan found — verify licensing (R1) and service-plan naming.' -ForegroundColor Yellow }
}
catch { Write-Warning ("Could not read subscribed SKUs: {0}" -f $_.Exception.Message) }

# --- Email advanced-hunting table freshness ---------------------------------------------------------
Write-Section 'Email advanced-hunting tables — freshness (labs & PoC validation need data)'
foreach ($t in $EmailTables) {
    try {
        $q = "$t | where Timestamp > ago(24h) | count"
        $body = @{ Query = $q } | ConvertTo-Json
        $r = Invoke-MgGraphRequest -Method POST -Uri 'https://graph.microsoft.com/v1.0/security/runHuntingQuery' -Body $body
        $n = if ($r.results) { [int]($r.results[0].Count) } else { 0 }
        if ($n -gt 0) { Write-Host ("  OK:    {0} = {1} rows (24h)." -f $t, $n) -ForegroundColor Green }
        else { Write-Host ("  EMPTY: {0} has no data in 24h — confirm Plan 2 provisioned and mail flowing." -f $t) -ForegroundColor Yellow }
    }
    catch { Write-Host ("  N/A:   {0} — table not present / query failed; verify schema for your cloud." -f $t) -ForegroundColor Yellow }
}

# --- Pilot-user-group and cohort membership ---------------------------------------------------------
foreach ($g in @($PilotGroup, $Cohort)) {
    Write-Section ("Group membership: {0}" -f $g)
    try {
        $grp = Get-MgGroup -Filter "displayName eq '$g'" -ErrorAction Stop
        if (-not $grp) { Write-Host ("  Group '{0}' not found — create it (Step 0.2)." -f $g) -ForegroundColor Yellow }
        else { Write-Host ("  {0} members in {1}." -f @(Get-MgGroupMember -GroupId $grp.Id -All).Count, $g) -ForegroundColor Green }
    }
    catch { Write-Warning ("Could not read group '{0}': {1}" -f $g, $_.Exception.Message) }
}

# --- Prevention baseline reminder (configured elsewhere) --------------------------------------------
Write-Section 'Prevention baseline — must EXIST to inspect and prove against (configured by Mail Hygiene solution)'
Write-Host '  Confirm in the portal: Email & collaboration -> Policies & rules -> Threat policies lists'
Write-Host '  anti-phish / Safe Links / Safe Attachments (or a Preset), scoped to the pilot users (R2).'
Write-Host '  This solution INSPECTS these; configuring them is the Mail Hygiene solution.' -ForegroundColor DarkGray

# --- AIR / Action center posture reminder -----------------------------------------------------------
Write-Section 'AIR / Action center — approval posture (must hold, not auto-apply, during labs and PoC)'
Write-Host '  Confirm in the portal: AIR enabled but recommended actions REQUIRE APPROVAL (Action center -> Pending).'
Write-Host '  (Programmatic read of the automation level varies by API surface — verify current endpoint.)' -ForegroundColor DarkGray

Write-Section 'Discovery complete'
Write-Host 'Next: load MDOFULL-Labs.kql and run the labs (03-implementation.md). Try: MDOFULL-RunLab.ps1 -Lab 5a'
