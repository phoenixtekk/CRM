<#
.SYNOPSIS
    APPGOVG-Remediation.ps1 — safely revoke risky delegated grants and app-role assignments (GCC High).
.DESCRIPTION
    PURPOSE
        Removes risky permissions from a named, confirmed over-permissioned app on a US Government
        (GCC High) tenant: its delegated oauth2PermissionGrants and/or its application-permission
        appRoleAssignments. Intended for apps you have already reviewed from APPGOVG-Report.ps1 and
        confirmed with the owner. Defaults to -WhatIf, so a plain run only PREVIEWS what it would
        revoke and changes nothing. Connects to US Gov Microsoft Graph (graph.microsoft.us).
    HOW TO RUN
        Preview (default, no changes):
            powershell -ExecutionPolicy Bypass -File .\APPGOVG-Remediation.ps1 -AppId your-app-id
        Apply after review:
            powershell -ExecutionPolicy Bypass -File .\APPGOVG-Remediation.ps1 -AppId your-app-id -WhatIf:$false
        Scope: -RevokeDelegated / -RevokeAppRoles (default: both). Graph scopes:
        Application.ReadWrite.All, DelegatedPermissionGrant.ReadWrite.All, Directory.Read.All;
        connects with -Environment USGov.
    EXPECTED RESULTS
        In preview: the exact delegated grants and app-role assignments that WOULD be revoked. When
        applied: those grants/assignments are removed; re-run APPGOVG-Validation.ps1 -CheckAppId to
        confirm. Reversible by re-granting the permission in the portal.
.NOTES
    White-label — the repeatable way. Write action — preview (-WhatIf) by default. US Gov Graph endpoints.
#>
[CmdletBinding(SupportsShouldProcess = $true, ConfirmImpact = 'High')]
param(
    [Parameter(Mandatory)] [string]$AppId,
    [switch]$RevokeDelegated,
    [switch]$RevokeAppRoles
)

# Default: act on both categories if neither switch is specified.
if (-not $RevokeDelegated -and -not $RevokeAppRoles) { $RevokeDelegated = $true; $RevokeAppRoles = $true }

Import-Module Microsoft.Graph.Authentication -ErrorAction Stop
Connect-MgGraph -Environment USGov -Scopes 'Application.ReadWrite.All','DelegatedPermissionGrant.ReadWrite.All','Directory.Read.All' -NoWelcome

$ctx = Get-MgContext
if ($ctx.Environment -ne 'USGov') {
    Write-Host ("WARNING: connected environment is '{0}', expected 'USGov' (GCC High). Reconnect with -Environment USGov." -f $ctx.Environment) -ForegroundColor Yellow
}

Write-Host "`n=== App Governance Remediation (GCC High) — $(Get-Date -Format s) ===" -ForegroundColor Cyan
$sp = Get-MgServicePrincipal -Filter "appId eq '$AppId'" -ErrorAction SilentlyContinue
if (-not $sp) { Write-Host "App not found for appId $AppId." -ForegroundColor Yellow; Disconnect-MgGraph | Out-Null; return }
Write-Host ("Target: {0}  (appId {1})" -f $sp.DisplayName, $sp.AppId) -ForegroundColor White

if ($RevokeDelegated) {
    Write-Host "`n-- Delegated grants (oauth2PermissionGrants) --" -ForegroundColor Cyan
    $grants = Get-MgOauth2PermissionGrant -Filter "clientId eq '$($sp.Id)'" -All -ErrorAction SilentlyContinue
    if (-not $grants) { Write-Host "  none" }
    foreach ($g in $grants) {
        if ($PSCmdlet.ShouldProcess("delegated grant [$($g.Scope)] -> resource $($g.ResourceId)", 'Revoke')) {
            Remove-MgOauth2PermissionGrant -OAuth2PermissionGrantId $g.Id -ErrorAction Stop
            Write-Host ("  REVOKED delegated: {0}" -f $g.Scope) -ForegroundColor Green
        } else {
            Write-Host ("  [WhatIf] would revoke delegated: {0}" -f $g.Scope) -ForegroundColor Yellow
        }
    }
}

if ($RevokeAppRoles) {
    Write-Host "`n-- Application permissions (appRoleAssignments) --" -ForegroundColor Cyan
    $assignments = Get-MgServicePrincipalAppRoleAssignment -ServicePrincipalId $sp.Id -All -ErrorAction SilentlyContinue
    if (-not $assignments) { Write-Host "  none" }
    foreach ($a in $assignments) {
        if ($PSCmdlet.ShouldProcess("app-role assignment $($a.Id) -> resource $($a.ResourceDisplayName)", 'Revoke')) {
            Remove-MgServicePrincipalAppRoleAssignment -ServicePrincipalId $sp.Id -AppRoleAssignmentId $a.Id -ErrorAction Stop
            Write-Host ("  REVOKED app-role on: {0}" -f $a.ResourceDisplayName) -ForegroundColor Green
        } else {
            Write-Host ("  [WhatIf] would revoke app-role on: {0}" -f $a.ResourceDisplayName) -ForegroundColor Yellow
        }
    }
}

Write-Host "`nRe-run APPGOVG-Validation.ps1 -CheckAppId $AppId to confirm." -ForegroundColor Cyan
Disconnect-MgGraph | Out-Null
