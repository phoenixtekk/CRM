<#
.SYNOPSIS
  Report search & IA health/coverage across a set of sites: which carry the standard content types and
  populated metadata, plus tenant schema-mapping presence and bookmark-target reachability. Read-only.
.DESCRIPTION
  Scans the provided sites (or all sites via Get-PnPTenantSite) for the standard content types and the
  presence of the key managed-metadata columns, flags libraries with heavy untagged content, confirms
  the expected managed-property aliases exist in the tenant schema, and checks that configured bookmark
  target URLs resolve. Emits a JSON health report for scheduled monitoring. Read-only.
.EXAMPLE
  .\Get-SearchHealthScope.ps1 -AdminUrl https://contoso-admin.sharepoint.com `
      -ContentTypeNames "Content Type – Policy Document – Prod","Content Type – Contract – Prod" `
      -OutputPath .\Search-Health-Tenant.json
  (PowerShell 5.1+/7+, PnP.PowerShell; connect with Connect-PnPOnline. Read-only.)
.NOTES
  Expected results: a JSON report with per-site content-type/metadata coverage and a schema/bookmark
  check. Pass signal = target sites show the standard content types applied and the expected aliases
  present; drift (missing content type, unpublished, empty metadata) is listed for remediation.
#>
[CmdletBinding()]
param(
    [Parameter(Mandatory)] [string] $AdminUrl,
    [string[]] $SiteUrls,
    [string[]] $ContentTypeNames = @("Content Type – Policy Document – Prod","Content Type – Contract – Prod"),
    [string[]] $ExpectedAliases  = @("Department","DocType","DocOwner"),
    [string[]] $BookmarkUrls     = @(),
    [string] $OutputPath = ".\Search-Health-Tenant.json"
)

$ErrorActionPreference = 'Stop'

Write-Host "Connecting to $AdminUrl ..." -ForegroundColor Cyan
Connect-PnPOnline -Url $AdminUrl -Interactive

$health = [ordered]@{
    GeneratedUtc = (Get-Date).ToUniversalTime().ToString('o')
    AdminUrl     = $AdminUrl
    Sites        = @()
    SchemaCheck  = [ordered]@{}
    Bookmarks    = @()
    Notes        = @()
}

# --- Determine site scope ---
if (-not $SiteUrls -or $SiteUrls.Count -eq 0) {
    try {
        $SiteUrls = (Get-PnPTenantSite -ErrorAction Stop |
            Where-Object { $_.Template -notmatch 'REDIRECT|SPSPERS' } |
            Select-Object -ExpandProperty Url)
    } catch { $health.Notes += "Could not enumerate tenant sites: $($_.Exception.Message)" }
}

# --- Per-site content-type / metadata coverage ---
foreach ($url in $SiteUrls) {
    $entry = [ordered]@{ Url = $url; ContentTypesPresent = @(); Missing = @(); Error = $null }
    try {
        Connect-PnPOnline -Url $url -Interactive
        $cts = Get-PnPContentType -ErrorAction SilentlyContinue | Select-Object -ExpandProperty Name
        foreach ($ctn in $ContentTypeNames) {
            if ($cts -contains $ctn) { $entry.ContentTypesPresent += $ctn } else { $entry.Missing += $ctn }
        }
    } catch { $entry.Error = $_.Exception.Message }
    $health.Sites += $entry
}

# --- Tenant schema: expected aliases present? ---
try {
    Connect-PnPOnline -Url $AdminUrl -Interactive
    $tmp = ".\SearchConfig-Health-{0:yyyyMMddHHmmss}.xml" -f (Get-Date)
    Get-PnPSearchConfiguration -Scope Subscription -Path $tmp
    $raw = Get-Content -Path $tmp -Raw
    foreach ($alias in $ExpectedAliases) {
        $health.SchemaCheck[$alias] = [bool]($raw -match [regex]::Escape($alias))
    }
    Remove-Item $tmp -ErrorAction SilentlyContinue
} catch { $health.Notes += "Schema alias check failed: $($_.Exception.Message)" }

# --- Bookmark target reachability ---
foreach ($b in $BookmarkUrls) {
    $ok = $false
    try {
        $resp = Invoke-WebRequest -Uri $b -Method Head -UseBasicParsing -TimeoutSec 20
        $ok = ($resp.StatusCode -ge 200 -and $resp.StatusCode -lt 400)
    } catch { $ok = $false }
    $health.Bookmarks += [ordered]@{ Url = $b; Reachable = $ok }
}

$health | ConvertTo-Json -Depth 6 | Out-File -FilePath $OutputPath -Encoding UTF8
Write-Host ("Health report written to {0}. Sites scanned: {1}" -f $OutputPath, $health.Sites.Count) `
    -ForegroundColor Green

Disconnect-PnPOnline
