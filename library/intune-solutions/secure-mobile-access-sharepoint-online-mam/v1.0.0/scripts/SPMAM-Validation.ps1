<#
.SYNOPSIS
    SPMAM-Validation.ps1 — per-user check that App Protection is applied AND the CA app-protection
    grant is effective for SharePoint Online mobile (Microsoft Graph). Read-only.
.DESCRIPTION
    PURPOSE
        For one user, confirms (1) an App Protection Policy (MAM) is assigned via a group the user
        belongs to, and (2) at least one enabled Conditional Access policy targets Office 365 with an
        app-protection / approved-app grant and includes the user. This is the "is this user set up
        to reach SharePoint Online on mobile?" check.
    HOW TO RUN
        powershell -ExecutionPolicy Bypass -File .\SPMAM-Validation.ps1 -UserPrincipalName user@contoso.com
        Requires the Microsoft Graph PowerShell SDK. Consented scopes (read-only):
        DeviceManagementApps.Read.All, Policy.Read.All, Group.Read.All, User.Read.All.
    EXPECTED RESULTS
        "MOBILE ACCESS READY" when the user has an App Protection Policy AND is in scope of an
        enabled CA app-protection grant for Office 365; otherwise the missing piece is named.
.NOTES
    Phoenixtekk Workplace Marketplace — Intune Solutions. Read-only against Graph.
#>
[CmdletBinding()] param(
    [Parameter(Mandatory=$true)][string]$UserPrincipalName
)

if (-not (Get-Module -ListAvailable -Name Microsoft.Graph.Authentication)) {
    Install-Module Microsoft.Graph -Scope CurrentUser -Force -AllowClobber
}
Import-Module Microsoft.Graph.Authentication -ErrorAction Stop
Connect-MgGraph -Scopes 'DeviceManagementApps.Read.All','Policy.Read.All','Group.Read.All','User.Read.All' -NoWelcome

Write-Host "=== SPMAM Validation — $UserPrincipalName ===" -ForegroundColor Cyan

# Resolve user + their transitive group membership
$user = Invoke-MgGraphRequest -Method GET -Uri "/v1.0/users/$UserPrincipalName`?`$select=id,displayName"
$memberIds = @()
$uri = "/v1.0/users/$($user.id)/transitiveMemberOf?`$select=id"
do { $r = Invoke-MgGraphRequest -Method GET -Uri $uri; $memberIds += ($r.value | ForEach-Object { $_.id }); $uri = $r.'@odata.nextLink' } while ($uri)

# 1) App Protection Policy applied via a group the user is in
$appApplied = $false
foreach ($seg in 'iosManagedAppProtections','androidManagedAppProtections') {
    try {
        $pols = (Invoke-MgGraphRequest -Method GET -Uri "/beta/deviceAppManagement/$seg`?`$expand=assignments").value
        foreach ($p in $pols) {
            $gids = $p.assignments | ForEach-Object { $_.target.groupId } | Where-Object { $_ }
            if ($gids | Where-Object { $memberIds -contains $_ }) { $appApplied = $true; Write-Host ("  App Protection : APPLIED via {0}" -f $p.displayName) -ForegroundColor Green }
        }
    } catch {}
}
if (-not $appApplied) { Write-Host "  App Protection : NOT APPLIED (no APP assigned to this user)" -ForegroundColor Yellow }

# 2) Enabled CA policy: Office 365 + app-protection/approved-app grant + includes the user
$caEffective = $false
$ca = (Invoke-MgGraphRequest -Method GET -Uri '/v1.0/identity/conditionalAccess/policies').value
foreach ($c in $ca) {
    if ($c.state -ne 'enabled') { continue }
    $hasGrant = ($c.grantControls.builtInControls -contains 'compliantApplication') -or ($c.grantControls.builtInControls -contains 'approvedApplication')
    if (-not $hasGrant) { continue }
    $apps = @($c.conditions.applications.includeApplications)
    $targetsO365 = ($apps -contains 'Office365') -or ($apps -contains 'All') -or ($apps -contains '00000003-0000-0ff1-ce00-000000000000')
    if (-not $targetsO365) { continue }
    $inc = @($c.conditions.users.includeGroups); $exc = @($c.conditions.users.excludeGroups)
    $incAll = $c.conditions.users.includeUsers -contains 'All'
    $included = $incAll -or ($inc | Where-Object { $memberIds -contains $_ }) -or ($c.conditions.users.includeUsers -contains $user.id)
    $excluded = ($exc | Where-Object { $memberIds -contains $_ }) -or ($c.conditions.users.excludeUsers -contains $user.id)
    if ($included -and -not $excluded) { $caEffective = $true; Write-Host ("  CA grant       : EFFECTIVE via {0}" -f $c.displayName) -ForegroundColor Green }
}
if (-not $caEffective) { Write-Host "  CA grant       : NOT EFFECTIVE (no enabled Office 365 app-protection grant includes this user)" -ForegroundColor Yellow }

if ($appApplied -and $caEffective) { Write-Host "`nResult: MOBILE ACCESS READY" -ForegroundColor Green; Disconnect-MgGraph | Out-Null; exit 0 }
else { Write-Host "`nResult: NOT READY — assign the App Protection Policy and/or include the user in the CA app-protection grant (see 03-implementation)." -ForegroundColor Yellow; Disconnect-MgGraph | Out-Null; exit 1 }
