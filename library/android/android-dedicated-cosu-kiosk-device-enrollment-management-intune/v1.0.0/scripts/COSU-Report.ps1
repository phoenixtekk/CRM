<#
.SYNOPSIS
    COSU-Report.ps1 — enrolled dedicated-fleet health / inventory report (read-only).
.DESCRIPTION
    PURPOSE
        Reports the enrolled Android DEDICATED (COSU) fleet: device count, compliance state, last
        check-in freshness (flags stale devices), OS version spread, and an OEM breakdown by
        manufacturer/model (e.g. Zebra, Samsung) — so you can audit fleet health and spot drifted or
        offline devices. Read-only against Microsoft Graph.
    HOW TO RUN
        powershell -ExecutionPolicy Bypass -File .\COSU-Report.ps1
        ... -DeviceGroup 'Android Dedicated - Devices - Pilot' -StaleDays 7
        Requires the Microsoft Graph PowerShell SDK and delegated scopes:
        DeviceManagementManagedDevices.Read.All, Group.Read.All.
    EXPECTED RESULTS
        A dedicated-device count with compliance/last-check-in/OS/OEM breakdowns and a per-device list;
        stale devices (no check-in within -StaleDays) are flagged. Read-only.
.NOTES
    Android category — Android dedicated (COSU)/kiosk. Read-only. Enrollment-type enum values may vary by version — verify against your tenant.
#>
[CmdletBinding()]
param(
    [string]$DeviceGroup = 'Android Dedicated - Devices - Pilot',
    [int]$StaleDays      = 7
)

if (-not (Get-Module -ListAvailable -Name Microsoft.Graph.Authentication)) {
    Install-Module Microsoft.Graph -Scope CurrentUser -Force -AllowClobber
}
Import-Module Microsoft.Graph.Authentication -ErrorAction Stop
Connect-MgGraph -Scopes 'DeviceManagementManagedDevices.Read.All','Group.Read.All' -NoWelcome

Write-Host "`n=== Android dedicated (COSU) fleet health / inventory ===" -ForegroundColor Cyan

# Pull Android dedicated devices. Prefer the dedicated enrollment type; fall back to the device group.
$devices = @()
try {
    $uri = "/beta/deviceManagement/managedDevices?`$filter=operatingSystem eq 'Android'&`$select=deviceName,id,complianceState,lastSyncDateTime,osVersion,manufacturer,model,deviceEnrollmentType,userId"
    $devices = (Invoke-MgGraphRequest -Method GET -Uri $uri).value
} catch { Write-Host "  (unable to read managed devices)" -ForegroundColor Yellow }

# Dedicated = Android device-owner, no user. Match enrollment type or user-less device-owner.
$dedicated = $devices | Where-Object {
    "$($_.deviceEnrollmentType)" -like '*androidEnterpriseDedicatedDevice*' -or
    ("$($_.deviceEnrollmentType)" -like '*android*' -and -not $_.userId)
}
if (-not $dedicated -or $dedicated.Count -eq 0) {
    Write-Host "No dedicated Android devices found yet (enroll a pilot device — Implementation Step 7)." -ForegroundColor Yellow
    Disconnect-MgGraph | Out-Null; return
}

Write-Host ("Dedicated devices : {0}" -f $dedicated.Count) -ForegroundColor Green

# Compliance breakdown
Write-Host "`n-- Compliance --" -ForegroundColor Cyan
$dedicated | Group-Object complianceState | Sort-Object Name | ForEach-Object {
    $col = if ($_.Name -eq 'compliant') { 'Green' } else { 'Yellow' }
    Write-Host ("  {0,-14}: {1}" -f $_.Name, $_.Count) -ForegroundColor $col
}

# Stale check-in
Write-Host "`n-- Check-in freshness --" -ForegroundColor Cyan
$cut = (Get-Date).AddDays(-$StaleDays)
$stale = $dedicated | Where-Object { $_.lastSyncDateTime -and ([datetime]$_.lastSyncDateTime -lt $cut) }
Write-Host ("  Checked in <= {0}d : {1}" -f $StaleDays, ($dedicated.Count - @($stale).Count)) -ForegroundColor Green
if ($stale) {
    Write-Host ("  STALE (> {0}d)     : {1}" -f $StaleDays, @($stale).Count) -ForegroundColor Yellow
    $stale | ForEach-Object { Write-Host ("        - {0}  (last {1})" -f $_.deviceName, $_.lastSyncDateTime) }
}

# OS version spread
Write-Host "`n-- OS version --" -ForegroundColor Cyan
$dedicated | Group-Object osVersion | Sort-Object Name | ForEach-Object { Write-Host ("  Android {0,-8}: {1}" -f $_.Name, $_.Count) }

# OEM breakdown
Write-Host "`n-- OEM (manufacturer / model) --" -ForegroundColor Cyan
$dedicated | Group-Object manufacturer | Sort-Object Count -Descending | ForEach-Object {
    Write-Host ("  {0,-14}: {1}" -f $_.Name, $_.Count) -ForegroundColor Green
    $_.Group | Group-Object model | Sort-Object Count -Descending | ForEach-Object { Write-Host ("      {0,-18} {1}" -f $_.Name, $_.Count) }
}

# Per-device
Write-Host "`n-- Per-device --" -ForegroundColor Cyan
$dedicated | Sort-Object deviceName |
    Select-Object deviceName, complianceState, osVersion, manufacturer, model, lastSyncDateTime |
    Format-Table -AutoSize | Out-String | Write-Host

Write-Host ("Note: device group '{0}' membership can be cross-checked in Entra; dynamic membership updates a few minutes after enrollment." -f $DeviceGroup) -ForegroundColor DarkGray
Disconnect-MgGraph | Out-Null
