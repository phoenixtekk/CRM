<#
.SYNOPSIS
    WSKQL-Report.ps1 — report cohort progress and per-lab result summaries (read-only).
.DESCRIPTION
    PURPOSE
        Produces a shareable summary of the workshop: for each lab, how many rows its query returns
        against the live tenant right now (a quick "does this lab have data to teach on?" signal), the
        cohort size, and a place to record knowledge-check scores. Read-only — it only queries and
        reports.
    HOW TO RUN
        pwsh -File .\WSKQL-Report.ps1
        pwsh -File .\WSKQL-Report.ps1 -Cohort "Grp-KQLWorkshop-Cohort" -OutputCsv .\wskql-cohort.csv

        Prereqs: Microsoft.Graph; sign in with a read/hunt account. Government cloud: pass -Environment.
    EXPECTED RESULTS
        A per-lab table (rows-returned now), the cohort count, and an optional CSV export you can hand
        to stakeholders as workshop evidence. Read-only.
.NOTES
    White-label. Read-only. Microsoft.Graph (security) + KQL via Graph runHuntingQuery. Knowledge-check
    scores are entered by the instructor (not derived by API). No credentials in code.
#>

[CmdletBinding()]
param(
    [string] $Cohort = 'Grp-KQLWorkshop-Cohort',
    [string] $OutputCsv,
    [ValidateSet('Global','USGov','USGovDoD')] [string] $Environment = 'Global'
)

$ErrorActionPreference = 'Stop'
function Write-Section([string] $Title) { Write-Host ''; Write-Host ("=== {0} ===" -f $Title) -ForegroundColor Cyan }

try { Connect-MgGraph -Scopes 'ThreatHunting.Read.All','Group.Read.All' -Environment $Environment -NoWelcome -ErrorAction Stop }
catch { Write-Error ("Failed to connect to Graph: {0}" -f $_.Exception.Message); return }

# Count-only probes per lab table (cheap, read-only) — "does this lab have data to teach on?"
$LabProbes = [ordered]@{
    'Lab1 Fundamentals (DeviceProcessEvents)'   = "DeviceProcessEvents | where Timestamp > ago(24h) | count"
    'Lab2 Filtering (encoded PowerShell)'       = "DeviceProcessEvents | where Timestamp > ago(7d) | where FileName =~ 'powershell.exe' and ProcessCommandLine has '-enc' | count"
    'Lab3 Aggregation (DeviceNetworkEvents)'    = "DeviceNetworkEvents | where Timestamp > ago(24h) | count"
    'Lab4/6 Joins (script hosts)'               = "DeviceProcessEvents | where Timestamp > ago(24h) | where FileName in~ ('powershell.exe','wscript.exe','mshta.exe','rundll32.exe') | count"
    'Lab5 Cross-tool (IdentityLogonEvents)'     = "IdentityLogonEvents | where Timestamp > ago(24h) | count"
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

# Cohort size
Write-Section ("Cohort: {0}" -f $Cohort)
$cohortCount = 0
try {
    $grp = Get-MgGroup -Filter "displayName eq '$Cohort'" -ErrorAction Stop
    if ($grp) { $cohortCount = @(Get-MgGroupMember -GroupId $grp.Id -All).Count }
    Write-Host ("  {0} learners." -f $cohortCount) -ForegroundColor Green
}
catch { Write-Host '  Cohort group not found — create it (Step 0.2).' -ForegroundColor Yellow }

# Knowledge-check scores are instructor-entered
Write-Section 'Knowledge-check scores'
Write-Host '  Record each learner''s Check-KQLLab-Pilot score here (WSKQL-Validate.ps1 prints the answer key).'

if ($OutputCsv) {
    $report | Export-Csv -Path $OutputCsv -NoTypeInformation -Encoding UTF8
    Write-Host ("`nWrote {0}" -f $OutputCsv) -ForegroundColor Green
}
Write-Host ''
Write-Host 'Report complete. Use this as workshop evidence alongside the WSKQL-Validate.ps1 gate results.' -ForegroundColor Cyan
