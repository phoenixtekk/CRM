<#
.SYNOPSIS
    MACBYOD-Report.ps1 — BYOD access-posture report for macOS (enrollment model, compliance, CA gating).
.DESCRIPTION
    PURPOSE
        Exports every macOS device in Intune with the fields that matter for BYOD: enrollment model
        (account-driven user enrollment vs device enrollment vs corporate/supervised), ownership,
        supervision, compliance state, and last check-in. Flags Macs that would be BLOCKED by a
        require-compliant Conditional Access gate (non-compliant or unmanaged), so you can see the
        access posture at a glance. Reads only — makes no changes.
    HOW TO RUN
        powershell -ExecutionPolicy Bypass -File .\MACBYOD-Report.ps1
        powershell -ExecutionPolicy Bypass -File .\MACBYOD-Report.ps1 -CsvPath C:\Temp\macos-byod.csv
        Requires the Microsoft Graph PowerShell SDK. Graph scope (read-only):
        DeviceManagementManagedDevices.Read.All.
    EXPECTED RESULTS
        A summary (total Macs, user-enrolled BYOD, personally owned, compliant, and would-be-gated
        counts) plus a CSV with one row per device.
.NOTES
    White-label — the repeatable way. Read-only against Microsoft Graph.
#>
[CmdletBinding()]
param(
    [string]$CsvPath = "$PSScriptRoot\macos-byod-report.csv"
)

$ErrorActionPreference = 'Stop'
if (-not (Get-Module -ListAvailable -Name Microsoft.Graph.Authentication)) { Install-Module Microsoft.Graph -Scope CurrentUser -Force -AllowClobber }
Import-Module Microsoft.Graph.Authentication -ErrorAction Stop
Connect-MgGraph -Scopes 'DeviceManagementManagedDevices.Read.All' -NoWelcome

$rows = New-Object System.Collections.Generic.List[object]
$uri  = "https://graph.microsoft.com/v1.0/deviceManagement/managedDevices?`$filter=operatingSystem eq 'macOS'"

do {
    $page = Invoke-MgGraphRequest -Method GET -Uri $uri
    foreach ($d in $page.value) {
        $isUserEnroll = ($d.deviceEnrollmentType -match 'userEnrollment|appleUserEnrollment') -or
                        ($d.managedDeviceOwnerType -eq 'personal' -and -not [bool]$d.isSupervised)
        $model = if ($isUserEnroll) { 'AccountDriven-UserEnrollment' }
                 elseif ($d.managedDeviceOwnerType -eq 'personal') { 'DeviceEnrollment-BYOD' }
                 elseif ([bool]$d.isSupervised) { 'Corporate-Supervised' }
                 else { 'Corporate-DeviceEnrollment' }
        $wouldGate = ($d.complianceState -ne 'compliant')   # a require-compliant CA policy would block these
        $rows.Add( [pscustomobject]@{
            DeviceName        = $d.deviceName
            Serial            = $d.serialNumber
            OSVersion         = $d.osVersion
            EnrollmentModel   = $model
            EnrollmentType    = $d.deviceEnrollmentType
            Ownership         = $d.managedDeviceOwnerType
            Supervised        = $d.isSupervised
            Compliance        = $d.complianceState
            WouldBeGatedByCA  = $wouldGate
            PrimaryUser       = $d.userPrincipalName
            LastCheckIn       = $d.lastSyncDateTime
        } )
    }
    $uri = $page.'@odata.nextLink'
} while ($uri)

$rows | Sort-Object DeviceName | Export-Csv -Path $CsvPath -NoTypeInformation -Encoding UTF8

$total = $rows.Count
Write-Host "macOS devices:                 $total"
Write-Host "Account-driven user enrollment: $((@($rows | Where-Object { $_.EnrollmentModel -eq 'AccountDriven-UserEnrollment' }).Count))"
Write-Host "Personally owned (BYOD):        $((@($rows | Where-Object { $_.Ownership -eq 'personal' }).Count))"
Write-Host "Compliant:                      $((@($rows | Where-Object { $_.Compliance -eq 'compliant' }).Count))"
Write-Host "Would be BLOCKED by CA gate:    $((@($rows | Where-Object { $_.WouldBeGatedByCA }).Count))"
Write-Host ''
Write-Host "CSV written to: $CsvPath" -ForegroundColor Green
Disconnect-MgGraph | Out-Null
