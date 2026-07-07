<#
.SYNOPSIS
  SPOEXT-Set-Sharing.ps1 — apply the tenant sharing baseline and/or tighten site-level sharing. SAFE BY DEFAULT: dry-run/-WhatIf unless -Commit.
.DESCRIPTION
  Configuration helper for Stage 2. In -TenantBaseline mode it sets "Tenant Sharing Baseline - SPO -
  Prod" (SharingCapability, OneDrive capability, default link type/permission, Anyone-link + guest
  expiration, domain-restriction mode + list) via Set-SPOTenant. In site mode it tightens each site in
  -SiteScope to -SiteSharingCapability via Set-SPOSite. Without -Commit it only REPORTS what it would do
  (dry run); -WhatIf is honored on the write cmdlets. Tightening tenant sharing can DISABLE existing
  links of a now-disallowed type — run in a change window with the Stage-0 rollback values ready.
.EXAMPLE
  .\SPOEXT-Set-Sharing.ps1 -SiteScope (Get-Content .\pilot-sites.txt) -SiteSharingCapability ExistingExternalUserSharingOnly -WhatIf
  # Dry run — shows the Set-SPOSite calls it would make on the pilot sites, changes nothing.
.EXAMPLE
  .\SPOEXT-Set-Sharing.ps1 -TenantBaseline -SharingCapability ExternalUserSharingOnly -DefaultLinkType Direct -DefaultLinkPermission View -GuestExpireDays 60 -DomainMode AllowList -DomainList "fabrikam.com contoso-partner.com" -Commit
  # Apply the tenant baseline (change window).
  # (PowerShell 5.1+/7+, Microsoft.Online.SharePoint.PowerShell; connect with Connect-SPOService.)
.NOTES
  Expected results: named settings applied; verify with SPOEXT-Validation.ps1 / SPOEXT-Discovery.ps1.
  Site SharingCapability can only be EQUAL TO or TIGHTER than the tenant. SharePoint — External Sharing
  & Access Governance.
#>
[CmdletBinding(SupportsShouldProcess = $true)]
param(
    # --- Tenant baseline mode ---
    [switch]$TenantBaseline,
    [ValidateSet('Disabled','ExistingExternalUserSharingOnly','ExternalUserSharingOnly','ExternalUserAndGuestSharing')]
    [string]$SharingCapability,
    [ValidateSet('Disabled','ExistingExternalUserSharingOnly','ExternalUserSharingOnly','ExternalUserAndGuestSharing')]
    [string]$OneDriveSharingCapability,
    [ValidateSet('Direct','Internal','AnonymousAccess')]
    [string]$DefaultLinkType,
    [ValidateSet('View','Edit')]
    [string]$DefaultLinkPermission,
    [int]$AnonymousLinkExpireDays,
    [int]$GuestExpireDays,
    [ValidateSet('None','AllowList','BlockList')]
    [string]$DomainMode,
    [string]$DomainList,   # space-separated domains, e.g. "fabrikam.com contoso-partner.com"

    # --- Site mode ---
    [string[]]$SiteScope,
    [ValidateSet('Disabled','ExistingExternalUserSharingOnly','ExternalUserSharingOnly','ExternalUserAndGuestSharing')]
    [string]$SiteSharingCapability,

    [switch]$Commit
)

if (-not (Get-Module -ListAvailable -Name Microsoft.Online.SharePoint.PowerShell)) {
    Install-Module Microsoft.Online.SharePoint.PowerShell -Scope CurrentUser -Force
}
Import-Module Microsoft.Online.SharePoint.PowerShell -ErrorAction Stop

try { $null = Get-SPOTenant -ErrorAction Stop }
catch {
    Write-Warning 'Not connected. Run: Connect-SPOService -Url https://<tenant>-admin.sharepoint.com (Government: your .us admin host).'
    return
}

if (-not $Commit) {
    Write-Host 'DRY RUN — no changes will be made. Re-run with -Commit to apply.' -ForegroundColor Yellow
}

# ---------------- Tenant baseline ----------------
if ($TenantBaseline) {
    Write-Host '--- Applying: Tenant Sharing Baseline - SPO - Prod ---' -ForegroundColor Cyan
    if ($SharingCapability -eq 'ExternalUserAndGuestSharing') {
        Write-Host 'NOTE: ExternalUserAndGuestSharing permits ANYONE (unauthenticated) links. Ensure expiration + view-only are set.' -ForegroundColor Yellow
    }
    $tParams = @{}
    if ($SharingCapability)            { $tParams.SharingCapability            = $SharingCapability }
    if ($OneDriveSharingCapability)    { $tParams.OneDriveSharingCapability    = $OneDriveSharingCapability }
    if ($DefaultLinkType)              { $tParams.DefaultSharingLinkType       = $DefaultLinkType }
    if ($DefaultLinkPermission)        { $tParams.DefaultLinkPermission        = $DefaultLinkPermission }
    if ($PSBoundParameters.ContainsKey('AnonymousLinkExpireDays')) { $tParams.RequireAnonymousLinksExpireInDays = $AnonymousLinkExpireDays }
    if ($PSBoundParameters.ContainsKey('GuestExpireDays')) {
        $tParams.ExternalUserExpirationRequired = $true
        $tParams.ExternalUserExpireInDays       = $GuestExpireDays
    }
    if ($DomainMode)                   { $tParams.SharingDomainRestrictionMode = $DomainMode }
    if ($DomainMode -eq 'AllowList' -and $DomainList) { $tParams.SharingAllowedDomainList = $DomainList }
    if ($DomainMode -eq 'BlockList' -and $DomainList) { $tParams.SharingBlockedDomainList = $DomainList }

    if ($tParams.Count -eq 0) {
        Write-Warning 'No tenant baseline values supplied — nothing to do.'
    }
    else {
        $summary = ($tParams.GetEnumerator() | ForEach-Object { "{0}={1}" -f $_.Key, $_.Value }) -join '; '
        if ($Commit) {
            if ($PSCmdlet.ShouldProcess('Set-SPOTenant', $summary)) {
                try {
                    Set-SPOTenant @tParams -ErrorAction Stop
                    Write-Host ("[applied] Set-SPOTenant {0}" -f $summary) -ForegroundColor Green
                } catch {
                    Write-Warning ("[fail] Set-SPOTenant — {0}" -f $_.Exception.Message)
                }
            }
        } else {
            Write-Host ("[would apply] Set-SPOTenant {0}" -f $summary) -ForegroundColor Yellow
        }
    }
}

# ---------------- Per-site tightening ----------------
if ($SiteScope -and $SiteSharingCapability) {
    Write-Host ("--- Tightening sites to '{0}' (Site Sharing - <SiteName> - Prod) ---" -f $SiteSharingCapability) -ForegroundColor Cyan
    $tenantCap = (Get-SPOTenant).SharingCapability
    foreach ($url in $SiteScope) {
        $s = try { Get-SPOSite -Identity $url -ErrorAction Stop } catch { Write-Warning ("Skip '{0}': {1}" -f $url, $_.Exception.Message); continue }
        if ($s.SharingCapability -eq $SiteSharingCapability) {
            Write-Host ("[skip] {0} — already {1}" -f $url, $SiteSharingCapability) -ForegroundColor DarkGray
            continue
        }
        if ($Commit) {
            if ($PSCmdlet.ShouldProcess($url, ("Set-SPOSite -SharingCapability {0}" -f $SiteSharingCapability))) {
                try {
                    Set-SPOSite -Identity $url -SharingCapability $SiteSharingCapability -ErrorAction Stop
                    Write-Host ("[set] {0} — {1}" -f $url, $SiteSharingCapability) -ForegroundColor Green
                } catch {
                    Write-Warning ("[fail] {0} — {1} (a site cannot be LOOSER than the tenant '{2}')" -f $url, $_.Exception.Message, $tenantCap)
                }
            }
        } else {
            Write-Host ("[would set] {0} — {1} (from {2})" -f $url, $SiteSharingCapability, $s.SharingCapability) -ForegroundColor Yellow
        }
    }
}

if (-not $TenantBaseline -and -not ($SiteScope -and $SiteSharingCapability)) {
    Write-Warning 'Nothing to do: pass -TenantBaseline (with values) and/or -SiteScope + -SiteSharingCapability.'
}
Write-Host 'Done. Verify with SPOEXT-Validation.ps1.' -ForegroundColor Cyan
