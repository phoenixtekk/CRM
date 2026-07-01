<#
.SYNOPSIS
    GCCHIGH-Discovery.ps1 - Read-only estate inventory of a commercial Microsoft 365 + Azure tenant.

    PURPOSE:
        Produces the Discovery baseline for a Commercial-to-GCC High migration program. Inventories
        Exchange Online mailboxes, SharePoint Online sites, OneDrive accounts, Microsoft Teams, and
        Azure (subscriptions, VMs, App Services) with per-object sizing. The output CSV drives license
        sizing, bandwidth planning, and wave generation.

    HOW TO RUN:
        1. Install modules (run once):
             Install-Module ExchangeOnlineManagement, Microsoft.Graph, MicrosoftTeams,
                            Microsoft.Online.SharePoint.PowerShell, Az -Scope CurrentUser
        2. Run against the COMMERCIAL (source) tenant:
             .\GCCHIGH-Discovery.ps1 -OutputCsv ".\Estate-Inventory - Discovery - Source.csv" `
                                     -SharePointAdminUrl "https://<org>-admin.sharepoint.com"
        3. Sign in interactively when prompted (a read-only / global-reader account is sufficient).

    EXPECTED RESULTS:
        A CSV "Estate-Inventory - Discovery - Source.csv" with one row per discovered object
        (ObjectType, Identity/Name, SizeGB, extra detail) plus a console summary of totals per
        workstream. No changes are made to any tenant - this script is strictly read-only.

.NOTES
    Azure Solutions - read-only.
#>

[CmdletBinding()]
param(
    [string]$OutputCsv = ".\Estate-Inventory - Discovery - Source.csv",
    [string]$SharePointAdminUrl,
    [switch]$SkipAzure,
    [switch]$SkipM365
)

$ErrorActionPreference = 'Stop'
$results = New-Object System.Collections.Generic.List[object]

function Add-Item {
    param($Type, $Name, $SizeGB = 0, $Detail = '')
    $results.Add([pscustomobject]@{
        ObjectType = $Type
        Name       = $Name
        SizeGB     = [math]::Round([double]$SizeGB, 3)
        Detail     = $Detail
        Workstream = switch ($Type) {
            'Mailbox'    { 'Exchange' }
            'OneDrive'   { 'SharePoint/OneDrive' }
            'SPOSite'    { 'SharePoint/OneDrive' }
            'Team'       { 'Teams' }
            'AzureVM'    { 'Servers' }
            'AppService' { 'PaaS' }
            default      { 'Other' }
        }
    })
}

function ConvertTo-GB {
    param([string]$SizeString)   # e.g. "12.34 GB (13,...bytes)"
    if (-not $SizeString) { return 0 }
    if ($SizeString -match '\(([\d,]+) bytes\)') {
        return [double]($Matches[1] -replace ',', '') / 1GB
    }
    return 0
}

if (-not $SkipM365) {
    Write-Host "=== Microsoft 365 (commercial / source) discovery ===" -ForegroundColor Cyan

    # --- Exchange Online: mailboxes ---
    Import-Module ExchangeOnlineManagement -ErrorAction Stop
    Connect-ExchangeOnline -ShowBanner:$false   # commercial endpoint (default)
    Write-Host "Enumerating mailboxes..."
    Get-ExoMailbox -ResultSize Unlimited |
        ForEach-Object {
            $stats = Get-ExoMailboxStatistics -Identity $_.PrimarySmtpAddress -ErrorAction SilentlyContinue
            Add-Item -Type 'Mailbox' -Name $_.PrimarySmtpAddress `
                     -SizeGB (ConvertTo-GB $stats.TotalItemSize.Value.ToString()) `
                     -Detail ("Type={0}; Items={1}" -f $_.RecipientTypeDetails, $stats.ItemCount)
        }
    Disconnect-ExchangeOnline -Confirm:$false

    # --- Microsoft Graph: Teams ---
    Import-Module Microsoft.Graph -ErrorAction Stop
    Connect-MgGraph -Scopes "Group.Read.All","Sites.Read.All" -NoWelcome   # commercial cloud
    Write-Host "Enumerating Teams..."
    Get-MgGroup -Filter "resourceProvisioningOptions/Any(x:x eq 'Team')" -All |
        ForEach-Object {
            $members = (Get-MgGroupMember -GroupId $_.Id -All).Count
            Add-Item -Type 'Team' -Name $_.DisplayName -Detail ("Members={0}" -f $members)
        }
    Disconnect-MgGraph | Out-Null

    # --- SharePoint Online: sites + OneDrive ---
    if ($SharePointAdminUrl) {
        Import-Module Microsoft.Online.SharePoint.PowerShell -ErrorAction Stop
        Connect-SPOService -Url $SharePointAdminUrl
        Write-Host "Enumerating SharePoint sites + OneDrive..."
        Get-SPOSite -Limit All -IncludePersonalSite $true |
            ForEach-Object {
                $type = if ($_.Url -match '/personal/') { 'OneDrive' } else { 'SPOSite' }
                Add-Item -Type $type -Name $_.Url -SizeGB ($_.StorageUsageCurrent / 1024) `
                         -Detail ("Template={0}" -f $_.Template)
            }
        Disconnect-SPOService
    } else {
        Write-Warning "SharePointAdminUrl not supplied - skipping SharePoint/OneDrive discovery."
    }
}

if (-not $SkipAzure) {
    Write-Host "=== Azure (commercial / source) discovery ===" -ForegroundColor Cyan
    Import-Module Az.Accounts, Az.Compute, Az.Websites -ErrorAction Stop
    Connect-AzAccount | Out-Null   # commercial Azure (default environment)
    foreach ($sub in Get-AzSubscription) {
        Set-AzContext -SubscriptionId $sub.Id | Out-Null
        Add-Item -Type 'AzureSubscription' -Name $sub.Name -Detail ("Id={0}" -f $sub.Id)
        Write-Host ("Enumerating VMs/App Services in subscription '{0}'..." -f $sub.Name)
        Get-AzVM | ForEach-Object {
            $diskGB = ($_.StorageProfile.OsDisk.DiskSizeGB) + (($_.StorageProfile.DataDisks | Measure-Object DiskSizeGB -Sum).Sum)
            Add-Item -Type 'AzureVM' -Name $_.Name -SizeGB ([double]$diskGB) `
                     -Detail ("Size={0}; OS={1}" -f $_.HardwareProfile.VmSize, $_.StorageProfile.OsDisk.OsType)
        }
        Get-AzWebApp | ForEach-Object {
            Add-Item -Type 'AppService' -Name $_.Name -Detail ("State={0}; Plan={1}" -f $_.State, $_.ServerFarmId)
        }
    }
}

# --- Export + summary ---
$results | Sort-Object Workstream, ObjectType, Name | Export-Csv -Path $OutputCsv -NoTypeInformation -Encoding UTF8
Write-Host ("`nExported {0} objects to {1}" -f $results.Count, $OutputCsv) -ForegroundColor Green
Write-Host "`n=== Summary by workstream ===" -ForegroundColor Cyan
$results | Group-Object Workstream | ForEach-Object {
    Write-Host ("  {0,-22} Count={1,-6} TotalGB={2}" -f $_.Name, $_.Count, [math]::Round((($_.Group | Measure-Object SizeGB -Sum).Sum),2))
}
