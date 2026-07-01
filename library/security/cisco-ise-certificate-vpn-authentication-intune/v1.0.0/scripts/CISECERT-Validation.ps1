<#
.SYNOPSIS
    CISECERT-Validation.ps1 — per-device VPN certificate + trust-chain validation (local, Windows).
.DESCRIPTION
    PURPOSE
        Run on a pilot/managed Windows device to confirm the EAP-TLS VPN certificate is actually
        deliverable: the issuing CA root/intermediate is present and trusted, a leaf client certificate
        was issued by that CA, chains to the trusted root, has the Client Authentication EKU, and is
        within validity. This is the device-side proof behind Testing Tests 2-4. Read-only.
    HOW TO RUN
        Elevated on the device:
        powershell -ExecutionPolicy Bypass -File .\CISECERT-Validation.ps1 -IssuingCaName "your-issuing-ca-name"
        -IssuingCaName is matched against certificate Issuer/Subject to identify the VPN certificate chain.
    EXPECTED RESULTS
        PASS for: issuing CA root trusted; a leaf cert issued by that CA present in LocalMachine\My;
        chain valid; Client Authentication EKU present; not expired; plus the Subject/SAN printed so you
        can confirm it matches what Cisco ISE keys on. Any FAIL maps to Troubleshooting A/B.
.NOTES
    White-label — the repeatable way. Read-only; inspects the local Windows certificate stores only.
    Cisco ISE internals deferred to vendor docs.
#>
[CmdletBinding()]
param(
    [Parameter(Mandatory=$true)][string]$IssuingCaName
)

$clientAuthOid = '1.3.6.1.5.5.7.3.2'
function Result($name,$ok,$detail) {
    $color = if ($ok) { 'Green' } else { 'Red' }
    Write-Host ("[{0}] {1} — {2}" -f $(if($ok){'PASS'}else{'FAIL'}), $name, $detail) -ForegroundColor $color
}

Write-Host "`n=== Cisco VPN certificate validation ($($env:COMPUTERNAME)) ===" -ForegroundColor Cyan
Write-Host ("Matching issuing CA name: {0}`n" -f $IssuingCaName)

# 1. Root trusted
$root = Get-ChildItem Cert:\LocalMachine\Root -ErrorAction SilentlyContinue |
        Where-Object { $_.Subject -like "*$IssuingCaName*" }
Result 'Issuing CA root trusted' ([bool]$root) ($(if($root){"found: $($root[0].Subject)"}else{"no root matching '$IssuingCaName' in Trusted Root store — deploy Cisco VPN - Trusted Root"}))

# 2. Leaf issued by the issuing CA (machine store first, then user store)
$leaf = @(Get-ChildItem Cert:\LocalMachine\My -ErrorAction SilentlyContinue) +
        @(Get-ChildItem Cert:\CurrentUser\My -ErrorAction SilentlyContinue) |
        Where-Object { $_.Issuer -like "*$IssuingCaName*" } |
        Sort-Object NotAfter -Descending | Select-Object -First 1
Result 'Leaf VPN certificate present' ([bool]$leaf) ($(if($leaf){"thumbprint $($leaf.Thumbprint)"}else{"no cert issued by '$IssuingCaName' in My store — see Troubleshooting A"}))

if ($leaf) {
    # 3. Chain builds to a trusted root
    $chain = [System.Security.Cryptography.X509Certificates.X509Chain]::new()
    $chainOk = $chain.Build($leaf)
    $chainDetail = if ($chainOk) { 'chain validates to a trusted root' } else { ($chain.ChainStatus | ForEach-Object { $_.StatusInformation.Trim() }) -join '; ' }
    Result 'Certificate chain valid' $chainOk $chainDetail

    # 4. Client Authentication EKU (required for EAP-TLS)
    $hasClientAuth = $leaf.EnhancedKeyUsageList.ObjectId -contains $clientAuthOid
    Result 'Client Authentication EKU' $hasClientAuth ($(if($hasClientAuth){'present — required for EAP-TLS'}else{'missing — ISE EAP-TLS will fail; fix the SCEP/PKCS profile EKU'}))

    # 5. Validity
    $valid = ($leaf.NotBefore -le (Get-Date)) -and ($leaf.NotAfter -gt (Get-Date))
    Result 'Within validity period' $valid ("NotAfter $($leaf.NotAfter)")

    # Identity — print Subject + SAN so the operator can compare to the ISE Certificate Authentication Profile
    Write-Host ("    Subject: {0}" -f $leaf.Subject)
    $san = ($leaf.Extensions | Where-Object { $_.Oid.Value -eq '2.5.29.17' })
    if ($san) { Write-Host ("    SAN:     {0}" -f $san.Format($false)) }
    Write-Host "    Confirm this Subject/SAN matches the identity ISE keys on (Testing Test 4)." -ForegroundColor Yellow
}

Write-Host "`nIf any check FAILs, see Troubleshooting A (no cert) / B (chain incomplete)." -ForegroundColor Yellow
