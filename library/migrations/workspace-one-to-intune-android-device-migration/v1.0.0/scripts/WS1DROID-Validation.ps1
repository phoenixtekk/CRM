<#
.SYNOPSIS
    WS1DROID-Validation.ps1 — validate Android enrollment mode and profile readiness (read-only).
.DESCRIPTION
    PURPOSE
        Confirms migration correctness in Intune: that the in-scope Android enrollment profiles exist,
        and that migrated Android devices report the expected Android Enterprise management mode
        (work profile vs fully managed vs dedicated) for their ownership. Read-only — changes nothing.
    HOW TO RUN
        powershell -ExecutionPolicy Bypass -File .\WS1DROID-Validation.ps1
        Optional: -GroupName 'Migration Ring – Pilot – Android' to scope devices to one ring group.
        Requires the Microsoft Graph SDK and read scopes (DeviceManagementConfiguration.Read.All,
        DeviceManagementManagedDevices.Read.All, Group.Read.All when -GroupName is used).
    EXPECTED RESULTS
        Lists which expected enrollment profiles are present/missing, and a per-device mode line so you
        can spot any device that landed in the wrong management mode. No changes are made.
.NOTES
    Workplace Marketplace — Migrations. Read-only against Microsoft Graph.
#>
[CmdletBinding()] param(
    [string]$GroupName
)

if (-not (Get-Module -ListAvailable -Name Microsoft.Graph.Authentication)) {
    Install-Module Microsoft.Graph -Scope CurrentUser -Force -AllowClobber
}
Import-Module Microsoft.Graph.Authentication -ErrorAction Stop
$scopes = @('DeviceManagementConfiguration.Read.All','DeviceManagementManagedDevices.Read.All')
if ($GroupName) { $scopes += 'Group.Read.All' }
Connect-MgGraph -Scopes $scopes -NoWelcome

Write-Host "=== Android enrollment validation (read-only) ===" -ForegroundColor Cyan

# Expected enrollment profiles by reusable artifact name
$expected = @(
    'Android Enrollment Profile – Work Profile BYOD – Migration',
    'Android Enrollment Profile – Fully Managed – Migration',
    'Android Enrollment Profile – Dedicated – Migration'
)
Write-Host "`n--- Enrollment profiles present ---" -ForegroundColor Cyan
try {
    $profiles = (Invoke-MgGraphRequest -Method GET -Uri '/beta/deviceManagement/androidDeviceOwnerEnrollmentProfiles').value
    $names = @($profiles | ForEach-Object { $_.displayName })
    foreach ($e in $expected) {
        if ($names -contains $e) { Write-Host ("  PRESENT : {0}" -f $e) -ForegroundColor Green }
        else { Write-Host ("  MISSING : {0}  (only needed if this mode is in scope)" -f $e) -ForegroundColor Yellow }
    }
} catch { Write-Host "  Could not read enrollment profiles: $($_.Exception.Message)" -ForegroundColor Yellow }

# Optionally scope device list to a ring group
$deviceFilter = "operatingSystem eq 'Android'"
$memberDeviceIds = $null
if ($GroupName) {
    try {
        $grp = (Invoke-MgGraphRequest -Method GET -Uri "/v1.0/groups?`$filter=displayName eq '$GroupName'").value | Select-Object -First 1
        if ($grp) {
            $members = (Invoke-MgGraphRequest -Method GET -Uri "/v1.0/groups/$($grp.id)/members?`$select=deviceId,displayName").value
            $memberDeviceIds = @($members | ForEach-Object { $_.deviceId } | Where-Object { $_ })
            Write-Host ("`nScoped to group '{0}' ({1} members)." -f $GroupName, $members.Count) -ForegroundColor DarkGray
        } else { Write-Host "`nGroup '$GroupName' not found — validating all Android devices." -ForegroundColor Yellow }
    } catch { Write-Host "  Group lookup failed: $($_.Exception.Message)" -ForegroundColor Yellow }
}

Write-Host "`n--- Per-device management mode ---" -ForegroundColor Cyan
try {
    $select = 'deviceName,managedDeviceOwnerType,deviceEnrollmentType,complianceState,azureADDeviceId'
    $devices = (Invoke-MgGraphRequest -Method GET -Uri "/v1.0/deviceManagement/managedDevices?`$filter=$deviceFilter&`$select=$select").value
    if ($memberDeviceIds) { $devices = $devices | Where-Object { $memberDeviceIds -contains $_.azureADDeviceId } }
    if ($devices) {
        foreach ($d in $devices) {
            Write-Host ("  {0,-28} owner={1,-12} enroll={2,-30} compliance={3}" -f `
                $d.deviceName, $d.managedDeviceOwnerType, $d.deviceEnrollmentType, $d.complianceState)
        }
        Write-Host ("  Devices evaluated: {0}" -f $devices.Count)
        Write-Host "  Check: corporate devices should show a fully-managed/dedicated enrollment type, BYOD a work-profile type." -ForegroundColor DarkGray
    } else { Write-Host "  No matching Android devices found." -ForegroundColor Yellow }
} catch { Write-Host "  Could not read managed devices: $($_.Exception.Message)" -ForegroundColor Yellow }

Disconnect-MgGraph | Out-Null
