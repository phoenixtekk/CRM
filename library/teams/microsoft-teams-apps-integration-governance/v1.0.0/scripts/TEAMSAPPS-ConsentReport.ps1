<#
.SYNOPSIS
    TEAMSAPPS-ConsentReport.ps1 — read-only consent/Graph-permission review for Teams apps; risk-flags high-impact permissions.
.DESCRIPTION
    PURPOSE
        Reviews what Teams apps can actually reach: for each enterprise application (service principal),
        lists its DELEGATED permissions (oauth2PermissionGrants) and APPLICATION permissions
        (appRoleAssignments) against Microsoft Graph, and risk-flags any that appear in the high-risk
        scope list (mail, files, directory, chat, full-access). Read-only — makes no changes. Writes the
        report "Consent Review - Teams Apps - Report". Whether a permission is ACCEPTABLE is a
        security/compliance decision — this surfaces and flags; it does not approve or revoke.
    HOW TO RUN
        .\TEAMSAPPS-ConsentReport.ps1 -CsvPath C:\Temp\TEAMSAPPS-Consent.csv
        (PowerShell 5.1+/7+; Microsoft Graph SDK)
        Connect: Connect-MgGraph -Scopes Application.Read.All, Directory.Read.All,
        DelegatedPermissionGrant.Read.All, AppRoleAssignment.Read.All
    EXPECTED RESULTS
        Console summary of apps holding high-risk permissions, and an optional CSV with one row per
        (app, permission, type, risk flag). No changes are made.
.NOTES
    Teams — Microsoft Teams Apps & Integration Governance. Read-only; the approval decision is deferred to security/compliance.
#>
[CmdletBinding()]
param(
    [string]$CsvPath,
    [string[]]$HighRiskScopes = @(
        'Mail.Read','Mail.ReadWrite','Mail.Send','Files.Read.All','Files.ReadWrite.All',
        'Sites.Read.All','Sites.ReadWrite.All','Sites.FullControl.All','Chat.Read.All','ChannelMessage.Read.All',
        'Directory.Read.All','Directory.ReadWrite.All','User.Read.All','User.ReadWrite.All',
        'Group.ReadWrite.All','full_access_as_app','Application.ReadWrite.All'
    )
)

if (-not (Get-Module -ListAvailable -Name Microsoft.Graph.Authentication)) { Install-Module Microsoft.Graph -Scope CurrentUser -Force -AllowClobber }
Import-Module Microsoft.Graph.Authentication -ErrorAction Stop
Connect-MgGraph -Scopes 'Application.Read.All','Directory.Read.All','DelegatedPermissionGrant.Read.All','AppRoleAssignment.Read.All' -NoWelcome

Write-Host '=== TEAMSAPPS Consent Review — Consent Review - Teams Apps - Report (read-only) ===' -ForegroundColor Cyan

# Build a map of the Microsoft Graph service principal's appRole ids -> permission value (for application permissions).
$graphSp = (Invoke-MgGraphRequest -Method GET -Uri "/v1.0/servicePrincipals?`$filter=appId eq '00000003-0000-0000-c000-000000000000'&`$select=id,appRoles,oauth2PermissionScopes").value | Select-Object -First 1
$appRoleMap = @{}; $graphSp.appRoles           | ForEach-Object { $appRoleMap[$_.id] = $_.value }
$scopeMap   = @{}; $graphSp.oauth2PermissionScopes | ForEach-Object { $scopeMap[$_.id]  = $_.value }

$rows = @()
$uri = "/v1.0/servicePrincipals?`$select=id,displayName,appId,tags,servicePrincipalType&`$top=100"
do {
    $r = Invoke-MgGraphRequest -Method GET -Uri $uri
    foreach ($sp in $r.value) {
        # Delegated permissions granted to this app (oauth2PermissionGrants where clientId = sp.id).
        $grants = (Invoke-MgGraphRequest -Method GET -Uri ("/v1.0/oauth2PermissionGrants?`$filter=clientId eq '{0}'" -f $sp.id)).value
        foreach ($grant in $grants) {
            foreach ($scope in ($grant.scope -split ' ' | Where-Object { $_ })) {
                $rows += [pscustomobject]@{ App=$sp.displayName; AppId=$sp.appId; Permission=$scope; Type='Delegated'; RiskFlag=$(if ($HighRiskScopes -contains $scope) { 'HIGH-RISK' } else { '' }) }
            }
        }
        # Application permissions (appRoleAssignments) this app holds on other resources.
        $roles = (Invoke-MgGraphRequest -Method GET -Uri ("/v1.0/servicePrincipals/{0}/appRoleAssignments" -f $sp.id)).value
        foreach ($ra in $roles) {
            $permVal = if ($appRoleMap.ContainsKey($ra.appRoleId)) { $appRoleMap[$ra.appRoleId] } else { $ra.appRoleId }
            $rows += [pscustomobject]@{ App=$sp.displayName; AppId=$sp.appId; Permission=$permVal; Type='Application'; RiskFlag=$(if ($HighRiskScopes -contains $permVal) { 'HIGH-RISK' } else { '' }) }
        }
    }
    $uri = $r.'@odata.nextLink'
} while ($uri)

$high = @($rows | Where-Object { $_.RiskFlag -eq 'HIGH-RISK' })
Write-Host ('--- {0} permission grants across apps; {1} HIGH-RISK ---' -f $rows.Count, $high.Count) -ForegroundColor $(if ($high.Count) { 'Yellow' } else { 'Green' })
$high | Sort-Object App | Select-Object App, Permission, Type | Format-Table -AutoSize

if ($CsvPath) { $rows | Export-Csv -Path $CsvPath -NoTypeInformation; Write-Host ("Saved 'Consent Review - Teams Apps - Report' to {0}" -f $CsvPath) -ForegroundColor Green }

Disconnect-MgGraph | Out-Null
