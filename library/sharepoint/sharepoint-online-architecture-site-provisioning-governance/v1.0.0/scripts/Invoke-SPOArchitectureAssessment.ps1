<#
.SYNOPSIS
  Read-only discovery of the SharePoint Online estate for an architecture/provisioning assessment.
.DESCRIPTION
  Inventories every site collection with its base template, storage, sharing capability, hub
  association, and owner, and flags orphaned/owner-less and un-associated sites. Read-only: it
  makes no changes. Produces the assessment baseline for Stage 1 (Assess).
.EXAMPLE
  .\Invoke-SPOArchitectureAssessment.ps1 -OutputPath .\out\SPOARCH-Assessment.csv
  (PowerShell 5.1+/7+, SharePoint Online Management Shell; connect with Connect-SPOService)
.NOTES
  Expected results: a CSV row per site collection with Url, Template, StorageMB, SharingCapability,
  HubAssociation, Owner, and a Flag column marking owner-less / un-associated sites. No changes made.
#>

[CmdletBinding()]
param(
    [Parameter(Mandatory = $true)]
    [string]$OutputPath,

    # Optional admin URL; if omitted, an existing Connect-SPOService session is used.
    [Parameter(Mandatory = $false)]
    [string]$AdminUrl
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

# --- Ensure a connection (modern auth; no stored credentials) ---
try {
    Get-SPOTenant -ErrorAction Stop | Out-Null
    Write-Host "Using existing SharePoint Online admin connection." -ForegroundColor Green
}
catch {
    if (-not $AdminUrl) {
        throw "Not connected. Run Connect-SPOService -Url https://<tenant>-admin.sharepoint.com (or pass -AdminUrl)."
    }
    Write-Host "Connecting to $AdminUrl ..." -ForegroundColor Cyan
    Connect-SPOService -Url $AdminUrl   # opens modern-auth / MFA sign-in
}

# --- Build a hub lookup so associations are human-readable ---
Write-Host "Enumerating hub sites..." -ForegroundColor Cyan
$hubLookup = @{}
try {
    foreach ($h in (Get-SPOHubSite)) {
        # SiteId identifies the hub a site is associated to
        $hubLookup[[string]$h.ID] = $h.Title
    }
}
catch {
    Write-Warning "Could not enumerate hub sites: $($_.Exception.Message)"
}

# --- Enumerate site collections ---
Write-Host "Enumerating site collections (this can take a while on large tenants)..." -ForegroundColor Cyan
$sites = Get-SPOSite -Limit All -Detailed

$results = foreach ($s in $sites) {

    $hubName = ''
    if ($s.HubSiteId -and ($s.HubSiteId -ne [guid]::Empty)) {
        $key = [string]$s.HubSiteId
        $hubName = if ($hubLookup.ContainsKey($key)) { $hubLookup[$key] } else { 'associated (unnamed)' }
    }

    $owner = $s.Owner
    $flags = @()
    if ([string]::IsNullOrWhiteSpace($owner)) { $flags += 'NO-OWNER' }
    if ([string]::IsNullOrWhiteSpace($hubName)) { $flags += 'NO-HUB' }

    [pscustomobject]@{
        Url               = $s.Url
        Title             = $s.Title
        Template          = $s.Template
        StorageUsedMB     = $s.StorageUsageCurrent
        StorageQuotaMB    = $s.StorageQuota
        SharingCapability = $s.SharingCapability
        HubAssociation    = $hubName
        Owner             = $owner
        LastContentMod    = $s.LastContentModifiedDate
        Flag              = ($flags -join '; ')
    }
}

# --- Write the baseline ---
$dir = Split-Path -Parent $OutputPath
if ($dir -and -not (Test-Path $dir)) { New-Item -ItemType Directory -Path $dir -Force | Out-Null }
$results | Sort-Object Url | Export-Csv -Path $OutputPath -NoTypeInformation -Encoding UTF8

# --- Summary to console ---
$total     = ($results | Measure-Object).Count
$noOwner   = ($results | Where-Object { $_.Flag -match 'NO-OWNER' } | Measure-Object).Count
$noHub     = ($results | Where-Object { $_.Flag -match 'NO-HUB' } | Measure-Object).Count

Write-Host ""
Write-Host "Assessment complete." -ForegroundColor Green
Write-Host ("  Site collections : {0}" -f $total)
Write-Host ("  Owner-less       : {0}" -f $noOwner)
Write-Host ("  Un-associated    : {0}" -f $noHub)
Write-Host ("  Baseline written : {0}" -f $OutputPath)
