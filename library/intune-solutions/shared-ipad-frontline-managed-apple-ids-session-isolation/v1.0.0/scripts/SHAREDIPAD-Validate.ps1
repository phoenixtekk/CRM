<#
.SYNOPSIS
    SHAREDIPAD-Validate.ps1 — PASS/FAIL scoring of the Shared iPad success criteria.

.DESCRIPTION
    PURPOSE
        Scores the tenant and the pilot devices against this solution's success criteria and prints a
        clear PASS/FAIL summary:
          1. An Apple ADE token exists and has not expired.
          2. The Apple MDM Push (APNs) certificate is active.
          3. An enrollment profile named 'SHARED IPAD - ADE Profile - Shared' exists AND has
             SHARED IPAD ENABLED.
          4. That profile is assigned to devices on the ADE token.
          5. The pilot device group is Assigned (not Dynamic) and owned by the Intune Provisioning
             Client service principal (AppId f1346770-5b25-470b-88bd-d5744ab7952c) — without this
             owner the group stays empty at enrollment and nothing deploys.
          6. Every pilot device is SUPERVISED and ADE-enrolled.
          7. 'SHARED IPAD - Restrictions - Field Lockdown' exists and is assigned to the pilot group.
          8. 'SHARED IPAD - Compliance - iPadOS' exists and is assigned to the pilot group.
          9. 'SHARED IPAD - Apps - Field Allowlist' exists and is assigned to the pilot group.

        READ-ONLY. This script makes no changes of any kind.

        WHAT A PASS DOES *NOT* MEAN
            A PASS here means the ARCHITECTURE is in place. It does NOT prove session isolation.
            The acceptance gate for this project is the session-isolation A/B test in Testing section 5,
            run with two real humans on a real device. This script cannot run that test. Do not sign
            off on this script alone.

    HOW TO RUN
        Install-Module Microsoft.Graph -Scope CurrentUser      # once
        .\SHAREDIPAD-Validate.ps1
        .\SHAREDIPAD-Validate.ps1 -DeviceGroupName 'SHARED IPAD – FMD – Production'

    REQUIRED GRAPH SCOPES
        DeviceManagementServiceConfig.Read.All      (APNs cert, ADE tokens, enrollment profiles)
        DeviceManagementConfiguration.Read.All      (configuration + compliance profiles, assignments)
        DeviceManagementManagedDevices.Read.All     (device state)
        DeviceManagementApps.Read.All               (app assignments)
        Group.Read.All                              (group membership and owners)

    EXPECTED RESULTS
        A PASS/FAIL line per criterion and an overall verdict. Overall PASS = the Shared iPad
        architecture is correctly configured for the named group, and you may proceed to the
        session-isolation test (Testing section 5).

.NOTES
    Intune Solutions — read-only. Makes no changes.
#>
[CmdletBinding()]
param(
    [string]$DeviceGroupName  = 'SHARED IPAD – FMD – Pilot',
    [string]$AdeProfileName   = 'SHARED IPAD – ADE Profile – Shared',
    [string]$RestrictionsName = 'SHARED IPAD – Restrictions – Field Lockdown',
    [string]$ComplianceName   = 'SHARED IPAD – Compliance – iPadOS',
    [string]$AllowlistName    = 'SHARED IPAD – Apps – Field Allowlist'
)

$ErrorActionPreference = 'Stop'

# The Intune Provisioning Client first-party service principal. Match by AppId — the display name
# varies by tenant (often 'Intune Autopilot ConfidentialClient').
$ProvisioningClientAppId = 'f1346770-5b25-470b-88bd-d5744ab7952c'

Connect-MgGraph -Scopes @(
    'DeviceManagementServiceConfig.Read.All'
    'DeviceManagementConfiguration.Read.All'
    'DeviceManagementManagedDevices.Read.All'
    'DeviceManagementApps.Read.All'
    'Group.Read.All'
) | Out-Null

function New-Result {
    param([string]$Criterion, [bool]$Pass, [string]$Detail)
    [pscustomobject]@{
        Criterion = $Criterion
        Result    = $(if ($Pass) { 'PASS' } else { 'FAIL' })
        Detail    = $Detail
    }
}

function Get-GraphCollection {
    param([string]$Uri)
    $items = @(); $next = $Uri
    while ($next) {
        $page = Invoke-MgGraphRequest -Method GET -Uri $next
        if ($page.value) { $items += $page.value }
        $next = $page.'@odata.nextLink'
    }
    return $items
}

$results = @()

Write-Host ''
Write-Host "=== Shared iPad — validation against '$DeviceGroupName' (read-only) ===" -ForegroundColor Cyan
Write-Host ''

# ---------------------------------------------------------------------------
# 1. ADE token valid
# ---------------------------------------------------------------------------
$depTokens = @()
try { $depTokens = Get-GraphCollection -Uri 'https://graph.microsoft.com/v1.0/deviceManagement/depOnboardingSettings' } catch { }
$validToken = $depTokens | Where-Object { $_.tokenExpirationDateTime -and ([datetime]$_.tokenExpirationDateTime) -gt (Get-Date) }
$results += New-Result 'ADE token present and unexpired' ([bool]$validToken) `
    ($(if ($validToken) { "$($validToken.Count) valid token(s); next expiry $((($validToken | Sort-Object tokenExpirationDateTime)[0].tokenExpirationDateTime))" }
       else { 'No valid ADE token — Shared iPad is impossible (Requirements R8)' }))

# ---------------------------------------------------------------------------
# 2. APNs certificate active
# ---------------------------------------------------------------------------
try {
    $apns = Invoke-MgGraphRequest -Method GET -Uri 'https://graph.microsoft.com/v1.0/deviceManagement/applePushNotificationCertificate'
    $apnsOk = $apns -and $apns.expirationDateTime -and ([datetime]$apns.expirationDateTime -gt (Get-Date))
    $results += New-Result 'Apple MDM Push (APNs) certificate active' $apnsOk `
        ($(if ($apnsOk) { "Expires $(([datetime]$apns.expirationDateTime).ToString('yyyy-MM-dd'))" } else { 'Missing or expired (Requirements R7)' }))
} catch {
    $results += New-Result 'Apple MDM Push (APNs) certificate active' $false 'Not configured (Requirements R7)'
}

# ---------------------------------------------------------------------------
# 3 + 4. Shared-iPad-enabled enrollment profile, and it is assigned
# ---------------------------------------------------------------------------
$namedProfile   = $null
$namedProfileTok = $null
foreach ($tok in $depTokens) {
    try {
        $profs = Get-GraphCollection -Uri "https://graph.microsoft.com/beta/deviceManagement/depOnboardingSettings/$($tok.id)/enrollmentProfiles"
        $hit = $profs | Where-Object { $_.displayName -eq $AdeProfileName }
        if ($hit) { $namedProfile = $hit[0]; $namedProfileTok = $tok; break }
    } catch { }
}

if ($namedProfile) {
    $isShared = $false
    foreach ($prop in @('isSharedIPad','sharedIPad','enableSharedIPad')) {
        if ($null -ne $namedProfile.$prop -and [bool]$namedProfile.$prop) { $isShared = $true }
    }
    $maxUsers = $null
    foreach ($prop in @('sharedIPadMaximumUserCount','maximumUserCount','sharedIPadMaxUserCount')) {
        if ($null -ne $namedProfile.$prop) { $maxUsers = $namedProfile.$prop }
    }

    $results += New-Result "Enrollment profile '$AdeProfileName' exists" $true "On token '$($namedProfileTok.tokenName)'"
    $results += New-Result 'Shared iPad ENABLED on that profile' $isShared `
        ($(if ($isShared) { "Yes; max resident users: $(if ($null -ne $maxUsers) { $maxUsers } else { 'not reported' })" }
           else { 'NO — devices will enroll SINGLE-USER and sessions WILL leak. This is the #1 cause of the problem this solution fixes (Implementation Step 7).' }))

    $isSupervisedProfile = $(if ($null -ne $namedProfile.isSupervised) { [bool]$namedProfile.isSupervised } else { $false })
    $results += New-Result 'Enrollment profile sets Supervised' $isSupervisedProfile `
        ($(if ($isSupervisedProfile) { 'Yes' } else { 'No — the field lockdown restrictions will be ignored (Requirements R9)' }))

    # Profile assigned to devices on the token?
    $assignedCount = 0
    try {
        $tokDevices = Get-GraphCollection -Uri "https://graph.microsoft.com/beta/deviceManagement/depOnboardingSettings/$($namedProfileTok.id)/importedAppleDeviceIdentities"
        $assignedCount = @($tokDevices | Where-Object { $_.enrollmentProfileName -eq $AdeProfileName }).Count
    } catch { }
    $results += New-Result 'Profile assigned to devices on the ADE token' ($assignedCount -gt 0) `
        ($(if ($assignedCount -gt 0) { "$assignedCount device serial(s) assigned this profile" }
           else { "No serials assigned this profile — devices will not enroll into Shared iPad (Implementation Step 8). If this reports 0 but the portal shows assignments, verify in Intune > Devices > Enrollment > Apple > Enrollment program tokens > (token) > Devices." }))
} else {
    $results += New-Result "Enrollment profile '$AdeProfileName' exists" $false 'Not found on any ADE token (Implementation Step 7)'
    $results += New-Result 'Shared iPad ENABLED on that profile' $false 'No profile to check'
    $results += New-Result 'Enrollment profile sets Supervised' $false 'No profile to check'
    $results += New-Result 'Profile assigned to devices on the ADE token' $false 'No profile to check'
}

# ---------------------------------------------------------------------------
# 5. Device group: exists, Assigned (not Dynamic), and owned by the Provisioning Client
# ---------------------------------------------------------------------------
$escaped = $DeviceGroupName.Replace("'", "''")
$grp = Get-GraphCollection -Uri "https://graph.microsoft.com/v1.0/groups?`$filter=displayName eq '$escaped'&`$select=id,displayName,groupTypes"
$groupId = $null

if ($grp) {
    $groupId  = $grp[0].id
    $isDynamic = $grp[0].groupTypes -contains 'DynamicMembership'
    $results += New-Result "Group '$DeviceGroupName' exists" $true "id $groupId"
    $results += New-Result 'Group membership type is Assigned' (-not $isDynamic) `
        ($(if ($isDynamic) { 'DYNAMIC — enrollment-time device grouping requires an ASSIGNED group (Implementation Step 2)' } else { 'Assigned' }))

    # Owner check — match by AppId, not display name.
    $ownerOk = $false; $ownerDetail = 'Owner not found'
    try {
        $owners = Get-GraphCollection -Uri "https://graph.microsoft.com/v1.0/groups/$groupId/owners"
        foreach ($o in $owners) {
            if ($o.appId -eq $ProvisioningClientAppId) {
                $ownerOk = $true
                $ownerDetail = "Present: '$($o.displayName)' (AppId $ProvisioningClientAppId)"
                break
            }
        }
    } catch { $ownerDetail = "Could not read owners: $($_.Exception.Message)" }

    if (-not $ownerOk -and $ownerDetail -eq 'Owner not found') {
        $ownerDetail = "MISSING — the Intune Provisioning Client (AppId $ProvisioningClientAppId) is not an owner. The group will stay EMPTY at enrollment and NOTHING will deploy (Implementation Step 2b)."
    }
    $results += New-Result 'Intune Provisioning Client owns the group' $ownerOk $ownerDetail
} else {
    $results += New-Result "Group '$DeviceGroupName' exists" $false 'Not found (Implementation Step 2)'
    $results += New-Result 'Group membership type is Assigned' $false 'No group to check'
    $results += New-Result 'Intune Provisioning Client owns the group' $false 'No group to check'
}

# ---------------------------------------------------------------------------
# 6. Devices in the group are supervised and ADE-enrolled
# ---------------------------------------------------------------------------
if ($groupId) {
    $memberSerials = @()
    try {
        $members = Get-GraphCollection -Uri "https://graph.microsoft.com/v1.0/groups/$groupId/members?`$select=id,displayName,deviceId"
        $memberSerials = $members
    } catch { }

    if ($memberSerials.Count -eq 0) {
        $results += New-Result 'Group has device members' $false `
            'Group is EMPTY. If devices have enrolled, the Provisioning Client owner is almost certainly missing (Implementation Step 2b).'
        $results += New-Result 'All group devices supervised + ADE' $false 'No members to check'
    } else {
        $results += New-Result 'Group has device members' $true "$($memberSerials.Count) member(s)"

        $mdevs = @()
        try {
            $mdevs = Get-GraphCollection -Uri ("https://graph.microsoft.com/beta/deviceManagement/managedDevices" +
                "?`$filter=operatingSystem eq 'iOS'&`$select=id,deviceName,azureADDeviceId,isSupervised,deviceEnrollmentType,model")
        } catch { }

        $memberAadIds = $memberSerials | ForEach-Object { $_.deviceId } | Where-Object { $_ }
        $groupDevices = $mdevs | Where-Object { $memberAadIds -contains $_.azureADDeviceId }

        if ($groupDevices) {
            $badSup = @($groupDevices | Where-Object { -not $_.isSupervised })
            $badAde = @($groupDevices | Where-Object { "$($_.deviceEnrollmentType)" -notlike '*appleDevice*' -and "$($_.deviceEnrollmentType)" -notlike '*dep*' })
            $ok = ($badSup.Count -eq 0 -and $badAde.Count -eq 0)
            $detail = if ($ok) { "All $($groupDevices.Count) device(s) supervised and ADE-enrolled" }
                      else { "$($badSup.Count) not supervised; $($badAde.Count) not ADE-enrolled — these CANNOT run Shared iPad (Requirements R6/R9). Wipe and re-enroll (Implementation Step 12)." }
            $results += New-Result 'All group devices supervised + ADE' $ok $detail
        } else {
            $results += New-Result 'All group devices supervised + ADE' $false 'Could not correlate group members to Intune devices — verify manually in Intune > Devices.'
        }
    }
}

# ---------------------------------------------------------------------------
# 7 + 8 + 9. Named profiles/policies exist AND are assigned to the group
# ---------------------------------------------------------------------------
function Test-AssignedToGroup {
    param([string]$AssignmentsUri, [string]$GroupId)
    try {
        $assigns = Get-GraphCollection -Uri $AssignmentsUri
        foreach ($a in $assigns) {
            if ($a.target -and $a.target.groupId -eq $GroupId) { return $true }
        }
    } catch { }
    return $false
}

# Configuration profiles (restrictions + allowlist)
$cfg = @()
try { $cfg = Get-GraphCollection -Uri 'https://graph.microsoft.com/v1.0/deviceManagement/deviceConfigurations?$select=id,displayName' } catch { }

foreach ($n in @($RestrictionsName, $AllowlistName)) {
    $hit = $cfg | Where-Object { $_.displayName -eq $n }
    if ($hit -and $groupId) {
        $assigned = Test-AssignedToGroup -AssignmentsUri "https://graph.microsoft.com/v1.0/deviceManagement/deviceConfigurations/$($hit[0].id)/assignments" -GroupId $groupId
        $results += New-Result "'$n' assigned to '$DeviceGroupName'" $assigned `
            ($(if ($assigned) { 'Assigned' } else { "Profile exists but is NOT assigned to this group (Implementation Steps 9 / 11b / 14)" }))
    } else {
        $results += New-Result "'$n' assigned to '$DeviceGroupName'" $false ($(if ($hit) { 'Group not found' } else { 'Profile not found (Implementation Steps 9 / 11b)' }))
    }
}

# Compliance policy
$comp = @()
try { $comp = Get-GraphCollection -Uri 'https://graph.microsoft.com/v1.0/deviceManagement/deviceCompliancePolicies?$select=id,displayName' } catch { }
$hitComp = $comp | Where-Object { $_.displayName -eq $ComplianceName }
if ($hitComp -and $groupId) {
    $assigned = Test-AssignedToGroup -AssignmentsUri "https://graph.microsoft.com/v1.0/deviceManagement/deviceCompliancePolicies/$($hitComp[0].id)/assignments" -GroupId $groupId
    $results += New-Result "'$ComplianceName' assigned to '$DeviceGroupName'" $assigned `
        ($(if ($assigned) { 'Assigned' } else { 'Policy exists but is NOT assigned to this group (Implementation Steps 10 / 14)' }))
} else {
    $results += New-Result "'$ComplianceName' assigned to '$DeviceGroupName'" $false ($(if ($hitComp) { 'Group not found' } else { 'Policy not found (Implementation Step 10)' }))
}

# App allowlist — at least one app Required-assigned to the group
if ($groupId) {
    $appsAssigned = 0
    try {
        $apps = Get-GraphCollection -Uri 'https://graph.microsoft.com/beta/deviceAppManagement/mobileApps?$select=id,displayName'
        foreach ($app in $apps) {
            try {
                $aa = Get-GraphCollection -Uri "https://graph.microsoft.com/beta/deviceAppManagement/mobileApps/$($app.id)/assignments"
                foreach ($x in $aa) {
                    if ($x.target -and $x.target.groupId -eq $groupId -and $x.intent -eq 'required') { $appsAssigned++; break }
                }
            } catch { }
        }
    } catch { }
    $results += New-Result 'Field allowlist apps assigned Required to the group' ($appsAssigned -gt 0) `
        ($(if ($appsAssigned -gt 0) { "$appsAssigned app(s) assigned Required" } else { 'No apps assigned Required to this group — the field workload will not install (Implementation Step 11a)' }))
}

# ---------------------------------------------------------------------------
# Verdict
# ---------------------------------------------------------------------------
Write-Host '--- Success criteria ---' -ForegroundColor Cyan
$results | Format-Table -AutoSize

$failCount = @($results | Where-Object Result -eq 'FAIL').Count
Write-Host ''
Write-Host ('=' * 78)
if ($failCount -eq 0) {
    Write-Host " OVERALL: PASS — the Shared iPad architecture is correctly configured for" -ForegroundColor Green
    Write-Host " '$DeviceGroupName'." -ForegroundColor Green
    Write-Host ''
    Write-Host ' NEXT — AND THIS IS THE REAL GATE:' -ForegroundColor Yellow
    Write-Host ' Run the session-isolation A/B test (Testing section 5) with TWO REAL USERS on a real'
    Write-Host ' device. This script proves the architecture exists. Only that test proves the'
    Write-Host ' sessions are actually isolated. Do not sign off on this script alone.'
} else {
    Write-Host " OVERALL: FAIL — $failCount criterion(s) failed for '$DeviceGroupName'." -ForegroundColor Red
    Write-Host ' Do not stage production devices. Resolve the failures above, then re-run.'
}
Write-Host ('=' * 78)
