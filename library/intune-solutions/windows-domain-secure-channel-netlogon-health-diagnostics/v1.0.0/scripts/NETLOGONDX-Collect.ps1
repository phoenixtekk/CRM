<#
.SYNOPSIS
    NETLOGONDX-Collect.ps1 — bundle secure-channel & Netlogon diagnostics into one ZIP for escalation.
.DESCRIPTION
    PURPOSE
        Gathers everything a support engineer (or a Microsoft support case) needs to diagnose a
        stubborn Netlogon 5719 / secure-channel problem, and packages it into a single timestamped ZIP
        you can attach to a ticket. It collects (read-only):
          - the relevant System-log events (NETLOGON, Time-Service, and Kerberos client events),
          - nltest output (/sc_query, /dsgetdc, /dclist),
          - ipconfig /all and the client DNS server list,
          - w32tm /query status and configuration,
          - the IPv6 DisabledComponents registry value,
          - the JSON/CSV/TXT output from the other NETLOGONDX scripts if present.
        It changes nothing on the device — it only reads and copies. No credentials or secrets are
        written into the bundle.
    HOW TO RUN
        Local, elevated:
          powershell -ExecutionPolicy Bypass -File .\NETLOGONDX-Collect.ps1
        Optional: -OutputDir C:\ProgramData\NETLOGONDX  -EventLookbackDays 30
        At scale: run under SYSTEM via Intune Proactive Remediations, then retrieve the ZIP from the
        device (e.g. with a follow-up collection package or your endpoint tooling).
    EXPECTED RESULTS
        A ZIP at <OutputDir>\NETLOGONDX-Collect-<host>-<timestamp>.zip containing the text/CSV/JSON
        artifacts above, and the path printed to the console.
.NOTES
    White-label — the repeatable way. Read-only diagnostics.
#>
[CmdletBinding()]
param(
    [string]$OutputDir = "$env:ProgramData\NETLOGONDX",
    [int]$EventLookbackDays = 30
)

$ErrorActionPreference = 'Continue'
$stamp = (Get-Date).ToString('yyyyMMdd-HHmmss')
$staging = Join-Path $OutputDir "collect-$stamp"
New-Item -ItemType Directory -Path $staging -Force | Out-Null

$cs = Get-CimInstance Win32_ComputerSystem -ErrorAction SilentlyContinue
$domain = $env:USERDNSDOMAIN; if (-not $domain -and $cs) { $domain = $cs.Domain }

function Save($name, $content) { $content | Out-File -FilePath (Join-Path $staging $name) -Encoding UTF8 }

# System-log events
$since = (Get-Date).AddDays(-1 * [math]::Abs($EventLookbackDays))
$providers = 'NETLOGON', 'Microsoft-Windows-Time-Service', 'Microsoft-Windows-Kerberos'
$evts = @()
foreach ($p in $providers) {
    try { $evts += Get-WinEvent -FilterHashtable @{ LogName = 'System'; ProviderName = $p; StartTime = $since } -ErrorAction Stop } catch {}
}
$evts | Sort-Object TimeCreated |
    Select-Object TimeCreated, Id, ProviderName, LevelDisplayName, @{n = 'Message'; e = { ($_.Message -replace '\s+', ' ').Trim() } } |
    Format-Table -AutoSize | Out-String | ForEach-Object { Save 'events-system.txt' $_ }

# nltest
Save 'nltest-sc_query.txt' ((& nltest.exe "/sc_query:$domain" 2>&1) -join "`n")
Save 'nltest-dsgetdc.txt'  ((& nltest.exe "/dsgetdc:$domain" 2>&1) -join "`n")
Save 'nltest-dclist.txt'   ((& nltest.exe "/dclist:$domain" 2>&1) -join "`n")

# Network + DNS
Save 'ipconfig-all.txt' ((& ipconfig.exe /all 2>&1) -join "`n")
try {
    $dns = Get-DnsClientServerAddress -ErrorAction Stop | Format-Table -AutoSize | Out-String
    Save 'dns-servers.txt' $dns
} catch {}
try { Save 'srv-record.txt' ((Resolve-DnsName -Name "_ldap._tcp.dc._msdcs.$domain" -Type SRV -ErrorAction Stop | Format-Table -AutoSize | Out-String)) } catch { Save 'srv-record.txt' $_.Exception.Message }

# Time service
Save 'w32tm-status.txt' ((& w32tm.exe /query /status 2>&1) -join "`n")
Save 'w32tm-config.txt' ((& w32tm.exe /query /configuration 2>&1) -join "`n")

# Secure channel state
try { Save 'securechannel.txt' ("Test-ComputerSecureChannel = " + (Test-ComputerSecureChannel -ErrorAction Stop)) } catch { Save 'securechannel.txt' "Test-ComputerSecureChannel error: $($_.Exception.Message)" }

# IPv6 DisabledComponents
$dc6 = (Get-ItemProperty -Path 'HKLM:\SYSTEM\CurrentControlSet\Services\Tcpip6\Parameters' -Name DisabledComponents -ErrorAction SilentlyContinue).DisabledComponents
$dc6Hex = if ($null -ne $dc6) { '0x{0:x}' -f $dc6 } else { '(absent = default 0x0)' }
Save 'ipv6-disabledcomponents.txt' "Tcpip6\Parameters\DisabledComponents = $dc6Hex`nSupported: 0x0 (recommended), 0x20, 0x11. Anything else is unsupported — reset to 0x0."

# Pull in prior NETLOGONDX outputs if present
foreach ($f in 'NETLOGONDX-Discovery.json', 'NETLOGONDX-Discovery.txt', 'NETLOGONDX-Report.txt', 'NETLOGONDX-Report.csv') {
    $src = Join-Path $OutputDir $f
    if (Test-Path $src) { Copy-Item $src -Destination $staging -Force -ErrorAction SilentlyContinue }
}

# Manifest
Save 'MANIFEST.txt' ("NETLOGONDX escalation bundle`nHost: $env:COMPUTERNAME`nDomain: $domain`nCollected: $((Get-Date).ToString('s'))`nLookback (days): $EventLookbackDays")

# Zip it
$zip = Join-Path $OutputDir "NETLOGONDX-Collect-$($env:COMPUTERNAME)-$stamp.zip"
if (Test-Path $zip) { Remove-Item $zip -Force }
Compress-Archive -Path (Join-Path $staging '*') -DestinationPath $zip -Force
Remove-Item $staging -Recurse -Force -ErrorAction SilentlyContinue

Write-Host "Escalation bundle created:" -ForegroundColor Green
Write-Host "  $zip"
Write-Host 'Attach this ZIP to your support ticket. It contains no credentials or secrets.' -ForegroundColor DarkGray
