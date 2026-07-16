<#
.SYNOPSIS
    SHAREDIPAD-Discovery.ps1 — read-only readiness discovery for Apple Shared iPad on iPadOS.

.DESCRIPTION
    PURPOSE
        Reports the tenant-side state of everything Apple Shared iPad depends on, so you know what is
        missing before you wipe a device:
          * Apple MDM Push (APNs) certificate — present and expiry date.
          * Apple ADE / Business Manager enrollment token(s) — present and expiry date.
          * ADE enrollment profiles — and, for each, whether SHARED IPAD MODE IS ENABLED.
          * iPad inventory — model, storage, iPadOS version, supervised state, ADE state, ownership.
          * Which of this solution's named objects exist:
              SHARED IPAD - FMD - Pilot            (Entra device group)
              SHARED IPAD - FMD - Production       (Entra device group)
              SHARED IPAD - ADE Profile - Shared   (ADE enrollment profile)
              SHARED IPAD - Restrictions - Field Lockdown (config profile)
              SHARED IPAD - Compliance - iPadOS    (compliance policy)
              SHARED IPAD - Apps - Field Allowlist (config profile)
              PILOT - Shared iPad Users            (Entra user group)

        READ-ONLY. This script makes no changes of any kind.

        WHAT THIS SCRIPT CANNOT TELL YOU
          * Whether a given iPad serial is present in Apple Business Manager. Only ABM knows that.
            A device that is NOT in ABM cannot be ADE-enrolled and therefore CANNOT run Shared iPad
            (Requirements R6). Compare the serial list this script exports against ABM > Devices.
          * Apple's current minimum iPadOS version, minimum/recommended storage, or maximum resident
            users for Shared iPad. Those are Apple's published figures and they change — VERIFY
            against current Apple Shared iPad documentation before sizing hardware (Requirements R10/R11).

    HOW TO RUN
        Install-Module Microsoft.Graph -Scope CurrentUser      # once
        .\SHAREDIPAD-Discovery.ps1
        .\SHAREDIPAD-Discovery.ps1 -CsvPath .\ipad-inventory.csv    # also export the device inventory

    REQUIRED GRAPH SCOPES
        DeviceManagementServiceConfig.Read.All      (APNs cert, ADE tokens, enrollment profiles)
        DeviceManagementConfiguration.Read.All      (configuration + compliance profiles)
        DeviceManagementManagedDevices.Read.All     (device inventory)
        DeviceManagementApps.Read.All               (allowlist apps)
        Group.Read.All                              (the named Entra groups)

    EXPECTED RESULTS
        A PASS/FAIL line per readiness check, an iPad inventory table (optionally to CSV), and an
        overall READY / NOT READY verdict. A READY tenant has an active APNs certificate, an unexpired
        ADE token, an enrollment profile with Shared iPad enabled, and the named groups/profiles present.

.NOTES
    Intune Solutions — read-only. Makes no changes.
#>
[CmdletBinding()]
param(
    [string]$PilotDeviceGroup      = 'SHARED IPAD – FMD – Pilot',
    [string]$ProductionDeviceGroup = 'SHARED IPAD – FMD – Production',
    [string]$PilotUserGroup        = 'PILOT – Shared iPad Users',
    [string]$AdeProfileName        = 'SHARED IPAD – ADE Profile – Shared',
    [string]$RestrictionsName      = 'SHARED IPAD – Restrictions – Field Lockdown',
    [string]$ComplianceName        = 'SHARED IPAD – Compliance – iPadOS',
    [string]$AllowlistName         = 'SHARED IPAD – Apps – Field Allowlist',
    [string]$CsvPath
)

$ErrorActionPreference = 'Stop'

Connect-MgGraph -Scopes @(
    'DeviceManagementServiceConfig.Read.All'
    'DeviceManagementConfiguration.Read.All'
    'DeviceManagementManagedDevices.Read.All'
    'DeviceManagementApps.Read.All'
    'Group.Read.All'
) | Out-Null

function New-Result {
    param([string]$Check, [bool]$Pass, [string]$Detail)
    [pscustomobject]@{
        Check  = $Check
        Result = $(if ($Pass) { 'PASS' } else { 'FAIL' })
        Detail = $Detail
    }
}

function Get-GraphCollection {
    param([string]$Uri)
    $items = @()
    $next  = $Uri
    while ($next) {
        $page  = Invoke-MgGraphRequest -Method GET -Uri $next
        if ($page.value) { $items += $page.value }
        $next = $page.'@odata.nextLink'
    }
    return $items
}

function Get-GroupByExactName {
    param([string]$Name)
    # Exact display-name match. The named objects use an en dash (–) — match it verbatim.
    $escaped = $Name.Replace("'", "''")
    $uri = "https://graph.microsoft.com/v1.0/groups?`$filter=displayName eq '$escaped'&`$select=id,displayName,membershipRule,groupTypes"
    return (Get-GraphCollection -Uri $uri)
}

$results = @()

Write-Host ''
Write-Host '=== Shared iPad — readiness discovery (read-only) ===' -ForegroundColor Cyan
Write-Host ''

# ---------------------------------------------------------------------------
# 1. Apple MDM Push (APNs) certificate
# ---------------------------------------------------------------------------
try {
    $apns = Invoke-MgGraphRequest -Method GET -Uri 'https://graph.microsoft.com/v1.0/deviceManagement/applePushNotificationCertificate'
    if ($apns -and $apns.expirationDateTime) {
        $exp  = [datetime]$apns.expirationDateTime
        $days = [int]($exp - (Get-Date)).TotalDays
        $ok   = $days -gt 0
        $note = if ($days -le 30 -and $days -gt 0) { " *** RENEW SOON ***" } else { '' }
        $results += New-Result 'Apple MDM Push (APNs) certificate' $ok ("Expires $($exp.ToString('yyyy-MM-dd')) ($days days)$note; Apple ID: $($apns.appleIdentifier)")
    } else {
        $results += New-Result 'Apple MDM Push (APNs) certificate' $false 'Not configured — no iPad can enroll (Requirements R7)'
    }
} catch {
    $results += New-Result 'Apple MDM Push (APNs) certificate' $false 'Not configured — no iPad can enroll (Requirements R7)'
}

# ---------------------------------------------------------------------------
# 2. Apple ADE (Business Manager) enrollment token(s)
# ---------------------------------------------------------------------------
$depTokens = @()
try {
    $depTokens = Get-GraphCollection -Uri 'https://graph.microsoft.com/v1.0/deviceManagement/depOnboardingSettings'
    if ($depTokens.Count -ge 1) {
        $detail = ($depTokens | ForEach-Object {
            $tExp = if ($_.tokenExpirationDateTime) { ([datetime]$_.tokenExpirationDateTime).ToString('yyyy-MM-dd') } else { 'unknown' }
            "$($_.tokenName) (expires $tExp)"
        }) -join '; '
        $anyValid = $depTokens | Where-Object { $_.tokenExpirationDateTime -and ([datetime]$_.tokenExpirationDateTime) -gt (Get-Date) }
        $results += New-Result 'Apple ADE enrollment token' ([bool]$anyValid) $detail
    } else {
        $results += New-Result 'Apple ADE enrollment token' $false 'No ADE token — Shared iPad is impossible without ADE (Requirements R8)'
    }
} catch {
    $results += New-Result 'Apple ADE enrollment token' $false 'Could not read ADE tokens (Requirements R8)'
}

# ---------------------------------------------------------------------------
# 3. ADE enrollment profiles — and whether Shared iPad is enabled
#    THIS IS THE CHECK THAT MATTERS. Without a Shared-iPad-enabled profile there is no
#    session isolation, no matter what else is configured.
# ---------------------------------------------------------------------------
$sharedProfileFound = $false
$profileDetails     = @()

foreach ($tok in $depTokens) {
    try {
        $profs = Get-GraphCollection -Uri "https://graph.microsoft.com/beta/deviceManagement/depOnboardingSettings/$($tok.id)/enrollmentProfiles"
        foreach ($p in $profs) {
            # Shared iPad is exposed on the iOS ADE enrollment profile resource. Property naming has
            # varied across Graph versions — check the known variants rather than assume one.
            $isShared = $false
            foreach ($prop in @('isSharedIPad','sharedIPad','enableSharedIPad')) {
                if ($null -ne $p.$prop -and [bool]$p.$prop) { $isShared = $true }
            }
            $maxUsers = $null
            foreach ($prop in @('sharedIPadMaximumUserCount','maximumUserCount','sharedIPadMaxUserCount')) {
                if ($null -ne $p.$prop) { $maxUsers = $p.$prop }
            }
            if ($isShared) { $sharedProfileFound = $true }
            $profileDetails += [pscustomobject]@{
                Token       = $tok.tokenName
                Profile     = $p.displayName
                SharedIPad  = $(if ($isShared) { 'ENABLED' } else { 'not enabled' })
                MaxUsers    = $(if ($null -ne $maxUsers) { $maxUsers } else { 'n/a' })
                Supervised  = $(if ($null -ne $p.isSupervised) { $p.isSupervised } else { 'n/a' })
                IsDefault   = $(if ($null -ne $p.isDefault) { $p.isDefault } else { 'n/a' })
            }
        }
    } catch {
        Write-Warning "Could not read enrollment profiles for token '$($tok.tokenName)': $($_.Exception.Message)"
    }
}

$namedAde = $profileDetails | Where-Object { $_.Profile -eq $AdeProfileName }
$results += New-Result "ADE profile '$AdeProfileName' exists" ([bool]$namedAde) `
    ($(if ($namedAde) { "Shared iPad: $($namedAde[0].SharedIPad); max users: $($namedAde[0].MaxUsers)" } else { 'Not found (Implementation Step 7)' }))
$results += New-Result 'An ADE profile with Shared iPad ENABLED exists' $sharedProfileFound `
    ($(if ($sharedProfileFound) { 'Yes — session isolation is architecturally possible' } else { 'NO — no Shared iPad profile. Devices will be single-user and sessions WILL leak (Implementation Step 7)' }))

# ---------------------------------------------------------------------------
# 4. The named Entra groups
# ---------------------------------------------------------------------------
foreach ($g in @($PilotDeviceGroup, $ProductionDeviceGroup, $PilotUserGroup)) {
    $found = Get-GroupByExactName -Name $g
    if ($found) {
        $isDynamic = $found[0].groupTypes -contains 'DynamicMembership'
        $detail = "id $($found[0].id); membership: " + $(if ($isDynamic) { 'DYNAMIC — must be Assigned for enrollment-time grouping (Implementation Step 2)' } else { 'Assigned' })
        # A dynamic *device* group breaks enrollment-time grouping; flag it as a failure for the device groups.
        $pass = if ($g -eq $PilotUserGroup) { $true } else { -not $isDynamic }
        $results += New-Result "Group '$g'" $pass $detail
    } else {
        $results += New-Result "Group '$g'" $false 'Not found (Implementation Steps 1-2)'
    }
}

# ---------------------------------------------------------------------------
# 5. The named configuration + compliance profiles
# ---------------------------------------------------------------------------
$cfg = @()
try   { $cfg = Get-GraphCollection -Uri 'https://graph.microsoft.com/v1.0/deviceManagement/deviceConfigurations?$select=id,displayName' }
catch { Write-Warning "Could not read device configurations: $($_.Exception.Message)" }

foreach ($n in @($RestrictionsName, $AllowlistName)) {
    $hit = $cfg | Where-Object { $_.displayName -eq $n }
    $results += New-Result "Configuration profile '$n'" ([bool]$hit) `
        ($(if ($hit) { "id $($hit[0].id)" } else { 'Not found (Implementation Steps 9 / 11b)' }))
}

$comp = @()
try   { $comp = Get-GraphCollection -Uri 'https://graph.microsoft.com/v1.0/deviceManagement/deviceCompliancePolicies?$select=id,displayName' }
catch { Write-Warning "Could not read compliance policies: $($_.Exception.Message)" }

$hitComp = $comp | Where-Object { $_.displayName -eq $ComplianceName }
$results += New-Result "Compliance policy '$ComplianceName'" ([bool]$hitComp) `
    ($(if ($hitComp) { "id $($hitComp[0].id)" } else { 'Not found (Implementation Step 10)' }))

# ---------------------------------------------------------------------------
# 6. iPad inventory
# ---------------------------------------------------------------------------
$ipads = @()
try {
    $devs = Get-GraphCollection -Uri ("https://graph.microsoft.com/beta/deviceManagement/managedDevices" +
        "?`$filter=operatingSystem eq 'iOS'" +
        "&`$select=id,deviceName,model,serialNumber,osVersion,isSupervised,managedDeviceOwnerType,deviceEnrollmentType,totalStorageSpaceInBytes,freeStorageSpaceInBytes,userPrincipalName,complianceState,lastSyncDateTime")

    $ipads = $devs | Where-Object { $_.model -like '*iPad*' } | ForEach-Object {
        [pscustomobject]@{
            DeviceName     = $_.deviceName
            Model          = $_.model
            Serial         = $_.serialNumber
            iPadOS         = $_.osVersion
            Supervised     = $_.isSupervised
            EnrollmentType = $_.deviceEnrollmentType     # look for an ADE / DEP enrollment type
            Ownership      = $_.managedDeviceOwnerType
            StorageGB      = if ($_.totalStorageSpaceInBytes) { [math]::Round($_.totalStorageSpaceInBytes / 1GB, 1) } else { $null }
            FreeGB         = if ($_.freeStorageSpaceInBytes)  { [math]::Round($_.freeStorageSpaceInBytes  / 1GB, 1) } else { $null }
            PrimaryUser    = $_.userPrincipalName
            Compliance     = $_.complianceState
            LastSync       = $_.lastSyncDateTime
        }
    }
} catch {
    Write-Warning "Could not read device inventory: $($_.Exception.Message)"
}

$results += New-Result 'iPads present in Intune' ([bool]$ipads) "$($ipads.Count) iPad(s) found"

if ($ipads) {
    $notSupervised = @($ipads | Where-Object { -not $_.Supervised })
    $results += New-Result 'All iPads supervised' ($notSupervised.Count -eq 0) `
        ($(if ($notSupervised.Count -eq 0) { 'Yes' } else { "$($notSupervised.Count) NOT supervised — these cannot enforce the field lockdown (Requirements R9)" }))

    $notAde = @($ipads | Where-Object { "$($_.EnrollmentType)" -notlike '*appleDevice*' -and "$($_.EnrollmentType)" -notlike '*dep*' })
    if ($notAde.Count -gt 0) {
        $results += New-Result 'All iPads ADE-enrolled' $false "$($notAde.Count) iPad(s) not ADE-enrolled — these CANNOT run Shared iPad (Requirements R6/R8)"
    } else {
        $results += New-Result 'All iPads ADE-enrolled' $true 'Yes'
    }
}

# ---------------------------------------------------------------------------
# Output
# ---------------------------------------------------------------------------
Write-Host '--- Readiness checks ---' -ForegroundColor Cyan
$results | Format-Table -AutoSize

if ($profileDetails) {
    Write-Host '--- ADE enrollment profiles ---' -ForegroundColor Cyan
    $profileDetails | Format-Table -AutoSize
}

if ($ipads) {
    Write-Host '--- iPad inventory ---' -ForegroundColor Cyan
    $ipads | Format-Table DeviceName, Model, Serial, iPadOS, Supervised, EnrollmentType, StorageGB, FreeGB -AutoSize

    if ($CsvPath) {
        $ipads | Export-Csv -Path $CsvPath -NoTypeInformation -Encoding UTF8
        Write-Host "iPad inventory exported to: $CsvPath" -ForegroundColor Green
    }
}

$failCount = @($results | Where-Object Result -eq 'FAIL').Count
Write-Host ''
if ($failCount -eq 0) {
    Write-Host 'OVERALL: READY — the Shared iPad building blocks are present.' -ForegroundColor Green
} else {
    Write-Host "OVERALL: NOT READY — $failCount check(s) failed. Resolve before wiping any device." -ForegroundColor Yellow
}

Write-Host ''
Write-Host 'Reminders — these cannot be checked from Microsoft Graph:' -ForegroundColor Yellow
Write-Host '  * Confirm every iPad serial above is present in Apple Business Manager > Devices.'
Write-Host '    A serial that is NOT in ABM cannot be ADE-enrolled and CANNOT run Shared iPad (R6).'
Write-Host '  * VERIFY WITH APPLE the current minimum iPadOS version, minimum/recommended storage,'
Write-Host '    and maximum resident users for Shared iPad before sizing hardware (R10/R11).'
Write-Host '  * Confirm Managed Apple ID conflicts are resolved in ABM (R14) — run'
Write-Host '    SHAREDIPAD-AppleIDConflict.ps1 to build the candidate worklist.'
