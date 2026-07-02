<#
.SYNOPSIS
    INTAPPDX-Set-ScopeTargeting.ps1 — add a pilot group assignment to an app for phased rollout (default -WhatIf).
.DESCRIPTION
    PURPOSE
        Adds a Required (or Available) assignment for a named pilot security group to an
        app, so you can validate a fix on a small ring before expanding to the fleet.
        It never removes existing assignments; it only adds the pilot targeting you name.
        Runs in preview mode by default and only shows the planned change.
    HOW TO RUN
        Preview (default):
          powershell -ExecutionPolicy Bypass -File .\INTAPPDX-Set-ScopeTargeting.ps1 -AppNameLike "your-app-name" -PilotGroupId your-group-id
        Apply:
          powershell -ExecutionPolicy Bypass -File .\INTAPPDX-Set-ScopeTargeting.ps1 -AppNameLike "your-app-name" -PilotGroupId your-group-id -Intent required -WhatIf:$false

        Required Graph scopes: DeviceManagementApps.ReadWrite.All, Group.Read.All
    EXPECTED RESULTS
        The planned assignment (app, intent, pilot group) is shown. In preview no change is
        made. When applied, the pilot group is added as an assignment target; validate the
        three gates on the pilot before expanding.
.NOTES
    White-label — the repeatable way. Defaults to -WhatIf; makes no change until you confirm.
#>

[CmdletBinding(SupportsShouldProcess = $true, ConfirmImpact = 'High')]
param(
    [Parameter(Mandatory)][string] $AppNameLike,
    [Parameter(Mandatory)][string] $PilotGroupId,
    [ValidateSet('required','available','uninstall')][string] $Intent = 'required',
    [switch] $WhatIf = $true
)

$ErrorActionPreference = 'Stop'
if ($WhatIf) { $WhatIfPreference = $true }

function Connect-Graph {
    $scopes = @('DeviceManagementApps.ReadWrite.All','Group.Read.All')
    if (-not (Get-Module -ListAvailable -Name Microsoft.Graph.Authentication)) {
        throw "Microsoft Graph SDK not found. Run: Install-Module Microsoft.Graph -Scope CurrentUser"
    }
    Import-Module Microsoft.Graph.Authentication -ErrorAction Stop
    if (-not (Get-MgContext)) { Connect-MgGraph -Scopes $scopes | Out-Null }
}

function Invoke-GraphGet {
    param([Parameter(Mandatory)][string] $Uri)
    $items = @(); $next = $Uri
    while ($next) {
        $resp = Invoke-MgGraphRequest -Method GET -Uri $next
        if ($resp.value) { $items += $resp.value } elseif ($resp) { $items += $resp }
        $next = $resp.'@odata.nextLink'
    }
    return $items
}

Connect-Graph
$base = 'https://graph.microsoft.com/beta'

# Resolve the pilot group name for the confirmation display (read-only).
$groupName = $PilotGroupId
try {
    $g = Invoke-MgGraphRequest -Method GET -Uri "$base/groups/$PilotGroupId"
    if ($g.displayName) { $groupName = $g.displayName }
} catch { Write-Host "Note: could not resolve group name for $PilotGroupId (continuing)." -ForegroundColor Yellow }

$apps = Invoke-GraphGet -Uri "$base/deviceAppManagement/mobileApps?`$top=100" |
        Where-Object { $_.displayName -like "*$AppNameLike*" }
if (-not $apps) { throw "No app found matching '$AppNameLike'." }

foreach ($app in $apps) {
    Write-Host ("Planned pilot assignment: App='{0}'  Intent='{1}'  Group='{2}' ({3})" -f $app.displayName, $Intent, $groupName, $PilotGroupId) -ForegroundColor Cyan

    if ($WhatIfPreference) {
        Write-Host "  PREVIEW (-WhatIf): no change made. Re-run with -WhatIf:`$false to apply." -ForegroundColor Yellow
        continue
    }

    if ($PSCmdlet.ShouldProcess("$($app.displayName)", "Add '$Intent' assignment for pilot group $groupName")) {
        $body = @{
            mobileAppAssignments = @(
                @{
                    '@odata.type' = '#microsoft.graph.mobileAppAssignment'
                    intent        = $Intent
                    target        = @{
                        '@odata.type' = '#microsoft.graph.groupAssignmentTarget'
                        groupId       = $PilotGroupId
                    }
                }
            )
        }
        try {
            Invoke-MgGraphRequest -Method POST -Uri "$base/deviceAppManagement/mobileApps/$($app.id)/assign" -Body ($body | ConvertTo-Json -Depth 6) | Out-Null
            Write-Host "  Pilot assignment added for '$($app.displayName)'." -ForegroundColor Green
        } catch {
            Write-Host "  Failed to add assignment for '$($app.displayName)': $($_.Exception.Message)" -ForegroundColor Red
        }
    }
}

Write-Host "`nValidate the three gates on the pilot (INTAPPDX-Validation.ps1) before expanding to the fleet." -ForegroundColor Cyan
