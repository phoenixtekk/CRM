<#
.SYNOPSIS
    INTAPPDX-Validation.ps1 — read per-device install and detection state for an app and map it to the pass/fail gates.
.DESCRIPTION
    PURPOSE
        Reads the reported install state and detection detail for one app across the
        devices it targets (or for a single device you name). It maps each device to the
        three gates from the Testing guide: requirement met, installed, detected — so you
        can see exactly which pipeline stage a device stalled at.
    HOW TO RUN
        powershell -ExecutionPolicy Bypass -File .\INTAPPDX-Validation.ps1 -AppNameLike "your-app-name"

        Optional: -DeviceName your-device-name to scope to one device.
        Required Graph scopes: DeviceManagementApps.Read.All, DeviceManagementManagedDevices.Read.All
    EXPECTED RESULTS
        A per-device table of installState / installStateDetail / errorCode with a Gate
        column. Pass = state is 'installed' and detection satisfied (all gates green).
        Fail = 'notApplicable' (Branch A), 'failed' with a code (Branch E), or installed-
        but-not-detected (Branch B). Read the device log to confirm the cause.
.NOTES
    White-label — the repeatable way. Read-only against Microsoft Graph.
#>

[CmdletBinding()]
param(
    [Parameter(Mandatory)][string] $AppNameLike,
    [string] $DeviceName,
    [string] $CsvPath
)

$ErrorActionPreference = 'Stop'

function Connect-Graph {
    $scopes = @('DeviceManagementApps.Read.All','DeviceManagementManagedDevices.Read.All')
    if (-not (Get-Module -ListAvailable -Name Microsoft.Graph.Authentication)) {
        throw "Microsoft Graph SDK not found. Run: Install-Module Microsoft.Graph -Scope CurrentUser"
    }
    Import-Module Microsoft.Graph.Authentication -ErrorAction Stop
    if (-not (Get-MgContext)) { Connect-MgGraph -Scopes $scopes | Out-Null }
}

function Invoke-GraphGet {
    param([Parameter(Mandatory)][string] $Uri)
    $items = @(); $next = $Uri
    while ($next) {
        $resp = Invoke-MgGraphRequest -Method GET -Uri $next
        if ($resp.value) { $items += $resp.value } elseif ($resp) { $items += $resp }
        $next = $resp.'@odata.nextLink'
    }
    return $items
}

function Get-Gate {
    param($state, $detail)
    switch ($state) {
        'installed'      { 'PASS - Detected (Gate 3)'; break }
        'failed'         { 'FAIL - Install/Detect (Branch B/E)'; break }
        'notApplicable'  { 'FAIL - Requirement (Branch A)'; break }
        'notInstalled'   { 'IN PROGRESS - Download/Install (Branch D/E)'; break }
        'pending'        { 'IN PROGRESS - Waiting (Branch D)'; break }
        default          { "UNKNOWN ($state)" }
    }
}

Connect-Graph
$base = 'https://graph.microsoft.com/beta'

Write-Host "Locating app '$AppNameLike'..." -ForegroundColor Cyan
$apps = Invoke-GraphGet -Uri "$base/deviceAppManagement/mobileApps?`$top=100" |
        Where-Object { $_.displayName -like "*$AppNameLike*" }

if (-not $apps) { throw "No app found matching '$AppNameLike'." }

$all = foreach ($app in $apps) {
    Write-Host ("Reading device install status for: {0}" -f $app.displayName) -ForegroundColor Cyan
    $statuses = Invoke-GraphGet -Uri "$base/deviceAppManagement/mobileApps/$($app.id)/deviceStatuses"
    foreach ($s in $statuses) {
        if ($DeviceName -and ($s.deviceName -notlike "*$DeviceName*")) { continue }
        [pscustomobject]@{
            AppName       = $app.displayName
            DeviceName    = $s.deviceName
            InstallState  = $s.installState
            StateDetail   = $s.installStateDetail
            ErrorCode     = $s.errorCode
            Gate          = (Get-Gate $s.installState $s.installStateDetail)
            LastSync      = $s.lastSyncDateTime
        }
    }
}

if (-not $all) { Write-Host "No device status rows returned (app may target no devices yet)." -ForegroundColor Yellow; return }

$all | Sort-Object AppName, DeviceName | Format-Table -AutoSize AppName, DeviceName, InstallState, ErrorCode, Gate

$summary = $all | Group-Object Gate | Sort-Object Count -Descending
Write-Host "`nGate summary:" -ForegroundColor Cyan
$summary | ForEach-Object { Write-Host ("  {0,-40} {1}" -f $_.Name, $_.Count) }

if ($CsvPath) {
    $all | Export-Csv -Path $CsvPath -NoTypeInformation -Encoding UTF8
    Write-Host "Saved validation results to $CsvPath" -ForegroundColor Green
}
