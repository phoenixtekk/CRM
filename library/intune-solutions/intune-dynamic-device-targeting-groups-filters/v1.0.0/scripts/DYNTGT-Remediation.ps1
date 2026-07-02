<#
.SYNOPSIS
    DYNTGT-Remediation.ps1 — safely attach the intended assignment filter to a mis-scoped assignment.
.DESCRIPTION
    PURPOSE
        Finds a configuration policy's assignment that targets a given group without the intended
        assignment filter, and attaches the filter (include or exclude) so the assignment is scoped
        correctly. Defaults to -WhatIf: it reports the change it WOULD make and writes nothing until
        you re-run with -Apply.
    HOW TO RUN
        Preview (default, read-only):
          powershell -ExecutionPolicy Bypass -File .\DYNTGT-Remediation.ps1 -PolicyName "Win – Baseline" -GroupName "Corp Devices – Windows – All" -FilterName "OS Version – Windows 11 – Include" -FilterMode include
        Apply the fix:
          ... -Apply
        Requires Microsoft Graph SDK and scope DeviceManagementConfiguration.ReadWrite.All.
    EXPECTED RESULTS
        A preview of the assignment change; with -Apply, the filter is attached to the assignment.
.NOTES
    White-label — Intune Solutions. Safe by default (-WhatIf).
#>
[CmdletBinding()] param(
    [Parameter(Mandatory)][string]$PolicyName,
    [Parameter(Mandatory)][string]$GroupName,
    [Parameter(Mandatory)][string]$FilterName,
    [ValidateSet('include','exclude')][string]$FilterMode = 'include',
    [switch]$Apply
)
$WhatIf = -not $Apply
if (-not (Get-Module -ListAvailable -Name Microsoft.Graph.Authentication)) { Install-Module Microsoft.Graph -Scope CurrentUser -Force -AllowClobber }
Import-Module Microsoft.Graph.Authentication -ErrorAction Stop
$scope = $(if($Apply){'DeviceManagementConfiguration.ReadWrite.All'}else{'DeviceManagementConfiguration.Read.All'})
Connect-MgGraph -Scopes $scope -NoWelcome
Write-Host ("=== Remediation ({0}) ===" -f ($(if($WhatIf){'WhatIf — no changes'}else{'APPLY'}))) -ForegroundColor ($(if($WhatIf){'Yellow'}else{'Cyan'}))

$policy = (Invoke-MgGraphRequest -Method GET -Uri ("/beta/deviceManagement/configurationPolicies?`$filter=name eq '{0}'" -f $PolicyName)).value | Select-Object -First 1
if (-not $policy) { Write-Host "  Policy not found." -ForegroundColor Yellow; Disconnect-MgGraph | Out-Null; exit 1 }
$group  = (Invoke-MgGraphRequest -Method GET -Uri ("/v1.0/groups?`$filter=displayName eq '{0}'&`$select=id,displayName" -f $GroupName)).value | Select-Object -First 1
$filter = (Invoke-MgGraphRequest -Method GET -Uri '/beta/deviceManagement/assignmentFilters').value | Where-Object displayName -eq $FilterName | Select-Object -First 1
if (-not $group -or -not $filter) { Write-Host "  Group or filter not found." -ForegroundColor Yellow; Disconnect-MgGraph | Out-Null; exit 1 }

$asgs = (Invoke-MgGraphRequest -Method GET -Uri ("/beta/deviceManagement/configurationPolicies/{0}/assignments" -f $policy.id)).value
$target = $asgs | Where-Object { $_.target.groupId -eq $group.id } | Select-Object -First 1
if (-not $target) { Write-Host ("  No assignment to '{0}' on this policy." -f $GroupName) -ForegroundColor Yellow; Disconnect-MgGraph | Out-Null; exit 0 }
if ($target.target.deviceAndAppManagementAssignmentFilterId -eq $filter.id) { Write-Host "  Assignment already uses this filter — nothing to do." -ForegroundColor Green; Disconnect-MgGraph | Out-Null; exit 0 }

Write-Host ("  Would set filter '{0}' ({1}) on assignment to '{2}'." -f $filter.displayName, $FilterMode, $group.displayName)
if ($WhatIf) { Write-Host "  (-WhatIf) Re-run with -Apply to make the change." -ForegroundColor Yellow; Disconnect-MgGraph | Out-Null; exit 0 }

$newAssignments = @()
foreach ($a in $asgs) {
    $t = @{ '@odata.type' = $a.target.'@odata.type'; groupId = $a.target.groupId }
    if ($a.target.groupId -eq $group.id) {
        $t.deviceAndAppManagementAssignmentFilterId   = $filter.id
        $t.deviceAndAppManagementAssignmentFilterType = $FilterMode
    } else {
        $t.deviceAndAppManagementAssignmentFilterId   = $a.target.deviceAndAppManagementAssignmentFilterId
        $t.deviceAndAppManagementAssignmentFilterType = $a.target.deviceAndAppManagementAssignmentFilterType
    }
    $newAssignments += @{ target = $t }
}
Invoke-MgGraphRequest -Method POST -Uri ("/beta/deviceManagement/configurationPolicies/{0}/assign" -f $policy.id) -Body (@{ assignments = $newAssignments } | ConvertTo-Json -Depth 6)
Write-Host "  Filter attached. Re-run DYNTGT-Validation.ps1 to confirm effective targeting." -ForegroundColor Green
Disconnect-MgGraph | Out-Null
