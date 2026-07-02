<#
.SYNOPSIS
    INTCOMPDX-Set-ScopeTargeting.ps1 — build/adjust pilot or target group membership for staged remediation, preview-first (-WhatIf).
.DESCRIPTION
    PURPOSE
        Moves affected device(s) or user(s) into the correct pilot/target Entra security
        group so a compliance fix or grace change can be staged before the fleet. Defaults
        to -WhatIf so it only previews the membership change; re-run with -WhatIf:$false to
        commit. Never disables a policy or widens fleet targeting. Replace the sample values
        your-group-name / your-object-id.
    HOW TO RUN
        powershell -ExecutionPolicy Bypass -File .\INTCOMPDX-Set-ScopeTargeting.ps1 -GroupName your-group-name -MemberObjectId your-object-id
        (preview only; add -WhatIf:$false to commit)

        Required Graph scopes:
            Group.ReadWrite.All
            GroupMember.ReadWrite.All
    EXPECTED RESULTS
        A preview of the group membership change (add/remove) or a confirmation when
        committed. Pass = the previewed assignment matches the intended pilot scope before
        you commit.
.NOTES
    White-label — the repeatable way. Read-only against Microsoft Graph unless -WhatIf:$false is set.
#>

[CmdletBinding(SupportsShouldProcess = $true, ConfirmImpact = 'High')]
param(
    [Parameter(Mandatory)][string]$GroupName,
    [Parameter(Mandatory)][string]$MemberObjectId,
    [ValidateSet('Add', 'Remove')][string]$Action = 'Add',
    [switch]$WhatIf = $true
)

$ErrorActionPreference = 'Stop'
if ($WhatIf) { $WhatIfPreference = $true }

function Connect-Graph {
    $scopes = @('Group.ReadWrite.All', 'GroupMember.ReadWrite.All')
    if (-not (Get-Module -ListAvailable -Name Microsoft.Graph.Authentication)) {
        throw "Microsoft Graph PowerShell SDK not found. Run: Install-Module Microsoft.Graph -Scope CurrentUser"
    }
    Import-Module Microsoft.Graph.Authentication -ErrorAction Stop
    $ctx = Get-MgContext
    if (-not $ctx -or -not ($scopes | Where-Object { $ctx.Scopes -contains $_ })) {
        Connect-MgGraph -Scopes $scopes | Out-Null
    }
    Write-Host "Connected to tenant: $((Get-MgContext).TenantId)" -ForegroundColor Green
}

function Invoke-GraphGetAll {
    param([Parameter(Mandatory)][string]$Uri)
    $results = @()
    $next = $Uri
    while ($next) {
        $resp = Invoke-MgGraphRequest -Method GET -Uri $next
        if ($resp.value) { $results += $resp.value } else { $results += $resp }
        $next = $resp.'@odata.nextLink'
    }
    return $results
}

Connect-Graph

if ($WhatIfPreference) {
    Write-Host "`n*** PREVIEW MODE (-WhatIf). No changes will be made. Re-run with -WhatIf:`$false to commit. ***`n" -ForegroundColor Yellow
}

# Resolve the pilot/target group
$grp = Invoke-GraphGetAll -Uri ("https://graph.microsoft.com/v1.0/groups?`$filter=displayName eq '{0}'" -f $GroupName)
if (-not $grp) { throw "Group '$GroupName' not found." }
if ($grp.Count -gt 1) { throw "Multiple groups named '$GroupName'. Resolve to a single group." }
$groupId = $grp.id

Write-Host "Staging target group: $GroupName ($groupId)" -ForegroundColor Cyan
Write-Host "STAGING NOTE: this changes only the pilot/target group membership — it does not disable or widen any compliance policy." -ForegroundColor Yellow

$target = "Group '$GroupName'"
$desc = "$Action member $MemberObjectId"

if ($PSCmdlet.ShouldProcess($target, $desc)) {
    if ($Action -eq 'Add') {
        $body = @{ '@odata.id' = "https://graph.microsoft.com/v1.0/directoryObjects/$MemberObjectId" } | ConvertTo-Json
        Invoke-MgGraphRequest -Method POST -Uri ("https://graph.microsoft.com/v1.0/groups/{0}/members/`$ref" -f $groupId) -Body $body | Out-Null
        Write-Host "Added $MemberObjectId to $GroupName." -ForegroundColor Green
    } else {
        Invoke-MgGraphRequest -Method DELETE -Uri ("https://graph.microsoft.com/v1.0/groups/{0}/members/{1}/`$ref" -f $groupId, $MemberObjectId) | Out-Null
        Write-Host "Removed $MemberObjectId from $GroupName." -ForegroundColor Green
    }
} else {
    Write-Host "Preview: would $Action member $MemberObjectId in group '$GroupName'." -ForegroundColor Yellow
}

Write-Host "`nScope-targeting run complete." -ForegroundColor Green
