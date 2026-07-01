<#
.SYNOPSIS
    AZSEC-Report.ps1 — governance-posture report: assignments, per-policy compliance, Defender for
    Cloud secure score and top recommendations, and drift versus a saved baseline.
.DESCRIPTION
    PURPOSE
        Read-only reporting for the "Azure Security Baseline & Governance" solution. Produces a
        posture snapshot for the scope in context (or a named subscription): the policy assignments,
        a compliant/non-compliant summary from Azure Policy state, the Defender for Cloud secure
        score, and the top open recommendations by impact. If -BaselinePath points to a JSON file
        written by a previous run, reports the DRIFT (new non-compliant resources / score change).
        Optionally writes this run's summary to -BaselinePath for next-cycle drift comparison.
    HOW TO RUN
        powershell -ExecutionPolicy Bypass -File .\AZSEC-Report.ps1
        powershell -ExecutionPolicy Bypass -File .\AZSEC-Report.ps1 -SubscriptionId '<sub id>'
        powershell -ExecutionPolicy Bypass -File .\AZSEC-Report.ps1 -BaselinePath .\azsec-baseline.json -SaveBaseline
        Requires Az.Accounts, Az.Resources, Az.PolicyInsights, Az.Security. Run Connect-AzAccount
        first, or the script will prompt.
    EXPECTED RESULTS
        A governance-posture report — assignments, non-compliant resource counts per policy, secure
        score, and top recommendations. With -BaselinePath, a drift line comparing this run to the
        saved baseline (score delta and new non-compliant count).
.NOTES
    Workplace Marketplace — Azure Solutions. Read-only. The repeatable way.
#>
[CmdletBinding()]
param(
    [string]$SubscriptionId,
    [string]$BaselinePath,
    [switch]$SaveBaseline,
    [int]$TopRecommendations = 10
)

foreach ($m in 'Az.Accounts','Az.Resources','Az.PolicyInsights','Az.Security') {
    if (-not (Get-Module -ListAvailable -Name $m)) { Install-Module Az -Scope CurrentUser -Force -AllowClobber; break }
}
Import-Module Az.Accounts -ErrorAction Stop
Import-Module Az.Resources -ErrorAction Stop
Import-Module Az.PolicyInsights -ErrorAction Stop
Import-Module Az.Security -ErrorAction Stop

if (-not (Get-AzContext)) { Connect-AzAccount | Out-Null }
if ($SubscriptionId) { Set-AzContext -SubscriptionId $SubscriptionId | Out-Null }

$ctx   = Get-AzContext
$scope = "/subscriptions/$($ctx.Subscription.Id)"

Write-Host "`n=== Azure Security Baseline & Governance — posture report ===" -ForegroundColor Cyan
Write-Host ("Subscription: {0} ({1})" -f $ctx.Subscription.Name, $ctx.Subscription.Id)

# --- Assignments ---
Write-Host "`n-- Policy assignments --" -ForegroundColor Cyan
try {
    $assignments = Get-AzPolicyAssignment -Scope $scope -ErrorAction Stop
    if ($assignments) { $assignments | ForEach-Object { Write-Host ("   {0}" -f $_.Name) } }
    else { Write-Host "   (none)" -ForegroundColor Yellow }
} catch { Write-Host ("   Could not read assignments: {0}" -f $_.Exception.Message) -ForegroundColor Yellow }

# --- Compliance summary from policy state ---
Write-Host "`n-- Compliance (non-compliant resources by policy) --" -ForegroundColor Cyan
$nonCompliantTotal = 0
try {
    $states = Get-AzPolicyState -Filter "ComplianceState eq 'NonCompliant'" -ErrorAction Stop
    if ($states) {
        $nonCompliantTotal = ($states | Measure-Object).Count
        $states | Group-Object PolicyDefinitionName | Sort-Object Count -Descending | ForEach-Object {
            Write-Host ("   {0,-45} non-compliant: {1}" -f $_.Name, $_.Count)
        }
    } else { Write-Host "   No non-compliant resources reported." -ForegroundColor Green }
} catch { Write-Host ("   Could not read policy state (run a compliance scan first): {0}" -f $_.Exception.Message) -ForegroundColor Yellow }

# --- Defender for Cloud secure score + top recommendations ---
Write-Host "`n-- Microsoft Defender for Cloud --" -ForegroundColor Cyan
$scorePct = $null
try {
    $score = Get-AzSecuritySecureScore -ErrorAction SilentlyContinue | Where-Object { $_.DisplayName -eq 'ascScore' } | Select-Object -First 1
    if (-not $score) { $score = Get-AzSecuritySecureScore -ErrorAction SilentlyContinue | Select-Object -First 1 }
    if ($score) {
        $scorePct = [math]::Round($score.Percentage * 100)
        Write-Host ("   Secure score: {0}% ({1}/{2})" -f $scorePct, $score.CurrentScore, $score.MaxScore)
    } else { Write-Host "   Secure score not available yet." -ForegroundColor Yellow }
} catch { Write-Host ("   Could not read secure score: {0}" -f $_.Exception.Message) -ForegroundColor Yellow }

try {
    $tasks = Get-AzSecurityTask -ErrorAction SilentlyContinue
    if ($tasks) {
        Write-Host ("   Top open recommendations (up to {0}):" -f $TopRecommendations) -ForegroundColor Cyan
        $tasks | Select-Object -First $TopRecommendations | ForEach-Object {
            Write-Host ("     - {0}" -f $_.Name)
        }
    } else { Write-Host "   No open recommendations reported." -ForegroundColor Green }
} catch { Write-Host ("   Could not read recommendations: {0}" -f $_.Exception.Message) -ForegroundColor Yellow }

# --- Drift vs baseline ---
if ($BaselinePath -and (Test-Path $BaselinePath)) {
    try {
        $base = Get-Content $BaselinePath -Raw | ConvertFrom-Json
        Write-Host "`n-- Drift vs baseline --" -ForegroundColor Cyan
        $scoreDelta = if ($null -ne $scorePct -and $null -ne $base.SecureScorePct) { $scorePct - $base.SecureScorePct } else { 'n/a' }
        $ncDelta    = $nonCompliantTotal - [int]$base.NonCompliantTotal
        Write-Host ("   Secure score delta: {0}" -f $scoreDelta)
        Write-Host ("   Non-compliant delta: {0} (baseline {1} -> now {2})" -f $ncDelta, $base.NonCompliantTotal, $nonCompliantTotal)
    } catch { Write-Host ("   Could not read baseline: {0}" -f $_.Exception.Message) -ForegroundColor Yellow }
}

# --- Save baseline for next cycle ---
if ($BaselinePath -and $SaveBaseline) {
    $snapshot = [pscustomobject]@{
        Timestamp         = (Get-Date).ToString('s')
        SubscriptionId    = $ctx.Subscription.Id
        SecureScorePct    = $scorePct
        NonCompliantTotal = $nonCompliantTotal
    }
    $snapshot | ConvertTo-Json | Set-Content -Path $BaselinePath
    Write-Host ("`nBaseline saved to {0}" -f $BaselinePath) -ForegroundColor Green
}

Write-Host "`nReport complete (read-only)." -ForegroundColor Green
