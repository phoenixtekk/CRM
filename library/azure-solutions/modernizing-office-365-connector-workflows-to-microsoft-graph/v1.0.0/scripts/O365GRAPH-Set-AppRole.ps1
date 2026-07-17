<#
.SYNOPSIS
    O365GRAPH-Set-AppRole.ps1 — assign (or verify) a Microsoft Graph application app-role on a
    migrated flow's managed identity. THE ONLY STATE-CHANGER — DEFAULTS TO -WhatIf.
.DESCRIPTION
    PURPOSE
        Grants the least-privilege Graph APPLICATION permission a migrated Logic App's managed
        identity ("<FlowName> - Graph MI - Target") needs to do its job — e.g. a mail permission —
        by assigning the corresponding app-role from the Microsoft Graph service principal to the
        managed identity's service principal. If the assignment already exists, it reports it and
        makes no change (idempotent).

        SAFETY: this is the only script in the package that changes state. It DEFAULTS TO -WhatIf
        (dry run) and prints exactly what it WOULD assign; nothing is granted until you re-run with
        -Apply. Even with -Apply it honors -Confirm.

        SCOPING: an app-role grant is tenant-wide by nature. Constrain the identity's actual mailbox
        reach to only the mailbox(es) it needs by ALSO applying the scoping construct from sibling #4
        (Application Access Policy or Graph RBAC-for-Exchange). This script grants the permission;
        #4 scopes it. Never rely on the app-role alone for least privilege on mail.
    HOW TO RUN
        # Dry run (default) — shows the planned assignment, changes nothing:
        powershell -ExecutionPolicy Bypass -File .\O365GRAPH-Set-AppRole.ps1 `
            -ManagedIdentityObjectId '<mi sp object id>' -GraphAppRole 'Mail.Read'
        # Apply, after review:
        powershell -ExecutionPolicy Bypass -File .\O365GRAPH-Set-AppRole.ps1 `
            -ManagedIdentityObjectId '<mi sp object id>' -GraphAppRole 'Mail.Read' -Apply
    SCOPES / ROLES
        Microsoft.Graph: AppRoleAssignment.ReadWrite.All + Application.Read.All, and a role able to
        grant/admin-consent application permissions (e.g. Privileged Role Administrator / Global
        Administrator). Run Connect-MgGraph with those scopes first.
        Modules: Microsoft.Graph (Applications, Authentication).
    EXPECTED RESULTS
        -WhatIf (default): a printed plan — "WOULD assign app-role '<role>' (id <guid>) on Graph SP
        to managed identity <name>". -Apply: the app-role is assigned (or reported already present),
        with the resulting assignment id echoed for the register.
.NOTES
    Azure Solutions — the only state-changer; defaults to -WhatIf. Grants a Graph app-role;
    scope the mailbox reach per sibling #4. Exact permission NAME is a verify-against-current-docs item.
    White-label sample values use contoso.com.
#>
[CmdletBinding(SupportsShouldProcess = $true, ConfirmImpact = 'High')]
param(
    [Parameter(Mandatory)][string]$ManagedIdentityObjectId,   # the MI's service principal object id
    [Parameter(Mandatory)][string]$GraphAppRole,              # e.g. 'Mail.Read' — VERIFY current least-priv name
    [string]$GraphAppId = '00000003-0000-0000-c000-000000000000',  # Microsoft Graph well-known appId
    [switch]$Apply
)

# Default posture is dry-run: unless -Apply is passed, force -WhatIf so nothing changes.
if (-not $Apply) { $WhatIfPreference = $true }

foreach ($m in 'Microsoft.Graph.Authentication','Microsoft.Graph.Applications') {
    if (-not (Get-Module -ListAvailable -Name $m)) { Install-Module Microsoft.Graph -Scope CurrentUser -Force; break }
}
Import-Module Microsoft.Graph.Authentication -ErrorAction Stop
Import-Module Microsoft.Graph.Applications   -ErrorAction Stop

if (-not (Get-MgContext)) {
    Connect-MgGraph -Scopes 'AppRoleAssignment.ReadWrite.All','Application.Read.All' | Out-Null
}

Write-Host "`n=== O365 Connector Workflows -> Graph — Set-AppRole ===" -ForegroundColor Cyan
if (-not $Apply) { Write-Host "MODE: -WhatIf (dry run). Re-run with -Apply to grant. Nothing will change." -ForegroundColor Yellow }

# Resolve the Microsoft Graph service principal and the requested app-role.
$graphSp = Get-MgServicePrincipal -Filter "appId eq '$GraphAppId'" -ErrorAction Stop
$role = $graphSp.AppRoles | Where-Object { $_.Value -eq $GraphAppRole -and $_.AllowedMemberTypes -contains 'Application' }
if (-not $role) {
    throw "App-role '$GraphAppRole' not found on the Graph SP as an Application permission. Verify the current least-privilege permission name against Microsoft documentation."
}

# Resolve the managed identity's service principal.
$miSp = Get-MgServicePrincipal -ServicePrincipalId $ManagedIdentityObjectId -ErrorAction Stop

# Idempotency: is it already assigned?
$existing = Get-MgServicePrincipalAppRoleAssignment -ServicePrincipalId $miSp.Id -All |
            Where-Object { $_.AppRoleId -eq $role.Id -and $_.ResourceId -eq $graphSp.Id }
if ($existing) {
    Write-Host ("ALREADY ASSIGNED: '{0}' on '{1}' (assignment id {2}) — no change." -f $GraphAppRole, $miSp.DisplayName, $existing.Id) -ForegroundColor Green
    Write-Host "Reminder: confirm the mailbox scope for this identity per sibling #4." -ForegroundColor DarkGray
    return
}

$action = "assign Graph app-role '$GraphAppRole' (id $($role.Id)) to managed identity '$($miSp.DisplayName)'"
if ($PSCmdlet.ShouldProcess($miSp.DisplayName, $action)) {
    $res = New-MgServicePrincipalAppRoleAssignment -ServicePrincipalId $miSp.Id -BodyParameter @{
        PrincipalId = $miSp.Id
        ResourceId  = $graphSp.Id
        AppRoleId   = $role.Id
    }
    Write-Host ("ASSIGNED: '{0}' on '{1}' (assignment id {2})." -f $GraphAppRole, $miSp.DisplayName, $res.Id) -ForegroundColor Green
    Write-Host "NEXT: scope this identity's mailbox reach to only what it needs, per sibling #4." -ForegroundColor Cyan
} else {
    Write-Host ("WOULD {0}. (Dry run — re-run with -Apply to grant.)" -f $action) -ForegroundColor Yellow
    Write-Host "AFTER granting: scope the mailbox reach per sibling #4 (Application Access Policy or Graph RBAC)." -ForegroundColor DarkGray
}
