<#
.SYNOPSIS
    AZSECG-Set-ScopeTargeting.ps1 — Tag/move a subscription into a governance stage on Azure Government (GCC High). Defaults to preview.
.DESCRIPTION
    PURPOSE
        Assigns the governance-stage tag (pilot/expand) to a subscription and, optionally, moves it
        under the Landing Zones management group so the baseline policy and RBAC apply by inheritance.
        Defaults to preview mode (-WhatIf); nothing changes until you pass -Apply. Provide
        'your-subscription-id' and the target stage.
    HOW TO RUN
        Preview (default, no changes):
            powershell -ExecutionPolicy Bypass -File .\AZSECG-Set-ScopeTargeting.ps1 -SubscriptionId your-subscription-id -Stage pilot
        Commit:
            powershell -ExecutionPolicy Bypass -File .\AZSECG-Set-ScopeTargeting.ps1 -SubscriptionId your-subscription-id -Stage pilot -Apply

        Required modules: Az.Accounts, Az.Resources.
        Connects with Connect-AzAccount -Environment AzureUSGovernment (fails fast if not US Gov).
    EXPECTED RESULTS
        Preview: prints the tag and MG move that WOULD be applied. Apply: sets the tag and (if
        -TargetManagementGroup given) moves the subscription. PASS = tag set / move completed.
.NOTES
    White-label — the repeatable way. Read-only against Azure/Graph US Gov endpoints unless -Apply is passed.
#>

[CmdletBinding(SupportsShouldProcess = $true, ConfirmImpact = 'High')]
param(
    [Parameter(Mandatory = $true)]
    [string]$SubscriptionId,

    [Parameter(Mandatory = $true)]
    [ValidateSet('pilot','expand')]
    [string]$Stage,

    [string]$TargetManagementGroup = 'Landing Zones MG',

    [string]$TagName = 'governance-stage',

    [switch]$Apply
)

$ErrorActionPreference = 'Stop'

# Connect / guard
$ctx = Get-AzContext -ErrorAction SilentlyContinue
if (-not $ctx -or $ctx.Environment.Name -ne 'AzureUSGovernment') {
    Connect-AzAccount -Environment AzureUSGovernment | Out-Null
    $ctx = Get-AzContext
}
if ($ctx.Environment.Name -ne 'AzureUSGovernment') {
    throw "Wrong cloud: '$($ctx.Environment.Name)'. Run Connect-AzAccount -Environment AzureUSGovernment."
}
Write-Host "Cloud OK: $($ctx.Environment.Name)" -ForegroundColor Green

if (-not $Apply) {
    Write-Host "PREVIEW MODE (-WhatIf). No changes will be made. Re-run with -Apply to commit." -ForegroundColor Yellow
}

$subScope = "/subscriptions/$SubscriptionId"

# 1) Tag the subscription
Write-Host "`nSubscription: $SubscriptionId" -ForegroundColor Cyan
Write-Host ("  Tag to set: {0} = {1}" -f $TagName, $Stage)
if ($Apply) {
    if ($PSCmdlet.ShouldProcess($SubscriptionId, "Set tag $TagName=$Stage")) {
        try {
            $existing = (Get-AzTag -ResourceId $subScope -ErrorAction SilentlyContinue).Properties.TagsProperty
            $tags = @{}
            if ($existing) { $existing.GetEnumerator() | ForEach-Object { $tags[$_.Key] = $_.Value } }
            $tags[$TagName] = $Stage
            Update-AzTag -ResourceId $subScope -Tag $tags -Operation Merge | Out-Null
            Write-Host "  Tag applied." -ForegroundColor Green
        } catch {
            Write-Warning "  Could not set tag: $($_.Exception.Message)"
        }
    }
} else {
    Write-Host "  WOULD set tag $TagName=$Stage on the subscription (preview)." -ForegroundColor Yellow
}

# 2) Move subscription under the target management group (inheritance)
if ($TargetManagementGroup) {
    Write-Host ("  Target management group: {0}" -f $TargetManagementGroup)
    if ($Apply) {
        if ($PSCmdlet.ShouldProcess($SubscriptionId, "Move under management group '$TargetManagementGroup'")) {
            try {
                $mg = Get-AzManagementGroup | Where-Object { $_.DisplayName -eq $TargetManagementGroup -or $_.Name -eq $TargetManagementGroup } | Select-Object -First 1
                if (-not $mg) { throw "Management group '$TargetManagementGroup' not found. Create it per the Implementation Guide first." }
                New-AzManagementGroupSubscription -GroupName $mg.Name -SubscriptionId $SubscriptionId -ErrorAction Stop | Out-Null
                Write-Host "  Subscription moved under $($mg.DisplayName)." -ForegroundColor Green
            } catch {
                Write-Warning "  Could not move subscription: $($_.Exception.Message)"
            }
        }
    } else {
        Write-Host "  WOULD move the subscription under '$TargetManagementGroup' (preview)." -ForegroundColor Yellow
    }
}

Write-Host "`nDone. $(if($Apply){'Scope targeting applied.'}else{'Preview only — re-run with -Apply to commit.'})" -ForegroundColor Green
