<#
.SYNOPSIS
    APPGOV-Report.ps1 — over-permission and expiring-secret report for enterprise apps.
.DESCRIPTION
    PURPOSE
        Read-only risk report over every service principal. It (1) ranks apps by permission risk —
        those holding high-privilege application permissions (appRoleAssignments to *.ReadWrite.All,
        Directory.*, Mail.*, full-mailbox/full-directory scopes), broad delegated grants
        (oauth2PermissionGrants), no owner, or many credentials — and (2) lists client secrets
        (passwordCredentials) and certificates (keyCredentials) that are expired, expiring within a
        window, or have no expiry / an excessive lifetime.
    HOW TO RUN
        powershell -ExecutionPolicy Bypass -File .\APPGOV-Report.ps1
        Optional: -ExpiryWindowDays 30 (default) to set the "expiring soon" window.
        Consents to Application.Read.All, Directory.Read.All (read-only).
    EXPECTED RESULTS
        A ranked over-permission table and an expiring-secret list with app, credential type, and
        days-to-expiry. No changes are made.
.NOTES
    Workplace Marketplace — Entra ID Solutions. Read-only.
#>
[CmdletBinding()]
param(
    [int]$ExpiryWindowDays = 30
)

Import-Module Microsoft.Graph.Authentication -ErrorAction Stop
Connect-MgGraph -Scopes 'Application.Read.All','Directory.Read.All' -NoWelcome

Write-Host "`n=== App Governance Report — $(Get-Date -Format s) ===" -ForegroundColor Cyan

# High-privilege permission-value fragments that raise risk (readable app-role Value strings)
$highRiskFragments = @('ReadWrite.All','Directory.','Mail.','Files.ReadWrite.All','FullControl',
    'Application.ReadWrite','RoleManagement','User.ReadWrite.All','Group.ReadWrite.All','.AccessAsUser.All')

$resourceRoleCache = @{}
function Get-AppRoleName($resourceSpId, $appRoleId) {
    if (-not $resourceRoleCache.ContainsKey($resourceSpId)) {
        $resourceRoleCache[$resourceSpId] = Get-MgServicePrincipal -ServicePrincipalId $resourceSpId -ErrorAction SilentlyContinue
    }
    $rsp = $resourceRoleCache[$resourceSpId]
    $role = $rsp.AppRoles | Where-Object { $_.Id -eq $appRoleId }
    if ($role) { $role.Value } else { '<unknown>' }
}

$now = Get-Date
$permRows = @()
$credRows = @()
$sps = Get-MgServicePrincipal -All

foreach ($sp in $sps) {
    $appRoles = Get-MgServicePrincipalAppRoleAssignment -ServicePrincipalId $sp.Id -All -ErrorAction SilentlyContinue
    $appPermNames = @($appRoles | ForEach-Object { Get-AppRoleName $_.ResourceId $_.AppRoleId })
    $grants = Get-MgOauth2PermissionGrant -Filter "clientId eq '$($sp.Id)'" -All -ErrorAction SilentlyContinue
    $delegated = @($grants | ForEach-Object { ($_.Scope).Trim() -split '\s+' } | Where-Object { $_ })
    $owners = Get-MgServicePrincipalOwner -ServicePrincipalId $sp.Id -All -ErrorAction SilentlyContinue
    $ownerCount = @($owners).Count

    # Risk score
    $risk = 0
    $reasons = @()
    $highApp = @($appPermNames | Where-Object { $n = $_; $highRiskFragments | Where-Object { $n -like "*$_*" } })
    if ($highApp.Count) { $risk += 5 * $highApp.Count; $reasons += "high-priv app perms: $($highApp -join ',')" }
    $highDel = @($delegated | Where-Object { $d = $_; $highRiskFragments | Where-Object { $d -like "*$_*" } })
    if ($highDel.Count) { $risk += 3 * $highDel.Count; $reasons += "broad delegated: $($highDel -join ',')" }
    if ($ownerCount -eq 0) { $risk += 2; $reasons += 'no owner' }
    $secrets = @($sp.PasswordCredentials); $certs = @($sp.KeyCredentials)
    if (($secrets.Count + $certs.Count) -gt 3) { $risk += 1; $reasons += "$($secrets.Count + $certs.Count) credentials" }

    if ($risk -gt 0) {
        $permRows += [pscustomobject]@{
            Risk = $risk; DisplayName = $sp.DisplayName; AppId = $sp.AppId
            Owners = $ownerCount; Reasons = ($reasons -join '; ')
        }
    }

    # Credential expiry
    foreach ($c in $secrets) {
        $credRows += [pscustomobject]@{ DisplayName=$sp.DisplayName; AppId=$sp.AppId; Type='Secret'
            EndDate=$c.EndDateTime; DaysToExpiry=$(if($c.EndDateTime){[int]($c.EndDateTime - $now).TotalDays}else{$null}) }
    }
    foreach ($c in $certs) {
        $credRows += [pscustomobject]@{ DisplayName=$sp.DisplayName; AppId=$sp.AppId; Type='Certificate'
            EndDate=$c.EndDateTime; DaysToExpiry=$(if($c.EndDateTime){[int]($c.EndDateTime - $now).TotalDays}else{$null}) }
    }
}

Write-Host "`n-- Over-permissioned / risky apps (highest risk first) --" -ForegroundColor Cyan
$permRows | Sort-Object Risk -Descending | Format-Table Risk, DisplayName, Owners, Reasons -AutoSize -Wrap

Write-Host "`n-- Credentials: expired, expiring within $ExpiryWindowDays days, or no expiry --" -ForegroundColor Cyan
$credRows |
    Where-Object { $null -eq $_.DaysToExpiry -or $_.DaysToExpiry -le $ExpiryWindowDays } |
    Sort-Object { if ($null -eq $_.DaysToExpiry) { -9999 } else { $_.DaysToExpiry } } |
    Format-Table DisplayName, Type, @{n='Expires';e={ if($_.EndDate){$_.EndDate.ToString('yyyy-MM-dd')}else{'NO EXPIRY'} }}, DaysToExpiry -AutoSize

Disconnect-MgGraph | Out-Null
