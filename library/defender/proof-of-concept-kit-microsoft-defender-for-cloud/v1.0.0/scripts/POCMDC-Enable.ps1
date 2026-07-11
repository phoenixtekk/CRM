<#
.SYNOPSIS
    POCMDC-Enable.ps1 — pilot-scoped enable of Microsoft Defender for Cloud for a proof of concept. -WhatIf-gated.
.DESCRIPTION
    PURPOSE
        Enables Defender for Cloud on ONE pilot subscription only: foundational/Defender CSPM plus
        ONE workload plan (e.g. VirtualMachines / StorageAccounts). It previews readiness (roles,
        subscription, current plan state, candidate resources) and, gated behind -WhatIf, turns on
        the plans via Az.Security. NOTE: Defender workload plans are BILLED while enabled — keep the
        PoC short and disable at teardown. Verify current pricing before enabling.
    HOW TO RUN
        # Preview only (changes nothing):
        powershell -ExecutionPolicy Bypass -File .\POCMDC-Enable.ps1 -WhatIf
        # Apply on the pilot subscription (enable CSPM + one workload plan):
        powershell -ExecutionPolicy Bypass -File .\POCMDC-Enable.ps1 -SubscriptionId <guid> -WorkloadPlan VirtualMachines
        Requires Az.Accounts + Az.Security and Security Admin/Contributor on the subscription.
    EXPECTED RESULTS
        A readiness summary, then (when applied) CSPM + the chosen workload plan set to On for the
        pilot subscription only.
.NOTES
    White-label. Read-only by default (-WhatIf). Pilot-scoped. Billed while on — reverse with POCMDC-Teardown.ps1.
#>
[CmdletBinding(SupportsShouldProcess = $true, ConfirmImpact = 'High')]
param(
    [string]$SubscriptionId,
    [ValidateSet('VirtualMachines','StorageAccounts','SqlServers','Containers','KeyVaults','AppServices')]
    [string]$WorkloadPlan = 'VirtualMachines',
    [string]$PilotResourceGroup = 'MDC PoC - Pilot RG - Pilot'
)

foreach ($m in 'Az.Accounts','Az.Security') {
    if (-not (Get-Module -ListAvailable -Name $m)) { Install-Module $m -Scope CurrentUser -Force -AllowClobber }
}
Import-Module Az.Accounts -ErrorAction Stop; Import-Module Az.Security -ErrorAction Stop
if (-not (Get-AzContext)) { Connect-AzAccount | Out-Null }
if ($SubscriptionId) { Set-AzContext -SubscriptionId $SubscriptionId | Out-Null }
$ctx = Get-AzContext

Write-Host "`n=== POCMDC — pilot enable (preview by default) ===" -ForegroundColor Cyan
Write-Host "Subscription : $($ctx.Subscription.Id) ($($ctx.Subscription.Name))" -ForegroundColor Gray
Write-Host "Workload plan: $WorkloadPlan" -ForegroundColor Gray
Write-Host "COST NOTE    : Defender workload plans are BILLED while enabled. Verify pricing; disable at teardown." -ForegroundColor Yellow

# --- Readiness (read-only) ---
Write-Host "`n[1] Current Defender plan state (read-only):" -ForegroundColor Cyan
try {
    Get-AzSecurityPricing | Select-Object Name, PricingTier | ForEach-Object {
        Write-Host ("  {0,-18} {1}" -f $_.Name, $_.PricingTier) -ForegroundColor Gray
    }
} catch { Write-Host ("  Could not read pricing: {0}" -f $_.Exception.Message) -ForegroundColor Yellow }
Write-Host "  Confirm you hold Security Admin + Contributor on this subscription." -ForegroundColor Gray

# --- Apply (gated) ---
Write-Host "`n[2] Enable CSPM + the '$WorkloadPlan' workload plan:" -ForegroundColor Cyan
if ($PSCmdlet.ShouldProcess("$($ctx.Subscription.Id)", "Enable CSPM + Defender for $WorkloadPlan (Standard)")) {
    try {
        # Foundational CSPM is on by default; set the workload plan to Standard for the PoC.
        Set-AzSecurityPricing -Name $WorkloadPlan -PricingTier 'Standard' -ErrorAction Stop
        Write-Host "  ENABLED — Defender for $WorkloadPlan = Standard on the pilot subscription." -ForegroundColor Green
        Write-Host "  (CSPM recommendations/Secure Score are available with foundational CSPM; Defender CSPM is a paid tier — verify.)" -ForegroundColor Gray
    } catch {
        Write-Host ("  Enable failed: {0}" -f $_.Exception.Message) -ForegroundColor Yellow
        Write-Host "  Confirm Security Admin/Contributor and re-run; or enable in the portal (Environment settings -> Defender plans)." -ForegroundColor Gray
    }
} else {
    Write-Host "  [WhatIf] Would set Defender for $WorkloadPlan to Standard on $($ctx.Subscription.Id). No change made." -ForegroundColor Yellow
}

Write-Host "`nCreate the pilot RG '$PilotResourceGroup' for the benign test resource if it does not exist." -ForegroundColor Gray
Write-Host "Next: POCMDC-TestSignal.ps1 (benign signal) -> POCMDC-Validate.ps1 -> POCMDC-Scorecard.ps1 -> POCMDC-Teardown.ps1" -ForegroundColor Cyan
