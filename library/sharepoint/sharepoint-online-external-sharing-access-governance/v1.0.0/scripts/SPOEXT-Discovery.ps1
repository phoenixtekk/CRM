<#
.SYNOPSIS
  SPOEXT-Discovery.ps1 — read-only SharePoint Online / OneDrive external-sharing posture + exposure baseline. Makes NO changes.
.DESCRIPTION
  Builds the "External Exposure - SPO - Discovery" baseline for the external-sharing governance solution:
  the tenant + OneDrive sharing capability, default link type/permission, Anyone-link + guest expiration,
  domain-restriction mode and lists, per-site SharingCapability for the sites in scope, and the count of
  external users. Read-only — it only runs Get-* cmdlets. Use it in Stage 0 (Assess) and to re-verify.
.EXAMPLE
  .\SPOEXT-Discovery.ps1
  # Assess the whole tenant, console summary only.
.EXAMPLE
  .\SPOEXT-Discovery.ps1 -CsvPath .\External-Exposure-Discovery.csv
  # Save the per-site "External Exposure - SPO - Discovery" export.
  # (PowerShell 5.1+/7+, Microsoft.Online.SharePoint.PowerShell; connect with Connect-SPOService.)
.NOTES
  Expected results: a tenant sharing summary + per-site SharingCapability table. Pass signal for later
  stages: the values match the approved "Tenant Sharing Baseline - SPO - Prod". Connect first with
  Connect-SPOService -Url https://<tenant>-admin.sharepoint.com (Government: your .us admin host).
  SharePoint — External Sharing & Access Governance.
#>
[CmdletBinding()]
param(
    [string[]]$SiteScope,       # optional list of site URLs; default = all sites
    [string]$CsvPath
)

if (-not (Get-Module -ListAvailable -Name Microsoft.Online.SharePoint.PowerShell)) {
    Write-Host 'Installing Microsoft.Online.SharePoint.PowerShell for current user...' -ForegroundColor Yellow
    Install-Module Microsoft.Online.SharePoint.PowerShell -Scope CurrentUser -Force
}
Import-Module Microsoft.Online.SharePoint.PowerShell -ErrorAction Stop

try { $null = Get-SPOTenant -ErrorAction Stop }
catch {
    Write-Warning 'Not connected. Run: Connect-SPOService -Url https://<tenant>-admin.sharepoint.com (Government: your .us admin host).'
    return
}

Write-Host '=== External Exposure - SPO - Discovery (read-only) ===' -ForegroundColor Cyan

$t = Get-SPOTenant
Write-Host '--- Tenant + OneDrive sharing baseline ---' -ForegroundColor Cyan
$t | Select-Object `
    SharingCapability, OneDriveSharingCapability,
    DefaultSharingLinkType, DefaultLinkPermission,
    RequireAnonymousLinksExpireInDays,
    ExternalUserExpirationRequired, ExternalUserExpireInDays,
    SharingDomainRestrictionMode,
    @{n='SharingAllowedDomainList';e={ $_.SharingAllowedDomainList }},
    @{n='SharingBlockedDomainList';e={ $_.SharingBlockedDomainList }},
    PreventExternalUsersFromResharing, RequireAcceptingAccountMatchInvitedAccount |
    Format-List

# Per-site sharing capability (the exposure surface)
if ($SiteScope) {
    $sites = foreach ($u in $SiteScope) {
        try { Get-SPOSite -Identity $u -Detailed -ErrorAction Stop }
        catch { Write-Warning ("Cannot read site '{0}': {1}" -f $u, $_.Exception.Message) }
    }
} else {
    $sites = Get-SPOSite -Limit All -Detailed
}

$rows = foreach ($s in $sites) {
    [pscustomobject]@{
        Url                 = $s.Url
        Title               = $s.Title
        SharingCapability   = $s.SharingCapability
        SharingDomainMode   = $s.SharingDomainRestrictionMode
        SensitivityLabel    = $s.SensitivityLabel
        ConditionalAccess   = $s.ConditionalAccessPolicy
    }
}
$rows | Sort-Object Url | Format-Table Url, SharingCapability, SharingDomainMode, SensitivityLabel -AutoSize

# External user population (read-only)
$extCount = $null
try {
    $ext = Get-SPOExternalUser -PageSize 50 -ErrorAction Stop
    $extCount = @($ext).Count
} catch {
    Write-Warning ("Could not enumerate external users: {0}" -f $_.Exception.Message)
}

$loose = @($rows | Where-Object { $_.SharingCapability -eq 'ExternalUserAndGuestSharing' }).Count
Write-Host ("Sites assessed: {0} | Anyone-capable sites: {1} | external users (first page): {2}" -f `
    $rows.Count, $loose, $extCount) -ForegroundColor Cyan

if ($CsvPath) {
    $rows | Export-Csv -Path $CsvPath -NoTypeInformation
    Write-Host ("Saved 'External Exposure - SPO - Discovery' to {0}" -f $CsvPath) -ForegroundColor Green
}
