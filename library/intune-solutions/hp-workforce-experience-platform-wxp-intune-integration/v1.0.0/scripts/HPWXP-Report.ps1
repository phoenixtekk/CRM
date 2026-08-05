<#
.SYNOPSIS
    HPWXP-Report.ps1 — agent-coverage report for HP WXP across Windows devices (installed or not).
.DESCRIPTION
    PURPOSE
        Produces an HP Workforce Experience Platform (WXP) agent-coverage report across managed Windows
        devices: for each device, whether the HP WXP agent Intune app is Installed. Use it to measure
        coverage before widening a rollout and to find Windows devices still missing the WXP agent.
        Read-only. Reports the AGENT-VIA-INTUNE half of the integration only (agent install status per
        device); the tenant-connector half is checked by HPWXP-Discovery.ps1.
    HOW TO RUN
        powershell -ExecutionPolicy Bypass -File .\HPWXP-Report.ps1
        Optional: -AppName "HP WXP Agent - Pilot"  -CsvPath .\HPWXP-coverage.csv
        (Install once: Install-Module Microsoft.Graph -Scope CurrentUser)
        Required Graph scopes: DeviceManagementApps.Read.All, DeviceManagementManagedDevices.Read.All
    EXPECTED RESULTS
        A table (and optional CSV) of Windows devices with an Installed column (Yes/No/Error) plus a
        coverage summary. Full coverage = every intended device shows Installed = Yes.
.NOTES
    White-label — the repeatable way. Read-only against Microsoft Graph.
#>
[CmdletBinding()]
param(
    [string]$AppName = 'HP WXP Agent - Pilot',
    [string]$CsvPath
)

$ErrorActionPreference = 'Stop'
Connect-MgGraph -Scopes 'DeviceManagementApps.Read.All','DeviceManagementManagedDevices.Read.All' | Out-Null

# Locate the HP WXP agent app
$app = $null
try {
    $apps = Invoke-MgGraphRequest -Method GET -Uri "https://graph.microsoft.com/v1.0/deviceAppManagement/mobileApps?`$filter=contains(displayName,'HP WXP')"
    $app = @($apps.value | Where-Object { $_.displayName -eq $AppName } | Select-Object -First 1)
    if (-not $app) { $app = @($apps.value | Where-Object { $_.displayName -match [regex]::Escape($AppName) -or $_.displayName -match 'HP WXP' } | Select-Object -First 1) }
    if ($app -is [array]) { $app = $app[0] }
} catch {}

if (-not $app) { Write-Host "No HP WXP agent app found (looked for '$AppName'). Nothing to report." -ForegroundColor Yellow; return }
$aName = $app.displayName

# Install state per device from the app's deviceStatuses
$installed = @{}
try {
    $stat = Invoke-MgGraphRequest -Method GET -Uri "https://graph.microsoft.com/beta/deviceAppManagement/mobileApps/$($app.id)/deviceStatuses"
    foreach ($s in @($stat.value)) {
        $installed["$($s.deviceName)"] = if ($s.installState -match 'installed') { 'Yes' } elseif ($s.installState -match 'fail|error') { 'Error' } else { 'No' }
    }
} catch {}

# All managed Windows devices
$rows = @()
try {
    $md = Invoke-MgGraphRequest -Method GET -Uri "https://graph.microsoft.com/v1.0/deviceManagement/managedDevices?`$filter=operatingSystem eq 'Windows'"
    foreach ($d in @($md.value)) {
        $rows += [pscustomobject]@{
            Device    = $d.deviceName
            User      = $d.userPrincipalName
            OSVersion = $d.osVersion
            Installed = $(if ($installed.ContainsKey($d.deviceName)) { $installed[$d.deviceName] } else { 'No' })
        }
    }
} catch { Write-Warning "Could not enumerate Windows devices: $($_.Exception.Message)" }

$rows | Sort-Object Installed, Device | Format-Table -AutoSize
if ($CsvPath) { $rows | Sort-Object Installed, Device | Export-Csv -Path $CsvPath -NoTypeInformation; Write-Host "CSV written: $CsvPath" -ForegroundColor Green }

$total = @($rows).Count
$yes   = @($rows | Where-Object Installed -eq 'Yes').Count
Write-Host ''
Write-Host ("Coverage: {0}/{1} Windows device(s) have the HP WXP agent installed (app '{2}')." -f $yes, $total, $aName) -ForegroundColor Cyan
Write-Host "NOTE: 'Installed' here means the Intune app reports installed. Confirm the device is actually reporting telemetry in the HP WXP admin console — the agent must also register with your enrollment code." -ForegroundColor DarkGray
