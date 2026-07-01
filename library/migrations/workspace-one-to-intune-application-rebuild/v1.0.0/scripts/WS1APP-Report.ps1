<#
.SYNOPSIS
    WS1APP-Report.ps1 — rebuild-coverage and deployment-success report from Intune (Microsoft Graph).
.DESCRIPTION
    PURPOSE
        Read-only. For each rebuilt app in Intune, reports the deployment outcome from the app
        installSummary (installed / failed / pending / not-installed counts) so you can see which
        apps have passed and which devices still need attention. Optionally drills into per-device
        results (deviceStatuses) for a single app via -AppId.
    HOW TO RUN
        powershell -ExecutionPolicy Bypass -File .\WS1APP-Report.ps1
        powershell -ExecutionPolicy Bypass -File .\WS1APP-Report.ps1 -AppId <appId> -CsvPath C:\Temp\app-devices.csv
        Requires the Microsoft Graph SDK and DeviceManagementApps.Read.All.
    EXPECTED RESULTS
        A per-app install summary table; with -AppId, a per-device install-status list for that app.
.NOTES
    Workplace Marketplace — Migrations. Read-only against Microsoft Graph.
#>
[CmdletBinding()] param([string]$AppId, [string]$CsvPath)

if (-not (Get-Module -ListAvailable -Name Microsoft.Graph.Authentication)) {
    Install-Module Microsoft.Graph -Scope CurrentUser -Force -AllowClobber
}
Import-Module Microsoft.Graph.Authentication -ErrorAction Stop
Connect-MgGraph -Scopes 'DeviceManagementApps.Read.All' -NoWelcome

if ($AppId) {
    Write-Host "=== Per-device install status for app $AppId ===" -ForegroundColor Cyan
    $rows = @()
    $uri  = "/beta/deviceAppManagement/mobileApps/$AppId/deviceStatuses"
    do {
        $r = Invoke-MgGraphRequest -Method GET -Uri $uri
        $rows += $r.value
        $uri = $r.'@odata.nextLink'
    } while ($uri)
    $report = $rows | ForEach-Object {
        [pscustomobject]@{ Device = $_.deviceName; User = $_.userName; Status = $_.installState; Detail = $_.installStateDetail }
    }
    $report | Sort-Object Status | Format-Table -AutoSize
    if ($CsvPath) { $report | Export-Csv -Path $CsvPath -NoTypeInformation; Write-Host "Saved $CsvPath" }
    Disconnect-MgGraph | Out-Null
    return
}

$apps = @()
$uri  = '/v1.0/deviceAppManagement/mobileApps?$select=id,displayName'
do {
    $r = Invoke-MgGraphRequest -Method GET -Uri $uri
    $apps += $r.value
    $uri = $r.'@odata.nextLink'
} while ($uri)

Write-Host "=== Rebuilt app deployment summary ===" -ForegroundColor Cyan
$summary = foreach ($a in $apps) {
    $s = try { Invoke-MgGraphRequest -Method GET -Uri "/beta/deviceAppManagement/mobileApps/$($a.id)/installSummary" } catch { $null }
    if ($s) {
        [pscustomobject]@{
            App          = $a.displayName
            Installed    = $s.installedDeviceCount
            Failed       = $s.failedDeviceCount
            Pending      = $s.pendingInstallDeviceCount
            NotInstalled = $s.notInstalledDeviceCount
        }
    }
}
$summary | Where-Object { $_ } | Sort-Object Failed -Descending | Format-Table -AutoSize
if ($CsvPath -and $summary) { $summary | Where-Object { $_ } | Export-Csv -Path $CsvPath -NoTypeInformation; Write-Host "Saved $CsvPath" }

Disconnect-MgGraph | Out-Null
