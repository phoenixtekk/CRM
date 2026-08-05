<#
.SYNOPSIS
    WIFIDX-Get-WifiProfiles.ps1 — export Intune Wi-Fi configuration profiles, assignments, and proxy;
    detect duplicates and conflicts.
.DESCRIPTION
    PURPOSE
        Enumerates every Intune Wi-Fi device-configuration profile (legacy Wi-Fi templates across
        Windows / iOS / Android, plus settings-catalog Wi-Fi policies), and for each reports the SSID,
        proxy mode/value, and the Included/Excluded Entra groups. It then groups profiles by SSID and
        FLAGS any SSID that is targeted by more than one profile (the duplicate/conflict set from
        Branch C). Read-only.
    HOW TO RUN
        powershell -ExecutionPolicy Bypass -File .\WIFIDX-Get-WifiProfiles.ps1
        powershell -ExecutionPolicy Bypass -File .\WIFIDX-Get-WifiProfiles.ps1 -Environment USGov -Ssid CORP-WIFI
        Requires scopes DeviceManagementConfiguration.Read.All, Group.Read.All.
    EXPECTED RESULTS
        One block per Wi-Fi profile (name, platform, SSID, proxy mode + value, Included/Excluded
        groups), then a DUPLICATES/CONFLICTS section listing any SSID owned by 2+ profiles. Proxy
        values are checked for the common shape mistake (a URL/slash in a manual field, or a bare host
        in an automatic/PAC field) and flagged inline.
.NOTES
    Intune Solutions — read-only. Cloud-aware (Global | USGov | USGovDoD). Detects duplicates/conflicts.
#>
[CmdletBinding()]
param(
    [ValidateSet('Global','USGov','USGovDoD')]
    [string]$Environment = 'Global',
    [string]$Ssid
)

if (-not (Get-Module -ListAvailable -Name Microsoft.Graph.Authentication)) {
    Install-Module Microsoft.Graph -Scope CurrentUser -Force -AllowClobber
}
Import-Module Microsoft.Graph.Authentication -ErrorAction Stop
Connect-MgGraph -Environment $Environment -Scopes 'DeviceManagementConfiguration.Read.All','Group.Read.All' -NoWelcome

function Resolve-GroupName([string]$id) {
    if (-not $id) { return $null }
    try { return (Invoke-MgGraphRequest -Method GET -Uri "/v1.0/groups/$id`?`$select=displayName").displayName }
    catch { return $id }
}

# Flag the classic proxy shape mistakes (see Branch B).
function Test-ProxyShape([string]$mode, [string]$value) {
    if (-not $value) { return '' }
    switch -Wildcard ($mode) {
        '*manual*'    { if ($value -match '://' -or $value -match '/') { return "  <-- CHECK: manual proxy must be HOST+PORT, not a URL/path" } }
        '*automatic*' { if ($value -notmatch '://') { return "  <-- CHECK: automatic proxy must be a full PAC URL (http://host/..pac)" } }
    }
    return ''
}

$rows = New-Object System.Collections.Generic.List[object]

# --- Legacy device-configuration Wi-Fi templates (Windows / iOS / Android) ---
$odataWifi = "isof('microsoft.graph.windowsWifiConfiguration') or isof('microsoft.graph.windowsWifiEnterpriseEAPConfiguration') or isof('microsoft.graph.iosWiFiConfiguration') or isof('microsoft.graph.iosEnterpriseWiFiConfiguration') or isof('microsoft.graph.androidWorkProfileWiFiConfiguration') or isof('microsoft.graph.androidWorkProfileEnterpriseWiFiConfiguration') or isof('microsoft.graph.androidDeviceOwnerWiFiConfiguration')"
try {
    $legacy = (Invoke-MgGraphRequest -Method GET -Uri "/beta/deviceManagement/deviceConfigurations?`$filter=$odataWifi&`$expand=assignments").value
} catch { $legacy = @() }

foreach ($c in $legacy) {
    $ssidVal  = $c.ssid
    $proxyMode = $c.proxySettings
    $proxyVal  = if ($c.proxyServerAddress) { "$($c.proxyServerAddress):$($c.proxyServerPort)" } elseif ($c.proxyAutomaticConfigurationUrl) { $c.proxyAutomaticConfigurationUrl } else { $null }
    $rows.Add([pscustomobject]@{
        Name = $c.displayName; Platform = ($c.'@odata.type' -replace '#microsoft.graph.',''); Ssid = $ssidVal
        ProxyMode = $proxyMode; ProxyVal = $proxyVal; Assignments = $c.assignments
    })
}

# --- Settings-catalog Wi-Fi policies (best-effort SSID/proxy extraction) ---
try {
    $catalog = (Invoke-MgGraphRequest -Method GET -Uri '/beta/deviceManagement/configurationPolicies?$expand=assignments').value |
        Where-Object { $_.name -match 'wifi|wi-fi|wireless' -or $_.templateReference.templateFamily -match 'wifi' }
} catch { $catalog = @() }
foreach ($p in $catalog) {
    $rows.Add([pscustomobject]@{
        Name = $p.name; Platform = ($p.platforms); Ssid = '(settings-catalog — open policy for SSID)'
        ProxyMode = '(see policy)'; ProxyVal = $null; Assignments = $p.assignments
    })
}

if ($Ssid) { $rows = $rows | Where-Object { $_.Ssid -eq $Ssid -or $_.Ssid -like '*settings-catalog*' } }

Write-Host "`n=== Intune Wi-Fi Configuration Profiles ===" -ForegroundColor Cyan
if (-not $rows -or $rows.Count -eq 0) { Write-Host "No Wi-Fi profiles found." -ForegroundColor Yellow; Disconnect-MgGraph | Out-Null; return }

foreach ($r in $rows) {
    Write-Host ("`nPROFILE: {0}   [platform: {1}]" -f $r.Name, $r.Platform) -ForegroundColor Cyan
    Write-Host ("  SSID: {0}" -f $r.Ssid)
    if ($r.ProxyVal) { Write-Host ("  Proxy: {0} = {1}{2}" -f $r.ProxyMode, $r.ProxyVal, (Test-ProxyShape $r.ProxyMode $r.ProxyVal)) -ForegroundColor Gray }
    elseif ($r.ProxyMode) { Write-Host ("  Proxy: {0}" -f $r.ProxyMode) -ForegroundColor Gray }
    if (-not $r.Assignments -or $r.Assignments.Count -eq 0) { Write-Host "  (no assignments — targets nothing)" -ForegroundColor Yellow; continue }
    foreach ($a in $r.Assignments) {
        $t = $a.target
        $kind = switch -Wildcard ($t.'@odata.type') {
            '*exclusionGroupAssignmentTarget'   { 'EXCLUDE' }
            '*allDevicesAssignmentTarget'       { 'INCLUDE (All devices)' }
            '*allLicensedUsersAssignmentTarget' { 'INCLUDE (All users)' }
            default { 'INCLUDE' }
        }
        $grp = if ($t.groupId) { "$(Resolve-GroupName $t.groupId) [$($t.groupId)]" } else { '(built-in target)' }
        $color = if ($kind -like 'EXCLUDE*') { 'Yellow' } else { 'Green' }
        Write-Host ("    {0,-22} {1}" -f $kind, $grp) -ForegroundColor $color
    }
}

# --- Duplicate / conflict detection by SSID ---
Write-Host "`n=== Duplicates / Conflicts (same SSID owned by 2+ profiles) ===" -ForegroundColor Cyan
$byS = $rows | Where-Object { $_.Ssid -and $_.Ssid -notlike '*settings-catalog*' } | Group-Object Ssid
$flagged = $false
foreach ($g in $byS) {
    if ($g.Count -gt 1) {
        $flagged = $true
        Write-Host ("  SSID '{0}' is targeted by {1} profiles:" -f $g.Name, $g.Count) -ForegroundColor Yellow
        $g.Group | ForEach-Object { Write-Host ("    - {0}" -f $_.Name) -ForegroundColor Yellow }
        Write-Host "    -> Branch C: reduce to ONE profile per SSID per device." -ForegroundColor Yellow
    }
}
if (-not $flagged) { Write-Host "  None detected." -ForegroundColor Green }

Disconnect-MgGraph | Out-Null
