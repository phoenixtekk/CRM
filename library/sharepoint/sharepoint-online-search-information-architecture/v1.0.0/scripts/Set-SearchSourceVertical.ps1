<#
.SYNOPSIS
  Configure a scoped result source and record the intended vertical + promoted-result/bookmark set
  from a JSON config. SAFE BY DEFAULT: dry-run (-WhatIf) unless -Commit is passed.
.DESCRIPTION
  Reads a JSON config describing one or more result sources (name + query transform), search
  verticals, and bookmarks. Result sources are created with PnP where supported; verticals and
  Microsoft Search bookmarks are surfaced as a checklist for the Search & Intelligence admin center
  (their creation is a portal/Graph beta operation that this script does not fabricate). Without
  -Commit nothing is created.
.EXAMPLE
  .\Set-SearchSourceVertical.ps1 -AdminUrl https://contoso-admin.sharepoint.com `
      -ConfigJson .\search-experience.json -WhatIf     # dry-run
  .\Set-SearchSourceVertical.ps1 -AdminUrl https://contoso-admin.sharepoint.com `
      -ConfigJson .\search-experience.json -Commit      # create result sources
  (PowerShell 5.1+/7+, PnP.PowerShell; connect with Connect-PnPOnline.)
.NOTES
  Expected results: dry-run prints the result sources, verticals, and bookmarks to be configured;
  commit creates the result source(s) and prints the exact admin-center steps to add the verticals
  and bookmarks (Microsoft Search & Intelligence admin center). Pass signal = the result source
  returns only the scoped content and the vertical/bookmark appear (see Testing 8-10).
#>
[CmdletBinding(SupportsShouldProcess = $true)]
param(
    [Parameter(Mandatory)] [string] $AdminUrl,
    [Parameter(Mandatory)] [string] $ConfigJson,
    [switch] $Commit
)

$ErrorActionPreference = 'Stop'

if (-not (Test-Path $ConfigJson)) { throw "Config JSON not found: $ConfigJson" }
$cfg = Get-Content -Path $ConfigJson -Raw | ConvertFrom-Json

Write-Host "Connecting to $AdminUrl ..." -ForegroundColor Cyan
Connect-PnPOnline -Url $AdminUrl -Interactive

# --- Result sources ---
Write-Host "`nResult sources:" -ForegroundColor Cyan
foreach ($rs in @($cfg.resultSources)) {
    Write-Host ("  {0}  transform: {1}" -f $rs.name, $rs.queryTransform)
    if ($Commit) {
        if ($PSCmdlet.ShouldProcess($rs.name, "Create/ensure result source")) {
            # Get-/New-PnPSearchExternalDataSource / result source cmdlet availability varies by module
            # version; if unavailable, create in the Search admin center (Manage Result Sources).
            if (Get-Command -Name 'New-PnPSearchResultSource' -ErrorAction SilentlyContinue) {
                try {
                    New-PnPSearchResultSource -Name $rs.name -QueryTemplate $rs.queryTransform `
                        -Protocol Local -ErrorAction Stop | Out-Null
                    Write-Host "    created result source '$($rs.name)'" -ForegroundColor Green
                } catch {
                    Write-Warning "    could not create via cmdlet ($($_.Exception.Message)); create '$($rs.name)' in Search admin center -> Manage Result Sources with the transform above."
                }
            } else {
                Write-Warning "    New-PnPSearchResultSource not available in this module; create '$($rs.name)' in Search admin center -> Manage Result Sources with the transform above."
            }
        }
    }
}

# --- Verticals (Microsoft Search & Intelligence admin center) ---
Write-Host "`nVerticals to add (Search & Intelligence admin center -> Customizations -> Verticals):" -ForegroundColor Cyan
foreach ($v in @($cfg.verticals)) {
    Write-Host ("  {0}  contentSource: {1}  query: {2}" -f $v.name, $v.contentSource, $v.query)
}

# --- Bookmarks / promoted results (Answers -> Bookmarks) ---
Write-Host "`nBookmarks to add (Search & Intelligence admin center -> Answers -> Bookmarks):" -ForegroundColor Cyan
foreach ($b in @($cfg.bookmarks)) {
    Write-Host ("  {0}  url: {1}  keywords: {2}  state: {3}" -f `
        $b.name, $b.url, ($b.keywords -join ','), $b.state)
}

if (-not $Commit) {
    Write-Host "`nDRY-RUN (-WhatIf default). No changes made. Re-run with -Commit to create result sources." -ForegroundColor Green
} else {
    Write-Host "`nResult sources processed. Add the verticals and bookmarks above in the Search & Intelligence admin center (portal/Graph-beta operations; not fabricated here)." -ForegroundColor Yellow
}

Disconnect-PnPOnline
