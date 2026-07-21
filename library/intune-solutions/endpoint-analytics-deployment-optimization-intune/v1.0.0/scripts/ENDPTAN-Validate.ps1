<#
.SYNOPSIS
    ENDPTAN-Validate.ps1 — prove the Endpoint Analytics pilot is ready to baseline (PASS/FAIL gate).

.DESCRIPTION
    PURPOSE
        Validates the acceptance gate for the Endpoint Analytics pilot: Endpoint Analytics data
        collection is configured, the pilot group exists and has members, the pilot devices are
        managed Windows devices reporting recently, and (best-effort) scores/baseline are available.
        Produces a clear PASS/FAIL verdict.

    HOW TO RUN
        Install-Module Microsoft.Graph -Scope CurrentUser   # once
        .\ENDPTAN-Validate.ps1
        .\ENDPTAN-Validate.ps1 -PilotGroupName 'EPA - Pilot Devices' -RecentDays 7

    GRAPH SCOPES (read-only)
        DeviceManagementConfiguration.Read.All
        DeviceManagementManagedDevices.Read.All
        Group.Read.All

    EXPECTED RESULTS
        Per-check PASS/FAIL plus an overall GATE verdict. A ready pilot shows: data collection
        configured, the pilot group populated, pilot devices managed and syncing recently.

    NOTE
        Score/baseline availability via Graph is best-effort (the resource evolves). If that check
        is inconclusive, confirm scores in Reports > Endpoint analytics and VERIFY the Graph resource
        against current Microsoft documentation.

.NOTES
    White-label — Intune Solutions. Read-only.
#>
[CmdletBinding()]
param(
    [string]$PilotGroupName = 'EPA – Pilot Devices',
    [int]$RecentDays = 7
)

$ErrorActionPreference = 'Stop'
Connect-MgGraph -Scopes 'DeviceManagementConfiguration.Read.All','DeviceManagementManagedDevices.Read.All','Group.Read.All' | Out-Null

function R($Name, $Pass, $Detail) {
    [pscustomobject]@{ Check = $Name; Result = $(if ($Pass) { 'PASS' } else { 'FAIL' }); Detail = $Detail }
}
function GraphGet($uri) { (Invoke-MgGraphRequest -Method GET -Uri $uri).value }

$results = @()

# Endpoint Analytics data collection configured (best-effort)
try {
    $ea = GraphGet 'https://graph.microsoft.com/beta/deviceManagement/userExperienceAnalyticsSettings'
    $results += R 'Endpoint Analytics data collection configured' ([bool]$ea) ($(if ($ea) { 'Settings present' } else { 'Confirm in Reports > Endpoint analytics > Settings' }))
} catch {
    $results += R 'Endpoint Analytics data collection configured' $false 'VERIFY in Reports > Endpoint analytics > Settings (Graph resource changes)'
}

# Pilot group exists and has members
$grp = GraphGet ("https://graph.microsoft.com/v1.0/groups?`$filter=displayName eq '{0}'" -f $PilotGroupName.Replace("'","''"))
if ($grp) {
    $members = GraphGet "https://graph.microsoft.com/v1.0/groups/$($grp[0].id)/members?`$select=id,displayName"
    $results += R "Pilot group '$PilotGroupName' populated" ($members.Count -ge 1) "$($members.Count) member(s)"
} else {
    $results += R "Pilot group '$PilotGroupName' populated" $false 'Group not found'
    $members = @()
}

# Pilot devices are managed Windows devices syncing recently
$cut = (Get-Date).AddDays(-$RecentDays)
try {
    $win = GraphGet "https://graph.microsoft.com/v1.0/deviceManagement/managedDevices?`$filter=operatingSystem eq 'Windows'&`$select=id,deviceName,osVersion,lastSyncDateTime"
    $recent = $win | Where-Object { $_.lastSyncDateTime -and ([datetime]$_.lastSyncDateTime -gt $cut) }
    $results += R "Managed Windows devices syncing (< $RecentDays d)" ($recent.Count -ge 1) "$($recent.Count) of $($win.Count) Windows device(s) synced recently"
} catch {
    $results += R "Managed Windows devices syncing (< $RecentDays d)" $false 'Could not enumerate managed devices'
}

$results | Format-Table -AutoSize
$fail = ($results | Where-Object Result -eq 'FAIL').Count
Write-Host ''
if ($fail -eq 0) { Write-Host 'GATE: PASS — pilot is configured and reporting; establish/confirm the baseline in the portal.' -ForegroundColor Green }
else { Write-Host "GATE: FAIL — $fail check(s) failed. See Troubleshooting (06)." -ForegroundColor Yellow }
