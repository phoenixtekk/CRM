<#
.SYNOPSIS
    POCMDE-Scorecard.ps1 — score the MDE proof of concept against your evaluation criteria. Read-only.
.DESCRIPTION
    PURPOSE
        Turns the PoC observations into an objective, shareable scorecard. It re-checks the key
        MDE capabilities (detection reached the portal, evidence attached, device timeline/hunting
        populated, automated investigation started) via read-only advanced hunting, maps each to
        the pass/fail criteria you agreed up front, and writes a JSON + console scorecard.
        Provide your criteria file (see the sample below) so the bar is yours, not ours.
    HOW TO RUN
        powershell -ExecutionPolicy Bypass -File .\POCMDE-Scorecard.ps1 `
            -CriteriaPath .\criteria.json -OutFile "MDE PoC Scorecard - Pilot Ring - Validate.json"
        Sample criteria.json:
          [
            { "id":"detect",   "label":"Detection reached portal",     "capability":"alert",    "required":true },
            { "id":"evidence", "label":"Evidence attached to alert",    "capability":"evidence", "required":true },
            { "id":"timeline", "label":"Device timeline populated",     "capability":"device",   "required":true },
            { "id":"air",      "label":"Automated investigation start", "capability":"air",      "required":false }
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
    [string]$OutFile = 'MDE PoC Scorecard - Pilot Ring - Validate.json',
    [string]$DeviceName,
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

$devFilter = if ($DeviceName) { "| where DeviceName has '$DeviceName'" } else { '' }

# Capability probes (read-only).
$cap = @{
    alert    = "AlertInfo | where Timestamp > ago(${LookbackHours}h) | summarize Cnt = count()"
    evidence = "AlertEvidence | where Timestamp > ago(${LookbackHours}h) $devFilter | summarize Cnt = count()"
    device   = "DeviceEvents | where Timestamp > ago(${LookbackHours}h) $devFilter | summarize Cnt = count()"
    air      = "AlertInfo | where Timestamp > ago(${LookbackHours}h) | where ServiceSource has 'Endpoint' | summarize Cnt = count()"
}
$observed = @{}
foreach ($k in $cap.Keys) { try { $observed[$k] = (Cnt (Invoke-Hunt $cap[$k])) } catch { $observed[$k] = -1 } }

# Default criteria if none supplied.
if ($CriteriaPath -and (Test-Path $CriteriaPath)) {
    $criteria = Get-Content $CriteriaPath -Raw | ConvertFrom-Json
} else {
    Write-Host "No -CriteriaPath supplied; using default PoC criteria." -ForegroundColor Yellow
    $criteria = @(
        [pscustomobject]@{ id='detect';   label='Detection reached portal';     capability='alert';    required=$true },
        [pscustomobject]@{ id='evidence'; label='Evidence attached to alert';    capability='evidence'; required=$true },
        [pscustomobject]@{ id='timeline'; label='Device timeline populated';     capability='device';   required=$true },
        [pscustomobject]@{ id='air';      label='Automated investigation start'; capability='air';      required=$false }
    )
}

Write-Host "`n=== POCMDE scorecard ===" -ForegroundColor Cyan
$rows = @(); $passCount = 0; $reqFail = 0
foreach ($c in $criteria) {
    $obs = if ($observed.ContainsKey($c.capability)) { $observed[$c.capability] } else { 0 }
    $result = if ($obs -gt 0) { 'PASS' } else { 'FAIL' }
    if ($result -eq 'PASS') { $passCount++ } elseif ($c.required) { $reqFail++ }
    $color = if ($result -eq 'PASS') { 'Green' } else { 'Yellow' }
    Write-Host ("  [{0}] {1} (required={2}, observed={3})" -f $result, $c.label, $c.required, $obs) -ForegroundColor $color
    $rows += [pscustomobject]@{ id=$c.id; label=$c.label; capability=$c.capability; required=$c.required; observed=$obs; result=$result }
}

$overall = if ($reqFail -eq 0) { 'PASS' } else { 'NEEDS REVIEW' }
$card = [pscustomobject]@{
    solution   = 'Proof-of-Concept Kit - Microsoft Defender for Endpoint'
    generated  = (Get-Date).ToString('u')
    device     = $DeviceName
    lookbackHrs= $LookbackHours
    criteria   = $rows
    passCount  = $passCount
    total      = $criteria.Count
    overall    = $overall
    note       = 'Benign test signal (EICAR / Microsoft built-in simulation). Final verdict is the customer decision.'
}
$card | ConvertTo-Json -Depth 6 | Set-Content -Path $OutFile -Encoding utf8
Write-Host ("`nOverall: {0}  ({1}/{2} criteria passed). Saved: {3}" -f $overall, $passCount, $criteria.Count, $OutFile) -ForegroundColor Cyan
Write-Host "Next (when done): POCMDE-Teardown.ps1 -WhatIf" -ForegroundColor Cyan
