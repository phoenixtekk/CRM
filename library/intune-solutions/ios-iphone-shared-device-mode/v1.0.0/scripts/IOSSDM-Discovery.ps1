<#
.SYNOPSIS
    IOSSDM-Discovery.ps1 — tenant readiness check for iOS iPhone Shared Device Mode (lockdown + Webex).

.DESCRIPTION
    PURPOSE
        Confirms the building blocks of the shared-device model exist: the Apple MDM Push (APNs)
        certificate, an Apple ADE enrollment token, the `iOS – Shared Devices` group, the kiosk
        lockdown and device-restrictions profiles, the Cisco Webex app, and an iOS compliance policy.
        (The Device Enrollment Manager account is confirmed in the Intune portal — Devices >
        Enrollment > Device enrollment managers — as it has no stable Graph list endpoint.)

    HOW TO RUN
        Install-Module Microsoft.Graph -Scope CurrentUser   # once
        .\IOSSDM-Discovery.ps1
        Reads only — makes no changes.

    EXPECTED RESULTS
        A PASS/FAIL line per check and an overall verdict. A READY tenant has an active APNs cert,
        an ADE token, the shared-device group, the kiosk + restrictions profiles, the Cisco Webex app,
        and an iOS compliance policy.

.NOTES
    Phoenixtekk Workplace Marketplace — Intune Solutions. Read-only.
#>
[CmdletBinding()]
param(
    [string]$SharedGroupName  = 'iOS – Shared Devices',
    [string]$KioskProfileName = 'iOS Shared – Kiosk Lockdown – Pilot',
    [string]$WebexNameLike    = 'Webex'
)

$ErrorActionPreference = 'Stop'
Connect-MgGraph -Scopes 'DeviceManagementConfiguration.Read.All','DeviceManagementApps.Read.All','DeviceManagementServiceConfig.Read.All','Group.Read.All' | Out-Null

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

# ADE enrollment token
try {
    $dep = GraphGet 'https://graph.microsoft.com/v1.0/deviceManagement/depOnboardingSettings'
    $ok = $dep -and $dep.Count -ge 1
    $results += R 'Apple ADE enrollment token' $ok ($(if ($ok) { "$($dep.Count) token(s) present" } else { 'No ADE token connected' }))
} catch { $results += R 'Apple ADE enrollment token' $false 'Not configured' }

# Shared-device group
$grp = GraphGet ("https://graph.microsoft.com/v1.0/groups?`$filter=displayName eq '{0}'" -f $SharedGroupName.Replace("'","''"))
$results += R "Group '$SharedGroupName'" ([bool]$grp) ($(if ($grp) { "id $($grp[0].id)" } else { 'Not found' }))

# Device configuration profiles (kiosk + restrictions)
$cfg = GraphGet 'https://graph.microsoft.com/v1.0/deviceManagement/deviceConfigurations?$select=id,displayName'
$kiosk = $cfg | Where-Object { $_.displayName -eq $KioskProfileName -or $_.displayName -like '*Kiosk*' }
$restr = $cfg | Where-Object { $_.displayName -like '*Restrictions*' }
$results += R 'Kiosk lockdown profile' ([bool]$kiosk) ($(if ($kiosk) { ($kiosk.displayName -join ', ') } else { 'No kiosk profile found' }))
$results += R 'Device restrictions profile' ([bool]$restr) ($(if ($restr) { ($restr.displayName -join ', ') } else { 'No restrictions profile found' }))

# Cisco Webex app
$apps = GraphGet 'https://graph.microsoft.com/v1.0/deviceAppManagement/mobileApps?$select=id,displayName'
$webex = $apps | Where-Object { $_.displayName -like "*$WebexNameLike*" }
$results += R 'Cisco Webex app added' ([bool]$webex) ($(if ($webex) { ($webex.displayName | Select-Object -First 3) -join ', ' } else { 'Webex not found in Apps' }))

# iOS compliance policy
$comp = GraphGet 'https://graph.microsoft.com/v1.0/deviceManagement/deviceCompliancePolicies?$select=id,displayName'
$iosComp = $comp | Where-Object { $_.'@odata.type' -like '*ios*' -or $_.displayName -like '*iOS*' }
$results += R 'iOS compliance policy' ([bool]$iosComp) ($(if ($iosComp) { ($iosComp.displayName | Select-Object -First 3) -join ', ' } else { 'No iOS compliance policy' }))

$results | Format-Table -AutoSize
$fail = ($results | Where-Object Result -eq 'FAIL').Count
Write-Host ''
if ($fail -eq 0) { Write-Host 'OVERALL: READY — all shared-device building blocks present.' -ForegroundColor Green }
else { Write-Host "OVERALL: NOT READY — $fail check(s) failed. Resolve before piloting." -ForegroundColor Yellow }
Write-Host 'Reminder: confirm the DEM account in Intune > Devices > Enrollment > Device enrollment managers.'
