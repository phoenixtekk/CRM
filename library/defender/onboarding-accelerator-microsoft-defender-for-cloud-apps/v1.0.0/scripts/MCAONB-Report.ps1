<#
.SYNOPSIS
    MCAONB-Report.ps1 — coverage report for Defender for Cloud Apps: risky OAuth apps, policy
    inventory/posture, and baseline drift.
.DESCRIPTION
    PURPOSE
        Read-only reporting for the "Onboarding Accelerator — Microsoft Defender for Cloud Apps"
        solution. Summarizes risky third-party OAuth apps (via advanced hunting / app governance
        signal), the policy inventory and posture (should be report-only during the pilot), and —
        with -SaveBaseline — records a baseline so later runs show drift.
    HOW TO RUN
        powershell -ExecutionPolicy Bypass -File .\MCAONB-Report.ps1 -Section All -SaveBaseline
        -Section accepts: OAuth | Policies | All (default All).
        Uses Microsoft.Graph.Authentication + Graph Security (advanced hunting, secure score).
    EXPECTED RESULTS
        A list of risky OAuth apps, a policy posture summary, and drift versus the saved baseline.
        A downward trend in risky-OAuth count / a stable report-only posture = healthy onboarding.
.NOTES
    White-label. Read-only. Revoking an OAuth app is disruptive and stays approval-gated — the
    security team decides. OAuth-risk data is indicative; verify in App governance.
#>
[CmdletBinding()]
param(
    [ValidateSet('OAuth','Policies','All')] [string]$Section = 'All',
    [switch]$SaveBaseline,
    [string]$BaselinePath = ".\MCAONB-baseline.json"
)

Import-Module Microsoft.Graph.Authentication -ErrorAction Stop
if (-not (Get-MgContext)) { Connect-MgGraph -Scopes 'ThreatHunting.Read.All','SecurityEvents.Read.All' -NoWelcome | Out-Null }
Write-Host "`n=== Defender for Cloud Apps — coverage report ($Section) ===" -ForegroundColor Cyan
$oauthCount = $null

if ($Section -in 'OAuth','All') {
    Write-Host "`n-- Risky OAuth apps (via advanced hunting) --" -ForegroundColor Cyan
    $kql = @"
OAuthAppInfo
| where RiskLevel in ('Medium','High') or VerifiedPublisher == ''
| project AppName=OAuthAppName, RiskLevel, Permissions, VerifiedPublisher, ConsentType
| take 50
"@
    try {
        $resp = Invoke-MgGraphRequest -Method POST -Uri 'https://graph.microsoft.com/v1.0/security/runHuntingQuery' -Body (@{ Query = $kql } | ConvertTo-Json) -ContentType 'application/json'
        if ($resp.results) { $oauthCount = $resp.results.Count; $resp.results | ForEach-Object { Write-Host ("   [{0}] {1}" -f $_.RiskLevel, $_.AppName) } }
        else { Write-Host "   No risky OAuth apps returned (or table not yet populated). Confirm in App governance." -ForegroundColor Yellow; $oauthCount = 0 }
    } catch { Write-Host ("   OAuth hunt unavailable ({0}). Review Cloud apps > App governance." -f $_.Exception.Message) -ForegroundColor Yellow }
    Write-Host "   Revocation of any app stays APPROVAL-GATED — security team decides." -ForegroundColor DarkGray
}

if ($Section -in 'Policies','All') {
    Write-Host "`n-- Policy inventory / posture --" -ForegroundColor Cyan
    Write-Host "   Confirm in: Cloud apps > Policies > Policy management." -ForegroundColor DarkGray
    Write-Host "   REVIEW: 'MDCA Session Control - Pilot Users - Report' and 'MDCA Access Control - Pilot Users - Report'" -ForegroundColor Yellow
    Write-Host "           are report-only, pilot-scoped; anomaly-detection policies on; no auto-block during pilot." -ForegroundColor Yellow
}

$now = [ordered]@{ Timestamp = (Get-Date).ToString('s'); RiskyOAuthCount = $oauthCount }
if ($SaveBaseline) { $now | ConvertTo-Json | Set-Content -Path $BaselinePath -Encoding UTF8; Write-Host ("`nBaseline saved: {0}" -f $BaselinePath) -ForegroundColor Green }
elseif (Test-Path $BaselinePath) {
    $base = Get-Content $BaselinePath -Raw | ConvertFrom-Json
    if ($null -ne $oauthCount -and $null -ne $base.RiskyOAuthCount) { Write-Host ("`nRisky-OAuth drift vs baseline ({0}): {1}" -f $base.Timestamp, ($oauthCount - $base.RiskyOAuthCount)) -ForegroundColor Cyan }
} else { Write-Host "`n(no baseline yet — run with -SaveBaseline to create one)" -ForegroundColor DarkGray }
Write-Host "Report complete (read-only)." -ForegroundColor Green
