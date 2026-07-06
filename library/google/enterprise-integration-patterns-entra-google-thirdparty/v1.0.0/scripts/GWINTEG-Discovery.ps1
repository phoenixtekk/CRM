<#
.SYNOPSIS
    GWINTEG-Discovery.ps1 — inventory the Entra-side integration estate (SSO, provisioning, federation).
.DESCRIPTION
    PURPOSE
        Read-only inventory of the Microsoft Entra ID side of the integration estate that the pattern
        catalog governs. Per enterprise application (service principal) it reports the single sign-on
        mode (SAML / OIDC / password / none), whether a SCIM provisioning (synchronization) job exists,
        the application (app-role) permissions it holds, the delegated OAuth grants, the owners, and the
        client-secret and certificate expiry. This is the baseline you classify against patterns P1-P7.
        Google-side SSO profiles and third-party-app capabilities are recorded separately in the
        capability matrix; this script covers the Microsoft/Entra plane only.
    HOW TO RUN
        Install-Module Microsoft.Graph -Scope CurrentUser   # once
        powershell -ExecutionPolicy Bypass -File .\GWINTEG-Discovery.ps1
        Optional: -CsvPath .\gwinteg-inventory.csv to export a flat CSV.
        Required Graph scopes (read-only): Application.Read.All, Directory.Read.All, Policy.Read.All,
        Synchronization.Read.All. Use 'your-tenant-id' if prompted to select a tenant.
    EXPECTED RESULTS
        A per-application listing of SSO mode, provisioning presence, application/delegated permissions,
        owners, and credential expiry. No changes are made (read-only) — pass.
.NOTES
    White-label — the repeatable way. Read-only against Microsoft Graph.
#>
[CmdletBinding()]
param(
    [string]$CsvPath
)

Import-Module Microsoft.Graph.Authentication -ErrorAction Stop
Connect-MgGraph -Scopes 'Application.Read.All','Directory.Read.All','Policy.Read.All','Synchronization.Read.All' -NoWelcome

Write-Host "`n=== Integration Estate Inventory (Entra side) — $(Get-Date -Format s) ===" -ForegroundColor Cyan

# Cache resource service principals so application-permission (app-role) names are readable.
$resourceRoleCache = @{}
function Get-AppRoleName($resourceSpId, $appRoleId) {
    if (-not $resourceRoleCache.ContainsKey($resourceSpId)) {
        $resourceRoleCache[$resourceSpId] = Get-MgServicePrincipal -ServicePrincipalId $resourceSpId -ErrorAction SilentlyContinue
    }
    $rsp = $resourceRoleCache[$resourceSpId]
    $role = $rsp.AppRoles | Where-Object { $_.Id -eq $appRoleId }
    if ($role) { "$($rsp.DisplayName)/$($role.Value)" } else { "$($rsp.DisplayName)/unknown-role" }
}

$rows = @()
$sps = Get-MgServicePrincipal -All
Write-Host ("Enterprise applications (service principals) found: {0}`n" -f $sps.Count)

foreach ($sp in $sps) {
    # SSO mode — the federation pattern signal (P1 / P5 candidates federate over saml/oidc).
    $ssoMode = if ($sp.PreferredSingleSignOnMode) { $sp.PreferredSingleSignOnMode } else { 'none' }

    # Provisioning — is there a SCIM synchronization job on this app (P2 / P6 signal)?
    $syncJobs = @()
    try {
        $syncJobs = @(Get-MgServicePrincipalSynchronizationJob -ServicePrincipalId $sp.Id -ErrorAction SilentlyContinue)
    } catch { $syncJobs = @() }
    $hasProvisioning = ($syncJobs.Count -gt 0)

    # Application permissions this app HOLDS (blast-radius / least-privilege signal).
    $appRoles = Get-MgServicePrincipalAppRoleAssignment -ServicePrincipalId $sp.Id -All -ErrorAction SilentlyContinue
    $appPerms = @($appRoles | ForEach-Object { Get-AppRoleName $_.ResourceId $_.AppRoleId })

    # Delegated permissions granted to this app.
    $grants = Get-MgOauth2PermissionGrant -Filter "clientId eq '$($sp.Id)'" -All -ErrorAction SilentlyContinue
    $delegated = @($grants | ForEach-Object { ($_.Scope).Trim() } | Where-Object { $_ })

    # Owners — an unowned integration is a governance risk.
    $owners = Get-MgServicePrincipalOwner -ServicePrincipalId $sp.Id -All -ErrorAction SilentlyContinue
    $ownerNames = @($owners | ForEach-Object { $_.AdditionalProperties.userPrincipalName ?? $_.AdditionalProperties.displayName })

    # Credentials — credential-sprawl / expiry signal.
    $secrets = @($sp.PasswordCredentials)
    $certs   = @($sp.KeyCredentials)
    $nextExpiry = ($secrets + $certs | Where-Object EndDateTime | Sort-Object EndDateTime | Select-Object -First 1).EndDateTime

    Write-Host ("• {0}" -f $sp.DisplayName) -ForegroundColor White
    Write-Host ("    appId {0}  |  SSO: {1}  |  provisioning: {2}  |  owners: {3}" -f `
        $sp.AppId, $ssoMode, ($(if($hasProvisioning){'yes (SCIM job)'}else{'no'})), ($(if($ownerNames){$ownerNames -join ', '}else{'<none>'})))
    Write-Host ("    application permissions ({0}): {1}" -f $appPerms.Count, ($(if($appPerms){$appPerms -join '; '}else{'none'})))
    Write-Host ("    delegated permissions        : {0}" -f ($(if($delegated){$delegated -join ' '}else{'none'})))
    Write-Host ("    secrets: {0}  certs: {1}  next expiry: {2}" -f `
        $secrets.Count, $certs.Count, ($(if($nextExpiry){$nextExpiry.ToString('yyyy-MM-dd')}else{'none'})))

    $rows += [pscustomobject]@{
        DisplayName            = $sp.DisplayName
        AppId                  = $sp.AppId
        ServicePrincipalId     = $sp.Id
        SsoMode                = $ssoMode
        HasProvisioning        = $hasProvisioning
        Owners                 = ($ownerNames -join '; ')
        ApplicationPermissions = ($appPerms -join '; ')
        DelegatedPermissions   = ($delegated -join ' ')
        SecretCount            = $secrets.Count
        CertificateCount       = $certs.Count
        NextCredentialExpiry   = $nextExpiry
    }
}

if ($CsvPath) {
    $rows | Export-Csv -Path $CsvPath -NoTypeInformation -Encoding UTF8
    Write-Host ("`nExported {0} rows to {1}" -f $rows.Count, $CsvPath) -ForegroundColor Green
}
Write-Host "`nNext: classify each app against patterns P1-P7 with GWINTEG-Report.ps1." -ForegroundColor Cyan
Disconnect-MgGraph | Out-Null
