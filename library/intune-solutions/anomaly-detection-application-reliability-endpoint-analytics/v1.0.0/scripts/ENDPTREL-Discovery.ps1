<#
.SYNOPSIS
    ENDPTREL-Discovery.ps1 — read-only discovery of Endpoint Analytics reliability data.

.DESCRIPTION
    PURPOSE
        Confirms the reliability side of Endpoint Analytics is producing data this solution can act on:
        that application-reliability and device/restart signals are present, reports the scoped device
        count, and lists the top unreliable apps and devices it can see. This is the "is the data
        flowing?" check that Phase 1 of the Implementation guide calls for. It changes NOTHING.

    HOW TO RUN
        Install-Module Microsoft.Graph -Scope CurrentUser   # once
        .\ENDPTREL-Discovery.ps1
        .\ENDPTREL-Discovery.ps1 -Top 15
        Reads only — makes no changes.

    GRAPH SCOPES
        DeviceManagementManagedDevices.Read.All, DeviceManagementConfiguration.Read.All
        (read-only). Connect-MgGraph will prompt for consent on first run.

    EXPECTED RESULTS
        A short readiness summary: whether application-reliability and device-reliability signals are
        returning data, the scoped device count, and the top-N unreliable apps/devices. If a signal is
        empty, finish the PARENT solution (enable Endpoint Analytics + data collection) and let the
        reporting window fill before triaging.

    NOTE ON ENDPOINTS
        Endpoint Analytics reliability data is exposed under the userExperienceAnalytics* Graph
        resources, which live on the /beta endpoint and CHANGE over time. Exact resource paths and
        availability — VERIFY AGAINST CURRENT MICROSOFT DOCUMENTATION. The script fails soft (reports
        "unavailable") rather than erroring if a path has moved.

.NOTES
    White-label — Intune Solutions. Read-only. Verify Graph resource paths against current Microsoft docs.
#>
[CmdletBinding()]
param(
    [int]$Top = 10
)

$ErrorActionPreference = 'Stop'
Connect-MgGraph -Scopes 'DeviceManagementManagedDevices.Read.All','DeviceManagementConfiguration.Read.All' | Out-Null

function Get-UxaValue($path) {
    # Fail-soft GET against a /beta userExperienceAnalytics* resource; returns $null if unavailable.
    try { return (Invoke-MgGraphRequest -Method GET -Uri "https://graph.microsoft.com/beta/deviceManagement/$path").value }
    catch { return $null }
}

Write-Host '== Endpoint Analytics reliability — discovery (read-only) ==' -ForegroundColor Cyan
Write-Host '(Reliability data comes from the userExperienceAnalytics* Graph resources — verify paths against current Microsoft documentation.)'
Write-Host ''

# --- Application reliability (app health) ---
$appPerf = Get-UxaValue 'userExperienceAnalyticsAppHealthApplicationPerformance'
if ($null -ne $appPerf -and $appPerf.Count -gt 0) {
    Write-Host "Application reliability: DATA PRESENT ($($appPerf.Count) apps reporting)." -ForegroundColor Green
    $appPerf |
        Sort-Object -Property appCrashCount -Descending |
        Select-Object -First $Top appDisplayName, appName, appPublisher, appCrashCount, appHangCount, activeDeviceCount |
        Format-Table -AutoSize
} else {
    Write-Host 'Application reliability: NO DATA (or resource path unavailable).' -ForegroundColor Yellow
    Write-Host '  -> Finish the PARENT Endpoint Analytics solution and allow the reporting window to fill.'
}
Write-Host ''

# --- Device reliability / restart analytics (device performance side of app health) ---
$devPerf = Get-UxaValue 'userExperienceAnalyticsAppHealthDevicePerformance'
if ($null -ne $devPerf -and $devPerf.Count -gt 0) {
    Write-Host "Device reliability signal: DATA PRESENT ($($devPerf.Count) devices scored)." -ForegroundColor Green
    $devPerf |
        Sort-Object -Property appCrashCount -Descending |
        Select-Object -First $Top deviceDisplayName, deviceModel, appCrashCount, appHangCount, meanTimeToFailureInMinutes |
        Format-Table -AutoSize
} else {
    Write-Host 'Device reliability signal: NO DATA (or resource path unavailable).' -ForegroundColor Yellow
}
Write-Host ''

# --- Scoped device count (from Endpoint Analytics device scores where available) ---
$scores = Get-UxaValue 'userExperienceAnalyticsDeviceScores'
$scopedCount = if ($null -ne $scores) { $scores.Count } else { 0 }
Write-Host "Scoped devices reporting Endpoint Analytics scores: $scopedCount"
if ($scopedCount -lt 1) {
    Write-Host '  -> Too few devices to triage reliably. Broaden data collection (parent solution) and let it populate.' -ForegroundColor Yellow
}
Write-Host ''
Write-Host 'Reminder: this is a read-only snapshot. Read the Application reliability and device/restart reports in the'
Write-Host 'Intune admin center > Endpoint analytics for the authoritative, current view (verify navigation against Microsoft docs).'
