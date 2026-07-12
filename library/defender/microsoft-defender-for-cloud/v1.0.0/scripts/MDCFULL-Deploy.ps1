<#
.SYNOPSIS
    MDCFULL-Deploy.ps1 — the ONLY change script: enable Defender for Cloud plans at management-group scope
    (reference Bicep) and/or per subscription (Az.Security). SAFE PREVIEW by default; -WhatIf/cost-gated.
.DESCRIPTION
    PURPOSE
        The single configuration-changing helper for the "Microsoft Defender for Cloud" (complete) solution.
        Two modes, both PREVIEW-FIRST:
          MG scope (architecture):  -ManagementGroupId '<pilotMgId>' [-Wave 1]
                Wraps the reference main.bicep as a management-group deployment. DEFAULTS TO A WHAT-IF
                (New-AzManagementGroupDeployment -WhatIf) so you see exactly which plan enablements would
                happen before anything changes; -Apply performs the deployment.
          Subscription scope (workload plans):  -SubscriptionId '<guid>' -Plans Servers,StorageAccounts,...
                Previews (default) or, with -Apply, sets the named Defender plans to Standard on the
                subscription via Az.Security. PAID plans bill while On.
        Paid plans incur cost — never -Apply until the what-if/preview is reviewed and cost is approved.
    HOW TO RUN
        # Architecture (MG) — preview then apply:
        powershell -ExecutionPolicy Bypass -File .\MDCFULL-Deploy.ps1 -ManagementGroupId '<pilotMgId>' -Wave 1
        powershell -ExecutionPolicy Bypass -File .\MDCFULL-Deploy.ps1 -ManagementGroupId '<pilotMgId>' -Wave 1 -Apply
        # Workload plans (subscription) — preview then apply:
        powershell -ExecutionPolicy Bypass -File .\MDCFULL-Deploy.ps1 -SubscriptionId '<guid>' -Plans VirtualMachines,StorageAccounts
        powershell -ExecutionPolicy Bypass -File .\MDCFULL-Deploy.ps1 -SubscriptionId '<guid>' -Plans VirtualMachines,StorageAccounts -Apply
        Requires Az.Accounts, Az.Resources, Az.Security and Owner/Contributor+Security Admin at the scope.
    EXPECTED RESULTS
        Preview: prints the what-if (MG) or the plan changes that WOULD be made (subscription).
        Apply: deploys the Bicep / sets the plans to Standard. Validate with MDCFULL-Validate.ps1.
        Rollback: redeploy with plans=Free / enforcementMode DoNotEnforce (MG), or set plans back to Free
        (Set-AzSecurityPricing -PricingTier Free) / MDCFULL-PoC.ps1 -Action Teardown.
.NOTES
    White-label. DEFAULTS TO preview/what-if. PAID plans bill on Apply — verify current pricing and the
    built-in initiative id in your tenant. Pilot scope first; expand in waves. Cost is finance's decision.
#>
[CmdletBinding()]
param(
    [string]$ManagementGroupId,
    [int]$Wave = 1,
    [string]$Location = 'eastus',
    [string]$TemplateFile = ".\main.bicep",
    [string]$SubscriptionId,
    [ValidateSet('VirtualMachines','Containers','SqlServers','StorageAccounts','KeyVaults','AppServices','Arm','CloudPosture')]
    [string[]]$Plans,
    [switch]$Apply
)

foreach ($m in 'Az.Accounts','Az.Resources','Az.Security') {
    if (-not (Get-Module -ListAvailable -Name $m)) { Install-Module Az -Scope CurrentUser -Force -AllowClobber; break }
}
Import-Module Az.Accounts -ErrorAction Stop
if (-not (Get-AzContext)) { Connect-AzAccount | Out-Null }

$whatIf = -not $Apply
if (-not $ManagementGroupId -and -not $SubscriptionId) {
    Write-Host "Specify -ManagementGroupId (architecture/MG deploy) and/or -SubscriptionId -Plans (workload plans)." -ForegroundColor Red
    return
}

Write-Host "`n=== MDCFULL deploy/enable ===" -ForegroundColor Cyan
Write-Host ("Mode: {0}" -f ($(if ($whatIf) { 'PREVIEW (what-if) — no changes' } else { 'APPLY — changes config; PAID plans may bill' }))) -ForegroundColor $(if ($whatIf) { 'Yellow' } else { 'Red' })

# --- Architecture: MG-scope Bicep deployment ---
if ($ManagementGroupId) {
    Import-Module Az.Resources -ErrorAction Stop
    if (-not (Test-Path $TemplateFile)) { Write-Host ("Template not found: {0}" -f $TemplateFile) -ForegroundColor Red }
    else {
        Write-Host ("`n[MG] Management group: {0}   Wave: {1}" -f $ManagementGroupId, $Wave) -ForegroundColor Cyan
        $deployParams = @{
            ManagementGroupId       = $ManagementGroupId
            Location                = $Location
            TemplateFile            = $TemplateFile
            TemplateParameterObject = @{ wave = $Wave }
            Name                    = ("mdcfull-wave{0}-{1}" -f $Wave, (Get-Date -Format 'yyyyMMddHHmm'))
        }
        try {
            if ($whatIf) {
                Write-Host "Running what-if (this changes nothing)..." -ForegroundColor Yellow
                New-AzManagementGroupDeployment @deployParams -WhatIf
                Write-Host "Review the predicted changes above. When approved, re-run with -Apply." -ForegroundColor Yellow
            } else {
                Write-Host "Deploying..." -ForegroundColor Red
                $d = New-AzManagementGroupDeployment @deployParams
                Write-Host ("APPLIED — provisioning state: {0}. Validate: MDCFULL-Validate.ps1 -Plan Inherit." -f $d.ProvisioningState) -ForegroundColor Green
                Write-Host "Rollback: redeploy with plans=Free / enforcementMode=DoNotEnforce, or remove the policy assignment." -ForegroundColor DarkGray
            }
        } catch {
            Write-Host ("MG deployment call failed: {0}" -f $_.Exception.Message) -ForegroundColor Red
            Write-Host "Confirm MG-scope rights, the built-in initiative id in main.bicep, and current plan availability." -ForegroundColor Yellow
        }
    }
}

# --- Workload plans: subscription-scope Az.Security ---
if ($SubscriptionId -and $Plans) {
    Import-Module Az.Security -ErrorAction Stop
    Set-AzContext -SubscriptionId $SubscriptionId | Out-Null
    Write-Host ("`n[SUB] Subscription: {0}   Plans: {1}" -f $SubscriptionId, ($Plans -join ', ')) -ForegroundColor Cyan
    foreach ($plan in $Plans) {
        if ($whatIf) {
            Write-Host ("   [WhatIf] Would set Defender for {0} to Standard (PAID). No change made." -f $plan) -ForegroundColor Yellow
        } else {
            try {
                Set-AzSecurityPricing -Name $plan -PricingTier 'Standard' -ErrorAction Stop
                Write-Host ("   Enabled Defender for {0} (Standard). Billing starts while On." -f $plan) -ForegroundColor Green
            } catch {
                Write-Host ("   Could not enable {0}: {1}. Confirm role + provider + plan availability." -f $plan, $_.Exception.Message) -ForegroundColor Yellow
            }
        }
    }
    if (-not $whatIf) { Write-Host "   Validate: MDCFULL-Validate.ps1 -Plan All -SubscriptionId '$SubscriptionId'" -ForegroundColor Green }
    else { Write-Host "   Review above; re-run with -Apply once cost is approved." -ForegroundColor Yellow }
}
elseif ($SubscriptionId -and -not $Plans) {
    Write-Host "`n[SUB] -SubscriptionId given without -Plans; nothing to enable. Pass -Plans VirtualMachines,StorageAccounts,..." -ForegroundColor Yellow
}
