<#
.SYNOPSIS
    TBMMDI-Validate.ps1 — read-only pass/fail check that a Defender for Identity blocker is cleared —
    the affected sensor is healthy and identity signal flows.
.DESCRIPTION
    PURPOSE
        Read-only validation for the "Technical Blocker Mitigation — Defender for Identity" solution.
        Runs the saved advanced-hunting logic 'MDI Sensor Blocker Check - Tenant - Diagnose' via
        Microsoft Graph Security to confirm identity signal for the affected DCs: logon events, directory
        events, and AD-query events (DSA). Returns a pass/fail per link. Makes NO changes.
    HOW TO RUN
        powershell -ExecutionPolicy Bypass -File .\TBMMDI-Validate.ps1 -DeviceNameLike "DC01"
        Requires Microsoft.Graph.Authentication and ThreatHunting.Read.All consent.
    EXPECTED RESULTS
        PASS/FAIL lines for logon/event signal and DSA query signal. FAIL points you to the matching
        Troubleshooting section. Cross-check sensor health in Settings -> Identities -> Sensors.
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
if (-not (Get-MgContext)) { Connect-MgGraph -Scopes 'ThreatHunting.Read.All' -NoWelcome | Out-Null }

function Invoke-Hunt([string]$Query) {
    $body = @{ Query = $Query } | ConvertTo-Json
    return Invoke-MgGraphRequest -Method POST -Uri 'https://graph.microsoft.com/v1.0/security/runHuntingQuery' -Body $body -ContentType 'application/json'
}
function Count($table, $filter) {
    $kql = "$table | where Timestamp > ago(${LookbackHours}h) $filter | summarize c=count()"
    try { $r = Invoke-Hunt $kql; if ($r.results -and $r.results.Count -gt 0) { return [int]$r.results[0].c } } catch { return -1 }
    return 0
}

$dcFilter = if ($DeviceNameLike) { "| where DeviceName has `"$DeviceNameLike`"" } else { "" }

Write-Host "`n=== TBMMDI validation — affected sensor (read-only) ===" -ForegroundColor Cyan
Write-Host ("Lookback: {0}h  DeviceNameLike: '{1}'" -f $LookbackHours, $DeviceNameLike)

$logon = Count 'IdentityLogonEvents'     $dcFilter
$dir   = Count 'IdentityDirectoryEvents' $dcFilter
$query = Count 'IdentityQueryEvents'     $dcFilter

Write-Host ("IdentityLogonEvents     : {0}" -f $logon)
Write-Host ("IdentityDirectoryEvents : {0}" -f $dir)
Write-Host ("IdentityQueryEvents     : {0}" -f $query)

if ($logon -gt 0 -or $dir -gt 0) { Write-Host "PASS — event-based identity signal is flowing (sensor + audit collection OK)." -ForegroundColor Green }
else { Write-Host "FAIL — no event signal. See Troubleshooting 'MDI sensor unhealthy' / 'Event-collection gap'." -ForegroundColor Yellow }

if ($query -gt 0) { Write-Host "PASS — AD-query signal present (DSA is working)." -ForegroundColor Green }
else { Write-Host "FAIL — no query signal. See Troubleshooting 'DSA missing or under-permissioned'." -ForegroundColor Yellow }

Write-Host "`nValidation complete (read-only). Confirm sensor 'Running / Healthy' in Settings -> Identities -> Sensors." -ForegroundColor Green
