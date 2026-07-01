<#
.SYNOPSIS
    EHEM-Report.ps1 — fleet Endpoint analytics scores + top issues via Microsoft Graph (read-only).
.DESCRIPTION
    PURPOSE
        Pulls Intune Endpoint analytics (user experience analytics) data with Microsoft Graph: the
        overall/sub-scores, the slowest devices by startup, the least reliable apps, and the busiest
        devices by resource performance — so you can see fleet health and the worst offenders.
    HOW TO RUN
        powershell -ExecutionPolicy Bypass -File .\EHEM-Report.ps1 -CsvPath C:\Temp\ehem.csv
        Requires the Microsoft Graph PowerShell SDK and DeviceManagementManagedDevices.Read.All.
    EXPECTED RESULTS
        The overall Endpoint analytics scores, plus top-N tables for startup, app reliability, and
        resource performance, and an optional per-device CSV. Read-only against Graph.
.NOTES
    Endpoint Health & Digital Experience Monitoring — Infrastructure. Read-only against Graph.
#>
[CmdletBinding()] param([string]$CsvPath, [int]$Top = 10)

if (-not (Get-Module -ListAvailable -Name Microsoft.Graph.Authentication)) {
    Install-Module Microsoft.Graph -Scope CurrentUser -Force -AllowClobber
}
Import-Module Microsoft.Graph.Authentication -ErrorAction Stop
Connect-MgGraph -Scopes 'DeviceManagementManagedDevices.Read.All' -NoWelcome

function Get-All($uri) {
    $items = @()
    do { $r = Invoke-MgGraphRequest -Method GET -Uri $uri; $items += $r.value; $uri = $r.'@odata.nextLink' } while ($uri)
    $items
}

# Overall scores
Write-Host "=== Endpoint analytics — overall scores ===" -ForegroundColor Cyan
try {
    $score = Invoke-MgGraphRequest -Method GET -Uri '/beta/deviceManagement/userExperienceAnalyticsOverview'
    [pscustomobject]@{
        OverallScore   = $score.overallScore
        StartupScore   = $score.deviceStartupScore
        AppReliability = $score.appReliabilityScore
        WorkFromAny    = $score.workFromAnywhereScore
        ResourceScore  = $score.resourcePerformanceScore
    } | Format-List
} catch { Write-Host "  Overview not available (analytics may still be warming up)." -ForegroundColor Yellow }

# Slowest devices by startup
Write-Host "=== Top $Top slowest startups (boot + sign-in, seconds) ===" -ForegroundColor Cyan
$startup = Get-All '/beta/deviceManagement/userExperienceAnalyticsDeviceStartupHistory'
$startup |
    Select-Object @{n='Device';e={$_.deviceId}}, coreBootTimeInMs, coreLoginTimeInMs |
    Sort-Object coreBootTimeInMs -Descending | Select-Object -First $Top | Format-Table -AutoSize

# Least reliable apps
Write-Host "=== Top $Top least reliable apps (by crash count) ===" -ForegroundColor Cyan
$apps = Get-All '/beta/deviceManagement/userExperienceAnalyticsAppHealthApplicationPerformance'
$apps |
    Select-Object appDisplayName, appCrashCount, appHangCount, activeDeviceCount |
    Sort-Object appCrashCount -Descending | Select-Object -First $Top | Format-Table -AutoSize

# Resource performance outliers
Write-Host "=== Top $Top resource-pressure devices (CPU/RAM spike) ===" -ForegroundColor Cyan
$res = Get-All '/beta/deviceManagement/userExperienceAnalyticsResourcePerformance'
$res |
    Select-Object deviceName, deviceResourcePerformanceScore, cpuSpikeTimePercentage, ramSpikeTimePercentage |
    Sort-Object deviceResourcePerformanceScore | Select-Object -First $Top | Format-Table -AutoSize

if ($CsvPath -and $res) { $res | Export-Csv -Path $CsvPath -NoTypeInformation; Write-Host "Saved $CsvPath" }
Disconnect-MgGraph | Out-Null
