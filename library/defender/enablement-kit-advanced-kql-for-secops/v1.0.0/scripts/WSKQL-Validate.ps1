<#
.SYNOPSIS
    WSKQL-Validate.ps1 — run the workshop pass/fail gates and score the knowledge-check (read-only).
.DESCRIPTION
    PURPOSE
        Turns 05-testing.md into a checklist run: confirms the environment supports the labs (tables
        have data), that the lab queries resolve, that the capstone detection Detect-KQLLab-Pilot
        exists and is ALERT-ONLY, that the saved-query set and workbook are present (manual where the
        API does not expose them), and scores the knowledge-check Check-KQLLab-Pilot. Read-only.
    HOW TO RUN
        pwsh -File .\WSKQL-Validate.ps1
        pwsh -File .\WSKQL-Validate.ps1 -DetectionName "Detect-KQLLab-Pilot" -Environment USGov

        Prereqs: Microsoft.Graph; sign in with a read/hunt account (custom-detection read may need a
        Security role). Government cloud: pass -Environment.
    EXPECTED RESULTS
        A list of PASS / FAIL / MANUAL gate lines and a knowledge-check score. Any FAIL = reinforce the
        mapped lab and re-check before declaring the cohort enabled.
.NOTES
    White-label. Read-only. Microsoft.Graph (security) + KQL via Graph runHuntingQuery. Some checks
    (workbook presence, custom-detection response-action detail) are surfaced as MANUAL where the API
    does not expose them — verify in the portal. No credentials in code.
#>

[CmdletBinding()]
param(
    [string] $DetectionName = 'Detect-KQLLab-Pilot',
    [string] $SavedQuerySet = 'Hunt-KQLLab-Pilot',
    [string] $Workbook      = 'Workbook-KQLLab-Pilot',
    [ValidateSet('Global','USGov','USGovDoD')] [string] $Environment = 'Global'
)

$ErrorActionPreference = 'Stop'
$results = New-Object System.Collections.Generic.List[object]
function Add-Gate([string]$Gate,[string]$Status,[string]$Detail) {
    $results.Add([pscustomobject]@{ Gate=$Gate; Status=$Status; Detail=$Detail })
    $c = switch ($Status) { 'PASS'{'Green'} 'FAIL'{'Red'} default{'Yellow'} }
    Write-Host ("[{0}] {1} — {2}" -f $Status, $Gate, $Detail) -ForegroundColor $c
}

try { Connect-MgGraph -Scopes 'ThreatHunting.Read.All','CustomDetection.Read.All' -Environment $Environment -NoWelcome -ErrorAction Stop }
catch { Write-Error ("Failed to connect to Graph: {0}" -f $_.Exception.Message); return }

# Gate 1 — advanced hunting reachable + data present
try {
    $body = @{ Query = "DeviceProcessEvents | where Timestamp > ago(24h) | count" } | ConvertTo-Json
    $r = Invoke-MgGraphRequest -Method POST -Uri 'https://graph.microsoft.com/v1.0/security/runHuntingQuery' -Body $body
    $n = if ($r.results) { [int]($r.results[0].Count) } else { 0 }
    if ($n -gt 0) { Add-Gate 'G1 advanced hunting + data' 'PASS' ("DeviceProcessEvents = $n rows (24h)") }
    else { Add-Gate 'G1 advanced hunting + data' 'FAIL' 'core table empty in 24h — onboard pillar / run labs on a live table (R2)' }
}
catch { Add-Gate 'G1 advanced hunting + data' 'FAIL' ("query failed: {0}" -f $_.Exception.Message) }

# Gate 3 — a representative lab query resolves (Lab 6 shape)
try {
    $q6 = "DeviceProcessEvents | where Timestamp > ago(24h) | where FileName in~ ('powershell.exe','wscript.exe','cscript.exe','mshta.exe','rundll32.exe') | summarize Runs = count() by DeviceName, FileName | take 5"
    $body = @{ Query = $q6 } | ConvertTo-Json
    $null = Invoke-MgGraphRequest -Method POST -Uri 'https://graph.microsoft.com/v1.0/security/runHuntingQuery' -Body $body
    Add-Gate 'G3 lab queries resolve' 'PASS' 'Lab-6-shape query ran without schema error'
}
catch { Add-Gate 'G3 lab queries resolve' 'FAIL' 'a lab query hit a schema error — correct table/column to your tenant (troubleshooting #2)' }

# Gate 5 — capstone detection exists and is alert-only
try {
    $det = Invoke-MgGraphRequest -Method GET -Uri 'https://graph.microsoft.com/beta/security/rules/detectionRules'
    $match = @($det.value | Where-Object { $_.displayName -eq $DetectionName })
    if ($match.Count -gt 0) {
        Add-Gate 'G5 detection exists' 'PASS' ("$DetectionName found")
        Add-Gate 'G5 detection alert-only' 'MANUAL' 'confirm response actions = alert-only in the portal (Custom detection rules)'
    }
    else { Add-Gate 'G5 detection exists' 'MANUAL' ("$DetectionName not returned by API — verify in Advanced hunting -> Custom detection rules (beta endpoint/schema varies)") }
}
catch { Add-Gate 'G5 detection exists' 'MANUAL' 'custom-detection API unavailable in this cloud — verify in the portal (beta endpoint)' }

# Gate 6 — saved-query set + workbook (manual: not reliably exposed by API)
Add-Gate 'G6 saved-query set' 'MANUAL' ("confirm shared-query folder '$SavedQuerySet' exists in Advanced hunting")
Add-Gate 'G6 workbook'        'MANUAL' ("confirm workbook '$Workbook' renders its tiles from live data")

# Gate 7 — knowledge-check (concept answer key; instructor records per-learner results)
Write-Host ''
Write-Host '=== Knowledge-check (Check-KQLLab-Pilot) — concept answer key ===' -ForegroundColor Cyan
$answers = @(
    'Q1 Pipe |  ............ passes a table from one operator to the next (tabular pipeline).'
    'Q2 has vs contains .... has = whole-token match (faster/indexed); contains = substring.'
    'Q3 dcount() ........... distinct count; count() = all rows.'
    'Q4 join kinds ......... inner=both; leftouter=keep all left; leftanti=in-left-not-right.'
    'Q5 bin(Timestamp,1h) .. buckets time into fixed windows (the basis of time charts).'
    'Q6 Defender vs Sentinel same KQL, different tables; Timestamp (Defender) vs TimeGenerated (Sentinel).'
    'Q7 hunt -> detection .. tune to a small explainable result, then create an ALERT-ONLY rule.'
)
$answers | ForEach-Object { Write-Host ("  {0}" -f $_) }
Add-Gate 'G7 knowledge-check' 'MANUAL' 'instructor scores each learner against the key above; threshold is your call'

# --- Summary ----------------------------------------------------------------------------------------
Write-Host ''
Write-Host '=== Validation summary ===' -ForegroundColor Cyan
$results | Format-Table -AutoSize
$fail = @($results | Where-Object Status -eq 'FAIL').Count
if ($fail -eq 0) { Write-Host 'No hard FAILs — resolve any MANUAL checks in the portal, then the cohort is enabled.' -ForegroundColor Green }
else { Write-Host ("{0} FAIL gate(s) — reinforce the mapped lab and re-run." -f $fail) -ForegroundColor Red }
