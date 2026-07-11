<#
.SYNOPSIS
    WSMDO-Report.ps1 — report MDO workshop cohort progress and per-lab email-data availability (read-only).
.DESCRIPTION
    PURPOSE
        Produces a shareable summary of the workshop: for each email hunting lab, how many rows its
        query returns against the live tenant right now (a "does this lab have data to teach on?"
        signal), the lab-group and cohort sizes, the post-delivery threat picture, and a place to
        record knowledge-check scores. Read-only — it only queries and reports.
    HOW TO RUN
        pwsh -File .\WSMDO-Report.ps1
        pwsh -File .\WSMDO-Report.ps1 -Cohort "Grp-MDOWorkshop-Cohort" -OutputCsv .\wsmdo-cohort.csv

        Prereqs: Microsoft.Graph; sign in with a read/hunt account. Government cloud: pass -Environment.
        Attack-simulation per-user detail is authoritative in the portal (Graph endpoints are beta).
    EXPECTED RESULTS
        A per-lab table (rows-returned now), cohort count, a post-delivery threat summary, and an
        optional CSV export you can hand to stakeholders as workshop evidence. Read-only.
.NOTES
    White-label. Read-only. Microsoft.Graph (security) + KQL via Graph runHuntingQuery. Knowledge-check
    scores are instructor-entered; attack-sim per-user detail lives in the portal. No credentials in code.
#>

[CmdletBinding()]
param(
    [string] $Cohort = 'Grp-MDOWorkshop-Cohort',
    [string] $OutputCsv,
    [ValidateSet('Global','USGov','USGovDoD')] [string] $Environment = 'Global'
)

$ErrorActionPreference = 'Stop'
function Write-Section([string] $Title) { Write-Host ''; Write-Host ("=== {0} ===" -f $Title) -ForegroundColor Cyan }

try { Connect-MgGraph -Scopes 'ThreatHunting.Read.All','Group.Read.All' -Environment $Environment -NoWelcome -ErrorAction Stop }
catch { Write-Error ("Failed to connect to Graph: {0}" -f $_.Exception.Message); return }

$LabProbes = [ordered]@{
    'Lab5a Post-delivery clicks (UrlClickInfo)' = "UrlClickInfo | where Timestamp > ago(7d) | count"
    'Lab5b Received mail (EmailEvents)'         = "EmailEvents | where Timestamp > ago(24h) | count"
    'Lab5c Attachments (EmailAttachmentInfo)'   = "EmailAttachmentInfo | where Timestamp > ago(7d) | count"
    'Lab8 Delivered-then-detected (phish/mal)'  = "EmailEvents | where Timestamp > ago(7d) | where DeliveryAction == 'Delivered' and (ThreatTypes has 'Phish' or ThreatTypes has 'Malware') | count"
}

Write-Section 'Per-lab data availability (rows now — a live table means the lab has something to teach on)'
$report = New-Object System.Collections.Generic.List[object]
foreach ($lab in $LabProbes.Keys) {
    $rows = $null; $status = 'OK'
    try {
        $body = @{ Query = $LabProbes[$lab] } | ConvertTo-Json
        $r = Invoke-MgGraphRequest -Method POST -Uri 'https://graph.microsoft.com/v1.0/security/runHuntingQuery' -Body $body
        $rows = if ($r.results) { [int]($r.results[0].Count) } else { 0 }
        if ($rows -eq 0) { $status = 'EMPTY' }
    }
    catch { $status = 'N/A (schema)'; $rows = -1 }
    $report.Add([pscustomobject]@{ Lab=$lab; RowsNow=$rows; Status=$status })
}
$report | Format-Table -AutoSize

Write-Section ("Cohort: {0}" -f $Cohort)
try {
    $grp = Get-MgGroup -Filter "displayName eq '$Cohort'" -ErrorAction Stop
    if ($grp) { Write-Host ("  {0} learners." -f @(Get-MgGroupMember -GroupId $grp.Id -All).Count) -ForegroundColor Green }
    else { Write-Host '  Cohort group not found — create it (Step 0.2).' -ForegroundColor Yellow }
}
catch { Write-Host '  Could not read cohort group.' -ForegroundColor Yellow }

Write-Section 'Attack Simulation Training — user-risk'
Write-Host '  Per-user susceptibility / repeat-offender detail is authoritative in the portal:'
Write-Host '  Email & collaboration -> Attack simulation training -> Simulations -> Sim-MDOLab-Pilot report.'
Write-Host '  (Graph attack-simulation endpoints are beta — verify availability for your cloud.)' -ForegroundColor DarkGray

Write-Section 'Knowledge-check scores'
Write-Host '  Record each learner''s Check-MDOLab-Pilot score here (WSMDO-Validate.ps1 prints the answer key).'

if ($OutputCsv) {
    $report | Export-Csv -Path $OutputCsv -NoTypeInformation -Encoding UTF8
    Write-Host ("`nWrote {0}" -f $OutputCsv) -ForegroundColor Green
}
Write-Host ''
Write-Host 'Report complete. Use this as workshop evidence alongside the WSMDO-Validate.ps1 gate results.' -ForegroundColor Cyan
