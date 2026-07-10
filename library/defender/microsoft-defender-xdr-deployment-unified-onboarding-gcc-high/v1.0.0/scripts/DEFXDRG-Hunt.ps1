<#
.SYNOPSIS
    DEFXDRG-Hunt.ps1 — run the cross-pillar correlation advanced-hunting query to confirm all four
    Defender XDR pillars are streaming. Read-only.
.DESCRIPTION
    PURPOSE
        Read-only validation for the "Microsoft Defender XDR Deployment & Unified Onboarding"
        solution. Executes the KQL advanced-hunting query
        'XDR Cross-Pillar Correlation Check - Tenant - Validate' via the Microsoft 365 Defender
        advanced-hunting API (Microsoft Graph Security). It confirms each pillar's table
        (DeviceInfo, IdentityInfo, EmailEvents, CloudAppEvents) returns recent rows — the
        prerequisite for cross-pillar incident correlation. Makes no changes.
    HOW TO RUN
        powershell -ExecutionPolicy Bypass -File .\DEFXDRG-Hunt.ps1
        powershell -ExecutionPolicy Bypass -File .\DEFXDRG-Hunt.ps1 -LookbackHours 48
        # DoD (IL5): -GraphEnvironment USGovDoD
        Requires Microsoft.Graph.Authentication and ThreatHunting.Read.All consent. Connects to the
        US GOVERNMENT cloud (GCC High) by DEFAULT (-Environment USGov, graph.microsoft.us); for DoD (IL5)
        pass -GraphEnvironment USGovDoD (dod-graph.microsoft.us). Verify endpoints against current
        Microsoft Government documentation.
    EXPECTED RESULTS
        One row per pillar with its recent row count and a PASS/WARN flag; an overall verdict on
        whether all four pillars are streaming and correlation should be possible.
.NOTES
    White-label. Read-only. The embedded KQL only reads telemetry.
    The query is also saved in the portal as 'XDR Cross-Pillar Correlation Check - Tenant - Validate'.
#>
[CmdletBinding()]
param(
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
if (-not (Get-MgContext)) { Connect-MgGraph -Environment $GraphEnvironment -Scopes 'ThreatHunting.Read.All' -NoWelcome | Out-Null }

# --- The cross-pillar correlation check (KQL) ---
# Each pillar contributes a labelled row; the union lets one query confirm all four stream.
$kql = @"
let Window = ${LookbackHours}h;
DeviceInfo    | where Timestamp > ago(Window) | summarize Rows = count() | extend Pillar = 'Endpoint (DeviceInfo)'
| union (IdentityInfo  | where Timestamp > ago(Window) | summarize Rows = count() | extend Pillar = 'Identity (IdentityInfo)')
| union (EmailEvents   | where Timestamp > ago(Window) | summarize Rows = count() | extend Pillar = 'Office 365 (EmailEvents)')
| union (CloudAppEvents| where Timestamp > ago(Window) | summarize Rows = count() | extend Pillar = 'Cloud Apps (CloudAppEvents)')
| project Pillar, Rows
| sort by Pillar asc
"@

Write-Host "`n=== DEFXDRG — cross-pillar correlation check (read-only) ===" -ForegroundColor Cyan
Write-Host ("Lookback: {0}h" -f $LookbackHours)

try {
    $body = @{ Query = $kql } | ConvertTo-Json
    $resp = Invoke-MgGraphRequest -Method POST -Uri "$GraphBase/v1.0/security/runHuntingQuery" -Body $body -ContentType 'application/json'
    $streaming = 0
    if ($resp.results) {
        foreach ($r in $resp.results) {
            $rows = [int]$r.Rows
            $flag = if ($rows -gt 0) { 'PASS'; $streaming++ } else { 'WARN' }
            $color = if ($rows -gt 0) { 'Green' } else { 'Yellow' }
            Write-Host ("   {0,-30} rows: {1,-8} {2}" -f $r.Pillar, $rows, $flag) -ForegroundColor $color
        }
    }
    Write-Host ""
    if ($streaming -ge 4) {
        Write-Host "VERDICT: PASS — all four pillars stream. Cross-pillar correlation should group multi-pillar alerts." -ForegroundColor Green
    } else {
        Write-Host ("VERDICT: {0}/4 pillars streaming. Fix the WARN pillar(s) onboarding and allow warm-up time." -f $streaming) -ForegroundColor Yellow
        Write-Host "See Troubleshooting: 'No cross-pillar correlation'." -ForegroundColor Yellow
    }
} catch {
    Write-Host ("Could not run the hunting query: {0}" -f $_.Exception.Message) -ForegroundColor Yellow
    Write-Host "Confirm ThreatHunting.Read.All consent and that each pillar is activated in the portal." -ForegroundColor Yellow
}
