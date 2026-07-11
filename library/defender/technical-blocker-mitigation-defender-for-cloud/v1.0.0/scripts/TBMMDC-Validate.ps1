<#
.SYNOPSIS
    TBMMDC-Validate.ps1 — read-only pass/fail check that a Defender for Cloud blocker is cleared on the
    affected scope.
.DESCRIPTION
    PURPOSE
        Read-only validation for the "Technical Blocker Mitigation — Defender for Cloud" solution.
        For each subscription in scope, re-checks the signal-chain links and returns pass/fail:
        plan On (Standard), assessments/recommendations present, Secure Score returns a value, and (if
        present) security connectors exist. Makes NO changes.
    HOW TO RUN
        Connect-AzAccount ; then:
        powershell -ExecutionPolicy Bypass -File .\TBMMDC-Validate.ps1 -SubscriptionIds "sub1,sub2"
        Requires Az.Accounts, Az.Security. Read-only (Security Reader / Reader).
    EXPECTED RESULTS
        PASS/FAIL lines per link. FAIL points you to the matching Troubleshooting section.
.NOTES
    White-label. Read-only. Reads state only; changes nothing.
#>
[CmdletBinding()]
param(
    [string]$SubscriptionIds = ""
)

foreach ($m in 'Az.Accounts','Az.Security') {
    if (-not (Get-Module -ListAvailable -Name $m)) { Install-Module $m -Scope CurrentUser -Force -AllowClobber }
}
Import-Module Az.Accounts -ErrorAction Stop
if (-not (Get-AzContext)) { Connect-AzAccount | Out-Null }
$subs = if ($SubscriptionIds) { $SubscriptionIds.Split(',') | ForEach-Object { $_.Trim() } } else { @((Get-AzContext).Subscription.Id) }

Write-Host "`n=== TBMMDC validation — affected scope (read-only) ===" -ForegroundColor Cyan

foreach ($sid in $subs) {
    Write-Host ("`n### Subscription: {0}" -f $sid) -ForegroundColor Cyan
    try { Set-AzContext -Subscription $sid -ErrorAction Stop | Out-Null } catch { Write-Host ("   Cannot set context: {0}" -f $_.Exception.Message) -ForegroundColor Yellow; continue }

    # Plan On?
    try {
        $std = @(Get-AzSecurityPricing -ErrorAction Stop | Where-Object { $_.PricingTier -eq 'Standard' })
        if ($std.Count -gt 0) { Write-Host ("   PASS — {0} plan(s) On (Standard)." -f $std.Count) -ForegroundColor Green }
        else { Write-Host "   FAIL — no Standard plans. See Troubleshooting 'Plan will not enable / reverts to Free'." -ForegroundColor Yellow }
    } catch { Write-Host ("   Could not read pricing: {0}" -f $_.Exception.Message) -ForegroundColor Yellow }

    # Assessments present?
    try {
        $assess = @(Get-AzSecurityAssessment -ErrorAction SilentlyContinue)
        if ($assess.Count -gt 0) { Write-Host ("   PASS — {0} assessment(s)/recommendation(s) present." -f $assess.Count) -ForegroundColor Green }
        else { Write-Host "   FAIL — no assessments. See Troubleshooting 'Recommendations not populating'." -ForegroundColor Yellow }
    } catch { Write-Host ("   Could not read assessments: {0}" -f $_.Exception.Message) -ForegroundColor Yellow }

    # Secure Score present?
    try {
        $score = Get-AzSecuritySecureScore -ErrorAction SilentlyContinue | Select-Object -First 1
        if ($score) { Write-Host ("   PASS — Secure Score present (current: {0})." -f $score.Current) -ForegroundColor Green }
        else { Write-Host "   INFO — no Secure Score yet (allow warm-up). See 'Recommendations not populating' if persistent." -ForegroundColor Yellow }
    } catch { Write-Host ("   Could not read Secure Score: {0}" -f $_.Exception.Message) -ForegroundColor Yellow }

    # Connectors (informational)
    try {
        $uri = "/subscriptions/$sid/providers/Microsoft.Security/securityConnectors?api-version=2023-10-01-preview"
        $resp = Invoke-AzRestMethod -Method GET -Path $uri -ErrorAction SilentlyContinue
        if ($resp -and $resp.StatusCode -eq 200) {
            $c = ($resp.Content | ConvertFrom-Json).value
            if ($c) { Write-Host ("   INFO — {0} multicloud connector(s) present (confirm 'connected/syncing' in portal)." -f $c.Count) }
            else    { Write-Host "   INFO — no multicloud connectors on this subscription." -ForegroundColor DarkGray }
        }
    } catch { }
}

Write-Host "`nValidation complete (read-only). Cross-check plan/coverage/connector/recommendations in the portal." -ForegroundColor Green
