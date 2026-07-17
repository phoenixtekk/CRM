<#
.SYNOPSIS
    MBXRBAC-Report.ps1 — the audit artifact: report every app-permission-to-mailbox scoping (or lack
    of it) across the tenant, to console and CSV.
.DESCRIPTION
    PURPOSE
        Read-only reporting for the "Scoping Application-Permission Mailbox Access" solution. Produces
        the security-review artifact: for every app / managed identity holding a mail-capable
        application Graph permission, one row stating the app, the permission(s), whether it is SCOPED
        (via an Application Access Policy / Exchange RBAC assignment) or TENANT-WIDE, and — when
        scoped — the mailboxes/scope it is allowed to reach. Emits a summary count of unscoped apps
        (the number you are driving to zero). Makes no changes.
    HOW TO RUN
        powershell -ExecutionPolicy Bypass -File .\MBXRBAC-Report.ps1
        powershell -ExecutionPolicy Bypass -File .\MBXRBAC-Report.ps1 -CsvPath .\MBXRBAC-scoping-report.csv
        Requires Microsoft.Graph and ExchangeOnlineManagement. Run Connect-MgGraph and
        Connect-ExchangeOnline first, or the script prompts.
    REQUIRED SCOPES / ROLES
        Microsoft Graph (delegated): Application.Read.All, Directory.Read.All.
        Exchange Online: a View-Only role able to run Get-ApplicationAccessPolicy /
        Get-DistributionGroupMember. VERIFY exact scopes, roles, and app-role IDs against current
        Microsoft documentation.
    EXPECTED RESULTS
        A tenant-wide table + CSV of every mail-capable application permission and its scoping status,
        plus a "TENANT-WIDE apps remaining: N" summary. The CSV is the auditor's evidence. Read-only.
.NOTES
    Azure Solutions — read-only. White-label sample values use contoso.com. All cmdlet/permission
    names: verify against current Microsoft documentation.
#>
[CmdletBinding()]
param(
    [string]$CsvPath = ".\MBXRBAC-scoping-report.csv"
)

$MailAppPermissions = @('Mail.Read','Mail.ReadWrite','Mail.ReadBasic.All','Mail.Send','MailboxSettings.Read','MailboxSettings.ReadWrite')

Import-Module Microsoft.Graph.Applications -ErrorAction SilentlyContinue
Import-Module ExchangeOnlineManagement -ErrorAction SilentlyContinue
try { if (-not (Get-MgContext)) { Connect-MgGraph -Scopes 'Application.Read.All','Directory.Read.All' | Out-Null } } catch { Write-Host "Connect-MgGraph failed: $($_.Exception.Message)" -ForegroundColor Yellow }
try { Get-ConnectionInformation -ErrorAction Stop | Out-Null } catch { try { Connect-ExchangeOnline -ShowBanner:$false | Out-Null } catch { Write-Host "Connect-ExchangeOnline failed: $($_.Exception.Message)" -ForegroundColor Yellow } }

Write-Host "`n=== Application-permission mailbox scoping report ===" -ForegroundColor Cyan

$graphSp = $null
try { $graphSp = Get-MgServicePrincipal -Filter "appId eq '00000003-0000-0000-c000-000000000000'" -ErrorAction Stop } catch {}
$roleIdToValue = @{}
if ($graphSp) { foreach ($r in $graphSp.AppRoles) { $roleIdToValue[$r.Id.ToString()] = $r.Value } }

$accessPolicies = @()
try { $accessPolicies = Get-ApplicationAccessPolicy -ErrorAction Stop } catch { Write-Host "   (could not read Application Access Policies: $($_.Exception.Message))" -ForegroundColor Yellow }

$rows = @()
$spList = @()
try { $spList = Get-MgServicePrincipal -All -ErrorAction Stop } catch { Write-Host "   Could not enumerate service principals: $($_.Exception.Message)" -ForegroundColor Yellow }

foreach ($sp in $spList) {
    $grants = @()
    try { $grants = Get-MgServicePrincipalAppRoleAssignment -ServicePrincipalId $sp.Id -ErrorAction Stop } catch { continue }
    $mailPerms = @()
    foreach ($g in $grants) { $v = $roleIdToValue[$g.AppRoleId.ToString()]; if ($v -and ($MailAppPermissions -contains $v)) { $mailPerms += $v } }
    if ($mailPerms.Count -eq 0) { continue }

    $scopePolicy = $null
    foreach ($p in $accessPolicies) { if ($p.AppId -contains $sp.AppId -or $p.ScopeName -eq $sp.AppId) { $scopePolicy = $p; break } }
    $scoped = [bool]$scopePolicy

    $allowed = ''
    if ($scoped -and $scopePolicy.ScopeName) {
        try { $allowed = (Get-DistributionGroupMember -Identity $scopePolicy.ScopeName -ErrorAction Stop | Select-Object -ExpandProperty PrimarySmtpAddress) -join '; ' } catch {}
    }

    $rows += [pscustomobject]@{
        DisplayName    = $sp.DisplayName
        AppId          = $sp.AppId
        MailPerms      = ($mailPerms -join ', ')
        Scoping        = if ($scoped) { 'SCOPED' } else { 'TENANT-WIDE' }
        ScopeGroup     = if ($scoped) { $scopePolicy.ScopeName } else { '' }
        AllowedMailbox = $allowed
    }
}

if ($rows.Count -gt 0) {
    $rows | Sort-Object Scoping, DisplayName | Format-Table DisplayName, MailPerms, Scoping, ScopeGroup -AutoSize
    $rows | Export-Csv -Path $CsvPath -NoTypeInformation -Encoding UTF8
    Write-Host "   CSV written: $CsvPath" -ForegroundColor Cyan
    $tenantWide = ($rows | Where-Object Scoping -eq 'TENANT-WIDE').Count
    $color = if ($tenantWide -eq 0) { 'Green' } else { 'Yellow' }
    Write-Host ("`nTENANT-WIDE apps remaining: {0}  (target: 0)" -f $tenantWide) -ForegroundColor $color
} else {
    Write-Host "   (no apps with mail-capable application permissions found)" -ForegroundColor Yellow
}

Write-Host "`nReport complete (read-only)." -ForegroundColor Green
Write-Host "NOTE: apps scoped via the Graph RBAC-for-Exchange model may not appear as 'SCOPED' here — that state also lives in Exchange RBAC role assignments. Verify against current Microsoft documentation." -ForegroundColor DarkGray
