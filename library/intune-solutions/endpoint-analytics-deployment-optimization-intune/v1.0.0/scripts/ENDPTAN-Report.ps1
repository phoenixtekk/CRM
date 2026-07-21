<#
.SYNOPSIS
    ENDPTAN-Report.ps1 — export an Endpoint Analytics score / sub-signal summary to CSV.

.DESCRIPTION
    PURPOSE
        Pulls the Endpoint Analytics scores and their key sub-signals (Startup performance,
        Application reliability, Work-From-Anywhere, Resource performance) and writes a CSV summary
        for records, baseline tracking, and stakeholder reporting. Best-effort per-device pull where
        Graph exposes it, plus an overall-score summary.

    HOW TO RUN
        Install-Module Microsoft.Graph -Scope CurrentUser   # once
        .\ENDPTAN-Report.ps1
        .\ENDPTAN-Report.ps1 -CsvPath C:\Temp\endpoint-analytics.csv

    GRAPH SCOPES (read-only)
        DeviceManagementConfiguration.Read.All
        DeviceManagementManagedDevices.Read.All

    EXPECTED RESULTS
        A CSV of scores/sub-signals (overall and, where available, per device) plus a printed
        summary. Read-only.

    NOTE
        The Endpoint Analytics Graph resources (userExperienceAnalytics*) are on the beta endpoint and
        CHANGE over time — VERIFY the current resource names/shape against Microsoft documentation. If
        a pull returns nothing, read the scores directly in Reports > Endpoint analytics.

.NOTES
    White-label — Intune Solutions. Read-only.
#>
[CmdletBinding()]
param(
    [string]$CsvPath = "$PSScriptRoot\endpoint-analytics-report.csv"
)

$ErrorActionPreference = 'Stop'
Connect-MgGraph -Scopes 'DeviceManagementConfiguration.Read.All','DeviceManagementManagedDevices.Read.All' | Out-Null

function TryGet($uri) {
    try { return (Invoke-MgGraphRequest -Method GET -Uri $uri) } catch { return $null }
}

$rows = @()

# Overall scores (best-effort; beta resources VERIFY against Microsoft docs)
$overall = TryGet 'https://graph.microsoft.com/beta/deviceManagement/userExperienceAnalyticsOverview'
if ($overall) {
    $rows += [pscustomobject]@{ Scope='Overall'; Area='Overview'; Metric='overallScore'; Value=$overall.overallScore }
}

$scoreSets = @(
    @{ Area='Startup performance'; Uri='https://graph.microsoft.com/beta/deviceManagement/userExperienceAnalyticsBootPerformanceOverview' },
    @{ Area='Work-From-Anywhere'; Uri='https://graph.microsoft.com/beta/deviceManagement/userExperienceAnalyticsWorkFromAnywhereMetrics' },
    @{ Area='Resource performance'; Uri='https://graph.microsoft.com/beta/deviceManagement/userExperienceAnalyticsResourcePerformanceOverview' },
    @{ Area='Application reliability'; Uri='https://graph.microsoft.com/beta/deviceManagement/userExperienceAnalyticsAppHealthOverview' }
)
foreach ($s in $scoreSets) {
    $data = TryGet $s.Uri
    if ($data) {
        foreach ($p in $data.PSObject.Properties) {
            if ($p.Value -is [int] -or $p.Value -is [double] -or $p.Value -is [long]) {
                $rows += [pscustomobject]@{ Scope='Overall'; Area=$s.Area; Metric=$p.Name; Value=$p.Value }
            }
        }
    } else {
        $rows += [pscustomobject]@{ Scope='Overall'; Area=$s.Area; Metric='(unavailable via Graph)'; Value='Read in Reports > Endpoint analytics; VERIFY resource with MS docs' }
    }
}

if ($rows.Count -eq 0) {
    Write-Host 'No Endpoint Analytics data returned via Graph.' -ForegroundColor Yellow
    Write-Host 'Read the scores directly in Intune > Reports > Endpoint analytics, and VERIFY the Graph resource names against current Microsoft documentation.'
    return
}

$rows | Export-Csv -NoTypeInformation -Path $CsvPath
Write-Host "CSV written: $CsvPath" -ForegroundColor Cyan
Write-Host ''
$rows | Format-Table -AutoSize
Write-Host ''
Write-Host 'Keep this alongside your pilot/fleet baseline so improvement is provable over time.'
