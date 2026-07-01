<#
.SYNOPSIS
    TUNMAM-Report.ps1 — Microsoft Tunnel usage + health report (Graph).
.DESCRIPTION
    PURPOSE
        Read-only reporting. Summarizes Microsoft Tunnel sites, servers and their health, and the
        Tunnel (MAM) app-configuration coverage across targeted groups. Optionally exports CSV.
    HOW TO RUN
        powershell -ExecutionPolicy Bypass -File .\TUNMAM-Report.ps1 [-CsvPath .\tunmam-report.csv]
        Requires the Microsoft Graph PowerShell SDK. Consents to read-only scopes.
    EXPECTED RESULTS
        A per-server health table and a MAM-configuration coverage table printed to the console, and
        (if -CsvPath is given) the server table written to CSV. No changes are made.
.NOTES
    Intune Solutions — Microsoft Tunnel for MAM. Read-only against Microsoft Graph.
#>
[CmdletBinding()] param(
    [string]$CsvPath
)

if (-not (Get-Module -ListAvailable -Name Microsoft.Graph.Authentication)) {
    Install-Module Microsoft.Graph -Scope CurrentUser -Force -AllowClobber
}
Import-Module Microsoft.Graph.Authentication -ErrorAction Stop
Connect-MgGraph -Scopes 'DeviceManagementConfiguration.Read.All','DeviceManagementApps.Read.All' -NoWelcome

function Get-Val($uri) { try { (Invoke-MgGraphRequest -Method GET -Uri $uri).value } catch { @() } }

$sites   = Get-Val '/beta/deviceManagement/microsoftTunnelSites'
$servers = Get-Val '/beta/deviceManagement/microsoftTunnelServers'
$appcfg  = Get-Val '/beta/deviceAppManagement/targetedManagedAppConfigurations'

Write-Host "=== Tunnel sites ===" -ForegroundColor Cyan
Write-Host ("  Sites: {0}" -f $sites.Count)

Write-Host "=== Tunnel server health ===" -ForegroundColor Cyan
$rows = foreach ($s in $servers) {
    [pscustomobject]@{
        Server      = $s.displayName
        Health      = $s.tunnelServerHealthStatus
        LastCheckIn = $s.lastCheckinDateTime
    }
}
if ($rows) { $rows | Format-Table -AutoSize } else { Write-Host "  (no servers)" -ForegroundColor Yellow }

$healthy = ($servers | Where-Object { $_.tunnelServerHealthStatus -eq 'healthy' }).Count
Write-Host ("  Healthy servers: {0} / {1}" -f $healthy, $servers.Count) -ForegroundColor Green

Write-Host "=== Tunnel (MAM) configuration coverage ===" -ForegroundColor Cyan
foreach ($a in $appcfg) {
    $grp = @()
    try { $grp = (Invoke-MgGraphRequest -Method GET -Uri "/beta/deviceAppManagement/targetedManagedAppConfigurations/$($a.id)/assignments").value | ForEach-Object { $_.target.groupId } | Where-Object { $_ } } catch {}
    Write-Host ("  {0}  [groups: {1}]" -f $a.displayName, ($grp -join ', '))
}
if (-not $appcfg) { Write-Host "  (none)" -ForegroundColor Yellow }

if ($CsvPath -and $rows) { $rows | Export-Csv -Path $CsvPath -NoTypeInformation; Write-Host ("`nServer report written to {0}" -f $CsvPath) -ForegroundColor Green }

Disconnect-MgGraph | Out-Null
