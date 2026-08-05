<#
.SYNOPSIS
    APPUNIN-Validation.ps1 — per-device uninstall/detection state for a Win32 app, with assignment-conflict detection.
.DESCRIPTION
    PURPOSE
        Reads, from Microsoft Graph, the per-device install state for a Win32 app and
        maps it to the four removal gates (gone / uninstall succeeded / Intune agrees /
        stays gone). With -CheckConflicts it also lists every assignment on the app,
        resolves group membership, and flags any device that is targeted by BOTH an
        install intent (Required/Available) AND an Uninstall intent -- the Branch A
        root cause -- and reports the app's supersedence depth.
    HOW TO RUN
        Read state:
          powershell -ExecutionPolicy Bypass -File .\APPUNIN-Validation.ps1 -AppNameLike "Contoso LOB"
        Detect intent conflicts + supersedence depth:
          powershell -ExecutionPolicy Bypass -File .\APPUNIN-Validation.ps1 -AppNameLike "Contoso LOB" -CheckConflicts
        US Gov: add -GraphEnvironment USGov  (GCC High)  or  -GraphEnvironment USGovDoD (DoD)

        Required Graph scopes: DeviceManagementApps.Read.All, Group.Read.All,
                               DeviceManagementManagedDevices.Read.All
    EXPECTED RESULTS
        A per-device table of installState (notInstalled / uninstallFailed / installed /
        pendingInstall / unknown), installStateDetail, and errorCode. With -CheckConflicts,
        an assignment map and any CONFLICT rows. Pass = target devices show notInstalled
        with no conflict. Fail = uninstallFailed/installed, or a device flagged CONFLICT
        (go to Branch A).
.NOTES
    Intune Solutions — read-only against Microsoft Graph. The repeatable way.
#>

[CmdletBinding()]
param(
    [Parameter(Mandatory)][string] $AppNameLike,
    [switch] $CheckConflicts,
    [ValidateSet('Global','USGov','USGovDoD')][string] $GraphEnvironment = 'Global'
)

$ErrorActionPreference = 'Stop'

function Connect-Graph {
    param([string[]] $Scopes, [string] $Environment)
    if (-not (Get-Module -ListAvailable -Name Microsoft.Graph.Authentication)) {
        throw "Microsoft Graph SDK not found. Run: Install-Module Microsoft.Graph -Scope CurrentUser"
    }
    Import-Module Microsoft.Graph.Authentication -ErrorAction Stop
    if (-not (Get-MgContext)) {
        if ($Environment -eq 'Global') { Connect-MgGraph -Scopes $Scopes | Out-Null }
        else { Connect-MgGraph -Scopes $Scopes -Environment $Environment | Out-Null }
    }
}

# Graph base URL follows the sovereign cloud.
$graphHost = switch ($GraphEnvironment) {
    'USGov'    { 'https://graph.microsoft.us' }
    'USGovDoD' { 'https://dod-graph.microsoft.us' }
    default    { 'https://graph.microsoft.com' }
}
$base = "$graphHost/beta"

function Invoke-GraphGet {
    param([Parameter(Mandatory)][string] $Uri)
    $items = @(); $next = $Uri
    while ($next) {
        $resp = Invoke-MgGraphRequest -Method GET -Uri $next
        if ($resp.value) { $items += $resp.value } elseif ($resp) { $items += $resp }
        $next = $resp.'@odata.nextLink'
    }
    return $items
}

$scopes = @('DeviceManagementApps.Read.All','DeviceManagementManagedDevices.Read.All')
if ($CheckConflicts) { $scopes += 'Group.Read.All' }
Connect-Graph -Scopes $scopes -Environment $GraphEnvironment

$apps = Invoke-GraphGet -Uri "$base/deviceAppManagement/mobileApps?`$top=100" |
        Where-Object { $_.displayName -like "*$AppNameLike*" }
if (-not $apps) { throw "No app found matching '$AppNameLike'." }

foreach ($app in $apps) {
    Write-Host "`n=== $($app.displayName)  [$($app.id)] ===" -ForegroundColor Cyan

    # Per-device state.
    $statuses = Invoke-GraphGet -Uri "$base/deviceAppManagement/mobileApps/$($app.id)/deviceStatuses"
    if ($statuses) {
        $statuses |
            Select-Object deviceName,
                          @{n='installState';e={$_.installState}},
                          @{n='installStateDetail';e={$_.installStateDetail}},
                          @{n='errorCode';e={$_.errorCode}} |
            Sort-Object installState, deviceName |
            Format-Table -AutoSize
    } else {
        Write-Host "  (no per-device status reported yet)" -ForegroundColor Yellow
    }

    if ($CheckConflicts) {
        Write-Host "-- Assignments --" -ForegroundColor Cyan
        $assign = Invoke-GraphGet -Uri "$base/deviceAppManagement/mobileApps/$($app.id)/assignments"
        $installGroups   = @()
        $uninstallGroups = @()
        foreach ($a in $assign) {
            $grp = $a.target.groupId
            "  intent={0,-10} group={1}" -f $a.intent, $grp | Write-Host
            if ($grp) {
                if ($a.intent -in @('required','available','availableWithoutEnrollment')) { $installGroups += $grp }
                elseif ($a.intent -eq 'uninstall') { $uninstallGroups += $grp }
            }
        }

        # Flag groups that appear on BOTH sides (direct overlap), and note nested membership must be checked manually.
        $overlap = $installGroups | Where-Object { $uninstallGroups -contains $_ }
        if ($overlap) {
            Write-Host "  CONFLICT: group(s) targeted by BOTH install and uninstall intent -> Required wins, uninstall is a no-op (Branch A):" -ForegroundColor Red
            $overlap | ForEach-Object { Write-Host "    $_" -ForegroundColor Red }
        }

        # Resolve members of the uninstall groups and check whether any are also transitive members of an install group.
        if ($uninstallGroups -and $installGroups) {
            $installMembers = @{}
            foreach ($g in ($installGroups | Select-Object -Unique)) {
                (Invoke-GraphGet -Uri "$base/groups/$g/transitiveMembers?`$select=id,displayName") |
                    ForEach-Object { if ($_.id) { $installMembers[$_.id] = $_.displayName } }
            }
            foreach ($g in ($uninstallGroups | Select-Object -Unique)) {
                $unMembers = Invoke-GraphGet -Uri "$base/groups/$g/transitiveMembers?`$select=id,displayName"
                foreach ($m in $unMembers) {
                    if ($m.id -and $installMembers.ContainsKey($m.id)) {
                        Write-Host ("  CONFLICT: '{0}' is in an UNINSTALL group AND an INSTALL group -> Branch A" -f $m.displayName) -ForegroundColor Red
                    }
                }
            }
        }
        if (-not $overlap) { Write-Host "  No direct install/uninstall group overlap detected." -ForegroundColor Green }

        # Supersedence depth (chains deeper than one hop stall).
        $rel = Invoke-GraphGet -Uri "$base/deviceAppManagement/mobileApps/$($app.id)/relationships"
        $supersedes = $rel | Where-Object { ($_.'@odata.type') -like '*supersed*' }
        if ($supersedes) {
            Write-Host "-- Supersedence --" -ForegroundColor Cyan
            $supersedes | ForEach-Object { "  {0} -> {1}" -f ($_.'@odata.type' -replace '#microsoft.graph.',''), $_.targetDisplayName | Write-Host }
            Write-Host "  Confirm the chain is a single hop; deeper chains are unsupported and stall (Branch H)." -ForegroundColor Yellow
        }
    }
}
