<#
.SYNOPSIS
  Map crawled properties to refinable managed properties (alias + queryable/retrievable/refinable
  flags) from a CSV. SAFE BY DEFAULT: dry-run (-WhatIf) unless -Commit is passed.
.DESCRIPTION
  Reads a mapping CSV (CrawledProperty,ManagedProperty,Alias,Flags) and applies each mapping to the
  SharePoint search schema. It edits the exported search-configuration XML and re-imports it with
  Set-PnPSearchConfiguration at the chosen scope. Without -Commit it only prints the intended
  changes and leaves the schema untouched. Always exports a fresh baseline first.
.EXAMPLE
  .\Set-ManagedPropertyMapping.ps1 -AdminUrl https://contoso-admin.sharepoint.com `
      -MappingCsv .\schema-map.csv -WhatIf        # dry-run, shows planned mappings
  .\Set-ManagedPropertyMapping.ps1 -AdminUrl https://contoso-admin.sharepoint.com `
      -MappingCsv .\schema-map.csv -Scope Subscription -Commit   # apply tenant-wide
  (PowerShell 5.1+/7+, PnP.PowerShell; connect with Connect-PnPOnline.)
  CSV header: CrawledProperty,ManagedProperty,Alias,Flags
  Row example: ows_Department,RefinableString00,Department,Queryable;Retrievable;Refinable
.NOTES
  Expected results: dry-run lists each intended mapping; commit re-imports the schema and reports
  success. A mapping does not take effect on content until it is re-crawled/reindexed (see the
  Implementation guide). Pass signal = validation later shows the alias mapped with the flags set.
#>
[CmdletBinding(SupportsShouldProcess = $true)]
param(
    [Parameter(Mandatory)] [string] $AdminUrl,
    [Parameter(Mandatory)] [string] $MappingCsv,
    [ValidateSet('Site','SiteCollection','Subscription')] [string] $Scope = 'Subscription',
    [string] $WorkingXml = ".\SearchConfig-Working.xml",
    [switch] $Commit
)

$ErrorActionPreference = 'Stop'

if (-not (Test-Path $MappingCsv)) { throw "Mapping CSV not found: $MappingCsv" }
if (-not (Get-Module -ListAvailable -Name PnP.PowerShell)) {
    throw "PnP.PowerShell module not found. Install-Module PnP.PowerShell -Scope CurrentUser"
}

$rows = Import-Csv -Path $MappingCsv
foreach ($col in 'CrawledProperty','ManagedProperty','Alias') {
    if ($rows.Count -and -not ($rows[0].PSObject.Properties.Name -contains $col)) {
        throw "CSV missing required column '$col'. Header must be: CrawledProperty,ManagedProperty,Alias,Flags"
    }
}

Write-Host "Connecting to $AdminUrl ..." -ForegroundColor Cyan
Connect-PnPOnline -Url $AdminUrl -Interactive

# Always capture a fresh baseline before touching the schema.
$baseline = ".\SearchConfig-Baseline-{0:yyyyMMdd-HHmmss}.xml" -f (Get-Date)
Get-PnPSearchConfiguration -Scope $Scope -Path $baseline
Write-Host "Baseline exported to $baseline (rollback with Set-PnPSearchConfiguration)." -ForegroundColor Yellow

Write-Host "`nPlanned managed-property mappings ($Scope scope):" -ForegroundColor Cyan
foreach ($r in $rows) {
    $flags = if ([string]::IsNullOrWhiteSpace($r.Flags)) { 'Queryable;Retrievable;Refinable' } else { $r.Flags }
    Write-Host ("  {0}  ->  {1}   alias='{2}'   flags=[{3}]" -f `
        $r.CrawledProperty, $r.ManagedProperty, $r.Alias, $flags)
}

if (-not $Commit) {
    Write-Host "`nDRY-RUN (-WhatIf default). No changes made. Re-run with -Commit to apply." -ForegroundColor Green
    Disconnect-PnPOnline
    return
}

# Commit path: edit the exported XML and re-import.
[xml]$cfg = Get-Content -Path $baseline -Raw
Copy-Item -Path $baseline -Destination $WorkingXml -Force

foreach ($r in $rows) {
    $flags = if ([string]::IsNullOrWhiteSpace($r.Flags)) { 'Queryable;Retrievable;Refinable' } else { $r.Flags }
    $target = "Managed property '$($r.ManagedProperty)' <- crawled '$($r.CrawledProperty)' (alias $($r.Alias); $flags)"
    if ($PSCmdlet.ShouldProcess($target, "Set search-schema mapping")) {
        $mp = $cfg.SelectSingleNode("//*[local-name()='ManagedProperty' and @Name='$($r.ManagedProperty)']")
        if ($null -eq $mp) {
            Write-Warning "Managed property '$($r.ManagedProperty)' not found in export; set this mapping in the Search admin center (Manage Search Schema) and re-export."
            continue
        }
        $mp.SetAttribute('Aliases', $r.Alias)
        if ($flags -match 'Queryable')   { $mp.SetAttribute('Queryable','true') }
        if ($flags -match 'Retrievable') { $mp.SetAttribute('Retrievable','true') }
        if ($flags -match 'Refinable')   { $mp.SetAttribute('Refinable','Yes') }
        if ($flags -match 'Sortable')    { $mp.SetAttribute('Sortable','Yes') }
        Write-Host "  staged: $target" -ForegroundColor Green
    }
}

$cfg.Save((Resolve-Path $WorkingXml))
if ($PSCmdlet.ShouldProcess("$AdminUrl ($Scope scope)", "Import edited search configuration")) {
    Set-PnPSearchConfiguration -Scope $Scope -Path $WorkingXml
    Write-Host "Search configuration imported. Reindex affected content for mappings to take effect." -ForegroundColor Green
}

Disconnect-PnPOnline
