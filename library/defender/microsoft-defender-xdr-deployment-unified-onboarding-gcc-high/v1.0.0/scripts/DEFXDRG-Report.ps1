<#
.SYNOPSIS
    DEFXDRG-Report.ps1 — coverage + Secure Score report across the Defender XDR pillars, with drift
    versus a saved baseline. Read-only.
.DESCRIPTION
    PURPOSE
        Read-only reporting for the "Microsoft Defender XDR Deployment & Unified Onboarding"
        solution. Summarizes per-pillar signal (row counts from the advanced-hunting tables),
        the Microsoft Secure Score, and the count of active security recommendations. If
        -BaselinePath points to a JSON file from a previous run, reports the DRIFT (score change,
        signal change). With -SaveBaseline, writes this run for next-cycle comparison.
    HOW TO RUN
        powershell -ExecutionPolicy Bypass -File .\DEFXDRG-Report.ps1
        powershell -ExecutionPolicy Bypass -File .\DEFXDRG-Report.ps1 -BaselinePath .\defxdr-baseline.json -SaveBaseline
        # DoD (IL5): -GraphEnvironment USGovDoD
        Requires Microsoft.Graph.Authentication with ThreatHunting.Read.All and SecurityEvents.Read.All.
        Connects to the US GOVERNMENT cloud (GCC High) by DEFAULT (-Environment USGov, graph.microsoft.us);
        for DoD (IL5) pass -GraphEnvironment USGovDoD (dod-graph.microsoft.us). Verify endpoints against
        current Microsoft Government documentation.
    EXPECTED RESULTS
        A posture report: per-pillar signal presence, Secure Score (current/max/percent), active
        recommendation count, and — with a baseline — a drift line.
.NOTES
    White-label. Read-only. Reports the AIR automation posture reminder; changes nothing.
#>
[CmdletBinding()]
param(
    [string]$BaselinePath,
    [switch]$SaveBaseline,
    [int]$LookbackHours = 24,
    # Government (GCC High) is the default for this edition. DoD (IL5): USGovDoD (dod-graph.microsoft.us).
    [ValidateSet('USGov','USGovDoD','Global')] [string]$GraphEnvironment = 'USGov'
)

$GraphBase = switch ($GraphEnvironment) {
    'USGovDoD' { 'https://dod-graph.microsoft.us' }
    'Global'   { 'https://graph.microsoft.com' }
    default    { 'https://graph.microsoft.us' }
}

Import-Module Microsoft.Graph.Authentication -ErrorAction Stop
if (-not (Get-MgContext)) { Connect-MgGraph -Environment $GraphEnvironment -Scopes 'ThreatHunting.Read.All','SecurityEvents.Read.All' -NoWelcome | Out-Null }

function Invoke-Hunt([string]$Query) {
    $body = @{ Query = $Query } | ConvertTo-Json
    return Invoke-MgGraphRequest -Method POST -Uri "$GraphBase/v1.0/security/runHuntingQuery" -Body $body -ContentType 'application/json'
}

Write-Host "`n=== Microsoft Defender XDR — coverage & Secure Score report (read-only) ===" -ForegroundColor Cyan

# --- Per-pillar signal ---
Write-Host "`n-- Per-pillar signal (last ${LookbackHours}h) --" -ForegroundColor Cyan
$pillars = [ordered]@{ Endpoint='DeviceInfo'; Identity='IdentityInfo'; Office365='EmailEvents'; CloudApps='CloudAppEvents' }
$signal  = [ordered]@{}
foreach ($p in $pillars.Keys) {
    $t = $pillars[$p]
    $kql = "$t | where Timestamp > ago(${LookbackHours}h) | summarize Rows = count()"
    try {
        $resp = Invoke-Hunt $kql
        $rows = if ($resp.results -and $resp.results.Count -gt 0) { [int]$resp.results[0].Rows } else { 0 }
    } catch { $rows = -1 }
    $signal[$p] = $rows
    $color = if ($rows -gt 0) { 'Green' } elseif ($rows -eq 0) { 'Yellow' } else { 'DarkGray' }
    Write-Host ("   {0,-10} {1,-16} rows: {2}" -f $p, $t, $rows) -ForegroundColor $color
}

# --- Secure Score ---
Write-Host "`n-- Microsoft Secure Score --" -ForegroundColor Cyan
$scorePct = $null
try {
    $ss = Invoke-MgGraphRequest -Method GET -Uri "$GraphBase/v1.0/security/secureScores?`$top=1"
    $cur = $ss.value | Select-Object -First 1
    if ($cur) {
        $scorePct = [math]::Round(($cur.currentScore / [double]$cur.maxScore) * 100)
        Write-Host ("   Secure Score: {0}% ({1}/{2}) as of {3}" -f $scorePct, $cur.currentScore, $cur.maxScore, $cur.createdDateTime)
    } else { Write-Host "   Secure Score not available yet (allow time after onboarding)." -ForegroundColor Yellow }
} catch { Write-Host ("   Could not read Secure Score: {0}" -f $_.Exception.Message) -ForegroundColor Yellow }

# --- Active recommendations (control profiles) ---
$recCount = $null
try {
    $ctrls = Invoke-MgGraphRequest -Method GET -Uri "$GraphBase/v1.0/security/secureScoreControlProfiles?`$top=200"
    $recCount = ($ctrls.value | Measure-Object).Count
    Write-Host ("   Secure Score control profiles available: {0}" -f $recCount)
} catch { Write-Host ("   Could not read control profiles: {0}" -f $_.Exception.Message) -ForegroundColor Yellow }

# --- AIR posture reminder ---
Write-Host "`n-- Automated response (AIR) --" -ForegroundColor Cyan
Write-Host "   Reminder: keep pilot device-group automation at 'Semi — require approval' until trusted." -ForegroundColor Gray
Write-Host "   Confirm in security.microsoft.us (GCC High) -> Settings -> Endpoints -> Advanced features / device groups." -ForegroundColor Gray

# --- Drift ---
if ($BaselinePath -and (Test-Path $BaselinePath)) {
    try {
        $base = Get-Content $BaselinePath -Raw | ConvertFrom-Json
        Write-Host "`n-- Drift vs baseline --" -ForegroundColor Cyan
        $delta = if ($null -ne $scorePct -and $null -ne $base.SecureScorePct) { $scorePct - $base.SecureScorePct } else { 'n/a' }
        Write-Host ("   Secure Score delta: {0}" -f $delta)
        foreach ($p in $pillars.Keys) {
            $was = $base.Signal.$p
            Write-Host ("   {0,-10} signal: baseline {1} -> now {2}" -f $p, $was, $signal[$p])
        }
    } catch { Write-Host ("   Could not read baseline: {0}" -f $_.Exception.Message) -ForegroundColor Yellow }
}

# --- Save baseline ---
if ($BaselinePath -and $SaveBaseline) {
    $snap = [pscustomobject]@{
        Timestamp      = (Get-Date).ToString('s')
        SecureScorePct = $scorePct
        RecommendationProfiles = $recCount
        Signal         = $signal
    }
    $snap | ConvertTo-Json -Depth 6 | Set-Content -Path $BaselinePath -Encoding UTF8
    Write-Host ("`nBaseline saved to {0}" -f $BaselinePath) -ForegroundColor Green
}

Write-Host "`nReport complete (read-only)." -ForegroundColor Green
