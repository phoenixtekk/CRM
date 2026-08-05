<#
.SYNOPSIS
    NETLOGONDX-Report.ps1 — readable + CSV health summary for domain secure-channel & Netlogon (read-only).
.DESCRIPTION
    PURPOSE
        Produces a single, human-readable health summary of a device's domain secure-channel and
        Netlogon posture, and writes a one-row CSV suitable for fleet roll-up (collect the CSVs from
        many devices to see coverage before/after a remediation wave). It reports the same signals the
        Discovery collector gathers — secure channel, DC locator, DNS SRV, time sync, DC port
        reachability (88/135/389/445), IPv6 DisabledComponents, and recent Event ID 5719 count —
        as a compact Healthy/Attention verdict per signal. Read-only.
    HOW TO RUN
        Local, elevated:
          powershell -ExecutionPolicy Bypass -File .\NETLOGONDX-Report.ps1
        Optional: -OutputDir C:\ProgramData\NETLOGONDX  -EventLookbackDays 14
        At scale: run under SYSTEM via Intune Proactive Remediations (as an additional detection
        package) and harvest <OutputDir>\NETLOGONDX-Report.csv from each device.
    EXPECTED RESULTS
        A formatted summary printed to the console and written to <OutputDir>\NETLOGONDX-Report.txt,
        plus a single-row <OutputDir>\NETLOGONDX-Report.csv. Overall = HEALTHY when every signal is OK.
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

$cs = Get-CimInstance Win32_ComputerSystem -ErrorAction SilentlyContinue
$domain = $env:USERDNSDOMAIN; if (-not $domain -and $cs) { $domain = $cs.Domain }
$partOfDomain = [bool]$cs.PartOfDomain

function Verdict($ok) { if ($ok) { 'Healthy' } else { 'Attention' } }

# Secure channel
$scOk = $null
if ($partOfDomain) { try { $scOk = Test-ComputerSecureChannel -ErrorAction Stop } catch { $scOk = $false } }

# DC locator
$dsGetDc = (& nltest.exe "/dsgetdc:$domain" 2>&1) -join "`n"
$dcName = $null
if ($dsGetDc -match 'DC:\s*\\\\([^\s]+)') { $dcName = $Matches[1] } elseif ($env:LOGONSERVER) { $dcName = $env:LOGONSERVER.TrimStart('\') }

# DNS SRV
$srv = "_ldap._tcp.dc._msdcs.$domain"; $srvOk = $false
try { $srvOk = @((Resolve-DnsName -Name $srv -Type SRV -ErrorAction Stop) | Where-Object Type -eq 'SRV').Count -gt 0 } catch {}

# Time
$skewSec = $null
if ($dcName) { $strip = (& w32tm.exe /stripchart "/computer:$dcName" /samples:1 /dataonly 2>&1) -join "`n"; if ($strip -match '([-+]?\d+\.\d+)s') { $skewSec = [double]$Matches[1] } }
$timeOk = ($null -ne $skewSec -and [math]::Abs($skewSec) -lt 300)

# DC ports
function Test-TcpPort($ComputerName, $Port, $TimeoutMs = 1500) {
    if (-not $ComputerName) { return $false }
    try { $c = New-Object System.Net.Sockets.TcpClient; $iar = $c.BeginConnect($ComputerName, $Port, $null, $null)
        $ok = $iar.AsyncWaitHandle.WaitOne($TimeoutMs, $false); if ($ok -and $c.Connected) { $c.EndConnect($iar); $c.Close(); return $true }; $c.Close(); return $false } catch { return $false }
}
$ports = 88, 135, 389, 445
$portMap = @{}; foreach ($p in $ports) { $portMap[$p] = (Test-TcpPort $dcName $p) }
$portsOk = ($dcName -and (@($portMap.Values | Where-Object { $_ }).Count -eq $ports.Count))

# IPv6
$dc6 = (Get-ItemProperty -Path 'HKLM:\SYSTEM\CurrentControlSet\Services\Tcpip6\Parameters' -Name DisabledComponents -ErrorAction SilentlyContinue).DisabledComponents
$dc6Hex = if ($null -ne $dc6) { '0x{0:x}' -f $dc6 } else { '0x0 (absent)' }
$ipv6Ok = ($null -eq $dc6 -or $dc6 -eq 0 -or $dc6 -eq 0x20 -or $dc6 -eq 0x11)

# Event 5719
$since = (Get-Date).AddDays(-1 * [math]::Abs($EventLookbackDays)); $count5719 = 0
try { $count5719 = @(Get-WinEvent -FilterHashtable @{ LogName = 'System'; ProviderName = 'NETLOGON'; Id = 5719; StartTime = $since } -ErrorAction Stop).Count } catch {}

$rows = @(
    [pscustomobject]@{ Signal = 'Secure channel';        Verdict = (Verdict $scOk);    Detail = "Test-ComputerSecureChannel=$scOk" }
    [pscustomobject]@{ Signal = 'DC locator';            Verdict = (Verdict ([bool]$dcName)); Detail = "DC=$dcName" }
    [pscustomobject]@{ Signal = 'DNS SRV (DC locator)';  Verdict = (Verdict $srvOk);   Detail = $srv }
    [pscustomobject]@{ Signal = 'Time sync';             Verdict = (Verdict $timeOk);  Detail = $(if ($null -ne $skewSec) { "offset ~$([math]::Round($skewSec,1))s" } else { 'not measured' }) }
    [pscustomobject]@{ Signal = 'DC ports 88/135/389/445'; Verdict = (Verdict $portsOk); Detail = (($ports | ForEach-Object { "{0}:{1}" -f $_, $(if ($portMap[$_]) { 'open' } else { 'blocked' }) }) -join ' ') }
    [pscustomobject]@{ Signal = 'IPv6 config';           Verdict = (Verdict $ipv6Ok);  Detail = "DisabledComponents=$dc6Hex" }
    [pscustomobject]@{ Signal = 'Event 5719 (recent)';   Verdict = (Verdict ($count5719 -eq 0)); Detail = "$count5719 in $EventLookbackDays day(s)" }
)

$overall = if (@($rows | Where-Object Verdict -eq 'Attention').Count -eq 0) { 'HEALTHY' } else { 'NEEDS ATTENTION' }

$txt = @()
$txt += "NETLOGONDX Health Summary"
$txt += "Host: $env:COMPUTERNAME    Domain: $domain    Generated: $((Get-Date).ToString('s'))"
$txt += ('-' * 72)
$txt += ($rows | Format-Table -AutoSize | Out-String)
$txt += "OVERALL: $overall"
$txt -join "`n" | Tee-Object -FilePath (Join-Path $OutputDir 'NETLOGONDX-Report.txt')

# One-row CSV for fleet roll-up
[pscustomobject]@{
    Host = $env:COMPUTERNAME; Domain = $domain; Generated = (Get-Date).ToString('s'); Overall = $overall
    SecureChannel = (Verdict $scOk); DC = $dcName; DnsSrv = (Verdict $srvOk); TimeSync = (Verdict $timeOk)
    DcPorts = (Verdict $portsOk); Ipv6 = $dc6Hex; Ipv6Ok = (Verdict $ipv6Ok); Event5719 = $count5719
} | Export-Csv -Path (Join-Path $OutputDir 'NETLOGONDX-Report.csv') -NoTypeInformation

Write-Host ''
Write-Host "OVERALL: $overall" -ForegroundColor $(if ($overall -eq 'HEALTHY') { 'Green' } else { 'Yellow' })
Write-Host "Saved: $(Join-Path $OutputDir 'NETLOGONDX-Report.csv')" -ForegroundColor DarkGray
