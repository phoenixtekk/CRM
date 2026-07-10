<#
.SYNOPSIS
    DEFCSPMG-Report.ps1 — Secure Score + top recommendations report with drift versus a saved
    baseline (measures whether remediation is raising the score). Read-only.
.DESCRIPTION
    PURPOSE
        Read-only reporting for the "Microsoft Defender for Cloud — CSPM & Secure Score
        Remediation" solution. Reports the current Secure Score, a count of unhealthy security
        assessments (open recommendations), and the top unhealthy assessments by name. If
        -BaselinePath points to a JSON file from a previous run, reports the DRIFT (score delta and
        change in open recommendations) so you can prove remediation is working. With -SaveBaseline,
        writes this run for next-cycle comparison.
    HOW TO RUN
        powershell -ExecutionPolicy Bypass -File .\DEFCSPMG-Report.ps1
        powershell -ExecutionPolicy Bypass -File .\DEFCSPMG-Report.ps1 -BaselinePath .\defcspm-baseline.json -SaveBaseline
        Requires Az.Accounts, Az.Security.
    EXPECTED RESULTS
        A posture report: Secure Score (current/max/percent), open-recommendation count, top
        unhealthy assessments, and — with a baseline — a drift line showing the improvement.
.NOTES
    Government (GCC High) edition: targets the US Gov cloud via Connect-AzAccount -Environment AzureUSGovernment. Plan/feature availability in GCC High/DoD may lag commercial — verify against current Microsoft Government documentation.
    White-label. Read-only.
#>
[CmdletBinding()]
param(
    [string]$SubscriptionId,
    [string]$BaselinePath,
    [switch]$SaveBaseline,
    [int]$TopRecommendations = 10
)

foreach ($m in 'Az.Accounts','Az.Security') {
    if (-not (Get-Module -ListAvailable -Name $m)) { Install-Module Az -Scope CurrentUser -Force -AllowClobber; break }
}
Import-Module Az.Accounts -ErrorAction Stop
Import-Module Az.Security -ErrorAction Stop

if (-not (Get-AzContext)) { Connect-AzAccount -Environment AzureUSGovernment | Out-Null }
if ($SubscriptionId) { Set-AzContext -SubscriptionId $SubscriptionId | Out-Null }
$ctx = Get-AzContext

Write-Host "`n=== Defender for Cloud — Secure Score & recommendations report (read-only) ===" -ForegroundColor Cyan
Write-Host ("Subscription: {0} ({1})" -f $ctx.Subscription.Name, $ctx.Subscription.Id)

# --- Secure Score ---
$scorePct = $null
Write-Host "`n-- Secure Score --" -ForegroundColor Cyan
try {
    $score = Get-AzSecuritySecureScore -ErrorAction SilentlyContinue | Where-Object { $_.DisplayName -eq 'ascScore' } | Select-Object -First 1
    if (-not $score) { $score = Get-AzSecuritySecureScore -ErrorAction SilentlyContinue | Select-Object -First 1 }
    if ($score) {
        $scorePct = [math]::Round($score.Percentage * 100)
        Write-Host ("   Secure Score: {0}% ({1}/{2})" -f $scorePct, $score.CurrentScore, $score.MaxScore) -ForegroundColor Green
    } else { Write-Host "   Secure Score not available yet." -ForegroundColor Yellow }
} catch { Write-Host ("   Could not read Secure Score: {0}" -f $_.Exception.Message) -ForegroundColor Yellow }

# --- Open recommendations (unhealthy assessments) ---
Write-Host "`n-- Open recommendations (unhealthy assessments) --" -ForegroundColor Cyan
$openCount = 0
try {
    $assess = Get-AzSecurityAssessment -ErrorAction Stop
    $unhealthy = $assess | Where-Object { $_.Status.Code -eq 'Unhealthy' }
    $openCount = ($unhealthy | Measure-Object).Count
    Write-Host ("   Open (unhealthy): {0}" -f $openCount)
    Write-Host ("   Top {0} by name:" -f $TopRecommendations) -ForegroundColor Cyan
    $unhealthy | Select-Object -First $TopRecommendations | ForEach-Object {
        Write-Host ("     - {0}" -f $_.DisplayName)
    }
} catch { Write-Host ("   Could not read assessments: {0}" -f $_.Exception.Message) -ForegroundColor Yellow }

# --- Drift ---
if ($BaselinePath -and (Test-Path $BaselinePath)) {
    try {
        $base = Get-Content $BaselinePath -Raw | ConvertFrom-Json
        Write-Host "`n-- Drift vs baseline --" -ForegroundColor Cyan
        $scoreDelta = if ($null -ne $scorePct -and $null -ne $base.SecureScorePct) { $scorePct - $base.SecureScorePct } else { 'n/a' }
        $openDelta  = $openCount - [int]$base.OpenRecommendations
        Write-Host ("   Secure Score delta: {0} (baseline {1}% -> now {2}%)" -f $scoreDelta, $base.SecureScorePct, $scorePct)
        Write-Host ("   Open recommendations delta: {0} (baseline {1} -> now {2})" -f $openDelta, $base.OpenRecommendations, $openCount)
        if ($scoreDelta -is [int] -and $scoreDelta -gt 0) { Write-Host "   Trend: IMPROVING — remediation is raising the score." -ForegroundColor Green }
    } catch { Write-Host ("   Could not read baseline: {0}" -f $_.Exception.Message) -ForegroundColor Yellow }
}

# --- Save baseline ---
if ($BaselinePath -and $SaveBaseline) {
    $snap = [pscustomobject]@{
        Timestamp           = (Get-Date).ToString('s')
        SubscriptionId      = $ctx.Subscription.Id
        SecureScorePct      = $scorePct
        OpenRecommendations = $openCount
    }
    $snap | ConvertTo-Json | Set-Content -Path $BaselinePath -Encoding UTF8
    Write-Host ("`nBaseline saved to {0}" -f $BaselinePath) -ForegroundColor Green
}

Write-Host "`nReport complete (read-only)." -ForegroundColor Green
