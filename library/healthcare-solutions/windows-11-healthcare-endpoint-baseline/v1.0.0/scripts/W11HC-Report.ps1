<#
.SYNOPSIS
    W11HC-Report.ps1 - fleet-wide baseline status + OS-build inventory (Microsoft Graph).
.DESCRIPTION
    PURPOSE
        Reports, across all managed Windows 11 devices, their OS version/build and last sync, and the
        per-device deployment status of each baseline configuration policy - so you can see which
        devices have inherited the baseline and which are drifting/lagging.
    HOW TO RUN
        powershell -ExecutionPolicy Bypass -File .\W11HC-Report.ps1 -CsvPath C:\Temp\w11hc.csv
        Requires the Microsoft Graph PowerShell SDK and the scopes
        DeviceManagementManagedDevices.Read.All and DeviceManagementConfiguration.Read.All.
    EXPECTED RESULTS
        A breakdown of Windows devices by OS version, a count of devices per baseline policy status,
        and (optional) a per-device CSV.
.NOTES
    Healthcare Solutions - Windows 11 endpoint baseline. Read-only against Graph.
#>
[CmdletBinding()] param([string]$CsvPath)
if (-not (Get-Module -ListAvailable -Name Microsoft.Graph.Authentication)) { Install-Module Microsoft.Graph -Scope CurrentUser -Force -AllowClobber }
Import-Module Microsoft.Graph.Authentication -ErrorAction Stop
Connect-MgGraph -Scopes 'DeviceManagementManagedDevices.Read.All','DeviceManagementConfiguration.Read.All' -NoWelcome
# Devices
$devs = @(); $uri = "/v1.0/deviceManagement/managedDevices?`$select=deviceName,operatingSystem,osVersion,lastSyncDateTime&`$filter=operatingSystem eq 'Windows'"
do { $r = Invoke-MgGraphRequest -Method GET -Uri $uri; $devs += $r.value; $uri = $r.'@odata.nextLink' } while ($uri)
$report = $devs | ForEach-Object { [pscustomobject]@{ Device=$_.deviceName; OSVersion=$_.osVersion; LastSync=$_.lastSyncDateTime } }
Write-Host "=== Windows devices by OS version ===" -ForegroundColor Cyan
$report | Group-Object OSVersion | Sort-Object Name -Descending | Select-Object Count, @{n='OSVersion';e={$_.Name}} | Format-Table -AutoSize
Write-Host ("Total Windows devices: {0}" -f $report.Count) -ForegroundColor Cyan
# Baseline policy status (device config profiles whose name starts with the W11 convention)
Write-Host "`n=== Baseline configuration policies - per-status counts ===" -ForegroundColor Cyan
$cfgs = (Invoke-MgGraphRequest -Method GET -Uri "/beta/deviceManagement/deviceConfigurations?`$select=id,displayName").value | Where-Object { $_.displayName -like 'W11 *' }
foreach ($c in $cfgs) {
    $st = (Invoke-MgGraphRequest -Method GET -Uri "/beta/deviceManagement/deviceConfigurations/$($c.id)/deviceStatusOverview" -ErrorAction SilentlyContinue)
    Write-Host ("  {0,-40} success={1} error={2} conflict={3}" -f $c.displayName, $st.successCount, $st.errorCount, $st.conflictCount)
}
if (-not $cfgs) { Write-Host "  No 'W11 ...' baseline policies found." -ForegroundColor Yellow }
if ($CsvPath) { $report | Export-Csv -Path $CsvPath -NoTypeInformation; Write-Host "`nSaved $CsvPath" }
Disconnect-MgGraph | Out-Null
