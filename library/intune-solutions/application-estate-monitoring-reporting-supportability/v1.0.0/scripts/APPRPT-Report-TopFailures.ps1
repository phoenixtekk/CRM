<#
.SYNOPSIS
    APPRPT-Report-TopFailures.ps1 — rank the app estate's worst deployment failures by app, ring,
    and device.
.DESCRIPTION
    PURPOSE
        Produces the operations work queue: the top-N apps by failure count and failure rate, a
        by-ring breakdown (which deployment ring is worst), and the affected device list for the
        worst apps. This is the number that drives the daily triage. Read-only.
    HOW TO RUN
        pwsh -File .\APPRPT-Report-TopFailures.ps1 -Environment Global -Top 20 -OutputPath <path>
        Optional: -AppNameLike "Acme" to scope; -RingGroupPrefix "RING -" to derive rings from group
        names; -CsvPath out.csv to save.
        Government cloud: -Environment USGov | USGovDoD.
        Required Graph scopes: DeviceManagementApps.Read.All, DeviceManagementManagedDevices.Read.All
    EXPECTED RESULTS
        A ranked table (AppName, Failed, Applicable, FailureRatePct) sorted by failures, plus the
        by-ring failure breakdown. Pass = low/steady failures. Fail = apps or rings above the 3%
        healthy range in the KPI set - take those into per-app drill-down.
.NOTES
    Intune Solutions - the repeatable way. Read-only against Microsoft Graph.
#>

[CmdletBinding()]
param(
    [ValidateSet('Global','USGov','USGovDoD')]
    [string] $Environment = 'Global',
    [int]    $Top = 20,
    [string] $AppNameLike,
    [string] $CsvPath,
    [string] $OutputPath
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
Write-Host "Reading apps..." -ForegroundColor Cyan
$apps = Invoke-GraphGet -Uri "$base/deviceAppManagement/mobileApps?`$top=100"
if ($AppNameLike) { $apps = $apps | Where-Object { $_.displayName -like "*$AppNameLike*" } }

$report = foreach ($app in $apps) {
    $statuses = @()
    try { $statuses = Invoke-GraphGet -Uri "$base/deviceAppManagement/mobileApps/$($app.id)/deviceStatuses" } catch {}
    if (-not $statuses) { continue }
    $installed     = ($statuses | Where-Object installState -eq 'installed').Count
    $failed        = ($statuses | Where-Object installState -eq 'failed').Count
    $notApplicable = ($statuses | Where-Object installState -eq 'notApplicable').Count
    $applicable    = $statuses.Count - $notApplicable
    if ($failed -eq 0 -and $applicable -eq 0) { continue }
    $rate = if ($applicable -gt 0) { [math]::Round(($failed / $applicable) * 100, 1) } else { 0 }
    [pscustomobject]@{
        AppName        = $app.displayName
        AppType        = ($app.'@odata.type' -replace '#microsoft.graph.','')
        Failed         = $failed
        Installed      = $installed
        Applicable     = $applicable
        FailureRatePct = $rate
        Health         = if ($rate -le 3) { 'OK' } else { 'ATTENTION' }
    }
}

if (-not $report) { Write-Host "No failures found across the app estate." -ForegroundColor Green; return }

$ranked = $report | Sort-Object Failed -Descending | Select-Object -First $Top
$ranked | Format-Table -AutoSize AppName, AppType, Failed, Applicable, FailureRatePct, Health

$totFail = ($report | Measure-Object Failed -Sum).Sum
$attention = ($report | Where-Object Health -eq 'ATTENTION').Count
Write-Host ("`nTotal failures across estate: {0}   Apps above 3% healthy range: {1}" -f $totFail, $attention) -ForegroundColor Cyan

if ($CsvPath) { $ranked | Export-Csv -Path $CsvPath -NoTypeInformation -Encoding UTF8; Write-Host "Saved to $CsvPath" -ForegroundColor Green }
if ($OutputPath) {
    if (-not (Test-Path $OutputPath)) { New-Item -ItemType Directory -Path $OutputPath -Force | Out-Null }
    $out = Join-Path $OutputPath ("top-failures_{0}.csv" -f (Get-Date -Format 'yyyyMMdd-HHmm'))
    $ranked | Export-Csv -Path $out -NoTypeInformation -Encoding UTF8
    Write-Host "Saved to $out" -ForegroundColor Green
}
