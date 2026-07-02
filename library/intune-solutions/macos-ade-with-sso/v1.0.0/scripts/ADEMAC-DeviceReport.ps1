<#
.SYNOPSIS
    ADEMAC-DeviceReport.ps1 — tenant-wide inventory of managed Macs and their enrollment/SSO posture.

.DESCRIPTION
    PURPOSE
        Exports every macOS device in Intune with the fields that matter for this solution:
        enrollment type (ADE vs. other), OS version, ownership, supervision, compliance, last
        check-in, and primary user. Use it to measure ADE coverage and Platform SSO rollout.

    HOW TO RUN
        Install-Module Microsoft.Graph -Scope CurrentUser   # once
        .\ADEMAC-DeviceReport.ps1
        .\ADEMAC-DeviceReport.ps1 -CsvPath C:\Temp\macos-fleet.csv

    EXPECTED RESULTS
        A summary (total Macs, ADE count, supervised count, compliant count) plus a CSV with one
        row per device. Read-only.

.NOTES
    White-label — Intune Solutions. Read-only.
#>
[CmdletBinding()]
param(
    [string]$CsvPath = "$PSScriptRoot\macos-fleet-report.csv"
)

$ErrorActionPreference = 'Stop'
Connect-MgGraph -Scopes 'DeviceManagementManagedDevices.Read.All' | Out-Null

$rows = New-Object System.Collections.Generic.List[object]
$uri  = "https://graph.microsoft.com/v1.0/deviceManagement/managedDevices?`$filter=operatingSystem eq 'macOS'"

do {
    $page = Invoke-MgGraphRequest -Method GET -Uri $uri
    foreach ($d in $page.value) {
        $rows.Add( [pscustomobject]@{
            DeviceName     = $d.deviceName
            Serial         = $d.serialNumber
            OSVersion      = $d.osVersion
            EnrollmentType = $d.deviceEnrollmentType
            IsADE          = [bool]($d.deviceEnrollmentType -match 'depDeviceEnrollment|appleBulkWith')
            Supervised     = $d.isSupervised
            Ownership      = $d.managedDeviceOwnerType
            Compliance     = $d.complianceState
            PrimaryUser    = $d.userPrincipalName
            LastCheckIn    = $d.lastSyncDateTime
        } )
    }
    $uri = $page.'@odata.nextLink'
} while ($uri)

$rows | Sort-Object DeviceName | Export-Csv -Path $CsvPath -NoTypeInformation -Encoding UTF8

$total = $rows.Count
Write-Host "macOS devices:        $total"
Write-Host "ADE-enrolled:         $((@($rows | Where-Object IsADE).Count))"
Write-Host "Supervised:           $((@($rows | Where-Object { $_.Supervised }).Count))"
Write-Host "Compliant:            $((@($rows | Where-Object { $_.Compliance -eq 'compliant' }).Count))"
Write-Host "macOS 13+ :           $((@($rows | Where-Object { try { [version]($_.OSVersion -replace '[^0-9.].*$') -ge [version]'13.0' } catch { $false } }).Count))"
Write-Host ''
Write-Host "CSV written to: $CsvPath" -ForegroundColor Green
