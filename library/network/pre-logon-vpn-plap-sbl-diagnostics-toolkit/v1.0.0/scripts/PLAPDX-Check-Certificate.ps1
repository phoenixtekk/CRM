<#
.SYNOPSIS
    PLAPDX-Check-Certificate.ps1 — machine-certificate deep-check for pre-logon VPN authentication.
.DESCRIPTION
    PURPOSE
        For each candidate machine certificate in LocalMachine\My, checks the facts pre-logon VPN
        authentication depends on: present, not expired (and not yet-valid), Client Authentication EKU,
        chains to a trusted root, and a private key present. Optionally confirm the expected issuing CA
        with -CaThumbprint. This is the certificate that backs both the AOVPN device tunnel and (where
        cert auth is used) the SBL/PLAP connect. Read-only: it inspects, never modifies, the store.
    HOW TO RUN
        Run ELEVATED (private-key visibility for LocalMachine\My needs it):
            powershell -ExecutionPolicy Bypass -File .\PLAPDX-Check-Certificate.ps1
            powershell -ExecutionPolicy Bypass -File .\PLAPDX-Check-Certificate.ps1 -CaThumbprint <expected-issuing-CA-thumbprint>
        No Microsoft Graph scopes needed — this is a local device check.
    EXPECTED RESULTS
        A per-certificate PASS/FAIL table (private key, expiry, Client Auth EKU, chain, and — with
        -CaThumbprint — issued-by-expected-CA). At least one PASS => the cert side is healthy; if the
        gateway still rejects it, the head-end likely does not trust the issuing CA (vendor-deferred).
        No client-auth cert / none pass => fix the trusted root + SCEP cert (see 06-troubleshooting.md).
.NOTES
    White-label — the repeatable way. Read-only local inspection. VPN head-end / gateway internals deferred to vendor docs.
#>

[CmdletBinding()]
param(
    [string] $CaThumbprint,
    [string] $IssuerLike
)

$ErrorActionPreference = 'Continue'
Write-Host "=== Pre-Logon VPN — Machine Certificate Deep-Check ===" -ForegroundColor Cyan
Write-Host "Device: $env:COMPUTERNAME (scanning Cert:\LocalMachine\My, read-only)`n"

$clientAuthOid = '1.3.6.1.5.5.7.3.2'
$results = [System.Collections.Generic.List[object]]::new()

foreach ($c in (Get-ChildItem Cert:\LocalMachine\My -ErrorAction SilentlyContinue)) {
    if ($IssuerLike -and ($c.Issuer -notlike "*$IssuerLike*")) { continue }

    $hasClientAuth = $false
    foreach ($eku in $c.EnhancedKeyUsageList) { if ($eku.ObjectId -eq $clientAuthOid -or $eku.FriendlyName -eq 'Client Authentication') { $hasClientAuth = $true } }
    $ekuEmpty = (@($c.EnhancedKeyUsageList).Count -eq 0)
    # Only consider certs that could be VPN client certs: client-auth EKU, or no EKU at all.
    if (-not $hasClientAuth -and -not $ekuEmpty) { continue }

    $now     = Get-Date
    $expired = $c.NotAfter -lt $now
    $notYet  = $c.NotBefore -gt $now

    $chain = New-Object System.Security.Cryptography.X509Certificates.X509Chain
    $chain.ChainPolicy.RevocationMode = [System.Security.Cryptography.X509Certificates.X509RevocationMode]::NoCheck
    $chainOk = $false; $chainMsg = ''
    try {
        $chainOk = $chain.Build($c)
        if (-not $chainOk) { $chainMsg = ($chain.ChainStatus | ForEach-Object { $_.Status.ToString() }) -join '; ' }
    } catch { $chainMsg = $_.Exception.Message }

    $issuerMatch = $null
    if ($CaThumbprint) {
        $issuerCert = $chain.ChainElements | Select-Object -Skip 1 -First 1
        $issuerMatch = ($issuerCert -and $issuerCert.Certificate.Thumbprint -eq $CaThumbprint)
    }

    $pass = ($c.HasPrivateKey -and -not $expired -and -not $notYet -and ($hasClientAuth -or $ekuEmpty) -and $chainOk)
    if ($CaThumbprint) { $pass = $pass -and $issuerMatch }

    $results.Add([pscustomobject]@{
        Subject       = $c.Subject
        Issuer        = $c.Issuer
        Thumbprint    = $c.Thumbprint
        NotAfter      = $c.NotAfter
        HasPrivateKey = $c.HasPrivateKey
        ClientAuthEku = $hasClientAuth
        Expired       = $expired
        NotYetValid   = $notYet
        ChainValid    = $chainOk
        ChainStatus   = if ($chainMsg) { $chainMsg } else { 'OK' }
        IssuerMatch   = if ($null -eq $issuerMatch) { 'n/a' } else { $issuerMatch }
        Result        = if ($pass) { 'PASS' } else { 'FAIL' }
    })
}

if ($results.Count -eq 0) {
    Write-Host "RESULT: No client-authentication machine certificate found in LocalMachine\My." -ForegroundColor Yellow
    Write-Host "  Remedy: deploy Pre-Logon VPN - Trusted Root, then Pre-Logon VPN - Device Cert (SCEP); re-sync." -ForegroundColor Yellow
    Write-Host "  See 06-troubleshooting.md (Certificate)." -ForegroundColor Yellow
    return
}

$results | Format-Table Result, HasPrivateKey, Expired, ClientAuthEku, ChainValid, IssuerMatch, ChainStatus, Issuer -AutoSize -Wrap
$passing = @($results | Where-Object { $_.Result -eq 'PASS' })
Write-Host ""
if ($passing.Count -gt 0) {
    Write-Host "RESULT: $($passing.Count) machine certificate(s) PASS. The cert side is healthy." -ForegroundColor Green
    Write-Host "  If the gateway still rejects auth, the head-end likely does not trust the issuing CA (vendor-deferred, see 06-troubleshooting.md)." -ForegroundColor Gray
} else {
    Write-Host "RESULT: certificate(s) present but none pass — fix the failing fact above." -ForegroundColor Yellow
    Write-Host "  Common: missing Client Auth EKU, expired, no private key, or untrusted chain (deploy Pre-Logon VPN - Trusted Root first)." -ForegroundColor Yellow
    Write-Host "  See 06-troubleshooting.md (Certificate)." -ForegroundColor Yellow
}
