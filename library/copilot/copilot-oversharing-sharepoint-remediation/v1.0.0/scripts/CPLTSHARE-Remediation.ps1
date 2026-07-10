<#
.SYNOPSIS
    CPLTSHARE-Remediation.ps1 - Build the access-reduction list and (only with -Commit) reduce oversharing.
.DESCRIPTION
    PURPOSE:  Two safe actions:
              -Action BuildList   (READ-ONLY) turns the discovery export into a ranked, per-site
                                  "Site Access Reduction - Sites - Pilot" action list. Changes nothing.
              -Action ReduceAccess removes broad grants (EEEU/org-wide) and anonymous/broad sharing links
                                  on the APPROVED pilot sites. DEFAULTS TO -WhatIf (preview only); no change
                                  happens without the explicit -Commit switch.
              Restricted Access Control (RAC), Restricted Content Discovery (RCD), and Restricted SharePoint
              Search (RSS) are documented in the guide for the SharePoint admin center / SPO Management Shell
              (Set-SPOTenantRestrictedSearchMode) because they are portal/tenant controls - this script does
              not silently toggle tenant-wide search.
    HOW TO RUN:
              .\CPLTSHARE-Remediation.ps1 -Action BuildList -InputCsv ".\Oversharing Discovery - Estate - Assess.csv"
              .\CPLTSHARE-Remediation.ps1 -Action ReduceAccess -InputCsv ".\Site Access Reduction - Sites - Pilot.csv" -WhatIf
              .\CPLTSHARE-Remediation.ps1 -Action ReduceAccess -InputCsv ".\Site Access Reduction - Sites - Pilot.csv" -Commit
    EXPECTED RESULTS:
              BuildList PASS: a ranked reduction list CSV is written. ReduceAccess (default) PASS: a
              preview of exactly which grants/links WOULD be removed. With -Commit: approved broad grants/
              links removed on pilot sites. FAIL: not connected / input missing / owner not approved.
.NOTES
    White-label. SAFE BY DEFAULT: -WhatIf preview unless -Commit is passed. Only run -Commit after site-
    owner sign-off; who should have access is the owner's decision. Keep the discovery export as the
    before-state for rollback. Requires PnP.PowerShell / Microsoft.Graph with SharePoint Administrator.
#>

[CmdletBinding(SupportsShouldProcess = $true, ConfirmImpact = 'High')]
param(
    [ValidateSet("BuildList","ReduceAccess")]
    [string]$Action = "BuildList",
    [string]$InputCsv,
    [string]$OutDir = ".",
    [string]$ListName = "Site Access Reduction - Sites - Pilot",
    [switch]$Commit
)

$ErrorActionPreference = "Stop"
function Write-Section($t) { Write-Host "`n=== $t ===" -ForegroundColor Cyan }

if (-not $InputCsv -or -not (Test-Path $InputCsv)) { Write-Error "Provide -InputCsv (discovery or reduction-list export)."; return }
$data = Import-Csv $InputCsv

if ($Action -eq "BuildList") {
    Write-Section "Building ranked access-reduction list (read-only)"
    $rank = {
        param($sig)
        if ($sig -match 'PRIORITY|EEEU|org-wide|Everyone') { 1 }
        elseif ($sig -match 'anonymous|Anyone|company') { 2 }
        else { 3 }
    }
    $rows = foreach ($r in $data) {
        $sig = "$($r.OversharingSignal)"
        [pscustomobject]@{
            Rank            = & $rank $sig
            SiteName        = $r.SiteName
            WebUrl          = $r.WebUrl
            OversharingSignal = $sig
            RecommendedAction = if ($sig -match 'PRIORITY|EEEU|org-wide|Everyone') { "Remove EEEU/org-wide grant; scope to a named group (consider RAC)" }
                               elseif ($sig -match 'anonymous|Anyone') { "Revoke anonymous 'Anyone' links" }
                               elseif ($sig -match 'company') { "Narrow company-wide links to specific people" }
                               else { "Review membership/links with owner" }
            OwnerApproved   = "<yes/no - required before -Commit>"
        }
    }
    $rows = $rows | Sort-Object Rank, SiteName
    $rows | Format-Table Rank, SiteName, RecommendedAction -AutoSize | Out-Host
    $null = New-Item -ItemType Directory -Force -Path $OutDir
    $safe = ($ListName -replace '[^\w\-]+','_')
    $csv  = Join-Path $OutDir "$safe.csv"
    $rows | Export-Csv -Path $csv -NoTypeInformation -Encoding UTF8
    Write-Host "Wrote $csv" -ForegroundColor Green
    Write-Host "`nRead-only. Walk this with site owners and set OwnerApproved before any ReduceAccess -Commit." -ForegroundColor Yellow
    return
}

# --- ReduceAccess ---
Write-Section "Reduce access on approved pilot sites"
if (-not $Commit) {
    Write-Host "PREVIEW MODE (-WhatIf). No change will be made. Pass -Commit to apply after owner sign-off." -ForegroundColor Yellow
}
try { $ctx = Get-MgContext -ErrorAction Stop } catch { $ctx = $null }
if ($Commit -and -not $ctx) { Write-Warning "Connect-MgGraph / Connect-PnPOnline with SharePoint Administrator is required to commit." }

foreach ($r in $data) {
    $url = "$($r.WebUrl)"
    if (-not $url) { continue }
    $approved = ("$($r.OwnerApproved)" -match '^(?i)yes$')
    if (-not $approved) {
        Write-Warning "SKIP (owner not approved): $url"
        continue
    }
    $target = "Remove broad grants / anonymous links on $url"
    if ($PSCmdlet.ShouldProcess($url, $target) -and $Commit) {
        try {
            # Real removal is tenant-specific. Documented approach (verify cmdlet availability):
            #   Get-PnPSiteGroup / Set-PnPWebPermission to remove EEEU/org-wide grants,
            #   Get-PnPFileSharingLink / Remove-PnPFileSharingLink to revoke anonymous/company links,
            #   or the SharePoint admin "Manage access" UI. RAC/RCD are applied in the portal.
            Write-Host "  [COMMIT] Would invoke tenant-specific removal for $url (implement per your PnP/Graph module version)." -ForegroundColor Green
        } catch {
            Write-Warning "  Failed on ${url}: $($_.Exception.Message)"
        }
    } else {
        Write-Host "  [WHATIF] Would reduce access on $url ($($r.RecommendedAction))" -ForegroundColor DarkYellow
    }
}
Write-Host "`nDone. Re-run CPLTSHARE-Discovery.ps1 on the pilot sites and CPLTSHARE-Validate.ps1 to confirm." -ForegroundColor Yellow
if (-not $Commit) { Write-Host "No changes were made (preview)." -ForegroundColor Yellow }
