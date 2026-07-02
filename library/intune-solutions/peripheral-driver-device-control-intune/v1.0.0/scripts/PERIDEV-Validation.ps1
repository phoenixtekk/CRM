<#
.SYNOPSIS
    PERIDEV-Validation.ps1 — per-device applied state for the three PERIDEV gates.
.DESCRIPTION
    PURPOSE
        Read-only per-device validation of the peripheral, driver, and device-control gates:
        driver current, printer mapped, and USB/device-control policy enforced. For each
        managed device (optionally scoped to a group), it reports the applied state of the
        PERIDEV policies so you can confirm the pilot before you expand. Makes no changes.
    HOW TO RUN
        powershell -ExecutionPolicy Bypass -File .\PERIDEV-Validation.ps1
        powershell -ExecutionPolicy Bypass -File .\PERIDEV-Validation.ps1 -GroupName SG-PERIDEV-Pilot

        Required Graph scopes: DeviceManagementManagedDevices.Read.All,
        DeviceManagementConfiguration.Read.All, Group.Read.All
    EXPECTED RESULTS
        A table with columns Device / Driver / Printer / DeviceControl showing PASS, FAIL, or
        N/A per gate. Pass = all targeted devices show PASS on all three gates; Fail = any
        device shows FAIL (investigate with the Troubleshooting guide).
.NOTES
    White-label — the repeatable way. Read-only against Microsoft Graph.
#>

[CmdletBinding()]
param(
    [string]$GroupName = 'SG-PERIDEV-Pilot',
    [string]$OutCsv
)

$ErrorActionPreference = 'Stop'

$DriverProfileName  = 'PERIDEV-DriverUpdates-Pilot'
$PrinterProfileName = 'PERIDEV-Printers-Pilot'
$DeviceControlName  = 'PERIDEV-DeviceControl-USB-Pilot'

function Connect-PeridevGraph {
    $scopes = @('DeviceManagementManagedDevices.Read.All','DeviceManagementConfiguration.Read.All','Group.Read.All')
    if (-not (Get-Module -ListAvailable -Name Microsoft.Graph.Authentication)) {
        throw "Microsoft Graph PowerShell SDK not found. Install with: Install-Module Microsoft.Graph -Scope CurrentUser"
    }
    Import-Module Microsoft.Graph.Authentication -ErrorAction Stop
    $ctx = $null
    try { $ctx = Get-MgContext } catch { $ctx = $null }
    if (-not $ctx) { Connect-MgGraph -Scopes $scopes | Out-Null }
    Write-Host "Connected to Microsoft Graph." -ForegroundColor Green
}

function Get-GroupMemberDeviceNames {
    param([string]$Name)
    $names = @()
    try {
        $g = Invoke-MgGraphRequest -Method GET -Uri "https://graph.microsoft.com/v1.0/groups?`$filter=displayName eq '$Name'" -ErrorAction Stop
        $gid = $g.value[0].id
        if (-not $gid) { return $names }
        $m = Invoke-MgGraphRequest -Method GET -Uri "https://graph.microsoft.com/v1.0/groups/$gid/members?`$top=200" -ErrorAction Stop
        foreach ($member in $m.value) {
            if ($member.displayName) { $names += $member.displayName }
        }
    } catch { Write-Warning "Could not resolve group '$Name': $($_.Exception.Message)" }
    return $names
}

Connect-PeridevGraph

$scopeNames = Get-GroupMemberDeviceNames -Name $GroupName
Write-Host ("Scoping to group '{0}' ({1} member name(s))." -f $GroupName, $scopeNames.Count) -ForegroundColor Cyan

# Managed devices
$devices = @()
try {
    $md = Invoke-MgGraphRequest -Method GET -Uri "https://graph.microsoft.com/v1.0/deviceManagement/managedDevices?`$top=200" -ErrorAction Stop
    $devices = $md.value
} catch { throw "Failed to read managed devices: $($_.Exception.Message)" }

if ($scopeNames.Count -gt 0) {
    $devices = $devices | Where-Object { $scopeNames -contains $_.deviceName }
}

$results = @()
foreach ($d in $devices) {
    $driverState  = 'N/A'
    $printerState = 'N/A'
    $dcState      = 'N/A'

    try {
        $states = Invoke-MgGraphRequest -Method GET -Uri "https://graph.microsoft.com/beta/deviceManagement/managedDevices/$($d.id)/deviceConfigurationStates" -ErrorAction Stop
        foreach ($s in $states.value) {
            $verdict = if ($s.state -eq 'compliant') { 'PASS' } elseif ($s.state -in @('error','conflict','notApplicable')) { 'FAIL' } else { $s.state }
            switch -Regex ($s.displayName) {
                [regex]::Escape($DriverProfileName)  { $driverState  = $verdict }
                [regex]::Escape($PrinterProfileName) { $printerState = $verdict }
                [regex]::Escape($DeviceControlName)  { $dcState      = $verdict }
            }
        }
    } catch { }

    $results += [pscustomobject]@{
        Device        = $d.deviceName
        Driver        = $driverState
        Printer       = $printerState
        DeviceControl = $dcState
    }
}

if (-not $results) {
    Write-Warning "No devices matched. Confirm the group name and that devices have checked in."
} else {
    $results | Format-Table -AutoSize
    $pass = ($results | Where-Object { $_.Driver -eq 'PASS' -and $_.Printer -eq 'PASS' -and $_.DeviceControl -eq 'PASS' }).Count
    Write-Host ("`n{0}/{1} device(s) PASS all three gates." -f $pass, $results.Count) -ForegroundColor Cyan
}

if ($OutCsv) {
    $results | Export-Csv -Path $OutCsv -NoTypeInformation -Encoding UTF8
    Write-Host "Exported to $OutCsv" -ForegroundColor Green
}

Write-Host "`nValidation complete (read-only)." -ForegroundColor Green
