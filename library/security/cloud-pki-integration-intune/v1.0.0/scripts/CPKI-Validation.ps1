<#
.SYNOPSIS
    CPKI-Validation.ps1 — per-device certificate issuance + trust-chain validation (local, Windows).
.DESCRIPTION
    PURPOSE
        Run on a pilot/managed Windows device to confirm the cloud PKI integration actually delivered:
        (1) the cloud PKI root/intermediate is present and trusted, and (2) a leaf client certificate
        was issued by the cloud PKI CA, chains to that root, has the Client Authentication EKU, and is
        within validity. This is the device-side proof behind Testing Tests 2-4. Read-only.
    HOW TO RUN
        Elevated on the device:
        powershell -ExecutionPolicy Bypass -File .\CPKI-Validation.ps1 -CloudPkiCaName "<cloud PKI CA name>"
        -CloudPkiCaName is matched against certificate Issuer/Subject to identify the cloud PKI chain.
    EXPECTED RESULTS
        PASS for: cloud PKI root trusted; a leaf cert issued by the cloud PKI CA present in
        LocalMachine\My; chain valid; Client Authentication EKU present; not expired. Any FAIL points
        to the matching Troubleshooting section (B trust chain / C issuance).
.NOTES
    White-label — the repeatable way. Read-only; inspects the local Windows certificate stores only.
#>
[CmdletBinding()]
param(
    [Parameter(Mandatory=$true)][string]$CloudPkiCaName
)

$clientAuthOid = '1.3.6.1.5.5.7.3.2'
function Result($name,$ok,$detail) {
    $color = if ($ok) { 'Green' } else { 'Red' }
    Write-Host ("[{0}] {1} — {2}" -f $(if($ok){'PASS'}else{'FAIL'}), $name, $detail) -ForegroundColor $color
}

Write-Host "`n=== Cloud PKI certificate validation ($($env:COMPUTERNAME)) ===" -ForegroundColor Cyan
Write-Host ("Matching cloud PKI CA name: {0}`n" -f $CloudPkiCaName)

# 1. Root trusted
$root = Get-ChildItem Cert:\LocalMachine\Root -ErrorAction SilentlyContinue |
        Where-Object { $_.Subject -like "*$CloudPkiCaName*" }
Result 'Cloud PKI root trusted' ([bool]$root) ($(if($root){"found: $($root[0].Subject)"}else{"no root matching '$CloudPkiCaName' in Trusted Root store"}))

# 2. Leaf issued by cloud PKI CA
$leaf = Get-ChildItem Cert:\LocalMachine\My -ErrorAction SilentlyContinue |
        Where-Object { $_.Issuer -like "*$CloudPkiCaName*" } |
        Sort-Object NotAfter -Descending | Select-Object -First 1
Result 'Leaf certificate issued by cloud PKI' ([bool]$leaf) ($(if($leaf){"thumbprint $($leaf.Thumbprint)"}else{"no cert in LocalMachine\My issued by '$CloudPkiCaName'"}))

if ($leaf) {
    # 3. Chain builds
    $chain = [System.Security.Cryptography.X509Certificates.X509Chain]::new()
    $chainOk = $chain.Build($leaf)
    $chainDetail = if ($chainOk) { 'chain validates to a trusted root' } else { ($chain.ChainStatus | ForEach-Object { $_.StatusInformation.Trim() }) -join '; ' }
    Result 'Certificate chain valid' $chainOk $chainDetail

    # 4. Client Authentication EKU
    $ekus = ($leaf.Extensions | Where-Object { $_.Oid.Value -eq '2.5.29.37' })
    $hasClientAuth = $leaf.EnhancedKeyUsageList.ObjectId -contains $clientAuthOid
    Result 'Client Authentication EKU' $hasClientAuth ($(if($hasClientAuth){'present'}else{'missing — Wi-Fi/VPN/auth will fail; fix the profile EKU'}))

    # 5. Validity
    $valid = ($leaf.NotBefore -le (Get-Date)) -and ($leaf.NotAfter -gt (Get-Date))
    Result 'Within validity period' $valid ("NotAfter $($leaf.NotAfter)")
    Write-Host ("    Subject: {0}" -f $leaf.Subject)
}

Write-Host "`nIf any check FAILs, see Troubleshooting B (trust chain) / C (issuance)." -ForegroundColor Yellow
