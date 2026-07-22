<#
.SYNOPSIS
    VPNHEALTH-Discovery.ps1 — read-only inventory of VPN profiles + the tunnel-health monitoring package.

.DESCRIPTION
    PURPOSE
        Gives you a one-page picture, via Microsoft Graph, of what this monitoring practice has to work
        with and whether it is wired up:
          - Which VPN CONFIGURATION PROFILES are deployed in Intune (so you know what tunnels exist to
            monitor) and roughly what VPN technology each is.
          - Whether the health-check package 'VPNHEALTH - Tunnel Health - Detect - Pilot' (and the
            Production copy) EXISTS and is ASSIGNED.
          - Whether a Log Analytics / telemetry data path looks present (best-effort hint).
        Makes NO changes — read-only.

    HOW TO RUN
        Install-Module Microsoft.Graph -Scope CurrentUser   # once
        .\VPNHEALTH-Discovery.ps1
        .\VPNHEALTH-Discovery.ps1 -NameLike 'VPNHEALTH'

    GRAPH SCOPES (read-only)
        DeviceManagementConfiguration.Read.All

    EXPECTED RESULTS
        A table of deployed VPN profiles and a table of health-check packages with assignment counts.
        An empty package list means the monitor is not deployed yet (Implementation Step 4). NOTE:
        Proactive Remediations = device health scripts on the Graph BETA endpoint
        (deviceManagement/deviceHealthScripts) which can change — verify against current Microsoft docs.

.NOTES
    White-label — Intune Solutions. Read-only.
#>
[CmdletBinding()]
param(
    [string]$NameLike = 'VPNHEALTH'
)

$ErrorActionPreference = 'Stop'
Connect-MgGraph -Scopes 'DeviceManagementConfiguration.Read.All' | Out-Null

function GraphGet($uri) {
    $items = @()
    do { $r = Invoke-MgGraphRequest -Method GET -Uri $uri; $items += $r.value; $uri = $r.'@odata.nextLink' } while ($uri)
    return $items
}

# --- 1) Deployed VPN configuration profiles (what tunnels exist to monitor) -------------------
Write-Host 'VPN configuration profiles deployed in Intune:' -ForegroundColor Cyan
try {
    $configs = GraphGet 'https://graph.microsoft.com/beta/deviceManagement/deviceConfigurations?$select=id,displayName,@odata.type'
    $vpn = $configs | Where-Object { $_.'@odata.type' -match 'vpn' -or $_.displayName -match 'vpn|tunnel|anyconnect|always ?on' }
    if ($vpn) { $vpn | Select-Object displayName, @{n='Type';e={$_.'@odata.type'}} | Format-Table -AutoSize }
    else { Write-Host '  (no obvious VPN profiles found via deviceConfigurations — some VPN profiles live under the Settings Catalog; verify in the console)' -ForegroundColor Yellow }
} catch {
    Write-Host '  Could not enumerate deviceConfigurations (beta) — verify endpoint/permissions against Microsoft docs.' -ForegroundColor Yellow
}
Write-Host ''

# --- 2) The health-check package(s) -----------------------------------------------------------
Write-Host 'Tunnel-health monitoring package(s):' -ForegroundColor Cyan
$base = 'https://graph.microsoft.com/beta/deviceManagement/deviceHealthScripts'
try {
    $scripts = GraphGet "$base`?`$select=id,displayName,publisher,runAsAccount,version,lastModifiedDateTime"
} catch {
    Write-Host '  Could not read deviceHealthScripts (beta). Confirm the Proactive Remediations entitlement (R1) and the current Graph endpoint against Microsoft documentation.' -ForegroundColor Yellow
    return
}
if ($NameLike) { $scripts = $scripts | Where-Object { $_.displayName -like "*$NameLike*" } }
if (-not $scripts) { Write-Host "  No packages matching '$NameLike' — deploy the monitor (Implementation Step 4)." -ForegroundColor Yellow; return }

$rows = foreach ($s in $scripts) {
    $assign = @(); try { $assign = GraphGet "$base/$($s.id)/assignments" } catch {}
    [pscustomobject]@{
        Name        = $s.displayName
        Publisher   = $s.publisher
        RunAs       = $s.runAsAccount
        Assignments = $assign.Count
        Modified    = $s.lastModifiedDateTime
    }
}
$rows | Sort-Object Name | Format-Table -AutoSize
$unassigned = $rows | Where-Object { $_.Assignments -eq 0 }
if ($unassigned) {
    Write-Host ''
    Write-Host 'Health-check packages with NO assignments (deployed to nothing — review):' -ForegroundColor Yellow
    $unassigned | Format-Table Name, Modified -AutoSize
}
Write-Host ''
Write-Host 'Telemetry note: whether health results reach Log Analytics depends on the data path you wired (Implementation Step 7).' -ForegroundColor DarkGray
Write-Host 'The exact table/connector for Proactive Remediations output is verify-with-Microsoft.' -ForegroundColor DarkGray
