<#
.SYNOPSIS
    CVPNMIG-Report.ps1 — fleet migration-progress / coexistence report (legacy vs Intune-managed).
.DESCRIPTION
    PURPOSE
        Reads the Intune-side delivery status via Microsoft Graph to show how far the Cisco VPN
        migration has progressed: how many devices have the Intune-delivered Secure Client app, VPN
        profile, and certificate installed, versus how many are still pending — the coexistence view
        across waves. Use it each cutover cycle to track the legacy-to-Intune shift and chase laggards.
    HOW TO RUN
        powershell -ExecutionPolicy Bypass -File .\CVPNMIG-Report.ps1
        powershell -ExecutionPolicy Bypass -File .\CVPNMIG-Report.ps1 -AppNameMatch 'Cisco Secure Client' -CsvPath C:\Temp\cvpnmig-report.csv
        Requires the Microsoft Graph SDK and scopes:
        DeviceManagementApps.Read.All, DeviceManagementConfiguration.Read.All

    EXPECTED RESULTS
        A table of installed / failed / pending / not-applicable counts for the Intune client app and
        the VPN + certificate profiles, plus an overall Intune-managed vs pending summary. An optional
        CSV. A rising installed count each cycle means the migration is progressing.
.NOTES
    White-label — the repeatable way. Read-only against Microsoft Graph for reads. Cisco internals deferred to vendor docs.
#>
[CmdletBinding()] param(
    [string]$AppNameMatch = 'Cisco|Secure Client|AnyConnect',
    [string]$ProfileNameMatch = 'VPN|Cisco|Cert|Trusted|SCEP|PKCS',
    [string]$CsvPath
)
if (-not (Get-Module -ListAvailable -Name Microsoft.Graph.Authentication)) { Install-Module Microsoft.Graph -Scope CurrentUser -Force -AllowClobber }
Import-Module Microsoft.Graph.Authentication -ErrorAction Stop
Connect-MgGraph -Scopes 'DeviceManagementApps.Read.All','DeviceManagementConfiguration.Read.All' -NoWelcome

$report = @()

# --- 1. Win32 client app install summary ---
$apps = @(); $uri = "/v1.0/deviceAppManagement/mobileApps?`$filter=isof('microsoft.graph.win32LobApp')"
do { $r = Invoke-MgGraphRequest -Method GET -Uri $uri; $apps += $r.value; $uri = $r.'@odata.nextLink' } while ($uri)
foreach ($a in ($apps | Where-Object { $_.displayName -match $AppNameMatch })) {
    $sum = $null
    try { $sum = Invoke-MgGraphRequest -Method GET -Uri "/v1.0/deviceAppManagement/mobileApps/$($a.id)/installSummary" } catch {}
    $report += [pscustomobject]@{
        Object='Win32 app'; Name=$a.displayName
        Installed=[int]$sum.installedDeviceCount; Failed=[int]$sum.failedDeviceCount
        Pending=[int]$sum.pendingInstallDeviceCount; NotApplicable=[int]$sum.notApplicableDeviceCount
    }
}

# --- 2. VPN + certificate configuration-profile status ---
$cfg = @(); $uri = '/v1.0/deviceManagement/deviceConfigurations'
do { $r = Invoke-MgGraphRequest -Method GET -Uri $uri; $cfg += $r.value; $uri = $r.'@odata.nextLink' } while ($uri)
foreach ($c in ($cfg | Where-Object { $_.displayName -match $ProfileNameMatch })) {
    $st = $null
    try { $st = Invoke-MgGraphRequest -Method GET -Uri "/v1.0/deviceManagement/deviceConfigurations/$($c.id)/deviceStatusOverview" } catch {}
    $report += [pscustomobject]@{
        Object=$c.'@odata.type'.Split('.')[-1]; Name=$c.displayName
        Installed=[int]$st.successCount; Failed=([int]$st.errorCount + [int]$st.failedCount)
        Pending=[int]$st.pendingCount; NotApplicable=[int]$st.notApplicableCount
    }
}

Write-Host "`n=== Cisco VPN migration — Intune delivery status ===" -ForegroundColor Cyan
if ($report) { $report | Sort-Object Failed -Descending | Format-Table Object, Name, Installed, Failed, Pending, NotApplicable -AutoSize }
else { Write-Host '  No matching Intune objects found — build them per the Implementation Guide, or adjust -AppNameMatch / -ProfileNameMatch.' -ForegroundColor Yellow }

$totalInstalled = ($report | Measure-Object Installed -Sum).Sum
$totalPending   = ($report | Measure-Object Pending   -Sum).Sum
$totalFailed    = ($report | Measure-Object Failed     -Sum).Sum
Write-Host ("Intune-managed (installed) delivery events: {0}   Pending: {1}   Failed: {2}" -f $totalInstalled, $totalPending, $totalFailed) -ForegroundColor Cyan
Write-Host ("Objects with failures: {0}" -f (@($report | Where-Object { $_.Failed -gt 0 }).Count)) -ForegroundColor $(if (@($report | Where-Object { $_.Failed -gt 0 }).Count) { 'Yellow' } else { 'Green' })
Write-Host "Note: devices still counted under the legacy SCCM deployment / GPO scope are NOT yet migrated — reconcile against the SCCM collection and GPO scope." -ForegroundColor Gray

if ($CsvPath) { $report | Export-Csv -Path $CsvPath -NoTypeInformation; Write-Host "Saved $CsvPath" -ForegroundColor Green }
Disconnect-MgGraph | Out-Null
