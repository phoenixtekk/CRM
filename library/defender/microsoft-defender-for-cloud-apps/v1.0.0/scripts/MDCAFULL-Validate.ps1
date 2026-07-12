<#
.SYNOPSIS
    MDCAFULL-Validate.ps1 — targeted, read-only validation of the Defender for Cloud Apps lifecycle
    (connectors, Cloud Discovery flow, policy scope/posture, cloud-app signal, and the PoC).
.DESCRIPTION
    PURPOSE
        Read-only validation for the complete "Microsoft Defender for Cloud Apps" solution. Confirms
        the piece named by -Check and maps to the Testing Guide gates:
          Connectors — connectors connected (portal confirm).
          Discovery  — Cloud Discovery flowing (portal confirm).
          Policy     — session/access policies report-only and scoped to the pilot group.
          Signal     — CloudAppEvents streaming (advanced-hunting reminder + alert read).
          PoC        — the PoC observations: discovery report, audit-policy match, alert surfaced.
          All        — every check.
    HOW TO RUN
        powershell -ExecutionPolicy Bypass -File .\MDCAFULL-Validate.ps1 -Check Policy
        -Check accepts: Connectors | Discovery | Policy | Signal | PoC | All (default All).
        Uses Microsoft.Graph.Authentication + Graph Security. Reads only; makes no changes.
    EXPECTED RESULTS
        PASS/REVIEW lines per check with the object names from the Implementation Guide, so you can
        confirm each Testing Guide gate before enforcing or expanding beyond the pilot.
.NOTES
    White-label. Read-only. Where a setting is portal-only, the script prints the exact path to
    confirm manually. Policies must stay report-only until validated.
#>
[CmdletBinding()]
param(
    [ValidateSet('Connectors','Discovery','Policy','Signal','PoC','All')] [string]$Check = 'All',
    [string]$PilotGroup = 'MDCA Pilot Users - Pilot Ring - Pilot',
    [string]$PoCPolicyName = 'MDCA PoC Activity Policy - Pilot Users - Audit'
)

Import-Module Microsoft.Graph.Authentication -ErrorAction Stop
if (-not (Get-MgContext)) { Connect-MgGraph -Scopes 'SecurityEvents.Read.All','ThreatHunting.Read.All','Policy.Read.All','Directory.Read.All' -NoWelcome | Out-Null }
Write-Host "`n=== Defender for Cloud Apps — validation ($Check) ===" -ForegroundColor Cyan

function Test-Connectors {
    Write-Host "`n[Connectors] 'MDCA App Connectors - Priority SaaS - Prod'" -ForegroundColor Cyan
    Write-Host "   Confirm in: Cloud apps > Connected apps > App connectors — each shows 'Connected'." -ForegroundColor DarkGray
    Write-Host "   REVIEW: Microsoft 365 first, then priority third-party apps." -ForegroundColor Yellow
}
function Test-Discovery {
    Write-Host "`n[Discovery] Cloud Discovery source" -ForegroundColor Cyan
    Write-Host "   Confirm in: Cloud apps > Cloud discovery > Dashboard — discovered apps/traffic visible." -ForegroundColor DarkGray
    Write-Host "   REVIEW: source = MDE integration / log collector / SWG / uploaded sample log." -ForegroundColor Yellow
}
function Test-Policy {
    Write-Host "`n[Policy] 'MDCA Session Control - Pilot Users - Report' / 'MDCA Access Control - Pilot Users - Report'" -ForegroundColor Cyan
    try {
        $grp = (Invoke-MgGraphRequest -Method GET -Uri ("https://graph.microsoft.com/v1.0/groups?`$filter=displayName eq '{0}'" -f $PilotGroup)).value | Select-Object -First 1
        if ($grp) { Write-Host ("   Pilot group resolved: {0} ({1})" -f $grp.displayName, $grp.id) -ForegroundColor Green }
        else { Write-Host ("   Pilot group '{0}' NOT found — create it (Implementation Step A1)." -f $PilotGroup) -ForegroundColor Yellow }
    } catch { Write-Host ("   Group read failed: {0}" -f $_.Exception.Message) -ForegroundColor Yellow }
    Write-Host "   Confirm in: Cloud apps > Policies — both policies exist, are MONITOR/report-only, scoped to the pilot group." -ForegroundColor DarkGray
    Write-Host "   REVIEW: no enforcing/blocking action is live during the pilot." -ForegroundColor Yellow
}
function Test-Signal {
    Write-Host "`n[Signal] CloudAppEvents streaming" -ForegroundColor Cyan
    try {
        $al = (Invoke-MgGraphRequest -Method GET -Uri "https://graph.microsoft.com/v1.0/security/alerts_v2?`$top=5&`$filter=serviceSource eq 'microsoftDefenderForCloudApps'").value
        Write-Host ("   MDCA alerts reachable (sample count): {0}" -f (($al | Measure-Object).Count)) -ForegroundColor Green
    } catch { Write-Host ("   Could not read alerts_v2: {0}" -f $_.Exception.Message) -ForegroundColor Yellow }
    Write-Host "   Confirm in: Hunting > Advanced hunting — run the saved 'MDCA Signal Validation - Tenant - Validate' query." -ForegroundColor DarkGray
    Write-Host "   REVIEW: CloudAppEvents returns recent rows from connectors/discovery (allow warm-up)." -ForegroundColor Yellow
}
function Test-PoC {
    Write-Host "`n[PoC] audit-mode observations" -ForegroundColor Cyan
    Write-Host ("   Confirm: discovery report 'MDCA PoC Discovery - Pilot - Report' populated (Cloud apps > Cloud discovery)." -f $PoCPolicyName) -ForegroundColor DarkGray
    Write-Host ("   Confirm: audit policy '{0}' matched the benign activity (Cloud apps > Alerts)." -f $PoCPolicyName) -ForegroundColor DarkGray
    try {
        $al = (Invoke-MgGraphRequest -Method GET -Uri "https://graph.microsoft.com/v1.0/security/alerts_v2?`$top=10&`$filter=serviceSource eq 'microsoftDefenderForCloudApps'").value
        Write-Host ("   Alerts surfaced (sample count): {0} — expect at least one for the benign match." -f (($al | Measure-Object).Count)) -ForegroundColor Green
    } catch { Write-Host ("   Could not read alerts_v2: {0}" -f $_.Exception.Message) -ForegroundColor Yellow }
    Write-Host "   REVIEW: audit mode still ALERTS but takes NO governance action; nothing blocked." -ForegroundColor Yellow
}

switch ($Check) {
    'Connectors' { Test-Connectors }
    'Discovery'  { Test-Discovery }
    'Policy'     { Test-Policy }
    'Signal'     { Test-Signal }
    'PoC'        { Test-PoC }
    'All'        { Test-Connectors; Test-Discovery; Test-Policy; Test-Signal; Test-PoC }
}
Write-Host "`nValidation complete (read-only). Resolve any REVIEW items before enforcing/expanding." -ForegroundColor Green
