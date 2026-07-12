<#
.SYNOPSIS
    MDCAFULL-Report.ps1 — read-only coverage & OAuth-risk report for Defender for Cloud Apps, with
    shadow-IT / OAuth shortlist templates and baseline-drift comparison.
.DESCRIPTION
    PURPOSE
        Read-only reporting for the complete "Microsoft Defender for Cloud Apps" solution. By section:
          OAuth    — a summary of risky OAuth apps (delegates to the same read as MDCAFULL-OAuthRisk)
                     plus the 'OAuthRisk-Shortlist - CloudApps - Pilot' template.
          Policies — MDCA alerts by severity + the policy inventory/posture reminder (portal confirm).
          All      — both, plus the 'ShadowIT-Shortlist - CloudApps - Pilot' template.
        -SaveBaseline writes the current numbers as a baseline; a later run reports drift against it.
        Makes no changes.
    HOW TO RUN
        powershell -ExecutionPolicy Bypass -File .\MDCAFULL-Report.ps1 -Section All
        powershell -ExecutionPolicy Bypass -File .\MDCAFULL-Report.ps1 -Section Policies -SaveBaseline
        -Section accepts: OAuth | Policies | All (default All). Uses Microsoft.Graph read scopes.
    EXPECTED RESULTS
        A printed coverage/risk summary and shortlist templates; a JSON snapshot; and, when a baseline
        exists, the drift (new/resolved alerts, OAuth-risk change) since the last baseline.
.NOTES
    White-label. Read-only. Shortlists are recommendations — app-sanctioning / revocation decisions
    are the customer's security team's.
#>
[CmdletBinding()]
param(
    [ValidateSet('OAuth','Policies','All')] [string]$Section = 'All',
    [switch]$SaveBaseline,
    [string]$OutputPath = ".\MDCAFULL-report.json",
    [string]$BaselinePath = ".\MDCAFULL-baseline.json"
)

Import-Module Microsoft.Graph.Authentication -ErrorAction Stop
if (-not (Get-MgContext)) { Connect-MgGraph -Scopes 'SecurityEvents.Read.All','Application.Read.All','Directory.Read.All' -NoWelcome | Out-Null }
Write-Host "`n=== Defender for Cloud Apps — report ($Section) ===" -ForegroundColor Cyan
$snap = [ordered]@{ Timestamp = (Get-Date).ToString('s') }

function Get-McaAlerts {
    try { return (Invoke-MgGraphRequest -Method GET -Uri "https://graph.microsoft.com/v1.0/security/alerts_v2?`$top=200&`$filter=serviceSource eq 'microsoftDefenderForCloudApps'").value } catch { return @() }
}

if ($Section -in 'Policies','All') {
    Write-Host "`n-- MDCA alerts by severity (read-only) --" -ForegroundColor Cyan
    $alerts = Get-McaAlerts
    $bySev = $alerts | Group-Object severity | Sort-Object Name
    if ($bySev) { $bySev | ForEach-Object { Write-Host ("   {0,-10} {1}" -f $_.Name, $_.Count) } } else { Write-Host "   No MDCA alerts in the sample window (or none reachable)." -ForegroundColor Yellow }
    $snap.AlertsTotal = (($alerts | Measure-Object).Count)
    $snap.AlertsBySeverity = @{}; $bySev | ForEach-Object { $snap.AlertsBySeverity[$_.Name] = $_.Count }
    Write-Host "`n   Confirm policy inventory/posture in: Cloud apps > Policies — report-only first, enforcing gated." -ForegroundColor DarkGray
}

if ($Section -in 'OAuth','All') {
    Write-Host "`n-- OAuth app risk summary (read-only) --" -ForegroundColor Cyan
    $highRiskScopes = @('Mail.ReadWrite','Mail.Send','Files.ReadWrite.All','Directory.ReadWrite.All','Sites.ReadWrite.All','User.ReadWrite.All','full_access_as_user','Application.ReadWrite.All')
    $risky = 0; $total = 0
    try {
        Import-Module Microsoft.Graph.Applications -ErrorAction Stop
        $sps = Get-MgServicePrincipal -All -Property 'id','displayName','appId','verifiedPublisher','servicePrincipalType' -ErrorAction Stop | Where-Object { $_.ServicePrincipalType -eq 'Application' }
        foreach ($sp in $sps) {
            $total++
            $grants = @(); try { $grants = Get-MgServicePrincipalOauth2PermissionGrant -ServicePrincipalId $sp.Id -All -ErrorAction Stop } catch {}
            $scopeText = ($grants | ForEach-Object { $_.Scope }) -join ' '
            $high = @($highRiskScopes | Where-Object { $scopeText -match [regex]::Escape($_) })
            $verified = [bool]($sp.VerifiedPublisher -and $sp.VerifiedPublisher.DisplayName)
            if ($high.Count -gt 0 -or -not $verified) { $risky++ }
        }
        Write-Host ("   OAuth apps: {0} total, {1} flagged (high-priv scope or unverified publisher)." -f $total, $risky) -ForegroundColor Green
    } catch { Write-Host ("   Could not enumerate OAuth apps: {0} (run MDCAFULL-OAuthRisk.ps1 for detail)." -f $_.Exception.Message) -ForegroundColor Yellow }
    $snap.OAuthTotal = $total; $snap.OAuthRisky = $risky
    Write-Host "`n   TEMPLATE 'OAuthRisk-Shortlist - CloudApps - Pilot': App | Publisher verified? | High-priv scopes | Disposition (review/restrict/revoke-with-approval)" -ForegroundColor DarkGray
}

if ($Section -eq 'All') {
    Write-Host "`n   TEMPLATE 'ShadowIT-Shortlist - CloudApps - Pilot': App | Risk score | Users | Traffic | Disposition (sanction/restrict/block-later)" -ForegroundColor DarkGray
    Write-Host "   (Build from Cloud apps > Cloud discovery > Discovered apps, sorted by risk score.)" -ForegroundColor DarkGray
}

# Baseline drift
if ($SaveBaseline) {
    $snap | ConvertTo-Json -Depth 6 | Set-Content -Path $BaselinePath -Encoding UTF8
    Write-Host ("`nBaseline saved: {0}" -f $BaselinePath) -ForegroundColor Green
} elseif (Test-Path $BaselinePath) {
    try {
        $base = Get-Content $BaselinePath -Raw | ConvertFrom-Json
        Write-Host "`n-- Drift vs baseline --" -ForegroundColor Cyan
        if ($null -ne $snap.AlertsTotal -and $null -ne $base.AlertsTotal) { Write-Host ("   Alerts: {0} -> {1} (delta {2})" -f $base.AlertsTotal, $snap.AlertsTotal, ($snap.AlertsTotal - $base.AlertsTotal)) }
        if ($null -ne $snap.OAuthRisky -and $null -ne $base.OAuthRisky) { Write-Host ("   OAuth risky: {0} -> {1} (delta {2})" -f $base.OAuthRisky, $snap.OAuthRisky, ($snap.OAuthRisky - $base.OAuthRisky)) }
    } catch { Write-Host "   Could not read baseline for drift." -ForegroundColor Yellow }
}

$snap | ConvertTo-Json -Depth 6 | Set-Content -Path $OutputPath -Encoding UTF8
Write-Host ("`nReport complete (read-only). Snapshot: {0}" -f $OutputPath) -ForegroundColor Green
