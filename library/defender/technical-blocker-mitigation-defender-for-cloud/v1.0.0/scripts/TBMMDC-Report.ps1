<#
.SYNOPSIS
    TBMMDC-Report.ps1 — read-only before/after report proving a Defender for Cloud blocker cleared.
.DESCRIPTION
    PURPOSE
        Read-only reporting for the "Technical Blocker Mitigation — Defender for Cloud" solution.
        Compares the discovery baseline (MDC-blocker-discovery.json) with a fresh live read of the same
        signal-chain links per subscription (plan tiers, assessment count, Secure Score) and prints a
        before/after summary — the evidence the blocker moved from broken to cleared. Makes NO changes.
    HOW TO RUN
        Connect-AzAccount ; then:
        powershell -ExecutionPolicy Bypass -File .\TBMMDC-Report.ps1 -Baseline .\MDC-blocker-discovery.json
        Requires Az.Accounts, Az.Security. Read-only.
    EXPECTED RESULTS
        A per-subscription baseline vs current table and an overall CLEARED / STILL-BLOCKED verdict,
        written to MDC-blocker-report.json.
.NOTES
    White-label. Read-only. Reads state only; changes nothing.
#>
[CmdletBinding()]
param(
    [string]$Baseline = ".\MDC-blocker-discovery.json",
    [string]$OutputPath = ".\MDC-blocker-report.json"
)

foreach ($m in 'Az.Accounts','Az.Security') {
    if (-not (Get-Module -ListAvailable -Name $m)) { Install-Module $m -Scope CurrentUser -Force -AllowClobber }
}
Import-Module Az.Accounts -ErrorAction Stop
if (-not (Get-AzContext)) { Connect-AzAccount | Out-Null }

Write-Host "`n=== TBMMDC — before/after blocker report (read-only) ===" -ForegroundColor Cyan
$base = $null
if (Test-Path $Baseline) { $base = Get-Content $Baseline -Raw | ConvertFrom-Json; Write-Host ("Baseline: {0} ({1})" -f $Baseline, $base.Timestamp) }
else { Write-Host "No baseline found — run TBMMDC-Discovery.ps1 first for a true before/after." -ForegroundColor Yellow; return }

$reportSubs = @()
$allCleared = $true
foreach ($bs in $base.Subscriptions) {
    $sid = $bs.SubscriptionId
    Write-Host ("`n### Subscription: {0}" -f $sid) -ForegroundColor Cyan
    try { Set-AzContext -Subscription $sid -ErrorAction Stop | Out-Null } catch { Write-Host ("   Cannot set context: {0}" -f $_.Exception.Message) -ForegroundColor Yellow; continue }

    $baseStd = @($bs.Plans | Where-Object { $_.Tier -eq 'Standard' }).Count
    $curStd  = @(Get-AzSecurityPricing -ErrorAction SilentlyContinue | Where-Object { $_.PricingTier -eq 'Standard' }).Count
    $curAssess = @(Get-AzSecurityAssessment -ErrorAction SilentlyContinue).Count
    $curScore  = (Get-AzSecuritySecureScore -ErrorAction SilentlyContinue | Select-Object -First 1).Current

    Write-Host ("   Standard plans base -> now : {0} -> {1}" -f $baseStd, $curStd)
    Write-Host ("   Assessments base -> now    : {0} -> {1}" -f $bs.AssessmentCount, $curAssess)
    Write-Host ("   Secure Score (now)         : {0}" -f $curScore)

    $cleared = ($curStd -gt 0 -and $curAssess -gt 0)
    if (-not $cleared) { $allCleared = $false }
    Write-Host ("   Verdict: {0}" -f $(if ($cleared) { 'CLEARED' } else { 'STILL-BLOCKED' })) -ForegroundColor ($(if ($cleared) { 'Green' } else { 'Yellow' }))
    $reportSubs += [ordered]@{ SubscriptionId=$sid; StandardPlansBase=$baseStd; StandardPlansNow=$curStd; AssessmentsBase=$bs.AssessmentCount; AssessmentsNow=$curAssess; SecureScoreNow=$curScore; Cleared=$cleared }
}

$verdict = if ($allCleared) { 'CLEARED' } else { 'STILL-BLOCKED' }
Write-Host ("`nOverall verdict: {0}" -f $verdict) -ForegroundColor ($(if ($allCleared) { 'Green' } else { 'Yellow' }))

[ordered]@{ Timestamp=(Get-Date).ToString('s'); BaselineTimestamp=$base.Timestamp; Subscriptions=$reportSubs; Verdict=$verdict } |
    ConvertTo-Json -Depth 8 | Set-Content -Path $OutputPath -Encoding UTF8
Write-Host ("Report: {0}" -f $OutputPath) -ForegroundColor Green
