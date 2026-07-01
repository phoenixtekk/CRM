<#
.SYNOPSIS
    Imprivata SSO / Badge-Tap / EPCS - safe re-deploy of the named agent/driver app
    to a device. Read-only / -WhatIf by default; acts only with -Apply.

    PURPOSE:
        When a device fails validation because the agent or reader-driver app did
        not install, this safely ensures the device's group membership and triggers
        an app re-evaluation by (a) confirming the named app is assigned to the
        clinical group and (b) adding the device to the group if it is missing.
        It does NOT alter app install command lines or appliance/EPCS policy.

        Default mode previews the actions (-WhatIf). Pass -Apply to make the change
        (add device to group).

    HOW TO RUN:
        Preview:  .\IMPRIVATA-Remediation.ps1 -DeviceName "WOW-WARD3-PC01"
        Apply:    .\IMPRIVATA-Remediation.ps1 -DeviceName "WOW-WARD3-PC01" -Apply

    EXPECTED RESULTS:
        A report of what is/would be changed. With -Apply, the device is added to
        'IMPRIVATA - Clinical Endpoints' (if missing) so the assigned agent/driver
        apps re-evaluate on next Intune sync. Re-run IMPRIVATA-Validation.ps1 after.

.NOTES
    Healthcare Solutions - read-only.
#>

[CmdletBinding(SupportsShouldProcess, ConfirmImpact='Medium')]
param(
    [Parameter(Mandatory)] [string]$DeviceName,
    [string]$GroupName           = 'IMPRIVATA - Clinical Endpoints',
    [string]$AgentAppName        = 'Imprivata Agent - Clinical Endpoints - Deploy',
    [string]$ReaderDriverAppName = 'Proximity Reader Driver - Clinical Endpoints - Deploy',
    [switch]$Apply
)

$ErrorActionPreference = 'Stop'
# When -Apply is NOT supplied, force WhatIf behavior (preview only).
if (-not $Apply) { $WhatIfPreference = $true }

try {
    Import-Module Microsoft.Graph.Authentication -ErrorAction Stop
    $scopes = if ($Apply) { @('Group.ReadWrite.All','DeviceManagementApps.Read.All','DeviceManagementManagedDevices.Read.All','Device.Read.All') }
              else        { @('Group.Read.All','DeviceManagementApps.Read.All','DeviceManagementManagedDevices.Read.All','Device.Read.All') }
    Connect-MgGraph -Scopes $scopes -NoWelcome
}
catch { Write-Error "Unable to connect to Microsoft Graph: $($_.Exception.Message)"; exit 1 }

# Resolve device + its Entra device object
$mdm = Get-MgDeviceManagementManagedDevice -Filter "deviceName eq '$DeviceName'" -ErrorAction SilentlyContinue | Select-Object -First 1
if (-not $mdm) { Write-Error "Device '$DeviceName' not found in Intune."; exit 1 }
$aadDevice = Get-MgDevice -Filter "deviceId eq '$($mdm.AzureAdDeviceId)'" -ErrorAction SilentlyContinue | Select-Object -First 1
if (-not $aadDevice) { Write-Error "Entra device object for '$DeviceName' not found."; exit 1 }

# Confirm apps are assigned to the group (informational only - we never edit assignments here)
foreach ($appName in @($AgentAppName, $ReaderDriverAppName)) {
    $app = Get-MgDeviceAppManagementMobileApp -Filter "displayName eq '$appName'" -ErrorAction SilentlyContinue | Select-Object -First 1
    if ($app) {
        $assign = Get-MgDeviceAppManagementMobileAppAssignment -MobileAppId $app.Id -ErrorAction SilentlyContinue
        Write-Host ("App '{0}': found, {1} assignment(s)." -f $appName, ($assign | Measure-Object).Count)
    } else {
        Write-Warning ("App '{0}' not found - create it per 03-implementation.md before remediating." -f $appName)
    }
}

# Ensure device is in the clinical group
$group = Get-MgGroup -Filter "displayName eq '$GroupName'" -ErrorAction SilentlyContinue | Select-Object -First 1
if (-not $group) { Write-Error "Group '$GroupName' not found."; exit 1 }

$members = Get-MgGroupMember -GroupId $group.Id -All -ErrorAction SilentlyContinue
$already = [bool]($members | Where-Object { $_.Id -eq $aadDevice.Id })

if ($already) {
    Write-Host ("Device '{0}' is already a member of '{1}'. No change needed." -f $DeviceName, $GroupName)
} else {
    if ($PSCmdlet.ShouldProcess("$DeviceName -> $GroupName", "Add device to group")) {
        New-MgGroupMember -GroupId $group.Id -DirectoryObjectId $aadDevice.Id
        Write-Host ("ADDED '{0}' to '{1}'. Apps will re-evaluate on next Intune sync." -f $DeviceName, $GroupName)
    } else {
        Write-Host ("[WhatIf] Would ADD '{0}' to '{1}'. Re-run with -Apply to perform." -f $DeviceName, $GroupName)
    }
}

Write-Host 'Next: re-run IMPRIVATA-Validation.ps1 after the device syncs.'
