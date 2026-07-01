<#
.SYNOPSIS
    APPGOV-Discovery.ps1 — inventory enterprise apps and service principals in Microsoft Entra.
.DESCRIPTION
    PURPOSE
        Read-only inventory of every service principal (enterprise application) in the tenant. Per
        app it reports: the application (app-role) permissions granted via appRoleAssignments, the
        delegated permissions granted via oauth2PermissionGrants, the owners, and the client-secret
        (passwordCredentials) and certificate (keyCredentials) expiry. This is your governance
        baseline.
    HOW TO RUN
        Install-Module Microsoft.Graph -Scope CurrentUser   # once
        powershell -ExecutionPolicy Bypass -File .\APPGOV-Discovery.ps1
        Optional: -CsvPath .\appgov-inventory.csv to export a flat CSV.
        Consents to Application.Read.All, Directory.Read.All, Policy.Read.All (read-only).
    EXPECTED RESULTS
        A per-service-principal listing of application permissions, delegated grants, owners, and
        credential expiry. No changes are made.
.NOTES
    Workplace Marketplace — Entra ID Solutions. Read-only.
#>
[CmdletBinding()]
param(
    [string]$CsvPath
)

Import-Module Microsoft.Graph.Authentication -ErrorAction Stop
Connect-MgGraph -Scopes 'Application.Read.All','Directory.Read.All','Policy.Read.All' -NoWelcome

Write-Host "`n=== Enterprise App & Service Principal Inventory — $(Get-Date -Format s) ===" -ForegroundColor Cyan

# Map appRoleId -> permission name per resource service principal (for readable app-permission names)
$resourceRoleCache = @{}
function Get-AppRoleName($resourceSpId, $appRoleId) {
    if (-not $resourceRoleCache.ContainsKey($resourceSpId)) {
        $rsp = Get-MgServicePrincipal -ServicePrincipalId $resourceSpId -ErrorAction SilentlyContinue
        $resourceRoleCache[$resourceSpId] = $rsp
    }
    $rsp = $resourceRoleCache[$resourceSpId]
    $role = $rsp.AppRoles | Where-Object { $_.Id -eq $appRoleId }
    if ($role) { "$($rsp.DisplayName)/$($role.Value)" } else { "$($rsp.DisplayName)/<unknown role>" }
}

$rows = @()
$sps = Get-MgServicePrincipal -All
Write-Host ("Service principals found: {0}`n" -f $sps.Count)

foreach ($sp in $sps) {
    # Application permissions (app roles this app HOLDS on other resources)
    $appRoles = Get-MgServicePrincipalAppRoleAssignment -ServicePrincipalId $sp.Id -All -ErrorAction SilentlyContinue
    $appPerms = @($appRoles | ForEach-Object { Get-AppRoleName $_.ResourceId $_.AppRoleId })

    # Delegated permissions granted to this app
    $grants = Get-MgOauth2PermissionGrant -Filter "clientId eq '$($sp.Id)'" -All -ErrorAction SilentlyContinue
    $delegated = @($grants | ForEach-Object { ($_.Scope).Trim() } | Where-Object { $_ })

    # Owners
    $owners = Get-MgServicePrincipalOwner -ServicePrincipalId $sp.Id -All -ErrorAction SilentlyContinue
    $ownerNames = @($owners | ForEach-Object { $_.AdditionalProperties.userPrincipalName ?? $_.AdditionalProperties.displayName })

    # Credentials
    $secrets = @($sp.PasswordCredentials)
    $certs   = @($sp.KeyCredentials)
    $nextExpiry = ($secrets + $certs | Where-Object EndDateTime | Sort-Object EndDateTime | Select-Object -First 1).EndDateTime

    Write-Host ("• {0}" -f $sp.DisplayName) -ForegroundColor White
    Write-Host ("    appId {0}  |  owners: {1}" -f $sp.AppId, ($(if($ownerNames){$ownerNames -join ', '}else{'<none>'})))
    Write-Host ("    application permissions ({0}): {1}" -f $appPerms.Count, ($(if($appPerms){$appPerms -join '; '}else{'none'})))
    Write-Host ("    delegated permissions       : {0}" -f ($(if($delegated){$delegated -join ' '}else{'none'})))
    Write-Host ("    secrets: {0}  certs: {1}  next expiry: {2}" -f $secrets.Count, $certs.Count, ($(if($nextExpiry){$nextExpiry.ToString('yyyy-MM-dd')}else{'none'})))

    $rows += [pscustomobject]@{
        DisplayName          = $sp.DisplayName
        AppId                = $sp.AppId
        ServicePrincipalId   = $sp.Id
        Owners               = ($ownerNames -join '; ')
        ApplicationPermissions = ($appPerms -join '; ')
        DelegatedPermissions = ($delegated -join ' ')
        SecretCount          = $secrets.Count
        CertificateCount     = $certs.Count
        NextCredentialExpiry = $nextExpiry
    }
}

if ($CsvPath) {
    $rows | Export-Csv -Path $CsvPath -NoTypeInformation -Encoding UTF8
    Write-Host ("`nExported {0} rows to {1}" -f $rows.Count, $CsvPath) -ForegroundColor Green
}
Disconnect-MgGraph | Out-Null
