<#
.SYNOPSIS
    ABMPROV-Remediation.ps1 — safely re-provision a user / fix scope-group membership (default -WhatIf).
.DESCRIPTION
    PURPOSE
        Closes the most common provisioning gaps: (1) add a user to the Managed Apple ID provisioning
        scope group so the next SCIM cycle provisions them; (2) ensure the provisioning scope group is
        assigned to the Entra "Apple Business Manager" application; and (3) optionally request an
        on-demand provisioning retry for a user (provisionOnDemand). By default it runs in -WhatIf mode
        and only reports the changes it would make; pass -Apply to make them. It does NOT configure
        federation or resolve Apple-ID conflicts — those are ABM-side and deferred to Apple's docs.
    HOW TO RUN
        Preview (default):  powershell -ExecutionPolicy Bypass -File .\ABMPROV-Remediation.ps1 -UserUpn user1@contoso.com
        Apply:              powershell -ExecutionPolicy Bypass -File .\ABMPROV-Remediation.ps1 -UserUpn user1@contoso.com -Apply
        Requires the Microsoft Graph PowerShell SDK and delegated scopes:
        Application.ReadWrite.All, AppRoleAssignment.ReadWrite.All, Group.ReadWrite.All,
        User.Read.All, Synchronization.ReadWrite.All.
    EXPECTED RESULTS
        In preview: the membership/assignment/retry actions that are needed. With -Apply: the user is
        added to the scope group, the group is assigned to the app if missing, and (if -OnDemand) a
        provisioning retry is requested. Re-run ABMPROV-Validation.ps1 / ABMPROV-Report.ps1 afterward.
.NOTES
    Entra ID Solutions — Entra ID + ABM federation & auto-provisioning. Default -WhatIf. ABM/conflicts deferred.
#>
[CmdletBinding(SupportsShouldProcess=$true)]
param(
    [Parameter(Mandatory=$true)][string]$UserUpn,
    [string]$AppDisplayName = 'Apple Business Manager - Federation - Prod',
    [string]$ScopeGroup     = 'Managed Apple ID Provisioning - Pilot - Stage',
    [switch]$OnDemand,
    [switch]$Apply
)

$WhatIfPreference = -not $Apply

if (-not (Get-Module -ListAvailable -Name Microsoft.Graph.Authentication)) {
    Install-Module Microsoft.Graph -Scope CurrentUser -Force -AllowClobber
}
Import-Module Microsoft.Graph.Authentication -ErrorAction Stop
Connect-MgGraph -Scopes 'Application.ReadWrite.All','AppRoleAssignment.ReadWrite.All','Group.ReadWrite.All','User.Read.All','Synchronization.ReadWrite.All' -NoWelcome

Write-Host "=== ABM provisioning remediation ===" -ForegroundColor Cyan
if (-not $Apply) { Write-Host "(preview mode — re-run with -Apply to make changes)" -ForegroundColor Yellow }

# Resolve user
$ue = $UserUpn.Replace("'","''")
$user = (Invoke-MgGraphRequest -Method GET -Uri "/v1.0/users?`$filter=userPrincipalName eq '$ue'").value | Select-Object -First 1
if (-not $user) { Write-Host ("User '{0}' not found." -f $UserUpn) -ForegroundColor Yellow; Disconnect-MgGraph | Out-Null; return }

# 1. Ensure user is in the scope group
$ge = $ScopeGroup.Replace("'","''")
$grp = (Invoke-MgGraphRequest -Method GET -Uri "/v1.0/groups?`$filter=displayName eq '$ge'").value | Select-Object -First 1
if (-not $grp) { Write-Host ("Scope group '{0}' missing — create it with ABMPROV-Set-ScopeTargeting.ps1." -f $ScopeGroup) -ForegroundColor Yellow; Disconnect-MgGraph | Out-Null; return }

$isMember = $false
try {
    $members = (Invoke-MgGraphRequest -Method GET -Uri "/v1.0/groups/$($grp.id)/members?`$select=id").value
    if ($members.id -contains $user.id) { $isMember = $true }
} catch {}

if ($isMember) {
    Write-Host ("  OK   : '{0}' already in '{1}'." -f $UserUpn, $ScopeGroup) -ForegroundColor Green
} elseif ($PSCmdlet.ShouldProcess($UserUpn, "Add to '$ScopeGroup'")) {
    $body = @{ '@odata.id' = "https://graph.microsoft.com/v1.0/directoryObjects/$($user.id)" } | ConvertTo-Json
    try { Invoke-MgGraphRequest -Method POST -Uri "/v1.0/groups/$($grp.id)/members/`$ref" -Body $body -ContentType 'application/json' | Out-Null
          Write-Host ("  DONE : added '{0}' to '{1}'." -f $UserUpn, $ScopeGroup) -ForegroundColor Green }
    catch { Write-Host ("  FAIL : could not add '{0}': {1}" -f $UserUpn, $_.Exception.Message) -ForegroundColor Yellow }
} else {
    Write-Host ("  WOULD: add '{0}' to '{1}'." -f $UserUpn, $ScopeGroup) -ForegroundColor Cyan
}

# 2. Ensure scope group is assigned to the provisioning app
$escaped = $AppDisplayName.Replace("'","''")
$sp = (Invoke-MgGraphRequest -Method GET -Uri "/v1.0/servicePrincipals?`$filter=displayName eq '$escaped'").value | Select-Object -First 1
if (-not $sp) {
    Write-Host ("  App '{0}' not found — add it (Implementation Step 2)." -f $AppDisplayName) -ForegroundColor Yellow
} else {
    $assigned = @()
    try { $assigned = (Invoke-MgGraphRequest -Method GET -Uri "/v1.0/servicePrincipals/$($sp.id)/appRoleAssignedTo").value } catch {}
    if ($assigned.principalId -contains $grp.id) {
        Write-Host ("  OK   : '{0}' already assigned to the app." -f $ScopeGroup) -ForegroundColor Green
    } else {
        $roleId = '00000000-0000-0000-0000-000000000000'
        if ($sp.appRoles) {
            $r = $sp.appRoles | Where-Object { $_.isEnabled -and ($_.allowedMemberTypes -contains 'User') } | Select-Object -First 1
            if ($r) { $roleId = $r.id }
        }
        if ($PSCmdlet.ShouldProcess($ScopeGroup, "Assign group to '$AppDisplayName'")) {
            $b = @{ principalId = $grp.id; resourceId = $sp.id; appRoleId = $roleId } | ConvertTo-Json
            try { Invoke-MgGraphRequest -Method POST -Uri "/v1.0/servicePrincipals/$($sp.id)/appRoleAssignedTo" -Body $b -ContentType 'application/json' | Out-Null
                  Write-Host ("  DONE : assigned '{0}' to the app." -f $ScopeGroup) -ForegroundColor Green }
            catch { Write-Host ("  FAIL : could not assign '{0}': {1}" -f $ScopeGroup, $_.Exception.Message) -ForegroundColor Yellow }
        } else {
            Write-Host ("  WOULD: assign '{0}' to the app." -f $ScopeGroup) -ForegroundColor Cyan
        }
    }

    # 3. Optional on-demand provisioning retry
    if ($OnDemand) {
        $jobId = $null
        try { $jobId = ((Invoke-MgGraphRequest -Method GET -Uri "/v1.0/servicePrincipals/$($sp.id)/synchronization/jobs").value | Select-Object -First 1).id } catch {}
        if (-not $jobId) {
            Write-Host "  on-demand: no synchronization job found (enable provisioning first)." -ForegroundColor Yellow
        } elseif ($PSCmdlet.ShouldProcess($UserUpn, "Provision on demand")) {
            $od = @{ parameters = @(@{ subjects = @(@{ objectId = $user.id; objectTypeName = 'User' }); ruleId = $null }) } | ConvertTo-Json -Depth 6
            try { Invoke-MgGraphRequest -Method POST -Uri "/v1.0/servicePrincipals/$($sp.id)/synchronization/jobs/$jobId/provisionOnDemand" -Body $od -ContentType 'application/json' | Out-Null
                  Write-Host ("  DONE : requested on-demand provisioning for '{0}'." -f $UserUpn) -ForegroundColor Green }
            catch { Write-Host ("  NOTE : on-demand provisioning not available / failed: {0}" -f $_.Exception.Message) -ForegroundColor Yellow }
        } else {
            Write-Host ("  WOULD: request on-demand provisioning for '{0}'." -f $UserUpn) -ForegroundColor Cyan
        }
    }
}

Write-Host "`nFederation and existing-Apple-ID conflict resolution are ABM-side (deferred to Apple's documentation)." -ForegroundColor DarkGray
Write-Host "Re-run ABMPROV-Validation.ps1 / ABMPROV-Report.ps1 to confirm." -ForegroundColor Green
Disconnect-MgGraph | Out-Null
