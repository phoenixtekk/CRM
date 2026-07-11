<#
.SYNOPSIS
    WSMDE-Validate.ps1 — run the MDE workshop pass/fail gates and score the knowledge-check (read-only).
.DESCRIPTION
    PURPOSE
        Turns 05-testing.md into a checklist run: confirms endpoint tables have data, that a
        representative hunting-lab query resolves, that the capstone detection Detect-MDELab-Pilot
        exists (alert-only confirmed in the portal), and scores the knowledge-check Check-MDELab-Pilot.
        ASR-audit-only and Live-Response-read-only are surfaced as MANUAL portal checks. Read-only.
    HOW TO RUN
        pwsh -File .\WSMDE-Validate.ps1
        pwsh -File .\WSMDE-Validate.ps1 -DetectionName "Detect-MDELab-Pilot" -Environment USGov

        Prereqs: Microsoft.Graph; sign in with a read/hunt account. Government cloud: pass -Environment.
    EXPECTED RESULTS
        A list of PASS / FAIL / MANUAL gate lines and a knowledge-check answer key + score prompt.
        Any FAIL = reinforce the mapped lab and re-check.
.NOTES
    White-label. Read-only. Microsoft.Graph (security) + KQL via Graph runHuntingQuery. Some checks
    (ASR mode, Live Response transcript, detection response-action) are MANUAL portal checks. No
    credentials in code.
#>

[CmdletBinding()]
param(
    [string] $DetectionName = 'Detect-MDELab-Pilot',
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

# Gate 1 — endpoint tables have data
try {
    $body = @{ Query = "DeviceProcessEvents | where Timestamp > ago(24h) | count" } | ConvertTo-Json
    $r = Invoke-MgGraphRequest -Method POST -Uri 'https://graph.microsoft.com/v1.0/security/runHuntingQuery' -Body $body
    $n = if ($r.results) { [int]($r.results[0].Count) } else { 0 }
    if ($n -gt 0) { Add-Gate 'G1 MDE onboarded + data' 'PASS' ("DeviceProcessEvents = $n rows (24h)") }
    else { Add-Gate 'G1 MDE onboarded + data' 'FAIL' 'endpoint tables empty — onboard devices (R1)' }
}
catch { Add-Gate 'G1 MDE onboarded + data' 'FAIL' ("query failed: {0}" -f $_.Exception.Message) }

# Gate 3 — a representative hunting-lab query resolves (Lab 4 shape)
try {
    $q = "DeviceProcessEvents | where Timestamp > ago(24h) | where FileName in~ ('powershell.exe','wscript.exe','mshta.exe','rundll32.exe') | join kind=inner (DeviceNetworkEvents | where Timestamp > ago(24h) | summarize c=count() by DeviceId) on DeviceId | take 5"
    $body = @{ Query = $q } | ConvertTo-Json
    $null = Invoke-MgGraphRequest -Method POST -Uri 'https://graph.microsoft.com/v1.0/security/runHuntingQuery' -Body $body
    Add-Gate 'G3 hunting labs resolve' 'PASS' 'Lab-4-shape join query ran without schema error'
}
catch { Add-Gate 'G3 hunting labs resolve' 'FAIL' 'a lab query hit a schema error — correct table/column to your tenant (troubleshooting #3)' }

# Gate 5 — ASR audit-only (manual: mode not read here)
Add-Gate 'G5 ASR audit-only' 'MANUAL' 'confirm ASR-Lab-AuditOnly-Pilot rules are AUDIT (never block) on the lab devices'

# Gate 6 — Live Response read-only (manual)
Add-Gate 'G6 Live Response read-only' 'MANUAL' 'review Live Response history: only processes/dir/fileinfo/getfile — no run/remediate/putfile'

# Gate 7 — capstone detection exists and alert-only
try {
    $det = Invoke-MgGraphRequest -Method GET -Uri 'https://graph.microsoft.com/beta/security/rules/detectionRules'
    $match = @($det.value | Where-Object { $_.displayName -eq $DetectionName })
    if ($match.Count -gt 0) {
        Add-Gate 'G7 detection exists' 'PASS' ("$DetectionName found")
        Add-Gate 'G7 detection alert-only' 'MANUAL' 'confirm response = alert-only (no isolate/remediate) in the portal'
    }
    else { Add-Gate 'G7 detection exists' 'MANUAL' ("$DetectionName not returned by API — verify in Custom detection rules (beta endpoint/schema varies)") }
}
catch { Add-Gate 'G7 detection exists' 'MANUAL' 'custom-detection API unavailable in this cloud — verify in the portal' }

# Gate 8 — knowledge-check (concept answer key)
Write-Host ''
Write-Host '=== Knowledge-check (Check-MDELab-Pilot) — concept answer key ===' -ForegroundColor Cyan
@(
    'Q1 Incident vs alert . an incident groups related alerts + evidence across devices/identities.'
    'Q2 Alert story ....... the process tree that reconstructs how the alert happened (root cause).'
    'Q3 Device timeline ... per-device chronological event record — ground truth for "what happened".'
    'Q4 ASR rollout ....... audit -> read DeviceEvents -> enforce by ring with rollback (never block-first).'
    'Q5 Live Response ..... read-only: processes/dir/fileinfo/getfile; change: run/remediate/putfile (gated).'
    'Q6 Response actions .. isolate / restrict / collect package / stop-quarantine / AV scan — each approval-gated.'
    'Q7 hunt -> detection . tune to a small explainable result, then create an ALERT-ONLY rule.'
) | ForEach-Object { Write-Host ("  {0}" -f $_) }
Add-Gate 'G8 knowledge-check' 'MANUAL' 'instructor scores each learner against the key above'

Write-Host ''
Write-Host '=== Validation summary ===' -ForegroundColor Cyan
$results | Format-Table -AutoSize
$fail = @($results | Where-Object Status -eq 'FAIL').Count
if ($fail -eq 0) { Write-Host 'No hard FAILs — resolve MANUAL checks in the portal, then the cohort is enabled.' -ForegroundColor Green }
else { Write-Host ("{0} FAIL gate(s) — reinforce the mapped lab and re-run." -f $fail) -ForegroundColor Red }
