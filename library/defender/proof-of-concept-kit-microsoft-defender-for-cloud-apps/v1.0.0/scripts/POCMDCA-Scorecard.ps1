<#
.SYNOPSIS
    POCMDCA-Scorecard.ps1 — score the MDCA proof of concept against your evaluation criteria. Read-only.
.DESCRIPTION
    PURPOSE
        Turns the PoC observations into an objective, shareable scorecard. It re-checks the key
        MDCA capabilities (cloud-app activity visible, audit-policy alert surfaced) via read-only
        advanced hunting, maps each to the pass/fail criteria you agreed up front, and writes a
        JSON + console scorecard. Confirm the Cloud Discovery report in the portal for the
        discovery criterion (report state is not in the hunting tables).
    HOW TO RUN
        powershell -ExecutionPolicy Bypass -File .\POCMDCA-Scorecard.ps1 `
            -CriteriaPath .\criteria.json -OutFile "MDCA PoC Scorecard - Pilot Users - Validate.json"
        Sample criteria.json:
          [
            { "id":"activity", "label":"Cloud-app activity visible", "capability":"activity", "required":true },
            { "id":"alert",    "label":"Audit policy alert surfaced", "capability":"alert",    "required":true },
            { "id":"discovery","label":"Shadow IT report populated",  "capability":"portal",   "required":true }
          ]
        Requires Microsoft.Graph.Authentication and ThreatHunting.Read.All consent.
    EXPECTED RESULTS
        A per-criterion PASS/FAIL table, an overall pass rate, and a saved scorecard file.
.NOTES
    White-label. Read-only. Whether the PoC "passed" and how criteria are weighted is the customer's decision.
#>
[CmdletBinding()]
param(
    [string]$CriteriaPath,
    [string]$OutFile = 'MDCA PoC Scorecard - Pilot Users - Validate.json',
    [int]$LookbackHours = 12
)

foreach ($m in 'Microsoft.Graph.Authentication') {
    if (-not (Get-Module -ListAvailable -Name $m)) { Install-Module Microsoft.Graph -Scope CurrentUser -Force -AllowClobber; break }
}
Import-Module Microsoft.Graph.Authentication -ErrorAction Stop
if (-not (Get-MgContext)) { Connect-MgGraph -Scopes 'ThreatHunting.Read.All' -NoWelcome | Out-Null }

function Invoke-Hunt([string]$Query) {
    $body = @{ Query = $Query } | ConvertTo-Json
    return Invoke-MgGraphRequest -Method POST -Uri 'https://graph.microsoft.com/v1.0/security/runHuntingQuery' -Body $body -ContentType 'application/json'
}
function Cnt($resp) { if ($resp.results -and $resp.results.Count -gt 0) { return [int]$resp.results[0].Cnt } return 0 }

$cap = @{
    activity = "CloudAppEvents | where Timestamp > ago(${LookbackHours}h) | summarize Cnt = count()"
    alert    = "AlertInfo | where Timestamp > ago(${LookbackHours}h) | where ServiceSource has_any('CloudApps','App') or Title has_any('activity policy','cloud app','anomaly') | summarize Cnt = count()"
}
$observed = @{}
foreach ($k in $cap.Keys) { try { $observed[$k] = (Cnt (Invoke-Hunt $cap[$k])) } catch { $observed[$k] = -1 } }
# 'portal' capabilities (e.g. discovery report) are confirmed in the portal, not via hunting.
$observed['portal'] = -2  # -2 = "confirm in portal"

if ($CriteriaPath -and (Test-Path $CriteriaPath)) {
    $criteria = Get-Content $CriteriaPath -Raw | ConvertFrom-Json
} else {
    Write-Host "No -CriteriaPath supplied; using default PoC criteria." -ForegroundColor Yellow
    $criteria = @(
        [pscustomobject]@{ id='activity';  label='Cloud-app activity visible'; capability='activity'; required=$true },
        [pscustomobject]@{ id='alert';     label='Audit policy alert surfaced';capability='alert';    required=$true },
        [pscustomobject]@{ id='discovery'; label='Shadow IT report populated'; capability='portal';   required=$true }
    )
}

Write-Host "`n=== POCMDCA scorecard ===" -ForegroundColor Cyan
$rows = @(); $passCount = 0; $reqFail = 0
foreach ($c in $criteria) {
    $obs = if ($observed.ContainsKey($c.capability)) { $observed[$c.capability] } else { 0 }
    if ($obs -eq -2) {
        $result = 'CONFIRM-IN-PORTAL'
        Write-Host ("  [{0}] {1} (confirm the discovery report in Cloud discovery -> Dashboard)" -f $result, $c.label) -ForegroundColor Cyan
    } else {
        $result = if ($obs -gt 0) { 'PASS' } else { 'FAIL' }
        if ($result -eq 'PASS') { $passCount++ } elseif ($c.required) { $reqFail++ }
        $color = if ($result -eq 'PASS') { 'Green' } else { 'Yellow' }
        Write-Host ("  [{0}] {1} (required={2}, observed={3})" -f $result, $c.label, $c.required, $obs) -ForegroundColor $color
    }
    $rows += [pscustomobject]@{ id=$c.id; label=$c.label; capability=$c.capability; required=$c.required; observed=$obs; result=$result }
}

$overall = if ($reqFail -eq 0) { 'PASS (verify portal-confirmed items)' } else { 'NEEDS REVIEW' }
$card = [pscustomobject]@{
    solution   = 'Proof-of-Concept Kit - Microsoft Defender for Cloud Apps'
    generated  = (Get-Date).ToString('u')
    lookbackHrs= $LookbackHours
    criteria   = $rows
    passCount  = $passCount
    total      = $criteria.Count
    overall    = $overall
    note       = 'Benign test signal (sample discovery log + benign activity), audit mode. Final verdict is the customer decision.'
}
$card | ConvertTo-Json -Depth 6 | Set-Content -Path $OutFile -Encoding utf8
Write-Host ("`nOverall: {0}  ({1}/{2} hunting criteria passed). Saved: {3}" -f $overall, $passCount, $criteria.Count, $OutFile) -ForegroundColor Cyan
Write-Host "Next (when done): POCMDCA-Teardown.ps1 -WhatIf" -ForegroundColor Cyan
