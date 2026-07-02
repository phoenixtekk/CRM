<#
.SYNOPSIS
    New-EpmElevationRule.ps1 — Read a target app's identity to author an EPM elevation rule.

.DESCRIPTION
    PURPOSE
        Inspects a target executable (or MSI) and prints the exact values you need to create an
        Endpoint Privilege Management elevation rule in Intune: the file name, the SHA-256 file
        hash, the file/product version, and — if the file is signed — the publisher certificate
        details (subject, thumbprint). It recommends a CERTIFICATE rule for signed apps (survives
        updates) and a HASH rule for unsigned, fixed binaries. Run it during Implementation Step 5
        for every app your users legitimately need to elevate.

    HOW TO RUN
        powershell -ExecutionPolicy Bypass -File .\New-EpmElevationRule.ps1 -Path "C:\Path\to\app.exe"
        Optional: emit a JSON blob you can keep alongside your change log:
            .\New-EpmElevationRule.ps1 -Path "C:\Path\to\app.exe" -AsJson

    EXPECTED RESULTS
        A summary block with File name, SHA-256, version, and signer (if signed), plus a clear
        recommendation of which rule type (Certificate vs File hash) to use. You then enter these
        values when adding a rule under Endpoint security → Endpoint Privilege Management →
        Elevation rules policy → Add. This script makes NO changes to the device or Intune.

.NOTES
    White-label — Intune Solutions. Read-only.
#>
[CmdletBinding()]
param(
    [Parameter(Mandatory = $true)]
    [string]$Path,
    [switch]$AsJson
)

if (-not (Test-Path $Path)) {
    Write-Error "File not found: $Path"
    return
}

$item = Get-Item -LiteralPath $Path
$hash = (Get-FileHash -LiteralPath $Path -Algorithm SHA256).Hash
$ver  = $item.VersionInfo

# Signature / publisher certificate
$sig = Get-AuthenticodeSignature -LiteralPath $Path
$signed = $sig.Status -eq 'Valid' -and $sig.SignerCertificate
$signer = if ($signed) {
    [pscustomobject]@{
        Subject    = $sig.SignerCertificate.Subject
        Issuer     = $sig.SignerCertificate.Issuer
        Thumbprint = $sig.SignerCertificate.Thumbprint
        NotAfter   = $sig.SignerCertificate.NotAfter
    }
} else { $null }

$recommended = if ($signed) { 'Certificate (survives app updates)' } else { 'File hash (unsigned — note this breaks on every new build)' }

$result = [ordered]@{
    FileName       = $item.Name
    FullPath       = $item.FullName
    SizeBytes      = $item.Length
    SHA256         = $hash
    FileVersion    = $ver.FileVersion
    ProductVersion = $ver.ProductVersion
    ProductName    = $ver.ProductName
    Signed         = [bool]$signed
    SignatureStatus= $sig.Status.ToString()
    Signer         = $signer
    RecommendedRule= $recommended
}

if ($AsJson) {
    $result | ConvertTo-Json -Depth 5
    return
}

Write-Host "`n=== EPM Elevation Rule — Source Values ($($item.Name)) ===" -ForegroundColor Cyan
Write-Host ("File name      : {0}" -f $result.FileName)
Write-Host ("SHA-256 hash   : {0}" -f $result.SHA256)
Write-Host ("File version   : {0}" -f $result.FileVersion)
Write-Host ("Product        : {0} {1}" -f $result.ProductName, $result.ProductVersion)
Write-Host ("Signed         : {0} ({1})" -f $result.Signed, $result.SignatureStatus)
if ($signed) {
    Write-Host ("Signer subject : {0}" -f $signer.Subject)
    Write-Host ("Signer issuer  : {0}" -f $signer.Issuer)
    Write-Host ("Thumbprint     : {0}" -f $signer.Thumbprint)
    Write-Host ("Cert expires   : {0}" -f $signer.NotAfter)
}
Write-Host ("`nRecommended rule type: {0}" -f $recommended) -ForegroundColor Green
Write-Host "Enter these under: Endpoint security → Endpoint Privilege Management → Elevation rules policy → + Add."
Write-Host "Set Elevation type = User confirmed (recommended); require business justification for a clean audit record."
if ($signed) { Write-Host "For a certificate rule, export the signer certificate (.cer) from this file's Digital Signatures tab to upload in the rule." -ForegroundColor Yellow }
