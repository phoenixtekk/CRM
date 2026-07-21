<#
.SYNOPSIS
    ENDPTREL-Report.ps1 — export an application + device reliability + anomaly summary to CSV.

.DESCRIPTION
    PURPOSE
        Produces the monthly reliability record the review cadence keeps: one CSV combining the top
        unreliable applications (crash/hang by app/version), the least-reliable devices, and any active
        anomalies. This is the 'Reliability Review – <YYYY-MM>.csv' artifact referenced throughout the
        Implementation and Best Practices guides. Read-only — it only reads and writes a local CSV.

    HOW TO RUN
        Install-Module Microsoft.Graph -Scope CurrentUser   # once
        .\ENDPTREL-Report.ps1
        .\ENDPTREL-Report.ps1 -Top 25 -OutDir 'C:\Reliability'
        Reads Graph and writes a local CSV — makes no tenant changes.

    GRAPH SCOPES
        DeviceManagementManagedDevices.Read.All, DeviceManagementConfiguration.Read.All (read-only).

    EXPECTED RESULTS
        A CSV named 'Reliability Review – <YYYY-MM>.csv' in the output directory with rows tagged by
        section (Application / Device / Anomaly), plus a console summary. Keep the monthly files to
        trend corrections-per-review over time (a downward trend means the practice is working).

    NOTE ON ENDPOINTS
        Reliability + anomaly data comes from the userExperienceAnalytics* /beta Graph resources, which
        change over time and vary by cloud. VERIFY AGAINST CURRENT MICROSOFT DOCUMENTATION. Sections
        with no data are written as a single 'no data' row rather than failing.

.NOTES
    White-label — Intune Solutions. Read-only export. Verify Graph resource paths against current Microsoft docs.
#>
[CmdletBinding()]
param(
    [int]$Top = 20,
    [string]$OutDir = '.'
)

$ErrorActionPreference = 'Stop'
Connect-MgGraph -Scopes 'DeviceManagementManagedDevices.Read.All','DeviceManagementConfiguration.Read.All' | Out-Null

function Get-UxaValue($path) {
    try { return (Invoke-MgGraphRequest -Method GET -Uri "https://graph.microsoft.com/beta/deviceManagement/$path").value }
    catch { return $null }
}

$rows = New-Object System.Collections.Generic.List[object]

# --- Application reliability ---
$appPerf = Get-UxaValue 'userExperienceAnalyticsAppHealthApplicationPerformance'
if ($appPerf -and $appPerf.Count -gt 0) {
    $appPerf | Sort-Object -Property appCrashCount -Descending | Select-Object -First $Top | ForEach-Object {
        $rows.Add([pscustomobject]@{
            Section = 'Application'; Name = $_.appDisplayName; Detail = $_.appPublisher
            Version = $_.appName; CrashCount = $_.appCrashCount; HangCount = $_.appHangCount
            AffectedDevices = $_.activeDeviceCount; MeanTimeToFailureMin = ''
        })
    }
} else {
    $rows.Add([pscustomobject]@{ Section='Application'; Name='(no data)'; Detail='Verify parent Endpoint Analytics data collection'; Version='';CrashCount='';HangCount='';AffectedDevices='';MeanTimeToFailureMin='' })
}

# --- Device reliability / restart ---
$devPerf = Get-UxaValue 'userExperienceAnalyticsAppHealthDevicePerformance'
if ($devPerf -and $devPerf.Count -gt 0) {
    $devPerf | Sort-Object -Property appCrashCount -Descending | Select-Object -First $Top | ForEach-Object {
        $rows.Add([pscustomobject]@{
            Section = 'Device'; Name = $_.deviceDisplayName; Detail = $_.deviceModel
            Version = ''; CrashCount = $_.appCrashCount; HangCount = $_.appHangCount
            AffectedDevices = ''; MeanTimeToFailureMin = $_.meanTimeToFailureInMinutes
        })
    }
} else {
    $rows.Add([pscustomobject]@{ Section='Device'; Name='(no data)'; Detail='';Version='';CrashCount='';HangCount='';AffectedDevices='';MeanTimeToFailureMin='' })
}

# --- Anomalies ---
$anom = Get-UxaValue 'userExperienceAnalyticsAnomaly'
if ($anom -and $anom.Count -gt 0) {
    $anom | ForEach-Object {
        $rows.Add([pscustomobject]@{
            Section = 'Anomaly'; Name = $_.anomalyId; Detail = $_.anomalyType
            Version = $_.state; CrashCount = ''; HangCount = ''
            AffectedDevices = $_.deviceImpactedCount; MeanTimeToFailureMin = ''
        })
    }
} else {
    $rows.Add([pscustomobject]@{ Section='Anomaly'; Name='(none or unavailable)'; Detail='0 anomalies is healthy; anomaly detection may be preview/unavailable — verify against Microsoft docs'; Version='';CrashCount='';HangCount='';AffectedDevices='';MeanTimeToFailureMin='' })
}

if (-not (Test-Path $OutDir)) { New-Item -ItemType Directory -Path $OutDir -Force | Out-Null }
$stamp = Get-Date -Format 'yyyy-MM'
$outFile = Join-Path $OutDir ("Reliability Review – {0}.csv" -f $stamp)
$rows | Export-Csv -Path $outFile -NoTypeInformation -Encoding UTF8

Write-Host "Wrote $($rows.Count) rows to: $outFile" -ForegroundColor Green
$rows | Group-Object Section | ForEach-Object { Write-Host ("  {0}: {1} row(s)" -f $_.Name, $_.Count) }
Write-Host 'Keep the monthly file as the trend record for the reliability review cadence.'
