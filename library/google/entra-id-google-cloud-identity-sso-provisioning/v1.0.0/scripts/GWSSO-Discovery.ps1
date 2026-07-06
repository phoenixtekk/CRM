<#
.SYNOPSIS
    GWSSO-Discovery.ps1 — identity-readiness discovery for Entra->Google SSO federation & provisioning.
.DESCRIPTION
    PURPOSE
        Read-only discovery of the Microsoft Entra ID side of the Entra->Google identity foundation.
        It locates the 'Google Cloud / G Suite Connector by Microsoft' enterprise application (service
        principal), reports its single sign-on mode (SAML / password / none), whether a SCIM
        provisioning (synchronization) job exists and its state, the count of assigned users and groups,
        and the tenant's verified custom domains (flagging any onmicrosoft.com reliance). This is the
        baseline you assess before configuring SSO and provisioning. Google-side state (the SSO profile,
        provisioned users/groups, GCDS runs) is confirmed in the Google Admin console.
    HOW TO RUN
        Install-Module Microsoft.Graph -Scope CurrentUser   # once
        powershell -ExecutionPolicy Bypass -File .\GWSSO-Discovery.ps1
        Optional: -AppFilter 'Google' to change the display-name match; -CsvPath .\gwsso-domains.csv.
        Required Graph scopes (read-only): Application.Read.All, Directory.Read.All, Policy.Read.All,
        Synchronization.Read.All, User.Read.All. Use 'your-tenant-id' if prompted to select a tenant.
    EXPECTED RESULTS
        The Google connector app(s) with SSO mode, provisioning presence/state, assigned user/group
        counts, and the tenant's verified domains. No changes are made (read-only) — pass.
.NOTES
    White-label — the repeatable way. Read-only against Microsoft Graph.
#>
[CmdletBinding()]
param(
    [string]$AppFilter = 'Google',
    [string]$CsvPath
)

Import-Module Microsoft.Graph.Authentication -ErrorAction Stop
Connect-MgGraph -Scopes 'Application.Read.All','Directory.Read.All','Policy.Read.All','Synchronization.Read.All','User.Read.All' -NoWelcome

Write-Host "`n=== Entra->Google Identity Readiness — $(Get-Date -Format s) ===" -ForegroundColor Cyan

# ---- Verified custom domains (must match Google; onmicrosoft.com is rejected for provisioning/SSO) ----
Write-Host "`n-- Verified custom domains --" -ForegroundColor Cyan
$domains = Get-MgDomain -All -ErrorAction SilentlyContinue
$verified = @($domains | Where-Object { $_.IsVerified })
foreach ($d in $verified) {
    $tag = if ($d.Id -like '*.onmicrosoft.com') { '(onmicrosoft — not usable for Google SSO/provisioning)' } else { '' }
    $def = if ($d.IsDefault) { ' [default]' } else { '' }
    Write-Host ("  {0}{1} {2}" -f $d.Id, $def, $tag)
}
$customVerified = @($verified | Where-Object { $_.Id -notlike '*.onmicrosoft.com' })
if (-not $customVerified) {
    Write-Host "  WARNING: no verified custom domain — federation/provisioning need one verified in BOTH Entra and Google." -ForegroundColor Yellow
}

# ---- The Google connector enterprise application(s) ----
Write-Host ("`n-- Enterprise apps matching '{0}' --" -f $AppFilter) -ForegroundColor Cyan
$sps = @(Get-MgServicePrincipal -All -ErrorAction SilentlyContinue | Where-Object { $_.DisplayName -like "*$AppFilter*" })
if (-not $sps) {
    Write-Host "  none found — add 'Google Cloud / G Suite Connector by Microsoft' from the gallery (Implementation Step 1)." -ForegroundColor Yellow
}

$rows = @()
foreach ($sp in $sps) {
    $ssoMode = if ($sp.PreferredSingleSignOnMode) { $sp.PreferredSingleSignOnMode } else { 'none' }

    # SCIM provisioning (synchronization) job + state.
    $job = $null
    try { $job = Get-MgServicePrincipalSynchronizationJob -ServicePrincipalId $sp.Id -ErrorAction SilentlyContinue | Select-Object -First 1 } catch { $job = $null }
    $provState = if ($job) { "yes ($($job.Status.Code))" } else { 'no' }

    # Assigned users/groups (provisioning/SSO scope signal).
    $assignments = @(Get-MgServicePrincipalAppRoleAssignedTo -ServicePrincipalId $sp.Id -All -ErrorAction SilentlyContinue)
    $userCount  = @($assignments | Where-Object { $_.PrincipalType -eq 'User' }).Count
    $groupCount = @($assignments | Where-Object { $_.PrincipalType -eq 'Group' }).Count

    Write-Host ("• {0}" -f $sp.DisplayName) -ForegroundColor White
    Write-Host ("    appId {0}  |  SSO: {1}  |  provisioning: {2}" -f $sp.AppId, $ssoMode, $provState)
    Write-Host ("    assigned users: {0}  |  assigned groups: {1}" -f $userCount, $groupCount)
    if ($ssoMode -eq 'saml') { Write-Host "    NOTE: confirm the NameID is mapped to user.mail and matches the Google domain." -ForegroundColor DarkGray }

    $rows += [pscustomobject]@{
        DisplayName        = $sp.DisplayName
        AppId              = $sp.AppId
        ServicePrincipalId = $sp.Id
        SsoMode            = $ssoMode
        Provisioning       = $provState
        AssignedUsers      = $userCount
        AssignedGroups     = $groupCount
    }
}

if ($CsvPath) {
    $rows | Export-Csv -Path $CsvPath -NoTypeInformation -Encoding UTF8
    Write-Host ("`nExported {0} app row(s) to {1}" -f $rows.Count, $CsvPath) -ForegroundColor Green
}

Write-Host "`nNext: decide the source of truth, then configure SSO + provisioning (Implementation Steps 2-3)." -ForegroundColor Cyan
Disconnect-MgGraph | Out-Null
