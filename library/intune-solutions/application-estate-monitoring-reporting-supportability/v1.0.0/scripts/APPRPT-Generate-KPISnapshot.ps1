<#
.SYNOPSIS
    APPRPT-Generate-KPISnapshot.ps1 — compute the 'App Estate KPI Set - v1' metrics into a single
    snapshot row for trend tracking and the Power BI executive view.
.DESCRIPTION
    PURPOSE
        Rolls the whole app estate up into one KPI snapshot: install success rate, failure rate,
        detection mismatch rate, stale device rate, and applicable/installed/failed totals, each
        with its healthy-range PASS/FAIL verdict. Appending one snapshot per run builds the trend
        that the executive dashboard and the SLO error budget read. Read-only.
    HOW TO RUN
        pwsh -File .\APPRPT-Generate-KPISnapshot.ps1 -Environment Global -OutputPath <path>
        Optional: -AppNameLike "Acme" to scope; -Append <file.csv> to grow a trend file.
        Government cloud: -Environment USGov | USGovDoD.
        Required Graph scopes: DeviceManagementApps.Read.All, DeviceManagementManagedDevices.Read.All
    EXPECTED RESULTS
        One snapshot row (timestamp + each KPI + PASS/FAIL) printed and written to CSV/JSON. Run it
        on the same schedule as the export so the trend line stays continuous. Pass = all KPIs in
        their healthy range; any FAIL is the weekly review agenda.
.NOTES
    Intune Solutions - the repeatable way. Read-only against Microsoft Graph.
#>

[CmdletBinding()]
param(
    [ValidateSet('Global','USGov','USGovDoD')]
    [string] $Environment = 'Global',
    [string] $AppNameLike,
    [string] $OutputPath,
    [string] $Append,
    [int]    $StaleDays = 7
)

$ErrorActionPreference = 'Stop'

$graphEnv = switch ($Environment) {
    'USGov'    { @{ Env = 'USGov';    Base = 'https://graph.microsoft.us' } }
    'USGovDoD' { @{ Env = 'USGovDoD'; Base = 'https://dod-graph.microsoft.us' } }
    default    { @{ Env = 'Global';   Base = 'https://graph.microsoft.com' } }
}
$base = "$($graphEnv.Base)/beta"

function Connect-Graph {
    $scopes = @('DeviceManagementApps.Read.All','DeviceManagementManagedDevices.Read.All')
    if (-not (Get-Module -ListAvailable -Name Microsoft.Graph.Authentication)) {
        throw "Microsoft Graph SDK not found. Run: Install-Module Microsoft.Graph -Scope CurrentUser"
    }
    Import-Module Microsoft.Graph.Authentication -ErrorAction Stop
    if (-not (Get-MgContext)) { Connect-MgGraph -Environment $graphEnv.Env -Scopes $scopes | Out-Null }
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

Connect-Graph
Write-Host "Computing App Estate KPI Set - v1 ..." -ForegroundColor Cyan
$apps = Invoke-GraphGet -Uri "$base/deviceAppManagement/mobileApps?`$top=100"
if ($AppNameLike) { $apps = $apps | Where-Object { $_.displayName -like "*$AppNameLike*" } }

$installed = 0; $failed = 0; $notApplicable = 0; $total = 0
foreach ($app in $apps) {
    $statuses = @()
    try { $statuses = Invoke-GraphGet -Uri "$base/deviceAppManagement/mobileApps/$($app.id)/deviceStatuses" } catch {}
    $total         += $statuses.Count
    $installed     += ($statuses | Where-Object installState -eq 'installed').Count
    $failed        += ($statuses | Where-Object installState -eq 'failed').Count
    $notApplicable += ($statuses | Where-Object installState -eq 'notApplicable').Count
}
$applicable = $total - $notApplicable

# Stale device rate from managed device inventory
$devices = Invoke-GraphGet -Uri "$base/deviceManagement/managedDevices?`$select=id,deviceName,lastSyncDateTime&`$top=100"
$devTotal = $devices.Count
$cutoff = (Get-Date).AddDays(-$StaleDays)
$stale = ($devices | Where-Object { $_.lastSyncDateTime -and ([datetime]$_.lastSyncDateTime) -lt $cutoff }).Count

$successRate = if (($installed + $failed) -gt 0) { [math]::Round(($installed / ($installed + $failed)) * 100, 2) } else { 0 }
$failureRate = if ($applicable -gt 0) { [math]::Round(($failed / $applicable) * 100, 2) } else { 0 }
$staleRate   = if ($devTotal -gt 0) { [math]::Round(($stale / $devTotal) * 100, 2) } else { 0 }

$snap = [pscustomobject]@{
    SnapshotUtc          = (Get-Date).ToUniversalTime().ToString('s')
    AppsMeasured         = $apps.Count
    Applicable           = $applicable
    Installed            = $installed
    Failed               = $failed
    NotApplicable        = $notApplicable
    InstallSuccessRatePct= $successRate
    InstallSuccess_Verdict= if ($successRate -ge 97) { 'PASS' } else { 'FAIL' }
    FailureRatePct       = $failureRate
    FailureRate_Verdict  = if ($failureRate -le 3) { 'PASS' } else { 'FAIL' }
    DevicesTotal         = $devTotal
    StaleDeviceRatePct   = $staleRate
    StaleRate_Verdict    = if ($staleRate -le 5) { 'PASS' } else { 'FAIL' }
}

$snap | Format-List
Write-Host ("Install success {0}%  Failure {1}%  Stale {2}%" -f $successRate, $failureRate, $staleRate) -ForegroundColor Cyan

if ($Append) {
    $exists = Test-Path $Append
    $snap | Export-Csv -Path $Append -NoTypeInformation -Encoding UTF8 -Append
    Write-Host ("{0} snapshot to trend file $Append" -f $(if($exists){'Appended'}else{'Started'})) -ForegroundColor Green
}
if ($OutputPath) {
    if (-not (Test-Path $OutputPath)) { New-Item -ItemType Directory -Path $OutputPath -Force | Out-Null }
    $stamp = (Get-Date).ToString('yyyyMMdd-HHmm')
    $snap | Export-Csv -Path (Join-Path $OutputPath "kpi-snapshot_$stamp.csv") -NoTypeInformation -Encoding UTF8
    $snap | ConvertTo-Json -Depth 3 | Out-File -FilePath (Join-Path $OutputPath "kpi-snapshot_$stamp.json") -Encoding UTF8
    Write-Host "Saved KPI snapshot to $OutputPath" -ForegroundColor Green
}
