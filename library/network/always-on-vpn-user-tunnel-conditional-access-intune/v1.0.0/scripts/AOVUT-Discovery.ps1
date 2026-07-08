<#
.SYNOPSIS
    AOVUT-Discovery.ps1 — Always On VPN user-tunnel + Conditional Access deployment-readiness discovery across Entra + Intune.
.DESCRIPTION
    PURPOSE
        Read-only readiness sweep for a Windows Always On VPN user-tunnel deployment via Intune with an
        Entra Conditional Access gate. Finds the trusted-root CA profile, the user SCEP certificate
        profile, the user-tunnel VPN profile, the Conditional Access policy that gates access, and the
        pilot/production Entra USER groups, and reports which expected objects are present, named to
        convention, and assigned. Makes NO changes.
    HOW TO RUN
        powershell -ExecutionPolicy Bypass -File .\AOVUT-Discovery.ps1
        Required Microsoft Graph scopes (delegated, read-only):
            DeviceManagementConfiguration.Read.All
            DeviceManagementServiceConfig.Read.All
            Policy.Read.All
            Group.Read.All
            Directory.Read.All
    EXPECTED RESULTS
        A readiness table: each expected profile Found/Missing with assignment state, the Conditional
        Access policy Found/Missing with its state (report-only/on/off), and the pilot group membership
        count. All green = ready to pilot; any Missing = fix before deploying (see 02-requirements.md /
        03-implementation.md).
.NOTES
    White-label — the repeatable way. Read-only against Microsoft Graph. VPN gateway / head-end internals deferred to vendor docs.
#>

[CmdletBinding()]
param(
    [string] $PilotGroupName = 'PILOT – AOVPN User Tunnel Users',
    [string] $ProdGroupName  = 'PROD – AOVPN User Tunnel Users'
)

$ErrorActionPreference = 'Stop'

# Object names this solution creates (match 03-implementation.md verbatim).
$ExpectedProfiles = @(
    'AOVPN – User Tunnel – Trusted Root CA – Windows',
    'AOVPN – User Tunnel – User Cert (SCEP) – Windows',
    'AOVPN – User Tunnel – Profile – Windows'
)
$CaPolicyName = 'CA – AOVPN User Tunnel Access'

function Connect-Graph {
    if (-not (Get-Module Microsoft.Graph.Authentication -ListAvailable)) {
        throw "Microsoft Graph PowerShell SDK not found. Run: Install-Module Microsoft.Graph -Scope CurrentUser"
    }
    Import-Module Microsoft.Graph.Authentication -ErrorAction Stop
    $scopes = @(
        'DeviceManagementConfiguration.Read.All',
        'DeviceManagementServiceConfig.Read.All',
        'Policy.Read.All',
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

Write-Host "`n=== Always On VPN User Tunnel + Conditional Access — Deployment Readiness ===" -ForegroundColor Cyan

# --- Helper: assignment count for a profile ----------------------------------
function Get-AssignmentSummary {
    param([string] $Uri)
    try {
        $a = Invoke-Graph $Uri
        if ($a -and $a.Count -gt 0) { return "$($a.Count) assignment(s)" } else { return "UNASSIGNED" }
    } catch { return "unknown" }
}

# --- Configuration profiles (trusted root + user SCEP + VPN) -----------------
Write-Host "`n[1] Trusted root + user SCEP + VPN configuration profiles" -ForegroundColor Cyan
$allConfigs = Invoke-Graph "$base/deviceManagement/deviceConfigurations?`$select=id,displayName"
$allSettingsCatalog = Invoke-Graph "$base/deviceManagement/configurationPolicies?`$select=id,name"

function Find-Profile {
    param([string] $Name)
    $c = $allConfigs | Where-Object { $_.displayName -eq $Name }
    if ($c) { return @{ Id = $c.id; Kind = 'deviceConfigurations' } }
    $s = $allSettingsCatalog | Where-Object { $_.name -eq $Name }
    if ($s) { return @{ Id = $s.id; Kind = 'configurationPolicies' } }
    return $null
}

$profileRows = foreach ($name in $ExpectedProfiles) {
    $p = Find-Profile -Name $name
    if ($p) {
        $assign = Get-AssignmentSummary "$base/deviceManagement/$($p.Kind)/$($p.Id)/assignments"
        [pscustomobject]@{ Object = $name; State = 'Found'; Assignment = $assign }
    } else {
        [pscustomobject]@{ Object = $name; State = 'MISSING'; Assignment = '-' }
    }
}
$profileRows | Format-Table -AutoSize -Wrap

# --- Conditional Access policy -----------------------------------------------
Write-Host "[2] Conditional Access policy" -ForegroundColor Cyan
$caState = 'MISSING'
$caStatus = '-'
try {
    $enc = [uri]::EscapeDataString($CaPolicyName)
    $ca = Invoke-Graph "$base/identity/conditionalAccess/policies?`$filter=displayName eq '$enc'&`$select=id,displayName,state"
    if ($ca) { $caState = 'Found'; $caStatus = $ca[0].state }
} catch {
    Write-Host "  (could not query Conditional Access — ensure the Policy.Read.All scope is consented)" -ForegroundColor DarkGray
}
[pscustomobject]@{ Object = $CaPolicyName; State = $caState; PolicyState = $caStatus } | Format-Table -AutoSize -Wrap

# --- Groups ------------------------------------------------------------------
Write-Host "[3] Target Entra USER groups" -ForegroundColor Cyan
$groupRows = foreach ($gname in @($PilotGroupName, $ProdGroupName)) {
    $enc = [uri]::EscapeDataString($gname)
    $g = Invoke-Graph "$base/groups?`$filter=displayName eq '$enc'&`$select=id,displayName"
    if ($g) {
        $members = Invoke-Graph "$base/groups/$($g[0].id)/members?`$select=id"
        [pscustomobject]@{ Group = $gname; State = 'Found'; Members = $members.Count }
    } else {
        [pscustomobject]@{ Group = $gname; State = 'MISSING'; Members = 0 }
    }
}
$groupRows | Format-Table -AutoSize

# --- Summary -----------------------------------------------------------------
$missing = @()
$missing += ($profileRows | Where-Object { $_.State -eq 'MISSING' }).Object
if ($caState -eq 'MISSING') { $missing += $CaPolicyName }
$missing += ($groupRows   | Where-Object { $_.State -eq 'MISSING' }).Group

Write-Host "`n=== Summary ===" -ForegroundColor Cyan
if ($missing.Count -eq 0) {
    Write-Host "READY: all expected profiles, the Conditional Access policy, and the user groups are present." -ForegroundColor Green
    if ($caStatus -ne 'enabled') {
        Write-Host "Note: Conditional Access policy state is '$caStatus' — keep it 'reportOnly' for the pilot, then turn it On at Expand." -ForegroundColor DarkGray
    }
} else {
    Write-Host "NOT READY — missing objects:" -ForegroundColor Yellow
    $missing | ForEach-Object { Write-Host "  - $_" -ForegroundColor Yellow }
    Write-Host "See 02-requirements.md / 03-implementation.md to create them." -ForegroundColor Yellow
}
Write-Host "Discovery complete (read-only). No changes were made." -ForegroundColor Green
