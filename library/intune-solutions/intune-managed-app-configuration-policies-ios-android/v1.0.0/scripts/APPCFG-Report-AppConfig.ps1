<#
.SYNOPSIS
    APPCFG-Report-AppConfig.ps1 — which managed apps have app configuration, and which do not (read-only, Graph).
.DESCRIPTION
    PURPOSE
        Coverage report. Lists the managed apps in the tenant (iOS store/VPP and Android managed
        Google Play apps) and cross-references the managed-device App Configuration Policies to show,
        per app, whether an App Configuration Policy is attached. Surfaces the gaps — apps that are
        deployed but not configured. Read-only.
    HOW TO RUN
        powershell -ExecutionPolicy Bypass -File .\APPCFG-Report-AppConfig.ps1 -CsvPath C:\Temp\appcfg-coverage.csv
        powershell -ExecutionPolicy Bypass -File .\APPCFG-Report-AppConfig.ps1 -Environment USGov
        Requires the Microsoft Graph SDK and DeviceManagementApps.Read.All.
    EXPECTED RESULTS
        One row per app (App / Platform / BundleOrPackage / HasConfig / PolicyName). PASS = every app
        that should be configured shows HasConfig = True.
.NOTES
    Intune Solutions — read-only. Cloud-aware (Commercial / USGov). No credentials stored.
.EXAMPLE
    .\APPCFG-Report-AppConfig.ps1 -CsvPath C:\Temp\appcfg-coverage.csv
#>
[CmdletBinding()]
param(
    [string]$CsvPath,
    [ValidateSet('Global', 'USGov', 'USGovDoD')]
    [string]$Environment = 'Global'
)

if (-not (Get-Module -ListAvailable -Name Microsoft.Graph.Authentication)) {
    Install-Module Microsoft.Graph -Scope CurrentUser -Force -AllowClobber
}
Import-Module Microsoft.Graph.Authentication -ErrorAction Stop
Connect-MgGraph -Scopes 'DeviceManagementApps.Read.All' -Environment $Environment -NoWelcome

function Get-GraphAll($uri) {
    $items = @()
    do { $resp = Invoke-MgGraphRequest -Method GET -Uri $uri; $items += $resp.value; $uri = $resp.'@odata.nextLink' } while ($uri)
    return $items
}

# Build a map: appId -> config policy name (managed-device channel)
$cfgByApp = @{}
foreach ($c in (Get-GraphAll "/v1.0/deviceAppManagement/mobileAppConfigurations")) {
    foreach ($appId in @($c.targetedMobileApps)) { $cfgByApp[$appId] = $c.displayName }
}

$mobileTypes = @{
    '#microsoft.graph.iosStoreApp'                = 'iOS'
    '#microsoft.graph.iosVppApp'                  = 'iOS'
    '#microsoft.graph.androidManagedStoreApp'     = 'Android'
    '#microsoft.graph.androidManagedStoreWebApp'  = 'Android'
}

$rows = @()
foreach ($app in (Get-GraphAll "/v1.0/deviceAppManagement/mobileApps")) {
    $plat = $mobileTypes[$app.'@odata.type']
    if (-not $plat) { continue }
    $id = if ($app.bundleId) { $app.bundleId } elseif ($app.packageId) { $app.packageId } elseif ($app.appIdentifier) { $app.appIdentifier } else { '' }
    $has = $cfgByApp.ContainsKey($app.id)
    $rows += [pscustomobject]@{
        App             = $app.displayName
        Platform        = $plat
        BundleOrPackage = $id
        HasConfig       = $has
        PolicyName      = if ($has) { $cfgByApp[$app.id] } else { '' }
    }
}

if (-not $rows) {
    Write-Host "No iOS/Android managed apps found." -ForegroundColor Yellow
} else {
    $rows | Sort-Object HasConfig, Platform, App | Format-Table -AutoSize
    $missing = ($rows | Where-Object { -not $_.HasConfig }).Count
    Write-Host ("`nApps: {0} | Without app config: {1}" -f $rows.Count, $missing) -ForegroundColor Cyan
    if ($missing) { Write-Host "Review apps with HasConfig=False — configure the ones that need it." -ForegroundColor Yellow }
    if ($CsvPath) { $rows | Export-Csv -Path $CsvPath -NoTypeInformation; Write-Host "Saved $CsvPath" -ForegroundColor Green }
}
Disconnect-MgGraph | Out-Null
