<#
.SYNOPSIS
  Discovery (READ-ONLY): produces the "Federation Assessment - M365 - Prod" snapshot of each domain's
  authentication type and, for federated domains, the Microsoft Entra federation trust and its trusted
  token-signing certificate (thumbprint + expiry). Makes no changes.
.DESCRIPTION
  Connects to Microsoft Graph and enumerates every verified domain via Get-MgDomain. For each FEDERATED
  domain it reads the federation configuration (Get-MgDomainFederationConfiguration): issuer URI,
  passive sign-in / metadata endpoints, and the trusted signing certificate, decoding its thumbprint
  and NotAfter. Certificates expiring within -ExpiryWarningDays are flagged. Read-only: requires only
  Domain.Read.All. Compare the reported trusted-signing thumbprint against your ADFS primary
  token-signing certificate (Get-AdfsCertificate -CertificateType Token-Signing) on a federation server.
.EXAMPLE
  .\Get-M365FederationAssessment.ps1
  # Read-only assessment of all domains; flags federation signing certs expiring within 60 days.
.EXAMPLE
  .\Get-M365FederationAssessment.ps1 -ExpiryWarningDays 90 -CsvPath .\federation-assessment.csv
  # Widen the expiry warning window and export the snapshot to CSV.
  # (PowerShell 5.1+/7+, Microsoft.Graph module; connect with Connect-MgGraph.)
.NOTES
  Expected results: one row per domain with AuthenticationType and, for federated domains, issuer,
  endpoints, signing-cert thumbprint + NotAfter, and an EXPIRING flag. No changes are made.
  MSOnline (Get-MsolFederationProperty) is a deprecated alternative source - verify availability in
  your tenant. Government cloud: connect with the correct environment (Connect-MgGraph -Environment
  USGov / USGovDoD) and verify endpoints for your cloud.
#>

[CmdletBinding()]
param(
    [int]$ExpiryWarningDays = 60,
    [string]$CsvPath
)

function Get-CertInfoFromBase64 {
    param([string]$Base64Cert)
    if ([string]::IsNullOrWhiteSpace($Base64Cert)) { return $null }
    try {
        $bytes = [System.Convert]::FromBase64String($Base64Cert)
        $cert  = New-Object System.Security.Cryptography.X509Certificates.X509Certificate2 (,$bytes)
        [pscustomobject]@{ Thumbprint = $cert.Thumbprint; NotAfter = $cert.NotAfter }
    } catch {
        Write-Verbose "Could not parse signing certificate: $($_.Exception.Message)"
        $null
    }
}

Write-Host "Connecting to Microsoft Graph (read-only: Domain.Read.All)..." -ForegroundColor Cyan
try {
    Connect-MgGraph -Scopes 'Domain.Read.All' -ErrorAction Stop | Out-Null
} catch {
    Write-Error "Connect-MgGraph failed: $($_.Exception.Message)"
    return
}

$results = New-Object System.Collections.Generic.List[object]

try {
    $domains = Get-MgDomain -All -ErrorAction Stop
} catch {
    Write-Error "Get-MgDomain failed: $($_.Exception.Message)"
    return
}

foreach ($d in $domains) {
    $row = [ordered]@{
        Domain             = $d.Id
        AuthenticationType = $d.AuthenticationType
        IsVerified         = $d.IsVerified
        IssuerUri          = $null
        PassiveSignInUri   = $null
        MetadataExchangeUri= $null
        SigningThumbprint  = $null
        SigningNotAfter    = $null
        DaysToExpiry       = $null
        Expiring           = $false
    }

    if ($d.AuthenticationType -eq 'Federated') {
        try {
            $fed = Get-MgDomainFederationConfiguration -DomainId $d.Id -ErrorAction Stop | Select-Object -First 1
            if ($fed) {
                $row.IssuerUri           = $fed.IssuerUri
                $row.PassiveSignInUri    = $fed.PassiveSignInUri
                $row.MetadataExchangeUri = $fed.MetadataExchangeUri
                $certInfo = Get-CertInfoFromBase64 -Base64Cert $fed.SigningCertificate
                if ($certInfo) {
                    $row.SigningThumbprint = $certInfo.Thumbprint
                    $row.SigningNotAfter   = $certInfo.NotAfter
                    $row.DaysToExpiry      = [int]([math]::Floor(($certInfo.NotAfter - (Get-Date)).TotalDays))
                    $row.Expiring          = ($row.DaysToExpiry -le $ExpiryWarningDays)
                }
            }
        } catch {
            Write-Warning "Could not read federation configuration for $($d.Id): $($_.Exception.Message)"
        }
    }

    $results.Add([pscustomobject]$row)
}

Write-Host "`nFederation Assessment - M365 - Prod" -ForegroundColor Green
$results | Format-Table Domain, AuthenticationType, SigningThumbprint, SigningNotAfter, DaysToExpiry, Expiring -AutoSize

$flagged = $results | Where-Object { $_.Expiring }
if ($flagged) {
    Write-Host "`nWARNING: federation signing certificate(s) expiring within $ExpiryWarningDays days:" -ForegroundColor Yellow
    $flagged | Format-Table Domain, SigningThumbprint, SigningNotAfter, DaysToExpiry -AutoSize
    Write-Host "Run Invoke-TokenSigningCertRollover.ps1 -WhatIf to preview the rollover." -ForegroundColor Yellow
} else {
    Write-Host "`nNo federation signing certificates expiring within $ExpiryWarningDays days." -ForegroundColor Green
}

if ($CsvPath) {
    $results | Export-Csv -Path $CsvPath -NoTypeInformation -Encoding UTF8
    Write-Host "Exported assessment to $CsvPath" -ForegroundColor Cyan
}

Write-Host "`nNext: on a federation server compare SigningThumbprint above with the ADFS primary token-signing cert:" -ForegroundColor Cyan
Write-Host "  Get-AdfsCertificate -CertificateType Token-Signing" -ForegroundColor DarkGray
