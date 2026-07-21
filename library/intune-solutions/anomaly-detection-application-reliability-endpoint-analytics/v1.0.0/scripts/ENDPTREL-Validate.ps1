<#
.SYNOPSIS
    ENDPTREL-Validate.ps1 — PASS/FAIL readiness gate for the reliability practice on a pilot scope.

.DESCRIPTION
    PURPOSE
        Confirms the pieces this solution needs are in place for a pilot: reliability signals are
        present for the scoped devices, the pilot group exists, and anomaly detection appears active.
        Emits a PASS/FAIL line per check and an overall verdict — the acceptance gate before you widen
        the reliability review from pilot to fleet. Read-only.

    HOW TO RUN
        Install-Module Microsoft.Graph -Scope CurrentUser   # once
        .\ENDPTREL-Validate.ps1
        .\ENDPTREL-Validate.ps1 -PilotGroupName 'Reliability – Pilot'
        Reads only — makes no changes.

    GRAPH SCOPES
        DeviceManagementManagedDevices.Read.All, DeviceManagementConfiguration.Read.All, Group.Read.All
        (read-only).

    EXPECTED RESULTS
        A PASS/FAIL table and an OVERALL verdict. A READY pilot has application-reliability data,
        device/restart data, the 'Reliability – Pilot' group present, and anomaly detection returning a
        result (anomalies OR an explicit "no anomalies").

    NOTE ON ENDPOINTS
        Anomaly detection availability and its Graph resource path VARY by cloud and over time (may be
        preview). VERIFY AGAINST CURRENT MICROSOFT DOCUMENTATION. A missing anomaly resource is reported
        as a WARNING (not a hard fail) so the app/device-reliability practice can still proceed.

.NOTES
    White-label — Intune Solutions. Read-only. Verify anomaly-detection availability against Microsoft docs.
#>
[CmdletBinding()]
param(
    [string]$PilotGroupName = 'Reliability – Pilot'
)

$ErrorActionPreference = 'Stop'
Connect-MgGraph -Scopes 'DeviceManagementManagedDevices.Read.All','DeviceManagementConfiguration.Read.All','Group.Read.All' | Out-Null

function R($Name, $Pass, $Detail) {
    [pscustomobject]@{ Check = $Name; Result = $(if ($Pass) { 'PASS' } else { 'FAIL' }); Detail = $Detail }
}
function Get-UxaValue($path) {
    try { return (Invoke-MgGraphRequest -Method GET -Uri "https://graph.microsoft.com/beta/deviceManagement/$path").value }
    catch { return $null }
}

$results = @()

# Application reliability data present
$appPerf = Get-UxaValue 'userExperienceAnalyticsAppHealthApplicationPerformance'
$results += R 'Application reliability data present' ([bool]($appPerf -and $appPerf.Count -gt 0)) `
    ($(if ($appPerf) { "$($appPerf.Count) apps reporting" } else { 'No data / path unavailable' }))

# Device reliability / restart data present
$devPerf = Get-UxaValue 'userExperienceAnalyticsAppHealthDevicePerformance'
$results += R 'Device reliability / restart data present' ([bool]($devPerf -and $devPerf.Count -gt 0)) `
    ($(if ($devPerf) { "$($devPerf.Count) devices scored" } else { 'No data / path unavailable' }))

# Pilot group exists
$grp = (Invoke-MgGraphRequest -Method GET -Uri ("https://graph.microsoft.com/v1.0/groups?`$filter=displayName eq '{0}'" -f $PilotGroupName.Replace("'","''"))).value
$results += R "Group '$PilotGroupName' exists" ([bool]$grp) ($(if ($grp) { "id $($grp[0].id)" } else { 'Not found — create it (Implementation Step 2)' }))

# Anomaly detection returning a result (WARN, not FAIL, if unavailable)
$anom = Get-UxaValue 'userExperienceAnalyticsAnomaly'
if ($null -ne $anom) {
    $results += R 'Anomaly detection active' $true "Responding ($($anom.Count) anomaly record(s) — 0 means 'no anomalies', which is healthy)"
} else {
    $results += [pscustomobject]@{ Check = 'Anomaly detection active'; Result = 'WARN'; Detail = 'Unavailable/preview in this tenant — proceed with app/device reliability; verify against Microsoft docs' }
}

$results | Format-Table -AutoSize
$fail = ($results | Where-Object Result -eq 'FAIL').Count
$warn = ($results | Where-Object Result -eq 'WARN').Count
Write-Host ''
if ($fail -eq 0) {
    Write-Host "OVERALL: READY for pilot ($warn warning(s))." -ForegroundColor Green
} else {
    Write-Host "OVERALL: NOT READY — $fail check(s) failed. Resolve before running the reliability review." -ForegroundColor Yellow
}
