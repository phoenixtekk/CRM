<#
.SYNOPSIS
  Create a recurring Entra access review of guests with auto-remove (expiration) - dry-run by default.
.DESCRIPTION
  Creates an accessReviewScheduleDefinition ("Guest Access Review - Recert - Pilot") scoped to guest
  members of a group, recurring on the chosen cadence, with auto-apply that REMOVES access when a guest
  is not approved - the expiration mechanism. Without -Commit it previews the definition. Reports
  existing reviews with -List. Requires Microsoft Entra ID Governance / Entra ID P2 (verified at runtime).
.EXAMPLE
  .\New-GuestAccessReview.ps1 -GroupId <guid> -RecurrenceType quarterly -AutoApplyRemove -WhatIf   # dry-run
  .\New-GuestAccessReview.ps1 -GroupId <guid> -RecurrenceType quarterly -AutoApplyRemove -Commit
  (PowerShell 5.1+/7+, Microsoft.Graph.Identity.Governance; connect with Connect-MgGraph)
.NOTES
  Expected results: a preview of the review definition, or (with -Commit) an active recurring review that
  auto-removes unapproved guests. If access reviews are unavailable, the script reports "verify Entra ID
  Governance/P2 licensing in your tenant" and makes no changes.
#>

[CmdletBinding(SupportsShouldProcess = $true, ConfirmImpact = 'High')]
param(
    [Parameter(Mandatory = $true, ParameterSetName = 'Create')]
    [string]$GroupId,
    [string]$ReviewName = "Guest Access Review - Recert - Pilot",
    [ValidateSet('weekly','monthly','quarterly','halfyearly','annual')]
    [string]$RecurrenceType = 'quarterly',
    [int]$DurationInDays = 14,
    [switch]$AutoApplyRemove,
    [Parameter(ParameterSetName = 'List')]
    [switch]$List,
    [switch]$Commit
)

$ErrorActionPreference = 'Stop'
if (-not (Get-MgContext)) { Connect-MgGraph -Scopes "AccessReview.ReadWrite.All" | Out-Null }

# Verify the capability is present (licensing-dependent)
try { Get-MgIdentityGovernanceAccessReviewDefinition -Top 1 -ErrorAction Stop | Out-Null }
catch {
    Write-Warning "Access reviews unavailable - verify Microsoft Entra ID Governance / Entra ID P2 licensing and permissions in your tenant. No changes made."
    return
}

if ($List) {
    Get-MgIdentityGovernanceAccessReviewDefinition -All |
        Select-Object Id, DisplayName, Status, @{n='Recurrence';e={$_.Settings.Recurrence.Pattern.Type}}
    return
}

$start = (Get-Date).ToUniversalTime()
$body = @{
    displayName    = $ReviewName
    descriptionForAdmins = "Recurring recertification of guest members; unapproved guests are removed."
    scope = @{
        "@odata.type" = "#microsoft.graph.accessReviewQueryScope"
        query     = "/groups/$GroupId/members/microsoft.graph.user/?`$filter=(userType eq 'Guest')"
        queryType = "MicrosoftGraph"
    }
    reviewers = @( @{ query = "/groups/$GroupId/owners"; queryType = "MicrosoftGraph" } )
    settings = @{
        mailNotificationsEnabled       = $true
        reminderNotificationsEnabled   = $true
        defaultDecisionEnabled         = $true
        defaultDecision                = if ($AutoApplyRemove) { "Deny" } else { "None" }
        autoApplyDecisionsEnabled      = [bool]$AutoApplyRemove
        instanceDurationInDays         = $DurationInDays
        recurrence = @{
            pattern = @{ type = $RecurrenceType; interval = 1 }
            range   = @{ type = "noEnd"; startDate = $start.ToString('yyyy-MM-dd') }
        }
    }
}

if ($Commit -and $PSCmdlet.ShouldProcess($ReviewName, "create recurring guest access review (auto-remove=$AutoApplyRemove)")) {
    $def = New-MgIdentityGovernanceAccessReviewDefinition -BodyParameter $body
    Write-Host "[APPLIED] Access review '$ReviewName' created (Id: $($def.Id)); recurrence=$RecurrenceType, autoRemove=$AutoApplyRemove." -ForegroundColor Green
} else {
    Write-Host "[WHATIF] Would create access review '$ReviewName': scope=Guests of $GroupId, recurrence=$RecurrenceType, autoRemove=$AutoApplyRemove." -ForegroundColor Yellow
    Write-Host "Re-run with -Commit to create it." -ForegroundColor Cyan
}
