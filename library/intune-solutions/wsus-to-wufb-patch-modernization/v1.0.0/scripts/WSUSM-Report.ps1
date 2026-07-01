<#
.SYNOPSIS
    WSUSM-Report.ps1 — fleet patch-status and update-ring report (Microsoft Graph).
.DESCRIPTION
    PURPOSE
        Read-only. Produces a migration-readiness picture from Intune: the Windows Update for
        Business update rings and feature update policies with their assigned groups, plus a
        per-device patch-status / OS-build inventory. Use it to track the cutover and confirm no
        device is left without a ring before WSUS is decommissioned.
    HOW TO RUN
        powershell -ExecutionPolicy Bypass -File .\WSUSM-Report.ps1
        Requires the Microsoft Graph PowerShell SDK and consented scopes
        DeviceManagementConfiguration.Read.All and DeviceManagementManagedDevices.Read.All.
    EXPECTED RESULTS
        A list of update rings and feature update policies with assigned group IDs, followed by a
        managed-device table (name, OS, OS version, last sync).
.NOTES
    Workplace Marketplace — Intune Solutions. Read-only against Graph.
#>
[CmdletBinding()] param()

if (-not (Get-Module -ListAvailable -Name Microsoft.Graph.Authentication)) {
    Install-Module Microsoft.Graph -Scope CurrentUser -Force -AllowClobber
}
Import-Module Microsoft.Graph.Authentication -ErrorAction Stop
Connect-MgGraph -Scopes 'DeviceManagementConfiguration.Read.All','DeviceManagementManagedDevices.Read.All' -NoWelcome

function Get-AssignedGroups($id) {
    try { (Invoke-MgGraphRequest -Method GET -Uri "/beta/deviceManagement/deviceConfigurations/$id/assignments").value |
          ForEach-Object { $_.target.groupId } | Where-Object { $_ } } catch { @() }
}

$cfgs  = (Invoke-MgGraphRequest -Method GET -Uri '/beta/deviceManagement/deviceConfigurations').value
$rings = $cfgs | Where-Object { $_.'@odata.type' -match 'windowsUpdateForBusiness' }
$feat  = $cfgs | Where-Object { $_.'@odata.type' -match 'windowsFeatureUpdate' }

Write-Host "`n=== Update rings (WUfB) ===" -ForegroundColor Cyan
if ($rings) { foreach ($r in $rings) { Write-Host ("  {0}  [groups: {1}]" -f $r.displayName, ((Get-AssignedGroups $r.id) -join ', ')) } }
else { Write-Host "  None found." -ForegroundColor Yellow }

Write-Host "`n=== Feature update policies ===" -ForegroundColor Cyan
if ($feat) { foreach ($f in $feat) { Write-Host ("  {0}  -> {1}  [groups: {2}]" -f $f.displayName, $f.featureUpdateVersion, ((Get-AssignedGroups $f.id) -join ', ')) } }
else { Write-Host "  None found." -ForegroundColor Yellow }

Write-Host "`n=== Managed Windows devices — patch inventory ===" -ForegroundColor Cyan
$devices = (Invoke-MgGraphRequest -Method GET -Uri "/beta/deviceManagement/managedDevices?`$filter=operatingSystem eq 'Windows'&`$select=deviceName,osVersion,operatingSystem,lastSyncDateTime").value
if ($devices) {
    $devices |
        Select-Object @{n='Device';e={$_.deviceName}}, @{n='OS';e={$_.operatingSystem}}, @{n='OSVersion';e={$_.osVersion}}, @{n='LastSync';e={$_.lastSyncDateTime}} |
        Sort-Object Device | Format-Table -AutoSize
    Write-Host ("Total Windows devices    : {0}" -f $devices.Count) -ForegroundColor Green
} else { Write-Host "  No managed Windows devices returned." -ForegroundColor Yellow }

Disconnect-MgGraph | Out-Null
