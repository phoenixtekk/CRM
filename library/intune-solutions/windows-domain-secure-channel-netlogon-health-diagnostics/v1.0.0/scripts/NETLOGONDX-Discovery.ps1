<#
.SYNOPSIS
    NETLOGONDX-Discovery.ps1 — collect Windows domain secure-channel & Netlogon health signals (read-only).
.DESCRIPTION
    PURPOSE
        Runs LOCALLY on an affected domain-joined Windows device and gathers the full root-cause
        picture behind Netlogon Event ID 5719 ("There are currently no logon servers available" /
        broken secure channel) in one pass:
          - recent NETLOGON Event ID 5719 and related secure-channel events from the System log,
          - the machine secure channel state (Test-ComputerSecureChannel),
          - the domain-controller locator view (nltest /sc_query and nltest /dsgetdc),
          - DNS resolution of the domain SRV locator records (_ldap._tcp.dc._msdcs.<domain>),
          - the Windows Time (w32tm) synchronization state and source,
          - TCP reachability to a domain controller on ports 88/135/389/445,
          - the IPv6 DisabledComponents registry value under Tcpip6\Parameters.
        This is a DIAGNOSTICS collector — it changes nothing. Pair it with NETLOGONDX-Validation.ps1
        (pass/fail gate) and NETLOGONDX-Remediation.ps1 (safe, -WhatIf-by-default repair).
    HOW TO RUN
        Local, elevated:
          powershell -ExecutionPolicy Bypass -File .\NETLOGONDX-Discovery.ps1
        Optional: -OutputDir C:\ProgramData\NETLOGONDX  -EventLookbackDays 14
        At scale: run under SYSTEM via Intune Proactive Remediations, or as a one-off with any
        endpoint management tool. No modules required — everything uses in-box Windows commands.
    EXPECTED RESULTS
        A per-signal PASS/FAIL/INFO table and an overall summary printed to the console, plus a
        machine-readable copy written to <OutputDir>\NETLOGONDX-Discovery.json and a readable
        transcript at <OutputDir>\NETLOGONDX-Discovery.txt. A healthy device shows: no recent 5719,
        secure channel OK, DCs resolvable, time in sync, DC ports open, IPv6 not invalidly disabled.
.NOTES
    White-label — the repeatable way. Read-only diagnostics.
#>
[CmdletBinding()]
param(
    [string]$OutputDir = "$env:ProgramData\NETLOGONDX",
    [int]$EventLookbackDays = 14
)

$ErrorActionPreference = 'Continue'
if (-not (Test-Path $OutputDir)) { New-Item -ItemType Directory -Path $OutputDir -Force | Out-Null }
try { Start-Transcript -Path (Join-Path $OutputDir 'NETLOGONDX-Discovery.txt') -Force | Out-Null } catch {}

$results = New-Object System.Collections.Generic.List[object]
function Add-Result($Name, $State, $Detail) {
    $results.Add([pscustomobject]@{ Check = $Name; State = $State; Detail = "$Detail" })
}

# --- Identity / domain context -------------------------------------------------
$cs     = Get-CimInstance Win32_ComputerSystem -ErrorAction SilentlyContinue
$domain = $env:USERDNSDOMAIN
if (-not $domain -and $cs) { $domain = $cs.Domain }
$partOfDomain = [bool]($cs.PartOfDomain)
Add-Result 'Domain membership' $(if ($partOfDomain) { 'INFO' } else { 'FAIL' }) "PartOfDomain=$partOfDomain; Domain=$domain; Host=$env:COMPUTERNAME"
if (-not $partOfDomain) { Write-Warning 'Device is not domain-joined — secure-channel checks do not apply.' }

# --- 1) NETLOGON Event ID 5719 + related secure-channel events -----------------
$eventIds = 5719, 5722, 5723, 3210, 3095, 5805, 5807
$since    = (Get-Date).AddDays(-1 * [math]::Abs($EventLookbackDays))
$events = @()
foreach ($provider in 'NETLOGON', 'Netlogon') {
    try {
        $events += Get-WinEvent -FilterHashtable @{ LogName = 'System'; ProviderName = $provider; StartTime = $since } -ErrorAction Stop |
            Where-Object { $eventIds -contains $_.Id }
    } catch {}
}
$events = $events | Sort-Object TimeCreated -Unique
$five719 = @($events | Where-Object Id -eq 5719)
Add-Result 'Netlogon Event ID 5719 (no logon servers / secure session)' $(if ($five719.Count -eq 0) { 'PASS' } else { 'FAIL' }) "$($five719.Count) in last $EventLookbackDays day(s); $($events.Count) related event(s) total"
$eventDetail = @($events | Select-Object -First 10 | ForEach-Object { "{0} Id={1}" -f $_.TimeCreated.ToString('s'), $_.Id })

# --- 2) Machine secure channel -------------------------------------------------
$scOk = $null
if ($partOfDomain) {
    try { $scOk = Test-ComputerSecureChannel -ErrorAction Stop } catch { $scOk = $false }
    Add-Result 'Secure channel (Test-ComputerSecureChannel)' $(if ($scOk) { 'PASS' } else { 'FAIL' }) "Healthy=$scOk"
}

# --- 3) DC locator view (nltest) ----------------------------------------------
$scQuery  = (& nltest.exe "/sc_query:$domain" 2>&1) -join "`n"
$dsGetDc  = (& nltest.exe "/dsgetdc:$domain" 2>&1) -join "`n"
$dcName = $null
if ($dsGetDc -match 'DC:\s*\\\\([^\s]+)') { $dcName = $Matches[1] }
elseif ($env:LOGONSERVER) { $dcName = $env:LOGONSERVER.TrimStart('\') }
$scQueryOk = ($scQuery -match 'Flags:.*NT_STATUS_SUCCESS' -or $scQuery -match 'The command completed successfully' -or $scQuery -match 'Trusted DC Name')
Add-Result 'DC locator (nltest /sc_query, /dsgetdc)' $(if ($dcName) { 'PASS' } else { 'FAIL' }) "Located DC: $dcName"

# --- 4) DNS SRV locator records ------------------------------------------------
$srv = "_ldap._tcp.dc._msdcs.$domain"
$srvOk = $false; $srvDetail = 'not resolved'
if ($domain) {
    try {
        $rr = Resolve-DnsName -Name $srv -Type SRV -ErrorAction Stop
        $srvOk = @($rr | Where-Object { $_.Type -eq 'SRV' }).Count -gt 0
        $srvDetail = ($rr | Where-Object Type -eq 'SRV' | Select-Object -First 3 | ForEach-Object { $_.NameTarget }) -join ', '
    } catch { $srvDetail = $_.Exception.Message }
}
$dnsServers = (Get-DnsClientServerAddress -AddressFamily IPv4 -ErrorAction SilentlyContinue |
    Where-Object { $_.ServerAddresses } | Select-Object -ExpandProperty ServerAddresses -Unique) -join ', '
Add-Result 'DNS resolves domain SRV records' $(if ($srvOk) { 'PASS' } else { 'FAIL' }) "$srv -> $srvDetail | client DNS: $dnsServers"

# --- 5) Windows Time sync ------------------------------------------------------
$w32status = (& w32tm.exe /query /status 2>&1) -join "`n"
$timeSvc   = Get-Service w32time -ErrorAction SilentlyContinue
$skewSec = $null; $timeState = 'INFO'
if ($dcName) {
    $strip = (& w32tm.exe /stripchart "/computer:$dcName" /samples:1 /dataonly 2>&1) -join "`n"
    if ($strip -match '([-+]?\d+\.\d+)s') { $skewSec = [double]$Matches[1] }
}
if ($null -ne $skewSec) {
    $timeState = $(if ([math]::Abs($skewSec) -lt 300) { 'PASS' } else { 'FAIL' })
    Add-Result 'Time in sync with DC (< 5 min / Kerberos skew)' $timeState ("Offset ~{0}s vs {1}; w32time={2}" -f $skewSec, $dcName, $timeSvc.Status)
} else {
    Add-Result 'Windows Time state' $(if ($timeSvc.Status -eq 'Running') { 'INFO' } else { 'FAIL' }) "w32time=$($timeSvc.Status); could not measure offset"
}

# --- 6) DC port reachability (88 Kerberos, 135 RPC EPM, 389 LDAP, 445 SMB) ------
function Test-TcpPort($ComputerName, $Port, $TimeoutMs = 1500) {
    if (-not $ComputerName) { return $false }
    try {
        $client = New-Object System.Net.Sockets.TcpClient
        $iar = $client.BeginConnect($ComputerName, $Port, $null, $null)
        $ok = $iar.AsyncWaitHandle.WaitOne($TimeoutMs, $false)
        if ($ok -and $client.Connected) { $client.EndConnect($iar); $client.Close(); return $true }
        $client.Close(); return $false
    } catch { return $false }
}
$ports = 88, 135, 389, 445
$portStates = @()
foreach ($p in $ports) { $portStates += "{0}:{1}" -f $p, $(if (Test-TcpPort $dcName $p) { 'open' } else { 'blocked' }) }
$portsAllOpen = ($portStates -notmatch 'blocked').Count -eq $ports.Count -and $dcName
Add-Result 'DC ports reachable (88/135/389/445)' $(if ($portsAllOpen) { 'PASS' } else { 'FAIL' }) "$dcName -> $($portStates -join ', ')"

# --- 7) IPv6 DisabledComponents ------------------------------------------------
$ipv6Path = 'HKLM:\SYSTEM\CurrentControlSet\Services\Tcpip6\Parameters'
$dc6 = (Get-ItemProperty -Path $ipv6Path -Name DisabledComponents -ErrorAction SilentlyContinue).DisabledComponents
$dc6Hex = if ($null -ne $dc6) { '0x{0:x}' -f $dc6 } else { '(absent = default 0x0)' }
# Recommended: 0x0 (default, IPv6 enabled dual-stack). Supported-with-justification: 0x20, 0x11.
# Invalid / unsupported-by-Microsoft-testing (e.g. 0xffffffff, 0xff): correct back to 0x0.
$ipv6State = 'PASS'; $ipv6Note = 'IPv6 enabled (recommended dual-stack default)'
if ($null -ne $dc6 -and $dc6 -ne 0) {
    if ($dc6 -eq 0x20) { $ipv6State = 'INFO'; $ipv6Note = 'Prefer IPv4 (0x20) — IPv6 still enabled; acceptable with justification' }
    elseif ($dc6 -eq 0x11) { $ipv6State = 'INFO'; $ipv6Note = 'Disable IPv6 on non-tunnel+tunnel interfaces (0x11) — acceptable ONLY with justification' }
    else { $ipv6State = 'FAIL'; $ipv6Note = "INVALID/unsupported value — Microsoft does not test this. Recommend resetting to 0x0. Disabling IPv6 breaks DirectAccess/Remote Assistance/HomeGroup." }
}
Add-Result 'IPv6 DisabledComponents (recommended config)' $ipv6State "$dc6Hex — $ipv6Note"

# --- Output --------------------------------------------------------------------
$results | Format-Table -AutoSize
if ($eventDetail) { Write-Host ''; Write-Host 'Recent Netlogon/secure-channel events:' -ForegroundColor Cyan; $eventDetail | ForEach-Object { Write-Host "  $_" } }

$payload = [ordered]@{
    Host              = $env:COMPUTERNAME
    Domain            = $domain
    CollectedUtc      = (Get-Date).ToUniversalTime().ToString('o')
    DomainController  = $dcName
    SecureChannelOk   = $scOk
    Event5719Count    = $five719.Count
    TimeOffsetSeconds = $skewSec
    Ipv6DisabledComponents = $dc6Hex
    DcPorts           = $portStates
    Checks            = $results
}
$jsonPath = Join-Path $OutputDir 'NETLOGONDX-Discovery.json'
$payload | ConvertTo-Json -Depth 6 | Set-Content -Path $jsonPath -Encoding UTF8

$fail = @($results | Where-Object State -eq 'FAIL').Count
Write-Host ''
if ($fail -eq 0) { Write-Host 'OVERALL: HEALTHY — no secure-channel / Netlogon issues detected.' -ForegroundColor Green }
else { Write-Host "OVERALL: ISSUES FOUND — $fail signal(s) failing. See NETLOGONDX-Report.ps1 and Remediation." -ForegroundColor Yellow }
Write-Host "Saved: $jsonPath" -ForegroundColor DarkGray
try { Stop-Transcript | Out-Null } catch {}
