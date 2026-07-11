<#
.SYNOPSIS
    SOPMDE-Hunt.ps1 — read-only KQL advanced-hunting for tuning: ASR audit/block evidence,
    noisy benign detections, and device coverage gaps.
.DESCRIPTION
    PURPOSE
        Read-only hunting for the "Solution Optimization — Microsoft Defender for Endpoint"
        solution. Runs one of three saved KQL queries via the Microsoft 365 advanced-hunting API
        (Microsoft Graph Security). It provides the evidence behind every tuning decision and
        makes no changes:
          -Mode ASRAudit   'ASR Audit vs Block Evidence - Tenant - Assess'  (which rules would/do block)
          -Mode Noise      'Repeating Benign Detections - Tenant - Assess'  (noisiest alert titles)
          -Mode Coverage   'Endpoint Coverage Gaps - Tenant - Assess'       (devices not reporting recently)
    HOW TO RUN
        powershell -ExecutionPolicy Bypass -File .\SOPMDE-Hunt.ps1 -Mode ASRAudit
        powershell -ExecutionPolicy Bypass -File .\SOPMDE-Hunt.ps1 -Mode ASRAudit -BlockedOnly
        powershell -ExecutionPolicy Bypass -File .\SOPMDE-Hunt.ps1 -Mode Noise -LookbackDays 7
        powershell -ExecutionPolicy Bypass -File .\SOPMDE-Hunt.ps1 -Mode Coverage
        Requires Microsoft.Graph.Authentication and ThreatHunting.Read.All consent.
    EXPECTED RESULTS
        ASRAudit: per-rule audited (would-block) vs blocked counts and top devices.
        Noise:    the highest-volume repeating detections — candidates to tune/suppress.
        Coverage: devices with no recent DeviceInfo heartbeat — onboarding/sensor-health gaps.
.NOTES
    White-label. Read-only. The embedded KQL only reads telemetry.
    Queries are also saved in the portal under the names above.
#>
[CmdletBinding()]
param(
    [ValidateSet('ASRAudit','Noise','Coverage')] [string]$Mode = 'ASRAudit',
    [int]$LookbackDays = 7,
    [switch]$BlockedOnly
)

if (-not (Get-Module -ListAvailable -Name Microsoft.Graph.Authentication)) {
    Install-Module Microsoft.Graph.Authentication -Scope CurrentUser -Force -AllowClobber
}
Import-Module Microsoft.Graph.Authentication -ErrorAction Stop
if (-not (Get-MgContext)) { Connect-MgGraph -Scopes 'ThreatHunting.Read.All' -NoWelcome | Out-Null }

# ASR audit action types: 'Asr* Audited' = would-block; 'Asr* Blocked' = enforced.
$asrFilter = if ($BlockedOnly) { "ActionType has 'Blocked'" } else { "ActionType has 'Asr'" }

switch ($Mode) {
    'ASRAudit' {
        $kql = @"
let Window = ${LookbackDays}d;
DeviceEvents
| where Timestamp > ago(Window)
| where ActionType startswith 'Asr'
| where $asrFilter
| extend Mode = iff(ActionType endswith 'Blocked','Block','Audit')
| summarize Events = count(), Devices = dcount(DeviceName) by ActionType, Mode
| sort by Events desc
"@
    }
    'Noise' {
        $kql = @"
let Window = ${LookbackDays}d;
AlertInfo
| where Timestamp > ago(Window)
| summarize Alerts = count(), Days = dcount(bin(Timestamp,1d)) by Title, Severity
| where Alerts > 5
| sort by Alerts desc
| take 25
"@
    }
    'Coverage' {
        $kql = @"
let Window = ${LookbackDays}d;
DeviceInfo
| summarize LastSeen = max(Timestamp) by DeviceName, OnboardingStatus
| extend StaleHours = datetime_diff('hour', now(), LastSeen)
| where OnboardingStatus != 'Onboarded' or LastSeen < ago(Window)
| project DeviceName, OnboardingStatus, LastSeen, StaleHours
| sort by StaleHours desc
| take 100
"@
    }
}

Write-Host ("`n=== SOPMDE hunt — mode: {0} (read-only) ===" -f $Mode) -ForegroundColor Cyan
try {
    $body = @{ Query = $kql } | ConvertTo-Json
    $resp = Invoke-MgGraphRequest -Method POST -Uri 'https://graph.microsoft.com/v1.0/security/runHuntingQuery' -Body $body -ContentType 'application/json'
    if ($resp.results -and $resp.results.Count -gt 0) {
        $resp.results | ForEach-Object { $_ | Format-List | Out-String | Write-Host }
        Write-Host ("Rows returned: {0}" -f $resp.results.Count) -ForegroundColor Green
    } else {
        Write-Host "No rows returned. For ASRAudit this may mean rules haven't run in audit yet (see Requirements 2.3)." -ForegroundColor Yellow
    }
} catch {
    Write-Host ("Could not run the hunting query: {0}" -f $_.Exception.Message) -ForegroundColor Yellow
    Write-Host "Confirm ThreatHunting.Read.All consent and that the deployment is reporting telemetry." -ForegroundColor Yellow
}
