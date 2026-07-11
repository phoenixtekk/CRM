<#
.SYNOPSIS
    TBMMCA-Report.ps1 — read-only before/after report proving a Defender for Cloud Apps blocker cleared.
.DESCRIPTION
    PURPOSE
        Read-only reporting for the "Technical Blocker Mitigation — Defender for Cloud Apps" solution.
        Compares the discovery baseline (MDCA-blocker-discovery.json) with a fresh live read of the same
        signal-chain links (activity signal, App Control policy state) and prints a before/after summary
        — the evidence the blocker moved from broken to cleared. Makes NO changes.
    HOW TO RUN
        powershell -ExecutionPolicy Bypass -File .\TBMMCA-Report.ps1 -Baseline .\MDCA-blocker-discovery.json
        Requires Microsoft.Graph.Authentication with ThreatHunting.Read.All and Policy.Read.All consent.
    EXPECTED RESULTS
        A table of each link's baseline vs current state and an overall CLEARED / STILL-BLOCKED verdict,
        written to MDCA-blocker-report.json.
.NOTES
    White-label. Read-only. Reads state/telemetry only; changes nothing.
#>
[CmdletBinding()]
param(
    [string]$Baseline = ".\MDCA-blocker-discovery.json",
    [string]$OutputPath = ".\MDCA-blocker-report.json",
    [int]$LookbackHours = 24
)

foreach ($m in 'Microsoft.Graph.Authentication') {
    if (-not (Get-Module -ListAvailable -Name $m)) { Install-Module Microsoft.Graph -Scope CurrentUser -Force -AllowClobber; break }
}
Import-Module Microsoft.Graph.Authentication -ErrorAction Stop
if (-not (Get-MgContext)) { Connect-MgGraph -Scopes 'ThreatHunting.Read.All','Policy.Read.All' -NoWelcome | Out-Null }

function Invoke-Hunt([string]$Query) {
    $body = @{ Query = $Query } | ConvertTo-Json
    return Invoke-MgGraphRequest -Method POST -Uri 'https://graph.microsoft.com/v1.0/security/runHuntingQuery' -Body $body -ContentType 'application/json'
}

Write-Host "`n=== TBMMCA — before/after blocker report (read-only) ===" -ForegroundColor Cyan
$base = $null
if (Test-Path $Baseline) { $base = Get-Content $Baseline -Raw | ConvertFrom-Json; Write-Host ("Baseline: {0} ({1})" -f $Baseline, $base.Timestamp) }
else { Write-Host "No baseline found — run TBMMCA-Discovery.ps1 first for a true before/after." -ForegroundColor Yellow }

# Current activity signal
$curCae = -1
try { $r = Invoke-Hunt "CloudAppEvents | where Timestamp > ago(${LookbackHours}h) | summarize c=count()"; if ($r.results -and $r.results.Count -gt 0) { $curCae = [int]$r.results[0].c } } catch { }

# Current App Control policy count (enabled)
$curEnabled = 0
try {
    $pol = Invoke-MgGraphRequest -Method GET -Uri 'https://graph.microsoft.com/v1.0/identity/conditionalAccess/policies'
    foreach ($p in $pol.value) { if ($p.sessionControls -and $p.sessionControls.cloudAppSecurity -and $p.sessionControls.cloudAppSecurity.isEnabled -and $p.state -eq 'enabled') { $curEnabled++ } }
} catch { }

$baseEnabled = @($base.AppControlPolicies | Where-Object { $_.State -eq 'enabled' }).Count

Write-Host "`n-- Signal-chain status --" -ForegroundColor Cyan
Write-Host ("   Plan (baseline)                       : {0}" -f (($base.McaServicePlans) -join ', '))
Write-Host ("   CloudAppEvents rows base -> now        : {0} -> {1}" -f $base.CloudAppEventsRows, $curCae)
Write-Host ("   Enabled App Control policies base->now : {0} -> {1}" -f $baseEnabled, $curEnabled)

$cleared = ($curCae -gt 0)
$verdict = if ($cleared) { 'CLEARED (activity flowing — confirm connector/discovery/session in portal)' } else { 'STILL-BLOCKED' }
Write-Host ("`nVerdict: {0}" -f $verdict) -ForegroundColor ($(if ($cleared) { 'Green' } else { 'Yellow' }))
if (-not $cleared) { Write-Host "Return to the Troubleshooting Guide for the failing link, or assemble a support bundle." -ForegroundColor Yellow }

[ordered]@{ Timestamp=(Get-Date).ToString('s'); BaselineTimestamp=$base.Timestamp;
    Current=@{ CloudAppEventsRows=$curCae; EnabledAppControlPolicies=$curEnabled }; Verdict=$verdict } |
    ConvertTo-Json -Depth 6 | Set-Content -Path $OutputPath -Encoding UTF8
Write-Host ("Report: {0}" -f $OutputPath) -ForegroundColor Green
