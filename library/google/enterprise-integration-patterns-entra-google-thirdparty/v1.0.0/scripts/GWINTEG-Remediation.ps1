<#
.SYNOPSIS
    GWINTEG-Remediation.ps1 — safely bring a reviewed snowflake toward its target pattern.
.DESCRIPTION
    PURPOSE
        Applies the safe, reversible remediation that moves a reviewed integration toward the catalog:
        it revokes the over-broad application-permission app-role assignments and risky delegated OAuth
        grants on a named app (the P7 least-privilege step and the first move off a snowflake). It is
        intended for an app you have already reviewed in GWINTEG-Report.ps1 and confirmed with the app
        owner. Defaults to -WhatIf, so a plain run only PREVIEWS what it would revoke and changes
        nothing. Re-federating an app (moving password SSO to SAML/OIDC, enabling SCIM) and any
        third-party-app or Google-side change are done in those consoles, not by this script.
    HOW TO RUN
        Preview (default, no changes):
            powershell -ExecutionPolicy Bypass -File .\GWINTEG-Remediation.ps1 -AppId your-app-id
        Apply after review:
            powershell -ExecutionPolicy Bypass -File .\GWINTEG-Remediation.ps1 -AppId your-app-id -WhatIf:$false
        Scope switches: -RevokeDelegated / -RevokeAppRoles (default: both).
        Required Graph scopes: Application.ReadWrite.All, DelegatedPermissionGrant.ReadWrite.All,
        Directory.Read.All.
    EXPECTED RESULTS
        In preview: the exact delegated grants and app-role assignments that WOULD be revoked. When
        applied: those grants/assignments are removed; re-run GWINTEG-Validation.ps1 -CheckAppId to
        confirm. Reversible by re-granting the permission in the portal.
.NOTES
    White-label — the repeatable way. Write action — preview (-WhatIf) by default.
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

Write-Host "`n=== Integration Remediation — $(Get-Date -Format s) ===" -ForegroundColor Cyan

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

Write-Host "`nRe-run GWINTEG-Validation.ps1 -CheckAppId $AppId to confirm conformance." -ForegroundColor Cyan
Write-Host "Re-federation (password SSO -> SAML/OIDC) and SCIM enablement are done in the app/Google consoles." -ForegroundColor DarkGray
Disconnect-MgGraph | Out-Null
