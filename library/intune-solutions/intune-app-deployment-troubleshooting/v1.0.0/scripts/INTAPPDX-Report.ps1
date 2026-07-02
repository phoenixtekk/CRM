<#
.SYNOPSIS
    INTAPPDX-Report.ps1 — produce an app deployment coverage and failure report across the fleet.
.DESCRIPTION
    PURPOSE
        Summarizes deployment health for each app: how many devices report installed,
        failed, not-applicable, and pending. Gives a coverage percentage and a ranked
        failure list so you can spot the apps that need attention before users report them.
    HOW TO RUN
        powershell -ExecutionPolicy Bypass -File .\INTAPPDX-Report.ps1

        Optional: -AppNameLike "your-app-name" to scope, -CsvPath your-output-path.csv to save.
        Required Graph scopes: DeviceManagementApps.Read.All, DeviceManagementManagedDevices.Read.All
    EXPECTED RESULTS
        A per-app summary (Installed / Failed / NotApplicable / Pending / Coverage%) sorted
        by failure count. Pass = high coverage and low failures. Fail = apps with high
        failure or low coverage — take those into the Diagnostic Playbook.
.NOTES
    White-label — the repeatable way. Read-only against Microsoft Graph.
#>

[CmdletBinding()]
param(
    [string] $AppNameLike,
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

Connect-Graph
$base = 'https://graph.microsoft.com/beta'

Write-Host "Reading apps..." -ForegroundColor Cyan
$apps = Invoke-GraphGet -Uri "$base/deviceAppManagement/mobileApps?`$top=100"
if ($AppNameLike) { $apps = $apps | Where-Object { $_.displayName -like "*$AppNameLike*" } }

$report = foreach ($app in $apps) {
    $statuses = @()
    try { $statuses = Invoke-GraphGet -Uri "$base/deviceAppManagement/mobileApps/$($app.id)/deviceStatuses" } catch {}
    $total = $statuses.Count
    if ($total -eq 0) { continue }

    $installed     = ($statuses | Where-Object installState -eq 'installed').Count
    $failed        = ($statuses | Where-Object installState -eq 'failed').Count
    $notApplicable = ($statuses | Where-Object installState -eq 'notApplicable').Count
    $pending       = $total - $installed - $failed - $notApplicable
    $applicable    = $total - $notApplicable
    $coverage      = if ($applicable -gt 0) { [math]::Round(($installed / $applicable) * 100, 1) } else { 0 }

    [pscustomobject]@{
        AppName       = $app.displayName
        AppType       = ($app.'@odata.type' -replace '#microsoft.graph.','')
        Total         = $total
        Installed     = $installed
        Failed        = $failed
        NotApplicable = $notApplicable
        Pending       = $pending
        CoveragePct   = $coverage
    }
}

if (-not $report) { Write-Host "No app device-status data found." -ForegroundColor Yellow; return }

$report = $report | Sort-Object Failed, @{Expression='CoveragePct';Descending=$false}
$report | Format-Table -AutoSize AppName, AppType, Total, Installed, Failed, NotApplicable, Pending, CoveragePct

$totFail = ($report | Measure-Object Failed -Sum).Sum
Write-Host ("`nApps reported: {0}   Total failures across apps: {1}" -f $report.Count, $totFail) -ForegroundColor Cyan
Write-Host "Top failure apps (take into the Diagnostic Playbook):" -ForegroundColor Cyan
$report | Where-Object Failed -gt 0 | Sort-Object Failed -Descending | Select-Object -First 5 |
    ForEach-Object { Write-Host ("  {0,-45} Failed: {1}  Coverage: {2}%" -f $_.AppName, $_.Failed, $_.CoveragePct) }

if ($CsvPath) {
    $report | Export-Csv -Path $CsvPath -NoTypeInformation -Encoding UTF8
    Write-Host "Saved report to $CsvPath" -ForegroundColor Green
}
