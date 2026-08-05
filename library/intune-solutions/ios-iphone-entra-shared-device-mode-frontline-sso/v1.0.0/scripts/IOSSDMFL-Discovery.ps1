<#
.SYNOPSIS
    IOSSDMFL-Discovery.ps1 — tenant readiness check for iOS iPhone Entra ID Shared Device Mode.
.DESCRIPTION
    PURPOSE
        Confirms the Intune/Entra tenant is ready to run shared (frontline) iPhones under Entra Shared
        Device Mode: an iOS ADE enrollment profile that enrolls WITHOUT user affinity exists; Microsoft
        Authenticator and Microsoft Teams (iOS) are added; an ASSIGNED device group is present with the
        Intune Provisioning Client (AppId f1346770-5b25-470b-88bd-d5744ab7952c) as an OWNER; and the
        Cloud Device Administrator role has at least one member (the account that registers devices
        into shared mode). Read-only.
    HOW TO RUN
        powershell -ExecutionPolicy Bypass -File .\IOSSDMFL-Discovery.ps1 -GroupName "iPhone SDM - Devices"
        (Install once: Install-Module Microsoft.Graph -Scope CurrentUser)
        Required Graph scopes: DeviceManagementServiceConfig.Read.All, DeviceManagementApps.Read.All,
                               Group.Read.All, RoleManagement.Read.Directory, Application.Read.All
    EXPECTED RESULTS
        A PASS/FAIL line per check and an overall verdict. READY = no-affinity ADE profile present,
        Authenticator + Teams added, the Assigned group owned by the Intune Provisioning Client, and
        Cloud Device Administrator populated.
.NOTES
    White-label — the repeatable way. Read-only against Microsoft Graph.
#>
[CmdletBinding()]
param(
    [string]$GroupName = 'iPhone SDM - Devices'
)

$ErrorActionPreference = 'Stop'
Connect-MgGraph -Scopes 'DeviceManagementServiceConfig.Read.All','DeviceManagementApps.Read.All','Group.Read.All','RoleManagement.Read.Directory','Application.Read.All' | Out-Null

$ProvClientAppId = 'f1346770-5b25-470b-88bd-d5744ab7952c'  # Intune Provisioning Client

function R($Name, $Pass, $Detail) {
    [pscustomobject]@{ Check = $Name; Result = $(if ($Pass) { 'PASS' } else { 'FAIL' }); Detail = $Detail }
}
$results = New-Object System.Collections.Generic.List[object]

# 1) ADE enrollment profile that enrolls without user affinity
$noAffinity = $false; $profName = 'none'
try {
    $tokens = Invoke-MgGraphRequest -Method GET -Uri 'https://graph.microsoft.com/beta/deviceManagement/depOnboardingSettings'
    foreach ($t in @($tokens.value)) {
        $profs = Invoke-MgGraphRequest -Method GET -Uri "https://graph.microsoft.com/beta/deviceManagement/depOnboardingSettings/$($t.id)/enrollmentProfiles"
        foreach ($p in @($profs.value)) {
            if ($p.platform -match 'ios' -or $p.'@odata.type' -match 'ios' -or $null -ne $p.userlessEnrollment -or $p.PSObject.Properties.Name -contains 'requiresUserAuthentication') {
                # userlessEnrollment / requiresUserAuthentication=false indicates no user affinity
                if (($p.userlessEnrollment -eq $true) -or ($p.requiresUserAuthentication -eq $false)) {
                    $noAffinity = $true; $profName = $p.displayName; break
                }
            }
        }
        if ($noAffinity) { break }
    }
} catch { $profName = $_.Exception.Message }
$results.Add( (R 'No-affinity iOS ADE enrollment profile present' $noAffinity "Profile: $profName") )

# 2) Microsoft Authenticator (iOS) and Microsoft Teams (iOS) added
try {
    $apps = Invoke-MgGraphRequest -Method GET -Uri "https://graph.microsoft.com/v1.0/deviceAppManagement/mobileApps?`$filter=(isof('microsoft.graph.iosStoreApp'))"
    $names = @($apps.value | ForEach-Object { $_.displayName })
    $hasAuth = @($names | Where-Object { $_ -match 'Authenticator' }).Count -gt 0
    $hasTeams= @($names | Where-Object { $_ -match 'Teams' }).Count -gt 0
    $results.Add( (R 'Microsoft Authenticator (iOS) added' $hasAuth "Authenticator present: $hasAuth") )
    $results.Add( (R 'Microsoft Teams (iOS) added' $hasTeams "Teams present: $hasTeams") )
} catch {
    $results.Add( (R 'Microsoft Authenticator (iOS) added' $false $_.Exception.Message) )
    $results.Add( (R 'Microsoft Teams (iOS) added' $false 'see above') )
}

# 3) Assigned device group with the Intune Provisioning Client as owner
$grpFound=$false; $isAssigned=$false; $ownerOk=$false
try {
    $g = Invoke-MgGraphRequest -Method GET -Uri "https://graph.microsoft.com/v1.0/groups?`$filter=displayName eq '$GroupName'"
    $grp = @($g.value)[0]
    if ($grp) {
        $grpFound = $true
        $isAssigned = -not $grp.groupTypes -or ($grp.groupTypes -notcontains 'DynamicMembership')
        $owners = Invoke-MgGraphRequest -Method GET -Uri "https://graph.microsoft.com/v1.0/groups/$($grp.id)/owners"
        $ownerOk = @($owners.value | Where-Object { $_.appId -eq $ProvClientAppId }).Count -gt 0
    }
} catch {}
$results.Add( (R "Assigned device group '$GroupName' exists" ($grpFound -and $isAssigned) "found=$grpFound assigned=$isAssigned") )
$results.Add( (R 'Intune Provisioning Client is an OWNER of the group' $ownerOk "owner set: $ownerOk (AppId $ProvClientAppId)") )

# 4) Cloud Device Administrator role populated
$cdaOk=$false
try {
    $roles = Invoke-MgGraphRequest -Method GET -Uri "https://graph.microsoft.com/v1.0/directoryRoles"
    $cda = @($roles.value | Where-Object { $_.displayName -eq 'Cloud Device Administrator' })[0]
    if ($cda) {
        $members = Invoke-MgGraphRequest -Method GET -Uri "https://graph.microsoft.com/v1.0/directoryRoles/$($cda.id)/members"
        $cdaOk = @($members.value).Count -gt 0
    }
} catch {}
$results.Add( (R 'Cloud Device Administrator role has a member' $cdaOk "members present: $cdaOk") )

$results | Format-Table -AutoSize
$fail = @($results | Where-Object Result -eq 'FAIL').Count
Write-Host ''
if ($fail -eq 0) { Write-Host 'OVERALL: READY — tenant is prepared for iPhone Shared Device Mode.' -ForegroundColor Green }
else { Write-Host "OVERALL: NOT READY — $fail check(s) failed. Resolve before piloting." -ForegroundColor Yellow }
