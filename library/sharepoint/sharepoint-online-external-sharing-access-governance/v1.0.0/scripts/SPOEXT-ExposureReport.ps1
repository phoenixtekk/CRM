<#
.SYNOPSIS
  SPOEXT-ExposureReport.ps1 — read-only external-exposure report: sharing links + external principals across the sites in scope. Makes NO changes.
.DESCRIPTION
  Reporting for Stage 3/4. For each site in -SiteScope it enumerates file/folder sharing links via PnP
  (Get-PnPFileSharingLink / Get-PnPFolderSharingLink) and flags Anyone (anonymous) links, links with no
  expiration, and external principals. With -IncludeGuests it also lists the tenant's external users
  (Get-SPOExternalUser) as a guest-review fallback. Produces "External Exposure - SPO - Report". Fully
  read-only. Enumeration can be throttled on very large sites — scope accordingly.
.EXAMPLE
  .\SPOEXT-ExposureReport.ps1 -SiteScope (Get-Content .\pilot-sites.txt) -CsvPath .\External-Exposure-Report.csv
  # Report sharing links across the pilot sites.
.EXAMPLE
  .\SPOEXT-ExposureReport.ps1 -IncludeGuests -CsvPath .\Guest-Review.csv
  # Guest-review fallback when Entra Access Reviews are not licensed.
  # (PowerShell 7+, PnP.PowerShell + Microsoft.Online.SharePoint.PowerShell; Connect-PnPOnline per site.)
.NOTES
  Expected results: a CSV of sharing links (site, item, LinkKind, Anyone?, expiration, principals) plus a
  flagged summary. Connect PnP per site: Connect-PnPOnline -Url <site> -Interactive. On Government clouds
  use the correct AzureEnvironment. SharePoint — External Sharing & Access Governance.
#>
[CmdletBinding()]
param(
    [string[]]$SiteScope,
    [switch]$IncludeGuests,
    [int]$MaxItemsPerLibrary = 500,
    [string]$CsvPath
)

$rows = New-Object System.Collections.Generic.List[object]

if ($SiteScope) {
    if (-not (Get-Module -ListAvailable -Name PnP.PowerShell)) {
        Write-Host 'Installing PnP.PowerShell for current user...' -ForegroundColor Yellow
        Install-Module PnP.PowerShell -Scope CurrentUser -Force
    }
    Import-Module PnP.PowerShell -ErrorAction Stop

    foreach ($site in $SiteScope) {
        Write-Host ("--- Enumerating sharing links: {0}" -f $site) -ForegroundColor Cyan
        try {
            Connect-PnPOnline -Url $site -Interactive -ErrorAction Stop
        } catch {
            Write-Warning ("Cannot connect to {0}: {1}" -f $site, $_.Exception.Message); continue
        }

        # Document libraries only (BaseTemplate 101)
        $libs = Get-PnPList -ErrorAction SilentlyContinue | Where-Object { $_.BaseTemplate -eq 101 -and -not $_.Hidden }
        foreach ($lib in $libs) {
            $items = Get-PnPListItem -List $lib -PageSize 200 -Fields 'FileRef','FileLeafRef','FSObjType' -ErrorAction SilentlyContinue |
                Select-Object -First $MaxItemsPerLibrary
            foreach ($item in $items) {
                $isFolder = ($item['FSObjType'] -eq 1)
                $links = @()
                try {
                    if ($isFolder) { $links = Get-PnPFolderSharingLink -Folder $item['FileRef'] -ErrorAction SilentlyContinue }
                    else           { $links = Get-PnPFileSharingLink   -FileUrl $item['FileRef'] -ErrorAction SilentlyContinue }
                } catch { }
                foreach ($lk in $links) {
                    $scope = $lk.Link.Scope          # anonymous | organization | users
                    $exp   = $lk.Link.ExpirationDateTime
                    $princ = ($lk.GrantedToIdentitiesV2 | ForEach-Object { $_.User.Email } | Where-Object { $_ }) -join ';'
                    $rows.Add([pscustomobject]@{
                        Site         = $site
                        Item         = $item['FileRef']
                        Type         = if ($isFolder) { 'Folder' } else { 'File' }
                        LinkScope    = $scope
                        IsAnyone     = ($scope -eq 'anonymous')
                        Permission   = $lk.Link.Type      # view | edit | review ...
                        Expiration   = $exp
                        NoExpiration = [string]::IsNullOrEmpty($exp)
                        Principals   = $princ
                    })
                }
            }
        }
        Disconnect-PnPOnline -ErrorAction SilentlyContinue
    }
}

if ($IncludeGuests) {
    if (-not (Get-Module -ListAvailable -Name Microsoft.Online.SharePoint.PowerShell)) {
        Install-Module Microsoft.Online.SharePoint.PowerShell -Scope CurrentUser -Force
    }
    Import-Module Microsoft.Online.SharePoint.PowerShell -ErrorAction Stop
    try {
        Write-Host '--- External users (guest-review fallback) ---' -ForegroundColor Cyan
        $page = 0
        do {
            $batch = Get-SPOExternalUser -Position ($page * 50) -PageSize 50 -ErrorAction Stop
            foreach ($g in $batch) {
                $rows.Add([pscustomobject]@{
                    Site='(tenant)'; Item='(external user)'; Type='Guest'; LinkScope='guest'
                    IsAnyone=$false; Permission=''; Expiration=''; NoExpiration=$false
                    Principals=("{0} <{1}> invited {2}" -f $g.DisplayName, $g.Email, $g.WhenCreated)
                })
            }
            $page++
        } while (@($batch).Count -eq 50)
    } catch {
        Write-Warning ("Could not enumerate external users: {0}" -f $_.Exception.Message)
    }
}

# Summary
$anyone   = @($rows | Where-Object { $_.IsAnyone }).Count
$noExpire = @($rows | Where-Object { $_.NoExpiration -and $_.LinkScope -ne 'guest' }).Count
Write-Host ("External Exposure - SPO - Report: {0} link/principal rows | Anyone-links: {1} | links with no expiration: {2}" -f `
    $rows.Count, $anyone, $noExpire) -ForegroundColor Cyan
if ($anyone -gt 0)   { Write-Host ("  FLAG: {0} Anyone (anonymous) link(s) — review against policy." -f $anyone) -ForegroundColor Yellow }
if ($noExpire -gt 0) { Write-Host ("  FLAG: {0} link(s) with no expiration — review against policy." -f $noExpire) -ForegroundColor Yellow }

if ($CsvPath) {
    $rows | Export-Csv -Path $CsvPath -NoTypeInformation
    Write-Host ("Saved 'External Exposure - SPO - Report' to {0}" -f $CsvPath) -ForegroundColor Green
} elseif ($rows.Count) {
    $rows | Format-Table Site, Type, LinkScope, IsAnyone, Expiration, Principals -AutoSize
}
