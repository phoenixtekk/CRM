<#
.SYNOPSIS
    INTAPPDX-Discovery.ps1 — inventory Intune apps with their assignments, dependencies, and supersedence links.
.DESCRIPTION
    PURPOSE
        Builds a read-only inventory of Win32, LOB, and Store apps in the tenant.
        For each app it lists the assignment groups (Required/Available/Uninstall),
        dependency apps, and supersedence links so you can see where a device is in
        scope and whether a relationship is blocking an install.
    HOW TO RUN
        powershell -ExecutionPolicy Bypass -File .\INTAPPDX-Discovery.ps1

        Required Graph scopes: DeviceManagementApps.Read.All, DeviceManagementManagedDevices.Read.All
    EXPECTED RESULTS
        A table (and optional CSV) of apps with assignment, dependency, and supersedence
        detail. Pass = your target app and its relationships appear as expected. Fail =
        the app is missing an assignment to the device's group, or shows an unexpected
        dependency/supersedence link (investigate in the Diagnostic Playbook).
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
    $ctx = Get-MgContext
    if (-not $ctx) { Connect-MgGraph -Scopes $scopes | Out-Null }
}

function Invoke-GraphGet {
    param([Parameter(Mandatory)][string] $Uri)
    $items = @()
    $next = $Uri
    while ($next) {
        $resp = Invoke-MgGraphRequest -Method GET -Uri $next
        if ($resp.value) { $items += $resp.value } elseif ($resp) { $items += $resp }
        $next = $resp.'@odata.nextLink'
    }
    return $items
}

Connect-Graph

$base = 'https://graph.microsoft.com/beta'
$appsUri = "$base/deviceAppManagement/mobileApps?`$top=100"
Write-Host "Reading apps from Intune..." -ForegroundColor Cyan
$apps = Invoke-GraphGet -Uri $appsUri

if ($AppNameLike) {
    $apps = $apps | Where-Object { $_.displayName -like "*$AppNameLike*" }
}

$results = foreach ($app in $apps) {
    $id   = $app.id
    $name = $app.displayName
    $type = ($app.'@odata.type' -replace '#microsoft.graph.','')

    $assignments = @()
    try {
        $a = Invoke-GraphGet -Uri "$base/deviceAppManagement/mobileApps/$id/assignments"
        $assignments = $a | ForEach-Object {
            $intent = $_.intent
            $target = ($_.target.'@odata.type' -replace '#microsoft.graph.','')
            $grp    = $_.target.groupId
            "$intent -> $target$(if($grp){" ($grp)"})"
        }
    } catch { $assignments = @('(unable to read assignments)') }

    $relationships = @()
    try {
        $rel = Invoke-GraphGet -Uri "$base/deviceAppManagement/mobileApps/$id/relationships"
        $relationships = $rel | ForEach-Object {
            $rtype = ($_.'@odata.type' -replace '#microsoft.graph.','')
            "$rtype -> $($_.targetDisplayName)"
        }
    } catch { }

    [pscustomobject]@{
        AppName        = $name
        AppType        = $type
        AppId          = $id
        Assignments    = ($assignments -join '; ')
        Relationships  = ($relationships -join '; ')
    }
}

$results | Sort-Object AppName | Format-Table -AutoSize AppName, AppType, Assignments, Relationships

if ($CsvPath) {
    $results | Export-Csv -Path $CsvPath -NoTypeInformation -Encoding UTF8
    Write-Host "Saved inventory to $CsvPath" -ForegroundColor Green
}

Write-Host ("Discovered {0} app(s)." -f $results.Count) -ForegroundColor Green
