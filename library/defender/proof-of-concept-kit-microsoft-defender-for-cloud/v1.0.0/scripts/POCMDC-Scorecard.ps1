<#
.SYNOPSIS
    POCMDC-Scorecard.ps1 — score the Defender for Cloud proof of concept against your evaluation criteria. Read-only.
.DESCRIPTION
    PURPOSE
        Turns the PoC observations into an objective, shareable scorecard. It re-checks the key
        Defender-for-Cloud capabilities (recommendations, Secure Score, security alerts) via
        read-only Az.Security, maps each to the pass/fail criteria you agreed up front, and writes a
        JSON + console scorecard. Confirm Regulatory compliance in the portal for that criterion.
    HOW TO RUN
        powershell -ExecutionPolicy Bypass -File .\POCMDC-Scorecard.ps1 `
            -CriteriaPath .\criteria.json -OutFile "MDC PoC Scorecard - Pilot Sub - Validate.json"
        Sample criteria.json:
          [
            { "id":"reco",  "label":"Recommendation raised",   "capability":"reco",  "required":true },
            { "id":"score", "label":"Secure Score present",     "capability":"score", "required":true },
            { "id":"alert", "label":"Security alert fired",      "capability":"alert", "required":true },
            { "id":"comp",  "label":"Regulatory compliance data","capability":"portal","required":false }
          ]
        Requires Az.Accounts + Az.Security and Security Reader.
    EXPECTED RESULTS
        A per-criterion PASS/FAIL table, an overall pass rate, and a saved scorecard file.
.NOTES
    White-label. Read-only. Whether the PoC "passed" and how criteria are weighted is the customer's decision.
#>
[CmdletBinding()]
param(
    [string]$CriteriaPath,
    [string]$OutFile = 'MDC PoC Scorecard - Pilot Sub - Validate.json',
    [string]$SubscriptionId
)

foreach ($m in 'Az.Accounts','Az.Security') {
    if (-not (Get-Module -ListAvailable -Name $m)) { Install-Module $m -Scope CurrentUser -Force -AllowClobber }
}
Import-Module Az.Accounts -ErrorAction Stop; Import-Module Az.Security -ErrorAction Stop
if (-not (Get-AzContext)) { Connect-AzAccount | Out-Null }
if ($SubscriptionId) { Set-AzContext -SubscriptionId $SubscriptionId | Out-Null }

$observed = @{}
try { $a = Get-AzSecurityAssessment -ErrorAction SilentlyContinue; $t = Get-AzSecurityTask -ErrorAction SilentlyContinue; $observed['reco'] = (@($t).Count + @($a | Where-Object { $_.Status.Code -ne 'Healthy' }).Count) } catch { $observed['reco'] = -1 }
try { $s = Get-AzSecuritySecureScore -ErrorAction SilentlyContinue; $observed['score'] = @($s).Count } catch { $observed['score'] = -1 }
try { $al = Get-AzSecurityAlert -ErrorAction SilentlyContinue; $observed['alert'] = @($al).Count } catch { $observed['alert'] = -1 }
$observed['portal'] = -2  # confirm regulatory compliance in the portal

if ($CriteriaPath -and (Test-Path $CriteriaPath)) {
    $criteria = Get-Content $CriteriaPath -Raw | ConvertFrom-Json
} else {
    Write-Host "No -CriteriaPath supplied; using default PoC criteria." -ForegroundColor Yellow
    $criteria = @(
        [pscustomobject]@{ id='reco';  label='Recommendation raised';    capability='reco';   required=$true },
        [pscustomobject]@{ id='score'; label='Secure Score present';     capability='score';  required=$true },
        [pscustomobject]@{ id='alert'; label='Security alert fired';      capability='alert';  required=$true },
        [pscustomobject]@{ id='comp';  label='Regulatory compliance data';capability='portal'; required=$false }
    )
}

Write-Host "`n=== POCMDC scorecard ===" -ForegroundColor Cyan
$rows = @(); $passCount = 0; $reqFail = 0
foreach ($c in $criteria) {
    $obs = if ($observed.ContainsKey($c.capability)) { $observed[$c.capability] } else { 0 }
    if ($obs -eq -2) {
        $result = 'CONFIRM-IN-PORTAL'
        Write-Host ("  [{0}] {1} (confirm in Defender for Cloud -> Regulatory compliance)" -f $result, $c.label) -ForegroundColor Cyan
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
    solution   = 'Proof-of-Concept Kit - Microsoft Defender for Cloud'
    generated  = (Get-Date).ToString('u')
    criteria   = $rows
    passCount  = $passCount
    total      = $criteria.Count
    overall    = $overall
    note       = 'Benign test signal (sample alerts + benign misconfig + EICAR). Final verdict is the customer decision. Remember to disable the Defender plan at teardown.'
}
$card | ConvertTo-Json -Depth 6 | Set-Content -Path $OutFile -Encoding utf8
Write-Host ("`nOverall: {0}  ({1}/{2} checks passed). Saved: {3}" -f $overall, $passCount, $criteria.Count, $OutFile) -ForegroundColor Cyan
Write-Host "Next (when done): POCMDC-Teardown.ps1 -WhatIf  (disable the plan to stop billing)" -ForegroundColor Cyan
