<#
.SYNOPSIS
    TBMMDE-Validate.ps1 — read-only pass/fail check that a Defender for Endpoint blocker is cleared
    on the affected device subset.
.DESCRIPTION
    PURPOSE
        Read-only validation for the "Technical Blocker Mitigation — Defender for Endpoint" solution.
        Runs the saved advanced-hunting logic 'MDE Onboarding Blocker Check - Tenant - Diagnose' via
        Microsoft Graph Security to confirm, for the affected devices, the state of each signal-chain
        link: onboarded/sensor-health status and recent telemetry rows. Returns a pass/fail per link.
        Makes NO changes.
    HOW TO RUN
        powershell -ExecutionPolicy Bypass -File .\TBMMDE-Validate.ps1
        Optionally scope by device name pattern:
        .\TBMMDE-Validate.ps1 -DeviceNameLike "PILOT-" -LookbackHours 24
        Requires Microsoft.Graph.Authentication and ThreatHunting.Read.All consent.
    EXPECTED RESULTS
        PASS/FAIL lines for onboarded/health and telemetry. FAIL points you to the matching
        Troubleshooting section for that blocker class.
.NOTES
    White-label. Read-only. Advanced-hunting queries only read telemetry; they change nothing.
#>
[CmdletBinding()]
param(
    [string]$DeviceNameLike = "",
    [int]$LookbackHours = 24
)

foreach ($m in 'Microsoft.Graph.Authentication') {
    if (-not (Get-Module -ListAvailable -Name $m)) { Install-Module Microsoft.Graph -Scope CurrentUser -Force -AllowClobber; break }
}
Import-Module Microsoft.Graph.Authentication -ErrorAction Stop
if (-not (Get-MgContext)) { Connect-MgGraph -Scopes 'ThreatHunting.Read.All','SecurityEvents.Read.All' -NoWelcome | Out-Null }

function Invoke-Hunt([string]$Query) {
    $body = @{ Query = $Query } | ConvertTo-Json
    return Invoke-MgGraphRequest -Method POST -Uri 'https://graph.microsoft.com/v1.0/security/runHuntingQuery' -Body $body -ContentType 'application/json'
}

$filter = if ($DeviceNameLike) { "| where DeviceName has `"$DeviceNameLike`"" } else { "" }

Write-Host "`n=== TBMMDE validation — affected subset (read-only) ===" -ForegroundColor Cyan
Write-Host ("Lookback: {0}h  DeviceNameLike: '{1}'" -f $LookbackHours, $DeviceNameLike)

# --- Onboarded + sensor health (DeviceInfo carries OnboardingStatus / SensorHealthState) ---
$kqlHealth = @"
DeviceInfo
| where Timestamp > ago(${LookbackHours}h)
$filter
| summarize arg_max(Timestamp, OnboardingStatus, SensorHealthState) by DeviceName
| summarize Total = count(),
            Onboarded = countif(OnboardingStatus == "Onboarded"),
            Active = countif(SensorHealthState == "Active"),
            Impaired = countif(SensorHealthState in ("Inactive","ImpairedCommunication","NoSensorData"))
"@

try {
    $r = Invoke-Hunt $kqlHealth
    if ($r.results -and $r.results.Count -gt 0) {
        $row = $r.results[0]
        Write-Host ("Devices seen: {0}  Onboarded: {1}  Active: {2}  Impaired/Inactive: {3}" -f $row.Total,$row.Onboarded,$row.Active,$row.Impaired)
        if ([int]$row.Onboarded -gt 0 -and [int]$row.Onboarded -eq [int]$row.Total) { Write-Host "PASS — all seen devices are Onboarded." -ForegroundColor Green }
        else { Write-Host "FAIL — some devices not Onboarded. See Troubleshooting 'Device not onboarding'." -ForegroundColor Yellow }
        if ([int]$row.Impaired -eq 0 -and [int]$row.Active -gt 0) { Write-Host "PASS — sensor health Active." -ForegroundColor Green }
        else { Write-Host "FAIL — impaired/inactive sensors. See Troubleshooting 'Sensor Inactive / Impaired communication'." -ForegroundColor Yellow }
    } else { Write-Host "No DeviceInfo rows in window — devices may not be reporting yet (allow warm-up)." -ForegroundColor Yellow }
} catch { Write-Host ("Could not run health query: {0}" -f $_.Exception.Message) -ForegroundColor Yellow }

# --- Telemetry flowing (DeviceEvents) ---
$kqlTelem = @"
DeviceEvents
| where Timestamp > ago(${LookbackHours}h)
$filter
| summarize Rows = count(), Devices = dcount(DeviceName)
"@

try {
    $r2 = Invoke-Hunt $kqlTelem
    $rows = 0; $dev = 0
    if ($r2.results -and $r2.results.Count -gt 0) { $rows = [int]$r2.results[0].Rows; $dev = [int]$r2.results[0].Devices }
    Write-Host ("Telemetry: {0} DeviceEvents rows across {1} device(s) in {2}h" -f $rows,$dev,$LookbackHours)
    if ($rows -gt 0) { Write-Host "PASS — telemetry is flowing." -ForegroundColor Green }
    else { Write-Host "FAIL — no telemetry. Allow warm-up; see Troubleshooting 'No telemetry after onboarding'." -ForegroundColor Yellow }
} catch { Write-Host ("Could not run telemetry query: {0}" -f $_.Exception.Message) -ForegroundColor Yellow }

Write-Host "`nValidation complete (read-only)." -ForegroundColor Green
