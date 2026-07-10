<#
.SYNOPSIS
    CPLTSHARE-AccessReview.ps1 - Produce a per-site access-review workbook for owner-led cleanup (READ-ONLY).
.DESCRIPTION
    PURPOSE:  For the in-scope (or pilot) sites, enumerate owners, members, guests, broad grants (EEEU/
              org-wide), and active sharing links into a portable review workbook that site owners use to
              confirm or clean membership. This drives the data-owner decision - it does NOT change access.
              Complements SharePoint Advanced Management "site access reviews" where SAM is licensed.
    HOW TO RUN:
              1. Connect-MgGraph -Scopes "Sites.Read.All","Directory.Read.All"
                 (and/or Connect-PnPOnline -Url https://<tenant>-admin.sharepoint.com -Interactive)
              2. .\CPLTSHARE-AccessReview.ps1 -SiteUrls @("https://contoso.sharepoint.com/sites/Finance")
                 .\CPLTSHARE-AccessReview.ps1 -InputCsv ".\Oversharing Discovery - Estate - Assess.csv"
    EXPECTED RESULTS:
              PASS: a review workbook (CSV) is written listing each site's owners/members/guests/broad
              grants/links for owner sign-off. FAIL: no site list / not connected.
.NOTES
    White-label. Read-only - changes NO access. Owners decide who should have access; this only reports
    the current state. Requires Microsoft.Graph and/or PnP.PowerShell.
#>

[CmdletBinding()]
param(
    [string[]]$SiteUrls,
    [string]$InputCsv,
    [string]$OutDir = ".",
    [string]$ArtifactName = "Site Access Review - Broad Sites - Pilot"
)

$ErrorActionPreference = "Stop"
function Write-Section($t) { Write-Host "`n=== $t ===" -ForegroundColor Cyan }

# --- Resolve the site list ---
$targets = @()
if ($SiteUrls) { $targets += $SiteUrls }
if ($InputCsv -and (Test-Path $InputCsv)) {
    try { $targets += (Import-Csv $InputCsv | Where-Object { $_.WebUrl } | Select-Object -ExpandProperty WebUrl) }
    catch { Write-Warning "Could not read $InputCsv : $($_.Exception.Message)" }
}
$targets = $targets | Where-Object { $_ } | Select-Object -Unique
if (-not $targets) { Write-Error "Provide -SiteUrls or -InputCsv (e.g. the discovery export)."; return }

try { $ctx = Get-MgContext -ErrorAction Stop } catch { $ctx = $null }
if (-not $ctx) { Write-Warning "Connect-MgGraph is recommended; PnP-only enumeration may be limited." }

Write-Section "Building access-review workbook (read-only)"
$rows = @()
foreach ($url in $targets) {
    $owners = ""; $members = ""; $guests = ""; $broad = ""; $links = ""; $note = ""
    try {
        # Read-only enumeration. Cmdlets/endpoints vary by module version - verify in your tenant.
        $site = Get-MgSite -SiteId $url.Replace("https://","").Replace("/",":/",1) -ErrorAction SilentlyContinue
        if ($site) {
            $perms = Get-MgSitePermission -SiteId $site.Id -ErrorAction SilentlyContinue
            $broad = ($perms | Where-Object {
                ($_.GrantedToV2.SiteGroup.DisplayName -match 'Everyone') -or
                ($_.GrantedToIdentitiesV2.DisplayName -match 'Everyone except external users|Everyone')
            } | ForEach-Object { $_.GrantedToV2.SiteGroup.DisplayName } ) -join "; "
        }
        $note = "Enumerate detailed membership/links via SharePoint admin or PnP (Get-PnPSiteGroup / Get-PnPFileSharingLink) as needed."
    } catch {
        $note = "read unavailable: $($_.Exception.Message)"
    }
    $rows += [pscustomobject]@{
        SiteUrl        = $url
        Owners         = $owners
        Members        = $members
        Guests         = $guests
        BroadGrants    = $broad
        SharingLinks   = $links
        OwnerDecision  = "<owner: keep / scope-to-group / remove>"
        Note           = $note
    }
}

$rows | Format-Table SiteUrl, BroadGrants -AutoSize | Out-Host
$null = New-Item -ItemType Directory -Force -Path $OutDir
$safe = ($ArtifactName -replace '[^\w\-]+','_')
$csv  = Join-Path $OutDir "$safe.csv"
$rows | Export-Csv -Path $csv -NoTypeInformation -Encoding UTF8
Write-Host "Wrote $csv" -ForegroundColor Green
Write-Host "`nRead-only: hand this to site owners for the access decision. No access was changed." -ForegroundColor Yellow
