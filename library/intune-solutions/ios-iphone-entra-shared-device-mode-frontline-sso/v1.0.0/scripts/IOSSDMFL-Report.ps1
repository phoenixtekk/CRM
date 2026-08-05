<#
.SYNOPSIS
    IOSSDMFL-Report.ps1 — shared-pool inventory of no-affinity (shared) iOS iPhones.
.DESCRIPTION
    PURPOSE
        Produces an inventory of iOS/iPadOS devices enrolled WITHOUT a primary user (the shared pool),
        so you can see which shared iPhones exist, their OS version, enrollment/ownership, and whether
        they are members of the shared-device group. Use it to measure coverage before widening and to
        find shared phones that still need provisioning. Read-only.
    HOW TO RUN
        powershell -ExecutionPolicy Bypass -File .\IOSSDMFL-Report.ps1
        Optional: -GroupName "iPhone SDM - Devices"  -CsvPath .\IOSSDMFL-shared-devices.csv
        (Install once: Install-Module Microsoft.Graph -Scope CurrentUser)
        Required Graph scopes: DeviceManagementManagedDevices.Read.All, Group.Read.All
    EXPECTED RESULTS
        A table (and optional CSV) of no-primary-user iOS devices with an InGroup column, plus a
        summary. Note: 'registered into Shared Device Mode' is an on-device Authenticator action and is
        confirmed on the device (Testing Test 4); this report covers the enrollment/group foundation.
.NOTES
    White-label — the repeatable way. Read-only against Microsoft Graph.
#>
[CmdletBinding()]
param(
    [string]$GroupName = 'iPhone SDM - Devices',
    [string]$CsvPath
)

$ErrorActionPreference = 'Stop'
Connect-MgGraph -Scopes 'DeviceManagementManagedDevices.Read.All','Group.Read.All' | Out-Null

# Resolve the group's member device IDs (best effort)
$memberDeviceNames = @()
try {
    $g = Invoke-MgGraphRequest -Method GET -Uri "https://graph.microsoft.com/v1.0/groups?`$filter=displayName eq '$GroupName'"
    $grp = @($g.value)[0]
    if ($grp) {
        $m = Invoke-MgGraphRequest -Method GET -Uri "https://graph.microsoft.com/v1.0/groups/$($grp.id)/members"
        $memberDeviceNames = @($m.value | ForEach-Object { $_.displayName })
    }
} catch {}

# All managed iOS devices; flag the ones with no primary user (shared)
$rows = @()
try {
    $md = Invoke-MgGraphRequest -Method GET -Uri "https://graph.microsoft.com/v1.0/deviceManagement/managedDevices?`$filter=operatingSystem eq 'iOS'"
    foreach ($d in @($md.value)) {
        $noUser = [string]::IsNullOrWhiteSpace($d.userPrincipalName)
        if ($noUser) {
            $rows += [pscustomobject]@{
                Device    = $d.deviceName
                OSVersion = $d.osVersion
                Ownership = $d.managedDeviceOwnerType
                Supervised= $d.isSupervised
                InGroup   = $(if ($memberDeviceNames -contains $d.deviceName) { 'Yes' } else { 'No' })
            }
        }
    }
} catch { Write-Warning "Could not enumerate iOS devices: $($_.Exception.Message)" }

$rows | Sort-Object InGroup, Device | Format-Table -AutoSize
if ($CsvPath) { $rows | Sort-Object InGroup, Device | Export-Csv -Path $CsvPath -NoTypeInformation; Write-Host "CSV written: $CsvPath" -ForegroundColor Green }

$total = @($rows).Count
$inGrp = @($rows | Where-Object InGroup -eq 'Yes').Count
Write-Host ''
Write-Host ("Shared (no primary user) iOS devices: {0}; in '{1}': {2}." -f $total, $GroupName, $inGrp) -ForegroundColor Cyan
Write-Host "Confirm per-device Shared Device Mode registration on the device (Testing Test 4)." -ForegroundColor DarkGray
