<#
.SYNOPSIS
    Imprivata SSO / Badge-Tap / EPCS - per-device validation (read-only, PASS/FAIL).

    PURPOSE:
        For a given device, validates the endpoint-side prerequisites of the
        deployment and reports PASS/FAIL for each:
          - the Imprivata agent app reports Installed for the device
          - the reader-driver app reports Installed for the device
          - the device is a member of 'IMPRIVATA - Clinical Endpoints'
        Makes NO changes.

    HOW TO RUN:
        1. Install-Module Microsoft.Graph -Scope CurrentUser
        2. .\IMPRIVATA-Validation.ps1 -DeviceName "WOW-WARD3-PC01"
           (or -DeviceId <intuneManagedDeviceId>)
        3. Sign in with Intune read access.

    EXPECTED RESULTS:
        A PASS/FAIL line per check for the named device, and an overall
        DEVICE RESULT. Exit code 0 if all PASS, 1 if any FAIL.

.NOTES
    Healthcare Solutions - read-only.
#>

[CmdletBinding(DefaultParameterSetName='ByName')]
param(
    [Parameter(ParameterSetName='ByName', Mandatory)] [string]$DeviceName,
    [Parameter(ParameterSetName='ById',   Mandatory)] [string]$DeviceId,
    [string]$AgentAppName        = 'Imprivata Agent - Clinical Endpoints - Deploy',
    [string]$ReaderDriverAppName = 'Proximity Reader Driver - Clinical Endpoints - Deploy',
    [string]$GroupName           = 'IMPRIVATA - Clinical Endpoints'
)

$ErrorActionPreference = 'Stop'
$pass = $true

function Write-Result {
    param([string]$Label, [bool]$Ok, [string]$Detail)
    $tag = if ($Ok) { 'PASS' } else { 'FAIL' }
    Write-Host ("[{0}] {1} {2}" -f $tag, $Label, $Detail)
    if (-not $Ok) { $script:pass = $false }
}

try {
    Import-Module Microsoft.Graph.Authentication -ErrorAction Stop
    Connect-MgGraph -Scopes 'DeviceManagementApps.Read.All','Group.Read.All','DeviceManagementManagedDevices.Read.All' -NoWelcome
}
catch { Write-Error "Unable to connect to Microsoft Graph: $($_.Exception.Message)"; exit 1 }

# Resolve device
if ($PSCmdlet.ParameterSetName -eq 'ByName') {
    $device = Get-MgDeviceManagementManagedDevice -Filter "deviceName eq '$DeviceName'" -ErrorAction SilentlyContinue | Select-Object -First 1
} else {
    $device = Get-MgDeviceManagementManagedDevice -ManagedDeviceId $DeviceId -ErrorAction SilentlyContinue
}
if (-not $device) { Write-Error "Device not found in Intune."; exit 1 }
Write-Host ("Validating device: {0} ({1})" -f $device.DeviceName, $device.Id)
Write-Host ''

# Helper: per-device app install state via app's deviceStatuses
function Get-AppInstallState {
    param([string]$AppName, [string]$DeviceNameToMatch)
    $app = Get-MgDeviceAppManagementMobileApp -Filter "displayName eq '$AppName'" -ErrorAction SilentlyContinue | Select-Object -First 1
    if (-not $app) { return $null }
    $uri = "https://graph.microsoft.com/beta/deviceAppManagement/mobileApps/$($app.Id)/deviceStatuses"
    try {
        $resp = Invoke-MgGraphRequest -Method GET -Uri $uri -ErrorAction Stop
        $match = $resp.value | Where-Object { $_.deviceName -eq $DeviceNameToMatch } | Select-Object -First 1
        if ($match) { return $match.installState } else { return 'unknown' }
    } catch { return 'unknown' }
}

# Agent installed
$agentState = Get-AppInstallState -AppName $AgentAppName -DeviceNameToMatch $device.DeviceName
Write-Result "Agent app installed" ($agentState -eq 'installed') ("(state: $agentState)")

# Reader driver installed
$driverState = Get-AppInstallState -AppName $ReaderDriverAppName -DeviceNameToMatch $device.DeviceName
Write-Result "Reader-driver app installed" ($driverState -eq 'installed') ("(state: $driverState - skip only for HID driverless readers)")

# Device in group
$group = Get-MgGroup -Filter "displayName eq '$GroupName'" -ErrorAction SilentlyContinue | Select-Object -First 1
$inGroup = $false
if ($group) {
    $members = Get-MgGroupMember -GroupId $group.Id -All -ErrorAction SilentlyContinue
    $inGroup = [bool]($members | Where-Object { $_.Id -eq $device.AzureAdDeviceId -or $_.Id -eq $device.Id })
}
Write-Result "Device in '$GroupName'" $inGroup ''

Write-Host ''
if ($pass) { Write-Host 'DEVICE RESULT: PASS'; exit 0 } else { Write-Host 'DEVICE RESULT: FAIL - see 06-troubleshooting.md'; exit 1 }
