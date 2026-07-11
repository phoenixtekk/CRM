<#
.SYNOPSIS
    MDEONB-Hunt.ps1 — run the onboarding-coverage validation KQL to confirm devices are onboarded,
    healthy, and streaming EDR/TVM telemetry.
.DESCRIPTION
    PURPOSE
        Read-only advanced-hunting for the "Onboarding Accelerator — Microsoft Defender for
        Endpoint" solution. Executes the saved query 'MDE Onboarding Coverage - Tenant - Validate'
        via Microsoft Graph Security advanced hunting to confirm DeviceInfo shows the pilot devices
        onboarded/healthy, that DeviceEvents are flowing, and that TVM has software-vulnerability
        rows (Testing Guide Test 6).
    HOW TO RUN
        powershell -ExecutionPolicy Bypass -File .\MDEONB-Hunt.ps1
        Uses Microsoft.Graph.Authentication and the ThreatHunting.Read.All scope. Read-only.
    EXPECTED RESULTS
        Onboarding coverage counts by OS/health, recent DeviceEvents volume, and a TVM row count —
        proof the endpoints are onboarded and telemetry is streaming.
.NOTES
    White-label. Read-only (advanced hunting). Embedded KQL below is the delivered query.
#>
[CmdletBinding()]
param([int]$LookbackDays = 1)

Import-Module Microsoft.Graph.Authentication -ErrorAction Stop
if (-not (Get-MgContext)) { Connect-MgGraph -Scopes 'ThreatHunting.Read.All' -NoWelcome | Out-Null }
Write-Host "`n=== MDE onboarding-coverage hunt (read-only) ===" -ForegroundColor Cyan

$coverageKql = @"
// MDE Onboarding Coverage - Tenant - Validate  (onboarding + health by OS)
DeviceInfo
| where Timestamp > ago($($LookbackDays)d)
| summarize arg_max(Timestamp, OnboardingStatus, HealthStatus, OSPlatform) by DeviceName
| summarize Devices=count() by OSPlatform, OnboardingStatus, HealthStatus
| order by OSPlatform asc
"@

$telemetryKql = @"
// MDE Onboarding Coverage - Tenant - Validate  (telemetry + TVM presence)
let since = ago($($LookbackDays)d);
union
 (DeviceEvents | where Timestamp > since | summarize Rows=count() | extend Table='DeviceEvents'),
 (DeviceNetworkEvents | where Timestamp > since | summarize Rows=count() | extend Table='DeviceNetworkEvents'),
 (DeviceTvmSoftwareVulnerabilities | summarize Rows=count() | extend Table='DeviceTvmSoftwareVulnerabilities')
| project Table, Rows
"@

function Invoke-Hunt($kql, $label) {
    Write-Host "`n-- $label --" -ForegroundColor Cyan
    try {
        $resp = Invoke-MgGraphRequest -Method POST -Uri 'https://graph.microsoft.com/v1.0/security/runHuntingQuery' -Body (@{ Query = $kql } | ConvertTo-Json) -ContentType 'application/json'
        if ($resp.results) { $resp.results | ForEach-Object { Write-Host ("   {0}" -f ($_ | ConvertTo-Json -Compress)) } }
        else { Write-Host "   (no rows — allow onboarding warm-up, then re-run)" -ForegroundColor Yellow }
    } catch { Write-Host ("   Hunt failed: {0}" -f $_.Exception.Message) -ForegroundColor Yellow }
}

Invoke-Hunt $coverageKql  'Onboarding + health by OS'
Invoke-Hunt $telemetryKql 'Telemetry + TVM presence'
Write-Host "`nHunt complete (read-only). 'Can be onboarded' / empty tables => fix onboarding first (Testing Guide Test 1)." -ForegroundColor Green
