<#
.SYNOPSIS
    RHELPOPS-Discovery.ps1 — read-only discovery of the Remote Help help-desk operating model (Graph).
.DESCRIPTION
    PURPOSE
        Reports the current Remote Help RBAC role assignments, the scope groups attached to them,
        and — from that — who-can-help-whom. Use it to see the operating model as it exists today
        before you design or change tiers. This is the OPERATIONS layer; it assumes Remote Help is
        already deployed (see the base "Remote Help" solution).
    HOW TO RUN
        powershell -ExecutionPolicy Bypass -File .\RHELPOPS-Discovery.ps1
        Requires the Microsoft Graph PowerShell SDK. Sign in with an account that can read Intune
        RBAC and Entra groups.
    GRAPH SCOPES
        DeviceManagementRBAC.Read.All, Group.Read.All, User.Read.All
        (Exact scopes/endpoints that expose Remote Help role assignments and their scope members
         may change — verify against current Microsoft documentation.)
    EXPECTED RESULTS
        A console table of each Intune role definition, its assignments, the member (agent) groups,
        and the scope groups — i.e. which tier can help which user population. Read-only; changes
        nothing.
.NOTES
    White-label — Intune Solutions. Read-only against Graph.
    Verify current role/permission names and Graph endpoints against Microsoft documentation.
#>
[CmdletBinding()] param()

if (-not (Get-Module -ListAvailable -Name Microsoft.Graph.Authentication)) {
    Install-Module Microsoft.Graph -Scope CurrentUser -Force -AllowClobber
}
Import-Module Microsoft.Graph.Authentication -ErrorAction Stop
Connect-MgGraph -Scopes 'DeviceManagementRBAC.Read.All','Group.Read.All' -NoWelcome

function Get-GroupName([string]$id) {
    if (-not $id) { return '' }
    try { (Invoke-MgGraphRequest -Method GET -Uri "/v1.0/groups/$id").displayName } catch { $id }
}

Write-Host "Discovering Remote Help RBAC role assignments (read-only)..." -ForegroundColor Cyan
$rows = @()
try {
    # Intune role definitions (built-in + custom). Remote Help capability lives in these roles.
    $defs = (Invoke-MgGraphRequest -Method GET -Uri '/beta/deviceManagement/roleDefinitions?$top=200').value
    foreach ($def in $defs) {
        $assigns = @()
        try { $assigns = (Invoke-MgGraphRequest -Method GET -Uri "/beta/deviceManagement/roleDefinitions/$($def.id)/roleAssignments").value } catch {}
        foreach ($a in $assigns) {
            $members = @($a.members    | ForEach-Object { Get-GroupName $_ })
            $scopes  = @($a.scopeMembers | ForEach-Object { Get-GroupName $_ })
            $rows += [pscustomobject]@{
                Role         = $def.displayName
                BuiltIn      = $def.isBuiltIn
                Assignment   = $a.displayName
                AgentGroups  = ($members -join '; ')
                ScopeGroups  = ($scopes  -join '; ')
                ScopeType    = $a.scopeType
            }
        }
    }
} catch {
    Write-Host "Could not enumerate role definitions/assignments via this endpoint — verify the current Graph path against Microsoft documentation." -ForegroundColor Yellow
}

if ($rows.Count) {
    $rows | Sort-Object Role, Assignment | Format-Table -AutoSize
    Write-Host ("Role assignments discovered: {0}" -f $rows.Count) -ForegroundColor Green
    Write-Host "Read the AgentGroups -> ScopeGroups pairs as 'this tier can help these users'." -ForegroundColor Cyan
} else {
    Write-Host "No role assignments surfaced. Confirm Remote Help is deployed (base solution) and that roles are assigned." -ForegroundColor Yellow
}
Disconnect-MgGraph | Out-Null
