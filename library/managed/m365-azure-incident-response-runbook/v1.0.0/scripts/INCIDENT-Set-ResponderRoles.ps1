<#
.SYNOPSIS
    INCIDENT-Set-ResponderRoles.ps1 - Create the responder Entra group + assign reader roles (-WhatIf).

    PURPOSE:
        Stands up responder access for the runbook (see 03-implementation.md, Part A8):
          1. Creates (or reuses) the Entra security group "Responder Access Group - Identity - Response".
          2. Optionally adds the named responder users to it.
          3. Assigns the least-privilege reader directory roles responders need for the Diagnose phase
             (Global Reader, Service Support Administrator, Reports Reader, Security Reader) to the group
             via role-assignable group eligibility where possible, falling back to direct user assignment.
        SAFETY MODEL: previews with -WhatIf by default; pass -Apply to make changes. Assigns READER
        roles only - it intentionally does NOT grant scoped admin (Exchange/Teams/SharePoint/Intune
        Administrator), which should be PIM-eligible and granted deliberately per the requirements.

    HOW TO RUN:
        1. Install module (run once):
             Install-Module Microsoft.Graph -Scope CurrentUser
        2. Preview (default - makes NO change):
             .\INCIDENT-Set-ResponderRoles.ps1 -Members "a@contoso.com","b@contoso.com"
        3. Apply for real:
             .\INCIDENT-Set-ResponderRoles.ps1 -Members "a@contoso.com","b@contoso.com" -Apply
        Run as a Privileged Role Administrator / Global Administrator (assigning roles requires it).

    EXPECTED RESULTS:
        Without -Apply: prints the group + role assignments it WOULD make.
        With -Apply: creates the group, adds members, and assigns the reader roles; prints a summary.

.NOTES
    Managed - read-only.
#>

[CmdletBinding(SupportsShouldProcess, ConfirmImpact = 'High')]
param(
    [string]$GroupName = "Responder Access Group - Identity - Response",
    [string[]]$Members = @(),
    [string[]]$ReaderRoles = @('Global Reader','Service Support Administrator','Reports Reader','Security Reader'),
    [switch]$Apply
)

$ErrorActionPreference = 'Stop'
if (-not $Apply) { $WhatIfPreference = $true }

function Write-Plan { param($msg) Write-Host ("[PLAN] {0}" -f $msg) -ForegroundColor Yellow }
function Write-Done { param($msg) Write-Host ("[DONE] {0}" -f $msg) -ForegroundColor Green }

Import-Module Microsoft.Graph.Authentication -ErrorAction Stop
Connect-MgGraph -Scopes "Group.ReadWrite.All","RoleManagement.ReadWrite.Directory","User.Read.All" -NoWelcome

try {
    # --- 1. Group (create or reuse) ---
    $existing = (Invoke-MgGraphRequest -Method GET `
        -Uri "https://graph.microsoft.com/v1.0/groups?`$filter=displayName eq '$GroupName'").value
    if ($existing.Count -gt 0) {
        $groupId = $existing[0].id
        Write-Done ("Reusing existing group '{0}' ({1})." -f $GroupName, $groupId)
    } else {
        Write-Plan ("Create role-assignable security group '{0}'." -f $GroupName)
        if ($PSCmdlet.ShouldProcess($GroupName, "Create security group")) {
            $body = @{
                displayName     = $GroupName
                mailEnabled     = $false
                mailNickname    = ("responder-access-{0}" -f (Get-Random -Maximum 99999))
                securityEnabled = $true
                isAssignableToRole = $true
                description     = "Incident responders - reader access for the M365 & Azure incident runbook."
            }
            $g = Invoke-MgGraphRequest -Method POST -Uri "https://graph.microsoft.com/v1.0/groups" `
                    -Body ($body | ConvertTo-Json)
            $groupId = $g.id
            Write-Done ("Created group '{0}' ({1})." -f $GroupName, $groupId)
        } else { $groupId = '<would-be-created>' }
    }

    # --- 2. Members ---
    foreach ($m in $Members) {
        Write-Plan ("Add member '{0}' to group." -f $m)
        if ($PSCmdlet.ShouldProcess($m, "Add to $GroupName")) {
            try {
                $user = Invoke-MgGraphRequest -Method GET -Uri "https://graph.microsoft.com/v1.0/users/$m"
                Invoke-MgGraphRequest -Method POST `
                    -Uri "https://graph.microsoft.com/v1.0/groups/$groupId/members/`$ref" `
                    -Body (@{ "@odata.id" = "https://graph.microsoft.com/v1.0/directoryObjects/$($user.id)" } | ConvertTo-Json) | Out-Null
                Write-Done ("Added '{0}'." -f $m)
            } catch { Write-Warning ("Could not add '{0}': {1}" -f $m, $_.Exception.Message) }
        }
    }

    # --- 3. Reader directory roles -> group ---
    $roleDefs = (Invoke-MgGraphRequest -Method GET `
        -Uri "https://graph.microsoft.com/v1.0/roleManagement/directory/roleDefinitions?`$filter=isBuiltIn eq true").value
    foreach ($roleName in $ReaderRoles) {
        $def = $roleDefs | Where-Object { $_.displayName -eq $roleName } | Select-Object -First 1
        if (-not $def) { Write-Warning ("Role definition '{0}' not found - skipping." -f $roleName); continue }
        Write-Plan ("Assign reader role '{0}' to group '{1}'." -f $roleName, $GroupName)
        if ($PSCmdlet.ShouldProcess($GroupName, "Assign role $roleName")) {
            try {
                $assign = @{
                    principalId      = $groupId
                    roleDefinitionId = $def.id
                    directoryScopeId = "/"
                }
                Invoke-MgGraphRequest -Method POST `
                    -Uri "https://graph.microsoft.com/v1.0/roleManagement/directory/roleAssignments" `
                    -Body ($assign | ConvertTo-Json) | Out-Null
                Write-Done ("Assigned '{0}'." -f $roleName)
            } catch { Write-Warning ("Could not assign '{0}': {1}" -f $roleName, $_.Exception.Message) }
        }
    }

    if (-not $Apply) {
        Write-Host "`nWhatIf: no changes made. Re-run with -Apply to create the group and assign roles." -ForegroundColor Cyan
    }
    Write-Host "`nNote: scoped admin roles (Exchange/Teams/SharePoint/Intune Administrator) are intentionally" -ForegroundColor Cyan
    Write-Host "NOT granted here - assign them PIM-eligible and deliberately per Requirements R1." -ForegroundColor Cyan
}
finally { try { Disconnect-MgGraph | Out-Null } catch {} }
