<#
.SYNOPSIS
    CPAVPN-Discovery.ps1 — Cisco per-app VPN readiness inventory for iOS/Android (read-only).
.DESCRIPTION
    PURPOSE
        Inventories per-app VPN readiness in Microsoft Intune: enumerates iOS and Android VPN
        device-configuration profiles (flagging Cisco Secure Client / per-app ones), lists managed
        mobile apps and their bundle IDs / package names, shows profile and app assignments, and
        confirms the Entra targeting groups exist. Read-only baseline before any change.
        Cisco head-end configuration is deferred to Cisco documentation.
    HOW TO RUN
        powershell -ExecutionPolicy Bypass -File .\CPAVPN-Discovery.ps1

        Requires the Microsoft Graph PowerShell SDK and delegated scopes:
        DeviceManagementConfiguration.Read.All, DeviceManagementApps.Read.All, Group.Read.All.
    EXPECTED RESULTS
        Lists of iOS/Android VPN profiles, managed apps, and assignments, plus OK/MISS on the scope
        groups. No changes are made (read-only). Use it to confirm what exists before building the
        per-app VPN profiles.
.NOTES
    White-label — the repeatable way. Read-only against Microsoft Graph. Cisco internals deferred to vendor docs.
#>
[CmdletBinding()] param(
    [string[]] $ScopeGroup = @('PILOT - Per-App VPN Users','BROAD - Per-App VPN Users')
)

Write-Host "`n=== CPAVPN Discovery — per-app VPN readiness (read-only) ===" -ForegroundColor Cyan

if (-not (Get-Module -ListAvailable -Name Microsoft.Graph.Authentication)) {
    Install-Module Microsoft.Graph -Scope CurrentUser -Force -AllowClobber
}
Import-Module Microsoft.Graph.Authentication -ErrorAction Stop
Connect-MgGraph -Scopes 'DeviceManagementConfiguration.Read.All','DeviceManagementApps.Read.All','Group.Read.All' -NoWelcome

# --- VPN device-configuration profiles (iOS + Android) ---
Write-Host "`n[VPN profiles — iOS & Android]" -ForegroundColor Cyan
try {
    $profiles = (Invoke-MgGraphRequest -Method GET -Uri "/v1.0/deviceManagement/deviceConfigurations?`$top=200").value
    $vpn = $profiles | Where-Object {
        $_.'@odata.type' -match 'VpnConfiguration' -or $_.displayName -match 'VPN'
    }
    if ($vpn) {
        foreach ($p in ($vpn | Sort-Object displayName)) {
            $type = $p.'@odata.type'
            $plat = if ($type -match 'ios') { 'iOS' } elseif ($type -match 'android') { 'Android' } else { 'other' }
            $cisco = if (($p | ConvertTo-Json -Depth 6) -match 'ciscoAnyConnect|ciscoSecureClient|cisco') { 'Cisco?' } else { '' }
            Write-Host ("  [{0,-7}] {1}  {2}" -f $plat, $p.displayName, $cisco)
        }
        Write-Host ("  Total VPN-like profiles: {0}" -f $vpn.Count) -ForegroundColor Green
    } else {
        Write-Host "  No VPN profiles found — build 'Cisco Per-App VPN - iOS' and 'Cisco Per-App VPN - Android'." -ForegroundColor Yellow
    }
} catch {
    Write-Host ("  Could not enumerate VPN profiles: {0}" -f $_.Exception.Message) -ForegroundColor Yellow
}

# --- Managed mobile apps (bundle IDs / package names) ---
Write-Host "`n[Managed mobile apps — candidates to associate]" -ForegroundColor Cyan
try {
    $apps = (Invoke-MgGraphRequest -Method GET -Uri "/v1.0/deviceAppManagement/mobileApps?`$top=200").value
    $mobile = $apps | Where-Object { $_.'@odata.type' -match 'ios|android' }
    if ($mobile) {
        foreach ($a in ($mobile | Sort-Object displayName)) {
            $id = $a.bundleId; if (-not $id) { $id = $a.packageId }; if (-not $id) { $id = $a.appIdentifier }
            $cisco = if ($a.displayName -match 'Cisco|Secure Client|AnyConnect') { '  <-- Cisco Secure Client' } else { '' }
            Write-Host ("  {0,-40} {1}{2}" -f $a.displayName, $id, $cisco)
        }
        Write-Host ("  Total iOS/Android managed apps: {0}" -f $mobile.Count) -ForegroundColor Green
    } else {
        Write-Host "  No iOS/Android managed apps found — deploy the apps you intend to tunnel." -ForegroundColor Yellow
    }
} catch {
    Write-Host ("  Could not enumerate managed apps: {0}" -f $_.Exception.Message) -ForegroundColor Yellow
}

# --- Assignments on the VPN profiles ---
Write-Host "`n[VPN profile assignments]" -ForegroundColor Cyan
try {
    foreach ($p in ($vpn | Where-Object { $_.displayName -match 'Per-App VPN' } | Sort-Object displayName)) {
        $asg = (Invoke-MgGraphRequest -Method GET -Uri "/v1.0/deviceManagement/deviceConfigurations/$($p.id)/assignments").value
        if ($asg) {
            Write-Host ("  {0}: {1} assignment(s)" -f $p.displayName, $asg.Count) -ForegroundColor Green
        } else {
            Write-Host ("  {0}: NOT assigned — assign to 'PILOT - Per-App VPN Users'." -f $p.displayName) -ForegroundColor Yellow
        }
    }
} catch {
    Write-Host ("  Could not read assignments: {0}" -f $_.Exception.Message) -ForegroundColor Yellow
}

# --- Scope-group readiness ---
Write-Host "`n[Per-app VPN scope groups]" -ForegroundColor Cyan
foreach ($g in $ScopeGroup) {
    try {
        $f = "displayName eq '$($g.Replace("'","''"))'"
        $found = (Invoke-MgGraphRequest -Method GET -Uri "/v1.0/groups?`$filter=$f").value
        if ($found) { Write-Host ("  OK   {0}" -f $g) -ForegroundColor Green }
        else        { Write-Host ("  MISS {0}  (build it with CPAVPN-Set-ScopeTargeting.ps1)" -f $g) -ForegroundColor Yellow }
    } catch {
        Write-Host ("  ERR  {0}: {1}" -f $g, $_.Exception.Message) -ForegroundColor Yellow
    }
}

# --- Cisco head-end (DEFERRED) ---
Write-Host "`n[Cisco VPN head-end — DEFERRED]" -ForegroundColor DarkYellow
Write-Host "  The Cisco Secure Client head-end (gateway/firewall remote-access role, typically" -ForegroundColor DarkYellow
Write-Host "  brokered by Cisco ISE) — connection profile, address pool, split-tunnel/split-DNS," -ForegroundColor DarkYellow
Write-Host "  and posture — is configured in Cisco's consoles and deferred to Cisco documentation." -ForegroundColor DarkYellow
Write-Host "  This script consumes only the head-end server address + auth method (per Cisco docs)." -ForegroundColor DarkYellow

Write-Host "`nBaseline captured. Build/associate the per-app VPN profiles per the Implementation Guide." -ForegroundColor Green
Disconnect-MgGraph | Out-Null
