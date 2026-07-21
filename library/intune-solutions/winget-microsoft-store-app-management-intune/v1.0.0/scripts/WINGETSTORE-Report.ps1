<#
.SYNOPSIS
    WINGETSTORE-Report.ps1 — install/update status for Microsoft Store (new) / winget apps, exported to
    CSV (Microsoft Graph, read-only).
.DESCRIPTION
    PURPOSE
        Read-only report of how each Store (new) / winget app is deploying across the fleet —
        Installed / Failed / Not applicable / Pending counts, and (with -CsvPath) a per-device row
        including the installed version so you can spot apps lagging behind on updates. Use it to gate
        the pilot before expanding and to chase failures.
    HOW TO RUN
        powershell -ExecutionPolicy Bypass -File .\WINGETSTORE-Report.ps1
        powershell -ExecutionPolicy Bypass -File .\WINGETSTORE-Report.ps1 `
            -AppName "Adobe Acrobat Reader – Store – Required" -CsvPath C:\Temp\wingetstore.csv
        Requires the Microsoft Graph PowerShell SDK.
    GRAPH SCOPES
        DeviceManagementApps.Read.All   (read app install summaries + device statuses)
    EXPECTED RESULTS
        A status summary per app and, with -CsvPath, a per-device CSV (device, app, install state,
        detected version) for reviewing update lag. No data is modified.
.NOTES
    Intune Solutions — read-only against Graph. New Store app type = 'microsoft.graph.winGetApp'.
    Update cadence is service-managed; confirm expected timing against Microsoft docs
    (verify-with-Microsoft) before treating a version lag as a failure.
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

$apps = @(); $uri = "/v1.0/deviceAppManagement/mobileApps?`$filter=isof('microsoft.graph.winGetApp')"
do { $r = Invoke-MgGraphRequest -Method GET -Uri $uri; $apps += $r.value; $uri = $r.'@odata.nextLink' } while ($uri)
if ($AppName) { $apps = $apps | Where-Object { $_.displayName -eq $AppName } }
if (-not $apps) { Write-Host "No matching Store (new) / winget apps found." -ForegroundColor Yellow; Disconnect-MgGraph | Out-Null; return }

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
                $rows += [pscustomobject]@{
                    App          = $app.displayName
                    Device       = $d.deviceName
                    InstallState = $d.installState
                    Version      = $d.installedVersion   # detected version, for update-lag review
                    DetailCode   = $d.installStateDetail
                }
            }
            $duri = $dr.'@odata.nextLink'
        } while ($duri)
    }
}

if ($CsvPath -and $rows.Count) { $rows | Export-Csv -Path $CsvPath -NoTypeInformation; Write-Host "Saved $CsvPath" -ForegroundColor Green }
Disconnect-MgGraph | Out-Null
