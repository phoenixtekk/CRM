<#
.SYNOPSIS
    ENROLLID-Discovery.ps1 — enrollment posture and primary-user coverage across the fleet (Microsoft Graph).
.DESCRIPTION
    PURPOSE
        Summarizes managed devices by operating system, ownership (corporate vs. personal), and
        enrollment profile/type, and reports how many devices have a primary user vs. none — so you
        can see the current enrollment posture before configuring.
    HOW TO RUN
        powershell -ExecutionPolicy Bypass -File .\ENROLLID-Discovery.ps1 -CsvPath C:\Temp\enrollid.csv
        Requires the Microsoft Graph SDK and DeviceManagementManagedDevices.Read.All.
    EXPECTED RESULTS
        Device counts by OS and ownership, a breakdown of primary-user coverage, and an optional
        per-device CSV (device, OS, ownership, enrollment type, primary user).
.NOTES
    Phoenixtekk Workplace Marketplace — Intune Solutions. Read-only against Graph.
#>
[CmdletBinding()] param([string]$CsvPath)
if (-not (Get-Module -ListAvailable -Name Microsoft.Graph.Authentication)) { Install-Module Microsoft.Graph -Scope CurrentUser -Force -AllowClobber }
Import-Module Microsoft.Graph.Authentication -ErrorAction Stop
Connect-MgGraph -Scopes 'DeviceManagementManagedDevices.Read.All' -NoWelcome
$devs = @(); $uri = "/v1.0/deviceManagement/managedDevices?`$select=deviceName,operatingSystem,osVersion,managedDeviceOwnerType,deviceEnrollmentType,userPrincipalName,lastSyncDateTime"
do { $r = Invoke-MgGraphRequest -Method GET -Uri $uri; $devs += $r.value; $uri = $r.'@odata.nextLink' } while ($uri)
$report = $devs | ForEach-Object {
    [pscustomobject]@{
        Device         = $_.deviceName
        OS             = $_.operatingSystem
        OSVersion      = $_.osVersion
        Ownership      = $_.managedDeviceOwnerType
        EnrollmentType = $_.deviceEnrollmentType
        PrimaryUser    = $_.userPrincipalName
        HasPrimaryUser = [bool]$_.userPrincipalName
        LastSync       = $_.lastSyncDateTime
    }
}
Write-Host "`n=== Enrollment posture ===" -ForegroundColor Cyan
$report | Group-Object OS | Select-Object Count, @{n='OS';e={$_.Name}} | Format-Table -AutoSize
Write-Host "=== Ownership ===" -ForegroundColor Cyan
$report | Group-Object Ownership | Select-Object Count, @{n='Ownership';e={$_.Name}} | Format-Table -AutoSize
Write-Host "=== Enrollment type ===" -ForegroundColor Cyan
$report | Group-Object EnrollmentType | Select-Object Count, @{n='EnrollmentType';e={$_.Name}} | Format-Table -AutoSize
$withPU = ($report | Where-Object HasPrimaryUser).Count
Write-Host ("Primary-user coverage : {0} of {1} devices have a primary user" -f $withPU, $report.Count) -ForegroundColor Cyan
if ($CsvPath) { $report | Export-Csv -Path $CsvPath -NoTypeInformation; Write-Host "Saved $CsvPath" }
Disconnect-MgGraph | Out-Null
