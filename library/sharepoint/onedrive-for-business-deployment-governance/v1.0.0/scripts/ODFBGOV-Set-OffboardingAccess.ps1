<#
.SYNOPSIS
    ODFBGOV-Set-OffboardingAccess.ps1 — grant a departing user's manager access to their OneDrive and confirm retention (dry-run by default; -Commit to apply).
.DESCRIPTION
    PURPOSE
        On a user departure, preserves and hands off their OneDrive data WITHOUT deleting anything.
        Resolves the user's OneDrive personal site, grants a delegate (typically the manager) as a
        site-collection administrator so they can retrieve needed files, and reports the tenant
        orphaned-OneDrive retention period so operators know how long the data survives account
        deletion. SAFE BY DEFAULT: previews the grant unless -Commit is passed. It never deletes the
        account, the OneDrive, or any content, and never removes a hold.
    HOW TO RUN
        # Preview:
        .\ODFBGOV-Set-OffboardingAccess.ps1 -AdminUrl https://contoso-admin.sharepoint.com -DepartingUser jdoe@contoso.com -Delegate manager@contoso.com -WhatIf
        # Apply:
        .\ODFBGOV-Set-OffboardingAccess.ps1 -AdminUrl https://contoso-admin.sharepoint.com -DepartingUser jdoe@contoso.com -Delegate manager@contoso.com -Commit
        (PowerShell 5.1+/7+; Microsoft.Online.SharePoint.PowerShell; Connect-SPOService modern auth.)
    EXPECTED RESULTS
        Confirms the resolved OneDrive URL, the retention period in days, and (with -Commit) that the
        delegate now holds site-collection admin on "Offboarding Access - Manager - Prod". Legal hold /
        records determinations are DEFERRED to compliance — this only grants operational access.
.NOTES
    SharePoint category — OneDrive for Business Deployment & Governance. Writes only with -Commit; honors -WhatIf.
    Placing the OneDrive on retention/eDiscovery hold (Purview) is a COMPLIANCE decision — out of scope here.
#>
[CmdletBinding(SupportsShouldProcess, ConfirmImpact = 'High')]
param(
    [Parameter(Mandatory)][string]$AdminUrl,
    [Parameter(Mandatory)][string]$DepartingUser,
    [Parameter(Mandatory)][string]$Delegate,
    [switch]$Commit
)

if (-not (Get-Module -ListAvailable -Name Microsoft.Online.SharePoint.PowerShell)) {
    Install-Module Microsoft.Online.SharePoint.PowerShell -Scope CurrentUser -Force -AllowClobber
}
Import-Module Microsoft.Online.SharePoint.PowerShell -DisableNameChecking -ErrorAction Stop
Connect-SPOService -Url $AdminUrl

# Resolve the departing user's OneDrive personal site (owner match).
$od = Get-SPOSite -IncludePersonalSite $true -Limit All -Filter "Url -like '-my.sharepoint.com/personal/'" |
      Where-Object { $_.Owner -eq $DepartingUser } | Select-Object -First 1

if (-not $od) {
    Write-Warning "No provisioned OneDrive found for $DepartingUser. The site may not be provisioned, or the owner UPN differs. Aborting."
    Disconnect-SPOService; return
}

$retention = (Get-SPOTenant).OrphanedPersonalSitesRetentionPeriod
Write-Host '=== Offboarding Access - Manager - Prod ===' -ForegroundColor Cyan
[pscustomobject]@{
    DepartingUser       = $DepartingUser
    OneDriveUrl         = $od.Url
    Delegate            = $Delegate
    RetentionAfterDelete= "$retention days (tenant OrphanedPersonalSitesRetentionPeriod)"
} | Format-List

if (-not $Commit) {
    Write-Host 'DRY-RUN: no access granted. Re-run with -Commit to apply.' -ForegroundColor Yellow
    Disconnect-SPOService; return
}

if ($PSCmdlet.ShouldProcess($od.Url, "Grant site-collection admin to $Delegate")) {
    Set-SPOUser -Site $od.Url -LoginName $Delegate -IsSiteCollectionAdmin $true | Out-Null
    Write-Host ("Granted {0} site-collection admin on {1}." -f $Delegate, $od.Url) -ForegroundColor Green
    Write-Host 'Reminder: remove this grant once handoff is complete; confirm any legal/records hold with compliance BEFORE deleting the account.' -ForegroundColor Yellow
}

Disconnect-SPOService
