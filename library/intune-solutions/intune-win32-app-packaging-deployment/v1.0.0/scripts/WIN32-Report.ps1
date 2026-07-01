<#
.SYNOPSIS
    WIN32-Report.ps1 — fleet-wide Win32 app deployment success/failure report (Microsoft Graph).
.DESCRIPTION
    PURPOSE
        Read-only report of how a Win32 app (or all Win32 apps) is deploying across the fleet —
        Installed / Failed / Not applicable / Pending counts, optionally per device. Use it to gate
        the pilot before expanding and to chase failures.
    HOW TO RUN
        powershell -ExecutionPolicy Bypass -File .\WIN32-Report.ps1
        powershell -ExecutionPolicy Bypass -File .\WIN32-Report.ps1 -AppName "Contoso LOB Suite – Win32 – v4.2.0" -CsvPath C:\Temp\win32.csv
        Requires the Microsoft Graph SDK and DeviceManagementApps.Read.All.
    EXPECTED RESULTS
        A status summary per Win32 app and, with -CsvPath, a per-device CSV (device, app, install state).
.NOTES
    Workplace Marketplace — Intune Solutions. Read-only against Graph.
#>
[CmdletBinding()]
param(
    [string]$AppName,
    [string]$CsvPath
)

if (-not (Get-Module -ListAvailable -Name Microsoft.Graph.Authentication)) {
    Install-Module Microsoft.Graph -Scope CurrentUser -Force -AllowClobber
}
Import-Module Microsoft.Graph.Authentication -ErrorAction Stop
Connect-MgGraph -Scopes 'DeviceManagementApps.Read.All' -NoWelcome

# Win32 LOB apps
$apps = @(); $uri = "/v1.0/deviceAppManagement/mobileApps?`$filter=isof('microsoft.graph.win32LobApp')"
do { $r = Invoke-MgGraphRequest -Method GET -Uri $uri; $apps += $r.value; $uri = $r.'@odata.nextLink' } while ($uri)
if ($AppName) { $apps = $apps | Where-Object { $_.displayName -eq $AppName } }
if (-not $apps) { Write-Host "No matching Win32 apps found." -ForegroundColor Yellow; Disconnect-MgGraph | Out-Null; return }

$rows = @()
foreach ($app in $apps) {
    $id = $app.id
    $st = Invoke-MgGraphRequest -Method GET -Uri "/v1.0/deviceAppManagement/mobileApps/$id/installSummary"
    Write-Host ("=== {0} ===" -f $app.displayName) -ForegroundColor Cyan
    Write-Host ("  Installed:{0}  Failed:{1}  NotApplicable:{2}  Pending:{3}" -f `
        $st.installedDeviceCount, $st.failedDeviceCount, $st.notApplicableDeviceCount, $st.pendingInstallDeviceCount)

    if ($CsvPath) {
        $duri = "/v1.0/deviceAppManagement/mobileApps/$id/deviceStatuses"
        do {
            $dr = Invoke-MgGraphRequest -Method GET -Uri $duri
            foreach ($d in $dr.value) {
                $rows += [pscustomobject]@{ App=$app.displayName; Device=$d.deviceName; InstallState=$d.installState; DetailCode=$d.installStateDetail }
            }
            $duri = $dr.'@odata.nextLink'
        } while ($duri)
    }
}

if ($CsvPath -and $rows.Count) { $rows | Export-Csv -Path $CsvPath -NoTypeInformation; Write-Host "Saved $CsvPath" -ForegroundColor Green }
Disconnect-MgGraph | Out-Null
