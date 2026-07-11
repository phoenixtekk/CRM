<#
.SYNOPSIS
    POCMDI-Scorecard.ps1 — score the MDI proof of concept against your evaluation criteria. Read-only.
.DESCRIPTION
    PURPOSE
        Turns the PoC observations into an objective, shareable scorecard. It re-checks the key
        MDI capabilities (recon/honeytoken alert, enumeration observed, directory activity, logon
        context) via read-only advanced hunting, maps each to the pass/fail criteria you agreed up
        front, and writes a JSON + console scorecard.
    HOW TO RUN
        powershell -ExecutionPolicy Bypass -File .\POCMDI-Scorecard.ps1 `
            -CriteriaPath .\criteria.json -OutFile "MDI PoC Scorecard - Pilot DC - Validate.json"
        Sample criteria.json:
          [
            { "id":"alert",  "label":"Recon/honeytoken alert fired", "capability":"alert",     "required":true },
            { "id":"query",  "label":"Enumeration observed",         "capability":"query",     "required":true },
            { "id":"dir",    "label":"Directory activity on timeline","capability":"directory", "required":true },
            { "id":"logon",  "label":"Logon context captured",       "capability":"logon",     "required":false }
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
    [string]$OutFile = 'MDI PoC Scorecard - Pilot DC - Validate.json',
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

Write-Host "`n=== POCMDI scorecard ===" -ForegroundColor Cyan
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
    solution   = 'Proof-of-Concept Kit - Microsoft Defender for Identity'
    generated  = (Get-Date).ToString('u')
    lookbackHrs= $LookbackHours
    criteria   = $rows
    passCount  = $passCount
    total      = $criteria.Count
    overall    = $overall
    note       = 'Benign test signal (read-only enumeration + honeytoken). Final verdict is the customer decision.'
}
$card | ConvertTo-Json -Depth 6 | Set-Content -Path $OutFile -Encoding utf8
Write-Host ("`nOverall: {0}  ({1}/{2} criteria passed). Saved: {3}" -f $overall, $passCount, $criteria.Count, $OutFile) -ForegroundColor Cyan
Write-Host "Next (when done): POCMDI-Teardown.ps1 -WhatIf" -ForegroundColor Cyan
