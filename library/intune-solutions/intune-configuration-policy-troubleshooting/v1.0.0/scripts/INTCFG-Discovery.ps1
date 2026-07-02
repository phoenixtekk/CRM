<#
.SYNOPSIS
    INTCFG-Discovery.ps1 — list Intune device-configuration policies with their assignments and filters.
.DESCRIPTION
    PURPOSE
        Enumerates Intune settings-catalog / device-configuration policies and, for each, lists the
        Included and Excluded Entra groups and any assignment filter (with its Include/Exclude mode).
        This is the assignment-layer picture the console shows one policy at a time. Read-only.
        Optionally filter by name with -NameLike (for example 'BitLocker').
    HOW TO RUN
        powershell -ExecutionPolicy Bypass -File .\INTCFG-Discovery.ps1
        powershell -ExecutionPolicy Bypass -File .\INTCFG-Discovery.ps1 -NameLike BitLocker
        Requires Microsoft Graph SDK and scopes DeviceManagementConfiguration.Read.All, Group.Read.All.
    EXPECTED RESULTS
        One block per policy: name, platform, Included/Excluded group IDs, and any bound filter + mode.
        "No configuration policies found" if none match.
.NOTES
    White-label — the repeatable way. Read-only against Microsoft Graph.
#>
[CmdletBinding()]
param(
    [string]$NameLike
)

if (-not (Get-Module -ListAvailable -Name Microsoft.Graph.Authentication)) {
    Install-Module Microsoft.Graph -Scope CurrentUser -Force -AllowClobber
}
Import-Module Microsoft.Graph.Authentication -ErrorAction Stop
Connect-MgGraph -Scopes 'DeviceManagementConfiguration.Read.All','Group.Read.All' -NoWelcome

# cache filter id -> "name (mode)" so assignments can be labelled
$filters = @{}
try {
    foreach ($f in (Invoke-MgGraphRequest -Method GET -Uri '/beta/deviceManagement/assignmentFilters').value) {
        $filters[$f.id] = $f.displayName
    }
} catch {}

function Resolve-GroupName([string]$id) {
    if (-not $id) { return $null }
    try { return (Invoke-MgGraphRequest -Method GET -Uri "/v1.0/groups/$id`?`$select=displayName").displayName }
    catch { return $id }
}

Write-Host "`n=== Intune Configuration Policies — Assignments & Filters ===" -ForegroundColor Cyan
$policies = (Invoke-MgGraphRequest -Method GET -Uri '/beta/deviceManagement/configurationPolicies?$expand=assignments').value
$count = 0
foreach ($p in $policies) {
    if ($NameLike -and ($p.name -notmatch [regex]::Escape($NameLike))) { continue }
    $count++
    Write-Host ("`nPOLICY: {0}   [platform: {1}]" -f $p.name, $p.platforms) -ForegroundColor Cyan
    if (-not $p.assignments -or $p.assignments.Count -eq 0) {
        Write-Host "  (no assignments — this policy targets nothing)" -ForegroundColor Yellow
        continue
    }
    foreach ($a in $p.assignments) {
        $t = $a.target
        $kind = switch -Wildcard ($t.'@odata.type') {
            '*exclusionGroupAssignmentTarget' { 'EXCLUDE' }
            '*groupAssignmentTarget'          { 'INCLUDE' }
            '*allDevicesAssignmentTarget'     { 'INCLUDE (All devices)' }
            '*allLicensedUsersAssignmentTarget' { 'INCLUDE (All users)' }
            default { 'INCLUDE' }
        }
        $grp = if ($t.groupId) { "$(Resolve-GroupName $t.groupId) [$($t.groupId)]" } else { '(built-in target)' }
        $flt = ''
        if ($t.deviceAndAppManagementAssignmentFilterId) {
            $fname = $filters[$t.deviceAndAppManagementAssignmentFilterId]
            $fmode = $t.deviceAndAppManagementAssignmentFilterType
            $flt = "  filter: $fname ($fmode)"
        }
        $color = if ($kind -like 'EXCLUDE*') { 'Yellow' } else { 'Green' }
        Write-Host ("  {0,-22} {1}{2}" -f $kind, $grp, $flt) -ForegroundColor $color
    }
}
if ($count -eq 0) { Write-Host "No configuration policies found — check the name filter or your permissions." -ForegroundColor Yellow }
Write-Host ("`nPolicies listed: {0}" -f $count) -ForegroundColor Cyan
Disconnect-MgGraph | Out-Null
