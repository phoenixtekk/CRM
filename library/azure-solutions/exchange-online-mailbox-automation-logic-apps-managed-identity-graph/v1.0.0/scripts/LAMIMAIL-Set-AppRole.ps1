<#
.SYNOPSIS
    LAMIMAIL-Set-AppRole.ps1 — assign (or verify/remove) the least-privilege APPLICATION Graph
    permission (app role, e.g. Mail.Read) on the Logic App's managed identity. DEFAULTS TO -WhatIf.
.DESCRIPTION
    PURPOSE
        The one state-changing helper for the "Exchange Online Mailbox Automation with Logic Apps
        Managed Identity (Graph)" solution. It grants the Microsoft Graph APPLICATION permission
        'Mail.Read' (an app-role assignment) to the managed identity's service principal — the grant
        that lets the identity read mail without a stored credential. It can also -Verify (report only)
        or -Remove (rollback) the grant.

        SAFETY: DEFAULTS TO -WhatIf. With no -Execute switch it prints exactly what it WOULD do and
        changes nothing. Re-run with -Execute to apply. Assigning an application permission is an
        admin-consent-level action and requires a role able to grant application permissions
        (Global Administrator / Privileged Role Administrator).

        NOTE: this grants the app role only. It does NOT scope the mailbox — an application Mail.Read
        grant is tenant-wide until you scope it to one mailbox (Implementation Step 3 / the scoping
        sibling product). Always follow this with the scope and LAMIMAIL-Test-MailboxAccess.ps1.
    HOW TO RUN
        # Preview (default, no change):
        powershell -ExecutionPolicy Bypass -File .\LAMIMAIL-Set-AppRole.ps1 -IdentityDisplayName 'la-mailbox-automation-pilot'
        # Verify only (report the current grant):
        powershell -ExecutionPolicy Bypass -File .\LAMIMAIL-Set-AppRole.ps1 -IdentityDisplayName 'la-mailbox-automation-pilot' -Verify
        # Apply for real:
        powershell -ExecutionPolicy Bypass -File .\LAMIMAIL-Set-AppRole.ps1 -IdentityDisplayName 'la-mailbox-automation-pilot' -Execute
        # Rollback (remove the grant), preview then execute:
        powershell -ExecutionPolicy Bypass -File .\LAMIMAIL-Set-AppRole.ps1 -IdentityDisplayName 'la-mailbox-automation-pilot' -Remove
        powershell -ExecutionPolicy Bypass -File .\LAMIMAIL-Set-AppRole.ps1 -IdentityDisplayName 'la-mailbox-automation-pilot' -Remove -Execute
    REQUIRED GRAPH SCOPES (delegated, for the operator running this script)
        Application.Read.All, AppRoleAssignment.ReadWrite.All, Directory.Read.All
        (verify the exact scope names against current Microsoft Graph documentation)
    EXPECTED RESULTS
        -WhatIf (default): a printed description of the app-role grant/removal — nothing changes.
        -Verify: reports whether the identity already holds Mail.Read.
        -Execute: the app-role assignment is created (or removed with -Remove).
.NOTES
    Azure Solutions — DEFAULTS TO -WhatIf. The repeatable way.
    Grants ONLY the least-privilege Mail.Read application permission; does not scope the mailbox and
    does not grant anything broader. Follow with the mailbox scope + the boundary test.
#>
[CmdletBinding()]
param(
    [Parameter(Mandatory)] [string]$IdentityDisplayName,        # e.g. la-mailbox-automation-pilot
    [string]$Permission = 'Mail.Read',                          # the least-privilege application permission
    [switch]$Verify,                                            # report only
    [switch]$Remove,                                            # rollback: remove the grant
    [switch]$Execute                                            # omit for -WhatIf (default safe mode)
)

if (-not (Get-Module -ListAvailable -Name Microsoft.Graph)) {
    Write-Host "Microsoft.Graph module not found. Install with: Install-Module Microsoft.Graph -Scope CurrentUser" -ForegroundColor Red
    return
}
Import-Module Microsoft.Graph.Authentication -ErrorAction Stop

$scopes = if ($Verify) { @('Application.Read.All','Directory.Read.All') } else { @('Application.Read.All','AppRoleAssignment.ReadWrite.All','Directory.Read.All') }
try { Connect-MgGraph -Scopes $scopes -NoWelcome -ErrorAction Stop }
catch { Write-Host ("Connect-MgGraph failed: {0}" -f $_.Exception.Message) -ForegroundColor Red; return }

$whatIf = -not $Execute

# Resolve the identity's service principal and the Microsoft Graph service principal + app role.
$sp = Get-MgServicePrincipal -Filter "displayName eq '$IdentityDisplayName'" -All -ErrorAction SilentlyContinue | Select-Object -First 1
if (-not $sp) { Write-Host ("No service principal named '{0}'. Enable the Logic App managed identity first (Implementation Step 1)." -f $IdentityDisplayName) -ForegroundColor Red; return }

$graphSp = Get-MgServicePrincipal -Filter "appId eq '00000003-0000-0000-c000-000000000000'" -ErrorAction SilentlyContinue | Select-Object -First 1
$appRole = $graphSp.AppRoles | Where-Object { $_.Value -eq $Permission -and $_.AllowedMemberTypes -contains 'Application' } | Select-Object -First 1
if (-not $appRole) { Write-Host ("Application permission '{0}' not found on Microsoft Graph. Verify the exact permission name against current Microsoft Graph documentation." -f $Permission) -ForegroundColor Red; return }

$existing = Get-MgServicePrincipalAppRoleAssignment -ServicePrincipalId $sp.Id -All -ErrorAction SilentlyContinue |
            Where-Object { $_.AppRoleId -eq $appRole.Id -and $_.ResourceId -eq $graphSp.Id } | Select-Object -First 1

Write-Host "`n=== LAMIMAIL — set app role ($Permission) on $IdentityDisplayName ===" -ForegroundColor Cyan

if ($Verify) {
    if ($existing) { Write-Host ("VERIFY: '{0}' IS granted to {1}." -f $Permission, $IdentityDisplayName) -ForegroundColor Green }
    else           { Write-Host ("VERIFY: '{0}' is NOT granted to {1}." -f $Permission, $IdentityDisplayName) -ForegroundColor Yellow }
    return
}

if ($Remove) {
    if (-not $existing) { Write-Host ("Nothing to remove — '{0}' is not granted." -f $Permission) -ForegroundColor Green; return }
    if ($whatIf) {
        Write-Host ("[WhatIf] Would REMOVE app role '{0}' from {1}. No change made. Re-run with -Execute." -f $Permission, $IdentityDisplayName) -ForegroundColor Yellow
    } else {
        try {
            Remove-MgServicePrincipalAppRoleAssignment -ServicePrincipalId $sp.Id -AppRoleAssignmentId $existing.Id -ErrorAction Stop
            Write-Host ("Removed app role '{0}' from {1}." -f $Permission, $IdentityDisplayName) -ForegroundColor Green
        } catch { Write-Host ("Removal failed: {0}" -f $_.Exception.Message) -ForegroundColor Red }
    }
    return
}

# Default action: assign the app role.
if ($existing) { Write-Host ("'{0}' is already granted to {1}. Nothing to do." -f $Permission, $IdentityDisplayName) -ForegroundColor Green; return }
if ($whatIf) {
    Write-Host ("[WhatIf] Would GRANT application permission '{0}' to {1} (ObjectId {2}). No change made. Re-run with -Execute." -f $Permission, $IdentityDisplayName, $sp.Id) -ForegroundColor Yellow
    Write-Host "         Reminder: this grant is TENANT-WIDE until you scope the mailbox (Step 3 / scoping sibling)." -ForegroundColor Yellow
} else {
    try {
        New-MgServicePrincipalAppRoleAssignment -ServicePrincipalId $sp.Id -PrincipalId $sp.Id -ResourceId $graphSp.Id -AppRoleId $appRole.Id -ErrorAction Stop | Out-Null
        Write-Host ("Granted '{0}' to {1}. NOW scope the mailbox (Step 3) and run LAMIMAIL-Test-MailboxAccess.ps1." -f $Permission, $IdentityDisplayName) -ForegroundColor Green
    } catch { Write-Host ("Grant failed: {0}" -f $_.Exception.Message) -ForegroundColor Red }
}

Write-Host ("`nDone ({0})." -f $(if($whatIf){'WhatIf — no changes'}else{'executed'})) -ForegroundColor ($(if($whatIf){'Yellow'}else{'Green'}))
