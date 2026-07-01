<#
.SYNOPSIS
    NSZTNA-Discovery.ps1 — ZTNA readiness: endpoint posture, current VPN routes/hosts, publisher candidates.
.DESCRIPTION
    PURPOSE
        Read-only assessment for a Netskope Private Access (ZTNA) VPN-replacement project. Captures
        the device's management/compliance posture signals, the routes/hosts the legacy VPN currently
        serves (a starting point for the private-app inventory), and whether the Netskope client is
        already present. Helps build the app inventory and confirm prerequisites before publishing apps.
    HOW TO RUN
        Elevated (for full network/route visibility):
            powershell -ExecutionPolicy Bypass -File .\NSZTNA-Discovery.ps1
    EXPECTED RESULTS
        OS/build, domain-join/management state, active VPN/tunnel interfaces and their routes/hosts,
        Netskope client presence, and a note on candidate publisher placement. No changes are made.
.NOTES
    Network — ZTNA / Netskope Private Access. Read-only. Authored the repeatable way.
    Netskope tenant-side discovery (publisher/app/policy state) is via the Netskope REST API and is
    deferred — see the flagged section below and the official Netskope documentation.
#>
[CmdletBinding()] param()

Write-Host "`n=== ZTNA Discovery — $($env:COMPUTERNAME) ===" -ForegroundColor Cyan

# --- OS / build ---
$ci = Get-ComputerInfo -Property WindowsProductName,OsBuildNumber,WindowsVersion -ErrorAction SilentlyContinue
Write-Host ("OS              : {0}  (build {1}, {2})" -f $ci.WindowsProductName, $ci.OsBuildNumber, $ci.WindowsVersion)

# --- Management / posture signals (informational; policy posture is evaluated by Netskope/Intune) ---
$cs = Get-CimInstance Win32_ComputerSystem -ErrorAction SilentlyContinue
Write-Host ("Domain joined   : {0}" -f $cs.PartOfDomain)
$dsreg = (& dsregcmd /status 2>$null)
$aadJoined = ($dsreg | Select-String 'AzureAdJoined\s*:\s*YES' -Quiet)
$mdmEnrolled = ($dsreg | Select-String 'MDMUrl|MDM enrollment' -Quiet)
Write-Host ("Entra joined    : {0}" -f ([bool]$aadJoined))
Write-Host ("MDM enrolled    : {0}" -f ([bool]$mdmEnrolled))

# --- Netskope client presence (informational) ---
$nsSvc = Get-Service -ErrorAction SilentlyContinue | Where-Object { $_.Name -match 'stagent|netskope' -or $_.DisplayName -match 'Netskope' }
if ($nsSvc) { Write-Host ("Netskope client : present  ({0})" -f (($nsSvc | ForEach-Object { $_.Name }) -join ', ')) -ForegroundColor Green }
else { Write-Host "Netskope client : not detected" -ForegroundColor Yellow }

# --- Legacy VPN interfaces + routes (starting point for the private-app inventory) ---
Write-Host "`n--- VPN / tunnel interfaces ---" -ForegroundColor Cyan
$vpnIfaces = Get-NetAdapter -ErrorAction SilentlyContinue | Where-Object {
    $_.Status -eq 'Up' -and ($_.InterfaceDescription -match 'VPN|WAN Miniport|TAP|tunnel|Netskope|AnyConnect|GlobalProtect|FortiClient|PANGP')
}
if ($vpnIfaces) {
    foreach ($i in $vpnIfaces) {
        Write-Host ("  Interface: {0}  ({1})" -f $i.Name, $i.InterfaceDescription)
        $routes = Get-NetRoute -InterfaceIndex $i.ifIndex -ErrorAction SilentlyContinue |
                  Where-Object { $_.DestinationPrefix -ne '0.0.0.0/0' -and $_.DestinationPrefix -notmatch '^(127\.|224\.|255\.|::)' }
        if ($routes) { $routes | Sort-Object DestinationPrefix | ForEach-Object { Write-Host ("    route -> {0}" -f $_.DestinationPrefix) } }
        else { Write-Host "    (no specific split-tunnel routes on this interface)" }
    }
    Write-Host "  NOTE: Map these subnets/hosts to named apps -> publish each as 'Private App - <App> - Inventory'." -ForegroundColor Yellow
} else {
    Write-Host "  No active VPN/tunnel interface detected on this device." -ForegroundColor Yellow
}

# --- Candidate publisher placement (informational) ---
Write-Host "`n--- Publisher placement hint ---" -ForegroundColor Cyan
Write-Host "  Place a 'Publisher - <Site> - Pilot' in each segment that hosts private apps (outbound egress only)."
Write-Host "  Confirm the chosen host has outbound internet egress to the Netskope cloud (no inbound ports)."

# --- DEFERRED: Netskope tenant-side discovery (REST API) ---
Write-Host "`n--- Netskope tenant discovery (DEFERRED) ---" -ForegroundColor DarkGray
Write-Host "  Enumerating existing publishers / private apps / access policies is done via the Netskope" -ForegroundColor DarkGray
Write-Host "  REST API (tenant base URL + API token). Endpoints and schema are tenant/version-specific and" -ForegroundColor DarkGray
Write-Host "  are DEFERRED to the official Netskope documentation. Do not hardcode endpoints here." -ForegroundColor DarkGray

Write-Host "`nDiscovery complete (read-only)." -ForegroundColor Green
