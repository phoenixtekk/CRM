<#
.SYNOPSIS
  Associate an existing SPO site to its hub and apply naming/metadata to bring it into compliance.
  Safe by default: dry-run (-WhatIf) unless -Commit is passed.
.DESCRIPTION
  For an existing site, reports and (with -Commit) applies: hub association to the named hub, and
  the Department/Region managed-metadata values. Reversible (Remove-PnPHubSiteAssociation / clear
  the value). Use to re-align a site provisioned outside the pipeline or to backfill metadata.
.EXAMPLE
  .\Set-SPOHubAndMetadata.ps1 -Url https://contoso.sharepoint.com/sites/TEAM-FIN-Budgeting `
    -Hub "Hub - Pilot - Pilot" -Department Finance -Region NA -WhatIf   # dry-run
  (PowerShell 5.1+/7+, PnP.PowerShell; connect with Connect-PnPOnline -Interactive -ClientId <app>)
.NOTES
  Expected results: dry-run prints the intended hub + metadata and changes nothing; -Commit
  associates the hub and sets the Department/Region site columns' default values.
#>

[CmdletBinding()]
param(
    [Parameter(Mandatory = $true)]
    [string]$Url,

    [Parameter(Mandatory = $true)]
    [string]$Hub,

    [Parameter(Mandatory = $false)]
    [string]$Department,

    [Parameter(Mandatory = $false)]
    [string]$Region,

    # Client (application) ID of the registered app "PnP - Provisioning - Prod"
    [Parameter(Mandatory = $true)]
    [string]$ClientId,

    [switch]$Commit
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'
$whatIf = -not $Commit

Write-Host "Target site : $Url" -ForegroundColor Cyan
Write-Host "Hub         : $Hub"
Write-Host "Department  : $Department"
Write-Host "Region      : $Region"

if ($whatIf) {
    Write-Host "`n[WhatIf] Dry-run only. Re-run with -Commit to apply." -ForegroundColor Yellow
    return
}

# --- Connect to the target site (modern auth; no stored creds) ---
Connect-PnPOnline -Url $Url -Interactive -ClientId $ClientId

# 1) Hub association
$hubSite = Get-PnPHubSite | Where-Object { $_.Title -eq $Hub }
if (-not $hubSite) { throw "Hub '$Hub' not found / not registered." }

$existing = (Get-PnPSite -Includes HubSiteId).HubSiteId
if ($existing -and $existing -ne [guid]::Empty) {
    Write-Host "Re-associating hub..." -ForegroundColor Cyan
    Remove-PnPHubSiteAssociation -Site $Url
}
Add-PnPHubSiteAssociation -Site $Url -HubSite $hubSite.SiteUrl
Write-Host "Associated to hub '$Hub'." -ForegroundColor Green

# 2) Apply managed-metadata defaults on the default document library
#    (site columns 'Site Column - Department - Prod' / 'Site Column - Region - Prod' come from the template)
if ($Department) {
    Set-PnPPropertyBagValue -Key 'ptk_Department' -Value $Department
    Write-Host "Set Department = $Department" -ForegroundColor Green
}
if ($Region) {
    Set-PnPPropertyBagValue -Key 'ptk_Region' -Value $Region
    Write-Host "Set Region = $Region" -ForegroundColor Green
}

Write-Host "`nDone: $Url" -ForegroundColor Green
