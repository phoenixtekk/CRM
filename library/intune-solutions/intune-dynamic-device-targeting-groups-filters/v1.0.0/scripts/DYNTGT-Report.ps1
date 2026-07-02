<#
.SYNOPSIS
    DYNTGT-Report.ps1 — targeting coverage and drift across the fleet (Microsoft Graph).
.DESCRIPTION
    PURPOSE
        Reports how managed Windows devices break down by ownership and OS, counts dynamic-group
        coverage, and flags drift — devices that are enrolled but matched by no dynamic targeting
        group (potential coverage gaps).
    HOW TO RUN
        powershell -ExecutionPolicy Bypass -File .\DYNTGT-Report.ps1 -CsvPath C:\Temp\dyntgt.csv
        Requires Microsoft Graph SDK and scopes Group.Read.All,
        DeviceManagementManagedDevices.Read.All.
    EXPECTED RESULTS
        Coverage summary (devices by ownership/OS, dynamic-group member counts) and a drift list of
        devices in no dynamic group; optional per-device CSV.
.NOTES
    White-label — Intune Solutions. Read-only against Graph.
#>
[CmdletBinding()] param([string]$CsvPath)
if (-not (Get-Module -ListAvailable -Name Microsoft.Graph.Authentication)) { Install-Module Microsoft.Graph -Scope CurrentUser -Force -AllowClobber }
Import-Module Microsoft.Graph.Authentication -ErrorAction Stop
Connect-MgGraph -Scopes 'Group.Read.All','DeviceManagementManagedDevices.Read.All' -NoWelcome

# Managed devices
$devs = @(); $uri = "/v1.0/deviceManagement/managedDevices?`$select=deviceName,operatingSystem,osVersion,managedDeviceOwnerType,azureADDeviceId&`$filter=operatingSystem eq 'Windows'"
do { $r = Invoke-MgGraphRequest -Method GET -Uri $uri; $devs += $r.value; $uri = $r.'@odata.nextLink' } while ($uri)

Write-Host "=== Coverage — Windows devices by ownership ===" -ForegroundColor Cyan
$devs | Group-Object managedDeviceOwnerType | Select-Object Count, @{n='Ownership';e={$_.Name}} | Format-Table -AutoSize

# Dynamic groups and their members (azureADDeviceId set)
$dg = @(); $guri = "/v1.0/groups?`$filter=groupTypes/any(c:c eq 'DynamicMembership')&`$select=id,displayName"
do { $gr = Invoke-MgGraphRequest -Method GET -Uri $guri; $dg += $gr.value; $guri = $gr.'@odata.nextLink' } while ($guri)
$covered = New-Object System.Collections.Generic.HashSet[string]
Write-Host "=== Dynamic-group member counts ===" -ForegroundColor Cyan
foreach ($g in $dg) {
    $members = (Invoke-MgGraphRequest -Method GET -Uri ("/v1.0/groups/{0}/members?`$select=deviceId,displayName" -f $g.id)).value
    foreach ($m in $members) { if ($m.deviceId) { [void]$covered.Add($m.deviceId) } }
    Write-Host ("  {0}: {1} members" -f $g.displayName, $members.Count)
}

# Drift: managed devices whose Entra deviceId is in no dynamic group
$drift = $devs | Where-Object { $_.azureADDeviceId -and -not $covered.Contains($_.azureADDeviceId) }
Write-Host ("`n=== Drift — devices in NO dynamic group: {0} ===" -f $drift.Count) -ForegroundColor ($(if($drift.Count){'Yellow'}else{'Green'}))
$drift | Select-Object -First 25 | ForEach-Object { Write-Host ("  {0}  ({1} {2})" -f $_.deviceName, $_.operatingSystem, $_.osVersion) }

if ($CsvPath) {
    $devs | ForEach-Object { [pscustomobject]@{ Device=$_.deviceName; OS=$_.operatingSystem; OSVersion=$_.osVersion; Ownership=$_.managedDeviceOwnerType; InDynamicGroup=($_.azureADDeviceId -and $covered.Contains($_.azureADDeviceId)) } } | Export-Csv -Path $CsvPath -NoTypeInformation
    Write-Host ("Saved {0}" -f $CsvPath)
}
Disconnect-MgGraph | Out-Null
