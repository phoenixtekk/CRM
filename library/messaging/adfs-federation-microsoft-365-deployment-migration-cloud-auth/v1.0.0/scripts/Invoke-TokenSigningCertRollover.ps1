<#
.SYNOPSIS
  Remediation (SAFE BY DEFAULT: -WhatIf / dry-run): previews the "Token-Signing Cert - ADFS - Rollover"
  by comparing the ADFS primary token-signing certificate against the certificate Microsoft Entra
  currently trusts, and shows the Entra federation-metadata update needed. Only acts when -Commit is
  passed.
.DESCRIPTION
  Reads ADFS token-signing certificates on the local federation server (Get-AdfsCertificate) and the
  Entra-trusted signing certificate for the domain (Get-MgDomainFederationConfiguration). If the ADFS
  primary thumbprint differs from the Entra-trusted thumbprint, Entra will reject tokens - this script
  reports that and, only with -Commit, refreshes the Entra federation trust with the current ADFS
  metadata (Update-MgDomainFederationConfiguration). It does NOT force an ADFS certificate rollover;
  that is done deliberately with Update-AdfsCertificate -CertificateType Token-Signing in a maintenance
  window. Run the ADFS cmdlets on a federation server (requires the ADFS PowerShell module).
.EXAMPLE
  .\Invoke-TokenSigningCertRollover.ps1 -DomainName contoso.com -WhatIf
  # Dry-run: shows current ADFS vs Entra-trusted signing certs and the update that WOULD be applied.
.EXAMPLE
  .\Invoke-TokenSigningCertRollover.ps1 -DomainName contoso.com -Commit
  # Updates the Entra federation trust to the current ADFS token-signing metadata (change window only).
  # (PowerShell 5.1+/7+, ADFS module on a federation server, Microsoft.Graph; Connect-MgGraph with
  #  Domain.ReadWrite.All to commit.)
.NOTES
  Expected results: THUMBPRINTS MATCH = healthy, no action. THUMBPRINTS DIFFER = Entra will reject
  tokens; commit to refresh the trust, keeping the prior cert as an ADFS secondary during overlap.
  Prefer the Microsoft Entra Connect wizard's federation-management task where available. Legacy
  MSOnline equivalent: Update-MSOLFederatedDomain -DomainName <domain> (deprecated - verify
  availability). Government cloud: connect Graph to the correct environment and verify endpoints.
#>

[CmdletBinding(SupportsShouldProcess = $true, ConfirmImpact = 'High')]
param(
    [Parameter(Mandatory = $true)]
    [string]$DomainName,

    [switch]$Commit
)

# Safe-by-default: without -Commit this is a dry run regardless of -WhatIf.
$isDryRun = -not $Commit
if ($isDryRun) { Write-Host "DRY-RUN (no changes). Pass -Commit to update the Entra federation trust." -ForegroundColor Yellow }

# --- ADFS side (must run on a federation server) ---
$adfsPrimary = $null
if (Get-Command Get-AdfsCertificate -ErrorAction SilentlyContinue) {
    try {
        $adfsSigning = Get-AdfsCertificate -CertificateType Token-Signing -ErrorAction Stop
        $adfsPrimary = $adfsSigning | Where-Object { $_.IsPrimary } | Select-Object -First 1
        Write-Host "`nADFS token-signing certificates:" -ForegroundColor Cyan
        $adfsSigning | Select-Object IsPrimary, @{n='Thumbprint';e={$_.Certificate.Thumbprint}},
            @{n='NotAfter';e={$_.Certificate.NotAfter}} | Format-Table -AutoSize
    } catch {
        Write-Warning "Get-AdfsCertificate failed: $($_.Exception.Message)"
    }
} else {
    Write-Warning "ADFS module not found. Run this on a federation server to read the ADFS token-signing cert."
}

# --- Entra side ---
Write-Host "Connecting to Microsoft Graph..." -ForegroundColor Cyan
$scope = if ($isDryRun) { 'Domain.Read.All' } else { 'Domain.ReadWrite.All' }
try {
    Connect-MgGraph -Scopes $scope -ErrorAction Stop | Out-Null
} catch {
    Write-Error "Connect-MgGraph failed: $($_.Exception.Message)"; return
}

try {
    $fed = Get-MgDomainFederationConfiguration -DomainId $DomainName -ErrorAction Stop | Select-Object -First 1
} catch {
    Write-Error "Get-MgDomainFederationConfiguration failed for $DomainName (is the domain federated?): $($_.Exception.Message)"
    return
}

$entraThumb = $null
if ($fed -and $fed.SigningCertificate) {
    try {
        $bytes = [System.Convert]::FromBase64String($fed.SigningCertificate)
        $entraCert = New-Object System.Security.Cryptography.X509Certificates.X509Certificate2 (,$bytes)
        $entraThumb = $entraCert.Thumbprint
        Write-Host "`nEntra-trusted signing certificate for ${DomainName}: $entraThumb (NotAfter $($entraCert.NotAfter))" -ForegroundColor Cyan
    } catch {
        Write-Warning "Could not parse the Entra-trusted signing certificate."
    }
}

# --- Compare ---
if ($adfsPrimary -and $entraThumb) {
    $adfsThumb = $adfsPrimary.Certificate.Thumbprint
    if ($adfsThumb -eq $entraThumb) {
        Write-Host "`nMATCH: ADFS primary token-signing cert equals the Entra-trusted cert. No rollover update needed." -ForegroundColor Green
        return
    } else {
        Write-Host "`nMISMATCH: ADFS primary ($adfsThumb) differs from Entra-trusted ($entraThumb). Entra will reject ADFS-signed tokens." -ForegroundColor Red
    }
} else {
    Write-Host "`nCould not compare both sides automatically; review the values above." -ForegroundColor Yellow
}

# --- Commit path ---
if ($isDryRun) {
    Write-Host "`nDRY-RUN: WOULD update the Entra federation trust for $DomainName to the current ADFS token-signing metadata." -ForegroundColor Yellow
    Write-Host "Re-run with -Commit inside a maintenance window to apply. Keep the prior cert as an ADFS secondary during overlap." -ForegroundColor Yellow
    return
}

if ($PSCmdlet.ShouldProcess("$DomainName federation trust", "Update Entra-trusted token-signing certificate")) {
    if (-not $adfsPrimary) {
        Write-Error "No ADFS primary token-signing certificate read; cannot build the update. Run on a federation server."
        return
    }
    $newSigningB64 = [System.Convert]::ToBase64String($adfsPrimary.Certificate.RawData)
    try {
        Update-MgDomainFederationConfiguration -DomainId $DomainName `
            -InternalDomainFederationId $fed.Id `
            -SigningCertificate $newSigningB64 -ErrorAction Stop
        Write-Host "Updated Entra federation trust for $DomainName with ADFS primary token-signing cert $($adfsPrimary.Certificate.Thumbprint)." -ForegroundColor Green
        Write-Host "Validate now: sign in as a federated user and re-run Get-M365FederationAssessment.ps1." -ForegroundColor Cyan
    } catch {
        Write-Error "Update-MgDomainFederationConfiguration failed: $($_.Exception.Message)"
        Write-Host "Rollback: the prior Entra metadata is unchanged if this failed; consider the Entra Connect wizard instead." -ForegroundColor Yellow
    }
}
