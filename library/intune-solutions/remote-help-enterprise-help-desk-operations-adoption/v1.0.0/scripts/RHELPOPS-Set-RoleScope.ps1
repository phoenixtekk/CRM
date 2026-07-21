<#
.SYNOPSIS
    RHELPOPS-Set-RoleScope.ps1 — assign a Remote Help RBAC role + scope group to a help-desk tier (Graph).
    THE ONLY STATE-CHANGER IN THIS SOLUTION. DEFAULTS TO -WhatIf (dry run) — it changes nothing until
    you explicitly pass -WhatIf:$false.
.DESCRIPTION
    PURPOSE
        Creates an Intune role assignment that binds a Remote Help RBAC role to a tier's agent group
        (members) with a scope group (the users that tier may help) — i.e. it wires one row of the
        operating model from the Implementation Guide (Step 5a). Use it to apply or adjust a single
        tier's role/scope without clicking through the portal.
    HOW TO RUN
        # Dry run (default — shows exactly what WOULD change, changes nothing):
        powershell -ExecutionPolicy Bypass -File .\RHELPOPS-Set-RoleScope.ps1 `
            -RoleName 'RHELP Role – Tier 1 View' -AgentGroup 'RHELP-T1-Agents' `
            -ScopeGroup 'RHELP-Scope-Standard-Users' -AssignmentName 'RHELP Assignment – Tier 1'
        # Commit the change (explicit opt-in):
        ... same command ... -WhatIf:$false
        Requires the Microsoft Graph PowerShell SDK and rights to manage Intune RBAC.
    GRAPH SCOPES
        DeviceManagementRBAC.ReadWrite.All, Group.Read.All
        (Verify the current role-assignment endpoint/payload shape against Microsoft documentation
         before committing — it changes over time.)
    EXPECTED RESULTS
        In -WhatIf mode: prints the resolved role, agent group, scope group, and the assignment it
        WOULD create — and exits without writing. With -WhatIf:$false: creates the role assignment
        and prints its id.
.NOTES
    White-label — Intune Solutions. State-changing (guarded). Defaults to -WhatIf = no change.
    Object names match the Implementation Guide (RHELP Role – Tier *, RHELP-T*-Agents, RHELP-Scope-*).
#>
[CmdletBinding(SupportsShouldProcess=$true, ConfirmImpact='High')]
param(
    [Parameter(Mandatory)][string]$RoleName,
    [Parameter(Mandatory)][string]$AgentGroup,
    [Parameter(Mandatory)][string]$ScopeGroup,
    [string]$AssignmentName = 'RHELP Assignment',
    # DEFAULT-SAFE: dry run unless the caller explicitly sets -WhatIf:$false
    [switch]$WhatIf = $true
)

if (-not (Get-Module -ListAvailable -Name Microsoft.Graph.Authentication)) {
    Install-Module Microsoft.Graph -Scope CurrentUser -Force -AllowClobber
}
Import-Module Microsoft.Graph.Authentication -ErrorAction Stop
Connect-MgGraph -Scopes 'DeviceManagementRBAC.ReadWrite.All','Group.Read.All' -NoWelcome

function Get-GroupId([string]$name) {
    try { ((Invoke-MgGraphRequest -Method GET -Uri "/v1.0/groups?`$filter=displayName eq '$name'").value | Select-Object -First 1).id } catch { $null }
}
function Get-RoleId([string]$name) {
    try {
        $defs = (Invoke-MgGraphRequest -Method GET -Uri '/beta/deviceManagement/roleDefinitions?$top=200').value
        ($defs | Where-Object { $_.displayName -eq $name } | Select-Object -First 1).id
    } catch { $null }
}

$roleId  = Get-RoleId  $RoleName
$agentId = Get-GroupId $AgentGroup
$scopeId = Get-GroupId $ScopeGroup

$problem = $false
if (-not $roleId)  { Write-Host "Role '$RoleName' not found — create it first (Implementation Step 3) or verify the name." -ForegroundColor Red; $problem=$true }
if (-not $agentId) { Write-Host "Agent group '$AgentGroup' not found — create it first (Step 1)." -ForegroundColor Red; $problem=$true }
if (-not $scopeId) { Write-Host "Scope group '$ScopeGroup' not found — create it first (Step 2)." -ForegroundColor Red; $problem=$true }
if ($problem) { Disconnect-MgGraph | Out-Null; exit 2 }

Write-Host "Resolved:" -ForegroundColor Cyan
Write-Host ("  Role        : {0}  ({1})" -f $RoleName,  $roleId)
Write-Host ("  Agent group : {0}  ({1})" -f $AgentGroup, $agentId)
Write-Host ("  Scope group : {0}  ({1})" -f $ScopeGroup, $scopeId)
Write-Host ("  Assignment  : {0}" -f $AssignmentName)

$body = @{
    displayName  = $AssignmentName
    description  = "Remote Help tier role/scope binding created by RHELPOPS-Set-RoleScope.ps1"
    members      = @($agentId)
    scopeMembers = @($scopeId)
    scopeType    = 'resourceScope'
} | ConvertTo-Json

$uri = "/beta/deviceManagement/roleDefinitions/$roleId/roleAssignments"

if ($WhatIf) {
    Write-Host ""
    Write-Host "-WhatIf (default): DRY RUN — no change made." -ForegroundColor Yellow
    Write-Host "WOULD POST to: $uri" -ForegroundColor Yellow
    Write-Host $body -ForegroundColor DarkGray
    Write-Host "Re-run with -WhatIf:`$false to commit. Verify the payload/endpoint against current Microsoft documentation first." -ForegroundColor Yellow
    Disconnect-MgGraph | Out-Null
    exit 0
}

if ($PSCmdlet.ShouldProcess($AssignmentName, "Create Remote Help role assignment ($RoleName -> $AgentGroup scoped to $ScopeGroup)")) {
    try {
        $res = Invoke-MgGraphRequest -Method POST -Uri $uri -Body $body -ContentType 'application/json'
        Write-Host ("Created role assignment. Id: {0}" -f $res.id) -ForegroundColor Green
    } catch {
        Write-Host ("Create failed: {0}" -f $_.Exception.Message) -ForegroundColor Red
        Write-Host "Verify the role-assignment endpoint/payload against current Microsoft documentation." -ForegroundColor Yellow
        Disconnect-MgGraph | Out-Null; exit 1
    }
}
Disconnect-MgGraph | Out-Null
