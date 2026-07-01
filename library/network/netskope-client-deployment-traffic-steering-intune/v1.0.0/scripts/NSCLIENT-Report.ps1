<#
.SYNOPSIS
    NSCLIENT-Report.ps1 — fleet-wide deployment status for the Netskope client app + cert coverage (Graph).
.DESCRIPTION
    PURPOSE
        Read-only. Reports, via Microsoft Graph, the Intune deployment status of the Netskope client
        app across managed Windows devices (installed / failed / pending / not applicable), so you can
        see per-ring coverage and chase failures. Optionally writes a per-device CSV.
    HOW TO RUN
        powershell -ExecutionPolicy Bypass -File .\NSCLIENT-Report.ps1 -AppName "Netskope Client - Windows - Production" -CsvPath C:\Temp\nsclient.csv
        Requires the Microsoft Graph PowerShell SDK and DeviceManagementApps.Read.All.
    EXPECTED RESULTS
        A status breakdown (installed/failed/pending/...) for the named app and an optional per-device CSV.
.NOTES
    Network Solutions — read-only against Microsoft Graph. Certificate-profile coverage is reported
    separately in the Intune portal; this script focuses on the client app deployment state. Steering
    state is device-side / Netskope-side and is validated by NSCLIENT-Validation.ps1 (DEFERRED to docs).
#>
[CmdletBinding()]
param(
    [string]$AppName = 'Netskope Client - Windows - Production',
    [string]$CsvPath
)

if (-not (Get-Module -ListAvailable -Name Microsoft.Graph.Authentication)) {
    Install-Module Microsoft.Graph -Scope CurrentUser -Force -AllowClobber
}
Import-Module Microsoft.Graph.Authentication -ErrorAction Stop
Connect-MgGraph -Scopes 'DeviceManagementApps.Read.All' -NoWelcome

# Find the app by display name (mobileApps), then read its per-device install status report.
$appsUri = "/beta/deviceAppManagement/mobileApps?`$filter=isof('microsoft.graph.win32LobApp')"
$apps = @()
do { $r = Invoke-MgGraphRequest -Method GET -Uri $appsUri; $apps += $r.value; $appsUri = $r.'@odata.nextLink' } while ($appsUri)
$app = $apps | Where-Object { $_.displayName -eq $AppName } | Select-Object -First 1

if (-not $app) {
    Write-Host ("App not found: {0}" -f $AppName) -ForegroundColor Yellow
    Write-Host "Confirm the app display name matches the Intune app exactly." -ForegroundColor Yellow
    Disconnect-MgGraph | Out-Null
    exit 1
}

$statusUri = "/beta/deviceAppManagement/mobileApps/$($app.id)/deviceStatuses"
$rows = @()
do { $r = Invoke-MgGraphRequest -Method GET -Uri $statusUri; $rows += $r.value; $statusUri = $r.'@odata.nextLink' } while ($statusUri)

$report = $rows | ForEach-Object {
    [pscustomobject]@{
        Device      = $_.deviceName
        InstallState= $_.installState
        User        = $_.userPrincipalName
        LastModified= $_.lastModifiedDateTime
    }
}

Write-Host ("=== {0} — install status ===" -f $AppName) -ForegroundColor Cyan
$report | Group-Object InstallState | Sort-Object Count -Descending |
    Select-Object Count, @{n='InstallState';e={$_.Name}} | Format-Table -AutoSize
Write-Host ("Devices reporting: {0}" -f $report.Count) -ForegroundColor Cyan

if ($CsvPath) { $report | Export-Csv -Path $CsvPath -NoTypeInformation; Write-Host "Saved $CsvPath" }

Disconnect-MgGraph | Out-Null
