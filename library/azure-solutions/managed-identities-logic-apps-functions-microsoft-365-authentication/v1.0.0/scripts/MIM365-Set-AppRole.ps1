<#
.SYNOPSIS
    MIM365-Set-AppRole.ps1 — assign (or verify) a least-privilege application app-role on Microsoft
    Graph to a managed identity. The ONLY state-changer in this solution. DEFAULTS TO -WhatIf.
.DESCRIPTION
    PURPOSE
        Grants a single application Graph permission to a managed identity's service principal by
        creating an app-role assignment — the equivalent of granting the application permission and
        admin-consenting it for that identity. Grant ONE least-privilege role at a time (e.g.
        Mail.Read); never a broad tenant-wide grant. If the role is already assigned, it reports that
        and makes no change (idempotent / verify mode).
        DEFAULTS TO -WhatIf — it prints the grant it WOULD make and changes NOTHING until you pass
        -Execute. This is stated here and echoed at run time.
        For MAILBOX permissions, granting is only half the job: scope the grant to specific mailboxes
        per companion product #4 ("Scoping Application-Permission Mailbox Access") before production.
    HOW TO RUN
        Preview (default, no change):
            powershell -ExecutionPolicy Bypass -File .\MIM365-Set-AppRole.ps1 -ManagedIdentityObjectId '<identity object id>' -GraphAppRole 'Mail.Read'
        Apply for real (explicit):
            powershell -ExecutionPolicy Bypass -File .\MIM365-Set-AppRole.ps1 -ManagedIdentityObjectId '<identity object id>' -GraphAppRole 'Mail.Read' -Execute
        Requires the Microsoft.Graph SDK. Run Connect-MgGraph first, or the script will prompt.
    GRAPH SCOPES (required to READ app-roles and WRITE the assignment)
        Application.Read.All, AppRoleAssignment.ReadWrite.All, Directory.Read.All
        (Granting an application permission / app-role assignment is a privileged, admin-consented
        action — verify the exact role name/scope for your call against current Microsoft documentation.)
    EXPECTED RESULTS
        In -WhatIf mode (default): a printed description of the app-role that WOULD be granted — no
        change. With -Execute: the app-role assignment is created (or reported as already present).
.NOTES
    Azure Solutions — DEFAULTS TO -WhatIf; the only state-changing script here. The repeatable way.
    Grants exactly one least-privilege application app-role to the named identity; touches nothing else.
    Mailbox scoping is out of scope here — see companion product #4. White-label sample tenant: contoso.com.
#>
[CmdletBinding()]
param(
    [Parameter(Mandatory)] [string]$ManagedIdentityObjectId,   # the managed identity's service principal Object ID
    [string]$GraphAppRole = 'Mail.Read',                       # the ONE least-privilege application permission to grant
    [switch]$Execute                                           # omit for -WhatIf (default safe mode)
)

if (-not (Get-Module -ListAvailable -Name 'Microsoft.Graph')) { Install-Module Microsoft.Graph -Scope CurrentUser -Force -AllowClobber }
Import-Module Microsoft.Graph.Applications -ErrorAction Stop

$whatIf = -not $Execute
Write-Host ("`n=== MIM365 Set-AppRole ({0}) ===" -f $(if($whatIf){'WhatIf — no changes'}else{'EXECUTE'})) -ForegroundColor Cyan
if ($whatIf) { Write-Host "Running in default -WhatIf mode. No change will be made. Re-run with -Execute to apply." -ForegroundColor Yellow }

$scopes = if ($whatIf) { @('Application.Read.All','Directory.Read.All') } else { @('Application.Read.All','AppRoleAssignment.ReadWrite.All','Directory.Read.All') }
if (-not (Get-MgContext)) { Connect-MgGraph -Scopes $scopes | Out-Null }

# Resolve the Microsoft Graph service principal (app-roles are defined on it).
$graphSp = Get-MgServicePrincipal -Filter "appId eq '00000003-0000-0000-c000-000000000000'" -ErrorAction Stop
$role = $graphSp.AppRoles | Where-Object { $_.Value -eq $GraphAppRole -and $_.AllowedMemberTypes -contains 'Application' }
if (-not $role) {
    Write-Host ("App-role '{0}' not found as an APPLICATION permission on Microsoft Graph. Verify the exact permission name against current Microsoft documentation." -f $GraphAppRole) -ForegroundColor Red
    return
}

# Confirm the target managed-identity service principal exists.
$miSp = Get-MgServicePrincipal -ServicePrincipalId $ManagedIdentityObjectId -ErrorAction SilentlyContinue
if (-not $miSp) {
    Write-Host ("Managed-identity service principal '{0}' not found. Pass the identity's Object (principal) ID." -f $ManagedIdentityObjectId) -ForegroundColor Red
    return
}

# Already granted?
$existing = Get-MgServicePrincipalAppRoleAssignment -ServicePrincipalId $ManagedIdentityObjectId -ErrorAction SilentlyContinue |
            Where-Object { $_.ResourceId -eq $graphSp.Id -and $_.AppRoleId -eq $role.Id }
if ($existing) {
    Write-Host ("Already granted: '{0}' is assigned to '{1}'. No change needed." -f $GraphAppRole, $miSp.DisplayName) -ForegroundColor Green
    return
}

if ($whatIf) {
    Write-Host ("[WhatIf] Would grant application app-role '{0}' (Graph) to managed identity '{1}' ({2}). No change made. Re-run with -Execute." -f $GraphAppRole, $miSp.DisplayName, $ManagedIdentityObjectId) -ForegroundColor Yellow
    return
}

try {
    New-MgServicePrincipalAppRoleAssignment -ServicePrincipalId $ManagedIdentityObjectId -PrincipalId $ManagedIdentityObjectId -ResourceId $graphSp.Id -AppRoleId $role.Id -ErrorAction Stop | Out-Null
    Write-Host ("Granted application app-role '{0}' (Graph) to managed identity '{1}'." -f $GraphAppRole, $miSp.DisplayName) -ForegroundColor Green
    Write-Host "Reminder: for mailbox permissions, scope this grant to specific mailboxes per companion product #4 before production." -ForegroundColor Cyan
} catch {
    Write-Host ("Grant failed: {0}" -f $_.Exception.Message) -ForegroundColor Red
}
