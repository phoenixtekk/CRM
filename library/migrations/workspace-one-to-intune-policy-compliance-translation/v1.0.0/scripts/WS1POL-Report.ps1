<#
.SYNOPSIS
    WS1POL-Report.ps1 — per-policy and per-device configuration + compliance state (Microsoft Graph).
.DESCRIPTION
    PURPOSE
        Reports the deployment state of the mapped Intune policies: which 'Mapped Config' and 'Mapped
        Compliance' policies exist, their assigned groups, and the device compliance state for the
        managed fleet — so you can confirm the translated policy reached the pilot/production scope and
        devices are compliant under the translated rules.
    HOW TO RUN
        powershell -ExecutionPolicy Bypass -File .\WS1POL-Report.ps1 -CsvPath C:\Temp\ws1pol-devices.csv
        Requires Microsoft Graph SDK with DeviceManagementConfiguration.Read.All and
        DeviceManagementManagedDevices.Read.All.
    EXPECTED RESULTS
        A list of the mapped configuration and compliance policies with assigned group IDs, plus a
        per-device compliance summary and (optional) a per-device CSV.
.NOTES
    Workspace ONE to Intune migration — read-only against Microsoft Graph.
#>
[CmdletBinding()] param([string]$CsvPath)

if (-not (Get-Module -ListAvailable -Name Microsoft.Graph.Authentication)) { Install-Module Microsoft.Graph -Scope CurrentUser -Force -AllowClobber }
Import-Module Microsoft.Graph.Authentication -ErrorAction Stop
Connect-MgGraph -Scopes 'DeviceManagementConfiguration.Read.All','DeviceManagementManagedDevices.Read.All' -NoWelcome

function Get-CfgAssignments($id) {
    try { (Invoke-MgGraphRequest -Method GET -Uri "/beta/deviceManagement/configurationPolicies/$id/assignments").value | ForEach-Object { $_.target.groupId } | Where-Object { $_ } } catch { @() }
}
function Get-CompAssignments($id) {
    try { (Invoke-MgGraphRequest -Method GET -Uri "/v1.0/deviceManagement/deviceCompliancePolicies/$id/assignments").value | ForEach-Object { $_.target.groupId } | Where-Object { $_ } } catch { @() }
}

# Mapped configuration policies (settings catalog).
$cfg = @(); $uri = '/beta/deviceManagement/configurationPolicies?$select=id,name'
do { $r = Invoke-MgGraphRequest -Method GET -Uri $uri; $cfg += $r.value; $uri = $r.'@odata.nextLink' } while ($uri)
$cfg = $cfg | Where-Object { $_.name -match 'Mapped Config -' }
Write-Host "`n=== Mapped configuration policies ===" -ForegroundColor Cyan
foreach ($c in $cfg) { Write-Host ("  {0}  [groups: {1}]" -f $c.name, ((Get-CfgAssignments $c.id) -join ', ')) }
if (-not $cfg) { Write-Host "  none found (expected 'Mapped Config - <Platform> - <Stage>')" -ForegroundColor Yellow }

# Mapped compliance policies.
$comp = @(); $uri = '/v1.0/deviceManagement/deviceCompliancePolicies?$select=id,displayName'
do { $r = Invoke-MgGraphRequest -Method GET -Uri $uri; $comp += $r.value; $uri = $r.'@odata.nextLink' } while ($uri)
$comp = $comp | Where-Object { $_.displayName -match 'Mapped Compliance -' }
Write-Host "`n=== Mapped compliance policies ===" -ForegroundColor Cyan
foreach ($c in $comp) { Write-Host ("  {0}  [groups: {1}]" -f $c.displayName, ((Get-CompAssignments $c.id) -join ', ')) }
if (-not $comp) { Write-Host "  none found (expected 'Mapped Compliance - <Platform> - <Stage>')" -ForegroundColor Yellow }

# Per-device compliance summary.
$devs = @(); $uri = '/v1.0/deviceManagement/managedDevices?$select=deviceName,operatingSystem,osVersion,complianceState,lastSyncDateTime'
do { $r = Invoke-MgGraphRequest -Method GET -Uri $uri; $devs += $r.value; $uri = $r.'@odata.nextLink' } while ($uri)
$report = $devs | ForEach-Object { [pscustomobject]@{ Device=$_.deviceName; OS=$_.operatingSystem; OSVersion=$_.osVersion; Compliance=$_.complianceState; LastSync=$_.lastSyncDateTime } }
Write-Host "`n=== Devices by compliance state ===" -ForegroundColor Cyan
$report | Group-Object Compliance | Select-Object Count, @{n='State';e={$_.Name}} | Format-Table -AutoSize
Write-Host ("Total managed devices: {0}" -f $report.Count) -ForegroundColor Cyan

if ($CsvPath) { $report | Export-Csv -Path $CsvPath -NoTypeInformation; Write-Host "Saved $CsvPath" -ForegroundColor Green }
Disconnect-MgGraph | Out-Null
