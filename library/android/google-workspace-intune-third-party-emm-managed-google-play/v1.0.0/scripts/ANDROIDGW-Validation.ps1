<#
.SYNOPSIS
    ANDROIDGW-Validation.ps1 — read-only account-add + app-delivery validation report for the Workspace <-> Intune third-party EMM integration.
.DESCRIPTION
    PURPOSE
        Validates that the integration is delivering: reports managed Google Play app-sync health, the
        managed Google Play apps assigned (optionally to the pilot group), and the pilot Android devices'
        install/compliance/last-check-in state. Use after the connection is in place to confirm account
        add + app delivery work. Read-only — makes NO changes. Writes "Account Add + App Delivery -
        Pilot - Validation".
    HOW TO RUN
        powershell -ExecutionPolicy Bypass -File .\ANDROIDGW-Validation.ps1 -PilotGroup "MGP Pilot - Android - Stage1" -CsvPath C:\Temp\ANDROIDGW-Validation.csv
        Requires the Microsoft Graph PowerShell SDK and (read-only) scopes:
        DeviceManagementServiceConfig.Read.All, DeviceManagementApps.Read.All,
        DeviceManagementManagedDevices.Read.All, Group.Read.All.
    EXPECTED RESULTS
        PASS: bind state bound + recent successful app sync; assigned managed Google Play apps present;
        pilot devices compliant and checking in. FAIL: failed/stale sync, no assigned apps, or pilot
        devices not compliant / not checking in.
.NOTES
    Android — Google Workspace <-> Intune Third-Party EMM. Read-only. On-device account-add is confirmed
    manually per Testing (05) Test 5; this script reports the supporting Intune-side signals.
#>
[CmdletBinding()]
param(
    [string]$PilotGroup = 'MGP Pilot - Android - Stage1',
    [string]$CsvPath,
    [string]$ReportName = 'Account Add + App Delivery - Pilot - Validation'
)

if (-not (Get-Module -ListAvailable -Name Microsoft.Graph.Authentication)) {
    Install-Module Microsoft.Graph -Scope CurrentUser -Force -AllowClobber
}
Import-Module Microsoft.Graph.Authentication -ErrorAction Stop
Connect-MgGraph -Scopes 'DeviceManagementServiceConfig.Read.All','DeviceManagementApps.Read.All','DeviceManagementManagedDevices.Read.All','Group.Read.All' -NoWelcome

Write-Host ("=== {0} ===" -f $ReportName) -ForegroundColor Cyan

# --- 1. App-sync / connection health ---
try {
    $binding = Invoke-MgGraphRequest -Method GET -Uri '/beta/deviceManagement/androidManagedStoreAccountEnterpriseSettings'
    Write-Host '--- Connection health ---' -ForegroundColor Cyan
    [pscustomobject]@{
        BindStatus        = $binding.bindStatus
        LastAppSync       = $binding.lastAppSyncDateTime
        LastAppSyncStatus = $binding.lastAppSyncStatus
    } | Format-List
    if ($binding.lastAppSyncStatus -and $binding.lastAppSyncStatus -notmatch 'success') {
        Write-Host ("App sync status '{0}' is not success — app delivery may be impaired." -f $binding.lastAppSyncStatus) -ForegroundColor Yellow
    }
} catch {
    Write-Warning ("Could not read connection health (beta): {0}" -f $_.Exception.Message)
}

# --- 2. Managed Google Play apps (assigned, optionally to the pilot group) ---
$groupId = $null
try {
    $g = (Invoke-MgGraphRequest -Method GET -Uri ("/v1.0/groups?`$filter=displayName eq '{0}'&`$select=id,displayName" -f ($PilotGroup -replace "'","''"))).value | Select-Object -First 1
    if ($g) { $groupId = $g.id } else { Write-Warning ("Pilot group '{0}' not found — reporting all managed Google Play apps." -f $PilotGroup) }
} catch { Write-Warning $_.Exception.Message }

$apps = (Invoke-MgGraphRequest -Method GET -Uri "/v1.0/deviceAppManagement/mobileApps?`$filter=isof('microsoft.graph.androidManagedStoreApp')&`$top=200").value
$appRows = @()
foreach ($a in $apps) {
    $assignedToPilot = $null
    try {
        $assigns = (Invoke-MgGraphRequest -Method GET -Uri ("/v1.0/deviceAppManagement/mobileApps/{0}/assignments" -f $a.id)).value
        if ($groupId) {
            $assignedToPilot = [bool]($assigns | Where-Object { $_.target.groupId -eq $groupId })
        }
        $appRows += [pscustomobject]@{
            AppName         = $a.displayName
            PublishingState = $a.publishingState
            Assignments     = @($assigns).Count
            AssignedToPilot = if ($groupId) { $assignedToPilot } else { 'n/a' }
        }
    } catch {
        $appRows += [pscustomobject]@{ AppName=$a.displayName; PublishingState=$a.publishingState; Assignments='?'; AssignedToPilot='error' }
    }
}
Write-Host ('--- Managed Google Play apps: {0} ---' -f $appRows.Count) -ForegroundColor Cyan
$appRows | Format-Table -AutoSize

# --- 3. Pilot device compliance / check-in ---
$devRows = @()
if ($groupId) {
    # Group members that are devices, then match to managedDevices by Entra device id.
    $members = (Invoke-MgGraphRequest -Method GET -Uri ("/v1.0/groups/{0}/members?`$select=id,deviceId,displayName&`$top=999" -f $groupId)).value
    $deviceIds = @($members | Where-Object { $_.deviceId } | ForEach-Object { $_.deviceId })
    $md = (Invoke-MgGraphRequest -Method GET -Uri "/v1.0/deviceManagement/managedDevices?`$filter=operatingSystem eq 'Android'&`$select=deviceName,azureADDeviceId,complianceState,lastSyncDateTime,deviceEnrollmentType&`$top=200").value
    foreach ($d in $md) {
        if ($deviceIds -contains $d.azureADDeviceId) {
            $devRows += [pscustomobject]@{
                DeviceName      = $d.deviceName
                EnrollmentType  = $d.deviceEnrollmentType
                ComplianceState = $d.complianceState
                LastSync        = $d.lastSyncDateTime
            }
        }
    }
    Write-Host ('--- Pilot devices (via {0}): {1} ---' -f $PilotGroup, $devRows.Count) -ForegroundColor Cyan
    $devRows | Format-Table -AutoSize
    if ($devRows.Count -eq 0) { Write-Host 'No pilot devices matched — confirm the pilot group contains device objects.' -ForegroundColor Yellow }
}

Write-Host "REMINDER: On-device 'add the managed Google account' is validated manually (Testing 05, Test 5)." -ForegroundColor DarkCyan

if ($CsvPath) {
    $appRows | Export-Csv -Path $CsvPath -NoTypeInformation
    if ($devRows.Count -gt 0) { $devRows | Export-Csv -Path ($CsvPath -replace '\.csv$','-devices.csv') -NoTypeInformation }
    Write-Host ("Saved '{0}' to {1}" -f $ReportName, $CsvPath) -ForegroundColor Green
}

Disconnect-MgGraph | Out-Null
