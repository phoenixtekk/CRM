<#
.SYNOPSIS
    MCAONB-Validate.ps1 — targeted validation of Defender for Cloud Apps onboarding
    (app connectors, Cloud Discovery flow, session/access policy scope and posture).
.DESCRIPTION
    PURPOSE
        Read-only validation for the "Onboarding Accelerator — Microsoft Defender for Cloud Apps"
        solution. Confirms the piece named by -Check: connectors connected, Cloud Discovery flowing,
        or the session/access policies report-only and scoped to the pilot group. Maps to the
        Testing Guide gates.
    HOW TO RUN
        powershell -ExecutionPolicy Bypass -File .\MCAONB-Validate.ps1 -Check Policy
        -Check accepts: Connectors | Discovery | Policy | All (default All).
        Uses Microsoft.Graph.Authentication and Graph Security. Reads only; makes no changes.
    EXPECTED RESULTS
        PASS/REVIEW lines per check with the object names from the Implementation Guide, so you can
        confirm each Testing Guide gate before enforcing or expanding beyond the pilot.
.NOTES
    White-label. Read-only. Where a setting is portal-only, the script prints the exact path to
    confirm manually. Policies must stay report-only until validated.
#>
[CmdletBinding()]
param(
    [ValidateSet('Connectors','Discovery','Policy','All')] [string]$Check = 'All',
    [string]$PilotGroup = 'MDCA Pilot Users - Pilot Ring - Pilot'
)

Import-Module Microsoft.Graph.Authentication -ErrorAction Stop
if (-not (Get-MgContext)) { Connect-MgGraph -Scopes 'SecurityEvents.Read.All','ThreatHunting.Read.All','Policy.Read.All' -NoWelcome | Out-Null }
Write-Host "`n=== Defender for Cloud Apps — validation ($Check) ===" -ForegroundColor Cyan

function Test-Connectors {
    Write-Host "`n[Connectors] 'MDCA App Connectors - Priority SaaS - Prod'" -ForegroundColor Cyan
    Write-Host "   Confirm in: Cloud apps > Connected apps > App connectors — each shows 'Connected'." -ForegroundColor DarkGray
    Write-Host "   REVIEW: Microsoft 365 first, then priority third-party apps." -ForegroundColor Yellow
}
function Test-Discovery {
    Write-Host "`n[Discovery] Cloud Discovery source" -ForegroundColor Cyan
    Write-Host "   Confirm in: Cloud apps > Cloud discovery > Dashboard — discovered apps/traffic visible." -ForegroundColor DarkGray
    Write-Host "   REVIEW: source = MDE integration / log collector / SWG." -ForegroundColor Yellow
}
function Test-Policy {
    Write-Host "`n[Policy] 'MDCA Session Control - Pilot Users - Report' / 'MDCA Access Control - Pilot Users - Report'" -ForegroundColor Cyan
    try {
        $grp = (Invoke-MgGraphRequest -Method GET -Uri ("https://graph.microsoft.com/v1.0/groups?`$filter=displayName eq '{0}'" -f $PilotGroup)).value | Select-Object -First 1
        if ($grp) { Write-Host ("   Pilot group resolved: {0} ({1})" -f $grp.displayName, $grp.id) -ForegroundColor Green }
        else { Write-Host ("   Pilot group '{0}' NOT found — create it (Implementation Step 1)." -f $PilotGroup) -ForegroundColor Yellow }
    } catch { Write-Host ("   Group read failed: {0}" -f $_.Exception.Message) -ForegroundColor Yellow }
    Write-Host "   Confirm in: Cloud apps > Policies — both policies exist, are MONITOR/report-only, scoped to the pilot group." -ForegroundColor DarkGray
    Write-Host "   REVIEW: no enforcing/blocking action is live during the pilot." -ForegroundColor Yellow
}

switch ($Check) {
    'Connectors' { Test-Connectors }
    'Discovery'  { Test-Discovery }
    'Policy'     { Test-Policy }
    'All'        { Test-Connectors; Test-Discovery; Test-Policy }
}
Write-Host "`nValidation complete (read-only). Resolve any REVIEW items before enforcing/expanding." -ForegroundColor Green
