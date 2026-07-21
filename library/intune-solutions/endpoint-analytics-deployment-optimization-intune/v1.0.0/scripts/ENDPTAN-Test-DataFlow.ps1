<#
.SYNOPSIS
    ENDPTAN-Test-DataFlow.ps1 — confirm pilot devices are submitting Endpoint Analytics data.

.DESCRIPTION
    PURPOSE
        For the pilot device group, confirms (read-only) that the members are managed Windows devices
        checking in recently and, best-effort, appearing in the Endpoint Analytics device-scores data
        — i.e. telemetry is flowing and scores are populating. Lists any pilot device that is NOT yet
        reporting so you know what to chase.

    HOW TO RUN
        Install-Module Microsoft.Graph -Scope CurrentUser   # once
        .\ENDPTAN-Test-DataFlow.ps1
        .\ENDPTAN-Test-DataFlow.ps1 -PilotGroupName 'EPA - Pilot Devices' -RecentDays 3

    GRAPH SCOPES (read-only)
        DeviceManagementConfiguration.Read.All
        DeviceManagementManagedDevices.Read.All
        Group.Read.All

    EXPECTED RESULTS
        A per-device table (managed? syncing recently? appears in analytics scores?) and a summary.
        Devices not yet reporting are called out. Read-only.

    NOTE
        Scores are NOT instant — allow the collection window Microsoft documents before treating a
        non-reporting device as a fault. The device-scores Graph resource is beta and evolves —
        VERIFY against current Microsoft documentation.

.NOTES
    White-label — Intune Solutions. Read-only.
#>
[CmdletBinding()]
param(
    [string]$PilotGroupName = 'EPA – Pilot Devices',
    [int]$RecentDays = 3
)

$ErrorActionPreference = 'Stop'
Connect-MgGraph -Scopes 'DeviceManagementConfiguration.Read.All','DeviceManagementManagedDevices.Read.All','Group.Read.All' | Out-Null

function GraphGet($uri) { (Invoke-MgGraphRequest -Method GET -Uri $uri).value }

# Resolve pilot group members
$grp = GraphGet ("https://graph.microsoft.com/v1.0/groups?`$filter=displayName eq '{0}'" -f $PilotGroupName.Replace("'","''"))
if (-not $grp) { throw "Pilot group '$PilotGroupName' not found — create it (Implementation Step 2)." }
$members = GraphGet "https://graph.microsoft.com/v1.0/groups/$($grp[0].id)/members?`$select=id,displayName"
if (-not $members) { Write-Host "Pilot group '$PilotGroupName' has no members." -ForegroundColor Yellow; return }

# Endpoint Analytics device scores (best-effort; beta resource — VERIFY with MS docs)
$eaDevices = @()
try { $eaDevices = GraphGet 'https://graph.microsoft.com/beta/deviceManagement/userExperienceAnalyticsDeviceScores?$select=id,deviceName' } catch { }

$cut = (Get-Date).AddDays(-$RecentDays)
$rows = foreach ($m in $members) {
    $md = $null
    try {
        $md = (Invoke-MgGraphRequest -Method GET -Uri ("https://graph.microsoft.com/v1.0/deviceManagement/managedDevices?`$filter=azureADDeviceId eq '{0}'&`$select=deviceName,operatingSystem,osVersion,lastSyncDateTime" -f $m.id)).value | Select-Object -First 1
    } catch { }
    if (-not $md) {
        try { $md = (Invoke-MgGraphRequest -Method GET -Uri ("https://graph.microsoft.com/v1.0/deviceManagement/managedDevices?`$filter=deviceName eq '{0}'&`$select=deviceName,operatingSystem,osVersion,lastSyncDateTime" -f $m.displayName.Replace("'","''"))).value | Select-Object -First 1 } catch { }
    }
    $name = if ($md) { $md.deviceName } else { $m.displayName }
    $syncing = $md -and $md.lastSyncDateTime -and ([datetime]$md.lastSyncDateTime -gt $cut)
    $inAnalytics = [bool]($eaDevices | Where-Object { $_.deviceName -eq $name })
    [pscustomobject]@{
        Device       = $name
        Managed      = [bool]$md
        OS           = if ($md) { "$($md.operatingSystem) $($md.osVersion)" } else { '(not managed)' }
        SyncingRecent= $syncing
        InAnalytics  = $inAnalytics
        Reporting    = ($syncing -and ($inAnalytics -or $eaDevices.Count -eq 0))
    }
}

$rows | Format-Table -AutoSize
Write-Host ''
Write-Host ("Pilot members        : {0}" -f $rows.Count)
Write-Host ("Managed              : {0}" -f ($rows | Where-Object Managed).Count)
Write-Host ("Syncing (< $RecentDays d)     : {0}" -f ($rows | Where-Object SyncingRecent).Count)
if ($eaDevices.Count -gt 0) { Write-Host ("Appearing in analytics: {0}" -f ($rows | Where-Object InAnalytics).Count) }
else { Write-Host 'Analytics device-scores not returned via Graph — confirm scores in Reports > Endpoint analytics (VERIFY resource with MS docs).' -ForegroundColor DarkGray }

$notReporting = $rows | Where-Object { -not $_.Reporting }
if ($notReporting) {
    Write-Host ''
    Write-Host 'Pilot devices NOT yet reporting (allow the documented collection window, then see Troubleshooting):' -ForegroundColor Yellow
    $notReporting | Format-Table Device, Managed, SyncingRecent, InAnalytics -AutoSize
}
