<#
.SYNOPSIS
    ENDPTAN-Discovery.ps1 — tenant readiness check for Endpoint Analytics deployment.

.DESCRIPTION
    PURPOSE
        Confirms the building blocks of an Endpoint Analytics rollout exist: an Endpoint Analytics
        data-collection setting/policy is present, the pilot device group exists and is assigned,
        which managed Windows devices are in scope, and (best-effort) which devices are already
        reporting. Reports PASS/NOTE per check with an overall verdict.

    HOW TO RUN
        Install-Module Microsoft.Graph -Scope CurrentUser   # once
        .\ENDPTAN-Discovery.ps1
        .\ENDPTAN-Discovery.ps1 -PilotGroupName 'EPA - Pilot Devices'
        Reads only — makes no changes.

    GRAPH SCOPES (read-only)
        DeviceManagementConfiguration.Read.All
        DeviceManagementManagedDevices.Read.All
        DeviceManagementServiceConfig.Read.All
        Group.Read.All

    EXPECTED RESULTS
        A PASS/FAIL line per check plus an overall verdict. A READY tenant has Endpoint Analytics
        data collection configured, the pilot group present, and managed Windows devices in scope.

    NOTE
        Endpoint Analytics data-collection and score objects evolve; some checks are best-effort and
        fall back to a portal reminder. VERIFY the current Graph resources/paths against Microsoft
        documentation before treating a NOTE as a hard failure.

.NOTES
    White-label — Intune Solutions. Read-only.
#>
[CmdletBinding()]
param(
    [string]$PilotGroupName = 'EPA – Pilot Devices'
)

$ErrorActionPreference = 'Stop'
Connect-MgGraph -Scopes 'DeviceManagementConfiguration.Read.All','DeviceManagementManagedDevices.Read.All','DeviceManagementServiceConfig.Read.All','Group.Read.All' | Out-Null

function R($Name, $Pass, $Detail) {
    [pscustomobject]@{ Check = $Name; Result = $(if ($Pass) { 'PASS' } else { 'FAIL' }); Detail = $Detail }
}
function GraphGet($uri) { (Invoke-MgGraphRequest -Method GET -Uri $uri).value }

$results = @()

# Endpoint Analytics data-collection / settings (best-effort — resource can change; VERIFY with MS docs)
try {
    $ea = GraphGet 'https://graph.microsoft.com/beta/deviceManagement/userExperienceAnalyticsSettings'
    $ok = [bool]$ea
    $results += R 'Endpoint Analytics data collection configured' $ok ($(if ($ok) { 'Settings object present' } else { 'Not found via Graph — confirm in Reports > Endpoint analytics > Settings' }))
} catch {
    $results += R 'Endpoint Analytics data collection configured' $false 'Could not read via Graph — VERIFY in Reports > Endpoint analytics > Settings (resource path changes)'
}

# Pilot device group
$grp = GraphGet ("https://graph.microsoft.com/v1.0/groups?`$filter=displayName eq '{0}'" -f $PilotGroupName.Replace("'","''"))
$results += R "Group '$PilotGroupName'" ([bool]$grp) ($(if ($grp) { "id $($grp[0].id)" } else { 'Not found — create EPA – Pilot Devices (Implementation Step 2)' }))

# Managed Windows devices in scope
try {
    $win = GraphGet "https://graph.microsoft.com/v1.0/deviceManagement/managedDevices?`$filter=operatingSystem eq 'Windows'&`$select=id,deviceName"
    $ok = ($win.Count -ge 1)
    $results += R 'Managed Windows devices present' $ok ("$($win.Count) Windows device(s) managed")
} catch {
    $results += R 'Managed Windows devices present' $false 'Could not enumerate managed devices'
}

$results | Format-Table -AutoSize
$fail = ($results | Where-Object Result -eq 'FAIL').Count
Write-Host ''
if ($fail -eq 0) { Write-Host 'OVERALL: READY — Endpoint Analytics building blocks present.' -ForegroundColor Green }
else { Write-Host "OVERALL: NOT READY — $fail check(s) failed/needs confirming. Resolve before baselining." -ForegroundColor Yellow }
Write-Host 'Reminder: confirm data collection + baseline in Intune > Reports > Endpoint analytics > Settings (VERIFY wording against Microsoft docs).'
