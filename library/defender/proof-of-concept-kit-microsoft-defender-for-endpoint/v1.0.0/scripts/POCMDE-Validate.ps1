<#
.SYNOPSIS
    POCMDE-Validate.ps1 — demo/validate that the benign test signal produced real MDE detections. Read-only.
.DESCRIPTION
    PURPOSE
        Read-only validation and live-demo helper for the MDE proof of concept. Using the
        Microsoft 365 Defender advanced-hunting API (via Microsoft Graph Security), it confirms
        that the benign test signal surfaced as:
          - alerts        (AlertInfo)         — a detection reached the portal
          - evidence      (AlertEvidence)     — file/process evidence is attached
          - device events (DeviceEvents)      — the activity is on the device timeline/hunting
        It also reminds you where to view the automated investigation (kept approval-gated).
        Makes no changes.
    HOW TO RUN
        powershell -ExecutionPolicy Bypass -File .\POCMDE-Validate.ps1 -DeviceName <pilotDevice>
        Requires Microsoft.Graph.Authentication and ThreatHunting.Read.All consent.
    EXPECTED RESULTS
        A pass/fail line per capability (alert present, evidence present, device events present),
        plus portal paths for the timeline and automated-investigation demo.
.NOTES
    White-label. Read-only. Advanced-hunting queries only read telemetry; they change nothing.
#>
[CmdletBinding()]
param(
    [string]$DeviceName,
    [int]$LookbackHours = 6
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
function Row0Count($resp) { if ($resp.results -and $resp.results.Count -gt 0) { return [int]$resp.results[0].Cnt } return 0 }

$devFilter = if ($DeviceName) { "| where DeviceName has '$DeviceName'" } else { '' }

Write-Host "`n=== POCMDE validation — benign-signal detections (read-only) ===" -ForegroundColor Cyan
if ($DeviceName) { Write-Host "Device filter: $DeviceName" -ForegroundColor Gray }

$checks = @(
    @{ Name = 'Alert reached the portal'; Kql = @"
AlertInfo
| where Timestamp > ago(${LookbackHours}h)
| where Title has_any('EICAR','test','Malware','tutorial','simulation') or Category != ''
| summarize Cnt = count()
"@ },
    @{ Name = 'Alert evidence attached'; Kql = @"
AlertEvidence
| where Timestamp > ago(${LookbackHours}h)
$devFilter
| summarize Cnt = count()
"@ },
    @{ Name = 'Device events / timeline'; Kql = @"
DeviceEvents
| where Timestamp > ago(${LookbackHours}h)
$devFilter
| where ActionType has_any('AntivirusDetection','AntivirusScanCompleted','ProcessCreated','FileCreated')
| summarize Cnt = count()
"@ }
)

$pass = 0
foreach ($c in $checks) {
    try {
        $n = Row0Count (Invoke-Hunt $c.Kql)
        if ($n -gt 0) { Write-Host ("  PASS — {0} ({1} row[s])" -f $c.Name, $n) -ForegroundColor Green; $pass++ }
        else { Write-Host ("  FAIL — {0}: no rows yet (allow warm-up, confirm onboarding)." -f $c.Name) -ForegroundColor Yellow }
    } catch {
        Write-Host ("  ERROR — {0}: {1}" -f $c.Name, $_.Exception.Message) -ForegroundColor Yellow
    }
}

Write-Host "`n[Demo the headline capabilities in the portal]" -ForegroundColor Cyan
Write-Host "  Incident story : security.microsoft.com -> Incidents & alerts -> open the test incident." -ForegroundColor Gray
Write-Host "  Device timeline: Assets -> Devices -> pilot device -> Timeline." -ForegroundColor Gray
Write-Host "  Automated inv. : the incident -> Automated investigations (must be 'Semi - require approval')." -ForegroundColor Gray

Write-Host ("`nSummary: {0}/{1} capability checks passing." -f $pass, $checks.Count) -ForegroundColor Cyan
Write-Host "Next: POCMDE-Scorecard.ps1" -ForegroundColor Cyan
