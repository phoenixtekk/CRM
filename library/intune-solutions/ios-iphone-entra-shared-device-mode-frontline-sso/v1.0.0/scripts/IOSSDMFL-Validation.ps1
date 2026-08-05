<#
.SYNOPSIS
    IOSSDMFL-Validation.ps1 — validate the shared-iPhone foundation (group ownership, ADE affinity, apps).
.DESCRIPTION
    PURPOSE
        Validates the three things that most often break an iPhone Shared Device Mode rollout:
        (1) the device group is ASSIGNED and owned by the Intune Provisioning Client (so no-affinity
        devices actually populate it at enrollment); (2) an iOS ADE enrollment profile enrolls WITHOUT
        user affinity; (3) Microsoft Authenticator and Teams are assigned to the group. Read-only.
    HOW TO RUN
        powershell -ExecutionPolicy Bypass -File .\IOSSDMFL-Validation.ps1 -GroupName "iPhone SDM - Devices"
        (Install once: Install-Module Microsoft.Graph -Scope CurrentUser)
        Required Graph scopes: Group.Read.All, Application.Read.All,
                               DeviceManagementServiceConfig.Read.All, DeviceManagementApps.Read.All
    EXPECTED RESULTS
        A PASS/FAIL summary. PASS when the group is Assigned + owned by the Provisioning Client, a
        no-affinity ADE profile exists, and Authenticator + Teams are assigned to the group.
.NOTES
    White-label — the repeatable way. Read-only against Microsoft Graph.
#>
[CmdletBinding()]
param(
    [string]$GroupName = 'iPhone SDM - Devices'
)

$ErrorActionPreference = 'Stop'
Connect-MgGraph -Scopes 'Group.Read.All','Application.Read.All','DeviceManagementServiceConfig.Read.All','DeviceManagementApps.Read.All' | Out-Null

$ProvClientAppId = 'f1346770-5b25-470b-88bd-d5744ab7952c'

function R($Name, $Pass, $Detail) {
    [pscustomobject]@{ Check = $Name; Result = $(if ($Pass) { 'PASS' } else { 'FAIL' }); Detail = $Detail }
}
$results = New-Object System.Collections.Generic.List[object]

# 1) Group present, Assigned, owned by the Provisioning Client
$grp = $null; $isAssigned=$false; $ownerOk=$false
try {
    $g = Invoke-MgGraphRequest -Method GET -Uri "https://graph.microsoft.com/v1.0/groups?`$filter=displayName eq '$GroupName'"
    $grp = @($g.value)[0]
    if ($grp) {
        $isAssigned = ($grp.groupTypes -notcontains 'DynamicMembership')
        $owners = Invoke-MgGraphRequest -Method GET -Uri "https://graph.microsoft.com/v1.0/groups/$($grp.id)/owners"
        $ownerOk = @($owners.value | Where-Object { $_.appId -eq $ProvClientAppId }).Count -gt 0
    }
} catch {}
$results.Add( (R "Group '$GroupName' found" ($null -ne $grp) $(if ($grp) { "id $($grp.id)" } else { 'not found' })) )
$results.Add( (R 'Group Membership type is Assigned' $isAssigned "assigned=$isAssigned") )
$results.Add( (R 'Intune Provisioning Client is an OWNER' $ownerOk "owner=$ownerOk (AppId $ProvClientAppId)") )

# 2) No-affinity iOS ADE profile
$noAffinity=$false; $profName='none'
try {
    $tokens = Invoke-MgGraphRequest -Method GET -Uri 'https://graph.microsoft.com/beta/deviceManagement/depOnboardingSettings'
    foreach ($t in @($tokens.value)) {
        $profs = Invoke-MgGraphRequest -Method GET -Uri "https://graph.microsoft.com/beta/deviceManagement/depOnboardingSettings/$($t.id)/enrollmentProfiles"
        foreach ($p in @($profs.value)) {
            if (($p.userlessEnrollment -eq $true) -or ($p.requiresUserAuthentication -eq $false)) { $noAffinity=$true; $profName=$p.displayName; break }
        }
        if ($noAffinity) { break }
    }
} catch {}
$results.Add( (R 'No-affinity iOS ADE profile exists' $noAffinity "profile: $profName") )

# 3) Authenticator + Teams assigned to the group
$authAssigned=$false; $teamsAssigned=$false
if ($grp) {
    try {
        $apps = Invoke-MgGraphRequest -Method GET -Uri "https://graph.microsoft.com/beta/deviceAppManagement/mobileApps?`$filter=(isof('microsoft.graph.iosStoreApp'))&`$expand=assignments"
        foreach ($a in @($apps.value)) {
            $targets = @($a.assignments | ForEach-Object { $_.target.groupId })
            if ($a.displayName -match 'Authenticator' -and ($targets -contains $grp.id)) { $authAssigned=$true }
            if ($a.displayName -match 'Teams' -and ($targets -contains $grp.id)) { $teamsAssigned=$true }
        }
    } catch {}
}
$results.Add( (R 'Microsoft Authenticator assigned to the group' $authAssigned "assigned=$authAssigned") )
$results.Add( (R 'Microsoft Teams assigned to the group' $teamsAssigned "assigned=$teamsAssigned") )

$results | Format-Table -AutoSize
$fail = @($results | Where-Object Result -eq 'FAIL').Count
Write-Host ''
if ($fail -eq 0) { Write-Host 'OVERALL: PASS — shared-iPhone foundation is correctly configured.' -ForegroundColor Green }
else { Write-Host "OVERALL: NEEDS ATTENTION — $fail check(s) failed (see IOSSDMFL-Remediation.ps1)." -ForegroundColor Yellow }
