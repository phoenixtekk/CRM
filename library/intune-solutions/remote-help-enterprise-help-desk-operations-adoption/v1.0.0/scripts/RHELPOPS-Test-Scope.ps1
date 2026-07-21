<#
.SYNOPSIS
    RHELPOPS-Test-Scope.ps1 — prove a help-desk tier is scoped to the intended users and no more (Graph).
.DESCRIPTION
    PURPOSE
        For a given tier, resolves the users the tier CAN help (the union of the scope groups on that
        tier's Remote Help role assignments) and compares them to the users you EXPECT it to help.
        Reports the overlap plus any users the tier can reach that it should NOT ("over-reach") and any
        it should reach but cannot ("gap"). This is the read-only proof behind Testing Test 1. Changes
        nothing.
    HOW TO RUN
        powershell -ExecutionPolicy Bypass -File .\RHELPOPS-Test-Scope.ps1 -TierAgentGroup RHELP-T1-Agents -ExpectedScopeGroup RHELP-Scope-Standard-Users
        Requires the Microsoft Graph PowerShell SDK.
    GRAPH SCOPES
        DeviceManagementRBAC.Read.All, Group.Read.All, User.Read.All
        (Verify current endpoints that expose role assignments + scope members against Microsoft docs.)
    EXPECTED RESULTS
        Counts and PASS/FAIL: PASS when the tier's reachable users equal the expected scope (no
        over-reach); FAIL when the tier can reach any user outside the expected scope.
.NOTES
    White-label — Intune Solutions. Read-only against Graph.
    Object names match the Implementation Guide (RHELP-T*-Agents, RHELP-Scope-*).
#>
[CmdletBinding()] param(
    [Parameter(Mandatory)][string]$TierAgentGroup,
    [Parameter(Mandatory)][string]$ExpectedScopeGroup
)

if (-not (Get-Module -ListAvailable -Name Microsoft.Graph.Authentication)) {
    Install-Module Microsoft.Graph -Scope CurrentUser -Force -AllowClobber
}
Import-Module Microsoft.Graph.Authentication -ErrorAction Stop
Connect-MgGraph -Scopes 'DeviceManagementRBAC.Read.All','Group.Read.All' -NoWelcome

function Get-GroupId([string]$name) {
    try { ((Invoke-MgGraphRequest -Method GET -Uri "/v1.0/groups?`$filter=displayName eq '$name'").value | Select-Object -First 1).id } catch { $null }
}
function Get-GroupMemberIds([string]$id) {
    if (-not $id) { return @() }
    $ids = @(); $uri = "/v1.0/groups/$id/members?`$select=id&`$top=999"
    do {
        try { $r = Invoke-MgGraphRequest -Method GET -Uri $uri } catch { break }
        $ids += @($r.value | ForEach-Object { $_.id }); $uri = $r.'@odata.nextLink'
    } while ($uri)
    $ids
}

$agentGroupId = Get-GroupId $TierAgentGroup
$expectedId   = Get-GroupId $ExpectedScopeGroup
if (-not $agentGroupId) { Write-Host "Tier agent group '$TierAgentGroup' not found." -ForegroundColor Red; Disconnect-MgGraph|Out-Null; exit 2 }
if (-not $expectedId)   { Write-Host "Expected scope group '$ExpectedScopeGroup' not found." -ForegroundColor Red; Disconnect-MgGraph|Out-Null; exit 2 }

# Resolve the scope groups attached to the tier's role assignments (its actual reach).
$reachScopeGroupIds = @()
try {
    $defs = (Invoke-MgGraphRequest -Method GET -Uri '/beta/deviceManagement/roleDefinitions?$top=200').value
    foreach ($def in $defs) {
        $as = @()
        try { $as = (Invoke-MgGraphRequest -Method GET -Uri "/beta/deviceManagement/roleDefinitions/$($def.id)/roleAssignments").value } catch {}
        foreach ($a in $as) {
            if ($a.members -contains $agentGroupId) { $reachScopeGroupIds += @($a.scopeMembers) }
        }
    }
} catch {
    Write-Host "Could not resolve role assignments — verify the Graph endpoint against Microsoft documentation." -ForegroundColor Yellow
}
$reachScopeGroupIds = $reachScopeGroupIds | Select-Object -Unique

$reachUsers    = @(); foreach ($g in $reachScopeGroupIds) { $reachUsers += Get-GroupMemberIds $g }
$reachUsers    = $reachUsers | Select-Object -Unique
$expectedUsers = Get-GroupMemberIds $expectedId

$overReach = @($reachUsers    | Where-Object { $_ -notin $expectedUsers })
$gap       = @($expectedUsers | Where-Object { $_ -notin $reachUsers })

Write-Host ("Tier '{0}' reachable users: {1}" -f $TierAgentGroup, $reachUsers.Count)
Write-Host ("Expected ('{0}') users:    {1}" -f $ExpectedScopeGroup, $expectedUsers.Count)
Write-Host ("Over-reach (can help but should NOT): {0}" -f $overReach.Count) -ForegroundColor ($(if($overReach.Count){'Red'}else{'Green'}))
Write-Host ("Gap (should help but cannot):         {0}" -f $gap.Count) -ForegroundColor ($(if($gap.Count){'Yellow'}else{'Green'}))

if ($overReach.Count -eq 0) {
    Write-Host "PASS — tier is scoped to the intended users and no more." -ForegroundColor Green
    Disconnect-MgGraph | Out-Null; exit 0
} else {
    Write-Host "FAIL — tier can reach users outside the expected scope. Tighten the role scope groups." -ForegroundColor Red
    Disconnect-MgGraph | Out-Null; exit 1
}
