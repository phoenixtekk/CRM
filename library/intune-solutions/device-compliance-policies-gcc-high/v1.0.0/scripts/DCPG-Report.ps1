<#
.SYNOPSIS
    DCPG-Report.ps1 — per-device compliance rollup for a GCC High tenant (status and audit evidence).
.DESCRIPTION
    PURPOSE
        Read-only reporting of device compliance state in a US Government (GCC High)
        tenant. Summarizes how many managed devices are compliant, noncompliant, in
        grace period, or not evaluated, with a per-device breakdown you can export for a
        status report or CMMC/NIST audit evidence. Connects to US Gov Graph only.
    HOW TO RUN
        powershell -ExecutionPolicy Bypass -File .\DCPG-Report.ps1
        (Graph scopes: DeviceManagementManagedDevices.Read.All; -Environment USGov)
        Add -CsvPath .\compliance-report.csv to save the per-device detail.
    EXPECTED RESULTS
        A summary count by compliance state, a compliance percentage, and (optionally) a
        CSV of every device with its state. Makes NO changes.
.NOTES
    White-label — the repeatable way. Read-only against Microsoft Graph US Gov endpoints.
#>

[CmdletBinding()]
param(
    [ValidateSet('USGov', 'USGovDoD')]
    [string]$Environment = 'USGov',

    [string]$CsvPath
)

$ErrorActionPreference = 'Stop'

try {
    $scopes = @('DeviceManagementManagedDevices.Read.All')
    Write-Host "Connecting to Microsoft Graph (Environment: $Environment)..." -ForegroundColor Cyan
    Connect-MgGraph -Environment $Environment -Scopes $scopes | Out-Null
    $ctx = Get-MgContext
    if ($ctx.Environment -ne $Environment) {
        throw "Connected to '$($ctx.Environment)', expected '$Environment'. Reconnect with -Environment $Environment."
    }
    Write-Host "Connected. Environment: $($ctx.Environment)" -ForegroundColor Green

    Write-Host "`nRetrieving managed devices..." -ForegroundColor Cyan
    $devices = Get-MgDeviceManagementManagedDevice -All `
        -Property 'deviceName,operatingSystem,osVersion,complianceState,lastSyncDateTime,userPrincipalName,ownerType' `
        -ErrorAction Stop

    if (-not $devices -or $devices.Count -eq 0) {
        Write-Host "No managed devices found in this ($Environment) tenant." -ForegroundColor Yellow
        return
    }

    $rows = foreach ($d in $devices) {
        [pscustomobject]@{
            DeviceName      = $d.DeviceName
            OS              = $d.OperatingSystem
            OSVersion       = $d.OsVersion
            ComplianceState = $d.ComplianceState
            User            = $d.UserPrincipalName
            Ownership       = $d.OwnerType
            LastSync        = $d.LastSyncDateTime
        }
    }

    Write-Host "`n=== Compliance summary ($Environment) ===`n" -ForegroundColor Green
    $summary = $rows | Group-Object ComplianceState | Sort-Object Name
    $summary | Format-Table @{n='ComplianceState';e={$_.Name}}, @{n='Devices';e={$_.Count}} -AutoSize

    $total = $rows.Count
    $compliant = ($rows | Where-Object { $_.ComplianceState -eq 'compliant' }).Count
    $pct = if ($total -gt 0) { [math]::Round(($compliant / $total) * 100, 1) } else { 0 }
    Write-Host "Total managed devices : $total" -ForegroundColor Cyan
    Write-Host "Compliant             : $compliant ($pct%)" -ForegroundColor Cyan

    if ($CsvPath) {
        $rows | Sort-Object ComplianceState, DeviceName | Export-Csv -Path $CsvPath -NoTypeInformation -Encoding UTF8
        Write-Host "Per-device detail written to: $CsvPath" -ForegroundColor Green
    } else {
        Write-Host "`n(Use -CsvPath to export the per-device detail.)" -ForegroundColor DarkGray
    }
}
finally {
    if (Get-MgContext) { Disconnect-MgGraph | Out-Null; Write-Host "`nDisconnected from Microsoft Graph." -ForegroundColor DarkGray }
}
