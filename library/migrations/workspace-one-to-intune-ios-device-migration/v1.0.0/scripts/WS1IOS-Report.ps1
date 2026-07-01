<#
.SYNOPSIS
    WS1IOS-Report.ps1 — fleet migration status and app-parity report for the iOS/iPadOS migration.

.DESCRIPTION
    PURPOSE
        Produces a fleet view of the migration: every iOS/iPadOS device in Intune with supervision,
        enrollment type (ADE vs other), compliance, and last check-in; plus an app-parity summary
        listing the iOS apps published in Intune and their install counts. Use it to track waves and
        confirm parity apps are landing. Read-only.

    HOW TO RUN
        Install-Module Microsoft.Graph -Scope CurrentUser   # once
        .\WS1IOS-Report.ps1
        .\WS1IOS-Report.ps1 -CsvPath .\ws1ios-migration.csv   # also export devices to CSV

    EXPECTED RESULTS
        A device table (supervision, ADE, compliance, last sync) and an app-parity table (app name,
        publisher, install count). Optional CSV of the device rows.

.NOTES
    Read-only. The repeatable Workspace ONE to Intune iOS/iPadOS migration.
#>
[CmdletBinding()]
param(
    [string]$CsvPath
)

$ErrorActionPreference = 'Stop'
Connect-MgGraph -Scopes 'DeviceManagementManagedDevices.Read.All','DeviceManagementApps.Read.All' | Out-Null

function GraphGet($uri) { (Invoke-MgGraphRequest -Method GET -Uri $uri).value }

# Devices
$uri = "https://graph.microsoft.com/v1.0/deviceManagement/managedDevices?`$filter=operatingSystem eq 'iOS'&`$select=deviceName,serialNumber,osVersion,isSupervised,deviceEnrollmentType,complianceState,lastSyncDateTime,userPrincipalName"
$devices = @()
do { $r = Invoke-MgGraphRequest -Method GET -Uri $uri; $devices += $r.value; $uri = $r.'@odata.nextLink' } while ($uri)

$deviceRows = $devices | Select-Object deviceName, serialNumber, osVersion, isSupervised,
    @{n='Enrollment';e={$_.deviceEnrollmentType}}, complianceState, lastSyncDateTime, userPrincipalName

Write-Host "=== iOS/iPadOS device migration status ($($devices.Count) devices) ===" -ForegroundColor Cyan
$deviceRows | Sort-Object deviceName | Format-Table -AutoSize

$superv = ($devices | Where-Object { $_.isSupervised }).Count
$ade    = ($devices | Where-Object { $_.deviceEnrollmentType -match 'appleBulk|deviceEnrollmentProgram|AutomatedDeviceEnrollment' }).Count
$compl  = ($devices | Where-Object { $_.complianceState -eq 'compliant' }).Count
Write-Host "Supervised: $superv / $($devices.Count)   ADE-enrolled: $ade / $($devices.Count)   Compliant: $compl / $($devices.Count)"

if ($CsvPath) { $deviceRows | Export-Csv -Path $CsvPath -NoTypeInformation; Write-Host "Devices exported to $CsvPath" -ForegroundColor Green }

# App parity (iOS apps in Intune + install summary)
Write-Host ''
Write-Host '=== App parity (iOS apps published in Intune) ===' -ForegroundColor Cyan
$apps = GraphGet "https://graph.microsoft.com/v1.0/deviceAppManagement/mobileApps?`$select=id,displayName,publisher,'@odata.type'"
$iosApps = $apps | Where-Object { $_.'@odata.type' -match 'ios' }
if (-not $iosApps) { Write-Host 'No iOS apps found in Intune.' -ForegroundColor Yellow; return }

$appRows = foreach ($a in $iosApps) {
    $installed = $null
    try {
        $sum = Invoke-MgGraphRequest -Method GET -Uri "https://graph.microsoft.com/v1.0/deviceAppManagement/mobileApps/$($a.id)/installSummary"
        $installed = $sum.installedDeviceCount
    } catch { $installed = 'n/a' }
    [pscustomobject]@{ App = $a.displayName; Publisher = $a.publisher; InstalledDevices = $installed }
}
$appRows | Sort-Object App | Format-Table -AutoSize
