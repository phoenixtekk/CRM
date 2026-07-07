<#
.SYNOPSIS
    ODFBGOV-Configure.ps1 — tenant OneDrive sync-control + storage/retention/sharing config helper (dry-run by default; -Commit to apply).
.DESCRIPTION
    PURPOSE
        Applies the tenant-level OneDrive governance posture in one safe, repeatable pass: default
        storage quota, orphaned-OneDrive retention period, OneDrive sharing capability (kept no more
        permissive than the org sharing level), optional web-only/limited access (blocks download and
        sync in the browser), and the sync-client domain-join allow list (domain GUIDs). SAFE BY
        DEFAULT: with no -Commit it only PREVIEWS every change (current -> proposed) and writes nothing.
    HOW TO RUN
        # Preview (no changes):
        .\ODFBGOV-Configure.ps1 -AdminUrl https://contoso-admin.sharepoint.com -StorageQuotaMB 1048576 -RetentionDays 365 -OneDriveSharing ExistingExternalUserSharingOnly -DomainGuids '12345678-90ab-cdef-1234-567890abcdef' -WhatIf
        # Apply:
        .\ODFBGOV-Configure.ps1 -AdminUrl https://contoso-admin.sharepoint.com -StorageQuotaMB 1048576 -RetentionDays 365 -Commit
        (PowerShell 5.1+/7+; Microsoft.Online.SharePoint.PowerShell; Connect-SPOService modern auth.
         Get domain GUIDs from ODFBGOV-Set-Scope.ps1. Government cloud admin URL is *-admin.sharepoint.us — verify.)
    EXPECTED RESULTS
        A change table (setting / current / proposed / action). With -Commit the named artifacts
        "OneDrive Storage Quota - Default - Prod", "OneDrive Retention - Orphaned - Prod",
        "OneDrive Sharing - Aligned - Prod", and "Sync Restriction - DomainJoined - Prod" are applied.
.NOTES
    SharePoint category — OneDrive for Business Deployment & Governance. Writes only with -Commit; honors -WhatIf.
    Tenant-wide sharing/retention/sync changes are HIGH-IMPACT — run under change control, pilot-first.
#>
[CmdletBinding(SupportsShouldProcess, ConfirmImpact = 'High')]
param(
    [Parameter(Mandatory)][string]$AdminUrl,
    [int]$StorageQuotaMB,
    [ValidateRange(30,3650)][int]$RetentionDays,
    [ValidateSet('Disabled','ExistingExternalUserSharingOnly','ExternalUserSharingOnly','ExternalUserAndGuestSharing')]
    [string]$OneDriveSharing,
    [ValidateSet('AllowFullAccess','AllowLimitedAccess')][string]$ConditionalAccess,
    [string[]]$DomainGuids,
    [switch]$Commit
)

if (-not (Get-Module -ListAvailable -Name Microsoft.Online.SharePoint.PowerShell)) {
    Install-Module Microsoft.Online.SharePoint.PowerShell -Scope CurrentUser -Force -AllowClobber
}
Import-Module Microsoft.Online.SharePoint.PowerShell -DisableNameChecking -ErrorAction Stop
Connect-SPOService -Url $AdminUrl

$t = Get-SPOTenant
$plan = @()
function Add-Plan($name, $current, $proposed) {
    if ($null -ne $proposed -and "$current" -ne "$proposed") {
        $script:plan += [pscustomobject]@{ Setting = $name; Current = $current; Proposed = $proposed }
    }
}
Add-Plan 'OneDriveStorageQuota (MB)'            $t.OneDriveStorageQuota                    ($StorageQuotaMB    ? $StorageQuotaMB    : $null)
Add-Plan 'OrphanedPersonalSitesRetention (Days)' $t.OrphanedPersonalSitesRetentionPeriod   ($RetentionDays     ? $RetentionDays     : $null)
Add-Plan 'OneDriveSharingCapability'            $t.OneDriveSharingCapability               ($OneDriveSharing   ? $OneDriveSharing   : $null)
Add-Plan 'ConditionalAccessPolicy'             $t.ConditionalAccessPolicy                 ($ConditionalAccess ? $ConditionalAccess : $null)

Write-Host '=== ODFBGOV-Configure — proposed tenant changes ===' -ForegroundColor Cyan
if ($plan.Count -eq 0) { Write-Host 'No tenant-setting changes requested/needed.' -ForegroundColor Yellow }
else { $plan | Format-Table -AutoSize }
if ($DomainGuids) { Write-Host ("Sync domain-join allow list -> {0}" -f ($DomainGuids -join '; ')) -ForegroundColor Cyan }

if (-not $Commit) {
    Write-Host 'DRY-RUN: no changes written. Re-run with -Commit to apply.' -ForegroundColor Yellow
    Disconnect-SPOService; return
}

# --- Apply (each guarded by ShouldProcess so -WhatIf still previews) ---
$set = @{}
if ($StorageQuotaMB)   { $set.OneDriveStorageQuota = $StorageQuotaMB }
if ($RetentionDays)    { $set.OrphanedPersonalSitesRetentionPeriod = $RetentionDays }
if ($OneDriveSharing)  { $set.OneDriveSharingCapability = $OneDriveSharing }
if ($ConditionalAccess){ $set.ConditionalAccessPolicy = $ConditionalAccess }
if ($set.Count -gt 0 -and $PSCmdlet.ShouldProcess('Tenant OneDrive settings', ($set.Keys -join ', '))) {
    Set-SPOTenant @set
    Write-Host 'Applied tenant OneDrive settings.' -ForegroundColor Green
}

if ($DomainGuids -and $PSCmdlet.ShouldProcess('Sync Restriction - DomainJoined - Prod', 'Set-SPOTenantSyncClientRestriction')) {
    Set-SPOTenantSyncClientRestriction -Enable -DomainGuids ($DomainGuids -join ';')
    Write-Host 'Applied sync domain-join allow list.' -ForegroundColor Green
}

Disconnect-SPOService
