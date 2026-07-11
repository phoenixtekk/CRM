<#
.SYNOPSIS
    TBMMDE-Report.ps1 — read-only before/after report proving a Defender for Endpoint blocker cleared.
.DESCRIPTION
    PURPOSE
        Read-only reporting for the "Technical Blocker Mitigation — Defender for Endpoint" solution.
        Compares the discovery baseline (MDE-blocker-discovery.json from TBMMDE-Discovery.ps1) with a
        fresh live read of the same signal-chain links, and prints a before/after summary — the
        evidence the blocker moved from broken to cleared. Makes NO changes.
    HOW TO RUN
        powershell -ExecutionPolicy Bypass -File .\TBMMDE-Report.ps1 -Baseline .\MDE-blocker-discovery.json
        Requires Microsoft.Graph.Authentication and ThreatHunting.Read.All consent.
    EXPECTED RESULTS
        A table of each link's baseline vs current state and an overall CLEARED / STILL-BLOCKED
        verdict, written to MDE-blocker-report.json.
.NOTES
    White-label. Read-only. Reads state only; changes nothing.
#>
[CmdletBinding()]
param(
    [string]$Baseline = ".\MDE-blocker-discovery.json",
    [string]$OutputPath = ".\MDE-blocker-report.json",
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

Write-Host "`n=== TBMMDE — before/after blocker report (read-only) ===" -ForegroundColor Cyan
$base = $null
if (Test-Path $Baseline) { $base = Get-Content $Baseline -Raw | ConvertFrom-Json; Write-Host ("Baseline: {0} ({1})" -f $Baseline, $base.Timestamp) }
else { Write-Host "No baseline found — run TBMMDE-Discovery.ps1 first for a true before/after." -ForegroundColor Yellow }

# Current health + telemetry
$kql = @"
DeviceInfo
| where Timestamp > ago(${LookbackHours}h)
| summarize arg_max(Timestamp, OnboardingStatus, SensorHealthState) by DeviceName
| summarize Total=count(), Onboarded=countif(OnboardingStatus=="Onboarded"), Active=countif(SensorHealthState=="Active")
"@
$cur = @{ DevicesSeen=0; Onboarded=0; Active=0 }
try {
    $r = Invoke-Hunt $kql
    if ($r.results -and $r.results.Count -gt 0) { $cur.DevicesSeen=[int]$r.results[0].Total; $cur.Onboarded=[int]$r.results[0].Onboarded; $cur.Active=[int]$r.results[0].Active }
} catch { Write-Host ("Health query failed: {0}" -f $_.Exception.Message) -ForegroundColor Yellow }

Write-Host "`n-- Signal-chain status --" -ForegroundColor Cyan
Write-Host ("   Plan (baseline)          : {0}" -f (($base.MdeServicePlans) -join ', '))
Write-Host ("   Connector (baseline)     : {0}" -f (($base.IntuneMdeConnectors | ForEach-Object { $_.partnerState }) -join ', '))
Write-Host ("   Devices onboarded (now)  : {0} / {1}" -f $cur.Onboarded, $cur.DevicesSeen)
Write-Host ("   Sensors active (now)     : {0} / {1}" -f $cur.Active, $cur.DevicesSeen)

$cleared = ($cur.DevicesSeen -gt 0 -and $cur.Onboarded -eq $cur.DevicesSeen -and $cur.Active -eq $cur.DevicesSeen)
$verdict = if ($cleared) { 'CLEARED' } else { 'STILL-BLOCKED' }
Write-Host ("`nVerdict: {0}" -f $verdict) -ForegroundColor ($(if ($cleared) { 'Green' } else { 'Yellow' }))
if (-not $cleared) { Write-Host "Return to the Troubleshooting Guide for the failing link, or assemble a support bundle." -ForegroundColor Yellow }

[ordered]@{ Timestamp=(Get-Date).ToString('s'); BaselineTimestamp=$base.Timestamp; Current=$cur; Verdict=$verdict } |
    ConvertTo-Json -Depth 6 | Set-Content -Path $OutputPath -Encoding UTF8
Write-Host ("Report: {0}" -f $OutputPath) -ForegroundColor Green
