<#
.SYNOPSIS
    GRAPHPOLL-Set-AppRole.ps1 — assign (or verify) the least-privilege Microsoft Graph APPLICATION
    permission (app role, e.g. Mail.Read) to the Logic App's managed identity. The ONLY state-changer in
    this solution — DEFAULTS TO -WhatIf.
.DESCRIPTION
    PURPOSE
        Grants the managed identity the application permission the polling workflow needs, as an app-role
        assignment on the Microsoft Graph service principal. An app-role assignment IS the tenant admin's
        consent for that application permission, so this both grants and consents in one step.
        DEFAULTS TO -WhatIf: it prints exactly what it would assign and changes nothing until you pass
        -Execute.
        This grant is tenant-wide for the permission until you SCOPE it to one mailbox — do that per
        product #4 "Scoping Application-Permission Mailbox Access". Granting Mail.Read here without scoping
        lets the identity read every mailbox; scope it before you pilot.
    HOW TO RUN
        Preview (default, no change):
            powershell -ExecutionPolicy Bypass -File .\GRAPHPOLL-Set-AppRole.ps1 `
                -ManagedIdentityObjectId '<managed identity object id>' `
                -PermissionName 'Mail.Read'
        Apply for real (explicit):
            ... -Execute
        Requires the Microsoft.Graph PowerShell SDK. The signed-in account needs rights to assign app
        roles / grant application permissions (e.g. Privileged Role Administrator or Global Administrator).
        For a national cloud, pass -Environment.
    GRAPH SCOPES (delegated, for THIS script's sign-in)
        AppRoleAssignment.ReadWrite.All, Application.Read.All, Directory.Read.All.
        (These let the script create the app-role assignment; the workflow itself then uses the APPLICATION
        Mail.Read permission this script grants.)
    EXPECTED RESULTS
        In -WhatIf mode (default): a printed description of the app-role assignment it would create (managed
        identity -> Graph app role <PermissionName>) — nothing changes. With -Execute: the assignment is
        created (idempotent — if it already exists it reports so). Verify the exact least-privilege
        permission name against current Microsoft documentation before granting.
.NOTES
    Azure Solutions — DEFAULTS TO -WhatIf. The repeatable way.
    The only state-changing script in this solution. Grants exactly one named app role to one identity;
    touches nothing else. Scope the grant to ONE mailbox afterward (product #4). White-label: contoso.com
    only.
#>
[CmdletBinding()]
param(
    [Parameter(Mandatory)] [string]$ManagedIdentityObjectId,
    [string]$PermissionName = 'Mail.Read',   # verify least-privilege name against current MS docs
    [string]$Environment = 'Global',
    [switch]$Execute                          # omit for -WhatIf (default safe mode)
)

if (-not (Get-Module -ListAvailable -Name Microsoft.Graph)) {
    Install-Module Microsoft.Graph -Scope CurrentUser -Force -AllowClobber
}
Import-Module Microsoft.Graph.Authentication -ErrorAction Stop
if (-not (Get-MgContext)) {
    Connect-MgGraph -Environment $Environment `
        -Scopes 'AppRoleAssignment.ReadWrite.All','Application.Read.All','Directory.Read.All' | Out-Null
}

$whatIf = -not $Execute
$graphAppId = '00000003-0000-0000-c000-000000000000'   # Microsoft Graph well-known appId

Write-Host "`n=== Graph Mailbox Polling — assign application permission (app role) ===" -ForegroundColor Cyan
Write-Host ("Managed identity : {0}" -f $ManagedIdentityObjectId)
Write-Host ("Permission       : {0}  (verify least-privilege name against current MS docs)" -f $PermissionName)
Write-Host ("Mode             : {0}" -f $(if ($whatIf) {'WhatIf (no change)'} else {'EXECUTE'}))

# Resolve the Graph service principal and the target app role id.
try {
    $graphSp = Get-MgServicePrincipal -Filter "appId eq '$graphAppId'" -ErrorAction Stop
} catch {
    Write-Host ("Could not resolve the Microsoft Graph service principal: {0}" -f $_.Exception.Message) -ForegroundColor Red
    return
}
$role = $graphSp.AppRoles | Where-Object { $_.Value -eq $PermissionName -and $_.AllowedMemberTypes -contains 'Application' } | Select-Object -First 1
if (-not $role) {
    Write-Host ("Application app role '{0}' not found on Microsoft Graph. Verify the exact name against current Microsoft documentation." -f $PermissionName) -ForegroundColor Red
    return
}

# Already assigned?
$existing = Get-MgServicePrincipalAppRoleAssignment -ServicePrincipalId $ManagedIdentityObjectId -All -ErrorAction SilentlyContinue |
            Where-Object { $_.AppRoleId -eq $role.Id -and $_.ResourceId -eq $graphSp.Id }
if ($existing) {
    Write-Host ("Already assigned: '{0}' is granted to this identity. Nothing to do." -f $PermissionName) -ForegroundColor Green
    return
}

if ($whatIf) {
    Write-Host ("[WhatIf] Would assign app role '{0}' (id {1}) on Microsoft Graph to identity {2}. No change made. Re-run with -Execute." -f `
        $PermissionName, $role.Id, $ManagedIdentityObjectId) -ForegroundColor Yellow
    Write-Host "[WhatIf] Reminder: scope this grant to ONE mailbox afterward (product #4)." -ForegroundColor Yellow
} else {
    try {
        New-MgServicePrincipalAppRoleAssignment -ServicePrincipalId $ManagedIdentityObjectId -BodyParameter @{
            principalId = $ManagedIdentityObjectId
            resourceId  = $graphSp.Id
            appRoleId   = $role.Id
        } -ErrorAction Stop | Out-Null
        Write-Host ("Assigned app role '{0}' to identity {1} (granted + consented)." -f $PermissionName, $ManagedIdentityObjectId) -ForegroundColor Green
        Write-Host "NEXT: scope this grant to ONE mailbox (product #4) before piloting." -ForegroundColor Yellow
    } catch {
        Write-Host ("Assignment failed: {0}" -f $_.Exception.Message) -ForegroundColor Red
    }
}

Write-Host ("`nSet-AppRole complete ({0})." -f $(if ($whatIf) {'WhatIf — no changes'} else {'executed'})) -ForegroundColor $(if ($whatIf) {'Yellow'} else {'Green'})
