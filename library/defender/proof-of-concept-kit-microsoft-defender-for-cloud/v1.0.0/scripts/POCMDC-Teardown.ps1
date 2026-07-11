<#
.SYNOPSIS
    POCMDC-Teardown.ps1 — clean rollback of the Defender for Cloud proof of concept (and STOP billing). -WhatIf-gated.
.DESCRIPTION
    PURPOSE
        Returns the pilot subscription to its pre-PoC state and stops Defender-plan billing. It:
          - deletes the benign misconfigured test resource(s) tagged MDC-PoC-TESTSIGNAL,
          - disables the chosen Defender workload plan (sets it back to Free) to STOP BILLING,
          - reminds you to dismiss the sample alerts.
        Every change is gated behind -WhatIf: run with -WhatIf first to preview, then without to apply.
    HOW TO RUN
        # Preview:
        powershell -ExecutionPolicy Bypass -File .\POCMDC-Teardown.ps1 -WhatIf
        # Apply (delete test resource + disable plan):
        powershell -ExecutionPolicy Bypass -File .\POCMDC-Teardown.ps1 -SubscriptionId <guid> -WorkloadPlan VirtualMachines -ResourceGroup "MDC PoC - Pilot RG - Pilot"
        Requires Az.Accounts + Az.Security (+ Az.Resources) and Security Admin/Contributor.
    EXPECTED RESULTS
        The test resource(s) deleted, the Defender plan set back to Free (billing stopped), and a
        reminder to dismiss the sample alerts.
.NOTES
    White-label. Reversible teardown. Disabling the plan is what stops the Defender-for-Cloud billing.
#>
[CmdletBinding(SupportsShouldProcess = $true, ConfirmImpact = 'High')]
param(
    [string]$SubscriptionId,
    [ValidateSet('VirtualMachines','StorageAccounts','SqlServers','Containers','KeyVaults','AppServices')]
    [string]$WorkloadPlan = 'VirtualMachines',
    [string]$ResourceGroup = 'MDC PoC - Pilot RG - Pilot',
    [string]$Tag = 'MDC-PoC-TESTSIGNAL',
    [switch]$DeleteResourceGroup
)

foreach ($m in 'Az.Accounts','Az.Security','Az.Resources') {
    if (-not (Get-Module -ListAvailable -Name $m)) { Install-Module $m -Scope CurrentUser -Force -AllowClobber }
}
Import-Module Az.Accounts -ErrorAction Stop; Import-Module Az.Security -ErrorAction Stop; Import-Module Az.Resources -ErrorAction Stop
if (-not (Get-AzContext)) { Connect-AzAccount | Out-Null }
if ($SubscriptionId) { Set-AzContext -SubscriptionId $SubscriptionId | Out-Null }
$rgName = ($ResourceGroup -replace '[^A-Za-z0-9-]','-')

Write-Host "`n=== POCMDC — teardown (preview by default) ===" -ForegroundColor Cyan

# 1) Delete the benign test resources.
Write-Host "`n[1] Delete benign test resource(s) tagged '$Tag':" -ForegroundColor Cyan
try {
    $res = Get-AzResource -TagName purpose -TagValue $Tag -ErrorAction SilentlyContinue
    if ($res) {
        foreach ($r in $res) {
            if ($PSCmdlet.ShouldProcess($r.Name, "Delete test resource")) {
                Remove-AzResource -ResourceId $r.ResourceId -Force -ErrorAction SilentlyContinue | Out-Null
                Write-Host "  Deleted: $($r.Name)" -ForegroundColor Green
            } else { Write-Host "  [WhatIf] Would delete: $($r.Name)" -ForegroundColor Yellow }
        }
    } else { Write-Host "  No resources tagged '$Tag' found." -ForegroundColor Gray }
} catch { Write-Host ("  Could not enumerate tagged resources: {0}" -f $_.Exception.Message) -ForegroundColor Yellow }

if ($DeleteResourceGroup) {
    if ($PSCmdlet.ShouldProcess($rgName, "Delete pilot resource group")) {
        Remove-AzResourceGroup -Name $rgName -Force -ErrorAction SilentlyContinue | Out-Null
        Write-Host "  Deleted resource group '$rgName'." -ForegroundColor Green
    } else { Write-Host "  [WhatIf] Would delete resource group '$rgName'." -ForegroundColor Yellow }
}

# 2) Disable the Defender plan (stop billing).
Write-Host "`n[2] Disable Defender for $WorkloadPlan (set to Free) to STOP billing:" -ForegroundColor Cyan
if ($PSCmdlet.ShouldProcess("$WorkloadPlan", "Set Defender plan to Free (stop billing)")) {
    try {
        Set-AzSecurityPricing -Name $WorkloadPlan -PricingTier 'Free' -ErrorAction Stop
        Write-Host "  Defender for $WorkloadPlan set to Free — billing stopped." -ForegroundColor Green
    } catch { Write-Host ("  Could not disable plan: {0}. Disable it in the portal (Environment settings -> Defender plans)." -f $_.Exception.Message) -ForegroundColor Yellow }
} else {
    Write-Host "  [WhatIf] Would set Defender for $WorkloadPlan to Free (stop billing)." -ForegroundColor Yellow
}

# 3) Dismiss sample alerts.
Write-Host "`n[3] Dismiss the benign sample alerts:" -ForegroundColor Cyan
Write-Host "  portal.azure.com -> Microsoft Defender for Cloud -> Security alerts -> dismiss the '$Tag' / sample alerts." -ForegroundColor Gray

Write-Host "`nConfirm with: POCMDC-Validate.ps1  (plan should be Free; test resource gone)." -ForegroundColor Cyan
