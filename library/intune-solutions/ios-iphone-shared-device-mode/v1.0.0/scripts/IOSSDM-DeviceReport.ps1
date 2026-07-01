<#
.SYNOPSIS
    IOSSDM-DeviceReport.ps1 — inventory of shared iOS iPhones (DEM-enrolled, supervised, no user).

.DESCRIPTION
    PURPOSE
        Exports every iOS managed device that looks like a shared appliance phone — no primary user —
        with supervision state, enrolled-by account, compliance, OS version, and last check-in. Flags
        any iOS device that unexpectedly HAS a primary user (i.e. not truly shared).

    HOW TO RUN
        Install-Module Microsoft.Graph -Scope CurrentUser   # once
        .\IOSSDM-DeviceReport.ps1
        .\IOSSDM-DeviceReport.ps1 -CsvPath C:\Temp\shared-iphones.csv
        .\IOSSDM-DeviceReport.ps1 -DemAccountLike dem-ios-shared

    EXPECTED RESULTS
        A summary (counts of shared vs. with-primary-user, supervised, compliant), a CSV per device,
        and a printed list of iOS devices that have a primary user (review these). Read-only.

.NOTES
    Phoenixtekk Workplace Marketplace — Intune Solutions. Read-only.
#>
[CmdletBinding()]
param(
    [string]$CsvPath = "$PSScriptRoot\shared-iphones-report.csv",
    [string]$DemAccountLike
)

$ErrorActionPreference = 'Stop'
Connect-MgGraph -Scopes 'DeviceManagementManagedDevices.Read.All' | Out-Null

# Pull all iOS managed devices (page through)
$uri = "https://graph.microsoft.com/v1.0/deviceManagement/managedDevices?`$filter=operatingSystem eq 'iOS'&`$select=deviceName,serialNumber,operatingSystem,osVersion,isSupervised,userId,userPrincipalName,complianceState,enrolledDateTime,lastSyncDateTime,managedDeviceOwnerType"
$devices = @()
do {
    $resp = Invoke-MgGraphRequest -Method GET -Uri $uri
    $devices += $resp.value
    $uri = $resp.'@odata.nextLink'
} while ($uri)

if ($DemAccountLike) { $devices = $devices | Where-Object { $_.userPrincipalName -like "*$DemAccountLike*" -or [string]::IsNullOrEmpty($_.userId) } }

$rows = $devices | ForEach-Object {
    [pscustomobject]@{
        DeviceName   = $_.deviceName
        Serial       = $_.serialNumber
        OS           = "$($_.operatingSystem) $($_.osVersion)"
        Supervised   = [bool]$_.isSupervised
        Shared       = [string]::IsNullOrEmpty($_.userId)
        EnrolledBy   = $_.userPrincipalName
        Compliance   = $_.complianceState
        Enrolled     = $_.enrolledDateTime
        LastSync     = $_.lastSyncDateTime
    }
}

$rows | Sort-Object Shared, DeviceName | Export-Csv -NoTypeInformation -Path $CsvPath
Write-Host "CSV written: $CsvPath" -ForegroundColor Cyan
Write-Host ''
Write-Host ("Total iOS devices    : {0}" -f $rows.Count)
Write-Host ("Shared (no user)     : {0}" -f ($rows | Where-Object Shared).Count)
Write-Host ("Supervised           : {0}" -f ($rows | Where-Object Supervised).Count)
Write-Host ("Compliant            : {0}" -f ($rows | Where-Object { $_.Compliance -eq 'compliant' }).Count)

$withUser = $rows | Where-Object { -not $_.Shared }
if ($withUser) {
    Write-Host ''
    Write-Host 'iOS devices WITH a primary user (review — should shared phones be here?):' -ForegroundColor Yellow
    $withUser | Format-Table DeviceName, Serial, EnrolledBy -AutoSize
}
