<#
.SYNOPSIS
    DUALDEV-DeviceReport.ps1 — tenant inventory by ownership, plus users who have both COD and BYOD.

.DESCRIPTION
    PURPOSE
        Exports every managed device with ownership (Corporate/Personal), platform, enrollment type,
        compliance, and primary user — then lists users who own BOTH a corporate and a personal
        device (the population this solution is designed for).

    HOW TO RUN
        Install-Module Microsoft.Graph -Scope CurrentUser   # once
        .\DUALDEV-DeviceReport.ps1
        .\DUALDEV-DeviceReport.ps1 -CsvPath C:\Temp\cod-byod.csv

    EXPECTED RESULTS
        A summary (totals by ownership/compliance), a CSV per device, and a printed list of users with
        both device types. Read-only.

.NOTES
    White-label — Intune Solutions. Read-only.
#>
[CmdletBinding()]
param(
    [string]$CsvPath = "$PSScriptRoot\cod-byod-report.csv"
)

$ErrorActionPreference = 'Stop'
Connect-MgGraph -Scopes 'DeviceManagementManagedDevices.Read.All' | Out-Null

$rows = New-Object System.Collections.Generic.List[object]
$uri  = 'https://graph.microsoft.com/v1.0/deviceManagement/managedDevices'
do {
    $page = Invoke-MgGraphRequest -Method GET -Uri $uri
    foreach ($d in $page.value) {
        $rows.Add( [pscustomobject]@{
            DeviceName     = $d.deviceName
            User           = $d.userPrincipalName
            Platform       = $d.operatingSystem
            OSVersion      = $d.osVersion
            Ownership      = $d.managedDeviceOwnerType
            EnrollmentType = $d.deviceEnrollmentType
            Compliance     = $d.complianceState
            LastCheckIn    = $d.lastSyncDateTime
        } )
    }
    $uri = $page.'@odata.nextLink'
} while ($uri)

$rows | Sort-Object User, Ownership | Export-Csv -Path $CsvPath -NoTypeInformation -Encoding UTF8

$total = $rows.Count
Write-Host "Managed devices:      $total"
Write-Host "Corporate (COD):      $((@($rows | Where-Object Ownership -eq 'company').Count))"
Write-Host "Personal (BYOD):      $((@($rows | Where-Object Ownership -eq 'personal').Count))"
Write-Host "Compliant:            $((@($rows | Where-Object Compliance -eq 'compliant').Count))"
Write-Host ''

# Users who own BOTH a corporate and a personal device
$both = $rows | Where-Object { $_.User } | Group-Object User | Where-Object {
    ($_.Group.Ownership -contains 'company') -and ($_.Group.Ownership -contains 'personal')
}
Write-Host "Users with BOTH a COD and a BYOD device: $((@($both).Count))" -ForegroundColor Cyan
$both | ForEach-Object { Write-Host "  $($_.Name)" }
Write-Host ''
Write-Host "CSV written to: $CsvPath" -ForegroundColor Green
