<#
.SYNOPSIS
    DYNTGT-Validation.ps1 — validate a device's dynamic group membership and effective targeting.
.DESCRIPTION
    PURPOSE
        For a named device, reports which dynamic groups it belongs to and evaluates the include/
        exclude assignment filters against its managed-device attributes, so you can confirm the
        effective targeting matches intent before expanding.
    HOW TO RUN
        powershell -ExecutionPolicy Bypass -File .\DYNTGT-Validation.ps1 -DeviceName "PILOT-PC-01"
        Requires Microsoft Graph SDK and scopes Group.Read.All,
        DeviceManagementManagedDevices.Read.All, DeviceManagementConfiguration.Read.All.
    EXPECTED RESULTS
        The device's Entra group memberships and, per assignment filter, whether the device matches
        (would be included) or not (would be excluded).
.NOTES
    White-label — Intune Solutions. Read-only against Graph.
#>
[CmdletBinding()] param([Parameter(Mandatory)][string]$DeviceName)
if (-not (Get-Module -ListAvailable -Name Microsoft.Graph.Authentication)) { Install-Module Microsoft.Graph -Scope CurrentUser -Force -AllowClobber }
Import-Module Microsoft.Graph.Authentication -ErrorAction Stop
Connect-MgGraph -Scopes 'Group.Read.All','DeviceManagementManagedDevices.Read.All','DeviceManagementConfiguration.Read.All' -NoWelcome

Write-Host ("=== Effective targeting — {0} ===" -f $DeviceName) -ForegroundColor Cyan
$md = (Invoke-MgGraphRequest -Method GET -Uri ("/v1.0/deviceManagement/managedDevices?`$filter=deviceName eq '{0}'" -f $DeviceName)).value | Select-Object -First 1
if (-not $md) { Write-Host "  Managed device not found." -ForegroundColor Yellow; Disconnect-MgGraph | Out-Null; exit 1 }
Write-Host ("  OS {0} {1} | ownership {2} | model {3}" -f $md.operatingSystem, $md.osVersion, $md.managedDeviceOwnerType, $md.model)

# Entra device object + group memberships
$ad = (Invoke-MgGraphRequest -Method GET -Uri ("/v1.0/devices?`$filter=deviceId eq '{0}'" -f $md.azureADDeviceId)).value | Select-Object -First 1
Write-Host "`n  Dynamic/assigned group memberships:" -ForegroundColor Cyan
if ($ad) {
    $mem = (Invoke-MgGraphRequest -Method GET -Uri ("/v1.0/devices/{0}/memberOf?`$select=displayName,groupTypes" -f $ad.id)).value
    if ($mem) { $mem | ForEach-Object { Write-Host ("    - {0}" -f $_.displayName) } } else { Write-Host "    (none)" -ForegroundColor Yellow }
} else { Write-Host "    Entra device object not found." -ForegroundColor Yellow }

# Evaluate assignment filters against this device's attributes (simple attribute match)
Write-Host "`n  Assignment-filter match (would-include):" -ForegroundColor Cyan
$filters = (Invoke-MgGraphRequest -Method GET -Uri '/beta/deviceManagement/assignmentFilters').value
foreach ($f in $filters) {
    $match = $false
    switch -Regex ($f.rule) {
        'osVersion\s+-startsWith\s+"([^"]+)"'        { $match = $md.osVersion -like ($matches[1] + '*') }
        'deviceOwnership\s+-eq\s+"Personal"'         { $match = $md.managedDeviceOwnerType -eq 'personal' }
        'deviceOwnership\s+-eq\s+"Corporate"'        { $match = $md.managedDeviceOwnerType -eq 'company' }
        'model\s+-startsWith\s+"([^"]+)"'            { $match = $md.model -like ($matches[1] + '*') }
        'model\s+-eq\s+"([^"]+)"'                    { $match = $md.model -eq $matches[1] }
        'operatingSystem\s+-eq\s+"([^"]+)"'          { $match = $md.operatingSystem -eq $matches[1] }
    }
    Write-Host ("    {0}  [{1}]  -> {2}" -f $f.displayName, $f.platform, ($(if($match){'MATCH'}else{'no match'}))) -ForegroundColor ($(if($match){'Green'}else{'Gray'}))
}
Write-Host "`nReview: group membership + filter mode (include/exclude) = effective targeting." -ForegroundColor Cyan
Disconnect-MgGraph | Out-Null
