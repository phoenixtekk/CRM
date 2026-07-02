<#
.SYNOPSIS
    NETDX-Discovery.ps1 — capture the endpoint's connectivity posture (DNS, proxy/PAC, VPN, routes).
.DESCRIPTION
    PURPOSE
        Records the affected Windows endpoint's network posture so you have an evidence baseline
        before troubleshooting: configured DNS servers, system (WinINET) and WinHTTP proxy, any PAC
        URL, VPN/interface state, and default routes. Read-only; changes nothing.
        Save the output as evidence and compare against a known-good control endpoint.
    HOW TO RUN
        powershell -ExecutionPolicy Bypass -File .\NETDX-Discovery.ps1
        powershell -ExecutionPolicy Bypass -File .\NETDX-Discovery.ps1 -OutputPath C:\Temp\netdx
        (no special scopes; run from an elevated prompt for the fullest posture)
    EXPECTED RESULTS
        A console summary plus a JSON file (netdx-discovery-COMPUTER-TIMESTAMP.json) capturing the
        posture. Admin sees DNS servers, proxy/PAC config, VPN/adapter state, and default routes.
        Pass = the file is written and the posture matches the intended design; investigate any
        unexpected proxy, missing VPN interface, or wrong DNS server.
.NOTES
    White-label — the repeatable way. Read-only for discovery/validation.
#>

[CmdletBinding()]
param(
    [string]$OutputPath = (Join-Path -Path $env:TEMP -ChildPath 'netdx')
)

$ErrorActionPreference = 'Continue'

function Write-Section {
    param([string]$Title)
    Write-Host ''
    Write-Host "=== $Title ===" -ForegroundColor Cyan
}

if (-not (Test-Path -Path $OutputPath)) {
    New-Item -Path $OutputPath -ItemType Directory -Force | Out-Null
}

$posture = [ordered]@{
    ComputerName = $env:COMPUTERNAME
    CollectedAt  = (Get-Date).ToString('o')
    DnsServers   = @()
    HostsEntries = @()
    SystemProxy  = $null
    WinHttpProxy = $null
    PacUrl       = $null
    Adapters     = @()
    DefaultRoutes = @()
}

# --- DNS servers ---
Write-Section 'DNS servers (configured)'
try {
    $dns = Get-DnsClientServerAddress -AddressFamily IPv4 -ErrorAction Stop |
        Where-Object { $_.ServerAddresses } |
        Select-Object InterfaceAlias, @{ n = 'Servers'; e = { $_.ServerAddresses -join ', ' } }
    $dns | Format-Table -AutoSize | Out-String | Write-Host
    $posture.DnsServers = $dns | ForEach-Object { @{ Interface = $_.InterfaceAlias; Servers = $_.Servers } }
}
catch { Write-Warning "Could not read DNS client servers: $($_.Exception.Message)" }

# --- hosts file overrides ---
Write-Section 'Hosts file entries (overrides)'
$hostsPath = Join-Path -Path $env:SystemRoot -ChildPath 'System32\drivers\etc\hosts'
try {
    $hostsLines = Get-Content -Path $hostsPath -ErrorAction Stop |
        Where-Object { $_ -and ($_.Trim() -notmatch '^#') -and ($_.Trim().Length -gt 0) }
    if ($hostsLines) {
        $hostsLines | ForEach-Object { Write-Host "  $_" }
        $posture.HostsEntries = @($hostsLines)
    }
    else { Write-Host '  (no active overrides)' }
}
catch { Write-Warning "Could not read hosts file: $($_.Exception.Message)" }

# --- system (WinINET) proxy ---
Write-Section 'System proxy (WinINET / HKCU Internet Settings)'
try {
    $inet = Get-ItemProperty -Path 'HKCU:\Software\Microsoft\Windows\CurrentVersion\Internet Settings' -ErrorAction Stop
    $sysProxy = [ordered]@{
        ProxyEnable   = $inet.ProxyEnable
        ProxyServer   = $inet.ProxyServer
        AutoConfigURL = $inet.AutoConfigURL
    }
    $sysProxy.GetEnumerator() | ForEach-Object { Write-Host ("  {0,-14}: {1}" -f $_.Key, $_.Value) }
    $posture.SystemProxy = $sysProxy
    if ($inet.AutoConfigURL) { $posture.PacUrl = $inet.AutoConfigURL }
}
catch { Write-Warning "Could not read WinINET settings: $($_.Exception.Message)" }

# --- WinHTTP proxy ---
Write-Section 'WinHTTP proxy (netsh)'
try {
    $winhttp = (& netsh winhttp show proxy) 2>&1 | Out-String
    Write-Host $winhttp.Trim()
    $posture.WinHttpProxy = $winhttp.Trim()
}
catch { Write-Warning "Could not read WinHTTP proxy: $($_.Exception.Message)" }

# --- adapters / VPN interface state ---
Write-Section 'Network adapters (interface state)'
try {
    $adapters = Get-NetAdapter -ErrorAction Stop |
        Select-Object Name, InterfaceDescription, Status, LinkSpeed
    $adapters | Format-Table -AutoSize | Out-String | Write-Host
    $posture.Adapters = $adapters | ForEach-Object {
        @{ Name = $_.Name; Description = $_.InterfaceDescription; Status = "$($_.Status)"; LinkSpeed = "$($_.LinkSpeed)" }
    }
}
catch { Write-Warning "Could not enumerate adapters: $($_.Exception.Message)" }

# --- default routes (split-tunnel visibility) ---
Write-Section 'Default routes (lowest metric first)'
try {
    $routes = Get-NetRoute -AddressFamily IPv4 -DestinationPrefix '0.0.0.0/0' -ErrorAction Stop |
        Sort-Object RouteMetric |
        Select-Object InterfaceAlias, NextHop, RouteMetric, InterfaceMetric
    $routes | Format-Table -AutoSize | Out-String | Write-Host
    $posture.DefaultRoutes = $routes | ForEach-Object {
        @{ Interface = $_.InterfaceAlias; NextHop = $_.NextHop; RouteMetric = $_.RouteMetric; InterfaceMetric = $_.InterfaceMetric }
    }
}
catch { Write-Warning "Could not read routes: $($_.Exception.Message)" }

# --- write evidence file ---
$stamp = (Get-Date).ToString('yyyyMMdd-HHmmss')
$file = Join-Path -Path $OutputPath -ChildPath ("netdx-discovery-{0}-{1}.json" -f $env:COMPUTERNAME, $stamp)
$posture | ConvertTo-Json -Depth 6 | Set-Content -Path $file -Encoding UTF8

Write-Section 'Done'
Write-Host "Posture saved to: $file" -ForegroundColor Green
