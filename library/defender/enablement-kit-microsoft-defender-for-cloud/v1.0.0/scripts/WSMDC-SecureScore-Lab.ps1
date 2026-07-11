<#
.SYNOPSIS
    WSMDC-SecureScore-Lab.ps1 — preview-first (-WhatIf) Lab 5 helper: shows what enabling a Defender
    plan on the PILOT subscription WOULD do. Defaults to preview — changes nothing.
.DESCRIPTION
    PURPOSE
        Supports Lab 5 of the "Workshop — Microsoft Defender for Cloud". It teaches the enable path
        for a Defender (CWPP) plan safely: by default it runs in PREVIEW and only REPORTS what would
        change (current tier -> desired tier). It performs the change ONLY if BOTH -Apply is passed
        AND -Confirm is answered — i.e. explicitly approval-gated. Intended for the PILOT subscription
        only, never production, and never at scale (that is the CSPM-program solution).
    HOW TO RUN
        Preview (default, safe):
          powershell -ExecutionPolicy Bypass -File .\WSMDC-SecureScore-Lab.ps1 -SubscriptionId '<pilot>' -PlanName 'VirtualMachines' -WhatIf
        Approval-gated apply (facilitator, pilot only):
          powershell -ExecutionPolicy Bypass -File .\WSMDC-SecureScore-Lab.ps1 -SubscriptionId '<pilot>' -PlanName 'VirtualMachines' -DesiredTier 'Standard' -Apply
    EXPECTED RESULTS
        In preview: a printed "would change plan X from <tier> to <tier>" and NO change. With -Apply:
        a confirmation prompt, then the single plan toggle on the pilot subscription.
.NOTES
    White-label. Preview-first. Enabling a Standard plan may incur cost — verify pricing first.
    Change approval belongs to the customer's cloud-ops/security functions.
#>
[CmdletBinding(SupportsShouldProcess = $true, ConfirmImpact = 'High')]
param(
    [string]$SubscriptionId,
    [string]$PlanName = 'VirtualMachines',      # e.g. VirtualMachines, StorageAccounts, Arm, KeyVaults
    [ValidateSet('Free','Standard')]
    [string]$DesiredTier = 'Standard',
    [switch]$Apply                               # must be set (plus confirmation) to actually change
)

$ErrorActionPreference = 'Continue'
foreach ($m in 'Az.Accounts','Az.Security') {
    if (-not (Get-Module -ListAvailable -Name $m)) {
        Write-Host "Installing Az modules (one-time)..." -ForegroundColor Yellow
        Install-Module Az -Scope CurrentUser -Force -AllowClobber; break
    }
}
Import-Module Az.Accounts -ErrorAction Stop
Import-Module Az.Security -ErrorAction Stop

if (-not (Get-AzContext)) { Connect-AzAccount | Out-Null }
if ($SubscriptionId) { Set-AzContext -SubscriptionId $SubscriptionId | Out-Null }
$ctx = Get-AzContext

Write-Host "`n=== Secure Score Lab (Lab 5) — plan-enable rehearsal (PREVIEW-FIRST) ===" -ForegroundColor Cyan
Write-Host ("Subscription: {0} ({1})" -f $ctx.Subscription.Name, $ctx.Subscription.Id)

$current = $null
try { $current = Get-AzSecurityPricing -Name $PlanName -ErrorAction Stop } catch {
    Write-Host "  Could not read plan '$PlanName': $($_.Exception.Message)" -ForegroundColor Yellow
    Write-Host "  Valid names include: VirtualMachines, StorageAccounts, Arm, KeyVaults, SqlServers, Containers, AppServices, Dns, Api." -ForegroundColor Yellow
    return
}
Write-Host ("Current tier for '{0}': {1}" -f $PlanName, $current.PricingTier) -ForegroundColor Cyan

if ($current.PricingTier -eq $DesiredTier) {
    Write-Host ("No change needed — '{0}' is already {1}." -f $PlanName, $DesiredTier) -ForegroundColor Green
    return
}

# Preview-first gate: only change when -Apply AND ShouldProcess confirmation both pass.
$action = "Set Defender plan '$PlanName' from '$($current.PricingTier)' to '$DesiredTier' on $($ctx.Subscription.Name)"
if (-not $Apply) {
    Write-Host "`n[PREVIEW] WOULD $action" -ForegroundColor Yellow
    Write-Host "[PREVIEW] No change made. Re-run with -Apply (and confirm) to enable — pilot only, cost-verified, approval-gated." -ForegroundColor Yellow
    return
}

if ($PSCmdlet.ShouldProcess($ctx.Subscription.Name, $action)) {
    Write-Host "  Enabling a Standard plan may incur cost. Proceeding under explicit -Apply + confirmation." -ForegroundColor Yellow
    try {
        Set-AzSecurityPricing -Name $PlanName -PricingTier $DesiredTier -ErrorAction Stop | Out-Null
        Write-Host ("  Done: '{0}' set to {1} on the PILOT subscription." -f $PlanName, $DesiredTier) -ForegroundColor Green
        Write-Host "  ROLLBACK: re-run with -DesiredTier 'Free' -Apply to revert." -ForegroundColor Cyan
    } catch { Write-Host "  Change failed: $($_.Exception.Message)" -ForegroundColor Red }
} else {
    Write-Host "  Confirmation declined — no change made." -ForegroundColor Yellow
}
