<#
.SYNOPSIS
    POCMDO-Scorecard.ps1 — score the MDO proof of concept against your evaluation criteria. Read-only.
.DESCRIPTION
    PURPOSE
        Turns the PoC observations into an objective, shareable scorecard. It re-checks the key
        MDO capabilities (mail processed, Safe Links engaged, Safe Attachments saw the attachment,
        spam/phish handled) via read-only advanced hunting, maps each to the pass/fail criteria you
        agreed up front, and writes a JSON + console scorecard.
    HOW TO RUN
        powershell -ExecutionPolicy Bypass -File .\POCMDO-Scorecard.ps1 `
            -CriteriaPath .\criteria.json -OutFile "MDO PoC Scorecard - Pilot Users - Validate.json"
        Sample criteria.json:
          [
            { "id":"mail",     "label":"Mail processed by MDO",    "capability":"mail",     "required":true },
            { "id":"safelinks","label":"Safe Links engaged",        "capability":"safelinks","required":true },
            { "id":"safeattach","label":"Safe Attachments detonated","capability":"safeattach","required":true },
            { "id":"spam",     "label":"Spam/phish handled",        "capability":"spam",     "required":false }
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
    [string]$OutFile = 'MDO PoC Scorecard - Pilot Users - Validate.json',
    [string]$Tag = 'MDO-PoC-TESTSIGNAL',
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
    mail       = "EmailEvents | where Timestamp > ago(${LookbackHours}h) | summarize Cnt = count()"
    safelinks  = "UrlClickEvents | where Timestamp > ago(${LookbackHours}h) | summarize Cnt = count()"
    safeattach = "EmailAttachmentInfo | where Timestamp > ago(${LookbackHours}h) | summarize Cnt = count()"
    spam       = "EmailEvents | where Timestamp > ago(${LookbackHours}h) | where ThreatTypes has_any('Spam','Phish') or DeliveryAction has 'Quarantine' | summarize Cnt = count()"
}
$observed = @{}
foreach ($k in $cap.Keys) { try { $observed[$k] = (Cnt (Invoke-Hunt $cap[$k])) } catch { $observed[$k] = -1 } }

if ($CriteriaPath -and (Test-Path $CriteriaPath)) {
    $criteria = Get-Content $CriteriaPath -Raw | ConvertFrom-Json
} else {
    Write-Host "No -CriteriaPath supplied; using default PoC criteria." -ForegroundColor Yellow
    $criteria = @(
        [pscustomobject]@{ id='mail';       label='Mail processed by MDO';     capability='mail';       required=$true },
        [pscustomobject]@{ id='safelinks';  label='Safe Links engaged';        capability='safelinks';  required=$true },
        [pscustomobject]@{ id='safeattach'; label='Safe Attachments detonated';capability='safeattach'; required=$true },
        [pscustomobject]@{ id='spam';       label='Spam/phish handled';        capability='spam';       required=$false }
    )
}

Write-Host "`n=== POCMDO scorecard ===" -ForegroundColor Cyan
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
    solution   = 'Proof-of-Concept Kit - Microsoft Defender for Office 365'
    generated  = (Get-Date).ToString('u')
    lookbackHrs= $LookbackHours
    criteria   = $rows
    passCount  = $passCount
    total      = $criteria.Count
    overall    = $overall
    note       = 'Benign test signal (Attack Simulation / GTUBE / EICAR / benign URL). Final verdict is the customer decision. Threat Explorer/simulation need P2 — verify.'
}
$card | ConvertTo-Json -Depth 6 | Set-Content -Path $OutFile -Encoding utf8
Write-Host ("`nOverall: {0}  ({1}/{2} criteria passed). Saved: {3}" -f $overall, $passCount, $criteria.Count, $OutFile) -ForegroundColor Cyan
Write-Host "Next (when done): POCMDO-Teardown.ps1 -WhatIf" -ForegroundColor Cyan
