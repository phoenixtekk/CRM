<#
.SYNOPSIS
    WS1DROID-Remediation.ps1 — safe remediation of failed Android migration enrollments (defaults to -WhatIf).
.DESCRIPTION
    PURPOSE
        Remediates devices that did not migrate cleanly. For a named ring group it can request a sync on
        stuck devices (work-profile devices often recover with a sync) and, for corporate-mode devices
        that must be wiped to land in the right mode, it can issue a retire (un-manage) so the device can
        be factory-reset and re-enrolled with the correct enrollment profile. SAFETY: it runs in preview
        (-WhatIf) by default and performs NO change until you pass -Execute.
    HOW TO RUN
        Preview (default, no changes):
            powershell -ExecutionPolicy Bypass -File .\WS1DROID-Remediation.ps1 -GroupName 'Migration Ring – Pilot – Android' -Action Sync
        Apply:
            powershell -ExecutionPolicy Bypass -File .\WS1DROID-Remediation.ps1 -GroupName 'Migration Ring – Pilot – Android' -Action Sync -Execute
        -Action Sync   : request a device sync (non-destructive).
        -Action Retire : un-manage so the device can be reset + re-enrolled (use only for corporate-mode re-enroll).
        Requires the Microsoft Graph SDK and scopes (DeviceManagementManagedDevices.PrivilegedOperations.All,
        DeviceManagementManagedDevices.Read.All, Group.Read.All).
    EXPECTED RESULTS
        In preview, prints exactly which devices WOULD be synced/retired and stops. With -Execute, performs
        the chosen action and reports per-device success. Re-run WS1DROID-Validation.ps1 afterward.
.NOTES
    Workplace Marketplace — Migrations. Defaults to -WhatIf; retire is destructive to management (not user data
    by itself, but corporate re-enroll requires a factory reset) — review the preview before -Execute.
#>
[CmdletBinding(SupportsShouldProcess = $true, ConfirmImpact = 'High')] param(
    [Parameter(Mandatory = $true)][string]$GroupName,
    [ValidateSet('Sync','Retire')][string]$Action = 'Sync',
    [switch]$Execute
)

# Default to preview unless -Execute is passed.
if (-not $Execute) { $WhatIfPreference = $true }

if (-not (Get-Module -ListAvailable -Name Microsoft.Graph.Authentication)) {
    Install-Module Microsoft.Graph -Scope CurrentUser -Force -AllowClobber
}
Import-Module Microsoft.Graph.Authentication -ErrorAction Stop
Connect-MgGraph -Scopes 'DeviceManagementManagedDevices.PrivilegedOperations.All','DeviceManagementManagedDevices.Read.All','Group.Read.All' -NoWelcome

Write-Host "=== Android migration remediation ($Action) ===" -ForegroundColor Cyan
if ($WhatIfPreference) { Write-Host "  PREVIEW MODE — no changes will be made (pass -Execute to apply)." -ForegroundColor Yellow }

# Resolve the ring group and its device members
try {
    $grp = (Invoke-MgGraphRequest -Method GET -Uri "/v1.0/groups?`$filter=displayName eq '$GroupName'").value | Select-Object -First 1
    if (-not $grp) { Write-Host "  Group '$GroupName' not found — nothing to do." -ForegroundColor Yellow; Disconnect-MgGraph | Out-Null; return }
    $members = (Invoke-MgGraphRequest -Method GET -Uri "/v1.0/groups/$($grp.id)/members?`$select=deviceId,displayName").value
    $deviceIds = @($members | ForEach-Object { $_.deviceId } | Where-Object { $_ })
    if (-not $deviceIds) { Write-Host "  Group has no device members." -ForegroundColor Yellow; Disconnect-MgGraph | Out-Null; return }
} catch { Write-Host "  Group resolution failed: $($_.Exception.Message)" -ForegroundColor Red; Disconnect-MgGraph | Out-Null; return }

# Map Entra device ids to Intune managedDevice ids (Android only)
$select = 'id,deviceName,azureADDeviceId,managedDeviceOwnerType'
$android = (Invoke-MgGraphRequest -Method GET -Uri "/v1.0/deviceManagement/managedDevices?`$filter=operatingSystem eq 'Android'&`$select=$select").value
$targets = $android | Where-Object { $deviceIds -contains $_.azureADDeviceId }
if (-not $targets) { Write-Host "  No Android managed devices in this group." -ForegroundColor Yellow; Disconnect-MgGraph | Out-Null; return }

foreach ($d in $targets) {
    $action = if ($Action -eq 'Sync') { 'syncDevice' } else { 'retire' }
    if ($PSCmdlet.ShouldProcess($d.deviceName, "$Action ($($d.managedDeviceOwnerType))")) {
        try {
            Invoke-MgGraphRequest -Method POST -Uri "/v1.0/deviceManagement/managedDevices/$($d.id)/$action" | Out-Null
            Write-Host ("  {0}: {1} requested." -f $d.deviceName, $Action) -ForegroundColor Green
        } catch { Write-Host ("  {0}: {1} FAILED — {2}" -f $d.deviceName, $Action, $_.Exception.Message) -ForegroundColor Red }
    }
}

Write-Host "`nRe-run WS1DROID-Validation.ps1 after the action completes." -ForegroundColor Green
if ($Action -eq 'Retire') { Write-Host "Reminder: corporate-mode devices must be factory reset and re-enrolled with the correct enrollment profile." -ForegroundColor DarkGray }
Disconnect-MgGraph | Out-Null
