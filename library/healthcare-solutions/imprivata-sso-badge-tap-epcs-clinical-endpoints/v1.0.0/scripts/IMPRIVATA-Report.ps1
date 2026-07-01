<#
.SYNOPSIS
    Imprivata SSO / Badge-Tap / EPCS - fleet coverage report to CSV (read-only).

    PURPOSE:
        Produces a fleet report for the clinical-endpoint deployment:
          - for every device in 'IMPRIVATA - Clinical Endpoints', the agent app
            install state and reader-driver install state
          - whether the device is in the group (coverage)
        Exports the result to CSV. Makes NO changes.

    HOW TO RUN:
        1. Install-Module Microsoft.Graph -Scope CurrentUser
        2. .\IMPRIVATA-Report.ps1 -OutCsv "C:\Temp\imprivata-coverage.csv"
        3. Sign in with Intune read access.

    EXPECTED RESULTS:
        A CSV at the path given (default .\IMPRIVATA-Coverage-<date>.csv) with one
        row per clinical-endpoint device: DeviceName, AgentInstallState,
        ReaderDriverInstallState, InGroup. A summary is also printed to console.

.NOTES
    Healthcare Solutions - read-only.
#>

[CmdletBinding()]
param(
    [string]$GroupName           = 'IMPRIVATA - Clinical Endpoints',
    [string]$AgentAppName        = 'Imprivata Agent - Clinical Endpoints - Deploy',
    [string]$ReaderDriverAppName = 'Proximity Reader Driver - Clinical Endpoints - Deploy',
    [string]$OutCsv              = (".\IMPRIVATA-Coverage-{0}.csv" -f (Get-Date -Format 'yyyyMMdd-HHmmss'))
)

$ErrorActionPreference = 'Stop'

try {
    Import-Module Microsoft.Graph.Authentication -ErrorAction Stop
    Connect-MgGraph -Scopes 'DeviceManagementApps.Read.All','Group.Read.All','DeviceManagementManagedDevices.Read.All' -NoWelcome
}
catch { Write-Error "Unable to connect to Microsoft Graph: $($_.Exception.Message)"; exit 1 }

# Build per-app deviceName -> installState maps (beta deviceStatuses)
function Get-AppStateMap {
    param([string]$AppName)
    $map = @{}
    $app = Get-MgDeviceAppManagementMobileApp -Filter "displayName eq '$AppName'" -ErrorAction SilentlyContinue | Select-Object -First 1
    if (-not $app) { return $map }
    $uri = "https://graph.microsoft.com/beta/deviceAppManagement/mobileApps/$($app.Id)/deviceStatuses"
    do {
        try { $resp = Invoke-MgGraphRequest -Method GET -Uri $uri -ErrorAction Stop } catch { break }
        foreach ($d in $resp.value) { if ($d.deviceName) { $map[$d.deviceName] = $d.installState } }
        $uri = $resp.'@odata.nextLink'
    } while ($uri)
    return $map
}

$agentMap  = Get-AppStateMap -AppName $AgentAppName
$driverMap = Get-AppStateMap -AppName $ReaderDriverAppName

# Resolve group members -> managed devices
$group = Get-MgGroup -Filter "displayName eq '$GroupName'" -ErrorAction SilentlyContinue | Select-Object -First 1
if (-not $group) { Write-Error "Group '$GroupName' not found."; exit 1 }
$members = Get-MgGroupMember -GroupId $group.Id -All -ErrorAction SilentlyContinue

$rows = New-Object System.Collections.Generic.List[object]
foreach ($m in $members) {
    # Group device members are Entra device objects; match to Intune by AzureAdDeviceId
    $aadDeviceId = $m.AdditionalProperties['deviceId']
    $name = $m.AdditionalProperties['displayName']
    if (-not $name) { $name = $m.Id }
    $rows.Add([pscustomobject]@{
        DeviceName               = $name
        AgentInstallState        = if ($agentMap.ContainsKey($name))  { $agentMap[$name] }  else { 'unknown' }
        ReaderDriverInstallState = if ($driverMap.ContainsKey($name)) { $driverMap[$name] } else { 'unknown' }
        InGroup                  = $true
    })
}

$rows | Export-Csv -Path $OutCsv -NoTypeInformation -Encoding UTF8

$total      = $rows.Count
$agentOk    = ($rows | Where-Object { $_.AgentInstallState -eq 'installed' }).Count
$driverOk   = ($rows | Where-Object { $_.ReaderDriverInstallState -eq 'installed' }).Count
Write-Host ("Devices in group : {0}" -f $total)
Write-Host ("Agent installed  : {0}/{1}" -f $agentOk, $total)
Write-Host ("Driver installed : {0}/{1}" -f $driverOk, $total)
Write-Host ("CSV written      : {0}" -f (Resolve-Path $OutCsv))
