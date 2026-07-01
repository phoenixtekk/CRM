<#
.SYNOPSIS
    CISEDIAG-Check-VpnClient.ps1 — check the Cisco Secure Client / VPN client and profile state on this device.
.DESCRIPTION
    PURPOSE
        Inspects the L2 device-side facts a connection needs before it can even authenticate: is a
        Cisco Secure Client / VPN service installed and running, is a VPN configuration profile present
        on the device, and what gateway/head-end does it name. Isolates Branch C (client won't try /
        wrong or missing profile / can't reach gateway). Optionally test reachability to a head-end
        with -Gateway your-vpn-gateway-fqdn. Read-only: it reads services, profile files, and does a
        name-resolution/reachability probe only — it never starts, stops, or reconfigures anything.
    HOW TO RUN
        powershell -ExecutionPolicy Bypass -File .\CISEDIAG-Check-VpnClient.ps1
        powershell -ExecutionPolicy Bypass -File .\CISEDIAG-Check-VpnClient.ps1 -Gateway your-vpn-gateway-fqdn
        (no Graph scopes required — this is a local device check)
    EXPECTED RESULTS
        Service status, a list of VPN configuration profile files with the gateway(s) they reference,
        and (if -Gateway given) DNS + reachability results. Service running + correct profile + gateway
        reachable => L2 healthy, move to Branch D. Missing profile or wrong gateway => Branch C (repair
        the VPN configuration profile in Intune). Client-internal faults => collect a Cisco DART bundle
        and escalate per vendor docs.
.NOTES
    White-label — the repeatable way. Read-only. Cisco ISE / Secure Client internals deferred to vendor docs.
#>

[CmdletBinding()]
param(
    [string] $Gateway,
    [string] $JsonOut
)

$ErrorActionPreference = 'Continue'
Write-Host "CISEDIAG-Check-VpnClient : inspecting VPN client + profile state (read-only)" -ForegroundColor Cyan

$report = [ordered]@{}

# ---- Service presence -------------------------------------------------------
$svc = Get-Service -ErrorAction SilentlyContinue |
    Where-Object { $_.DisplayName -match 'Cisco|Secure Client|AnyConnect|VPN' } |
    Select-Object Name, DisplayName, Status
$report.Services = $svc
if (@($svc).Count -eq 0) {
    Write-Host "  Services : none matching Cisco/Secure Client/VPN found." -ForegroundColor Yellow
} else {
    $svc | Format-Table DisplayName, Status -AutoSize
}

# ---- VPN configuration profiles on the device -------------------------------
$profilePaths = @(
    "$env:ProgramData\Cisco\Cisco Secure Client\VPN\Profile",
    "$env:ProgramData\Cisco\Cisco AnyConnect Secure Mobility Client\Profile"
)
$profileInfo = [System.Collections.Generic.List[object]]::new()
foreach ($p in $profilePaths) {
    if (Test-Path $p) {
        foreach ($f in (Get-ChildItem $p -Filter *.xml -ErrorAction SilentlyContinue)) {
            $hosts = @()
            try {
                [xml]$xml = Get-Content $f.FullName -Raw
                # Gateways in a Secure Client profile appear as HostAddress nodes; read defensively.
                $hosts = @($xml.SelectNodes('//*[local-name()="HostAddress"]') | ForEach-Object { $_.'#text' } | Where-Object { $_ })
            } catch { }
            $profileInfo.Add([pscustomobject]@{
                File     = $f.FullName
                Modified = $f.LastWriteTime
                Gateways = ($hosts -join ', ')
            })
        }
    }
}
$report.Profiles = $profileInfo
if ($profileInfo.Count -eq 0) {
    Write-Host "  Profiles : no VPN configuration profile found on device -> Branch C (profile delivery)." -ForegroundColor Yellow
} else {
    $profileInfo | Format-Table File, Gateways, Modified -AutoSize
}

# ---- Optional head-end reachability (read-only probe) -----------------------
if ($Gateway) {
    Write-Host "  Probing gateway '$Gateway' (name resolution + reachability)..." -ForegroundColor Gray
    $dns = $null; $reach = $null
    try { $dns = Resolve-DnsName -Name $Gateway -ErrorAction Stop | Select-Object -First 1 -ExpandProperty IPAddress } catch { $dns = "resolve failed: $($_.Exception.Message)" }
    try { $reach = (Test-NetConnection -ComputerName $Gateway -Port 443 -WarningAction SilentlyContinue).TcpTestSucceeded } catch { $reach = $false }
    $report.GatewayProbe = [pscustomobject]@{ Gateway = $Gateway; Resolved = $dns; Tcp443 = $reach }
    Write-Host "  Gateway resolve: $dns ; TCP/443 reachable: $reach"
    if (-not $reach) { Write-Host "  => Gateway unreachable -> network path (DNS/firewall/egress) or wrong gateway (Branch C)." -ForegroundColor Yellow }
}

if (@($svc | Where-Object Status -eq 'Running').Count -gt 0 -and $profileInfo.Count -gt 0) {
    Write-Host "RESULT: VPN client running and a profile is present -> if gateway reachable, proceed to Branch D (EAP-TLS)." -ForegroundColor Green
} else {
    Write-Host "RESULT: L2 gap detected -> work Branch C. For client-internal faults, collect a Cisco DART bundle (vendor docs) and escalate." -ForegroundColor Yellow
}

if ($JsonOut) { $report | ConvertTo-Json -Depth 5 | Out-File $JsonOut -Encoding utf8; Write-Host "Wrote $JsonOut" -ForegroundColor Gray }
