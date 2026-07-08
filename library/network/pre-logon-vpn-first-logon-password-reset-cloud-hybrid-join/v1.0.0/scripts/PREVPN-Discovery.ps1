<#
.SYNOPSIS
    PREVPN-Discovery.ps1 — pre-logon VPN readiness discovery: fleet join types + pre-logon capability.
.DESCRIPTION
    PURPOSE
        Read-only readiness sweep for the pre-logon VPN decision. Reports how the fleet's Windows
        devices are joined (Entra hybrid-joined vs Entra-joined vs domain-joined) from Entra device
        trustType, whether a pre-logon capability is deployed (a device-tunnel ProfileXML profile OR
        the Cisco Secure Client SBL Win32 app), and the pilot/production segmentation-group membership.
        Ends with a recommendation of which approach fits the fleet. Makes NO changes and creates NO
        VPN profiles (deployment is done in the companion products).
    HOW TO RUN
        powershell -ExecutionPolicy Bypass -File .\PREVPN-Discovery.ps1
        Required Microsoft Graph scopes (delegated, read-only):
            Device.Read.All
            DeviceManagementApps.Read.All
            DeviceManagementConfiguration.Read.All
            Group.Read.All
            Directory.Read.All
    EXPECTED RESULTS
        A readiness table: join-type counts (hybrid / Entra-joined / domain-joined / unknown), whether
        the referenced device-tunnel profile and the SBL app are Found/Missing, pilot/prod group
        counts, and a recommended approach. Hybrid/domain-joined devices are the ones the two
        scenarios apply to; Entra-joined largely avoid them.
.NOTES
    White-label — the repeatable way. Read-only against Microsoft Graph. Vendor internals deferred to vendor docs.
#>

[CmdletBinding()]
param(
    [string] $PilotGroupName = 'PILOT – Pre-Logon First-Logon Users',
    [string] $ProdGroupName  = 'PROD – Pre-Logon First-Logon Users'
)

$ErrorActionPreference = 'Stop'

# Objects created by the companion deployment products (referenced, not created here).
$DeviceTunnelProfileName = 'AOVPN – Device Tunnel – ProfileXML – Windows'
$SblAppName              = 'Cisco Secure Client – Pre-Logon (SBL) – Win32'

function Connect-Graph {
    if (-not (Get-Module Microsoft.Graph.Authentication -ListAvailable)) {
        throw "Microsoft Graph PowerShell SDK not found. Run: Install-Module Microsoft.Graph -Scope CurrentUser"
    }
    Import-Module Microsoft.Graph.Authentication -ErrorAction Stop
    $scopes = @(
        'Device.Read.All',
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

Write-Host "`n=== Pre-Logon VPN — Deployment-Decision Readiness ===" -ForegroundColor Cyan

# --- Device join types -------------------------------------------------------
# Entra device trustType: 'ServerAd' = domain-joined (on-prem AD), 'AzureAd' = Entra-joined,
# 'Workplace' = registered. Hybrid-joined devices report trustType 'ServerAd' with a cloud object,
# so we combine trustType with onPremisesSyncEnabled to separate hybrid from pure domain-joined.
Write-Host "`n[1] Windows device join types (Entra)" -ForegroundColor Cyan
$devices = Invoke-Graph "$base/devices?`$select=displayName,operatingSystem,trustType,onPremisesSyncEnabled&`$top=999"
$win = $devices | Where-Object { $_.operatingSystem -match 'Windows' }

$hybrid = 0; $entraJoined = 0; $domainJoined = 0; $registered = 0; $unknown = 0
foreach ($d in $win) {
    switch ($d.trustType) {
        'AzureAd'   { $entraJoined++ }
        'ServerAd'  { if ($d.onPremisesSyncEnabled) { $hybrid++ } else { $domainJoined++ } }
        'Workplace' { $registered++ }
        default     { $unknown++ }
    }
}
$joinRows = @(
    [pscustomobject]@{ 'Join type' = 'Entra hybrid-joined (needs DC path)'; Count = $hybrid }
    [pscustomobject]@{ 'Join type' = 'Domain-joined (needs DC path)';       Count = $domainJoined }
    [pscustomobject]@{ 'Join type' = 'Entra-joined (cloud — usually no tunnel)'; Count = $entraJoined }
    [pscustomobject]@{ 'Join type' = 'Registered / Workplace';              Count = $registered }
    [pscustomobject]@{ 'Join type' = 'Unknown';                            Count = $unknown }
)
$joinRows | Format-Table -AutoSize
$inScope = $hybrid + $domainJoined
Write-Host ("  In-scope for pre-logon (hybrid + domain-joined): {0}" -f $inScope) -ForegroundColor Yellow

# --- Pre-logon capability present? -------------------------------------------
Write-Host "`n[2] Pre-logon capability deployed (referenced companion objects)" -ForegroundColor Cyan

function Get-AssignmentSummary {
    param([string] $Uri)
    try {
        $a = Invoke-Graph $Uri
        if ($a -and $a.Count -gt 0) { return "$($a.Count) assignment(s)" } else { return 'UNASSIGNED' }
    } catch { return 'unknown' }
}

# Device-tunnel ProfileXML: a Windows custom (OMA-URI) device configuration named to convention.
$allConfigs = Invoke-Graph "$base/deviceManagement/deviceConfigurations?`$select=id,displayName"
$dt = $allConfigs | Where-Object { $_.displayName -eq $DeviceTunnelProfileName }
if ($dt) {
    $dtAssign = Get-AssignmentSummary "$base/deviceManagement/deviceConfigurations/$($dt.id)/assignments"
    $dtRow = [pscustomobject]@{ Capability = 'Device tunnel (A)'; Object = $DeviceTunnelProfileName; State = 'Found'; Assignment = $dtAssign }
} else {
    $dtRow = [pscustomobject]@{ Capability = 'Device tunnel (A)'; Object = $DeviceTunnelProfileName; State = 'MISSING'; Assignment = '-' }
}

# SBL/PLAP: a Win32 app named to convention.
$allApps = Invoke-Graph "$base/deviceAppManagement/mobileApps?`$select=id,displayName"
$sbl = $allApps | Where-Object { $_.displayName -eq $SblAppName }
if ($sbl) {
    $sblAssign = Get-AssignmentSummary "$base/deviceAppManagement/mobileApps/$($sbl.id)/assignments"
    $sblRow = [pscustomobject]@{ Capability = 'SBL / PLAP (B)'; Object = $SblAppName; State = 'Found'; Assignment = $sblAssign }
} else {
    $sblRow = [pscustomobject]@{ Capability = 'SBL / PLAP (B)'; Object = $SblAppName; State = 'MISSING'; Assignment = '-' }
}
@($dtRow, $sblRow) | Format-Table -AutoSize -Wrap

# --- Segmentation groups -----------------------------------------------------
Write-Host "[3] Segmentation groups" -ForegroundColor Cyan
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

# --- Recommendation ----------------------------------------------------------
Write-Host "`n=== Recommended approach ===" -ForegroundColor Cyan
if ($inScope -eq 0) {
    Write-Host "Fleet is effectively cloud-only (no hybrid/domain-joined devices detected)." -ForegroundColor Green
    Write-Host "  -> Pre-logon VPN is likely NOT needed. Use SSPR + TAP for cloud password/first-signin paths." -ForegroundColor Green
} else {
    Write-Host "$inScope device(s) are hybrid/domain-joined and need a DC path at pre-logon." -ForegroundColor Yellow
    if ($dt.State -eq 'Found' -or $dt) {
        Write-Host "  -> Device-tunnel profile is present. Prefer DEVICE TUNNEL (A) where devices are" -ForegroundColor Yellow
        Write-Host "     Enterprise/Education + have a machine cert + IKEv2 gateway (silent, no user action)." -ForegroundColor Yellow
    }
    if ($sbl) {
        Write-Host "  -> SBL/PLAP app is present. Use SBL / PLAP (B) where you already run Cisco Secure Client" -ForegroundColor Yellow
        Write-Host "     or cannot meet the device-tunnel SKU/cert/IKEv2 bar (user connects at the logon screen)." -ForegroundColor Yellow
    }
    if (-not $dt -and -not $sbl) {
        Write-Host "  -> NEITHER capability is deployed yet. Run the decision matrix (03-implementation.md)" -ForegroundColor Red
        Write-Host "     and deploy the chosen COMPANION product before validating the scenarios." -ForegroundColor Red
    }
}
Write-Host "`nDiscovery complete (read-only). No changes were made; no VPN profiles were created." -ForegroundColor Green
