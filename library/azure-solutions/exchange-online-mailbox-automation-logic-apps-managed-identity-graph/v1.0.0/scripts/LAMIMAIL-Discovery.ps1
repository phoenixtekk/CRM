<#
.SYNOPSIS
    LAMIMAIL-Discovery.ps1 — read-only discovery of the Logic App managed identity, the application
    Graph permissions (app roles) assigned to it, and whether the target mailbox is reachable/scoped.
.DESCRIPTION
    PURPOSE
        Read-only readiness snapshot for the "Exchange Online Mailbox Automation with Logic Apps
        Managed Identity (Graph)" solution. Reports:
          * the managed identity's service principal (system- or user-assigned) by display name;
          * the Microsoft Graph APPLICATION permissions (app-role assignments) granted to that
            identity — highlighting anything broader than the least-privilege 'Mail.Read';
          * whether the target mailbox resolves in the directory (reachability check).
        Makes NO changes.
    HOW TO RUN
        powershell -ExecutionPolicy Bypass -File .\LAMIMAIL-Discovery.ps1 `
            -IdentityDisplayName 'la-mailbox-automation-pilot' `
            -TargetMailbox 'automation-inbox@contoso.com'
    REQUIRED GRAPH SCOPES (delegated, for the operator running this script)
        Application.Read.All, AppRoleAssignment.Read.All, User.Read.All, Directory.Read.All
        (verify the exact scope names against current Microsoft Graph documentation)
    EXPECTED RESULTS
        A printed snapshot: the identity's service principal, each Graph app-role granted to it (with
        a warning if any grant is broader than Mail.Read), and whether the target mailbox resolves —
        the readiness picture before validating least privilege and scope.
.NOTES
    Azure Solutions — read-only. The repeatable way.
    Reports on configuration/identifiers only; makes no changes to identities, permissions, or mailboxes.
#>
[CmdletBinding()]
param(
    [Parameter(Mandatory)] [string]$IdentityDisplayName,   # e.g. la-mailbox-automation-pilot (or id-mailbox-automation-pilot)
    [Parameter(Mandatory)] [string]$TargetMailbox,         # e.g. automation-inbox@contoso.com
    [string]$LeastPrivPermission = 'Mail.Read'
)

if (-not (Get-Module -ListAvailable -Name Microsoft.Graph)) {
    Write-Host "Microsoft.Graph module not found. Install with: Install-Module Microsoft.Graph -Scope CurrentUser" -ForegroundColor Red
    return
}
Import-Module Microsoft.Graph.Authentication -ErrorAction Stop

# Connect read-only. Verify the exact scope names against current Microsoft Graph documentation.
try {
    Connect-MgGraph -Scopes 'Application.Read.All','AppRoleAssignment.Read.All','User.Read.All','Directory.Read.All' -NoWelcome -ErrorAction Stop
} catch {
    Write-Host ("Connect-MgGraph failed: {0}" -f $_.Exception.Message) -ForegroundColor Red
    return
}

Write-Host "`n=== LAMIMAIL — discovery (read-only) ===" -ForegroundColor Cyan
Write-Host ("Identity display name: {0}" -f $IdentityDisplayName)
Write-Host ("Target mailbox:        {0}" -f $TargetMailbox)

# --- The managed identity's service principal ---
Write-Host "`n-- Managed identity service principal --" -ForegroundColor Cyan
$sp = Get-MgServicePrincipal -Filter "displayName eq '$IdentityDisplayName'" -All -ErrorAction SilentlyContinue | Select-Object -First 1
if (-not $sp) {
    Write-Host ("   No service principal named '{0}'. Confirm the managed identity is enabled (Logic App > Identity)." -f $IdentityDisplayName) -ForegroundColor Yellow
} else {
    Write-Host ("   DisplayName : {0}" -f $sp.DisplayName)
    Write-Host ("   ObjectId    : {0}" -f $sp.Id)
    Write-Host ("   AppId       : {0}" -f $sp.AppId)
    Write-Host ("   SPType      : {0}" -f $sp.ServicePrincipalType)
}

# --- Graph application permissions (app-role assignments) granted to the identity ---
Write-Host "`n-- Graph application permissions (app roles) on the identity --" -ForegroundColor Cyan
if ($sp) {
    $graphSp = Get-MgServicePrincipal -Filter "appId eq '00000003-0000-0000-c000-000000000000'" -ErrorAction SilentlyContinue | Select-Object -First 1
    $assignments = Get-MgServicePrincipalAppRoleAssignment -ServicePrincipalId $sp.Id -All -ErrorAction SilentlyContinue
    if (-not $assignments) {
        Write-Host "   (no application permissions granted — the identity cannot yet read any mail)" -ForegroundColor Yellow
    } else {
        foreach ($a in $assignments) {
            $roleName = ($graphSp.AppRoles | Where-Object Id -eq $a.AppRoleId | Select-Object -First 1).Value
            if (-not $roleName) { $roleName = $a.AppRoleId }
            if ($roleName -eq $LeastPrivPermission) {
                Write-Host ("   {0}   (least-privilege target)" -f $roleName) -ForegroundColor Green
            } else {
                Write-Host ("   {0}   <-- broader than {1} — review" -f $roleName, $LeastPrivPermission) -ForegroundColor Yellow
            }
        }
    }
}

# --- Target mailbox reachability (does it resolve in the directory?) ---
Write-Host "`n-- Target mailbox reachability --" -ForegroundColor Cyan
$u = Get-MgUser -Filter "userPrincipalName eq '$TargetMailbox' or mail eq '$TargetMailbox'" -ErrorAction SilentlyContinue | Select-Object -First 1
if ($u) {
    Write-Host ("   Resolves: {0} (Id {1})" -f $u.UserPrincipalName, $u.Id) -ForegroundColor Green
    Write-Host "   NOTE: directory resolution is not the same as scoped access — run LAMIMAIL-Test-MailboxAccess.ps1 to prove the boundary." -ForegroundColor DarkGray
} else {
    Write-Host ("   '{0}' did not resolve as a user/mailbox. Confirm Exchange Online and the mailbox exist." -f $TargetMailbox) -ForegroundColor Yellow
}

Write-Host "`nDiscovery complete (read-only)." -ForegroundColor Green
