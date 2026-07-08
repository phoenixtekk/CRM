<#
.SYNOPSIS
    PLAPDX-Check-Intune.ps1 — confirm the pre-logon VPN Intune objects exist, are assigned, and are correctly scoped.
.DESCRIPTION
    PURPOSE
        Read-only Microsoft Graph audit for a pre-logon VPN deployment. Confirms the expected Intune
        objects are present and assigned — the SBL module Win32 app, the SBL-enabling VPN profile, the
        device-tunnel ProfileXML custom profile, the trusted-root profile, and the SCEP/PKCS cert
        profile — and flags the classic mis-scope: a DEVICE-TUNNEL profile assigned to a USER group
        instead of a DEVICE group (the tunnel connects with no user at boot, so it must target a device
        group). Makes NO changes.
    HOW TO RUN
        powershell -ExecutionPolicy Bypass -File .\PLAPDX-Check-Intune.ps1
        Required Microsoft Graph scopes (delegated, read-only):
            DeviceManagementApps.Read.All
            DeviceManagementConfiguration.Read.All
            Group.Read.All
            Directory.Read.All
    EXPECTED RESULTS
        A table: each expected object Found/Missing with its assignment state, and for the device-tunnel
        profile an OK (device group) / MIS-SCOPED (user group) verdict. All Found + assigned + device
        tunnel on a device group = healthy. Missing/UNASSIGNED/MIS-SCOPED = fix (see 03-implementation.md).
.NOTES
    White-label — the repeatable way. Read-only against Microsoft Graph. VPN head-end / gateway internals deferred to vendor docs.
#>

[CmdletBinding()]
param(
    [string] $PilotGroupName = 'PILOT – Pre-Logon VPN Devices'
)

$ErrorActionPreference = 'Stop'

# Object names this toolkit expects (match 01-solution-overview.md verbatim, incl. the en-dash).
$SblApp            = 'Pre-Logon VPN – SBL Module – Win32'
$SblProfile        = 'Pre-Logon VPN – SBL – Profile'
$DeviceTunnelProfile = 'Pre-Logon VPN – Device Tunnel – Profile'
$TrustedRoot       = 'Pre-Logon VPN – Trusted Root'
$CertProfile       = 'Pre-Logon VPN – Device Cert (SCEP)'

function Connect-Graph {
    if (-not (Get-Module Microsoft.Graph.Authentication -ListAvailable)) {
        throw "Microsoft Graph PowerShell SDK not found. Run: Install-Module Microsoft.Graph -Scope CurrentUser"
    }
    Import-Module Microsoft.Graph.Authentication -ErrorAction Stop
    $scopes = @(
        'DeviceManagementApps.Read.All',
        'DeviceManagementConfiguration.Read.All',
        'Group.Read.All',
        'Directory.Read.All'
    )
    if (-not (Get-MgContext)) { Connect-MgGraph -Scopes $scopes | Out-Null }
    Write-Host "Connected to Microsoft Graph as $((Get-MgContext).Account)" -ForegroundColor Green
}

function Invoke-Graph {
    param([string] $Uri)
    $results = @()
    do {
        $resp = Invoke-MgGraphRequest -Method GET -Uri $Uri
        if ($resp.value) { $results += $resp.value } elseif ($resp) { $results += $resp }
        $Uri = $resp.'@odata.nextLink'
    } while ($Uri)
    return $results
}

Connect-Graph
$base = 'https://graph.microsoft.com/v1.0'

Write-Host "`n=== Pre-Logon VPN — Intune Object & Scope Audit ===" -ForegroundColor Cyan

# --- Resolve profile across deviceConfigurations + configurationPolicies ------
$allConfigs        = Invoke-Graph "$base/deviceManagement/deviceConfigurations?`$select=id,displayName"
$allSettingsCatalog= Invoke-Graph "$base/deviceManagement/configurationPolicies?`$select=id,name"
function Find-Profile {
    param([string] $Name)
    $c = $allConfigs | Where-Object { $_.displayName -eq $Name }
    if ($c) { return @{ Id = $c.id; Kind = 'deviceConfigurations' } }
    $s = $allSettingsCatalog | Where-Object { $_.name -eq $Name }
    if ($s) { return @{ Id = $s.id; Kind = 'configurationPolicies' } }
    return $null
}
function Get-AssignmentTargets {
    param([string] $Uri)
    try { return Invoke-Graph $Uri } catch { return @() }
}

# --- Helper: classify a group's membership as user vs device ------------------
function Get-GroupKind {
    param([string] $GroupId)
    if (-not $GroupId) { return 'unknown' }
    try {
        $members = Invoke-Graph "$base/groups/$GroupId/members?`$select=id&`$top=25"
        $types = $members | ForEach-Object { $_.'@odata.type' }
        if ($types -contains '#microsoft.graph.user')   { return 'user' }
        if ($types -contains '#microsoft.graph.device') { return 'device' }
        return 'empty/unknown'
    } catch { return 'unknown' }
}

$rows = @()

# --- App: SBL module ----------------------------------------------------------
$allApps = Invoke-Graph "$base/deviceAppManagement/mobileApps?`$select=id,displayName"
$app = $allApps | Where-Object { $_.displayName -eq $SblApp }
if ($app) {
    $a = Get-AssignmentTargets "$base/deviceAppManagement/mobileApps/$($app.id)/assignments"
    $rows += [pscustomobject]@{ Object = $SblApp; State = 'Found'; Assignment = $(if ($a.Count) { "$($a.Count) assignment(s)" } else { 'UNASSIGNED' }); Scope = 'n/a' }
} else {
    $rows += [pscustomobject]@{ Object = $SblApp; State = 'MISSING'; Assignment = '-'; Scope = 'n/a' }
}

# --- Profiles -----------------------------------------------------------------
foreach ($name in @($SblProfile, $DeviceTunnelProfile, $TrustedRoot, $CertProfile)) {
    $p = Find-Profile -Name $name
    if (-not $p) {
        $rows += [pscustomobject]@{ Object = $name; State = 'MISSING'; Assignment = '-'; Scope = 'n/a' }
        continue
    }
    $assigns = Get-AssignmentTargets "$base/deviceManagement/$($p.Kind)/$($p.Id)/assignments"
    $assignState = if ($assigns.Count) { "$($assigns.Count) assignment(s)" } else { 'UNASSIGNED' }

    # Scope verdict only matters for the device-tunnel profile.
    $scope = 'n/a'
    if ($name -eq $DeviceTunnelProfile) {
        $scope = 'no group target'
        foreach ($t in $assigns) {
            $gid = $t.target.groupId
            if ($gid) {
                $kind = Get-GroupKind -GroupId $gid
                if ($kind -eq 'user')   { $scope = 'MIS-SCOPED (user group)'; break }
                if ($kind -eq 'device') { $scope = 'OK (device group)' }
                elseif ($scope -eq 'no group target') { $scope = "group kind: $kind" }
            }
        }
    }
    $rows += [pscustomobject]@{ Object = $name; State = 'Found'; Assignment = $assignState; Scope = $scope }
}

$rows | Format-Table Object, State, Assignment, Scope -AutoSize -Wrap

# --- Summary ------------------------------------------------------------------
Write-Host "`n=== Summary ===" -ForegroundColor Cyan
$missing  = @($rows | Where-Object { $_.State -eq 'MISSING' }).Object
$unassign = @($rows | Where-Object { $_.Assignment -eq 'UNASSIGNED' }).Object
$misScope = @($rows | Where-Object { $_.Scope -like 'MIS-SCOPED*' }).Object

if ($missing.Count)  { Write-Host "MISSING objects:";    $missing  | ForEach-Object { Write-Host "  - $_" -ForegroundColor Yellow } }
if ($unassign.Count) { Write-Host "UNASSIGNED objects:"; $unassign | ForEach-Object { Write-Host "  - $_" -ForegroundColor Yellow } }
if ($misScope.Count) {
    Write-Host "MIS-SCOPED (fix now):" -ForegroundColor Red
    $misScope | ForEach-Object { Write-Host "  - $_ is on a USER group; re-assign to a DEVICE group (e.g. $PilotGroupName)." -ForegroundColor Red }
}
if (-not $missing.Count -and -not $unassign.Count -and -not $misScope.Count) {
    Write-Host "OK: all expected objects are present, assigned, and the device-tunnel profile targets a device group." -ForegroundColor Green
}
Write-Host "Audit complete (read-only). No changes were made." -ForegroundColor Green
