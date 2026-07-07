<#
.SYNOPSIS
  Read-only discovery of the SharePoint Online search & IA baseline: term sets, published content
  types, site columns, and the current search-schema managed-property mappings. Also captures a
  rollback baseline export. Makes no changes.
.DESCRIPTION
  Connects with PnP PowerShell and enumerates the managed-metadata term store, published content
  types and their fields, and the current search configuration (managed properties, their crawled-
  property mappings and searchable/queryable/retrievable/refinable flags). Emits a JSON assessment
  and writes the tenant search-config baseline XML used for rollback. Read-only.
.EXAMPLE
  .\Get-SearchIAAssessment.ps1 -AdminUrl https://contoso-admin.sharepoint.com `
      -OutputPath .\Findability-Assessment-Tenant-Discovery.json
  (PowerShell 5.1+/7+, PnP.PowerShell; connect with Connect-PnPOnline. Read-only.)
.NOTES
  Expected results: a JSON file listing term sets, content types, and managed-property mappings, plus
  a SearchConfig-Baseline.xml. Pass signal = the file lists your Department/DocType columns and the
  refinable slots already in use (seed the allocation register from it).
#>
[CmdletBinding()]
param(
    [Parameter(Mandatory)] [string] $AdminUrl,
    [string] $OutputPath = ".\Findability-Assessment-Tenant-Discovery.json",
    [string] $BaselinePath = ".\SearchConfig-Baseline.xml"
)

$ErrorActionPreference = 'Stop'

if (-not (Get-Module -ListAvailable -Name PnP.PowerShell)) {
    throw "PnP.PowerShell module not found. Install-Module PnP.PowerShell -Scope CurrentUser"
}

Write-Host "Connecting to $AdminUrl (modern auth / interactive)..." -ForegroundColor Cyan
Connect-PnPOnline -Url $AdminUrl -Interactive

$report = [ordered]@{
    GeneratedUtc   = (Get-Date).ToUniversalTime().ToString('o')
    AdminUrl       = $AdminUrl
    TermSets       = @()
    ContentTypes   = @()
    ManagedProps   = @()
    Notes          = @()
}

# --- Term store (managed metadata) ---
try {
    foreach ($grp in (Get-PnPTermGroup)) {
        foreach ($ts in (Get-PnPTermSet -TermGroup $grp.Name -ErrorAction SilentlyContinue)) {
            $report.TermSets += [ordered]@{ Group = $grp.Name; TermSet = $ts.Name; Id = $ts.Id.ToString() }
        }
    }
} catch { $report.Notes += "Term store enumeration limited: $($_.Exception.Message)" }

# --- Published content types (from the connected site / hub) ---
try {
    foreach ($ct in (Get-PnPContentType -ErrorAction SilentlyContinue)) {
        $report.ContentTypes += [ordered]@{
            Name   = $ct.Name
            Id     = $ct.StringId
            Group  = $ct.Group
        }
    }
} catch { $report.Notes += "Content-type enumeration limited (connect to the gallery/hub site): $($_.Exception.Message)" }

# --- Search schema: export config and parse managed properties + mappings ---
try {
    Get-PnPSearchConfiguration -Scope Subscription -Path $BaselinePath
    Write-Host "Rollback baseline written to $BaselinePath" -ForegroundColor Green

    [xml]$cfg = Get-Content -Path $BaselinePath -Raw
    $ns = New-Object System.Xml.XmlNamespaceManager($cfg.NameTable)
    # Managed property nodes vary by schema version; capture name + flag attributes generically.
    $mpNodes = $cfg.SelectNodes("//*[local-name()='ManagedProperty']")
    foreach ($mp in $mpNodes) {
        $report.ManagedProps += [ordered]@{
            Name        = $mp.GetAttribute('Name')
            Queryable   = $mp.GetAttribute('Queryable')
            Retrievable = $mp.GetAttribute('Retrievable')
            Refinable   = $mp.GetAttribute('Refinable')
            Sortable    = $mp.GetAttribute('Sortable')
            Searchable  = $mp.GetAttribute('FullTextIndex')
        }
    }
    if ($report.ManagedProps.Count -eq 0) {
        $report.Notes += "No ManagedProperty nodes parsed from the export; inspect $BaselinePath / the Search admin center Manage Search Schema page directly."
    }
} catch {
    $report.Notes += "Search-config export/parse failed (need Search/SharePoint Admin): $($_.Exception.Message)"
}

$report | ConvertTo-Json -Depth 6 | Out-File -FilePath $OutputPath -Encoding UTF8
Write-Host "Assessment written to $OutputPath" -ForegroundColor Green
Write-Host ("Term sets: {0}  Content types: {1}  Managed props: {2}" -f `
    $report.TermSets.Count, $report.ContentTypes.Count, $report.ManagedProps.Count)

Disconnect-PnPOnline
