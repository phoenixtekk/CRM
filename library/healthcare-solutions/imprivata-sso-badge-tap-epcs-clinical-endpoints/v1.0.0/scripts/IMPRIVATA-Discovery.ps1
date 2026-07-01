<#
.SYNOPSIS
    Imprivata SSO / Badge-Tap / EPCS - tenant readiness discovery (read-only).

    PURPOSE:
        Confirms the tenant is ready for the Imprivata clinical-endpoint deployment:
          - the named agent Win32 app exists and is assigned
          - the named reader-driver Win32 app exists and is assigned
          - the 'IMPRIVATA - Clinical Endpoints' device group exists
          - target devices are present in Intune
        Makes NO changes.

    HOW TO RUN:
        1. Install the Microsoft Graph PowerShell SDK:
               Install-Module Microsoft.Graph -Scope CurrentUser
        2. Run:
               .\IMPRIVATA-Discovery.ps1
           (Optionally override the object names with the parameters below.)
        3. Sign in with an account holding at least Intune read access
           (Global Reader / Intune Administrator).

    EXPECTED RESULTS:
        A readiness summary printed to the console, one line per check, marked
        FOUND / MISSING. Any MISSING item must be created before deployment
        (see 03-implementation.md). Exit code 0 if all checks pass, 1 otherwise.

.NOTES
    Healthcare Solutions - read-only.
#>

[CmdletBinding()]
param(
    [string]$AgentAppName       = 'Imprivata Agent - Clinical Endpoints - Deploy',
    [string]$ReaderDriverAppName = 'Proximity Reader Driver - Clinical Endpoints - Deploy',
    [string]$GroupName          = 'IMPRIVATA - Clinical Endpoints'
)

$ErrorActionPreference = 'Stop'
$allOk = $true

function Write-Check {
    param([string]$Label, [bool]$Ok, [string]$Detail)
    $status = if ($Ok) { 'FOUND  ' } else { 'MISSING' }
    Write-Host ("[{0}] {1} {2}" -f $status, $Label, $Detail)
}

try {
    Import-Module Microsoft.Graph.Authentication -ErrorAction Stop
    Connect-MgGraph -Scopes 'DeviceManagementApps.Read.All','Group.Read.All','DeviceManagementManagedDevices.Read.All' -NoWelcome
}
catch {
    Write-Error "Unable to connect to Microsoft Graph: $($_.Exception.Message)"
    exit 1
}

# --- Agent app ---
$agent = Get-MgDeviceAppManagementMobileApp -Filter "displayName eq '$AgentAppName'" -ErrorAction SilentlyContinue
if ($agent) {
    $assignments = Get-MgDeviceAppManagementMobileAppAssignment -MobileAppId $agent.Id -ErrorAction SilentlyContinue
    Write-Check "Agent app '$AgentAppName'" $true ("- assignments: {0}" -f ($assignments | Measure-Object).Count)
    if (-not $assignments) { $allOk = $false; Write-Host "         WARNING: agent app has no assignments." }
} else { Write-Check "Agent app '$AgentAppName'" $false ''; $allOk = $false }

# --- Reader driver app ---
$driver = Get-MgDeviceAppManagementMobileApp -Filter "displayName eq '$ReaderDriverAppName'" -ErrorAction SilentlyContinue
if ($driver) {
    $dAssign = Get-MgDeviceAppManagementMobileAppAssignment -MobileAppId $driver.Id -ErrorAction SilentlyContinue
    Write-Check "Reader-driver app '$ReaderDriverAppName'" $true ("- assignments: {0}" -f ($dAssign | Measure-Object).Count)
    if (-not $dAssign) { $allOk = $false; Write-Host "         WARNING: reader-driver app has no assignments." }
} else { Write-Check "Reader-driver app '$ReaderDriverAppName'" $false '(skip only if HID-class driverless readers)'; $allOk = $false }

# --- Device group ---
$group = Get-MgGroup -Filter "displayName eq '$GroupName'" -ErrorAction SilentlyContinue
if ($group) {
    $members = Get-MgGroupMember -GroupId $group.Id -All -ErrorAction SilentlyContinue
    Write-Check "Group '$GroupName'" $true ("- members: {0}" -f ($members | Measure-Object).Count)
} else { Write-Check "Group '$GroupName'" $false ''; $allOk = $false }

# --- Managed devices present ---
$devices = Get-MgDeviceManagementManagedDevice -Top 1 -ErrorAction SilentlyContinue
Write-Check "Intune managed devices present" ([bool]$devices) ''
if (-not $devices) { $allOk = $false }

Write-Host ''
if ($allOk) { Write-Host 'RESULT: Tenant readiness checks PASSED.'; exit 0 }
else        { Write-Host 'RESULT: One or more readiness checks MISSING - see 03-implementation.md.'; exit 1 }
