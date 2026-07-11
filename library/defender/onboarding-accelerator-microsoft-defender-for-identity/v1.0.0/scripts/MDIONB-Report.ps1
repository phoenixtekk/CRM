<#
.SYNOPSIS
    MDIONB-Report.ps1 — sensor-health + identity posture (ISPM) + coverage report with baseline drift.
.DESCRIPTION
    PURPOSE
        Read-only reporting for the "Onboarding Accelerator — Microsoft Defender for Identity"
        solution. Summarizes sensor health across domain controllers, the MDI/Identity Secure
        Score recommendations (ISPM), and — with -SaveBaseline — records a posture baseline so
        later runs show drift. Also reports the response-action posture (should be approval-gated).
    HOW TO RUN
        powershell -ExecutionPolicy Bypass -File .\MDIONB-Report.ps1 -SaveBaseline
        powershell -ExecutionPolicy Bypass -File .\MDIONB-Report.ps1   # compare to saved baseline
        Uses Microsoft.Graph.Authentication + Graph Security (Secure Score, secure-score-control-profiles).
    EXPECTED RESULTS
        A sensor-health summary, the current Identity Secure Score and top recommendations, and the
        delta versus the saved baseline. A trend of remediated recommendations = improving posture.
.NOTES
    White-label. Read-only. ISPM/Secure Score facts are indicative — verify current availability.
    Response actions must remain approval-gated until the SOC decides otherwise.
#>
[CmdletBinding()]
param(
    [switch]$SaveBaseline,
    [string]$BaselinePath = ".\MDIONB-posture-baseline.json"
)

Import-Module Microsoft.Graph.Authentication -ErrorAction Stop
if (-not (Get-MgContext)) {
    Connect-MgGraph -Scopes 'SecurityEvents.Read.All','SecurityIdentitiesHealth.Read.All' -NoWelcome | Out-Null
}
Write-Host "`n=== Defender for Identity — posture & coverage report ===" -ForegroundColor Cyan

# --- Sensor health summary ---
Write-Host "`n-- Sensor health --" -ForegroundColor Cyan
try {
    $sensors = (Invoke-MgGraphRequest -Method GET -Uri 'https://graph.microsoft.com/beta/security/identities/sensors' -ErrorAction Stop).value
    $healthy = @($sensors | Where-Object { $_.healthStatus -eq 'healthy' }).Count
    Write-Host ("   Sensors: {0}  Healthy: {1}" -f ($sensors | Measure-Object).Count, $healthy) -ForegroundColor Green
} catch { Write-Host "   Sensor health API unavailable — confirm in Settings > Identities > Sensors." -ForegroundColor Yellow; $sensors = @() }

# --- Identity Secure Score / ISPM ---
Write-Host "`n-- Identity Secure Score (ISPM) --" -ForegroundColor Cyan
$score = $null; $recs = @()
try {
    $ss = (Invoke-MgGraphRequest -Method GET -Uri 'https://graph.microsoft.com/v1.0/security/secureScores?$top=1').value | Select-Object -First 1
    if ($ss) { $score = [double]$ss.currentScore; Write-Host ("   Current Secure Score: {0} / {1}" -f $ss.currentScore, $ss.maxScore) -ForegroundColor Green }
    $profiles = (Invoke-MgGraphRequest -Method GET -Uri "https://graph.microsoft.com/v1.0/security/secureScoreControlProfiles?`$top=200").value
    $recs = $profiles | Where-Object { $_.controlCategory -match 'Identity' } | Select-Object -First 15 -Property title, controlCategory, actionUrl
    if ($recs) { $recs | ForEach-Object { Write-Host ("     [{0}] {1}" -f $_.controlCategory, $_.title) } }
    else { Write-Host "   No Identity recommendations resolved yet (allow sensor warm-up). Verify ISPM availability." -ForegroundColor Yellow }
} catch { Write-Host ("   Secure Score read failed: {0}" -f $_.Exception.Message) -ForegroundColor Yellow }

Write-Host "`n-- Response actions --" -ForegroundColor Cyan
Write-Host "   Confirm response actions (disable user / force password reset) remain APPROVAL-GATED." -ForegroundColor DarkGray
Write-Host "   Settings > Identities > Response actions (verify current availability in your tenant)." -ForegroundColor DarkGray

$now = [ordered]@{ Timestamp = (Get-Date).ToString('s'); SecureScore = $score; SensorCount = ($sensors | Measure-Object).Count; IdentityRecommendations = @($recs | ForEach-Object { $_.title }) }
if ($SaveBaseline) {
    $now | ConvertTo-Json -Depth 6 | Set-Content -Path $BaselinePath -Encoding UTF8
    Write-Host ("`nBaseline saved: {0}" -f $BaselinePath) -ForegroundColor Green
} elseif (Test-Path $BaselinePath) {
    $base = Get-Content $BaselinePath -Raw | ConvertFrom-Json
    if ($null -ne $score -and $null -ne $base.SecureScore) {
        $delta = [math]::Round($score - $base.SecureScore, 2)
        Write-Host ("`nSecure Score drift vs baseline ({0}): {1}" -f $base.Timestamp, $delta) -ForegroundColor $(if ($delta -ge 0) { 'Green' } else { 'Yellow' })
    }
} else { Write-Host "`n(no baseline yet — run with -SaveBaseline to create one)" -ForegroundColor DarkGray }
Write-Host "Report complete (read-only)." -ForegroundColor Green
