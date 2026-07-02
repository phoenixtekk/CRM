<#
.SYNOPSIS
    PERIDEV-Report.ps1 — coverage report across a target group for all three PERIDEV areas.
.DESCRIPTION
    PURPOSE
        Read-only coverage report. For a target group (pilot or production), summarizes how
        many devices are covered by the driver, printer/peripheral, and device-control policies
        and flags any error states, so you can confirm coverage before expanding and catch
        drift over time. Makes no changes.
    HOW TO RUN
        powershell -ExecutionPolicy Bypass -File .\PERIDEV-Report.ps1
        powershell -ExecutionPolicy Bypass -File .\PERIDEV-Report.ps1 -GroupName SG-PERIDEV-Production -OutCsv coverage.csv

        Required Graph scopes: DeviceManagementManagedDevices.Read.All,
        DeviceManagementConfiguration.Read.All, Group.Read.All
    EXPECTED RESULTS
        A coverage summary (covered / not-covered / error counts per area) and an overall
        coverage percentage. Pass = 100% coverage with no error states for the group; Fail =
        any device not covered or in error (resolve before expanding).
.NOTES
    White-label — the repeatable way. Read-only against Microsoft Graph.
#>

[CmdletBinding()]
param(
    [string]$GroupName = 'SG-PERIDEV-Pilot',
    [string]$OutCsv
)

$ErrorActionPreference = 'Stop'

$DriverProfileName  = 'PERIDEV-DriverUpdates'
$PrinterProfileName = 'PERIDEV-Printers'
$DeviceControlName  = 'PERIDEV-DeviceControl-USB'

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
        foreach ($member in $m.value) { if ($member.displayName) { $names += $member.displayName } }
    } catch { Write-Warning "Could not resolve group '$Name': $($_.Exception.Message)" }
    return $names
}

Connect-PeridevGraph

$scopeNames = Get-GroupMemberDeviceNames -Name $GroupName
Write-Host ("Reporting coverage for group '{0}' ({1} member name(s))." -f $GroupName, $scopeNames.Count) -ForegroundColor Cyan

$devices = @()
try {
    $md = Invoke-MgGraphRequest -Method GET -Uri "https://graph.microsoft.com/v1.0/deviceManagement/managedDevices?`$top=200" -ErrorAction Stop
    $devices = $md.value
} catch { throw "Failed to read managed devices: $($_.Exception.Message)" }

if ($scopeNames.Count -gt 0) {
    $devices = $devices | Where-Object { $scopeNames -contains $_.deviceName }
}

$rows = @()
foreach ($d in $devices) {
    $cov = @{ Driver='NotCovered'; Printer='NotCovered'; DeviceControl='NotCovered' }
    try {
        $states = Invoke-MgGraphRequest -Method GET -Uri "https://graph.microsoft.com/beta/deviceManagement/managedDevices/$($d.id)/deviceConfigurationStates" -ErrorAction Stop
        foreach ($s in $states.value) {
            $val = if ($s.state -in @('error','conflict')) { 'Error' } else { 'Covered' }
            if ($s.displayName -match [regex]::Escape($DriverProfileName))  { $cov.Driver = $val }
            if ($s.displayName -match [regex]::Escape($PrinterProfileName)) { $cov.Printer = $val }
            if ($s.displayName -match [regex]::Escape($DeviceControlName))  { $cov.DeviceControl = $val }
        }
    } catch { }
    $rows += [pscustomobject]@{ Device=$d.deviceName; Driver=$cov.Driver; Printer=$cov.Printer; DeviceControl=$cov.DeviceControl }
}

if (-not $rows) {
    Write-Warning "No devices matched. Confirm the group name and that devices have checked in."
    return
}

$rows | Format-Table -AutoSize

function Summarize {
    param($rows, $field)
    $covered = ($rows | Where-Object { $_.$field -eq 'Covered' }).Count
    $error   = ($rows | Where-Object { $_.$field -eq 'Error' }).Count
    $missing = ($rows | Where-Object { $_.$field -eq 'NotCovered' }).Count
    Write-Host ("  {0,-14} Covered={1}  Error={2}  NotCovered={3}" -f $field, $covered, $error, $missing)
    return $covered
}

Write-Host "`n=== Coverage summary ===" -ForegroundColor Cyan
$total = $rows.Count
$cDrv = Summarize $rows 'Driver'
$cPrn = Summarize $rows 'Printer'
$cDc  = Summarize $rows 'DeviceControl'
$overall = [math]::Round((($cDrv + $cPrn + $cDc) / ($total * 3)) * 100, 1)
Write-Host ("`nOverall coverage across all three areas: {0}% of {1} device(s)." -f $overall, $total) -ForegroundColor Cyan
if ($overall -eq 100) { Write-Host "PASS - full coverage." -ForegroundColor Green }
else { Write-Host "FAIL - gaps remain; resolve before expanding." -ForegroundColor Yellow }

if ($OutCsv) {
    $rows | Export-Csv -Path $OutCsv -NoTypeInformation -Encoding UTF8
    Write-Host "Exported to $OutCsv" -ForegroundColor Green
}

Write-Host "`nReport complete (read-only)." -ForegroundColor Green
