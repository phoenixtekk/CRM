<#
.SYNOPSIS
    IOSLD-Discovery.ps1 — tenant/device readiness for the iOS lock-down (shared + corporate) model.

.DESCRIPTION
    PURPOSE
        Confirms the building blocks of the dual shared-vs-corporate iPhone model exist:
          - Apple MDM Push (APNs) certificate (active)
          - An Apple ADE enrollment token
          - The SHARED and CORPORATE ADE enrollment profiles (by name)
          - The 'iOS - Shared Devices' and 'iOS - Corporate Devices' groups
          - The shared lock-down restrictions profile and the corporate baseline profile
          - iOS compliance policies
        It also summarizes supervised state across enrolled iOS devices.

    HOW TO RUN
        Install-Module Microsoft.Graph -Scope CurrentUser   # once
        .\IOSLD-Discovery.ps1
        Reads only — makes no changes.

    EXPECTED RESULTS
        A PASS/FAIL line per check and an overall verdict. A READY tenant has an active APNs cert,
        an ADE token, both enrollment profiles, both device groups, the lock-down + baseline profiles,
        and iOS compliance policies.

.NOTES
    White-label — Intune Solutions. Read-only.
#>
[CmdletBinding()]
param(
    [string]$SharedGroupName    = 'iOS – Shared Devices',
    [string]$CorporateGroupName = 'iOS – Corporate Devices',
    [string]$SharedAdeProfile   = 'iOS Shared – ADE – Pilot',
    [string]$CorpAdeProfile     = 'iOS Corporate – ADE – Pilot',
    [string]$LockDownProfile    = 'iOS Lock-Down – Shared – Restrictions',
    [string]$BaselineProfile    = 'iOS Corporate – Baseline – Restrictions'
)

$ErrorActionPreference = 'Stop'
Connect-MgGraph -Scopes 'DeviceManagementConfiguration.Read.All','DeviceManagementServiceConfig.Read.All','DeviceManagementManagedDevices.Read.All','Group.Read.All' | Out-Null

function R($Name, $Pass, $Detail) {
    [pscustomobject]@{ Check = $Name; Result = $(if ($Pass) { 'PASS' } else { 'FAIL' }); Detail = $Detail }
}
function GraphGet($uri) { (Invoke-MgGraphRequest -Method GET -Uri $uri).value }

$results = @()

# APNs certificate
try {
    $apns = Invoke-MgGraphRequest -Method GET -Uri 'https://graph.microsoft.com/v1.0/deviceManagement/applePushNotificationCertificate'
    $ok = $apns -and $apns.expirationDateTime -and ([datetime]$apns.expirationDateTime -gt (Get-Date))
    $results += R 'Apple MDM Push (APNs) certificate' $ok ($(if ($ok) { "Active, expires $($apns.expirationDateTime)" } else { 'Missing or expired' }))
} catch { $results += R 'Apple MDM Push (APNs) certificate' $false 'Not configured' }

# ADE enrollment token + profiles
try {
    $dep = GraphGet 'https://graph.microsoft.com/v1.0/deviceManagement/depOnboardingSettings'
    $okToken = $dep -and $dep.Count -ge 1
    $results += R 'Apple ADE enrollment token' $okToken ($(if ($okToken) { "$($dep.Count) token(s) present" } else { 'No ADE token connected' }))

    $profileNames = @()
    foreach ($t in $dep) {
        try { $profileNames += (GraphGet "https://graph.microsoft.com/beta/deviceManagement/depOnboardingSettings/$($t.id)/enrollmentProfiles?`$select=displayName").displayName } catch {}
    }
    $hasShared = $profileNames -contains $SharedAdeProfile
    $hasCorp   = $profileNames -contains $CorpAdeProfile
    $results += R "Shared ADE profile '$SharedAdeProfile'" $hasShared ($(if ($hasShared) { 'Found (no user affinity expected)' } else { "Not found among: $($profileNames -join ', ')" }))
    $results += R "Corporate ADE profile '$CorpAdeProfile'" $hasCorp ($(if ($hasCorp) { 'Found (user affinity expected)' } else { "Not found among: $($profileNames -join ', ')" }))
} catch { $results += R 'Apple ADE enrollment token' $false 'Not configured' }

# Device groups
foreach ($g in @($SharedGroupName, $CorporateGroupName)) {
    $grp = GraphGet ("https://graph.microsoft.com/v1.0/groups?`$filter=displayName eq '{0}'" -f $g.Replace("'","''"))
    $results += R "Group '$g'" ([bool]$grp) ($(if ($grp) { "id $($grp[0].id)" } else { 'Not found' }))
}

# Configuration profiles (lock-down + baseline)
$cfg = GraphGet 'https://graph.microsoft.com/v1.0/deviceManagement/deviceConfigurations?$select=id,displayName'
$lock = $cfg | Where-Object { $_.displayName -eq $LockDownProfile -or $_.displayName -like '*Lock-Down*' -or $_.displayName -like '*Kiosk*' }
$base = $cfg | Where-Object { $_.displayName -eq $BaselineProfile -or $_.displayName -like '*Baseline*' }
$results += R 'Shared lock-down restrictions profile' ([bool]$lock) ($(if ($lock) { ($lock.displayName -join ', ') } else { 'No lock-down/kiosk profile found' }))
$results += R 'Corporate baseline restrictions profile' ([bool]$base) ($(if ($base) { ($base.displayName -join ', ') } else { 'No baseline profile found' }))

# iOS compliance policies
$comp = GraphGet 'https://graph.microsoft.com/v1.0/deviceManagement/deviceCompliancePolicies?$select=id,displayName'
$iosComp = $comp | Where-Object { $_.'@odata.type' -like '*ios*' -or $_.displayName -like '*iOS*' }
$results += R 'iOS compliance policy' ([bool]$iosComp) ($(if ($iosComp) { ($iosComp.displayName | Select-Object -First 3) -join ', ' } else { 'No iOS compliance policy' }))

# Supervised summary
try {
    $ios = GraphGet "https://graph.microsoft.com/v1.0/deviceManagement/managedDevices?`$filter=operatingSystem eq 'iOS'&`$select=isSupervised,userId"
    $sup = ($ios | Where-Object { $_.isSupervised }).Count
    $results += R 'Supervised iOS devices present' ($sup -ge 1) ("$sup supervised of $($ios.Count) iOS device(s)")
} catch { $results += R 'Supervised iOS devices present' $false 'Could not read managed devices' }

$results | Format-Table -AutoSize
$fail = ($results | Where-Object Result -eq 'FAIL').Count
Write-Host ''
if ($fail -eq 0) { Write-Host 'OVERALL: READY — shared + corporate building blocks present.' -ForegroundColor Green }
else { Write-Host "OVERALL: NOT READY — $fail check(s) failed. Resolve before piloting." -ForegroundColor Yellow }
Disconnect-MgGraph | Out-Null
