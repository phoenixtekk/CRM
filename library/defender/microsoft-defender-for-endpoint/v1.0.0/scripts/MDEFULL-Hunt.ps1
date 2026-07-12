<#
.SYNOPSIS
    MDEFULL-Hunt.ps1 — read-only KQL advanced-hunting for the Defender for Endpoint lifecycle:
    onboarding/health coverage, ASR audit vs block evidence, noisy detections, and telemetry/TVM presence.
.DESCRIPTION
    PURPOSE
        Read-only hunting for the comprehensive "Microsoft Defender for Endpoint" solution. Runs one of
        four saved KQL queries via the Microsoft 365 advanced-hunting API (Microsoft Graph Security). It
        provides the evidence behind onboarding validation (Deploy) and every tuning decision (Optimize),
        and makes no changes:
          -Mode Coverage   'MDE Onboarding Coverage - Tenant - Validate'  (onboarding + health by OS; coverage gaps)
          -Mode ASRAudit   'ASR Audit vs Block Evidence - Tenant - Assess' (which rules would/do block)
          -Mode Noise      'Repeating Benign Detections - Tenant - Assess' (noisiest alert titles)
          -Mode Telemetry  'Endpoint Telemetry + TVM Presence - Tenant - Validate' (tables streaming?)
    HOW TO RUN
        powershell -ExecutionPolicy Bypass -File .\MDEFULL-Hunt.ps1 -Mode Coverage
        powershell -ExecutionPolicy Bypass -File .\MDEFULL-Hunt.ps1 -Mode ASRAudit
        powershell -ExecutionPolicy Bypass -File .\MDEFULL-Hunt.ps1 -Mode ASRAudit -BlockedOnly
        powershell -ExecutionPolicy Bypass -File .\MDEFULL-Hunt.ps1 -Mode Noise -LookbackDays 7
        Requires Microsoft.Graph.Authentication and ThreatHunting.Read.All consent. Government cloud: -Environment.
    EXPECTED RESULTS
        Coverage:  onboarding/health by OS + stale/not-onboarded devices — onboarding/sensor-health gaps.
        ASRAudit:  per-rule audited (would-block) vs blocked counts.
        Noise:     the highest-volume repeating detections — candidates to tune/suppress.
        Telemetry: recent DeviceEvents/DeviceNetworkEvents volume + TVM row presence.
.NOTES
    White-label. Read-only. The embedded KQL only reads telemetry. Queries are also saved in the portal
    under the names above. Defender XDR tables use `Timestamp`; ASR ActionType names evolve — verify.
#>
[CmdletBinding()]
param(
    [ValidateSet('Coverage','ASRAudit','Noise','Telemetry')] [string]$Mode = 'Coverage',
    [int]$LookbackDays = 7,
    [switch]$BlockedOnly,
    [ValidateSet('Global','USGov','USGovDoD')] [string]$Environment = 'Global'
)

if (-not (Get-Module -ListAvailable -Name Microsoft.Graph.Authentication)) { Install-Module Microsoft.Graph -Scope CurrentUser -Force -AllowClobber }
Import-Module Microsoft.Graph.Authentication -ErrorAction Stop
if (-not (Get-MgContext)) { Connect-MgGraph -Scopes 'ThreatHunting.Read.All' -Environment $Environment -NoWelcome | Out-Null }

$asrFilter = if ($BlockedOnly) { "| where ActionType endswith 'Blocked'" } else { '' }

switch ($Mode) {
    'Coverage' {
        $kql = @"
// MDE Onboarding Coverage - Tenant - Validate (onboarding + health by OS, plus gaps)
DeviceInfo
| summarize arg_max(Timestamp, OnboardingStatus, HealthStatus, OSPlatform) by DeviceName
| extend StaleHours = datetime_diff('hour', now(), Timestamp)
| summarize Devices=count(), Stale=countif(StaleHours > ${LookbackDays}*24 or OnboardingStatus != 'Onboarded')
        by OSPlatform, OnboardingStatus, HealthStatus
| order by OSPlatform asc
"@
    }
    'ASRAudit' {
        $kql = @"
// ASR Audit vs Block Evidence - Tenant - Assess (audit = would-block; blocked = enforced)
DeviceEvents
| where Timestamp > ago(${LookbackDays}d)
| where ActionType startswith 'Asr'
$asrFilter
| extend Mode = iff(ActionType endswith 'Blocked','Block','Audit')
| summarize Events = count(), Devices = dcount(DeviceName), Sample = make_set(FolderPath, 5) by ActionType, Mode
| sort by Events desc
"@
    }
    'Noise' {
        $kql = @"
// Repeating Benign Detections - Tenant - Assess (tune/suppress candidates)
AlertInfo
| where Timestamp > ago(${LookbackDays}d)
| summarize Alerts = count(), Days = dcount(bin(Timestamp,1d)) by Title, Severity
| where Alerts > 5
| sort by Alerts desc
| take 25
"@
    }
    'Telemetry' {
        $kql = @"
// Endpoint Telemetry + TVM Presence - Tenant - Validate
let since = ago(${LookbackDays}d);
union
 (DeviceEvents | where Timestamp > since | summarize Rows=count() | extend Table='DeviceEvents'),
 (DeviceNetworkEvents | where Timestamp > since | summarize Rows=count() | extend Table='DeviceNetworkEvents'),
 (DeviceTvmSoftwareVulnerabilities | summarize Rows=count() | extend Table='DeviceTvmSoftwareVulnerabilities')
| project Table, Rows
"@
    }
}

Write-Host ("`n=== MDEFULL hunt — mode: {0} (read-only) ===" -f $Mode) -ForegroundColor Cyan
try {
    $resp = Invoke-MgGraphRequest -Method POST -Uri 'https://graph.microsoft.com/v1.0/security/runHuntingQuery' -Body (@{ Query = $kql } | ConvertTo-Json) -ContentType 'application/json'
    if ($resp.results -and $resp.results.Count -gt 0) {
        $resp.results | ForEach-Object { Write-Host ("   {0}" -f ($_ | ConvertTo-Json -Compress)) }
        Write-Host ("Rows returned: {0}" -f $resp.results.Count) -ForegroundColor Green
    } else {
        Write-Host "No rows returned. For ASRAudit this may mean rules haven't run in audit yet (Requirement 2.8); for Coverage/Telemetry allow onboarding warm-up." -ForegroundColor Yellow
    }
} catch {
    Write-Host ("Could not run the hunting query: {0}" -f $_.Exception.Message) -ForegroundColor Yellow
    Write-Host "Confirm ThreatHunting.Read.All consent and that the deployment is reporting telemetry. Verify table/ASR-ActionType names for your tenant." -ForegroundColor Yellow
}
