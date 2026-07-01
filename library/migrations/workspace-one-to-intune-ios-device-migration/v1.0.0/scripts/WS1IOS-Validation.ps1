<#
.SYNOPSIS
    WS1IOS-Validation.ps1 — per-device check that an iPhone/iPad migrated cleanly to Intune.

.DESCRIPTION
    PURPOSE
        Validates a named (or all) migrated iOS/iPadOS device: present in Intune, Supervised, enrolled
        via Automated Device Enrollment, a member of the migration ring group, and reporting compliant.
        Confirms the device is now Intune-managed (its presence in managedDevices) rather than only in
        the source MDM. Read-only.

    HOW TO RUN
        Install-Module Microsoft.Graph -Scope CurrentUser   # once
        .\WS1IOS-Validation.ps1                       # all iOS devices
        .\WS1IOS-Validation.ps1 -DeviceName "IPAD-PILOT-01"

    EXPECTED RESULTS
        A PASS/FAIL table per device: Supervised, ADE-enrolled, ring membership, compliance state.

.NOTES
    Read-only. The repeatable Workspace ONE to Intune iOS/iPadOS migration.
#>
[CmdletBinding()]
param(
    [string]$DeviceName,
    [string]$PilotRingGroupName = 'iOS Migration – Pilot Ring – Pilot',
    [string]$BroadRingGroupName = 'iOS Migration – Broad Ring – Expand'
)

$ErrorActionPreference = 'Stop'
Connect-MgGraph -Scopes 'DeviceManagementManagedDevices.Read.All','Group.Read.All','Directory.Read.All' | Out-Null

function GraphGet($uri) { (Invoke-MgGraphRequest -Method GET -Uri $uri).value }

# Resolve ring group ids and their device member set (by Intune device id where possible)
$ringMembers = @{}
foreach ($gName in @($PilotRingGroupName, $BroadRingGroupName)) {
    $grp = GraphGet ("https://graph.microsoft.com/v1.0/groups?`$filter=displayName eq '{0}'" -f $gName.Replace("'","''"))
    if ($grp) {
        $members = GraphGet "https://graph.microsoft.com/v1.0/groups/$($grp[0].id)/members?`$select=id,displayName,deviceId"
        foreach ($m in $members) { if ($m.displayName) { $ringMembers[$m.displayName] = $gName } }
    }
}

# Managed iOS devices
$uri = "https://graph.microsoft.com/v1.0/deviceManagement/managedDevices?`$filter=operatingSystem eq 'iOS'&`$select=id,deviceName,serialNumber,isSupervised,deviceEnrollmentType,complianceState,managementAgent,userPrincipalName"
$devices = @()
do { $r = Invoke-MgGraphRequest -Method GET -Uri $uri; $devices += $r.value; $uri = $r.'@odata.nextLink' } while ($uri)

if ($DeviceName) { $devices = $devices | Where-Object { $_.deviceName -eq $DeviceName } }
if (-not $devices) { Write-Host 'No matching iOS/iPadOS devices found in Intune.' -ForegroundColor Yellow; return }

$report = foreach ($d in $devices) {
    $ade   = $d.deviceEnrollmentType -match 'appleBulkWithoutUser|appleBulkWithUser|deviceEnrollmentProgram|appleAutomatedDeviceEnrollment'
    $ring  = if ($ringMembers.ContainsKey($d.deviceName)) { $ringMembers[$d.deviceName] } else { '(not in a ring group)' }
    $pass  = $d.isSupervised -and $ade -and ($ring -ne '(not in a ring group)') -and ($d.complianceState -eq 'compliant')
    [pscustomobject]@{
        Device      = $d.deviceName
        Serial      = $d.serialNumber
        Supervised  = $d.isSupervised
        ADEEnrolled = [bool]$ade
        RingGroup   = $ring
        Compliance  = $d.complianceState
        Result      = $(if ($pass) { 'PASS' } else { 'REVIEW' })
    }
}

$report | Format-Table -AutoSize
$review = ($report | Where-Object Result -eq 'REVIEW').Count
Write-Host ''
if ($review -eq 0) { Write-Host 'All listed devices PASS — supervised, ADE-enrolled, ringed, compliant.' -ForegroundColor Green }
else { Write-Host "$review device(s) need REVIEW. Check supervision, ADE enrollment, ring membership, and compliance." -ForegroundColor Yellow }
