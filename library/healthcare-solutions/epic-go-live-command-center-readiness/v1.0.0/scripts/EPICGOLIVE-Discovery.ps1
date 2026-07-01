<#
.SYNOPSIS
    EPICGOLIVE-Discovery — fleet readiness snapshot for an Epic go-live.

.DESCRIPTION
    Produces a read-only readiness snapshot of the in-scope clinical endpoint fleet from
    Microsoft Intune / Microsoft Entra via Microsoft Graph. For each device it reports
    enrollment state, compliance state, OS / build, last check-in, the detected Epic client
    version, and whether the Imprivata agent is present. This snapshot is the Assess-phase
    baseline and the rollback before-state for any later remediation.

    No state is changed. The script only reads from Microsoft Graph and inspects managed-app /
    detected-app inventory. Scope the run to the readiness device group so it reports against the
    activation's in-scope devices only.

.PARAMETER GroupId
    Object ID of the "Readiness Device Group - Clinical Fleet - Validation" to scope discovery to.
    If omitted, all managed Windows devices are enumerated (use a filter for large tenants).

.PARAMETER EpicAppNameLike
    Display-name match used to detect the Epic client among installed/detected apps
    (e.g. 'Hyperdrive', 'Hyperspace'). Supplied per environment by the Epic program / Epic TS.

.PARAMETER ImprivataAppNameLike
    Display-name match used to detect the Imprivata agent (e.g. 'Imprivata').

.PARAMETER OutputPath
    Optional path to write the snapshot CSV. If omitted, results are returned as objects.

.EXAMPLE
    Connect-MgGraph -Scopes 'DeviceManagementManagedDevices.Read.All','Group.Read.All'
    .\EPICGOLIVE-Discovery.ps1 -GroupId <guid> -OutputPath .\readiness-snapshot.csv

.NOTES
    Healthcare Solutions — read-only.
#>

[CmdletBinding()]
param(
    [string] $GroupId,
    [string] $EpicAppNameLike = 'Hyperdrive',
    [string] $ImprivataAppNameLike = 'Imprivata',
    [string] $OutputPath
)

#-------------------------------------------------------------------------------
# Preconditions
#-------------------------------------------------------------------------------
function Assert-Graph {
    if (-not (Get-Command Get-MgContext -ErrorAction SilentlyContinue)) {
        throw "Microsoft.Graph PowerShell SDK not found. Install-Module Microsoft.Graph, then Connect-MgGraph."
    }
    if (-not (Get-MgContext)) {
        throw "Not connected to Microsoft Graph. Run: Connect-MgGraph -Scopes 'DeviceManagementManagedDevices.Read.All','Group.Read.All'"
    }
}

Assert-Graph

#-------------------------------------------------------------------------------
# Resolve in-scope devices
#-------------------------------------------------------------------------------
function Get-ScopedManagedDevices {
    param([string] $GroupId)

    if ($GroupId) {
        Write-Verbose "Scoping to group members of $GroupId"
        $members = Get-MgGroupMember -GroupId $GroupId -All
        $deviceIds = $members | Where-Object { $_.AdditionalProperties.'@odata.type' -match 'device' } |
            ForEach-Object { $_.AdditionalProperties.deviceId }
        # Map Entra device objects to Intune managed devices by Entra device ID.
        $all = Get-MgDeviceManagementManagedDevice -All
        return $all | Where-Object { $deviceIds -contains $_.AzureAdDeviceId }
    }

    Write-Verbose "No group supplied; enumerating all managed Windows devices."
    return Get-MgDeviceManagementManagedDevice -All |
        Where-Object { $_.OperatingSystem -match 'Windows' }
}

#-------------------------------------------------------------------------------
# Per-device detected-app lookup (Epic client + Imprivata agent)
#-------------------------------------------------------------------------------
function Get-DetectedAppVersion {
    param([string] $ManagedDeviceId, [string] $NameLike)
    try {
        $apps = Get-MgDeviceManagementManagedDeviceDetectedApp -ManagedDeviceId $ManagedDeviceId -All -ErrorAction Stop
        $match = $apps | Where-Object { $_.DisplayName -like "*$NameLike*" } |
            Sort-Object Version -Descending | Select-Object -First 1
        if ($match) { return $match.Version }
    } catch {
        Write-Verbose "Detected-app lookup failed for $ManagedDeviceId : $($_.Exception.Message)"
    }
    return $null
}

#-------------------------------------------------------------------------------
# Build snapshot
#-------------------------------------------------------------------------------
Write-Host "EPICGOLIVE-Discovery — building fleet readiness snapshot (read-only)..." -ForegroundColor Cyan

$devices = Get-ScopedManagedDevices -GroupId $GroupId
Write-Host ("In-scope devices: {0}" -f ($devices | Measure-Object).Count)

$snapshot = foreach ($d in $devices) {
    $epicVer      = Get-DetectedAppVersion -ManagedDeviceId $d.Id -NameLike $EpicAppNameLike
    $imprivataVer = Get-DetectedAppVersion -ManagedDeviceId $d.Id -NameLike $ImprivataAppNameLike

    [pscustomobject]@{
        DeviceName        = $d.DeviceName
        ManagedDeviceId   = $d.Id
        AzureAdDeviceId   = $d.AzureAdDeviceId
        OperatingSystem   = $d.OperatingSystem
        OsVersion         = $d.OsVersion
        Enrolled          = [bool]$d.EnrolledDateTime
        ComplianceState   = $d.ComplianceState
        LastSyncDateTime  = $d.LastSyncDateTime
        EpicClientVersion = $epicVer
        ImprivataPresent  = [bool]$imprivataVer
        ImprivataVersion  = $imprivataVer
    }
}

if ($OutputPath) {
    $snapshot | Export-Csv -Path $OutputPath -NoTypeInformation -Encoding UTF8
    Write-Host "Snapshot written to $OutputPath" -ForegroundColor Green
} else {
    $snapshot
}

Write-Host "Done. No changes were made (read-only)." -ForegroundColor Green
