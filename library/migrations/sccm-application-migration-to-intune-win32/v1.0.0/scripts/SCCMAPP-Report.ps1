<#
.SYNOPSIS
    SCCMAPP-Report.ps1 — repackage coverage + Intune Win32 deployment-success report (Microsoft Graph).
.DESCRIPTION
    PURPOSE
        Lists the Intune Win32 (win32LobApp) apps and, for each, pulls the deployment install summary
        (installed / failed / pending / not applicable) so you can see repackage coverage and how the
        migrated apps are actually deploying across the fleet.
    HOW TO RUN
        powershell -ExecutionPolicy Bypass -File .\SCCMAPP-Report.ps1 -CsvPath C:\Temp\sccmapp-report.csv
        Requires the Microsoft Graph SDK and DeviceManagementApps.Read.All.
    EXPECTED RESULTS
        A per-app table of installed/failed/pending counts and a total Win32-app coverage line; an
        optional per-app CSV.
.NOTES
    Phoenixtekk Workplace Marketplace — Migrations. Read-only against Graph.
#>
[CmdletBinding()] param([string]$CsvPath)
if (-not (Get-Module -ListAvailable -Name Microsoft.Graph.Authentication)) { Install-Module Microsoft.Graph -Scope CurrentUser -Force -AllowClobber }
Import-Module Microsoft.Graph.Authentication -ErrorAction Stop
Connect-MgGraph -Scopes 'DeviceManagementApps.Read.All' -NoWelcome

# all Win32 LOB apps
$apps = @(); $uri = "/v1.0/deviceAppManagement/mobileApps?`$filter=isof('microsoft.graph.win32LobApp')"
do { $r = Invoke-MgGraphRequest -Method GET -Uri $uri; $apps += $r.value; $uri = $r.'@odata.nextLink' } while ($uri)

$report = foreach ($a in $apps) {
    $sum = $null
    try { $sum = Invoke-MgGraphRequest -Method GET -Uri "/v1.0/deviceAppManagement/mobileApps/$($a.id)/installSummary" } catch {}
    [pscustomobject]@{
        App           = $a.displayName
        Installed     = [int]$sum.installedDeviceCount
        Failed        = [int]$sum.failedDeviceCount
        Pending       = [int]$sum.pendingInstallDeviceCount
        NotApplicable = [int]$sum.notApplicableDeviceCount
    }
}
Write-Host "`n=== Migrated Win32 app deployment status ===" -ForegroundColor Cyan
$report | Sort-Object Failed -Descending | Format-Table -AutoSize
Write-Host ("Win32 apps (repackage coverage): {0}" -f $apps.Count) -ForegroundColor Cyan
Write-Host ("Apps with failures: {0}" -f (@($report | Where-Object { $_.Failed -gt 0 }).Count)) -ForegroundColor ($(if(@($report | Where-Object { $_.Failed -gt 0 }).Count){'Yellow'}else{'Green'}))
if ($CsvPath) { $report | Export-Csv -Path $CsvPath -NoTypeInformation; Write-Host "Saved $CsvPath" -ForegroundColor Green }
Disconnect-MgGraph | Out-Null
