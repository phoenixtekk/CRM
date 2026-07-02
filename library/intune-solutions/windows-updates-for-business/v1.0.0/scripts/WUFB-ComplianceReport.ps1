<#
.SYNOPSIS
    WUFB-ComplianceReport.ps1 — fleet-wide update status + OS-build inventory (Microsoft Graph).
.DESCRIPTION
    PURPOSE
        Summarizes managed Windows devices by OS version/build and last sync, so you can see which
        devices are on the target feature version and which are lagging.
    HOW TO RUN
        powershell -ExecutionPolicy Bypass -File .\WUFB-ComplianceReport.ps1 -CsvPath C:\Temp\wufb.csv
        Requires Microsoft Graph SDK and DeviceManagementManagedDevices.Read.All.
    EXPECTED RESULTS
        A breakdown of devices by OS version and a per-device CSV (device, OS version, last sync).
.NOTES
    White-label — Intune Solutions. Read-only against Graph.
#>
[CmdletBinding()] param([string]$CsvPath)
if (-not (Get-Module -ListAvailable -Name Microsoft.Graph.Authentication)) { Install-Module Microsoft.Graph -Scope CurrentUser -Force -AllowClobber }
Import-Module Microsoft.Graph.Authentication -ErrorAction Stop
Connect-MgGraph -Scopes 'DeviceManagementManagedDevices.Read.All' -NoWelcome
$devs = @(); $uri = '/v1.0/deviceManagement/managedDevices?$select=deviceName,operatingSystem,osVersion,lastSyncDateTime&$filter=operatingSystem eq ''Windows'''
do { $r = Invoke-MgGraphRequest -Method GET -Uri $uri; $devs += $r.value; $uri = $r.'@odata.nextLink' } while ($uri)
$report = $devs | ForEach-Object { [pscustomobject]@{ Device=$_.deviceName; OSVersion=$_.osVersion; LastSync=$_.lastSyncDateTime } }
Write-Host "=== Windows devices by OS version ===" -ForegroundColor Cyan
$report | Group-Object OSVersion | Sort-Object Name -Descending | Select-Object Count, @{n='OSVersion';e={$_.Name}} | Format-Table -AutoSize
Write-Host ("Total Windows devices: {0}" -f $report.Count) -ForegroundColor Cyan
if ($CsvPath) { $report | Export-Csv -Path $CsvPath -NoTypeInformation; Write-Host "Saved $CsvPath" }
Disconnect-MgGraph | Out-Null
