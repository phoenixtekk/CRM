<#
.SYNOPSIS
    CISEDIAG-Validate-Certificate.ps1 — validate the VPN client-authentication certificate and full chain on this device.
.DESCRIPTION
    PURPOSE
        Checks, for each candidate client-authentication certificate in this device's stores, the L1
        facts EAP-TLS depends on: private key present, not expired, Client Authentication EKU, a
        complete chain to a trusted root, and revocation status. Isolates Branch A (no cert) vs.
        Branch B (cert present but chain/trust broken). Optionally filter by issuer with -IssuerLike
        (for example 'your-issuing-ca-name'). Read-only: it inspects, never modifies, the store.
    HOW TO RUN
        powershell -ExecutionPolicy Bypass -File .\CISEDIAG-Validate-Certificate.ps1
        powershell -ExecutionPolicy Bypass -File .\CISEDIAG-Validate-Certificate.ps1 -IssuerLike "your-issuing-ca-name"
        (no Graph scopes required — this is a local device check)
    EXPECTED RESULTS
        A per-certificate PASS/FAIL table. All-green on one cert => L1 healthy, move to Branch C/D.
        No client-auth cert => Branch A. A cert with a chain error, missing private key, expiry, or
        untrusted root => Branch B (usually the trusted-root certificate profile), which also explains
        an ISE 'certificate chain validation failed' EAP-TLS result at L3.
.NOTES
    White-label — the repeatable way. Read-only. Cisco ISE / Secure Client internals deferred to vendor docs.
#>

[CmdletBinding()]
param(
    [string] $IssuerLike,
    [string] $JsonOut
)

$ErrorActionPreference = 'Continue'
Write-Host "CISEDIAG-Validate-Certificate : scanning device certificate stores (read-only)" -ForegroundColor Cyan

$clientAuthOid = '1.3.6.1.5.5.7.3.2'
$results = [System.Collections.Generic.List[object]]::new()

foreach ($store in @('Cert:\CurrentUser\My','Cert:\LocalMachine\My')) {
    $items = Get-ChildItem $store -ErrorAction SilentlyContinue
    foreach ($c in $items) {
        $hasClientAuth = $false
        foreach ($eku in $c.EnhancedKeyUsageList) {
            if ($eku.ObjectId -eq $clientAuthOid -or $eku.FriendlyName -eq 'Client Authentication') { $hasClientAuth = $true }
        }
        # A cert with NO EKU at all is technically valid for any usage; note but do not require.
        $ekuEmpty = (@($c.EnhancedKeyUsageList).Count -eq 0)
        if (-not $hasClientAuth -and -not $ekuEmpty) { continue }
        if ($IssuerLike -and ($c.Issuer -notlike "*$IssuerLike*")) { continue }

        $now      = Get-Date
        $expired  = $c.NotAfter -lt $now
        $notYet   = $c.NotBefore -gt $now

        # Build and validate the chain, including revocation where reachable.
        $chain = New-Object System.Security.Cryptography.X509Certificates.X509Chain
        $chain.ChainPolicy.RevocationMode = [System.Security.Cryptography.X509Certificates.X509RevocationMode]::Online
        $chain.ChainPolicy.RevocationFlag = [System.Security.Cryptography.X509Certificates.X509RevocationFlag]::EntireChain
        $chainOk  = $false
        $chainMsg = ''
        try {
            $chainOk = $chain.Build($c)
            if (-not $chainOk) {
                $chainMsg = ($chain.ChainStatus | ForEach-Object { $_.Status.ToString() }) -join '; '
            }
        } catch {
            $chainMsg = $_.Exception.Message
        }

        $pass = ($c.HasPrivateKey -and -not $expired -and -not $notYet -and ($hasClientAuth -or $ekuEmpty) -and $chainOk)
        $results.Add([pscustomobject]@{
            Store         = $store
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
            Result        = if ($pass) { 'PASS' } else { 'FAIL' }
        })
    }
}

if ($results.Count -eq 0) {
    Write-Host "RESULT: No client-authentication certificate found -> Branch A (certificate delivery)." -ForegroundColor Yellow
} else {
    $results | Format-Table Store, Result, HasPrivateKey, Expired, ClientAuthEku, ChainValid, ChainStatus, Issuer -AutoSize
    $passing = @($results | Where-Object { $_.Result -eq 'PASS' })
    if ($passing.Count -gt 0) {
        Write-Host "RESULT: $($passing.Count) certificate(s) PASS L1 validation -> proceed to Branch C/D." -ForegroundColor Green
    } else {
        Write-Host "RESULT: certificate(s) present but none pass -> Branch B (chain/trust, e.g. trusted-root certificate profile)." -ForegroundColor Yellow
    }
}

if ($JsonOut) { $results | ConvertTo-Json -Depth 4 | Out-File $JsonOut -Encoding utf8; Write-Host "Wrote $JsonOut" -ForegroundColor Gray }
