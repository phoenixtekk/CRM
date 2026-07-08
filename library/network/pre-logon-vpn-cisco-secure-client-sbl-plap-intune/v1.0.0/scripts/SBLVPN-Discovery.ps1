<#
.SYNOPSIS
    SBLVPN-Discovery.ps1 — Pre-Logon VPN (Cisco Secure Client SBL/PLAP) deployment-readiness discovery across Entra + Intune.
.DESCRIPTION
    PURPOSE
        Read-only readiness sweep for a Cisco Secure Client Start Before Logon (SBL/PLAP) pre-logon
        VPN deployment via Intune. Finds the Win32 app that installs the Core + Start Before Logon
        modules, the Windows VPN device-configuration profile, the Trusted Root CA profile and the
        SCEP device-certificate profile, and the pilot/production Entra groups, and reports which
        expected objects are present, named to convention, and assigned. Makes NO changes.
    HOW TO RUN
        powershell -ExecutionPolicy Bypass -File .\SBLVPN-Discovery.ps1
        Required Microsoft Graph scopes (delegated, read-only):
            DeviceManagementApps.Read.All
            DeviceManagementConfiguration.Read.All
            DeviceManagementServiceConfig.Read.All
            Group.Read.All
            Directory.Read.All
    EXPECTED RESULTS
        A readiness table: the Win32 app, the Windows VPN profile, the trusted-root and SCEP
        device-cert profiles each Found/Missing with assignment state, and the pilot group membership
        count. All green = ready to pilot; any Missing/unassigned = fix before deploying (see
        02-requirements.md / 03-implementation.md).
.NOTES
    White-label — the repeatable way. Read-only against Microsoft Graph. Cisco-specific internals deferred to vendor docs.
#>

[CmdletBinding()]
param(
    [string] $PilotGroupName = 'PILOT – Pre-Logon VPN (SBL) Users',
    [string] $ProdGroupName  = 'PROD – Pre-Logon VPN (SBL) Users'
)

$ErrorActionPreference = 'Stop'

# Object names this solution creates (match 03-implementation.md verbatim).
$ExpectedApps = @(
    'Cisco Secure Client – Pre-Logon (SBL) – Win32'
)
$ExpectedProfiles = @(
    'Cisco Secure Client – Pre-Logon (SBL) – Profile – Windows',
    'Cisco Secure Client – Pre-Logon – Trusted Root CA – Windows',
    'Cisco Secure Client – Pre-Logon – Device Cert (SCEP) – Windows'
)
$VpnProfileName  = 'Cisco Secure Client – Pre-Logon (SBL) – Profile – Windows'

function Connect-Graph {
    if (-not (Get-Module Microsoft.Graph.Authentication -ListAvailable)) {
        throw "Microsoft Graph PowerShell SDK not found. Run: Install-Module Microsoft.Graph -Scope CurrentUser"
    }
    Import-Module Microsoft.Graph.Authentication -ErrorAction Stop
    $scopes = @(
        'DeviceManagementApps.Read.All',
        'DeviceManagementConfiguration.Read.All',
        'DeviceManagementServiceConfig.Read.All',
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

Write-Host "`n=== Pre-Logon VPN (Cisco SBL/PLAP) — Deployment Readiness ===" -ForegroundColor Cyan

# --- Helper: assignment count for an app/profile -----------------------------
function Get-AssignmentSummary {
    param([string] $Uri)
    try {
        $a = Invoke-Graph $Uri
        if ($a -and $a.Count -gt 0) { return "$($a.Count) assignment(s)" } else { return "UNASSIGNED" }
    } catch { return "unknown" }
}

# --- Apps --------------------------------------------------------------------
Write-Host "`n[1] Win32 app (Core + Start Before Logon modules)" -ForegroundColor Cyan
$allApps = Invoke-Graph "$base/deviceAppManagement/mobileApps?`$select=id,displayName"
$appRows = foreach ($name in $ExpectedApps) {
    $match = $allApps | Where-Object { $_.displayName -eq $name }
    if ($match) {
        $assign = Get-AssignmentSummary "$base/deviceAppManagement/mobileApps/$($match.id)/assignments"
        [pscustomobject]@{ Object = $name; State = 'Found'; Assignment = $assign }
    } else {
        [pscustomobject]@{ Object = $name; State = 'MISSING'; Assignment = '-' }
    }
}
$appRows | Format-Table -AutoSize -Wrap

# --- Configuration profiles (VPN + trusted root + SCEP device cert) ----------
Write-Host "[2] VPN + certificate configuration profiles" -ForegroundColor Cyan
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
        $optional = if ($name -eq $VpnProfileName) { ' (optional — XML may be bundled in the Win32 app instead)' } else { '' }
        [pscustomobject]@{ Object = $name; State = "MISSING$optional"; Assignment = '-' }
    }
}
$profileRows | Format-Table -AutoSize -Wrap

# --- Groups ------------------------------------------------------------------
Write-Host "[3] Target Entra groups" -ForegroundColor Cyan
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
$groupRows | Format-Table -AutoSize -Wrap

# --- Summary -----------------------------------------------------------------
$missing = @()
$missing += ($appRows     | Where-Object { $_.State -like 'MISSING*' }).Object
$missing += ($profileRows | Where-Object { $_.State -like 'MISSING*' -and $_.Object -ne $VpnProfileName }).Object
$missing += ($groupRows   | Where-Object { $_.State -eq 'MISSING' }).Group

Write-Host "`n=== Summary ===" -ForegroundColor Cyan
if ($missing.Count -eq 0) {
    Write-Host "READY: the Win32 app, the trusted-root and SCEP device-cert profiles, and the groups are present." -ForegroundColor Green
} else {
    Write-Host "NOT READY — missing objects:" -ForegroundColor Yellow
    $missing | ForEach-Object { Write-Host "  - $_" -ForegroundColor Yellow }
    Write-Host "See 02-requirements.md / 03-implementation.md to create them." -ForegroundColor Yellow
}
Write-Host "Discovery complete (read-only). No changes were made." -ForegroundColor Green
