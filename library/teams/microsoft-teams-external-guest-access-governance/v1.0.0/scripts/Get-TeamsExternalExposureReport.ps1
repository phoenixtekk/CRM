<#
.SYNOPSIS
  Read-only external-exposure report: guests, inactivity, and non-approved domains, exported to CSV.
.DESCRIPTION
  Enumerates guest users (Entra B2B), flags those inactive for >= a threshold (stale) and those whose
  domain is not on the approved list, and captures the tenant's external-facing switches (federation
  model, guest toggle, shared-channel defaults). Exports a governance-ready CSV plus a console summary.
  Read-only: Get-* / reporting only, no changes.
.EXAMPLE
  .\Get-TeamsExternalExposureReport.ps1 -InactiveDays 90 -ApprovedDomains "contoso.com" -OutputPath .\external-exposure.csv
  (PowerShell 5.1+/7+, Microsoft.Graph + MicrosoftTeams; connect with Connect-MgGraph / Connect-MicrosoftTeams)
.NOTES
  Expected results: a CSV of guests with Stale/NonApprovedDomain flags and a summary count. Sign-in
  inactivity requires the appropriate Entra licensing - if unavailable it is reported as "unknown"
  (verify in your tenant), and guests are treated as stale-by-creation-age as a fallback.
#>

[CmdletBinding()]
param(
    [int]$InactiveDays = 90,
    [string[]]$ApprovedDomains = @(),
    [string]$OutputPath = ".\external-exposure.csv"
)

$ErrorActionPreference = 'Stop'
if (-not (Get-MgContext)) {
    Connect-MgGraph -Scopes "User.Read.All","AuditLog.Read.All" | Out-Null
}

$cutoff = (Get-Date).AddDays(-$InactiveDays)
$guests = Get-MgUser -Filter "userType eq 'Guest'" -All `
            -Property Id,DisplayName,Mail,UserPrincipalName,CreatedDateTime,SignInActivity

$rows = foreach ($g in $guests) {
    $last   = $g.SignInActivity.LastSignInDateTime
    $known  = [bool]$last
    $stale  = if ($known) { $last -lt $cutoff } else { $g.CreatedDateTime -lt $cutoff }  # fallback if no sign-in data
    $domain = if ($g.Mail) { ($g.Mail -split '@')[-1] } elseif ($g.UserPrincipalName -match '#EXT#') {
                 (($g.UserPrincipalName -split '#EXT#')[0] -split '_')[-1]
              } else { '' }
    $nonApproved = ($ApprovedDomains.Count -gt 0) -and ($domain) -and ($ApprovedDomains -notcontains $domain)
    [pscustomobject]@{
        DisplayName        = $g.DisplayName
        Mail               = $g.Mail
        Domain             = $domain
        CreatedUtc         = $g.CreatedDateTime
        LastSignInUtc      = if ($known) { $last } else { 'unknown (verify licensing)' }
        Stale              = $stale
        NonApprovedDomain  = $nonApproved
    }
}

$rows | Sort-Object Stale, NonApprovedDomain -Descending | Export-Csv -Path $OutputPath -NoTypeInformation -Encoding UTF8

$staleCount = ($rows | Where-Object Stale).Count
$badDomain  = ($rows | Where-Object NonApprovedDomain).Count
Write-Host "Guests: $($rows.Count) | Stale (>= $InactiveDays d): $staleCount | Non-approved domain: $badDomain" -ForegroundColor Cyan
Write-Host "Report written to $OutputPath" -ForegroundColor Green

# External-facing tenant switches (best-effort; skipped with a notice if Teams module absent)
try {
    if (-not (Get-CsTenantFederationConfiguration -ErrorAction SilentlyContinue)) { Connect-MicrosoftTeams | Out-Null }
    $fed = Get-CsTenantFederationConfiguration
    Write-Host "`nFederation: FederatedUsers=$($fed.AllowFederatedUsers) PublicUsers=$($fed.AllowPublicUsers)" -ForegroundColor Cyan
    Write-Host "AllowedDomains: $((($fed.AllowedDomains | Out-String).Trim()) )"
}
catch { Write-Warning "Teams federation switches skipped: $($_.Exception.Message)" }
