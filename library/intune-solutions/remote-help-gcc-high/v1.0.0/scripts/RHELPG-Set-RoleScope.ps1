<#
.SYNOPSIS
    RHELPG-Set-RoleScope.ps1 — assign a Remote Help RBAC role/scope in a US Government tenant (DEFAULTS TO -WhatIf).
.DESCRIPTION
    PURPOSE
        The ONLY state-changing script in this package. Creates a Remote Help RBAC role assignment in a
        US Government (GCC High/DoD) Intune tenant: it binds an Intune role that carries Remote Help
        permissions (default the built-in "Help Desk Operator") to a members (admin) group and a user
        scope group, so helpers can assist their scoped users. It also idempotently creates the pilot
        security group if a name is given. Runs in PREVIEW (-WhatIf) mode by DEFAULT — no change is made
        unless you re-run with -WhatIf:$false after reviewing the preview.

        IMPORTANT: On GCC High/DoD, Remote Help is NOT offered at authoring time, so the Remote Help role
        may be absent and this assignment can fail by design — that is the expected signal that the
        feature is not available for your tier (use the compliant alternative in gcc-high-parity-notes.md).
        For a GCC tenant (commercial instance) run with -Environment Global. Verify against current
        Microsoft documentation.
    HOW TO RUN
        Preview (default): powershell -ExecutionPolicy Bypass -File .\RHELPG-Set-RoleScope.ps1 `
                             -MembersGroupName "RemoteHelp - GCCH - Pilot" -ScopeGroupName "RemoteHelp - GCCH - Pilot"
        Apply:            add -WhatIf:$false to the same command after reviewing the preview.
    GRAPH SCOPES
        DeviceManagementRBAC.ReadWrite.All, Group.ReadWrite.All, Group.Read.All
    EXPECTED RESULTS
        The chosen role's ID, the members + scope group IDs, and either a WHATIF preview line or a created
        role assignment. If the role has no Remote Help permissions (or is absent on this tier), the
        script says so and makes no change.
.NOTES
    White-label — the repeatable way. State-changer, gated by -WhatIf (default preview).
    All sovereign availability/endpoints are "verify against current Microsoft documentation".
#>
[CmdletBinding(SupportsShouldProcess=$true, ConfirmImpact='Medium')]
param(
    [string]$RoleName        = 'Help Desk Operator',
    [string]$AssignmentName  = 'RemoteHelp - GCCH - HelpDesk Assignment',
    [Parameter(Mandatory=$true)][string]$MembersGroupName,
    [Parameter(Mandatory=$true)][string]$ScopeGroupName,
    [ValidateSet('USGov','USGovDoD','Global')][string]$Environment = 'USGov'
)
if (-not (Get-Module -ListAvailable -Name Microsoft.Graph.Authentication)) { Install-Module Microsoft.Graph -Scope CurrentUser -Force -AllowClobber }
Import-Module Microsoft.Graph.Authentication -ErrorAction Stop
Connect-MgGraph -Environment $Environment -Scopes 'DeviceManagementRBAC.ReadWrite.All','Group.ReadWrite.All','Group.Read.All' -NoWelcome

Write-Host "=== RHELPG Set Role Scope (Government edition, env: $Environment) ===" -ForegroundColor Cyan
if (-not $PSBoundParameters.ContainsKey('WhatIf')) { Write-Host "Running in PREVIEW (-WhatIf) mode — no changes will be made. Add -WhatIf:`$false to apply." -ForegroundColor Yellow }

function Get-OrNewGroup([string]$name) {
    $esc = $name.Replace("'","''")
    $g = (Invoke-MgGraphRequest -Method GET -Uri "/v1.0/groups?`$filter=displayName eq '$esc'").value | Select-Object -First 1
    if ($g) { Write-Host ("  group exists : {0} ({1})" -f $name, $g.id); return $g }
    if (-not $PSCmdlet.ShouldProcess($name, "Create security group")) { Write-Host ("  WHATIF would create group: {0}" -f $name) -ForegroundColor Yellow; return $null }
    $mail = ($name -replace '[^a-zA-Z0-9]','').ToLower()
    $body = @{ displayName=$name; mailEnabled=$false; mailNickname=$mail; securityEnabled=$true }
    $g = Invoke-MgGraphRequest -Method POST -Uri '/v1.0/groups' -Body ($body | ConvertTo-Json)
    Write-Host ("  group created: {0} ({1})" -f $name, $g.id) -ForegroundColor Green
    return $g
}

# 1) Resolve the RBAC role and confirm it carries Remote Help permissions
$roles = @((Invoke-MgGraphRequest -Method GET -Uri '/beta/deviceManagement/roleDefinitions?$top=200').value)
$role  = $roles | Where-Object { $_.displayName -eq $RoleName } | Select-Object -First 1
if (-not $role) {
    Write-Host ("  ! Role '{0}' not found in this tenant." -f $RoleName) -ForegroundColor Yellow
    Write-Host "  On GCC High/DoD the Remote Help role may be absent (feature not offered) — this is expected." -ForegroundColor Yellow
    Write-Host "  Use the compliant alternative (gcc-high-parity-notes.md §4). Verify against current Microsoft documentation." -ForegroundColor DarkCyan
    Disconnect-MgGraph | Out-Null; return
}
$hasRh = (@($role.rolePermissions.resourceActions.allowedResourceActions) -join ';') -match 'RemoteAssistance|RemoteHelp|RemoteTasks'
Write-Host ("  role         : {0} ({1}); Remote Help perms present: {2}" -f $role.displayName, $role.id, $hasRh) -ForegroundColor ($(if($hasRh){'Green'}else{'Yellow'}))
if (-not $hasRh) { Write-Host "  ! Selected role has no Remote Help permissions — pick a role that does, or the feature is unavailable on this tier." -ForegroundColor Yellow }

# 2) Resolve/create the members + scope groups
$members = Get-OrNewGroup $MembersGroupName
$scope   = Get-OrNewGroup $ScopeGroupName

# 3) Create the role assignment (state change — gated)
if ($members -and $scope) {
    $target = "role '$RoleName' -> members '$MembersGroupName', scope '$ScopeGroupName'"
    if ($PSCmdlet.ShouldProcess($target, "Create Intune role assignment '$AssignmentName'")) {
        $body = @{
            displayName        = $AssignmentName
            description        = 'Remote Help helpers scoped to their supported users (Government edition).'
            members            = @($members.id)
            scopeMembers       = @($scope.id)
            scopeType          = 'resourceScope'
            roleDefinition     = @{ id = $role.id }
        }
        try {
            $ra = Invoke-MgGraphRequest -Method POST -Uri '/beta/deviceManagement/roleAssignments' -Body ($body | ConvertTo-Json -Depth 5)
            Write-Host ("  created role assignment: {0} ({1})" -f $AssignmentName, $ra.id) -ForegroundColor Green
        } catch {
            Write-Host ("  ! Role assignment failed: {0}" -f $_.Exception.Message) -ForegroundColor Yellow
            Write-Host "  On GCC High/DoD this can be expected (Remote Help not offered). Verify against current Microsoft documentation." -ForegroundColor DarkCyan
        }
    } else {
        Write-Host ("  WHATIF would create role assignment: {0} ({1})" -f $AssignmentName, $target) -ForegroundColor Yellow
    }
}
Write-Host "`nReminder: scope to a USER group (the All Devices scope excludes unenrolled devices)." -ForegroundColor DarkCyan
Disconnect-MgGraph | Out-Null
