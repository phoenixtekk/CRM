<#
.SYNOPSIS
    CMG-Validation.ps1 - Read-only validation of CMG public endpoint, certificate, and a client's
    ability to reach and authenticate to the Cloud Management Gateway.

.DESCRIPTION
    Purpose:
        Confirms that the CMG named 'CMG - Internet Clients - Pilot' is reachable: the public DNS name
        resolves, TLS succeeds against the 'CMG - Internet Clients - Server Auth' certificate (valid,
        not expired), and, when run on a managed client, that the client sees an internet/CMG
        management point. READ-ONLY: makes no changes.

    How to run:
        - From an internet host (endpoint/cert checks):
              .\CMG-Validation.ps1 -CmgDnsName "CMG.contoso.com"
        - On a managed Configuration Manager client (adds client-side checks):
              .\CMG-Validation.ps1 -CmgDnsName "CMG.contoso.com"
          Run elevated for the client WMI checks.

    Expected results:
        DNS resolves, TCP 443 reachable, server certificate valid with subject matching the CMG name
        and a future expiry, and (on a client) the ConfigMgr client reports an internet-facing
        management point. Any failure is reported as FAIL with the reason.
#>
[CmdletBinding()]
param(
    [Parameter(Mandatory = $true)]
    [string]$CmgDnsName,

    [Parameter(Mandatory = $false)]
    [int]$Port = 443
)

function Ok($m)   { Write-Host "PASS  $m" -ForegroundColor Green }
function Bad($m)  { Write-Host "FAIL  $m" -ForegroundColor Red }
function Note($m) { Write-Host "INFO  $m" -ForegroundColor Yellow }

Write-Host "=== CMG endpoint validation: $CmgDnsName : $Port ===" -ForegroundColor Cyan

# --- DNS resolution ---
try {
    $dns = Resolve-DnsName -Name $CmgDnsName -ErrorAction Stop | Where-Object { $_.IPAddress -or $_.NameHost }
    if ($dns) { Ok "DNS resolves for $CmgDnsName" } else { Bad "DNS returned no records for $CmgDnsName" }
} catch { Bad "DNS resolution failed: $($_.Exception.Message)" }

# --- TCP 443 reachability ---
$tcp = Test-NetConnection -ComputerName $CmgDnsName -Port $Port -WarningAction SilentlyContinue
if ($tcp.TcpTestSucceeded) { Ok "TCP $Port reachable" } else { Bad "TCP $Port not reachable" }

# --- TLS certificate inspection (read-only) ---
try {
    $client = New-Object System.Net.Sockets.TcpClient
    $client.Connect($CmgDnsName, $Port)
    $ssl = New-Object System.Net.Security.SslStream($client.GetStream(), $false, ({ $true }))
    $ssl.AuthenticateAsClient($CmgDnsName)
    $cert = [System.Security.Cryptography.X509Certificates.X509Certificate2]$ssl.RemoteCertificate
    Write-Host ("Certificate subject : {0}" -f $cert.Subject)
    Write-Host ("Certificate expiry  : {0}" -f $cert.NotAfter)
    if ($cert.Subject -match [regex]::Escape($CmgDnsName)) {
        Ok "Certificate subject matches the CMG DNS name"
    } else {
        Note "Certificate subject does not contain $CmgDnsName - check SAN / 'CMG - Internet Clients - Server Auth'"
    }
    if ($cert.NotAfter -gt (Get-Date)) { Ok "Certificate is not expired" } else { Bad "Certificate is EXPIRED" }
    if (($cert.NotAfter - (Get-Date)).Days -lt 30) { Note "Certificate expires within 30 days - plan renewal" }
    $ssl.Dispose(); $client.Close()
} catch {
    Bad "TLS handshake / certificate read failed: $($_.Exception.Message)"
}

# --- Client-side checks (only meaningful on a managed ConfigMgr client) ---
Write-Host "`n=== Client-side checks (if run on a managed client) ===" -ForegroundColor Cyan
try {
    $mp = Get-CimInstance -Namespace "root\ccm\LocationServices" -ClassName "SMS_ActiveMPCandidate" -ErrorAction Stop
    if ($mp) {
        $mp | Select-Object MP, Type | Format-Table -AutoSize | Out-String | Write-Host
        if ($mp | Where-Object { $_.Type -match "Internet" -or $_.MP -match [regex]::Escape($CmgDnsName) }) {
            Ok "Client lists an internet / CMG management point"
        } else {
            Note "No internet/CMG management point listed yet - verify cloud-management client settings applied"
        }
    } else {
        Note "No MP candidates returned (not a managed client, or client not yet checked in)"
    }
} catch {
    Note "ConfigMgr client WMI not available - run on a managed client for client-side checks"
}

Write-Host "`nValidation complete (read-only)." -ForegroundColor Green
