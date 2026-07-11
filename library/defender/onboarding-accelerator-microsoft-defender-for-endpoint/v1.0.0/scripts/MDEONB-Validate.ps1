<#
.SYNOPSIS
    MDEONB-Validate.ps1 — targeted validation of Defender for Endpoint onboarding
    (onboarding coverage, EDR block mode/AV, ASR rule states, tamper/web filtering, device groups/RBAC).
.DESCRIPTION
    PURPOSE
        Read-only validation for the "Onboarding Accelerator — Microsoft Defender for Endpoint"
        solution. Confirms the area named by -Check against the Testing Guide gates: onboarding,
        EDR/AV, ASR, tamper + web content filtering config, or device groups + RBAC.
    HOW TO RUN
        powershell -ExecutionPolicy Bypass -File .\MDEONB-Validate.ps1 -Check Onboarding
        -Check accepts: Onboarding | EDR | ASR | Config | RBAC | All (default All).
        Uses Microsoft.Graph.Authentication + advanced hunting for onboarding coverage. Read-only.
    EXPECTED RESULTS
        PASS/REVIEW lines per check with the object names from the Implementation Guide, so you can
        confirm each Testing Guide gate before promoting ASR/block mode or expanding onboarding.
.NOTES
    White-label. Read-only. Where a control is portal-only, the script prints the exact path to
    confirm manually. ASR must be audited before block.
#>
[CmdletBinding()]
param(
    [ValidateSet('Onboarding','EDR','ASR','Config','RBAC','All')] [string]$Check = 'All'
)

Import-Module Microsoft.Graph.Authentication -ErrorAction Stop
if (-not (Get-MgContext)) { Connect-MgGraph -Scopes 'ThreatHunting.Read.All','SecurityEvents.Read.All','DeviceManagementConfiguration.Read.All' -NoWelcome | Out-Null }
Write-Host "`n=== Defender for Endpoint — validation ($Check) ===" -ForegroundColor Cyan

function Test-Onboarding {
    Write-Host "`n[Onboarding] 'MDE Device Group - Pilot Ring - Pilot'" -ForegroundColor Cyan
    $kql = "DeviceInfo | where Timestamp > ago(1d) | summarize arg_max(Timestamp, OnboardingStatus) by DeviceName | summarize Onboarded=countif(OnboardingStatus == 'Onboarded'), Total=count()"
    try {
        $r = Invoke-MgGraphRequest -Method POST -Uri 'https://graph.microsoft.com/v1.0/security/runHuntingQuery' -Body (@{ Query = $kql } | ConvertTo-Json) -ContentType 'application/json'
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
    Write-Host "   REVIEW: no rule was set to Block before audit review." -ForegroundColor Yellow
}
function Test-Config {
    Write-Host "`n[Config] Tamper protection + 'MDE Web Content Filtering - Tenant - Prod'" -ForegroundColor Cyan
    Write-Host "   Confirm: Settings > Endpoints > Advanced features > Tamper Protection = On (enforced)." -ForegroundColor DarkGray
    Write-Host "   Confirm: Settings > Endpoints > Web content filtering active (requires P2 — verify)." -ForegroundColor DarkGray
}
function Test-RBAC {
    Write-Host "`n[RBAC] Device groups + roles" -ForegroundColor Cyan
    Write-Host "   Confirm: Settings > Endpoints > Permissions > Device groups — 'MDE Device Group - Pilot Ring - Pilot', automation = Semi (approval)." -ForegroundColor DarkGray
    Write-Host "   Confirm: Roles 'MDE Security Reader - Tenant - Prod' / 'MDE Security Operator - Tenant - Prod' assigned least-privilege." -ForegroundColor DarkGray
}

switch ($Check) {
    'Onboarding' { Test-Onboarding }
    'EDR'        { Test-EDR }
    'ASR'        { Test-ASR }
    'Config'     { Test-Config }
    'RBAC'       { Test-RBAC }
    'All'        { Test-Onboarding; Test-EDR; Test-ASR; Test-Config; Test-RBAC }
}
Write-Host "`nValidation complete (read-only). Resolve any REVIEW items before promoting/expanding." -ForegroundColor Green
