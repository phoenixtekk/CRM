<#
.SYNOPSIS
    AZSECG-Remediation.ps1 — Safely bring resources into policy compliance on Azure Government (GCC High). Defaults to preview.
.DESCRIPTION
    PURPOSE
        Triggers Azure Policy remediation tasks for deployIfNotExists/modify policies within the
        security-baseline initiative on an Azure Government subscription, so non-compliant resources
        are brought into line. Defaults to preview mode (-WhatIf); nothing changes until you pass
        -Apply. Provide 'your-subscription-id'. Never enables Gov-unavailable Defender plans.
    HOW TO RUN
        Preview (default, no changes):
            powershell -ExecutionPolicy Bypass -File .\AZSECG-Remediation.ps1 -SubscriptionId your-subscription-id
        Commit changes:
            powershell -ExecutionPolicy Bypass -File .\AZSECG-Remediation.ps1 -SubscriptionId your-subscription-id -Apply

        Required modules: Az.Accounts, Az.Resources, Az.PolicyInsights.
        Connects with Connect-AzAccount -Environment AzureUSGovernment (fails fast if not US Gov).
    EXPECTED RESULTS
        Preview: lists the policy assignments and non-compliant resources that WOULD be remediated.
        Apply: creates remediation tasks and prints their ids. PASS = tasks created without error.
.NOTES
    White-label — the repeatable way. Read-only against Azure/Graph US Gov endpoints unless -Apply is passed.
#>

[CmdletBinding(SupportsShouldProcess = $true, ConfirmImpact = 'High')]
param(
    [Parameter(Mandatory = $true)]
    [string]$SubscriptionId,

    [string]$InitiativeName = 'Security Baseline Initiative – Governance Root – Pilot',

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
Set-AzContext -SubscriptionId $SubscriptionId | Out-Null
Write-Host "Cloud OK: $($ctx.Environment.Name)" -ForegroundColor Green

if (-not $Apply) {
    Write-Host "PREVIEW MODE (-WhatIf). No changes will be made. Re-run with -Apply to commit." -ForegroundColor Yellow
}

# Find candidate assignments (the baseline initiative and any deployIfNotExists/modify assignments)
$assignments = Get-AzPolicyAssignment -Scope "/subscriptions/$SubscriptionId" |
    Where-Object { $_.Name -eq $InitiativeName -or $_.Properties.DisplayName -eq $InitiativeName -or $_.Properties.DisplayName -like '*Baseline*' }

if (-not $assignments) {
    Write-Warning "No matching policy assignment found for '$InitiativeName' at this scope. Nothing to remediate."
    return
}

foreach ($a in $assignments) {
    $name = if ($a.Properties.DisplayName) { $a.Properties.DisplayName } else { $a.Name }
    Write-Host "`nAssignment: $name" -ForegroundColor Cyan

    # Show non-compliant resources for evidence
    try {
        $states = Get-AzPolicyState -SubscriptionId $SubscriptionId -Filter "PolicyAssignmentName eq '$($a.Name)' and ComplianceState eq 'NonCompliant'" -Top 50 -ErrorAction Stop
        $count = @($states).Count
        Write-Host ("  Non-compliant resources (sample up to 50): {0}" -f $count)
        $states | Select-Object -First 10 ResourceId, PolicyDefinitionName | Format-Table -AutoSize
    } catch {
        Write-Warning "  Could not read policy states (Az.PolicyInsights): $($_.Exception.Message)"
    }

    $remediationName = ("azsecg-remediation-{0:yyyyMMddHHmmss}" -f (Get-Date))
    if ($Apply) {
        if ($PSCmdlet.ShouldProcess($name, "Create policy remediation task '$remediationName'")) {
            try {
                $task = Start-AzPolicyRemediation -Name $remediationName -PolicyAssignmentId $a.PolicyAssignmentId -ErrorAction Stop
                Write-Host "  Remediation task created: $($task.Name) (state: $($task.ProvisioningState))" -ForegroundColor Green
            } catch {
                Write-Warning "  Remediation task not created (assignment may be audit-only, no DINE/modify policies): $($_.Exception.Message)"
            }
        }
    } else {
        Write-Host "  WOULD create remediation task '$remediationName' for this assignment (preview)." -ForegroundColor Yellow
    }
}

Write-Host "`nDone. $(if($Apply){'Remediation tasks submitted.'}else{'Preview only — re-run with -Apply to commit.'})" -ForegroundColor Green
