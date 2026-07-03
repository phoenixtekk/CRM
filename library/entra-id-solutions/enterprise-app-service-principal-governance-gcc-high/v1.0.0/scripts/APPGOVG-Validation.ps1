<#
.SYNOPSIS
    APPGOVG-Validation.ps1 — confirm the consent policy, admin-consent workflow, and remediation state (GCC High).
.DESCRIPTION
    PURPOSE
        Read-only check that the governance controls are in place on a US Government (GCC High) tenant:
        (1) the tenant user-consent policy restricts user consent (verified publishers / low-risk
        permissions, not "all apps"), read from the authorizationPolicy; (2) the admin-consent workflow
        is enabled with reviewers; and (3) an optional named app no longer holds a revoked delegated
        grant or app-role assignment. Connects to US Gov Microsoft Graph (graph.microsoft.us).
    HOW TO RUN
        powershell -ExecutionPolicy Bypass -File .\APPGOVG-Validation.ps1
        Optional: -CheckAppId your-app-id to verify a remediated app no longer holds risky grants.
        Graph scopes: Policy.Read.All, Application.Read.All, Directory.Read.All (read-only);
        connects with -Environment USGov.
    EXPECTED RESULTS
        PASS/WARN lines for the user-consent policy and admin-consent workflow, and — if -CheckAppId is
        given — the current app-role assignments and delegated grants for that app. No changes are made.
.NOTES
    White-label — the repeatable way. Read-only against Microsoft Graph US Gov endpoints.
#>
[CmdletBinding()]
param(
    [string]$CheckAppId
)

Import-Module Microsoft.Graph.Authentication -ErrorAction Stop
Connect-MgGraph -Environment USGov -Scopes 'Policy.Read.All','Application.Read.All','Directory.Read.All' -NoWelcome

$ctx = Get-MgContext
if ($ctx.Environment -ne 'USGov') {
    Write-Host ("WARNING: connected environment is '{0}', expected 'USGov' (GCC High). Reconnect with -Environment USGov." -f $ctx.Environment) -ForegroundColor Yellow
}

Write-Host "`n=== App Governance Validation (GCC High) — $(Get-Date -Format s) ===" -ForegroundColor Cyan

# 1. User-consent policy (authorizationPolicy)
$authPolicy = Invoke-MgGraphRequest -Method GET -Uri '/v1.0/policies/authorizationPolicy'
$grantPolicies = $authPolicy.defaultUserRolePermissions.permissionGrantPoliciesAssigned
Write-Host "`n-- User consent policy --" -ForegroundColor Cyan
if (-not $grantPolicies -or $grantPolicies.Count -eq 0) {
    Write-Host "  PASS: user consent is disabled (no permission-grant policy assigned)." -ForegroundColor Green
} elseif ($grantPolicies -match 'ManagePermissionGrantsForSelf.microsoft-user-default-low') {
    Write-Host "  PASS: user consent limited to low-risk / verified-publisher permissions." -ForegroundColor Green
} elseif ($grantPolicies -match 'ManagePermissionGrantsForSelf.microsoft-user-default-legacy') {
    Write-Host "  WARN: user consent allowed for ALL apps (legacy) — restrict this." -ForegroundColor Yellow
} else {
    Write-Host ("  INFO: custom user-consent grant policy assigned: {0}" -f ($grantPolicies -join ', '))
}

# 2. Admin-consent workflow
$adminConsent = Invoke-MgGraphRequest -Method GET -Uri '/v1.0/policies/adminConsentRequestPolicy' -ErrorAction SilentlyContinue
Write-Host "`n-- Admin consent workflow --" -ForegroundColor Cyan
if ($adminConsent.isEnabled) {
    $reviewerCount = @($adminConsent.reviewers).Count
    Write-Host ("  PASS: enabled; reviewer entries: {0}" -f $reviewerCount) -ForegroundColor Green
    if ($reviewerCount -eq 0) { Write-Host "  WARN: no reviewers configured." -ForegroundColor Yellow }
} else {
    Write-Host "  WARN: admin-consent workflow is disabled." -ForegroundColor Yellow
}

# 3. Optional remediation check
if ($CheckAppId) {
    Write-Host "`n-- Remediation check for appId $CheckAppId --" -ForegroundColor Cyan
    $sp = Get-MgServicePrincipal -Filter "appId eq '$CheckAppId'" -ErrorAction SilentlyContinue
    if (-not $sp) { Write-Host "  App not found." -ForegroundColor Yellow }
    else {
        $appRoles = Get-MgServicePrincipalAppRoleAssignment -ServicePrincipalId $sp.Id -All -ErrorAction SilentlyContinue
        $grants   = Get-MgOauth2PermissionGrant -Filter "clientId eq '$($sp.Id)'" -All -ErrorAction SilentlyContinue
        Write-Host ("  application permissions now: {0}" -f @($appRoles).Count)
        Write-Host ("  delegated grants now       : {0}" -f (@($grants | ForEach-Object { $_.Scope }) -join ' '))
    }
}

Disconnect-MgGraph | Out-Null
