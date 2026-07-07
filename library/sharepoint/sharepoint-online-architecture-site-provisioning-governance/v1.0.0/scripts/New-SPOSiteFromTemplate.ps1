<#
.SYNOPSIS
  Provision a SharePoint Online site from a PnP template, named + hub-associated + tagged.
  Safe by default: dry-run (-WhatIf) unless -Commit is passed.
.DESCRIPTION
  Computes the site name from the naming policy (TEAM-<Dept>-<Purpose> / COMM-<Purpose> /
  PROJ-<Code>), provisions the correct archetype, applies a PnP provisioning template, associates
  the target hub, sets owners, and tags the site's Department. Reports intended actions under
  -WhatIf and changes nothing until -Commit.
.EXAMPLE
  .\New-SPOSiteFromTemplate.ps1 -SiteType Team -Department Finance -Purpose Budgeting `
    -Owners owner1@contoso.com,owner2@contoso.com -Hub "Hub - Pilot - Pilot" `
    -TemplatePath ".\templates\Template - Team Site - Prod.pnp" -WhatIf   # dry-run
  (PowerShell 5.1+/7+, PnP.PowerShell; connect with Connect-PnPOnline -Interactive -ClientId <app>)
.NOTES
  Expected results: dry-run prints the computed Url, template, hub, and owners and makes NO change;
  with -Commit the site is created, template applied, hub associated, and owners set.
#>

[CmdletBinding()]
param(
    [Parameter(Mandatory = $true)]
    [ValidateSet('Team', 'Communication', 'Project')]
    [string]$SiteType,

    # Department (from Term Set - Department - Prod); required for Team sites.
    [Parameter(Mandatory = $false)]
    [string]$Department,

    # Purpose (Team/Communication) or project Code (Project) — used to build the name.
    [Parameter(Mandatory = $true)]
    [string]$Purpose,

    [Parameter(Mandatory = $true)]
    [string[]]$Owners,

    [Parameter(Mandatory = $true)]
    [string]$Hub,

    [Parameter(Mandatory = $true)]
    [string]$TemplatePath,

    # Tenant root, e.g. https://contoso.sharepoint.com
    [Parameter(Mandatory = $true)]
    [string]$TenantRoot,

    [switch]$Commit
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'
$whatIf = -not $Commit

function Get-NamePart([string]$v) {
    # upper-case, strip spaces/invalid URL chars, collapse to a clean token
    ($v -replace '[^A-Za-z0-9]', '').ToUpperInvariant()
}

# --- Compute the name per Naming Policy - Sites - Prod ---
switch ($SiteType) {
    'Team' {
        if ([string]::IsNullOrWhiteSpace($Department)) { throw "Team sites require -Department." }
        $name = "TEAM-{0}-{1}" -f (Get-NamePart $Department), (Get-NamePart $Purpose)
        $baseType = 'TeamSite'
    }
    'Communication' {
        $name = "COMM-{0}" -f (Get-NamePart $Purpose)
        $baseType = 'CommunicationSite'
    }
    'Project' {
        $name = "PROJ-{0}" -f (Get-NamePart $Purpose)
        $baseType = 'TeamSite'
    }
}
$url = "{0}/sites/{1}" -f $TenantRoot.TrimEnd('/'), $name

if (-not (Test-Path $TemplatePath)) { throw "Template not found: $TemplatePath" }

Write-Host "Planned provisioning:" -ForegroundColor Cyan
Write-Host ("  Site type : {0} ({1})" -f $SiteType, $baseType)
Write-Host ("  Name/Url  : {0}" -f $url)
Write-Host ("  Template  : {0}" -f $TemplatePath)
Write-Host ("  Hub       : {0}" -f $Hub)
Write-Host ("  Owners    : {0}" -f ($Owners -join ', '))
Write-Host ("  Department: {0}" -f $Department)

if ($whatIf) {
    Write-Host "`n[WhatIf] Dry-run only. No site created. Re-run with -Commit to apply." -ForegroundColor Yellow
    return
}

# --- Commit path: requires an active PnP admin connection ---
try { Get-PnPConnection -ErrorAction Stop | Out-Null }
catch { throw "Not connected. Run Connect-PnPOnline -Url $TenantRoot -Interactive -ClientId <app-client-id> first." }

# 1) Create the site collection
Write-Host "`nCreating site..." -ForegroundColor Cyan
if ($baseType -eq 'CommunicationSite') {
    New-PnPSite -Type CommunicationSite -Title $name -Url $url -Wait | Out-Null
}
else {
    New-PnPSite -Type TeamSite -Title $name -Alias $name -IsPublic:$false -Wait | Out-Null
}

# 2) Apply the PnP provisioning template (columns, content types, libraries, nav, theme)
Write-Host "Applying template..." -ForegroundColor Cyan
Connect-PnPOnline -Url $url -Interactive -ClientId (Get-PnPConnection).ClientId
Invoke-PnPSiteTemplate -Path $TemplatePath

# 3) Associate the hub
Write-Host "Associating hub '$Hub'..." -ForegroundColor Cyan
$hubSite = Get-PnPHubSite | Where-Object { $_.Title -eq $Hub }
if (-not $hubSite) { throw "Hub '$Hub' not found / not registered." }
Add-PnPHubSiteAssociation -Site $url -HubSite $hubSite.SiteUrl

# 4) Set owners
Write-Host "Setting owners..." -ForegroundColor Cyan
foreach ($o in $Owners) {
    Add-PnPSiteCollectionAdmin -Owners $o
}

# 5) Tag Department at the site level (property bag / site column default handled by template)
if ($Department) {
    Set-PnPPropertyBagValue -Key 'ptk_Department' -Value $Department
}

Write-Host "`nProvisioned: $url" -ForegroundColor Green
