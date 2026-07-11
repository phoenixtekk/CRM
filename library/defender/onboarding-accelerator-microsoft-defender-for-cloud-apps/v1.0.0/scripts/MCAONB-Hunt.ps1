<#
.SYNOPSIS
    MCAONB-Hunt.ps1 — run the cloud-app signal validation KQL to confirm connectors and discovery
    stream CloudAppEvents and that a monitor policy produced signal.
.DESCRIPTION
    PURPOSE
        Read-only advanced-hunting for the "Onboarding Accelerator — Microsoft Defender for Cloud
        Apps" solution. Executes the saved query 'MDCA Signal Validation - Tenant - Validate' via
        Microsoft Graph Security advanced hunting to confirm CloudAppEvents are streaming from the
        connectors/discovery and to surface recent activity for a pilot user so you can confirm a
        monitor policy fired (Testing Guide Tests 6 and 7).
    HOW TO RUN
        powershell -ExecutionPolicy Bypass -File .\MCAONB-Hunt.ps1 -PilotUserUpn 'pilot.user@contoso.com'
        Uses Microsoft.Graph.Authentication and the ThreatHunting.Read.All scope. Read-only.
    EXPECTED RESULTS
        Row counts for CloudAppEvents and recent activity for the pilot user — proof the CASB is
        streaming and a monitor policy generated signal without enforcement.
.NOTES
    White-label. Read-only (advanced hunting). Embedded KQL below is the delivered query.
#>
[CmdletBinding()]
param(
    [string]$PilotUserUpn = 'REPLACE-with-pilot-user-upn@contoso.com',
    [int]$LookbackDays = 1
)

Import-Module Microsoft.Graph.Authentication -ErrorAction Stop
if (-not (Get-MgContext)) { Connect-MgGraph -Scopes 'ThreatHunting.Read.All' -NoWelcome | Out-Null }
Write-Host "`n=== MDCA signal validation hunt (read-only) ===" -ForegroundColor Cyan

$coverageKql = @"
// MDCA Signal Validation - Tenant - Validate  (CloudAppEvents coverage)
let since = ago($($LookbackDays)d);
CloudAppEvents
| where Timestamp > since
| summarize Events=count(), Apps=dcount(Application) by bin(Timestamp, 1h)
| order by Timestamp desc
| take 24
"@

$pilotKql = @"
// MDCA Signal Validation - Tenant - Validate  (pilot-user activity)
let since = ago($($LookbackDays)d);
let pilot = '$PilotUserUpn';
CloudAppEvents
| where Timestamp > since
| where AccountDisplayName has pilot or RawEventData has pilot or AccountId has pilot
| project Timestamp, Application, ActionType, AccountDisplayName, IPAddress, DeviceType, ReportId
| order by Timestamp desc
| take 50
"@

function Invoke-Hunt($kql, $label) {
    Write-Host "`n-- $label --" -ForegroundColor Cyan
    try {
        $resp = Invoke-MgGraphRequest -Method POST -Uri 'https://graph.microsoft.com/v1.0/security/runHuntingQuery' -Body (@{ Query = $kql } | ConvertTo-Json) -ContentType 'application/json'
        if ($resp.results) { $resp.results | ForEach-Object { Write-Host ("   {0}" -f ($_ | ConvertTo-Json -Compress)) } }
        else { Write-Host "   (no rows — allow connector/discovery warm-up, then re-run)" -ForegroundColor Yellow }
    } catch { Write-Host ("   Hunt failed: {0}" -f $_.Exception.Message) -ForegroundColor Yellow }
}

Invoke-Hunt $coverageKql 'CloudAppEvents coverage (last 24h)'
Invoke-Hunt $pilotKql   'Pilot-user activity (monitor policy signal)'
Write-Host "`nHunt complete (read-only). Empty coverage => fix connectors/discovery first (Testing Guide Tests 1-2)." -ForegroundColor Green
