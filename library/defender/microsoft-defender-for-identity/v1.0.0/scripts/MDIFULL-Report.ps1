<#
.SYNOPSIS
    MDIFULL-Report.ps1 — sensor-health + identity posture (ISPM) + coverage report with baseline
    drift, and (-Scorecard) an objective PoC scorecard against your evaluation criteria.
.DESCRIPTION
    PURPOSE
        Read-only reporting for the "Microsoft Defender for Identity" solution. Default mode
        summarizes sensor health across domain controllers, the MDI/Identity Secure Score
        recommendations (ISPM), and — with -SaveBaseline — records a posture baseline so later runs
        show drift; it also reports the response-action posture (should be approval-gated).
        -Scorecard re-checks the key MDI capabilities (recon/honeytoken alert, enumeration observed,
        directory activity, logon context) via read-only advanced hunting, maps each to the pass/fail
        criteria you agreed up front, and writes a JSON + console scorecard.
    HOW TO RUN
        # Posture / coverage report (create or compare a baseline):
        powershell -ExecutionPolicy Bypass -File .\MDIFULL-Report.ps1 -SaveBaseline
        powershell -ExecutionPolicy Bypass -File .\MDIFULL-Report.ps1
        # PoC scorecard against your criteria:
        powershell -ExecutionPolicy Bypass -File .\MDIFULL-Report.ps1 -Scorecard `
            -CriteriaPath .\criteria.json -OutFile "MDI PoC Scorecard - Pilot DC - Validate.json"
        Sample criteria.json:
          [
            { "id":"alert", "label":"Recon/honeytoken alert fired", "capability":"alert",     "required":true },
            { "id":"query", "label":"Enumeration observed",         "capability":"query",     "required":true },
            { "id":"dir",   "label":"Directory activity on timeline","capability":"directory", "required":true },
            { "id":"logon", "label":"Logon context captured",       "capability":"logon",     "required":false }
          ]
        Uses Microsoft.Graph.Authentication + Graph Security (Secure Score / advanced hunting).
    EXPECTED RESULTS
        Report: a sensor-health summary, the current Identity Secure Score and top recommendations,
        and the delta versus the saved baseline. Scorecard: a per-criterion PASS/FAIL table, an
        overall pass rate, and a saved scorecard file.
.NOTES
    White-label. Read-only. ISPM/Secure Score facts are indicative — verify current availability.
    Whether the PoC "passed" and how criteria are weighted is the customer's decision.
#>
[CmdletBinding()]
param(
    [switch]$SaveBaseline,
    [string]$BaselinePath = ".\MDIFULL-posture-baseline.json",
    [switch]$Scorecard,
    [string]$CriteriaPath,
    [string]$OutFile = 'MDI PoC Scorecard - Pilot DC - Validate.json',
    [int]$LookbackHours = 12
)

foreach ($m in 'Microsoft.Graph.Authentication') {
    if (-not (Get-Module -ListAvailable -Name $m)) { Install-Module Microsoft.Graph -Scope CurrentUser -Force -AllowClobber; break }
}
Import-Module Microsoft.Graph.Authentication -ErrorAction Stop

# =================== PoC SCORECARD MODE ===================
if ($Scorecard) {
    if (-not (Get-MgContext)) { Connect-MgGraph -Scopes 'ThreatHunting.Read.All' -NoWelcome | Out-Null }
    function Invoke-Hunt([string]$Query) {
        $body = @{ Query = $Query } | ConvertTo-Json
        return Invoke-MgGraphRequest -Method POST -Uri 'https://graph.microsoft.com/v1.0/security/runHuntingQuery' -Body $body -ContentType 'application/json'
    }
    function Cnt($resp) { if ($resp.results -and $resp.results.Count -gt 0) { return [int]$resp.results[0].Cnt } return 0 }

    $cap = @{
        alert     = "AlertInfo | where Timestamp > ago(${LookbackHours}h) | where ServiceSource has 'Identity' or Title has_any('reconnaissance','honeytoken','enumeration') | summarize Cnt = count()"
        query     = "IdentityQueryEvents | where Timestamp > ago(${LookbackHours}h) | summarize Cnt = count()"
        directory = "IdentityDirectoryEvents | where Timestamp > ago(${LookbackHours}h) | summarize Cnt = count()"
        logon     = "IdentityLogonEvents | where Timestamp > ago(${LookbackHours}h) | summarize Cnt = count()"
    }
    $observed = @{}
    foreach ($k in $cap.Keys) { try { $observed[$k] = (Cnt (Invoke-Hunt $cap[$k])) } catch { $observed[$k] = -1 } }

    if ($CriteriaPath -and (Test-Path $CriteriaPath)) {
        $criteria = Get-Content $CriteriaPath -Raw | ConvertFrom-Json
    } else {
        Write-Host "No -CriteriaPath supplied; using default PoC criteria." -ForegroundColor Yellow
        $criteria = @(
            [pscustomobject]@{ id='alert'; label='Recon/honeytoken alert fired'; capability='alert';     required=$true },
            [pscustomobject]@{ id='query'; label='Enumeration observed';         capability='query';     required=$true },
            [pscustomobject]@{ id='dir';   label='Directory activity on timeline';capability='directory'; required=$true },
            [pscustomobject]@{ id='logon'; label='Logon context captured';       capability='logon';     required=$false }
        )
    }

    Write-Host "`n=== MDIFULL scorecard ===" -ForegroundColor Cyan
    $rows = @(); $passCount = 0; $reqFail = 0
    foreach ($c in $criteria) {
        $obs = if ($observed.ContainsKey($c.capability)) { $observed[$c.capability] } else { 0 }
        $res = if ($obs -gt 0) { 'PASS' } else { 'FAIL' }
        if ($res -eq 'PASS') { $passCount++ } elseif ($c.required) { $reqFail++ }
        Write-Host ("  [{0}] {1} (required={2}, observed={3})" -f $res, $c.label, $c.required, $obs) -ForegroundColor $(if ($res -eq 'PASS') { 'Green' } else { 'Yellow' })
        $rows += [pscustomobject]@{ id=$c.id; label=$c.label; capability=$c.capability; required=$c.required; observed=$obs; result=$res }
    }
    $overall = if ($reqFail -eq 0) { 'PASS' } else { 'NEEDS REVIEW' }
    $card = [pscustomobject]@{
        solution='Microsoft Defender for Identity'; generated=(Get-Date).ToString('u'); lookbackHrs=$LookbackHours
        criteria=$rows; passCount=$passCount; total=$criteria.Count; overall=$overall
        note='Benign test signal (read-only enumeration + honeytoken). Final verdict is the customer decision.'
    }
    $card | ConvertTo-Json -Depth 6 | Set-Content -Path $OutFile -Encoding utf8
    Write-Host ("`nOverall: {0}  ({1}/{2} criteria passed). Saved: {3}" -f $overall, $passCount, $criteria.Count, $OutFile) -ForegroundColor Cyan
    Write-Host "Next (when done): MDIFULL-Deploy.ps1 -Rollback -WhatIf" -ForegroundColor Cyan
    return
}

# =================== POSTURE / COVERAGE REPORT MODE ===================
if (-not (Get-MgContext)) { Connect-MgGraph -Scopes 'SecurityEvents.Read.All','SecurityIdentitiesHealth.Read.All' -NoWelcome | Out-Null }
Write-Host "`n=== Defender for Identity — posture & coverage report ===" -ForegroundColor Cyan

# --- Sensor health summary ---
Write-Host "`n-- Sensor health --" -ForegroundColor Cyan
try {
    $sensors = (Invoke-MgGraphRequest -Method GET -Uri 'https://graph.microsoft.com/beta/security/identities/sensors' -ErrorAction Stop).value
    $healthy = @($sensors | Where-Object { $_.healthStatus -eq 'healthy' }).Count
    Write-Host ("   Sensors: {0}  Healthy: {1}" -f ($sensors | Measure-Object).Count, $healthy) -ForegroundColor Green
} catch { Write-Host "   Sensor health API unavailable — confirm in Settings > Identities > Sensors." -ForegroundColor Yellow; $sensors = @() }

# --- Identity Secure Score / ISPM ---
Write-Host "`n-- Identity Secure Score (ISPM) --" -ForegroundColor Cyan
$score = $null; $recs = @()
try {
    $ss = (Invoke-MgGraphRequest -Method GET -Uri 'https://graph.microsoft.com/v1.0/security/secureScores?$top=1').value | Select-Object -First 1
    if ($ss) { $score = [double]$ss.currentScore; Write-Host ("   Current Secure Score: {0} / {1}" -f $ss.currentScore, $ss.maxScore) -ForegroundColor Green }
    $profiles = (Invoke-MgGraphRequest -Method GET -Uri "https://graph.microsoft.com/v1.0/security/secureScoreControlProfiles?`$top=200").value
    $recs = $profiles | Where-Object { $_.controlCategory -match 'Identity' } | Select-Object -First 15 -Property title, controlCategory, actionUrl
    if ($recs) { $recs | ForEach-Object { Write-Host ("     [{0}] {1}" -f $_.controlCategory, $_.title) } }
    else { Write-Host "   No Identity recommendations resolved yet (allow sensor warm-up). Verify ISPM availability." -ForegroundColor Yellow }
} catch { Write-Host ("   Secure Score read failed: {0}" -f $_.Exception.Message) -ForegroundColor Yellow }

Write-Host "`n-- Response actions --" -ForegroundColor Cyan
Write-Host "   Confirm response actions (disable user / force password reset) remain APPROVAL-GATED." -ForegroundColor DarkGray
Write-Host "   Settings > Identities > Response actions (verify current availability in your tenant)." -ForegroundColor DarkGray

$now = [ordered]@{ Timestamp = (Get-Date).ToString('s'); SecureScore = $score; SensorCount = ($sensors | Measure-Object).Count; IdentityRecommendations = @($recs | ForEach-Object { $_.title }) }
if ($SaveBaseline) {
    $now | ConvertTo-Json -Depth 6 | Set-Content -Path $BaselinePath -Encoding UTF8
    Write-Host ("`nBaseline saved: {0}" -f $BaselinePath) -ForegroundColor Green
} elseif (Test-Path $BaselinePath) {
    $base = Get-Content $BaselinePath -Raw | ConvertFrom-Json
    if ($null -ne $score -and $null -ne $base.SecureScore) {
        $delta = [math]::Round($score - $base.SecureScore, 2)
        Write-Host ("`nSecure Score drift vs baseline ({0}): {1}" -f $base.Timestamp, $delta) -ForegroundColor $(if ($delta -ge 0) { 'Green' } else { 'Yellow' })
    }
} else { Write-Host "`n(no baseline yet — run with -SaveBaseline to create one)" -ForegroundColor DarkGray }
Write-Host "Report complete (read-only)." -ForegroundColor Green
