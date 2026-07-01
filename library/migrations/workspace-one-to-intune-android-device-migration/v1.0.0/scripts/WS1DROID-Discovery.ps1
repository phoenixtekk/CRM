<#
.SYNOPSIS
    WS1DROID-Discovery.ps1 — Android migration-readiness discovery for Workspace ONE to Intune (read-only).
.DESCRIPTION
    PURPOSE
        Reports the Intune target readiness for an Android Enterprise migration: the managed Google
        Play / Android enterprise binding state, the Android enrollment profiles that exist, and an
        inventory of Android managed devices by ownership/mode. Read-only — it changes nothing.
        Workspace ONE-side inventory (source device-to-mode export) is deferred to VMware docs.
    HOW TO RUN
        powershell -ExecutionPolicy Bypass -File .\WS1DROID-Discovery.ps1
        Requires the Microsoft Graph PowerShell SDK and read scopes
        (DeviceManagementConfiguration.Read.All, DeviceManagementManagedDevices.Read.All).
    EXPECTED RESULTS
        Prints whether managed Google Play is bound (gate zero), lists Android enrollment profiles,
        and summarizes Android devices by ownership. No changes are made.
.NOTES
    Workplace Marketplace — Migrations. Read-only against Microsoft Graph.
#>
[CmdletBinding()] param()

if (-not (Get-Module -ListAvailable -Name Microsoft.Graph.Authentication)) {
    Install-Module Microsoft.Graph -Scope CurrentUser -Force -AllowClobber
}
Import-Module Microsoft.Graph.Authentication -ErrorAction Stop
Connect-MgGraph -Scopes 'DeviceManagementConfiguration.Read.All','DeviceManagementManagedDevices.Read.All' -NoWelcome

Write-Host "=== Android migration discovery (read-only) ===" -ForegroundColor Cyan

# Gate zero: managed Google Play / Android enterprise binding
Write-Host "`n--- Managed Google Play binding (gate zero) ---" -ForegroundColor Cyan
try {
    $settings = Invoke-MgGraphRequest -Method GET -Uri '/beta/deviceManagement/androidManagedStoreAccountEnterpriseSettings'
    if ($settings -and $settings.bindStatus) {
        Write-Host ("  Bind status : {0}" -f $settings.bindStatus)
        Write-Host ("  Owner email : {0}" -f $settings.ownerUserPrincipalName)
        Write-Host ("  Last sync   : {0}" -f $settings.lastAppSyncDateTime)
        if ($settings.bindStatus -eq 'bound') { Write-Host "  RESULT: managed Google Play is CONNECTED." -ForegroundColor Green }
        else { Write-Host "  RESULT: managed Google Play is NOT fully bound — connect before migrating." -ForegroundColor Yellow }
    } else {
        Write-Host "  RESULT: no managed Google Play binding found — connect it (gate zero)." -ForegroundColor Yellow
    }
} catch { Write-Host "  Could not read managed Google Play settings: $($_.Exception.Message)" -ForegroundColor Yellow }

# Android enrollment profiles (corporate-owned, fully managed / dedicated)
Write-Host "`n--- Android enrollment profiles ---" -ForegroundColor Cyan
try {
    $profiles = (Invoke-MgGraphRequest -Method GET -Uri '/beta/deviceManagement/androidDeviceOwnerEnrollmentProfiles').value
    if ($profiles) { foreach ($p in $profiles) { Write-Host ("  {0}  (tokenExpires: {1})" -f $p.displayName, $p.tokenExpirationDateTime) } }
    else { Write-Host "  No corporate-owned (fully managed / dedicated) enrollment profiles found." -ForegroundColor Yellow }
} catch { Write-Host "  Could not read enrollment profiles: $($_.Exception.Message)" -ForegroundColor Yellow }

# Android device inventory by ownership
Write-Host "`n--- Android managed devices (by ownership) ---" -ForegroundColor Cyan
try {
    $devices = (Invoke-MgGraphRequest -Method GET -Uri "/v1.0/deviceManagement/managedDevices?`$filter=operatingSystem eq 'Android'&`$select=deviceName,managedDeviceOwnerType,managedDeviceName,complianceState").value
    if ($devices) {
        $devices | Group-Object managedDeviceOwnerType | ForEach-Object { Write-Host ("  {0}: {1}" -f $_.Name, $_.Count) }
        Write-Host ("  Total Android devices: {0}" -f $devices.Count)
    } else { Write-Host "  No Android managed devices found in Intune yet." -ForegroundColor Yellow }
} catch { Write-Host "  Could not read managed devices: $($_.Exception.Message)" -ForegroundColor Yellow }

Write-Host "`nNote: source (Workspace ONE) device-to-mode export is produced from the Workspace ONE console — see VMware docs." -ForegroundColor DarkGray
Disconnect-MgGraph | Out-Null
