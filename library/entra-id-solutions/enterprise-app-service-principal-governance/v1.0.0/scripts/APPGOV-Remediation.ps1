<#
.SYNOPSIS
    APPGOV-Remediation.ps1 — safely revoke risky delegated grants and app-role assignments.
.DESCRIPTION
    PURPOSE
        Removes risky permissions from a named, confirmed over-permissioned app: its delegated
        oauth2PermissionGrants and/or its application-permission appRoleAssignments. It is intended to
        be run against apps you have already reviewed from APPGOV-Report.ps1 and confirmed with the
        owner. Defaults to -WhatIf, so a plain run only PREVIEWS what it would revoke and changes
        nothing.
    HOW TO RUN
        Preview (default, no changes):
            powershell -ExecutionPolicy Bypass -File .\APPGOV-Remediation.ps1 -AppId <appId>
        Apply after review:
            powershell -ExecutionPolicy Bypass -File .\APPGOV-Remediation.ps1 -AppId <appId> -WhatIf:$false
        Scope: -RevokeDelegated / -RevokeAppRoles (default: both). Consents to
        Application.ReadWrite.All, DelegatedPermissionGrant.ReadWrite.All, Directory.Read.All.
    EXPECTED RESULTS
        In preview: the exact delegated grants and app-role assignments that WOULD be revoked. When
        applied: those grants/assignments are removed; re-run APPGOV-Validation.ps1 -CheckAppId to
        confirm. Reversible by re-granting the permission in the portal.
.NOTES
    Workplace Marketplace — Entra ID Solutions. Write action — preview (-WhatIf) by default.
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
Connect-MgGraph -Scopes 'Application.ReadWrite.All','DelegatedPermissionGrant.ReadWrite.All','Directory.Read.All' -NoWelcome

Write-Host "`n=== App Governance Remediation — $(Get-Date -Format s) ===" -ForegroundColor Cyan
if (-not $PSBoundParameters.ContainsKey('WhatIf') -and -not $WhatIfPreference) {
    # nothing — respects -WhatIf:$false explicitly
}
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

Write-Host "`nRe-run APPGOV-Validation.ps1 -CheckAppId $AppId to confirm." -ForegroundColor Cyan
Disconnect-MgGraph | Out-Null
