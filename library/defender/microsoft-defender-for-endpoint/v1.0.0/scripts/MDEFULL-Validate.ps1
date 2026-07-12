<#
.SYNOPSIS
    MDEFULL-Validate.ps1 — targeted validation across the Defender for Endpoint lifecycle
    (deploy, optimize, enablement labs, and PoC gates from the Testing Guide).
.DESCRIPTION
    PURPOSE
        Read-only validation for the comprehensive "Microsoft Defender for Endpoint" solution.
        Confirms the area named by -Check against the Testing Guide pass/fail gates. Where a control
        is portal-only it prints the exact path to confirm manually; where it can be checked via
        advanced hunting (onboarding coverage, enablement-lab data, PoC benign-signal detections) it
        runs a read-only KQL query.
    HOW TO RUN
        powershell -ExecutionPolicy Bypass -File .\MDEFULL-Validate.ps1 -Check Onboarding
        -Check accepts: Onboarding | EDR | ASR | Config | RBAC | Tuning | Enablement | PoC | All (default All).
        -DeviceName (optional) narrows the PoC/enablement telemetry checks. Government cloud: -Environment.
    EXPECTED RESULTS
        PASS/REVIEW/FAIL lines per check with the object names from the Implementation Guide, so you
        can confirm each Testing Guide gate before promoting ASR/block mode, expanding onboarding,
        operationalizing the labs, or calling a PoC conclusive.
.NOTES
    White-label. Read-only. ASR must be audited before block. Lab ASR stays audit-only; the lab
    detection stays alert-only; PoC/AIR stays approval-gated. Verify P1/P2 feature availability.
#>
[CmdletBinding()]
param(
    [ValidateSet('Onboarding','EDR','ASR','Config','RBAC','Tuning','Enablement','PoC','All')] [string]$Check = 'All',
    [string]$DeviceName,
    [int]$LookbackHours = 12,
    [ValidateSet('Global','USGov','USGovDoD')] [string]$Environment = 'Global'
)

Import-Module Microsoft.Graph.Authentication -ErrorAction Stop
if (-not (Get-MgContext)) { Connect-MgGraph -Scopes 'ThreatHunting.Read.All','SecurityEvents.Read.All','DeviceManagementConfiguration.Read.All' -Environment $Environment -NoWelcome | Out-Null }
Write-Host "`n=== Defender for Endpoint — validation ($Check) ===" -ForegroundColor Cyan

function Invoke-Hunt([string]$Query) {
    $body = @{ Query = $Query } | ConvertTo-Json
    return Invoke-MgGraphRequest -Method POST -Uri 'https://graph.microsoft.com/v1.0/security/runHuntingQuery' -Body $body -ContentType 'application/json'
}
function Cnt($resp) { if ($resp.results -and $resp.results.Count -gt 0) { return [int]$resp.results[0].Cnt } return 0 }
$devFilter = if ($DeviceName) { "| where DeviceName has '$DeviceName'" } else { '' }

function Test-Onboarding {
    Write-Host "`n[Onboarding] 'MDE Device Group - Pilot Ring - Pilot'" -ForegroundColor Cyan
    $kql = "DeviceInfo | where Timestamp > ago(1d) | summarize arg_max(Timestamp, OnboardingStatus) by DeviceName | summarize Onboarded=countif(OnboardingStatus == 'Onboarded'), Total=count()"
    try {
        $r = Invoke-Hunt $kql
        if ($r.results) { $r.results | ForEach-Object { Write-Host ("   Onboarded {0} / {1} devices seen (last 24h)" -f $_.Onboarded, $_.Total) -ForegroundColor Green } }
        else { Write-Host "   No DeviceInfo rows yet — allow warm-up or confirm onboarding in Assets > Devices." -ForegroundColor Yellow }
    } catch { Write-Host ("   Onboarding hunt unavailable ({0}). Confirm in Assets > Devices." -f $_.Exception.Message) -ForegroundColor Yellow }
}
function Test-EDR {
    Write-Host "`n[EDR] Block mode + 'MDE Next-Gen AV - Pilot Ring - Prod'" -ForegroundColor Cyan
    Write-Host "   Confirm: Settings > Endpoints > Advanced features > EDR in block mode = On." -ForegroundColor DarkGray
    Write-Host "   REVIEW: AV policy assigned to the pilot ring; real-time + cloud-delivered protection on." -ForegroundColor Yellow
}
function Test-ASR {
    Write-Host "`n[ASR] 'MDE ASR Rules - Pilot Ring - Audit' / '- Block'" -ForegroundColor Cyan
    Write-Host "   Confirm: Endpoint security > Attack surface reduction — audit ran, exclusions tuned, block enforced on ring." -ForegroundColor DarkGray
    Write-Host "   REVIEW: no rule was set to Block before audit review (MDEFULL-Report.ps1 -Section ASR)." -ForegroundColor Yellow
}
function Test-Config {
    Write-Host "`n[Config] Tamper protection + 'MDE Web Content Filtering - Tenant - Prod'" -ForegroundColor Cyan
    Write-Host "   Confirm: Settings > Endpoints > Advanced features > Tamper Protection = On (enforced)." -ForegroundColor DarkGray
    Write-Host "   Confirm: Settings > Endpoints > Web content filtering active (requires P2 + network protection — verify)." -ForegroundColor DarkGray
}
function Test-RBAC {
    Write-Host "`n[RBAC] Device groups + roles" -ForegroundColor Cyan
    Write-Host "   Confirm: Permissions > Device groups — 'MDE Device Group - Pilot Ring - Pilot', automation = Semi (approval)." -ForegroundColor DarkGray
    Write-Host "   Confirm: Roles 'MDE Security Reader - Tenant - Prod' / 'MDE Security Operator - Tenant - Prod' assigned least-privilege." -ForegroundColor DarkGray
}
function Test-Tuning {
    Write-Host "`n[Tuning] Coverage, tags/groups, suppressions" -ForegroundColor Cyan
    $kql = "DeviceInfo | summarize LastSeen=max(Timestamp) by DeviceName, OnboardingStatus | summarize Active=countif(OnboardingStatus=='Onboarded' and LastSeen > ago(1d)), Total=count()"
    try { $r = Invoke-Hunt $kql; if ($r.results) { $r.results | ForEach-Object { Write-Host ("   Active/reporting {0} / {1} devices" -f $_.Active, $_.Total) -ForegroundColor Green } } }
    catch { Write-Host ("   Coverage hunt unavailable: {0}" -f $_.Exception.Message) -ForegroundColor Yellow }
    Write-Host "   Confirm: suppressions 'MDE FP Suppression - <detection> - Prod' / indicators 'MDE Allow Indicator - <object> - Prod' are scoped, justified, time-bound." -ForegroundColor DarkGray
    Write-Host "   Confirm: device tags resolve into the intended device groups (Assets > Devices > filter by tag)." -ForegroundColor DarkGray
}
function Test-Enablement {
    Write-Host "`n[Enablement] Lab data, audit-only ASR, alert-only detection, knowledge-check" -ForegroundColor Cyan
    $kql = "DeviceEvents | where Timestamp > ago(7d) | where ActionType startswith 'Asr' | summarize Audited=countif(ActionType endswith 'Audited'), Blocked=countif(ActionType endswith 'Blocked')"
    try {
        $r = Invoke-Hunt $kql
        if ($r.results) { $r.results | ForEach-Object {
            Write-Host ("   ASR lab events — Audited {0} / Blocked {1}" -f $_.Audited, $_.Blocked) -ForegroundColor Green
            if ([int]$_.Blocked -gt 0) { Write-Host "   CONCERN: a lab ASR rule is BLOCKING. 'MDE ASR Lab - Lab Devices - Audit' must stay audit-only (R2.13)." -ForegroundColor Red }
        } }
        else { Write-Host "   No ASR lab events yet — set 'MDE ASR Lab - Lab Devices - Audit' and re-run Lab 5." -ForegroundColor Yellow }
    } catch { Write-Host ("   Lab hunt unavailable: {0}" -f $_.Exception.Message) -ForegroundColor Yellow }
    Write-Host "   Confirm: Advanced hunting > Custom detection rules — 'MDE Lab Detection - Team - Pilot' response = ALERT ONLY." -ForegroundColor DarkGray
    Write-Host "   Confirm: Live Response transcript for 'MDE Lab Devices - Pilot Ring - Pilot' shows only read-only commands." -ForegroundColor DarkGray
    Write-Host "   Knowledge-check 'MDE Knowledge Check - Team - Pilot': score each learner on incident-vs-alert, timeline, ASR modes, LR read-vs-change, response approvals." -ForegroundColor DarkGray
}
function Test-PoC {
    Write-Host "`n[PoC] Benign-signal detections (read-only) — 'MDE PoC - Pilot Ring - Pilot'" -ForegroundColor Cyan
    $checks = @(
        @{ Name='Alert reached the portal'; Kql = "AlertInfo | where Timestamp > ago(${LookbackHours}h) | where Title has_any('EICAR','test','Malware','tutorial','simulation') or Category != '' | summarize Cnt=count()" },
        @{ Name='Alert evidence attached'; Kql = "AlertEvidence | where Timestamp > ago(${LookbackHours}h) $devFilter | summarize Cnt=count()" },
        @{ Name='Device events / timeline'; Kql = "DeviceEvents | where Timestamp > ago(${LookbackHours}h) $devFilter | where ActionType has_any('AntivirusDetection','AntivirusScanCompleted','ProcessCreated','FileCreated') | summarize Cnt=count()" }
    )
    $pass = 0
    foreach ($c in $checks) {
        try { $n = Cnt (Invoke-Hunt $c.Kql); if ($n -gt 0) { Write-Host ("   PASS — {0} ({1} row[s])" -f $c.Name, $n) -ForegroundColor Green; $pass++ } else { Write-Host ("   FAIL — {0}: no rows yet (allow warm-up, confirm onboarding)." -f $c.Name) -ForegroundColor Yellow } }
        catch { Write-Host ("   ERROR — {0}: {1}" -f $c.Name, $_.Exception.Message) -ForegroundColor Yellow }
    }
    Write-Host "   Confirm: the incident's Automated investigation started, pilot automation = 'Semi - require approval' (no unattended action)." -ForegroundColor DarkGray
    Write-Host ("   PoC capability checks passing: {0}/{1}" -f $pass, $checks.Count) -ForegroundColor Cyan
}

switch ($Check) {
    'Onboarding' { Test-Onboarding }
    'EDR'        { Test-EDR }
    'ASR'        { Test-ASR }
    'Config'     { Test-Config }
    'RBAC'       { Test-RBAC }
    'Tuning'     { Test-Tuning }
    'Enablement' { Test-Enablement }
    'PoC'        { Test-PoC }
    'All'        { Test-Onboarding; Test-EDR; Test-ASR; Test-Config; Test-RBAC; Test-Tuning; Test-Enablement; Test-PoC }
}
Write-Host "`nValidation complete (read-only). Resolve any REVIEW/FAIL items before promoting, expanding, operationalizing, or closing the PoC." -ForegroundColor Green
