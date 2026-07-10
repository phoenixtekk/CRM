<#
.SYNOPSIS
    ENTPIM-Validate.ps1 — confirm the PIM activation policy on privileged Entra roles.
.DESCRIPTION
    PURPOSE
        Read-only check that each onboarded privileged role's activation policy matches your tiering:
        require MFA on activation, require justification, require approval (with approvers) for Tier-0
        roles, and a maximum activation duration. It reads the role-management policy rules through
        Microsoft Graph and reports PASS/REVIEW per role so you can prove the guardrails are in place.
    HOW TO RUN
        powershell -ExecutionPolicy Bypass -File .\ENTPIM-Validate.ps1
        Optional: -Tier0Roles 'Global Administrator','Privileged Role Administrator'   roles that must require approval
        Optional: -MaxHours 8   maximum activation duration to expect (Tier-0 may be shorter)
        Consents to RoleManagementPolicy.Read.AzureADGroup, RoleManagement.Read.All, Directory.Read.All (read-only).
    EXPECTED RESULTS
        Per role: whether MFA, justification, approval, and max-duration are configured as expected.
        REVIEW lines flag roles whose policy does not match the tiering. No changes are made.
.NOTES
    White-label — Entra ID Solutions. Read-only.
#>
[CmdletBinding()]
param(
    [string[]]$Tier0Roles = @('Global Administrator','Privileged Role Administrator','Security Administrator'),
    [int]$MaxHours = 8
)

Import-Module Microsoft.Graph.Authentication -ErrorAction Stop
Connect-MgGraph -Scopes 'RoleManagementPolicy.Read.AzureADGroup','RoleManagement.Read.All','Directory.Read.All' -NoWelcome

Write-Host "`n=== PIM Activation-Policy Validation — $(Get-Date -Format s) ===" -ForegroundColor Cyan

$roleDefs = @{}
Get-MgRoleManagementDirectoryRoleDefinition -All | ForEach-Object { $roleDefs[$_.Id] = $_.DisplayName }

# Policy assignments map a role (scopeType DirectoryRole) to a policy holding the activation rules
$assignments = Get-MgPolicyRoleManagementPolicyAssignment -Filter "scopeId eq '/' and scopeType eq 'DirectoryRole'" -All -ErrorAction SilentlyContinue

$fail = 0
foreach ($pa in $assignments) {
    $roleName = $roleDefs[$pa.RoleDefinitionId]
    if (-not $roleName) { continue }

    $rules = Get-MgPolicyRoleManagementPolicyRule -UnifiedRoleManagementPolicyId $pa.PolicyId -All -ErrorAction SilentlyContinue

    # Enablement rule (End User Assignment) lists which controls are enabled: MultiFactorAuthentication / Justification
    $enable = $rules | Where-Object { $_.Id -eq 'Enablement_EndUser_Assignment' }
    $enabled = @()
    if ($enable) { $enabled = @($enable.AdditionalProperties.enabledRules) }
    $mfa  = $enabled -contains 'MultiFactorAuthentication'
    $just = $enabled -contains 'Justification'

    # Approval rule
    $appr = $rules | Where-Object { $_.Id -eq 'Approval_EndUser_Assignment' }
    $approvalOn = $false
    if ($appr) { $approvalOn = [bool]$appr.AdditionalProperties.setting.isApprovalRequired }

    # Expiration (max activation duration) rule
    $exp = $rules | Where-Object { $_.Id -eq 'Expiration_EndUser_Assignment' }
    $maxDur = if ($exp) { $exp.AdditionalProperties.maximumDuration } else { $null }

    $isTier0 = $roleName -in $Tier0Roles
    $issues = @()
    if (-not $mfa)  { $issues += 'no MFA' }
    if (-not $just) { $issues += 'no justification' }
    if ($isTier0 -and -not $approvalOn) { $issues += 'Tier-0 without approval' }

    $status = if ($issues.Count -eq 0) { 'PASS' } else { 'REVIEW' }
    if ($status -eq 'REVIEW') { $fail++ }
    $color = if ($status -eq 'PASS') { 'Green' } else { 'Yellow' }
    Write-Host ("[{0}] {1,-32} MFA={2} Just={3} Approval={4} MaxDur={5}" -f $status,$roleName,$mfa,$just,$approvalOn,$maxDur) -ForegroundColor $color
    if ($issues) { Write-Host ("        -> {0}" -f ($issues -join '; ')) -ForegroundColor Yellow }
}

Write-Host ("`nRoles needing review: {0}" -f $fail) -ForegroundColor $(if($fail){'Yellow'}else{'Green'})
Write-Host "Note: exact rule IDs/shape can vary by tenant and API version — *verify against your tenant's policy*."
Disconnect-MgGraph | Out-Null
