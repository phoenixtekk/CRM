<#
.SYNOPSIS
    ENTPIM-Discovery.ps1 — inventory standing (active) privileged role assignments in Microsoft Entra.
.DESCRIPTION
    PURPOSE
        Read-only baseline of standing privileged access. Lists every ACTIVE assignment for
        Microsoft Entra directory roles — the account, the role, and whether the assignment is
        permanent (no end date) versus time-bound — so you know exactly what to convert to eligible.
        With -IncludeAzureResources it also reports active Azure resource-role (RBAC) assignments for
        onboarded subscriptions. This is your conversion worklist.
    HOW TO RUN
        Install-Module Microsoft.Graph -Scope CurrentUser        # once
        powershell -ExecutionPolicy Bypass -File .\ENTPIM-Discovery.ps1
        Optional: -IncludeAzureResources   include Azure resource-role assignments (needs the Az module + RBAC read)
        Optional: -CsvPath .\entpim-standing.csv   export a flat CSV
        Consents to RoleManagement.Read.All, PrivilegedAccess.Read.AzureAD, Directory.Read.All (read-only).
    EXPECTED RESULTS
        A per-assignment listing of standing privileged access with account, role, and permanence.
        Permanent Global Administrators are highlighted. No changes are made.
.NOTES
    White-label — Entra ID Solutions. Read-only.
#>
[CmdletBinding()]
param(
    [switch]$IncludeAzureResources,
    [string]$CsvPath
)

Import-Module Microsoft.Graph.Authentication -ErrorAction Stop
Connect-MgGraph -Scopes 'RoleManagement.Read.All','PrivilegedAccess.Read.AzureAD','Directory.Read.All' -NoWelcome

Write-Host "`n=== Standing Privileged Access — $(Get-Date -Format s) ===" -ForegroundColor Cyan

# Build a lookup of roleDefinitionId -> display name
$roleDefs = @{}
Get-MgRoleManagementDirectoryRoleDefinition -All | ForEach-Object { $roleDefs[$_.Id] = $_.DisplayName }

# Principal name resolver (user / group / service principal)
$principalCache = @{}
function Resolve-Principal($id) {
    if ($principalCache.ContainsKey($id)) { return $principalCache[$id] }
    $name = $id
    $obj = Invoke-MgGraphRequest -Method GET -Uri "/v1.0/directoryObjects/$id" -ErrorAction SilentlyContinue
    if ($obj) { $name = $obj.userPrincipalName ?? $obj.displayName ?? $id }
    $principalCache[$id] = $name
    return $name
}

$rows = @()
# ACTIVE (standing) directory-role assignment instances
$active = Get-MgRoleManagementDirectoryRoleAssignmentScheduleInstance -All -ErrorAction SilentlyContinue
Write-Host ("Active directory-role assignments: {0}`n" -f $active.Count)

foreach ($a in $active) {
    $roleName  = $roleDefs[$a.RoleDefinitionId]
    $principal = Resolve-Principal $a.PrincipalId
    $permanent = [string]::IsNullOrEmpty($a.EndDateTime)
    $isGA      = $roleName -eq 'Global Administrator'

    $color = if ($isGA -and $permanent) { 'Red' } elseif ($permanent) { 'Yellow' } else { 'White' }
    Write-Host ("• {0,-32} {1}" -f $roleName, $principal) -ForegroundColor $color
    Write-Host ("    permanent: {0}   scope: {1}   assignmentType: {2}" -f $permanent, $a.DirectoryScopeId, $a.AssignmentType)

    $rows += [pscustomobject]@{
        Scope='EntraRole'; Role=$roleName; Principal=$principal; PrincipalId=$a.PrincipalId
        Permanent=$permanent; DirectoryScope=$a.DirectoryScopeId; AssignmentType=$a.AssignmentType
        EndDateTime=$a.EndDateTime
    }
}

$permGA = @($rows | Where-Object { $_.Role -eq 'Global Administrator' -and $_.Permanent })
Write-Host ("`nPermanent Global Administrators: {0}" -f $permGA.Count) -ForegroundColor $(if($permGA.Count -gt 2){'Red'}else{'Green'})
Write-Host "  (Target: only break-glass accounts hold permanent Global Administrator. *Verify current guidance in your tenant.*)"

if ($IncludeAzureResources) {
    Write-Host "`n--- Azure resource roles ---" -ForegroundColor Cyan
    if (Get-Module -ListAvailable Az.Resources) {
        Import-Module Az.Resources -ErrorAction SilentlyContinue
        try {
            foreach ($sub in (Get-AzSubscription -ErrorAction Stop)) {
                Set-AzContext -SubscriptionId $sub.Id | Out-Null
                foreach ($ra in (Get-AzRoleAssignment | Where-Object { $_.RoleDefinitionName -in 'Owner','Contributor','User Access Administrator' })) {
                    Write-Host ("• [{0}] {1,-24} {2}" -f $sub.Name, $ra.RoleDefinitionName, $ra.DisplayName)
                    $rows += [pscustomobject]@{
                        Scope='AzureResource'; Role=$ra.RoleDefinitionName; Principal=$ra.DisplayName; PrincipalId=$ra.ObjectId
                        Permanent=$true; DirectoryScope=$ra.Scope; AssignmentType='Active'; EndDateTime=$null
                    }
                }
            }
        } catch { Write-Warning "Azure discovery skipped: $($_.Exception.Message)" }
    } else {
        Write-Warning "Az.Resources module not found. Install-Module Az -Scope CurrentUser to include Azure resource roles."
    }
}

if ($CsvPath) {
    $rows | Export-Csv -Path $CsvPath -NoTypeInformation -Encoding UTF8
    Write-Host ("`nExported {0} rows to {1}" -f $rows.Count, $CsvPath) -ForegroundColor Green
}
Disconnect-MgGraph | Out-Null
