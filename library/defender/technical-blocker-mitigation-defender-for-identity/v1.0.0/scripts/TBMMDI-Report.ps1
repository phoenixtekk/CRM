<#
.SYNOPSIS
    TBMMDI-Report.ps1 — read-only before/after report proving a Defender for Identity blocker cleared.
.DESCRIPTION
    PURPOSE
        Read-only reporting for the "Technical Blocker Mitigation — Defender for Identity" solution.
        Compares the discovery baseline (MDI-blocker-discovery.json) with a fresh live read of the same
        identity-signal links and prints a before/after summary — the evidence the sensor became healthy
        and signal is flowing. Makes NO changes.
    HOW TO RUN
        powershell -ExecutionPolicy Bypass -File .\TBMMDI-Report.ps1 -Baseline .\MDI-blocker-discovery.json
        Requires Microsoft.Graph.Authentication and ThreatHunting.Read.All consent.
    EXPECTED RESULTS
        A table of each link's baseline vs current row-count and an overall CLEARED / STILL-BLOCKED
        verdict, written to MDI-blocker-report.json.
.NOTES
    White-label. Read-only. Reads telemetry only; changes nothing.
#>
[CmdletBinding()]
param(
    [string]$Baseline = ".\MDI-blocker-discovery.json",
    [string]$OutputPath = ".\MDI-blocker-report.json",
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
function Count-Table([string]$table) {
    try { $r = Invoke-Hunt "$table | where Timestamp > ago(${LookbackHours}h) | summarize c=count()"; if ($r.results -and $r.results.Count -gt 0) { return [int]$r.results[0].c } } catch { }
    return -1
}

Write-Host "`n=== TBMMDI — before/after blocker report (read-only) ===" -ForegroundColor Cyan
$base = $null
if (Test-Path $Baseline) { $base = Get-Content $Baseline -Raw | ConvertFrom-Json; Write-Host ("Baseline: {0} ({1})" -f $Baseline, $base.Timestamp) }
else { Write-Host "No baseline found — run TBMMDI-Discovery.ps1 first for a true before/after." -ForegroundColor Yellow }

$curLogon = Count-Table 'IdentityLogonEvents'
$curDir   = Count-Table 'IdentityDirectoryEvents'
$curQuery = Count-Table 'IdentityQueryEvents'

Write-Host "`n-- Signal-chain status (rows in window) --" -ForegroundColor Cyan
Write-Host ("   IdentityLogonEvents     base -> now : {0} -> {1}" -f $base.IdentityLogonRows, $curLogon)
Write-Host ("   IdentityDirectoryEvents base -> now : {0} -> {1}" -f $base.IdentityDirectoryRows, $curDir)
Write-Host ("   IdentityQueryEvents(DSA) base -> now : {0} -> {1}" -f $base.IdentityQueryRows, $curQuery)

$cleared = (($curLogon -gt 0 -or $curDir -gt 0) -and $curQuery -gt 0)
$verdict = if ($cleared) { 'CLEARED (signal + DSA flowing — confirm sensor Healthy in portal)' } else { 'STILL-BLOCKED' }
Write-Host ("`nVerdict: {0}" -f $verdict) -ForegroundColor ($(if ($cleared) { 'Green' } else { 'Yellow' }))
if (-not $cleared) { Write-Host "Return to the Troubleshooting Guide for the failing link, or assemble a support bundle." -ForegroundColor Yellow }

[ordered]@{ Timestamp=(Get-Date).ToString('s'); BaselineTimestamp=$base.Timestamp;
    Current=@{ Logon=$curLogon; Directory=$curDir; Query=$curQuery }; Verdict=$verdict } |
    ConvertTo-Json -Depth 6 | Set-Content -Path $OutputPath -Encoding UTF8
Write-Host ("Report: {0}" -f $OutputPath) -ForegroundColor Green
