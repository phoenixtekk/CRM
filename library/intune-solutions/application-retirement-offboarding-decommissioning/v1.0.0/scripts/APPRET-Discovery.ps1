<#
.SYNOPSIS
    APPRET-Discovery.ps1 — install-base and assignment discovery for an app being retired (read-only).
.DESCRIPTION
    PURPOSE
        Answers "who still has this app, and how is it assigned?" — the starting point of a retirement
        campaign. Reports the Intune app object(s) matching a name, every assignment intent and target
        group, dependency/supersedence links, and the per-device install list (device, primary user,
        last check-in) so you can plan waves and build evidence exhibit A. Strictly read-only.
    HOW TO RUN
        powershell -ExecutionPolicy Bypass -File .\APPRET-Discovery.ps1 -AppName "LegacyTrack Client"
        powershell -ExecutionPolicy Bypass -File .\APPRET-Discovery.ps1 -AppName "LegacyTrack Client" -CsvPath .\install-base.csv
        US Gov: add  -Environment USGov   (GCC High)  or  -Environment USGovDoD  (DoD)
        Requires the Microsoft Graph PowerShell SDK and DeviceManagementApps.Read.All.
    EXPECTED RESULTS
        A per-app summary (intents, target groups, dependencies, supersedence) and an install-state
        summary; with -CsvPath, a per-device CSV of every device that has the app.
.NOTES
    Intune Solutions — read-only. Discovery / planning stage of an application retirement.
#>
[CmdletBinding()]
param(
    [Parameter(Mandatory)][string]$AppName,
    [string]$CsvPath,
    [ValidateSet('Global','USGov','USGovDoD')][string]$Environment = 'Global'
)

if (-not (Get-Module -ListAvailable -Name Microsoft.Graph.Authentication)) {
    Install-Module Microsoft.Graph -Scope CurrentUser -Force -AllowClobber
}
Import-Module Microsoft.Graph.Authentication -ErrorAction Stop
Connect-MgGraph -Scopes 'DeviceManagementApps.Read.All','DeviceManagementManagedDevices.Read.All' -Environment $Environment -NoWelcome

# Find matching apps by display name
$apps = @(); $uri = "/v1.0/deviceAppManagement/mobileApps?`$filter=startswith(displayName,'$AppName')"
do { $r = Invoke-MgGraphRequest -Method GET -Uri $uri; $apps += $r.value; $uri = $r.'@odata.nextLink' } while ($uri)
$apps = $apps | Where-Object { $_.displayName -eq $AppName -or $_.displayName -like "$AppName*" }
if (-not $apps) { Write-Host "No app matching '$AppName' found." -ForegroundColor Yellow; Disconnect-MgGraph | Out-Null; return }

$rows = @()
foreach ($app in $apps) {
    $id = $app.id
    Write-Host ("=== {0}  ({1})" -f $app.displayName, $app.'@odata.type') -ForegroundColor Cyan
    Write-Host ("    Id: {0}   Publisher: {1}" -f $id, $app.publisher)

    # Assignments (intent + target group)
    $asg = (Invoke-MgGraphRequest -Method GET -Uri "/v1.0/deviceAppManagement/mobileApps/$id/assignments").value
    if ($asg) {
        Write-Host "    Assignments:" -ForegroundColor Gray
        foreach ($a in $asg) {
            $gid = $a.target.groupId
            $gname = if ($gid) { (try { (Invoke-MgGraphRequest -Method GET -Uri "/v1.0/groups/$gid").displayName } catch { $gid }) } else { $a.target.'@odata.type' }
            Write-Host ("      intent={0,-11} target={1}" -f $a.intent, $gname)
        }
    } else { Write-Host "    Assignments: (none)" -ForegroundColor DarkYellow }

    # Dependency / supersedence relationships
    try {
        $rel = (Invoke-MgGraphRequest -Method GET -Uri "/v1.0/deviceAppManagement/mobileApps/$id/relationships").value
        foreach ($x in $rel) { Write-Host ("    relationship: {0} -> {1}" -f $x.'@odata.type', $x.targetDisplayName) -ForegroundColor Gray }
    } catch {}

    # Install summary + per-device statuses
    try {
        $sum = Invoke-MgGraphRequest -Method GET -Uri "/v1.0/deviceAppManagement/mobileApps/$id/installSummary"
        Write-Host ("    Install summary — Installed:{0} Failed:{1} NotInstalled:{2} Pending:{3}" -f `
            $sum.installedDeviceCount, $sum.failedDeviceCount, $sum.notInstalledDeviceCount, $sum.pendingInstallDeviceCount) -ForegroundColor Green
    } catch {}

    $duri = "/v1.0/deviceAppManagement/mobileApps/$id/deviceStatuses"
    do {
        $dr = try { Invoke-MgGraphRequest -Method GET -Uri $duri } catch { $null }
        if (-not $dr) { break }
        foreach ($d in $dr.value) {
            $rows += [pscustomobject]@{
                App=$app.displayName; Device=$d.deviceName; User=$d.userName
                InstallState=$d.installState; Detail=$d.installStateDetail; LastSync=$d.lastSyncDateTime
            }
        }
        $duri = $dr.'@odata.nextLink'
    } while ($duri)
}

Write-Host ("`nTotal device records: {0}" -f $rows.Count) -ForegroundColor Cyan
if ($CsvPath -and $rows.Count) { $rows | Export-Csv -Path $CsvPath -NoTypeInformation -Encoding UTF8; Write-Host "Saved $CsvPath" -ForegroundColor Green }
elseif ($rows.Count) { $rows | Select-Object -First 20 | Format-Table -AutoSize }
Disconnect-MgGraph | Out-Null
