<#
.SYNOPSIS
    JAMFADE-DeviceReport.ps1 — tenant-wide macOS report (Entra registration + Intune compliance).

.DESCRIPTION
    PURPOSE
        Produces a CSV of every macOS device known to Intune (including Jamf partner-managed
        records): device name, serial, OS version, ownership, management agent, compliance state,
        Entra registration, and last sync. Use it monthly to track Platform SSO registration coverage
        and Conditional-Access readiness across the Jamf-managed fleet.

    HOW TO RUN
        Install-Module Microsoft.Graph -Scope CurrentUser   # once
        .\JAMFADE-DeviceReport.ps1                            # writes .\JAMFADE-macOS-report.csv
        .\JAMFADE-DeviceReport.ps1 -Path C:\Temp\macs.csv
        Reads only — makes no changes.

    EXPECTED RESULTS
        A CSV at the chosen path and a console summary: total Macs, compliant count, partner-managed
        (Jamf) count, and registered count.

.NOTES
    White-label — Intune Solutions. Read-only.
#>
[CmdletBinding()]
param([string]$Path = ".\JAMFADE-macOS-report.csv")

$ErrorActionPreference = 'Stop'
Connect-MgGraph -Scopes 'DeviceManagementManagedDevices.Read.All','Device.Read.All' | Out-Null

# Pull all macOS managed devices (paged)
$devices = New-Object System.Collections.Generic.List[object]
$uri = "https://graph.microsoft.com/v1.0/deviceManagement/managedDevices?`$filter=operatingSystem eq 'macOS'"
do {
    $page = Invoke-MgGraphRequest -Method GET -Uri $uri
    foreach ($d in $page.value) { $devices.Add($d) }
    $uri = $page.'@odata.nextLink'
} while ($uri)

# Build an Entra device name lookup for registration status
$registered = @{}
try {
    $au = "https://graph.microsoft.com/v1.0/devices?`$filter=operatingSystem eq 'MacMDM' or operatingSystem eq 'macOS' or operatingSystem eq 'Mac OS X'&`$select=displayName,trustType,accountEnabled"
    do {
        $ap = Invoke-MgGraphRequest -Method GET -Uri $au
        foreach ($e in $ap.value) { if ($e.displayName) { $registered[$e.displayName] = $e.trustType } }
        $au = $ap.'@odata.nextLink'
    } while ($au)
} catch { Write-Warning "Entra device lookup limited: $($_.Exception.Message)" }

$rows = foreach ($d in $devices) {
    [pscustomobject]@{
        DeviceName      = $d.deviceName
        SerialNumber    = $d.serialNumber
        OSVersion       = $d.osVersion
        Ownership       = $d.managedDeviceOwnerType
        ManagementAgent = $d.managementAgent
        Compliance      = $d.complianceState
        EntraRegistered = $(if ($registered.ContainsKey($d.deviceName)) { "Yes ($($registered[$d.deviceName]))" } else { 'No/Unknown' })
        LastSync        = $d.lastSyncDateTime
    }
}

$rows | Sort-Object DeviceName | Export-Csv -Path $Path -NoTypeInformation -Encoding UTF8

$total      = $rows.Count
$compliant  = @($rows | Where-Object Compliance -eq 'compliant').Count
$partner    = @($rows | Where-Object { $_.ManagementAgent -match 'jamf|partner' }).Count
$reg        = @($rows | Where-Object { $_.EntraRegistered -like 'Yes*' }).Count
Write-Host ""
Write-Host "macOS devices: $total | compliant: $compliant | partner-managed (Jamf): $partner | Entra-registered: $reg" -ForegroundColor Cyan
Write-Host "CSV written to: $Path" -ForegroundColor Green
