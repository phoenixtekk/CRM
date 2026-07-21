<#
.SYNOPSIS
    ENTAPPCAT-Report.ps1 — export catalog-app install + update status to CSV.
.DESCRIPTION
    PURPOSE
        Read-only fleet report of how Enterprise App Catalog (and Win32) apps are deploying and
        updating — Installed / Failed / Not applicable / Pending counts per app, and (with -CsvPath)
        a per-device row including the reported version so you can see update progress across rings.
    HOW TO RUN
        powershell -ExecutionPolicy Bypass -File .\ENTAPPCAT-Report.ps1
        powershell -ExecutionPolicy Bypass -File .\ENTAPPCAT-Report.ps1 `
          -AppName "Catalog App – Sample App – Prod" -CsvPath C:\Temp\entappcat.csv
    GRAPH SCOPES
        DeviceManagementApps.Read.All   (delegated, read-only)
    EXPECTED RESULTS
        A per-app status summary on screen and, with -CsvPath, a per-device CSV
        (device, app, install state, version). No changes are made.
.NOTES
    Intune Solutions. Read-only against Microsoft Graph.
    Enterprise App Catalog Graph type ('win32CatalogApp') is verify-with-Microsoft.
#>
[CmdletBinding()]
param(
    [string]$AppName,
    [string]$CsvPath,
    [string]$GraphEnvironment = 'Global'
)

if (-not (Get-Module -ListAvailable -Name Microsoft.Graph.Authentication)) {
    Install-Module Microsoft.Graph -Scope CurrentUser -Force -AllowClobber
}
Import-Module Microsoft.Graph.Authentication -ErrorAction Stop
Connect-MgGraph -Scopes 'DeviceManagementApps.Read.All' -Environment $GraphEnvironment -NoWelcome

$uri  = "/beta/deviceAppManagement/mobileApps?`$filter=isof('microsoft.graph.win32CatalogApp') or isof('microsoft.graph.win32LobApp')"
$apps = @()
do { $r = Invoke-MgGraphRequest -Method GET -Uri $uri; $apps += $r.value; $uri = $r.'@odata.nextLink' } while ($uri)
if ($AppName) { $apps = $apps | Where-Object { $_.displayName -eq $AppName } }
if (-not $apps) { Write-Host "No matching apps found." -ForegroundColor Yellow; Disconnect-MgGraph | Out-Null; return }

$rows = @()
foreach ($app in $apps) {
    $st = Invoke-MgGraphRequest -Method GET -Uri "/beta/deviceAppManagement/mobileApps/$($app.id)/installSummary"
    Write-Host ("=== {0} ===" -f $app.displayName) -ForegroundColor Cyan
    Write-Host ("  Installed:{0}  Failed:{1}  NotApplicable:{2}  Pending:{3}" -f `
        $st.installedDeviceCount, $st.failedDeviceCount, $st.notApplicableDeviceCount, $st.pendingInstallDeviceCount)

    if ($CsvPath) {
        $duri = "/beta/deviceAppManagement/mobileApps/$($app.id)/deviceStatuses"
        do {
            $dr = Invoke-MgGraphRequest -Method GET -Uri $duri
            foreach ($d in $dr.value) {
                $rows += [pscustomobject]@{
                    App          = $app.displayName
                    Device       = $d.deviceName
                    InstallState = $d.installState
                    Version      = $d.installedVersion   # reported version — update progress (verify field)
                    DetailCode   = $d.installStateDetail
                }
            }
            $duri = $dr.'@odata.nextLink'
        } while ($duri)
    }
}

if ($CsvPath -and $rows.Count) { $rows | Export-Csv -Path $CsvPath -NoTypeInformation; Write-Host "Saved $CsvPath" -ForegroundColor Green }
Disconnect-MgGraph | Out-Null
