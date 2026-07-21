<#
.SYNOPSIS
    ENDPTREL-Test-Signal.ps1 — confirm a known reliability signal is visible and attributable.

.DESCRIPTION
    PURPOSE
        Given the name of an application you know is failing (a seeded/known bad app, or one flagged in
        the Application reliability report), confirms the signal is actually VISIBLE in Endpoint
        Analytics and ATTRIBUTABLE to that app (and its version where exposed). This is the read-only
        check the Testing guide uses to prove a true signal is being detected — and, after a fix, that
        the signal has receded. It changes NOTHING.

    HOW TO RUN
        Install-Module Microsoft.Graph -Scope CurrentUser   # once
        .\ENDPTREL-Test-Signal.ps1 -AppNameLike 'Contoso LOB'
        .\ENDPTREL-Test-Signal.ps1 -AppNameLike 'Contoso LOB' -MinCrashCount 5
        Reads only — makes no changes.

    GRAPH SCOPES
        DeviceManagementManagedDevices.Read.All, DeviceManagementConfiguration.Read.All (read-only).

    EXPECTED RESULTS
        DETECTED with the matched app rows (crash/hang counts, affected devices) when the signal is
        present at or above the threshold; NOT DETECTED when the app is clean, below threshold, or the
        signal has receded after a fix. Use the same command before and after remediation to show the
        loop closed.

    NOTE ON ENDPOINTS
        Reads the userExperienceAnalytics* /beta Graph resources, which change over time and vary by
        cloud. VERIFY AGAINST CURRENT MICROSOFT DOCUMENTATION.

.NOTES
    White-label — Intune Solutions. Read-only. Verify Graph resource paths against current Microsoft docs.
#>
[CmdletBinding()]
param(
    [Parameter(Mandatory)][string]$AppNameLike,
    [int]$MinCrashCount = 1
)

$ErrorActionPreference = 'Stop'
Connect-MgGraph -Scopes 'DeviceManagementManagedDevices.Read.All','DeviceManagementConfiguration.Read.All' | Out-Null

function Get-UxaValue($path) {
    try { return (Invoke-MgGraphRequest -Method GET -Uri "https://graph.microsoft.com/beta/deviceManagement/$path").value }
    catch { return $null }
}

Write-Host "== Test reliability signal for apps like '*$AppNameLike*' (read-only) ==" -ForegroundColor Cyan

$appPerf = Get-UxaValue 'userExperienceAnalyticsAppHealthApplicationPerformance'
if ($null -eq $appPerf) {
    Write-Host 'Application reliability data is unavailable (or the resource path has moved).' -ForegroundColor Yellow
    Write-Host 'Finish the parent Endpoint Analytics solution / verify the Graph path against Microsoft docs.'
    return
}

$matches = $appPerf | Where-Object {
    ($_.appDisplayName -like "*$AppNameLike*" -or $_.appName -like "*$AppNameLike*") -and
    ([int]($_.appCrashCount) -ge $MinCrashCount)
}

if ($matches) {
    Write-Host "DETECTED — the reliability signal is visible and attributable to this app." -ForegroundColor Green
    $matches |
        Sort-Object -Property appCrashCount -Descending |
        Select-Object appDisplayName, appName, appPublisher, appCrashCount, appHangCount, activeDeviceCount |
        Format-Table -AutoSize
    Write-Host 'Interpretation: if one VERSION is bad and others are clean -> bad rollout/version; if all versions crash -> bad app.'
} else {
    Write-Host "NOT DETECTED — no app matching '*$AppNameLike*' is at/above $MinCrashCount crash(es)." -ForegroundColor Yellow
    Write-Host 'This is the expected result AFTER a successful fix, or if the app is clean / the signal was a false lead.'
}
