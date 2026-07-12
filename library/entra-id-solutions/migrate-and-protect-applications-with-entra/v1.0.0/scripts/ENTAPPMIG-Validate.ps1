<#
.SYNOPSIS
    ENTAPPMIG-Validate.ps1 — validate the named migrated objects from 03-implementation are present and wired.
.DESCRIPTION
    PURPOSE
        The automated form of the §5 gate table. Checks that: the migrated AD FS app has an SSO mode and the
        ENTAPPMIG-Pilot group assigned; the App Proxy app has pre-authentication = Entra and a connector
        group; the SCIM app has provisioning enabled and scoped; and the ENTAPPMIG Conditional Access policy
        targets the migrated apps AND excludes a break-glass group. Prints PASS/GAP per check.
    HOW TO RUN
        powershell -ExecutionPolicy Bypass -File .\ENTAPPMIG-Validate.ps1 `
            -PilotGroup 'ENTAPPMIG-Pilot' -BreakGlassGroup 'BreakGlass-Exclude'
    EXPECTED RESULTS
        A checklist of [PASS]/[GAP] lines mirroring the pilot exit criteria. PASS on all = ready to cut over.
.NOTES
    White-label — Entra ID Solutions. Read-only against Microsoft Graph. No credentials stored.
.EXAMPLE
    .\ENTAPPMIG-Validate.ps1
#>
[CmdletBinding()]
param(
    [string]$PilotGroup = 'ENTAPPMIG-Pilot',
    [string]$BreakGlassGroup,
    [string]$SamlAppName    = 'ENTAPPMIG - App - LOBSaml - Pilot',
    [string]$AppProxyName   = 'ENTAPPMIG - AppProxy - Intranet - Pilot',
    [string]$ScimAppName    = 'ENTAPPMIG - App - ScimSaaS - Pilot'
)

if (-not (Get-Module -ListAvailable -Name Microsoft.Graph.Authentication)) {
    Install-Module Microsoft.Graph -Scope CurrentUser -Force -AllowClobber
}
Import-Module Microsoft.Graph.Authentication -ErrorAction Stop
Connect-MgGraph -Scopes 'Application.Read.All','Directory.Read.All','Policy.Read.All','Group.Read.All' -NoWelcome

function Get-AllPages([string]$Uri) { $i=@(); do { $r=Invoke-MgGraphRequest -Method GET -Uri $Uri; $i+=$r.value; $Uri=$r.'@odata.nextLink' } while ($Uri); return $i }
function Result($ok,$msg){ if($ok){Write-Host "  [PASS] $msg" -ForegroundColor Green}else{Write-Host "  [GAP ] $msg" -ForegroundColor Yellow} }
function Get-Sp($name){ (Invoke-MgGraphRequest -Method GET -Uri "/v1.0/servicePrincipals?`$filter=displayName eq '$name'").value | Select-Object -First 1 }
function Has-PilotAssigned($sp){
    if (-not $sp) { return $false }
    $a = Get-AllPages "/v1.0/servicePrincipals/$($sp.id)/appRoleAssignedTo"
    return [bool]($a | Where-Object principalDisplayName -eq $PilotGroup)
}

Write-Host "`n=== ENTAPPMIG validation ===" -ForegroundColor Cyan

# 1. Migrated AD FS (SAML/OIDC) app
$saml = Get-Sp $SamlAppName
Result ([bool]$saml) "Migrated AD FS app '$SamlAppName' exists"
if ($saml) {
    Result ([bool]$saml.preferredSingleSignOnMode) "  SSO mode set ($($saml.preferredSingleSignOnMode))"
    Result (Has-PilotAssigned $saml) "  '$PilotGroup' assigned"
}

# 2. App Proxy published app
$proxy = Get-Sp $AppProxyName
Result ([bool]$proxy) "App Proxy app '$AppProxyName' exists"
if ($proxy) {
    $app = (Invoke-MgGraphRequest -Method GET -Uri "/beta/applications?`$filter=displayName eq '$AppProxyName'").value | Select-Object -First 1
    if ($app) {
        try {
            $pub = Invoke-MgGraphRequest -Method GET -Uri "/beta/applications/$($app.id)/onPremisesPublishing"
            Result ($pub.externalAuthenticationType -eq 'aadPreAuthentication') "  Pre-authentication = Microsoft Entra ID"
            Result ([bool]$pub.internalUrl -and [bool]$pub.externalUrl) "  Internal + external URL configured"
        } catch { Result $false "  onPremisesPublishing readable ($($_.Exception.Message))" }
    }
    Result (Has-PilotAssigned $proxy) "  '$PilotGroup' assigned"
}

# 3. SCIM provisioning app
$scim = Get-Sp $ScimAppName
Result ([bool]$scim) "SCIM app '$ScimAppName' exists"
if ($scim) {
    try {
        $jobs = Get-AllPages "/v1.0/servicePrincipals/$($scim.id)/synchronization/jobs"
        Result ([bool]$jobs) "  Provisioning (synchronization) job configured"
        if ($jobs) { Result ($jobs[0].schedule.state -eq 'Active') "  Provisioning job Active ($($jobs[0].schedule.state))" }
    } catch { Result $false "  synchronization job readable ($($_.Exception.Message))" }
    Result (Has-PilotAssigned $scim) "  '$PilotGroup' assigned (scoped provisioning)"
}

# 4. Conditional Access
$ca = Get-AllPages "/v1.0/identity/conditionalAccess/policies"
$entca = $ca | Where-Object displayName -like 'ENTAPPMIG*'
Result ([bool]$entca) "ENTAPPMIG Conditional Access policy exists ($($entca.Count))"
foreach ($p in $entca) {
    $ids = @($saml.appId; $proxy.appId; $scim.appId) | Where-Object { $_ }
    $inc = $p.conditions.applications.includeApplications
    $targets = [bool]($ids | Where-Object { $inc -contains $_ }) -or ($inc -contains 'All')
    Result $targets "  '$($p.displayName)' targets the migrated apps"
    if ($BreakGlassGroup) {
        $bg = (Invoke-MgGraphRequest -Method GET -Uri "/v1.0/groups?`$filter=displayName eq '$BreakGlassGroup'&`$select=id").value | Select-Object -First 1
        Result ($bg -and ($p.conditions.users.excludeGroups -contains $bg.id)) "  excludes break-glass group '$BreakGlassGroup'"
    }
}

Write-Host "`nValidation complete. Resolve every [GAP] before cutover or expansion." -ForegroundColor Cyan
Disconnect-MgGraph | Out-Null
