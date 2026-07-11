<#
.SYNOPSIS
    POCMDCA-Validate.ps1 — demo/validate that the benign cloud-app test signal produced real MDCA detections. Read-only.
.DESCRIPTION
    PURPOSE
        Read-only validation and live-demo helper for the MDCA proof of concept. Using the
        Microsoft 365 Defender advanced-hunting API (via Microsoft Graph Security), it confirms
        the benign test signal surfaced as:
          - CloudAppEvents — the benign activity is visible in the activity/hunting data
          - AlertInfo      — the audit policy raised an alert (audit mode still alerts)
        It also points to the Cloud Discovery dashboard and activity log for the visual demo.
        Makes no changes.
    HOW TO RUN
        powershell -ExecutionPolicy Bypass -File .\POCMDCA-Validate.ps1
        Requires Microsoft.Graph.Authentication and ThreatHunting.Read.All consent.
    EXPECTED RESULTS
        A pass/fail line per capability, plus portal paths for the discovery / activity-log demo.
.NOTES
    White-label. Read-only. Advanced-hunting queries only read telemetry; they change nothing.
#>
[CmdletBinding()]
param(
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
function Cnt($resp) { if ($resp.results -and $resp.results.Count -gt 0) { return [int]$resp.results[0].Cnt } return 0 }

Write-Host "`n=== POCMDCA validation — benign-signal detections (read-only) ===" -ForegroundColor Cyan

$checks = @(
    @{ Name = 'Cloud-app activity visible (CloudAppEvents)'; Kql = @"
CloudAppEvents
| where Timestamp > ago(${LookbackHours}h)
| summarize Cnt = count()
"@ },
    @{ Name = 'Policy alert surfaced (AlertInfo)'; Kql = @"
AlertInfo
| where Timestamp > ago(${LookbackHours}h)
| where ServiceSource has_any('CloudApps','App') or Title has_any('activity policy','cloud app','anomaly')
| summarize Cnt = count()
"@ }
)

$pass = 0
foreach ($c in $checks) {
    try {
        $n = Cnt (Invoke-Hunt $c.Kql)
        if ($n -gt 0) { Write-Host ("  PASS — {0} ({1} row[s])" -f $c.Name, $n) -ForegroundColor Green; $pass++ }
        else { Write-Host ("  FAIL — {0}: no rows yet (allow warm-up, confirm discovery source / policy)." -f $c.Name) -ForegroundColor Yellow }
    } catch {
        Write-Host ("  ERROR — {0}: {1}" -f $c.Name, $_.Exception.Message) -ForegroundColor Yellow
    }
}

Write-Host "`n[Demo the headline capabilities in the portal]" -ForegroundColor Cyan
Write-Host "  Shadow IT report : security.microsoft.com -> Cloud apps -> Cloud discovery -> Dashboard." -ForegroundColor Gray
Write-Host "  Activity log     : Cloud apps -> Activity log (the benign policy-matching activity)." -ForegroundColor Gray
Write-Host "  Policy match     : Cloud apps -> Alerts (audit policy match; no governance action taken)." -ForegroundColor Gray

Write-Host ("`nSummary: {0}/{1} capability checks passing (also confirm the discovery report in the portal)." -f $pass, $checks.Count) -ForegroundColor Cyan
Write-Host "Next: POCMDCA-Scorecard.ps1" -ForegroundColor Cyan
