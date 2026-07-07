<#
.SYNOPSIS
  Read-only governance compliance report for the SPO architecture / provisioning standard.
.DESCRIPTION
  Checks in-scope sites against the standard: naming-policy compliance (TEAM-/COMM-/PROJ-),
  hub association, presence of the governed content type, presence of the taxonomy columns, and
  an owner. Writes a per-site + summary CSV. Read-only: makes no changes.
.EXAMPLE
  .\Get-SPOGovernanceComplianceReport.ps1 -Scope Hub -Hub "Hub - Pilot - Pilot" `
    -OutputPath .\out\SPOARCH-Compliance.csv
  (PowerShell 5.1+/7+, PnP.PowerShell; connect with Connect-PnPOnline to the admin/root)
.NOTES
  Expected results: a CSV row per site with Pass/Fail per check and an overall Compliant flag;
  the console summary shows the non-compliant count (0 = clean gate).
#>

[CmdletBinding()]
param(
    [Parameter(Mandatory = $true)]
    [ValidateSet('Tenant', 'Hub')]
    [string]$Scope,

    # Required when -Scope Hub: the hub Title to scope the report to.
    [Parameter(Mandatory = $false)]
    [string]$Hub,

    [Parameter(Mandatory = $true)]
    [string]$OutputPath,

    [Parameter(Mandatory = $true)]
    [string]$ClientId,

    [Parameter(Mandatory = $true)]
    [string]$TenantRoot
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

$GovernedContentType = 'Content Type - Governed Document - Prod'
$TaxonomyColumns     = @('Site Column - Department - Prod', 'Site Column - Region - Prod')

try { Get-PnPConnection -ErrorAction Stop | Out-Null }
catch { throw "Not connected. Run Connect-PnPOnline -Url $TenantRoot -Interactive -ClientId $ClientId first." }

# --- Determine scope ---
$sites = Get-PnPTenantSite
if ($Scope -eq 'Hub') {
    if (-not $Hub) { throw "-Scope Hub requires -Hub <title>." }
    $hubSite = Get-PnPHubSite | Where-Object { $_.Title -eq $Hub }
    if (-not $hubSite) { throw "Hub '$Hub' not found." }
    $sites = $sites | Where-Object { $_.HubSiteId -eq $hubSite.SiteId }
}

$results = foreach ($s in $sites) {

    # naming policy
    $nameOk = ($s.Url -match '/sites/(TEAM|COMM|PROJ)-')
    # hub association
    $hubOk  = ($s.HubSiteId -and $s.HubSiteId -ne [guid]::Empty)
    # owner
    $ownerOk = -not [string]::IsNullOrWhiteSpace($s.Owner)

    # content type + taxonomy columns (connect per-site, read-only)
    $ctOk = $false; $taxOk = $false
    try {
        Connect-PnPOnline -Url $s.Url -Interactive -ClientId $ClientId
        $cts = Get-PnPContentType -ErrorAction SilentlyContinue
        $ctOk = [bool]($cts | Where-Object { $_.Name -eq $GovernedContentType })
        $cols = (Get-PnPField -ErrorAction SilentlyContinue).Title
        $taxOk = -not ($TaxonomyColumns | Where-Object { $_ -notin $cols })
    }
    catch {
        Write-Warning "Could not inspect $($s.Url): $($_.Exception.Message)"
    }

    $compliant = $nameOk -and $hubOk -and $ownerOk -and $ctOk -and $taxOk

    [pscustomobject]@{
        Url             = $s.Url
        NamingCompliant = $nameOk
        HubAssociated   = $hubOk
        OwnerSet        = $ownerOk
        GovernedCTType  = $ctOk
        TaxonomyColumns = $taxOk
        Compliant       = $compliant
    }
}

$dir = Split-Path -Parent $OutputPath
if ($dir -and -not (Test-Path $dir)) { New-Item -ItemType Directory -Path $dir -Force | Out-Null }
$results | Export-Csv -Path $OutputPath -NoTypeInformation -Encoding UTF8

$total = ($results | Measure-Object).Count
$bad   = ($results | Where-Object { -not $_.Compliant } | Measure-Object).Count
Write-Host ""
Write-Host ("Compliance report: {0} sites, {1} non-compliant." -f $total, $bad) -ForegroundColor $(if ($bad -eq 0) { 'Green' } else { 'Yellow' })
Write-Host ("Report written: {0}" -f $OutputPath)
