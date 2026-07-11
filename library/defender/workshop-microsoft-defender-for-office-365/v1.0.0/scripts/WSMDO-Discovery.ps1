<#
.SYNOPSIS
    WSMDO-Discovery.ps1 — inventory workshop readiness for Microsoft Defender for Office 365 (read-only).
.DESCRIPTION
    PURPOSE
        Confirms the environment can support the labs before the cohort arrives: whether MDO Plan 2 is
        present, whether the email advanced-hunting tables have recent data, the lab-user-group
        membership, and a reminder to confirm the AIR approval posture. Read-only — it changes nothing.
    HOW TO RUN
        pwsh -File .\WSMDO-Discovery.ps1
        pwsh -File .\WSMDO-Discovery.ps1 -LabGroup "Grp-MDO-LabUsers-Pilot" -Environment USGov

        Prereqs: Microsoft.Graph modules; sign in with an MFA-capable account holding at least a
        read/hunt role. Government cloud: pass -Environment and verify endpoints for your cloud.
    EXPECTED RESULTS
        Sections for: Plan 2 licensing presence, email-table freshness, lab-group membership, and the
        AIR/Action center posture reminder. PASS = the tenant resolves and the inventory completes.
.NOTES
    White-label. Read-only. Microsoft.Graph (security) + KQL via Graph runHuntingQuery. No credentials
    in code. Some attack-simulation Graph endpoints are beta — verify current availability.
#>

[CmdletBinding()]
param(
    [string]   $LabGroup = 'Grp-MDO-LabUsers-Pilot',
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
Write-Section 'Email advanced-hunting tables — freshness (labs need data to hunt on)'
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

# --- Lab-user-group membership ----------------------------------------------------------------------
Write-Section ("Lab user group membership: {0}" -f $LabGroup)
try {
    $grp = Get-MgGroup -Filter "displayName eq '$LabGroup'" -ErrorAction Stop
    if (-not $grp) { Write-Host ("  Group '{0}' not found — create it (Step 0.2)." -f $LabGroup) -ForegroundColor Yellow }
    else { Write-Host ("  {0} members in {1}." -f @(Get-MgGroupMember -GroupId $grp.Id -All).Count, $LabGroup) -ForegroundColor Green }
}
catch { Write-Warning ("Could not read lab group: {0}" -f $_.Exception.Message) }

# --- AIR / Action center posture reminder -----------------------------------------------------------
Write-Section 'AIR / Action center — approval posture (must hold, not auto-apply, during the workshop)'
Write-Host '  Confirm in the portal: AIR enabled but recommended actions REQUIRE APPROVAL (Action center -> Pending).'
Write-Host '  (Programmatic read of the automation level varies by API surface — verify current endpoint.)' -ForegroundColor DarkGray

Write-Section 'Discovery complete'
Write-Host 'Next: load WSMDO-Labs.kql and run the labs (03-implementation.md). Try: WSMDO-RunLab.ps1 -Lab 5'
