<#
.SYNOPSIS
    WS1DROID-Report.ps1 — Android migration status and app-parity gap report (read-only).
.DESCRIPTION
    PURPOSE
        Produces a migration status report for the Android estate in Intune: per-device mode,
        compliance, and last check-in, plus an app-parity gap — the in-scope managed Google Play apps
        assigned in Intune compared against an expected app list (your source parity target). Helps you
        confirm a ring re-enrolled cleanly with full app parity. Read-only — changes nothing.
    HOW TO RUN
        powershell -ExecutionPolicy Bypass -File .\WS1DROID-Report.ps1 -ExpectedAppsCsv .\expected-apps.csv
        The CSV is optional and has a single column 'packageId' (one expected app package per row).
        Requires the Microsoft Graph SDK and read scopes (DeviceManagementApps.Read.All,
        DeviceManagementManagedDevices.Read.All).
    EXPECTED RESULTS
        A per-device status table and, if a CSV is supplied, a list of expected app package ids that are
        NOT currently present as assigned Android apps in Intune (the parity gap). No changes are made.
.NOTES
    Workplace Marketplace — Migrations. Read-only against Microsoft Graph.
#>
[CmdletBinding()] param(
    [string]$ExpectedAppsCsv
)

if (-not (Get-Module -ListAvailable -Name Microsoft.Graph.Authentication)) {
    Install-Module Microsoft.Graph -Scope CurrentUser -Force -AllowClobber
}
Import-Module Microsoft.Graph.Authentication -ErrorAction Stop
Connect-MgGraph -Scopes 'DeviceManagementApps.Read.All','DeviceManagementManagedDevices.Read.All' -NoWelcome

Write-Host "=== Android migration status report (read-only) ===" -ForegroundColor Cyan

# Per-device migration status
Write-Host "`n--- Device status ---" -ForegroundColor Cyan
try {
    $select = 'deviceName,managedDeviceOwnerType,deviceEnrollmentType,complianceState,lastSyncDateTime,osVersion'
    $devices = (Invoke-MgGraphRequest -Method GET -Uri "/v1.0/deviceManagement/managedDevices?`$filter=operatingSystem eq 'Android'&`$select=$select").value
    if ($devices) {
        foreach ($d in $devices) {
            Write-Host ("  {0,-26} owner={1,-12} enroll={2,-28} compliance={3,-12} lastSync={4}" -f `
                $d.deviceName, $d.managedDeviceOwnerType, $d.deviceEnrollmentType, $d.complianceState, $d.lastSyncDateTime)
        }
        Write-Host ("  Total Android devices: {0}" -f $devices.Count)
    } else { Write-Host "  No Android managed devices found." -ForegroundColor Yellow }
} catch { Write-Host "  Could not read managed devices: $($_.Exception.Message)" -ForegroundColor Yellow }

# Assigned Android apps (managed Google Play / Android store)
Write-Host "`n--- Assigned Android apps (parity set) ---" -ForegroundColor Cyan
$assignedPackages = @()
try {
    $apps = (Invoke-MgGraphRequest -Method GET -Uri "/beta/deviceAppManagement/mobileApps?`$filter=isof('microsoft.graph.androidManagedStoreApp')").value
    foreach ($a in $apps) {
        $pkg = $a.packageId
        if ($pkg) { $assignedPackages += $pkg }
        Write-Host ("  {0}  [{1}]" -f $a.displayName, $pkg)
    }
    Write-Host ("  Android store apps in tenant: {0}" -f $apps.Count)
} catch { Write-Host "  Could not read Android apps: $($_.Exception.Message)" -ForegroundColor Yellow }

# App-parity gap vs expected list
if ($ExpectedAppsCsv) {
    Write-Host "`n--- App-parity gap (expected vs present) ---" -ForegroundColor Cyan
    if (Test-Path $ExpectedAppsCsv) {
        $expected = Import-Csv -Path $ExpectedAppsCsv | ForEach-Object { $_.packageId } | Where-Object { $_ }
        $missing = $expected | Where-Object { $assignedPackages -notcontains $_ }
        if ($missing) {
            Write-Host "  MISSING from Intune (parity gap):" -ForegroundColor Yellow
            $missing | ForEach-Object { Write-Host ("    {0}" -f $_) -ForegroundColor Yellow }
        } else { Write-Host "  Parity gap is ZERO — every expected app is present." -ForegroundColor Green }
    } else { Write-Host "  Expected-apps CSV not found: $ExpectedAppsCsv" -ForegroundColor Yellow }
} else {
    Write-Host "`n(No -ExpectedAppsCsv supplied; skipping the parity-gap comparison.)" -ForegroundColor DarkGray
}

Disconnect-MgGraph | Out-Null
