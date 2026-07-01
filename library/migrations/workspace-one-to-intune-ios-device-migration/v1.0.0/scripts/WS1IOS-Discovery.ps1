<#
.SYNOPSIS
    WS1IOS-Discovery.ps1 — tenant readiness check for a Workspace ONE to Intune iOS/iPadOS migration.

.DESCRIPTION
    PURPOSE
        Confirms the Intune-side building blocks for the migration exist: the Apple MDM Push (APNs)
        certificate, an Apple ADE enrollment token (depOnboardingSettings), a VPP / Apps and Books
        token, the parity device-configuration and compliance objects, and the migration ring groups.
        Workspace ONE / Apple Business Manager re-assignment is performed in those consoles and is
        deferred to the vendor documentation — this script checks only what Microsoft Graph exposes.

    HOW TO RUN
        Install-Module Microsoft.Graph -Scope CurrentUser   # once
        .\WS1IOS-Discovery.ps1
        Reads only — makes no changes.

    EXPECTED RESULTS
        A PASS/FAIL line per check and an overall verdict. A READY tenant has an active APNs cert,
        an ADE token, a VPP token, the parity profiles/compliance, and the pilot/broad ring groups.

.NOTES
    Read-only. The repeatable Workspace ONE to Intune iOS/iPadOS migration.
#>
[CmdletBinding()]
param(
    [string]$PilotRingGroupName  = 'iOS Migration – Pilot Ring – Pilot',
    [string]$BroadRingGroupName  = 'iOS Migration – Broad Ring – Expand',
    [string]$ParityProfileLike   = 'iOS Parity',
    [string]$ComplianceNameLike  = 'iOS Parity – Compliance Baseline – Cutover'
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

# ADE enrollment token (the Intune MDM server connected to ABM)
try {
    $dep = GraphGet 'https://graph.microsoft.com/v1.0/deviceManagement/depOnboardingSettings'
    $ok = $dep -and $dep.Count -ge 1
    $results += R 'Apple ADE enrollment token (ABM connection)' $ok ($(if ($ok) { "$($dep.Count) token(s) present" } else { 'No ADE token connected' }))
} catch { $results += R 'Apple ADE enrollment token (ABM connection)' $false 'Not configured' }

# VPP / Apps and Books token
try {
    $vpp = GraphGet 'https://graph.microsoft.com/v1.0/deviceAppManagement/vppTokens'
    $ok = $vpp -and $vpp.Count -ge 1
    $results += R 'VPP / Apps and Books token' $ok ($(if ($ok) { "$($vpp.Count) token(s) present" } else { 'No VPP token' }))
} catch { $results += R 'VPP / Apps and Books token' $false 'Not configured' }

# iOS ADE enrollment profiles present on the token(s)
try {
    $profCount = 0
    foreach ($t in $dep) {
        $p = GraphGet "https://graph.microsoft.com/v1.0/deviceManagement/depOnboardingSettings/$($t.id)/enrollmentProfiles?`$select=id,displayName"
        $profCount += ($p | Measure-Object).Count
    }
    $results += R 'ADE enrollment profile(s) created' ($profCount -ge 1) ($(if ($profCount -ge 1) { "$profCount profile(s)" } else { 'No ADE enrollment profiles' }))
} catch { $results += R 'ADE enrollment profile(s) created' $false 'Could not enumerate' }

# Parity device configuration profiles
$cfg = GraphGet 'https://graph.microsoft.com/v1.0/deviceManagement/deviceConfigurations?$select=id,displayName'
$parity = $cfg | Where-Object { $_.displayName -like "*$ParityProfileLike*" }
$results += R 'Parity configuration profiles' ([bool]$parity) ($(if ($parity) { ($parity.displayName | Select-Object -First 4) -join ', ' } else { "None matching '$ParityProfileLike'" }))

# Parity compliance policy
$comp = GraphGet 'https://graph.microsoft.com/v1.0/deviceManagement/deviceCompliancePolicies?$select=id,displayName'
$iosComp = $comp | Where-Object { $_.displayName -eq $ComplianceNameLike -or $_.displayName -like '*iOS*' }
$results += R 'iOS compliance policy' ([bool]$iosComp) ($(if ($iosComp) { ($iosComp.displayName | Select-Object -First 3) -join ', ' } else { 'No iOS compliance policy' }))

# Ring groups
foreach ($gName in @($PilotRingGroupName, $BroadRingGroupName)) {
    $grp = GraphGet ("https://graph.microsoft.com/v1.0/groups?`$filter=displayName eq '{0}'" -f $gName.Replace("'","''"))
    $results += R "Group '$gName'" ([bool]$grp) ($(if ($grp) { "id $($grp[0].id)" } else { 'Not found' }))
}

$results | Format-Table -AutoSize
$fail = ($results | Where-Object Result -eq 'FAIL').Count
Write-Host ''
if ($fail -eq 0) { Write-Host 'OVERALL: READY — Intune-side migration building blocks present.' -ForegroundColor Green }
else { Write-Host "OVERALL: NOT READY — $fail check(s) failed. Resolve before piloting." -ForegroundColor Yellow }
Write-Host 'Reminder: ABM MDM-server re-assignment is performed in Apple Business Manager (business.apple.com).'
