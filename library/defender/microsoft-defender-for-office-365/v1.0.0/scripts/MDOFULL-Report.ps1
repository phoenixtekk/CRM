<#
.SYNOPSIS
    MDOFULL-Report.ps1 — report cohort progress + per-lab data, and capture the PoC evidence scorecard (read-only).
.DESCRIPTION
    PURPOSE
        Produces the shareable outputs for both tracks:
          - Track A (enable): for each email hunting lab, how many rows its query returns against the
            live tenant now (a "does this lab have data to teach on?" signal), plus the cohort and pilot
            group sizes.
          - Track B (prove): re-checks the key MDO capabilities exercised by the benign PoC signal
            (mail processed, Safe Links engaged, Safe Attachments saw the attachment, spam/phish
            handled), maps each to the pass/fail evaluation criteria you agreed up front, and writes an
            evidence scorecard (JSON) — the PoC decision artefact.
        Read-only — it only queries and reports. Whether the PoC "passed" and how criteria are weighted
        is the customer's decision.
    HOW TO RUN
        pwsh -File .\MDOFULL-Report.ps1
        pwsh -File .\MDOFULL-Report.ps1 -OutputCsv .\mdofull-cohort.csv
        pwsh -File .\MDOFULL-Report.ps1 -CriteriaPath .\criteria.json -EvidenceOut "MDOFULL Evidence - Pilot Users - Validate.json"

        Sample criteria.json:
          [
            { "id":"mail",      "label":"Mail processed by MDO",     "capability":"mail",      "required":true  },
            { "id":"safelinks", "label":"Safe Links engaged",        "capability":"safelinks", "required":true  },
            { "id":"safeattach","label":"Safe Attachments detonated","capability":"safeattach","required":true  },
            { "id":"spam",      "label":"Spam/phish handled",        "capability":"spam",      "required":false }
          ]

        Prereqs: Microsoft.Graph; sign in with a read/hunt account. Government cloud: pass -Environment.
        Attack-simulation per-user detail is authoritative in the portal (Graph endpoints are beta).
    EXPECTED RESULTS
        A per-lab data table, cohort/pilot counts, a per-criterion PASS/FAIL PoC scorecard, and a saved
        evidence JSON + optional CSV you can hand to stakeholders. Read-only.
.NOTES
    White-label. Read-only. Microsoft.Graph (security) + KQL via Graph runHuntingQuery. Knowledge-check
    scores are instructor-entered; attack-sim per-user detail lives in the portal. All PoC signal is
    BENIGN. No credentials in code. Table/column names evolve and can differ by plan/cloud — verify.
#>

[CmdletBinding()]
param(
    [string] $Cohort      = 'Grp-MDOFULL-Cohort-Pilot',
    [string] $PilotGroup  = 'Grp-MDOFULL-PilotUsers-Pilot',
    [string] $OutputCsv,
    [string] $CriteriaPath,
    [string] $EvidenceOut = 'MDOFULL Evidence - Pilot Users - Validate.json',
    [int]    $LookbackHours = 12,
    [ValidateSet('Global','USGov','USGovDoD')] [string] $Environment = 'Global'
)

$ErrorActionPreference = 'Stop'
function Write-Section([string] $Title) { Write-Host ''; Write-Host ("=== {0} ===" -f $Title) -ForegroundColor Cyan }
function Invoke-Hunt([string]$Query) {
    $body = @{ Query = $Query } | ConvertTo-Json
    return Invoke-MgGraphRequest -Method POST -Uri 'https://graph.microsoft.com/v1.0/security/runHuntingQuery' -Body $body -ContentType 'application/json'
}
function Cnt($resp) { if ($resp.results -and $resp.results.Count -gt 0) { return [int]$resp.results[0].Cnt } return 0 }

try { Connect-MgGraph -Scopes 'ThreatHunting.Read.All','Group.Read.All' -Environment $Environment -NoWelcome -ErrorAction Stop }
catch { Write-Error ("Failed to connect to Graph: {0}" -f $_.Exception.Message); return }

# --- Track A: per-lab data availability -------------------------------------------------------------
$LabProbes = [ordered]@{
    'Lab5a Post-delivery clicks (UrlClickInfo)' = "UrlClickInfo | where Timestamp > ago(7d) | summarize Cnt = count()"
    'Lab5b Received mail (EmailEvents)'          = "EmailEvents | where Timestamp > ago(24h) | summarize Cnt = count()"
    'Lab5c Attachments (EmailAttachmentInfo)'    = "EmailAttachmentInfo | where Timestamp > ago(7d) | summarize Cnt = count()"
    'Lab8 Delivered-then-detected (phish/mal)'   = "EmailEvents | where Timestamp > ago(7d) | where DeliveryAction == 'Delivered' and (ThreatTypes has 'Phish' or ThreatTypes has 'Malware') | summarize Cnt = count()"
}
Write-Section 'Per-lab data availability (rows now — a live table means the lab has something to teach on)'
$report = New-Object System.Collections.Generic.List[object]
foreach ($lab in $LabProbes.Keys) {
    $rows = $null; $status = 'OK'
    try {
        $rows = Cnt (Invoke-Hunt $LabProbes[$lab])
        if ($rows -eq 0) { $status = 'EMPTY' }
    }
    catch { $status = 'N/A (schema)'; $rows = -1 }
    $report.Add([pscustomobject]@{ Lab=$lab; RowsNow=$rows; Status=$status })
}
$report | Format-Table -AutoSize

# --- Cohort / pilot group sizes ---------------------------------------------------------------------
foreach ($g in @($Cohort, $PilotGroup)) {
    Write-Section ("Group: {0}" -f $g)
    try {
        $grp = Get-MgGroup -Filter "displayName eq '$g'" -ErrorAction Stop
        if ($grp) { Write-Host ("  {0} members." -f @(Get-MgGroupMember -GroupId $grp.Id -All).Count) -ForegroundColor Green }
        else { Write-Host '  Group not found — create it (Step 0.2).' -ForegroundColor Yellow }
    }
    catch { Write-Host '  Could not read group.' -ForegroundColor Yellow }
}

# --- Track B: PoC evidence scorecard ----------------------------------------------------------------
Write-Section 'PoC evidence — observed capabilities vs your criteria'
$cap = @{
    mail       = "EmailEvents | where Timestamp > ago(${LookbackHours}h) | summarize Cnt = count()"
    safelinks  = "UrlClickInfo | where Timestamp > ago(${LookbackHours}h) | summarize Cnt = count()"
    safeattach = "EmailAttachmentInfo | where Timestamp > ago(${LookbackHours}h) | summarize Cnt = count()"
    spam       = "EmailEvents | where Timestamp > ago(${LookbackHours}h) | where ThreatTypes has_any('Spam','Phish') or DeliveryAction has 'Quarantine' | summarize Cnt = count()"
}
$observed = @{}
foreach ($k in $cap.Keys) { try { $observed[$k] = (Cnt (Invoke-Hunt $cap[$k])) } catch { $observed[$k] = -1 } }

if ($CriteriaPath -and (Test-Path $CriteriaPath)) {
    $criteria = Get-Content $CriteriaPath -Raw | ConvertFrom-Json
} else {
    Write-Host '  No -CriteriaPath supplied; using default PoC criteria.' -ForegroundColor Yellow
    $criteria = @(
        [pscustomobject]@{ id='mail';       label='Mail processed by MDO';      capability='mail';       required=$true  },
        [pscustomobject]@{ id='safelinks';  label='Safe Links engaged';         capability='safelinks';  required=$true  },
        [pscustomobject]@{ id='safeattach'; label='Safe Attachments detonated'; capability='safeattach'; required=$true  },
        [pscustomobject]@{ id='spam';       label='Spam/phish handled';         capability='spam';       required=$false }
    )
}

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
    solution    = 'Microsoft Defender for Office 365 - Enable & Prove'
    generated   = (Get-Date).ToString('u')
    lookbackHrs = $LookbackHours
    criteria    = $rows
    passCount   = $passCount
    total       = @($criteria).Count
    overall     = $overall
    note        = 'Benign test signal (Attack Simulation / GTUBE / EICAR / benign URL). Final verdict is the customer decision. Threat Explorer/simulation need P2 — verify.'
}
$card | ConvertTo-Json -Depth 6 | Set-Content -Path $EvidenceOut -Encoding utf8
Write-Host ("`n  Overall: {0}  ({1}/{2} criteria passed). Evidence saved: {3}" -f $overall, $passCount, @($criteria).Count, $EvidenceOut) -ForegroundColor Cyan

Write-Section 'Attack Simulation Training — user-risk'
Write-Host '  Per-user susceptibility / repeat-offender detail is authoritative in the portal:'
Write-Host '  Email & collaboration -> Attack simulation training -> Simulations -> Sim-MDOFULL-Pilot report.'
Write-Host '  (Graph attack-simulation endpoints are beta — verify availability for your cloud.)' -ForegroundColor DarkGray

Write-Section 'Knowledge-check scores'
Write-Host '  Record each learner''s Check-MDOFULL-Pilot score here (MDOFULL-Validate.ps1 prints the answer key).'

if ($OutputCsv) {
    $report | Export-Csv -Path $OutputCsv -NoTypeInformation -Encoding UTF8
    Write-Host ("`n  Wrote {0}" -f $OutputCsv) -ForegroundColor Green
}
Write-Host ''
Write-Host 'Report complete. Use the evidence scorecard + MDOFULL-Validate.ps1 gate results as the PoC decision record.' -ForegroundColor Cyan
