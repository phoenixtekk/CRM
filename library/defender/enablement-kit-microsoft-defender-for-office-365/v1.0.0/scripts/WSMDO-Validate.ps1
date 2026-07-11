<#
.SYNOPSIS
    WSMDO-Validate.ps1 — run the MDO workshop pass/fail gates and score the knowledge-check (read-only).
.DESCRIPTION
    PURPOSE
        Turns 05-testing.md into a checklist run: confirms email tables have data, that a
        representative email hunting-lab query resolves, that the capstone detection Detect-MDOLab-Pilot
        exists (alert-only confirmed in the portal), and scores the knowledge-check Check-MDOLab-Pilot.
        Simulation-reported and AIR-pending are surfaced as MANUAL portal checks. Read-only.
    HOW TO RUN
        pwsh -File .\WSMDO-Validate.ps1
        pwsh -File .\WSMDO-Validate.ps1 -DetectionName "Detect-MDOLab-Pilot" -Environment USGov

        Prereqs: Microsoft.Graph; sign in with a read/hunt account. Government cloud: pass -Environment.
    EXPECTED RESULTS
        A list of PASS / FAIL / MANUAL gate lines and a knowledge-check answer key + score prompt.
        Any FAIL = reinforce the mapped lab and re-check.
.NOTES
    White-label. Read-only. Microsoft.Graph (security) + KQL via Graph runHuntingQuery. Some checks
    (simulation report, AIR posture, detection response-action) are MANUAL portal checks. No
    credentials in code.
#>

[CmdletBinding()]
param(
    [string] $DetectionName = 'Detect-MDOLab-Pilot',
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

# Gate 3 — email tables have data
try {
    $body = @{ Query = "EmailEvents | where Timestamp > ago(24h) | count" } | ConvertTo-Json
    $r = Invoke-MgGraphRequest -Method POST -Uri 'https://graph.microsoft.com/v1.0/security/runHuntingQuery' -Body $body
    $n = if ($r.results) { [int]($r.results[0].Count) } else { 0 }
    if ($n -gt 0) { Add-Gate 'G3 email tables have data' 'PASS' ("EmailEvents = $n rows (24h)") }
    else { Add-Gate 'G3 email tables have data' 'FAIL' 'EmailEvents empty — confirm Plan 2 + mail flowing (R1/G3)' }
}
catch { Add-Gate 'G3 email tables have data' 'FAIL' ("query failed: {0} — verify Plan 2 / schema" -f $_.Exception.Message) }

# Gate 5 — a representative email hunting-lab query resolves (Lab 5a shape)
try {
    $q = "let look = ago(24h); UrlClickInfo | where Timestamp > look | join kind=inner (EmailEvents | where Timestamp > look and DeliveryAction == 'Delivered') on NetworkMessageId | take 5"
    $body = @{ Query = $q } | ConvertTo-Json
    $null = Invoke-MgGraphRequest -Method POST -Uri 'https://graph.microsoft.com/v1.0/security/runHuntingQuery' -Body $body
    Add-Gate 'G5 email hunting resolves' 'PASS' 'Lab-5a-shape join query ran without schema error'
}
catch { Add-Gate 'G5 email hunting resolves' 'FAIL' 'a lab query hit a schema error — correct table/column to your tenant (troubleshooting #4)' }

# Gate 4 — lab simulation reported (manual)
Add-Gate 'G4 lab simulation reported' 'MANUAL' 'confirm Sim-MDOLab-Pilot completed with a report and Training-MDOLab-Pilot assigned (Attack simulation training)'

# Gate 6 — AIR pending, not auto-applied (manual)
Add-Gate 'G6 AIR pending not applied' 'MANUAL' 'confirm AIR actions are in Action center -> Pending, not auto-applied (approval-required)'

# Gate 7 — capstone detection exists and alert-only
try {
    $det = Invoke-MgGraphRequest -Method GET -Uri 'https://graph.microsoft.com/beta/security/rules/detectionRules'
    $match = @($det.value | Where-Object { $_.displayName -eq $DetectionName })
    if ($match.Count -gt 0) {
        Add-Gate 'G7 detection exists' 'PASS' ("$DetectionName found")
        Add-Gate 'G7 detection alert-only' 'MANUAL' 'confirm response = alert-only (no remediation) in the portal'
    }
    else { Add-Gate 'G7 detection exists' 'MANUAL' ("$DetectionName not returned by API — verify in Custom detection rules (beta endpoint/schema varies)") }
}
catch { Add-Gate 'G7 detection exists' 'MANUAL' 'custom-detection API unavailable in this cloud — verify in the portal' }

# Gate 8 — knowledge-check (concept answer key)
Write-Host ''
Write-Host '=== Knowledge-check (Check-MDOLab-Pilot) — concept answer key ===' -ForegroundColor Cyan
@(
    'Q1 Two halves ........ prevention (block) vs post-delivery (hunt/respond); MDO does both.'
    'Q2 Threat Explorer ... pivot on sender/URL/file/click; answers who-got-it, who-clicked, still-in-inbox.'
    'Q3 Safe Links/Attach . time-of-click URL rewrite/detonation; attachment sandbox detonation.'
    'Q4 Simulation ........ benign; measures susceptibility + auto-assigns training; not punishment.'
    'Q5 AIR ............... approval-required = recommended actions WAIT in Action center for a human.'
    'Q6 Email tables ...... EmailEvents/EmailUrlInfo/UrlClickInfo/EmailAttachmentInfo (Plan 2).'
    'Q7 hunt -> detection . tune to a small explainable result, then create an ALERT-ONLY rule.'
) | ForEach-Object { Write-Host ("  {0}" -f $_) }
Add-Gate 'G8 knowledge-check' 'MANUAL' 'instructor scores each learner against the key above'

Write-Host ''
Write-Host '=== Validation summary ===' -ForegroundColor Cyan
$results | Format-Table -AutoSize
$fail = @($results | Where-Object Status -eq 'FAIL').Count
if ($fail -eq 0) { Write-Host 'No hard FAILs — resolve MANUAL checks in the portal, then the cohort is enabled.' -ForegroundColor Green }
else { Write-Host ("{0} FAIL gate(s) — reinforce the mapped lab and re-run." -f $fail) -ForegroundColor Red }
