<#
.SYNOPSIS
    WIFIMGT-Validate-Assignment.ps1 — report which groups/devices received the named Wi-Fi profiles (read-only, cloud-aware).
.DESCRIPTION
    PURPOSE
        For each named Wi-Fi profile, confirms it exists in Intune and lists the groups it is assigned
        to (and the member count of each group), so you can prove the pilot/production targeting is
        correct before and after expansion. Read-only.
    HOW TO RUN
        powershell -ExecutionPolicy Bypass -File .\WIFIMGT-Validate-Assignment.ps1
        Named profiles:  .\WIFIMGT-Validate-Assignment.ps1 -ProfileNames 'WIFIMGT - Corp WiFi - Windows - Pilot','WIFIMGT - Corp WiFi - iOS - Pilot'
        Sovereign cloud: .\WIFIMGT-Validate-Assignment.ps1 -Environment USGov      (or USGovDoD)
        Required Graph scopes: DeviceManagementConfiguration.Read.All, Group.Read.All
    EXPECTED RESULTS
        Per profile: FOUND/MISSING, the assigned group name(s), and each group's member count.
        A profile with no assignment is flagged UNASSIGNED.
.NOTES
    White-label — Intune Solutions. Read-only against Microsoft Graph.
#>
[CmdletBinding()]
param(
    [ValidateSet('Global','USGov','USGovDoD')]
    [string] $Environment = 'Global',
    [string[]] $ProfileNames = @(
        'WIFIMGT - Corp WiFi - Windows - Pilot',
        'WIFIMGT - Corp WiFi - iOS - Pilot',
        'WIFIMGT - Corp WiFi - Android - Pilot'
    )
)

$ErrorActionPreference = 'Stop'

if (-not (Get-Module -ListAvailable -Name Microsoft.Graph.Authentication)) {
    throw "Microsoft.Graph SDK not installed. Run: Install-Module Microsoft.Graph -Scope CurrentUser"
}
Import-Module Microsoft.Graph.Authentication -ErrorAction Stop
Connect-MgGraph -Environment $Environment -Scopes 'DeviceManagementConfiguration.Read.All','Group.Read.All' -NoWelcome
Write-Host "Connected to Graph ($Environment) tenant: $((Get-MgContext).TenantId)" -ForegroundColor Cyan

function Get-All($uri) {
    $out = @(); $next = $uri
    while ($next) {
        $resp = Invoke-MgGraphRequest -Method GET -Uri $next
        if ($resp.value) { $out += $resp.value } elseif ($resp) { $out += $resp }
        $next = $resp.'@odata.nextLink'
    }
    return $out
}
function Group-Info($id) {
    try {
        $g = Invoke-MgGraphRequest -Method GET -Uri "/v1.0/groups/$id`?`$select=displayName"
        $c = Invoke-MgGraphRequest -Method GET -Uri "/v1.0/groups/$id/members/`$count" -Headers @{ ConsistencyLevel = 'eventual' }
        return [pscustomobject]@{ Name = $g.displayName; Count = $c }
    } catch { return [pscustomobject]@{ Name = $id; Count = '?' } }
}

$allDc = Get-All "/beta/deviceManagement/deviceConfigurations?`$select=id,displayName"

foreach ($name in $ProfileNames) {
    Write-Host "`n=== $name ===" -ForegroundColor Yellow
    $p = $allDc | Where-Object { $_.displayName -eq $name }
    if (-not $p) {
        Write-Host "  [MISSING] profile not found in Intune." -ForegroundColor Red
        continue
    }
    Write-Host "  [FOUND] id $($p[0].id)" -ForegroundColor Green
    $asg = Get-All "/beta/deviceManagement/deviceConfigurations/$($p[0].id)/assignments"
    if (-not $asg) { Write-Host "  [UNASSIGNED] no groups assigned." -ForegroundColor Red; continue }
    foreach ($a in $asg) {
        if ($a.target.groupId) {
            $gi = Group-Info $a.target.groupId
            Write-Host ("  -> {0}  (members: {1})" -f $gi.Name, $gi.Count) -ForegroundColor Cyan
        } else {
            Write-Host ("  -> target: {0}" -f ($a.target.'@odata.type' -replace '#microsoft.graph.','')) -ForegroundColor Cyan
        }
    }
}

Write-Host "`nDone." -ForegroundColor Cyan
Disconnect-MgGraph | Out-Null
