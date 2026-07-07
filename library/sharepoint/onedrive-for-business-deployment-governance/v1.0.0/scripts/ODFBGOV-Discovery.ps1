<#
.SYNOPSIS
    ODFBGOV-Discovery.ps1 — read-only assessment of OneDrive for Business deployment, KFM, sync-control, storage, and sharing posture.
.DESCRIPTION
    PURPOSE
        Builds the OneDrive governance baseline before any change. Reads the tenant-level OneDrive
        settings from the SharePoint Online Management Shell (default storage quota, orphaned-site
        retention, OneDrive sharing capability, conditional-access/limited-access, sync-client
        restriction), enumerates provisioned OneDrive personal sites, and (optionally) pulls the
        Microsoft Graph OneDrive usage report to show storage used and last activity per account.
        Read-only — makes NO changes.
    HOW TO RUN
        .\ODFBGOV-Discovery.ps1 -AdminUrl https://contoso-admin.sharepoint.com -CsvPath C:\Temp\ODFBGOV-Baseline.csv
        (PowerShell 5.1+/7+; Microsoft.Online.SharePoint.PowerShell + optionally Microsoft.Graph.
         Connect with Connect-SPOService — modern auth / MFA. For Government clouds the admin URL is
         *-admin.sharepoint.us — verify in your tenant.)
    EXPECTED RESULTS
        A console summary of the tenant OneDrive settings and a per-OneDrive CSV (owner, URL, quota,
        storage used, last activity). No writes occur; this is the artifact "OneDrive Baseline - Tenant - Discovery".
.NOTES
    SharePoint category — OneDrive for Business Deployment & Governance. Read-only against SPO + Graph.
#>
[CmdletBinding()]
param(
    [Parameter(Mandatory)][string]$AdminUrl,
    [string]$CsvPath,
    [switch]$IncludeGraphUsage,
    [ValidateSet('D7','D30','D90','D180')][string]$UsagePeriod = 'D30'
)

if (-not (Get-Module -ListAvailable -Name Microsoft.Online.SharePoint.PowerShell)) {
    Install-Module Microsoft.Online.SharePoint.PowerShell -Scope CurrentUser -Force -AllowClobber
}
Import-Module Microsoft.Online.SharePoint.PowerShell -DisableNameChecking -ErrorAction Stop
Connect-SPOService -Url $AdminUrl

Write-Host '=== OneDrive Baseline - Tenant - Discovery ===' -ForegroundColor Cyan

# --- Tenant-level OneDrive posture ---
$t = Get-SPOTenant
[pscustomobject]@{
    OneDriveStorageQuota_MB              = $t.OneDriveStorageQuota
    OrphanedPersonalSitesRetention_Days  = $t.OrphanedPersonalSitesRetentionPeriod
    OneDriveSharingCapability            = $t.OneDriveSharingCapability
    SharingCapability_Org                = $t.SharingCapability
    ConditionalAccessPolicy              = $t.ConditionalAccessPolicy   # AllowLimitedAccess = web-only (blocks download/sync)
    NotifyOwnersWhenInvitationsAccepted  = $t.NotifyOwnersWhenInvitationsAccepted
} | Format-List

Write-Host '--- Sync client restriction (domain-join allow list) ---' -ForegroundColor Cyan
try {
    $sync = Get-SPOTenantSyncClientRestriction
    [pscustomobject]@{
        TenantRestrictionEnabled = $sync.TenantRestrictionEnabled
        AllowedDomainGuids       = ($sync.AllowedDomainList -join '; ')
        BlockMacSync             = $sync.BlockMacSync
        ExcludedFileExtensions   = ($sync.ExcludedFileExtensions -join '; ')
    } | Format-List
} catch {
    Write-Warning "Could not read sync client restriction: $($_.Exception.Message)"
}

# --- Enumerate provisioned OneDrive personal sites ---
Write-Host '--- Provisioned OneDrive sites ---' -ForegroundColor Cyan
$od = Get-SPOSite -IncludePersonalSite $true -Limit All -Filter "Url -like '-my.sharepoint.com/personal/'"
Write-Host ("OneDrive personal sites provisioned: {0}" -f $od.Count)

$usage = @{}
if ($IncludeGraphUsage) {
    if (-not (Get-Module -ListAvailable -Name Microsoft.Graph.Authentication)) {
        Install-Module Microsoft.Graph -Scope CurrentUser -Force -AllowClobber
    }
    Import-Module Microsoft.Graph.Authentication -ErrorAction Stop
    Connect-MgGraph -Scopes 'Reports.Read.All' -NoWelcome
    $uri = "/v1.0/reports/getOneDriveUsageAccountDetail(period='$UsagePeriod')"
    $csv = Invoke-MgGraphRequest -Method GET -Uri $uri -OutputType HttpResponseMessage
    ($csv.Content.ReadAsStringAsync().Result | ConvertFrom-Csv) | ForEach-Object {
        if ($_.'Owner Principal Name') { $usage[$_.'Owner Principal Name'.ToLower()] = $_ }
    }
    Disconnect-MgGraph | Out-Null
}

$rows = foreach ($s in $od) {
    $u = if ($s.Owner) { $usage[$s.Owner.ToLower()] } else { $null }
    [pscustomobject]@{
        Owner            = $s.Owner
        Url              = $s.Url
        StorageQuota_MB  = $s.StorageQuota
        StorageUsed_MB   = $s.StorageUsageCurrent
        LastContentMod   = if ($u) { $u.'Last Activity Date' } else { $s.LastContentModifiedDate }
        SharingCapability= $s.SharingCapability
    }
}

if ($CsvPath) {
    $rows | Export-Csv -Path $CsvPath -NoTypeInformation
    Write-Host ("Saved 'OneDrive Baseline - Tenant - Discovery' to {0}" -f $CsvPath) -ForegroundColor Green
} else {
    $rows | Sort-Object StorageUsed_MB -Descending | Select-Object -First 20 | Format-Table -AutoSize
}

Disconnect-SPOService
