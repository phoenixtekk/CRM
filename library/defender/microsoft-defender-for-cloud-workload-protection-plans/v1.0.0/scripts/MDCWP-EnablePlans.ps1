<#
.SYNOPSIS
    MDCWP-EnablePlans.ps1 — enable Defender for Cloud workload protection plans on a subscription.
    SAFE PREVIEW by default (-WhatIf); plans are enabled (paid) only when confirmed with -Apply.
.DESCRIPTION
    PURPOSE
        Change helper for the "Microsoft Defender for Cloud — Workload Protection Plans" solution.
        Sets the named Defender plans to the 'Standard' (paid, protected) tier on the pilot
        subscription 'MDC Workload Plans - Pilot Subscription - Pilot'. This is the only script that
        can change configuration, it INCURS COST, and it defaults to a safe preview.
    HOW TO RUN
        # Preview (default — shows what WOULD be enabled, changes nothing, no cost):
        powershell -ExecutionPolicy Bypass -File .\MDCWP-EnablePlans.ps1 -SubscriptionId <pilot> `
            -Plans VirtualMachines,Containers,StorageAccounts,SqlServers
        # Apply (explicit — enables paid plans):
        powershell -ExecutionPolicy Bypass -File .\MDCWP-EnablePlans.ps1 -SubscriptionId <pilot> `
            -Plans VirtualMachines,Containers,StorageAccounts,SqlServers -Apply
        Requires Az.Accounts, Az.Security and Security Admin/Owner on the subscription.
        Plan names: VirtualMachines, Containers, SqlServers, OpenSourceRelationalDatabases,
        CosmosDbs, StorageAccounts, KeyVaults, AppServices, Arm.
    EXPECTED RESULTS
        Preview: lists the plans that WOULD move to Standard (paid) and reminds you of cost.
        Apply: sets each named plan to Standard on the subscription. Validate with MDCWP-Validate.ps1.
.NOTES
    White-label. DEFAULTS TO -WhatIf/preview. ENABLING PLANS INCURS COST (per protected resource).
    Get cost approval first; pilot subscription only; expand deliberately. Verify current pricing/tier.
#>
[CmdletBinding()]
param(
    [Parameter(Mandatory)] [string]$SubscriptionId,
    [Parameter(Mandatory)] [string[]]$Plans,
    [switch]$Apply
)

Import-Module Az.Accounts -ErrorAction Stop
if (-not (Get-AzContext)) { Connect-AzAccount | Out-Null }
Set-AzContext -SubscriptionId $SubscriptionId | Out-Null
Import-Module Az.Security -ErrorAction Stop

$whatIf = -not $Apply
Write-Host "`n=== MDCWP enable workload plans on $SubscriptionId ===" -ForegroundColor Cyan
Write-Host ("Mode: {0}" -f ($(if ($whatIf) { 'PREVIEW (-WhatIf) — no changes, no cost' } else { 'APPLY — enables PAID plans (incurs cost)' }))) -ForegroundColor $(if ($whatIf) { 'Yellow' } else { 'Red' })
Write-Host "Plans requested:" -ForegroundColor Cyan
$Plans | ForEach-Object { Write-Host ("   {0} -> Standard (paid)" -f $_) }

Write-Host "`nPRE-FLIGHT: confirm cost approval for the pilot scope (MDCWP-Report.ps1 -Section Cost). Verify current pricing/tier." -ForegroundColor Yellow

if ($whatIf) {
    Write-Host "`nWOULD set the above plans to 'Standard' on $SubscriptionId. Re-run with -Apply to enable (incurs cost)." -ForegroundColor Yellow
    return
}

foreach ($p in $Plans) {
    try {
        Set-AzSecurityPricing -Name $p -PricingTier 'Standard' -ErrorAction Stop | Out-Null
        Write-Host ("   ENABLED: {0} -> Standard" -f $p) -ForegroundColor Green
    } catch {
        Write-Host ("   Failed to enable {0}: {1}" -f $p, $_.Exception.Message) -ForegroundColor Red
        Write-Host ("   Set it in the portal: Defender for Cloud > Environment settings > [sub] > Defender plans." -f $p) -ForegroundColor DarkGray
    }
}
Write-Host "`nApply complete. Validate with MDCWP-Validate.ps1 -SubscriptionId $SubscriptionId -Plan All. Watch cost in Cost Management." -ForegroundColor Green
