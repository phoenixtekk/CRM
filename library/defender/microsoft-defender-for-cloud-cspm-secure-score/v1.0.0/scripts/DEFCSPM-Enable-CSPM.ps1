<#
.SYNOPSIS
    DEFCSPM-Enable-CSPM.ps1 — enable the Defender CSPM (CloudPosture) plan on a subscription.
    SAFE PREVIEW by default (-WhatIf); makes the change only when explicitly confirmed.
.DESCRIPTION
    PURPOSE
        Change helper for the "Microsoft Defender for Cloud — CSPM & Secure Score Remediation"
        solution. Sets the Defender for Cloud CloudPosture (Defender CSPM) plan to Standard on the
        target subscription so agentless scanning, attack paths, and risk hunting unlock. This is
        the only script that can change configuration, and it DEFAULTS TO A SAFE PREVIEW.
    HOW TO RUN
        # Preview (default — shows current vs intended, changes nothing):
        powershell -ExecutionPolicy Bypass -File .\DEFCSPM-Enable-CSPM.ps1 -SubscriptionId '<pilot sub>'
        # Apply (explicit — required to make the change):
        powershell -ExecutionPolicy Bypass -File .\DEFCSPM-Enable-CSPM.ps1 -SubscriptionId '<pilot sub>' -Apply
        Requires Az.Accounts, Az.Security and Security Admin / Owner at the subscription.
    EXPECTED RESULTS
        Preview: prints the current CloudPosture tier and that it WOULD be set to Standard.
        Apply: sets the plan to Standard and confirms. Pilot first; Defender CSPM is a PAID plan —
        verify current pricing/availability in your tenant before applying.
.NOTES
    White-label. DEFAULTS TO -WhatIf/preview. Defender CSPM is paid — cost applies on Apply.
#>
[CmdletBinding()]
param(
    [Parameter(Mandatory)] [string]$SubscriptionId,
    [switch]$Apply
)

foreach ($m in 'Az.Accounts','Az.Security') {
    if (-not (Get-Module -ListAvailable -Name $m)) { Install-Module Az -Scope CurrentUser -Force -AllowClobber; break }
}
Import-Module Az.Accounts -ErrorAction Stop
Import-Module Az.Security -ErrorAction Stop

if (-not (Get-AzContext)) { Connect-AzAccount | Out-Null }
Set-AzContext -SubscriptionId $SubscriptionId | Out-Null

$whatIf = -not $Apply
Write-Host "`n=== DEFCSPM enable Defender CSPM (CloudPosture) ===" -ForegroundColor Cyan
Write-Host ("Subscription: {0}" -f $SubscriptionId)
Write-Host ("Mode: {0}" -f ($(if ($whatIf) { 'PREVIEW (-WhatIf) — no changes' } else { 'APPLY — will enable a PAID plan' }))) -ForegroundColor $(if ($whatIf) { 'Yellow' } else { 'Red' })

# Current state
try {
    $cur = Get-AzSecurityPricing -Name 'CloudPosture' -ErrorAction SilentlyContinue
    $curTier = if ($cur) { $cur.PricingTier } else { '(not set / Free)' }
    Write-Host ("Current CloudPosture tier: {0}" -f $curTier)
} catch { Write-Host ("Could not read current plan: {0}" -f $_.Exception.Message) -ForegroundColor Yellow }

if ($whatIf) {
    Write-Host "`nWOULD set CloudPosture (Defender CSPM) to 'Standard' on this subscription." -ForegroundColor Yellow
    Write-Host "Defender CSPM is a PAID plan — verify current pricing/availability, then re-run with -Apply." -ForegroundColor Yellow
    return
}

# Apply
try {
    Set-AzSecurityPricing -Name 'CloudPosture' -PricingTier 'Standard' -ErrorAction Stop | Out-Null
    Write-Host "`nAPPLIED — Defender CSPM (CloudPosture) set to Standard." -ForegroundColor Green
    Write-Host "Next: enable agentless scanning in the plan settings, then validate with DEFCSPM-Validate.ps1." -ForegroundColor Green
    Write-Host "Rollback: Set-AzSecurityPricing -Name 'CloudPosture' -PricingTier 'Free'" -ForegroundColor DarkGray
} catch {
    Write-Host ("Enable failed: {0}" -f $_.Exception.Message) -ForegroundColor Red
}
