<#
.SYNOPSIS
    APPUNIN-Report.ps1 — fleet-wide Win32 app removal status report from Microsoft Graph.
.DESCRIPTION
    PURPOSE
        For one or all Win32 apps, summarizes per-device uninstall status across the fleet
        so you can separate GENUINE removal failures from devices that simply have not
        reported. For each app it counts: notInstalled (removed), uninstallFailed,
        pendingInstall/pending, installed (still present), and unknown (not reporting).
        Use it to size a removal campaign, watch it drain, and catch rising
        uninstallFailed counts before users notice lingering software.
    HOW TO RUN
          powershell -ExecutionPolicy Bypass -File .\APPUNIN-Report.ps1
          powershell -ExecutionPolicy Bypass -File .\APPUNIN-Report.ps1 -AppNameLike "Contoso LOB" -CsvPath .\removal-report.csv
        US Gov: add -GraphEnvironment USGov (GCC High) or -GraphEnvironment USGovDoD (DoD)

        Required Graph scopes: DeviceManagementApps.Read.All, DeviceManagementManagedDevices.Read.All
    EXPECTED RESULTS
        A per-app summary table of the status counts, plus an optional CSV. A healthy,
        completing removal shows notInstalled rising and uninstallFailed at 0. A high
        'unknown' count points at non-reporting devices (Branch I), not failures.
.NOTES
    Intune Solutions — read-only against Microsoft Graph. The repeatable way.
#>

[CmdletBinding()]
param(
    [string] $AppNameLike,
    [string] $CsvPath,
    [ValidateSet('Global','USGov','USGovDoD')][string] $GraphEnvironment = 'Global'
)

$ErrorActionPreference = 'Stop'

function Connect-Graph {
    param([string[]] $Scopes, [string] $Environment)
    if (-not (Get-Module -ListAvailable -Name Microsoft.Graph.Authentication)) {
        throw "Microsoft Graph SDK not found. Run: Install-Module Microsoft.Graph -Scope CurrentUser"
    }
    Import-Module Microsoft.Graph.Authentication -ErrorAction Stop
    if (-not (Get-MgContext)) {
        if ($Environment -eq 'Global') { Connect-MgGraph -Scopes $Scopes | Out-Null }
        else { Connect-MgGraph -Scopes $Scopes -Environment $Environment | Out-Null }
    }
}

$graphHost = switch ($GraphEnvironment) {
    'USGov'    { 'https://graph.microsoft.us' }
    'USGovDoD' { 'https://dod-graph.microsoft.us' }
    default    { 'https://graph.microsoft.com' }
}
$base = "$graphHost/beta"

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

Connect-Graph -Scopes @('DeviceManagementApps.Read.All','DeviceManagementManagedDevices.Read.All') -Environment $GraphEnvironment

$apps = Invoke-GraphGet -Uri "$base/deviceAppManagement/mobileApps?`$top=200"
if ($AppNameLike) { $apps = $apps | Where-Object { $_.displayName -like "*$AppNameLike*" } }
# Only app types Intune tracks per-device install/uninstall for.
$apps = $apps | Where-Object { $_.'@odata.type' -match 'win32|windowsMobileMSI|microsoftStoreForBusiness|winGet' }
if (-not $apps) { throw "No matching apps found." }

$report = foreach ($app in $apps) {
    $statuses = Invoke-GraphGet -Uri "$base/deviceAppManagement/mobileApps/$($app.id)/deviceStatuses"
    $grp = $statuses | Group-Object installState -AsHashTable -AsString
    [pscustomobject]@{
        AppName         = $app.displayName
        NotInstalled    = @($grp['notInstalled']).Count
        UninstallFailed = @($grp['uninstallFailed']).Count
        Pending         = (@($grp['pendingInstall']).Count + @($grp['pending']).Count)
        StillInstalled  = @($grp['installed']).Count
        Unknown         = @($grp['unknown']).Count
        TotalReporting  = @($statuses).Count
    }
}

$report | Sort-Object UninstallFailed -Descending |
    Format-Table -AutoSize AppName, NotInstalled, UninstallFailed, Pending, StillInstalled, Unknown, TotalReporting

if ($CsvPath) {
    $report | Export-Csv -Path $CsvPath -NoTypeInformation -Encoding UTF8
    Write-Host "Saved report to $CsvPath" -ForegroundColor Green
}

$totFail = ($report | Measure-Object UninstallFailed -Sum).Sum
$totUnk  = ($report | Measure-Object Unknown -Sum).Sum
Write-Host ("`nTotal uninstallFailed: {0}  |  Total unknown (non-reporting): {1}" -f $totFail, $totUnk) -ForegroundColor Cyan
if ($totUnk -gt 0) { Write-Host "High 'unknown' = devices not checking in -> Branch I (reporting/lifecycle), not a command failure." -ForegroundColor Yellow }
