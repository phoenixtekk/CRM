<#
.SYNOPSIS
    NETLOGONDX-Validation.ps1 — assert domain secure-channel & Netlogon health (read-only, pass/fail).
.DESCRIPTION
    PURPOSE
        Runs LOCALLY and returns a clear PASS/FAIL verdict against the four things that must be true
        for a domain-joined Windows device to authenticate without Netlogon 5719:
          1. the machine secure channel is healthy (Test-ComputerSecureChannel),
          2. Windows Time is in sync with a domain controller (Kerberos skew < 5 minutes),
          3. DNS resolves the domain DC locator SRV records (_ldap._tcp.dc._msdcs.<domain>),
          4. IPv6 is NOT invalidly disabled (DisabledComponents is 0x0, or a supported value).
        Designed to double as an Intune Proactive Remediations DETECTION script: it exits 0 when the
        device is healthy (compliant) and exits 1 when any check fails (triggers the paired
        NETLOGONDX-Remediation.ps1). Read-only — it never changes anything.
    HOW TO RUN
        Local, elevated:
          powershell -ExecutionPolicy Bypass -File .\NETLOGONDX-Validation.ps1
        As an Intune Proactive Remediations detection script:
          Reports (Endpoint analytics) > Proactive remediations > Create script package
          Detection script = NETLOGONDX-Validation.ps1  ·  Remediation script = NETLOGONDX-Remediation.ps1
          Run this script using the logged-on credentials = No (runs as SYSTEM);  64-bit PowerShell = Yes.
    EXPECTED RESULTS
        A PASS/FAIL table and an overall verdict. Exit code 0 = HEALTHY, exit code 1 = ISSUES FOUND.
.NOTES
    White-label — the repeatable way. Read-only diagnostics.
#>
[CmdletBinding()]
param(
    [int]$MaxTimeSkewSeconds = 300
)

$ErrorActionPreference = 'Continue'
$results = New-Object System.Collections.Generic.List[object]
function R($Name, $Pass, $Detail) {
    $results.Add([pscustomobject]@{ Check = $Name; Result = $(if ($Pass) { 'PASS' } else { 'FAIL' }); Detail = "$Detail" })
}

$cs = Get-CimInstance Win32_ComputerSystem -ErrorAction SilentlyContinue
$domain = $env:USERDNSDOMAIN; if (-not $domain -and $cs) { $domain = $cs.Domain }
if (-not [bool]$cs.PartOfDomain) {
    Write-Host 'Device is not domain-joined — nothing to validate.' -ForegroundColor Yellow
    exit 0
}

# 1) Secure channel
$scOk = $false
try { $scOk = Test-ComputerSecureChannel -ErrorAction Stop } catch { $scOk = $false }
R 'Secure channel healthy' $scOk "Test-ComputerSecureChannel=$scOk"

# Locate a DC for the time + DNS checks
$dsGetDc = (& nltest.exe "/dsgetdc:$domain" 2>&1) -join "`n"
$dcName = $null
if ($dsGetDc -match 'DC:\s*\\\\([^\s]+)') { $dcName = $Matches[1] }
elseif ($env:LOGONSERVER) { $dcName = $env:LOGONSERVER.TrimStart('\') }

# 2) Time in sync
$skewSec = $null
if ($dcName) {
    $strip = (& w32tm.exe /stripchart "/computer:$dcName" /samples:1 /dataonly 2>&1) -join "`n"
    if ($strip -match '([-+]?\d+\.\d+)s') { $skewSec = [double]$Matches[1] }
}
$timeOk = ($null -ne $skewSec -and [math]::Abs($skewSec) -lt $MaxTimeSkewSeconds)
R 'Time in sync with DC (Kerberos skew)' $timeOk $(if ($null -ne $skewSec) { "Offset ~$([math]::Round($skewSec,1))s vs $dcName" } else { "Could not measure offset vs $dcName" })

# 3) DNS resolves DC SRV records
$srv = "_ldap._tcp.dc._msdcs.$domain"
$srvOk = $false; $srvDetail = 'not resolved'
try {
    $rr = Resolve-DnsName -Name $srv -Type SRV -ErrorAction Stop
    $srvOk = @($rr | Where-Object Type -eq 'SRV').Count -gt 0
    $srvDetail = ($rr | Where-Object Type -eq 'SRV' | Select-Object -First 2 -ExpandProperty NameTarget) -join ', '
} catch { $srvDetail = $_.Exception.Message }
R 'DNS resolves domain DCs (SRV)' $srvOk "$srv -> $srvDetail"

# 4) IPv6 not invalidly disabled
$dc6 = (Get-ItemProperty -Path 'HKLM:\SYSTEM\CurrentControlSet\Services\Tcpip6\Parameters' -Name DisabledComponents -ErrorAction SilentlyContinue).DisabledComponents
$dc6Hex = if ($null -ne $dc6) { '0x{0:x}' -f $dc6 } else { '(absent=0x0)' }
# Supported values: 0x0 (recommended default), 0x20 (prefer IPv4), 0x11 (disable non-tunnel+tunnel). All keep the OS supported.
$ipv6Ok = ($null -eq $dc6 -or $dc6 -eq 0 -or $dc6 -eq 0x20 -or $dc6 -eq 0x11)
R 'IPv6 not invalidly disabled' $ipv6Ok $(if ($ipv6Ok) { "$dc6Hex (supported)" } else { "$dc6Hex is INVALID/unsupported — reset to 0x0" })

$results | Format-Table -AutoSize
$fail = @($results | Where-Object Result -eq 'FAIL').Count
Write-Host ''
if ($fail -eq 0) {
    Write-Host 'OVERALL: HEALTHY — secure channel, time, DNS, and IPv6 config are all good.' -ForegroundColor Green
    exit 0
} else {
    Write-Host "OVERALL: ISSUES FOUND — $fail check(s) failed. Run NETLOGONDX-Remediation.ps1 (-WhatIf first)." -ForegroundColor Yellow
    exit 1
}
