<#
.SYNOPSIS
    GWSSO-Remediation.ps1 — safely bring a reviewed user or group into SSO/provisioning scope.
.DESCRIPTION
    PURPOSE
        Applies the safe, reversible remediation for a common Entra-side gap: a reviewed user or group
        that is NOT assigned to the 'Google Cloud / G Suite Connector by Microsoft' app and therefore is
        not federated or provisioned. It assigns that principal to the app (the default app role), which
        brings them into SSO and SCIM provisioning scope on the next cycle. It is intended for a
        principal you have already reviewed in GWSSO-Report.ps1 and confirmed with the identity owner.
        Defaults to -WhatIf, so a plain run only PREVIEWS the assignment and changes nothing. Domain
        moves (onmicrosoft -> custom), NameID mapping, the Google SSO profile, and GCDS are configured in
        the Entra SSO blade / Google Admin console / GCDS, not by this script.
    HOW TO RUN
        Preview (default, no changes):
            powershell -ExecutionPolicy Bypass -File .\GWSSO-Remediation.ps1 -PrincipalUpn user@your-domain.com
            powershell -ExecutionPolicy Bypass -File .\GWSSO-Remediation.ps1 -GroupName 'Entra Google SSO Pilot Scope - Pilot'
        Apply after review:
            powershell -ExecutionPolicy Bypass -File .\GWSSO-Remediation.ps1 -PrincipalUpn user@your-domain.com -WhatIf:$false
        Required Graph scopes: AppRoleAssignment.ReadWrite.All, Application.Read.All, Directory.Read.All,
        User.Read.All, Group.Read.All. Use 'your-tenant-id' if prompted.
    EXPECTED RESULTS
        In preview: the exact principal that WOULD be assigned to the Google connector app. When applied:
        the app-role assignment is created; re-run GWSSO-Validation.ps1 to confirm the user is in scope.
        Reversible by removing the assignment (Enterprise app -> Users and groups) in the portal.
.NOTES
    White-label — the repeatable way. Write action — preview (-WhatIf) by default.
#>
[CmdletBinding(SupportsShouldProcess = $true, ConfirmImpact = 'High')]
param(
    [string]$PrincipalUpn,
    [string]$GroupName,
    [string]$AppFilter = 'Google'
)

if (-not $PrincipalUpn -and -not $GroupName) {
    Write-Host "Specify -PrincipalUpn or -GroupName (the reviewed user/group to bring into scope)." -ForegroundColor Yellow
    return
}

Import-Module Microsoft.Graph.Authentication -ErrorAction Stop
Connect-MgGraph -Scopes 'AppRoleAssignment.ReadWrite.All','Application.Read.All','Directory.Read.All','User.Read.All','Group.Read.All' -NoWelcome

Write-Host "`n=== Entra->Google SSO/Provisioning Remediation — $(Get-Date -Format s) ===" -ForegroundColor Cyan

$sp = Get-MgServicePrincipal -All -ErrorAction SilentlyContinue | Where-Object { $_.DisplayName -like "*$AppFilter*" } | Select-Object -First 1
if (-not $sp) { Write-Host "Google connector app not found." -ForegroundColor Yellow; Disconnect-MgGraph | Out-Null; return }
Write-Host ("Target app: {0}  (appId {1})" -f $sp.DisplayName, $sp.AppId) -ForegroundColor White

# Resolve the principal (user or group) to assign.
$principalId = $null; $principalLabel = $null; $principalType = $null
if ($PrincipalUpn) {
    $u = Get-MgUser -Filter "userPrincipalName eq '$PrincipalUpn'" -ErrorAction SilentlyContinue | Select-Object -First 1
    if (-not $u) { Write-Host "User $PrincipalUpn not found." -ForegroundColor Yellow; Disconnect-MgGraph | Out-Null; return }
    if ($PrincipalUpn -like '*.onmicrosoft.com') { Write-Host "  WARNING: this UPN is on onmicrosoft.com — Google rejects it. Move to a verified custom domain first." -ForegroundColor Yellow }
    $principalId = $u.Id; $principalLabel = $u.UserPrincipalName; $principalType = 'user'
} else {
    $g = Get-MgGroup -Filter "displayName eq '$GroupName'" -ErrorAction SilentlyContinue | Select-Object -First 1
    if (-not $g) { Write-Host "Group '$GroupName' not found." -ForegroundColor Yellow; Disconnect-MgGraph | Out-Null; return }
    $principalId = $g.Id; $principalLabel = $g.DisplayName; $principalType = 'group'
}

# Already assigned?
$existing = Get-MgServicePrincipalAppRoleAssignedTo -ServicePrincipalId $sp.Id -All -ErrorAction SilentlyContinue |
    Where-Object { $_.PrincipalId -eq $principalId }
if ($existing) {
    Write-Host ("  Already in scope: {0} ({1}) is assigned to the app — nothing to do." -f $principalLabel, $principalType) -ForegroundColor Green
    Disconnect-MgGraph | Out-Null; return
}

# Use the default app role (id all-zero GUID = default access).
$appRoleId = '00000000-0000-0000-0000-000000000000'

if ($PSCmdlet.ShouldProcess("$principalType '$principalLabel' -> app '$($sp.DisplayName)'", 'Assign (bring into SSO/provisioning scope)')) {
    New-MgServicePrincipalAppRoleAssignedTo -ServicePrincipalId $sp.Id -BodyParameter @{
        principalId = $principalId
        resourceId  = $sp.Id
        appRoleId   = $appRoleId
    } -ErrorAction Stop | Out-Null
    Write-Host ("  ASSIGNED: {0} ({1}) now in scope for SSO/provisioning." -f $principalLabel, $principalType) -ForegroundColor Green
} else {
    Write-Host ("  [WhatIf] would assign {0} ({1}) to {2}." -f $principalLabel, $principalType, $sp.DisplayName) -ForegroundColor Yellow
}

Write-Host "`nRe-run GWSSO-Validation.ps1 to confirm. Reversible: remove the assignment in Enterprise app -> Users and groups." -ForegroundColor Cyan
Write-Host "Domain moves, NameID mapping, the Google SSO profile, and GCDS are configured in the Entra/Google consoles." -ForegroundColor DarkGray
Disconnect-MgGraph | Out-Null
