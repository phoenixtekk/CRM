<#
.SYNOPSIS
    WSMDE-Report.ps1 — report MDE workshop cohort progress and per-lab data availability (read-only).
.DESCRIPTION
    PURPOSE
        Produces a shareable summary of the workshop: for each hunting lab, how many rows its query
        returns against the live tenant right now (a "does this lab have data to teach on?" signal),
        onboarded-device count, cohort size, and a place to record knowledge-check scores. Read-only.
    HOW TO RUN
        pwsh -File .\WSMDE-Report.ps1
        pwsh -File .\WSMDE-Report.ps1 -Cohort "Grp-MDEWorkshop-Cohort" -OutputCsv .\wsmde-cohort.csv

        Prereqs: Microsoft.Graph; sign in with a read/hunt account. Government cloud: pass -Environment.
    EXPECTED RESULTS
        A per-lab table (rows-returned now), device + cohort counts, and an optional CSV export you can
        hand to stakeholders as workshop evidence. Read-only.
.NOTES
    White-label. Read-only. Microsoft.Graph (security) + KQL via Graph runHuntingQuery. Knowledge-check
    scores are instructor-entered. No credentials in code.
#>

[CmdletBinding()]
param(
    [string] $Cohort = 'Grp-MDEWorkshop-Cohort',
    [string] $OutputCsv,
    [ValidateSet('Global','USGov','USGovDoD')] [string] $Environment = 'Global'
)

$ErrorActionPreference = 'Stop'
function Write-Section([string] $Title) { Write-Host ''; Write-Host ("=== {0} ===" -f $Title) -ForegroundColor Cyan }

try { Connect-MgGraph -Scopes 'ThreatHunting.Read.All','Group.Read.All' -Environment $Environment -NoWelcome -ErrorAction Stop }
catch { Write-Error ("Failed to connect to Graph: {0}" -f $_.Exception.Message); return }

$LabProbes = [ordered]@{
    'Lab1/4 Process events (DeviceProcessEvents)' = "DeviceProcessEvents | where Timestamp > ago(24h) | count"
    'Lab4 Network events (DeviceNetworkEvents)'   = "DeviceNetworkEvents | where Timestamp > ago(24h) | count"
    'Lab5 ASR audit events (DeviceEvents/Asr)'    = "DeviceEvents | where Timestamp > ago(7d) | where ActionType startswith 'Asr' | count"
    'Lab6 Logon events (DeviceLogonEvents)'       = "DeviceLogonEvents | where Timestamp > ago(24h) | count"
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

Write-Section 'Onboarded devices'
try {
    $body = @{ Query = "DeviceInfo | where Timestamp > ago(24h) | summarize by DeviceId | count" } | ConvertTo-Json
    $r = Invoke-MgGraphRequest -Method POST -Uri 'https://graph.microsoft.com/v1.0/security/runHuntingQuery' -Body $body
    Write-Host ("  {0} devices seen (24h)." -f (if ($r.results) { [int]$r.results[0].Count } else { 0 })) -ForegroundColor Green
}
catch { Write-Host '  DeviceInfo query failed — verify onboarding/schema.' -ForegroundColor Yellow }

Write-Section ("Cohort: {0}" -f $Cohort)
try {
    $grp = Get-MgGroup -Filter "displayName eq '$Cohort'" -ErrorAction Stop
    if ($grp) { Write-Host ("  {0} learners." -f @(Get-MgGroupMember -GroupId $grp.Id -All).Count) -ForegroundColor Green }
    else { Write-Host '  Cohort group not found — create it (Step 0.2).' -ForegroundColor Yellow }
}
catch { Write-Host '  Could not read cohort group.' -ForegroundColor Yellow }

Write-Section 'Knowledge-check scores'
Write-Host '  Record each learner''s Check-MDELab-Pilot score here (WSMDE-Validate.ps1 prints the answer key).'

if ($OutputCsv) {
    $report | Export-Csv -Path $OutputCsv -NoTypeInformation -Encoding UTF8
    Write-Host ("`nWrote {0}" -f $OutputCsv) -ForegroundColor Green
}
Write-Host ''
Write-Host 'Report complete. Use this as workshop evidence alongside the WSMDE-Validate.ps1 gate results.' -ForegroundColor Cyan
