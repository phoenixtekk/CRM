<#
.SYNOPSIS
    SHAREDIPAD-Report.ps1 — fleet report: per-device Shared iPad readiness and state.

.DESCRIPTION
    PURPOSE
        Produces a per-device fleet report for the iPad estate and exports it to CSV. For each iPad:
          * Device name, model, serial number, iPadOS version.
          * Supervised state and enrollment type (ADE or not).
          * Shared iPad READINESS — a computed verdict (READY / NOT READY) based on the device being
            ADE-enrolled and supervised, with the blocking reason when it is not.
          * Assigned ADE enrollment profile (where the ADE token reports it) and whether that profile
            has Shared iPad enabled.
          * Total and free storage — the constraint that bites at scale.
          * Compliance state and last check-in.

        Use it to size the project (how many devices are actually eligible?), to track staging waves,
        and as the as-built record after rollout.

        READ-ONLY. This script makes no changes of any kind.

        WHAT THIS SCRIPT CANNOT TELL YOU
          * Whether a serial is present in Apple Business Manager. Only ABM knows. A device not in ABM
            cannot be ADE-enrolled and CANNOT run Shared iPad (Requirements R6). Compare the Serial
            column against ABM > Devices.
          * Whether a device's storage is SUFFICIENT. The report shows the storage; Apple publishes
            the minimum/recommended figures and the maximum resident-user count, and they change.
            VERIFY against current Apple Shared iPad documentation (Requirements R11).
          * Whether sessions are actually isolated. That is the A/B test in Testing section 5.

    HOW TO RUN
        Install-Module Microsoft.Graph -Scope CurrentUser      # once
        .\SHAREDIPAD-Report.ps1
        .\SHAREDIPAD-Report.ps1 -CsvPath .\shared-ipad-fleet.csv
        .\SHAREDIPAD-Report.ps1 -DeviceGroupName 'SHARED IPAD – FMD – Production' -CsvPath .\wave3.csv

    REQUIRED GRAPH SCOPES
        DeviceManagementManagedDevices.Read.All     (device inventory and state)
        DeviceManagementServiceConfig.Read.All      (ADE tokens and enrollment profiles)
        Group.Read.All                              (optional — scoping to a named device group)

    EXPECTED RESULTS
        A fleet table on screen, a summary count of READY vs NOT READY devices with the blocking
        reasons, and a CSV export when -CsvPath is supplied.

.NOTES
    Intune Solutions — read-only. Makes no changes.
#>
[CmdletBinding()]
param(
    [string]$CsvPath,
    [string]$DeviceGroupName,
    [string]$AdeProfileName = 'SHARED IPAD – ADE Profile – Shared'
)

$ErrorActionPreference = 'Stop'

Connect-MgGraph -Scopes @(
    'DeviceManagementManagedDevices.Read.All'
    'DeviceManagementServiceConfig.Read.All'
    'Group.Read.All'
) | Out-Null

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

Write-Host ''
Write-Host '=== Shared iPad — fleet report (read-only) ===' -ForegroundColor Cyan
Write-Host ''

# ---------------------------------------------------------------------------
# ADE profile map: serial -> assigned profile name; and profile name -> Shared iPad enabled
# ---------------------------------------------------------------------------
$serialToProfile   = @{}
$profileSharedFlag = @{}

try {
    $depTokens = Get-GraphCollection -Uri 'https://graph.microsoft.com/v1.0/deviceManagement/depOnboardingSettings'
    foreach ($tok in $depTokens) {
        try {
            $profs = Get-GraphCollection -Uri "https://graph.microsoft.com/beta/deviceManagement/depOnboardingSettings/$($tok.id)/enrollmentProfiles"
            foreach ($p in $profs) {
                $isShared = $false
                foreach ($prop in @('isSharedIPad','sharedIPad','enableSharedIPad')) {
                    if ($null -ne $p.$prop -and [bool]$p.$prop) { $isShared = $true }
                }
                $profileSharedFlag[$p.displayName] = $isShared
            }
        } catch { }

        try {
            $identities = Get-GraphCollection -Uri "https://graph.microsoft.com/beta/deviceManagement/depOnboardingSettings/$($tok.id)/importedAppleDeviceIdentities"
            foreach ($i in $identities) {
                if ($i.serialNumber) { $serialToProfile[$i.serialNumber] = $i.enrollmentProfileName }
            }
        } catch { }
    }
} catch {
    Write-Warning "Could not read ADE tokens/profiles: $($_.Exception.Message)"
}

# ---------------------------------------------------------------------------
# Optional: scope to a named device group
# ---------------------------------------------------------------------------
$scopeAadIds = $null
if ($DeviceGroupName) {
    $escaped = $DeviceGroupName.Replace("'", "''")
    $grp = Get-GraphCollection -Uri "https://graph.microsoft.com/v1.0/groups?`$filter=displayName eq '$escaped'&`$select=id,displayName"
    if (-not $grp) {
        Write-Warning "Group '$DeviceGroupName' not found — reporting on the whole iPad estate instead."
    } else {
        $members = Get-GraphCollection -Uri "https://graph.microsoft.com/v1.0/groups/$($grp[0].id)/members?`$select=id,displayName,deviceId"
        $scopeAadIds = @($members | ForEach-Object { $_.deviceId } | Where-Object { $_ })
        Write-Host "Scoped to '$DeviceGroupName' — $($scopeAadIds.Count) member device(s)." -ForegroundColor Cyan
        if ($scopeAadIds.Count -eq 0) {
            Write-Warning "The group is EMPTY. If devices have enrolled, the Intune Provisioning Client owner is probably missing (Implementation Step 2b)."
        }
    }
}

# ---------------------------------------------------------------------------
# Device inventory
# ---------------------------------------------------------------------------
$devs = Get-GraphCollection -Uri ("https://graph.microsoft.com/beta/deviceManagement/managedDevices" +
    "?`$filter=operatingSystem eq 'iOS'" +
    "&`$select=id,deviceName,model,serialNumber,osVersion,isSupervised,managedDeviceOwnerType,deviceEnrollmentType," +
    "totalStorageSpaceInBytes,freeStorageSpaceInBytes,userPrincipalName,complianceState,lastSyncDateTime,azureADDeviceId")

$ipads = $devs | Where-Object { $_.model -like '*iPad*' }
if ($null -ne $scopeAadIds) {
    $ipads = $ipads | Where-Object { $scopeAadIds -contains $_.azureADDeviceId }
}

if (-not $ipads) {
    Write-Host 'No iPads found matching the scope.' -ForegroundColor Yellow
    return
}

$report = foreach ($d in $ipads) {
    $isAde = ("$($d.deviceEnrollmentType)" -like '*appleDevice*' -or "$($d.deviceEnrollmentType)" -like '*dep*')
    $prof  = $serialToProfile[$d.serialNumber]
    $profShared = if ($prof -and $profileSharedFlag.ContainsKey($prof)) { $profileSharedFlag[$prof] } else { $null }

    # Compute the readiness verdict and the blocking reason.
    $blockers = @()
    if (-not $isAde)          { $blockers += 'not ADE-enrolled (device may not be in ABM — R6)' }
    if (-not $d.isSupervised) { $blockers += 'not supervised (R9)' }
    if ($isAde -and -not $prof) { $blockers += 'no ADE profile assigned to this serial (Step 8)' }
    if ($prof -and $profShared -eq $false) { $blockers += "assigned profile '$prof' does NOT have Shared iPad enabled (Step 7)" }

    [pscustomobject]@{
        DeviceName      = $d.deviceName
        Model           = $d.model
        Serial          = $d.serialNumber
        iPadOS          = $d.osVersion
        Supervised      = [bool]$d.isSupervised
        EnrollmentType  = $d.deviceEnrollmentType
        ADEEnrolled     = $isAde
        AdeProfile      = $(if ($prof) { $prof } else { '(none)' })
        ProfileIsShared = $(if ($null -eq $profShared) { 'unknown' } elseif ($profShared) { 'YES' } else { 'NO' })
        SharedIPadReady = $(if ($blockers.Count -eq 0) { 'READY' } else { 'NOT READY' })
        BlockingReason  = $(if ($blockers.Count -eq 0) { '' } else { $blockers -join '; ' })
        StorageGB       = $(if ($d.totalStorageSpaceInBytes) { [math]::Round($d.totalStorageSpaceInBytes / 1GB, 1) } else { $null })
        FreeGB          = $(if ($d.freeStorageSpaceInBytes)  { [math]::Round($d.freeStorageSpaceInBytes  / 1GB, 1) } else { $null })
        FreePercent     = $(if ($d.totalStorageSpaceInBytes -and $d.freeStorageSpaceInBytes) { [math]::Round(100 * $d.freeStorageSpaceInBytes / $d.totalStorageSpaceInBytes, 0) } else { $null })
        Ownership       = $d.managedDeviceOwnerType
        PrimaryUser     = $d.userPrincipalName
        Compliance      = $d.complianceState
        LastCheckIn     = $d.lastSyncDateTime
    }
}

$report = $report | Sort-Object SharedIPadReady, DeviceName

Write-Host '--- Fleet ---' -ForegroundColor Cyan
$report | Format-Table DeviceName, Model, Serial, iPadOS, Supervised, ADEEnrolled, ProfileIsShared, SharedIPadReady, StorageGB, FreeGB, Compliance -AutoSize

# ---------------------------------------------------------------------------
# Summary
# ---------------------------------------------------------------------------
$ready    = @($report | Where-Object SharedIPadReady -eq 'READY')
$notReady = @($report | Where-Object SharedIPadReady -eq 'NOT READY')

Write-Host ''
Write-Host '--- Summary ---' -ForegroundColor Cyan
Write-Host "  Total iPads:         $($report.Count)"
Write-Host "  Shared iPad READY:   $($ready.Count)" -ForegroundColor Green
Write-Host "  NOT READY:           $($notReady.Count)" -ForegroundColor $(if ($notReady.Count) { 'Yellow' } else { 'Green' })

if ($notReady.Count) {
    Write-Host ''
    Write-Host '  Blocking reasons:' -ForegroundColor Yellow
    $notReady | Group-Object BlockingReason | Sort-Object Count -Descending | ForEach-Object {
        Write-Host ("   {0,3} x  {1}" -f $_.Count, $_.Name)
    }
}

$noSync = @($report | Where-Object { $_.LastCheckIn -and ([datetime]$_.LastCheckIn) -lt (Get-Date).AddDays(-7) })
if ($noSync.Count) {
    Write-Host ''
    Write-Host "  $($noSync.Count) device(s) have not checked in for 7+ days — they may be off the rack, flat, or off-network." -ForegroundColor Yellow
}

if ($CsvPath) {
    $report | Export-Csv -Path $CsvPath -NoTypeInformation -Encoding UTF8
    Write-Host ''
    Write-Host "Fleet report exported to: $CsvPath" -ForegroundColor Green
}

Write-Host ''
Write-Host 'Reminders — these cannot be checked from Microsoft Graph:' -ForegroundColor Yellow
Write-Host '  * Compare the Serial column against Apple Business Manager > Devices. Serials absent from'
Write-Host '    ABM cannot be ADE-enrolled and CANNOT run Shared iPad (R6) — that is a procurement'
Write-Host '    question, not a configuration one.'
Write-Host '  * VERIFY WITH APPLE the current minimum/recommended storage and maximum resident users for'
Write-Host '    Shared iPad, then judge the StorageGB column against those figures (R11).'
