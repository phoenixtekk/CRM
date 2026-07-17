<#
.SYNOPSIS
    MBXRBAC-Discovery.ps1 — inventory apps / managed identities that hold mail-capable APPLICATION
    Graph permissions, and flag whether each is SCOPED (access policy / RBAC) or TENANT-WIDE.
.DESCRIPTION
    PURPOSE
        Read-only discovery for the "Scoping Application-Permission Mailbox Access" solution.
        Enumerates every service principal (app registration / managed identity) granted an
        application-type mail permission — Mail.Read, Mail.ReadWrite, Mail.Send, MailboxSettings.*,
        and their EWS/other equivalents — and reports, for each, whether an Exchange Application
        Access Policy (or an Exchange RBAC assignment) scopes it, or whether it is still tenant-wide
        (able to reach EVERY mailbox). Makes no changes.
    HOW TO RUN
        powershell -ExecutionPolicy Bypass -File .\MBXRBAC-Discovery.ps1
        powershell -ExecutionPolicy Bypass -File .\MBXRBAC-Discovery.ps1 -AppId "11111111-1111-1111-1111-111111111111"
        Requires the Microsoft.Graph and ExchangeOnlineManagement modules.
        Run Connect-MgGraph and Connect-ExchangeOnline first, or the script will prompt.
    REQUIRED SCOPES / ROLES
        Microsoft Graph (delegated): Application.Read.All, Directory.Read.All (read app permissions).
        Exchange Online: a role that can run Get-ApplicationAccessPolicy (e.g. View-Only roles).
        VERIFY the exact Graph scopes, Exchange role names, and the app-role/permission IDs against
        current Microsoft documentation — they are version- and cloud-dependent.
    EXPECTED RESULTS
        A per-app snapshot: each app/identity holding a mail-capable application permission, the
        permission(s) it holds, and a SCOPED / TENANT-WIDE verdict. Tenant-wide apps are the exposure
        to close. Read-only; no policy, group, or RBAC object is created or changed.
.NOTES
    Azure Solutions — read-only. Reports on configuration/identifiers only; makes no changes.
    White-label sample values use contoso.com. All cmdlet/permission names: verify against current
    Microsoft documentation.
#>
[CmdletBinding()]
param(
    [string]$AppId,
    [string]$CsvPath
)

# --- Mail-capable APPLICATION permissions to look for (VERIFY current names/IDs with Microsoft). ---
$MailAppPermissions = @(
    'Mail.Read','Mail.ReadWrite','Mail.ReadBasic.All','Mail.Send',
    'MailboxSettings.Read','MailboxSettings.ReadWrite'
)

foreach ($m in 'Microsoft.Graph','ExchangeOnlineManagement') {
    if (-not (Get-Module -ListAvailable -Name $m)) {
        Write-Host "Module $m not found. Install with: Install-Module $m -Scope CurrentUser" -ForegroundColor Yellow
    }
}
Import-Module Microsoft.Graph.Applications -ErrorAction SilentlyContinue
Import-Module ExchangeOnlineManagement -ErrorAction SilentlyContinue

# Connect if needed (delegated Graph + Exchange Online).
try { if (-not (Get-MgContext)) { Connect-MgGraph -Scopes 'Application.Read.All','Directory.Read.All' | Out-Null } }
catch { Write-Host "Connect-MgGraph failed: $($_.Exception.Message)" -ForegroundColor Yellow }
try { Get-ConnectionInformation -ErrorAction Stop | Out-Null } catch { try { Connect-ExchangeOnline -ShowBanner:$false | Out-Null } catch { Write-Host "Connect-ExchangeOnline failed: $($_.Exception.Message)" -ForegroundColor Yellow } }

Write-Host "`n=== Scoping Application-Permission Mailbox Access — discovery ===" -ForegroundColor Cyan

# Pull the Microsoft Graph resource service principal to resolve app-role IDs -> permission names.
$graphSp = $null
try { $graphSp = Get-MgServicePrincipal -Filter "appId eq '00000003-0000-0000-c000-000000000000'" -ErrorAction Stop } catch {}
$roleIdToValue = @{}
if ($graphSp) { foreach ($r in $graphSp.AppRoles) { $roleIdToValue[$r.Id.ToString()] = $r.Value } }

# Cache Application Access Policies from Exchange (used to decide SCOPED vs TENANT-WIDE).
$accessPolicies = @()
try { $accessPolicies = Get-ApplicationAccessPolicy -ErrorAction Stop } catch { Write-Host "   (could not read Application Access Policies: $($_.Exception.Message))" -ForegroundColor Yellow }

# Enumerate service principals that have mail-capable app-role assignments.
$results = @()
$spList = @()
try {
    if ($AppId) { $spList = Get-MgServicePrincipal -Filter "appId eq '$AppId'" -ErrorAction Stop }
    else        { $spList = Get-MgServicePrincipal -All -ErrorAction Stop }
} catch { Write-Host "   Could not enumerate service principals: $($_.Exception.Message)" -ForegroundColor Yellow }

foreach ($sp in $spList) {
    $grants = @()
    try { $grants = Get-MgServicePrincipalAppRoleAssignment -ServicePrincipalId $sp.Id -ErrorAction Stop } catch { continue }
    $mailPerms = @()
    foreach ($g in $grants) {
        $val = $roleIdToValue[$g.AppRoleId.ToString()]
        if ($val -and ($MailAppPermissions -contains $val)) { $mailPerms += $val }
    }
    if ($mailPerms.Count -eq 0) { continue }

    # SCOPED if any Application Access Policy references this app's AppId (VERIFY property name).
    $scoped = $false
    foreach ($p in $accessPolicies) {
        if ($p.AppId -contains $sp.AppId -or $p.ScopeName -eq $sp.AppId) { $scoped = $true; break }
    }
    $verdict = if ($scoped) { 'SCOPED (access policy)' } else { 'TENANT-WIDE (review)' }

    $results += [pscustomobject]@{
        DisplayName = $sp.DisplayName
        AppId       = $sp.AppId
        MailPerms   = ($mailPerms -join ', ')
        Scoping     = $verdict
    }
    $color = if ($scoped) { 'Green' } else { 'Yellow' }
    Write-Host ("   {0,-34} {1}" -f $sp.DisplayName, $verdict) -ForegroundColor $color
    Write-Host ("      AppId {0}  perms: {1}" -f $sp.AppId, ($mailPerms -join ', '))
}

if ($results.Count -eq 0) { Write-Host "   (no apps with mail-capable application permissions found)" -ForegroundColor Yellow }
if ($CsvPath) { $results | Export-Csv -Path $CsvPath -NoTypeInformation -Encoding UTF8; Write-Host "`n   CSV written: $CsvPath" -ForegroundColor Cyan }

Write-Host "`nDiscovery complete (read-only)." -ForegroundColor Green
Write-Host "NOTE: SCOPED/TENANT-WIDE for the Graph RBAC-for-Exchange model may also require checking Exchange RBAC role assignments — verify against current Microsoft documentation." -ForegroundColor DarkGray
