<#
.SYNOPSIS
    AGBINV-Export-AgentSharing.ps1 — for each Agent Builder agent, read who it is shared with
    (users/groups) from the per-agent detail endpoint and resolve to names.
.DESCRIPTION
    PURPOSE
        The sharing exporter. For every agent in the inventory CSV, calls
        GET /copilot/admin/catalog/packages/{id} and reads the copilotPackageDetail property
        allowedUsersAndGroups (each entry is { resourceId, resourceType = user|group }) — the granular
        "shared with whom" data. Resolves each id to a display name / UPN via /users/{id} or
        /groups/{id}. Also captures availableTo/deployedTo and sensitivity. Read-only; changes nothing.
    HOW TO RUN
        pwsh -File .\AGBINV-Export-AgentSharing.ps1 -Environment Global `
             -InventoryCsv C:\AgentGovernance\Exports\AgentBuilder-Inventory_<date>.csv `
             -OutputPath   C:\AgentGovernance\Exports
        Required scopes: CopilotPackages.Read.All  (and directory read to resolve names —
        User.Read.All / Group.Read.All or Directory.Read.All)
    EXPECTED RESULTS
        AgentBuilder-Sharing_<yyyyMMdd-HHmm>.csv — one row per agent x recipient, with AgentId,
        AgentName, SharingScope (OrgWide/Specific/OnlyOwner), RecipientType, RecipientId,
        RecipientName, RecipientUpnOrMail. Org-wide shares (availableTo=all) are labeled OrgWide rather
        than shown as an empty recipient list.
.NOTES
    Copilot Solutions — the repeatable way. Read-only against Microsoft Graph. The list endpoint only
    exposes all/some/none; the per-id detail exposes allowedUsersAndGroups — this script uses the
    per-id detail. Preview-volatile — verify property names against current docs.
#>

[CmdletBinding()]
param(
    [ValidateSet('Global','USGov','USGovDoD')]
    [string] $Environment = 'Global',
    [Parameter(Mandatory)][string] $InventoryCsv,
    [string] $OutputPath = '.'
)

$ErrorActionPreference = 'Stop'

$graphEnv = switch ($Environment) {
    'USGov'    { @{ Env = 'USGov';    Base = 'https://graph.microsoft.us' } }
    'USGovDoD' { @{ Env = 'USGovDoD'; Base = 'https://dod-graph.microsoft.us' } }
    default    { @{ Env = 'Global';   Base = 'https://graph.microsoft.com' } }
}
$base = "$($graphEnv.Base)/v1.0"

if (-not (Test-Path $InventoryCsv)) { throw "Inventory CSV not found: $InventoryCsv (run AGBINV-Export-AgentInventory.ps1 first)." }
if (-not (Get-Module -ListAvailable -Name Microsoft.Graph.Authentication)) {
    throw "Microsoft Graph SDK not found. Run: Install-Module Microsoft.Graph -Scope CurrentUser"
}
Import-Module Microsoft.Graph.Authentication -ErrorAction Stop
if (-not (Get-MgContext)) {
    Connect-MgGraph -Environment $graphEnv.Env -Scopes 'CopilotPackages.Read.All','User.Read.All','Group.Read.All' | Out-Null
}

$nameCache = @{}
function Resolve-Recipient {
    param([string] $Id, [string] $Type)
    if ($nameCache.ContainsKey($Id)) { return $nameCache[$Id] }
    $result = [pscustomobject]@{ Name = $Id; UpnOrMail = '' }  # default: raw id if unresolved
    try {
        if ($Type -match 'group') {
            $g = Invoke-MgGraphRequest -Method GET -Uri "$base/groups/$Id`?`$select=displayName,mail"
            $result = [pscustomobject]@{ Name = $g.displayName; UpnOrMail = $g.mail }
        } else {
            $u = Invoke-MgGraphRequest -Method GET -Uri "$base/users/$Id`?`$select=displayName,userPrincipalName"
            $result = [pscustomobject]@{ Name = $u.displayName; UpnOrMail = $u.userPrincipalName }
        }
    } catch {
        Write-Host "  (could not resolve $Type $Id — leaving raw id; grant directory read, see T9)" -ForegroundColor DarkYellow
    }
    $nameCache[$Id] = $result
    return $result
}

$agents = Import-Csv -Path $InventoryCsv
$rows = New-Object System.Collections.Generic.List[object]

foreach ($a in $agents) {
    Write-Host "Reading sharing for '$($a.DisplayName)' ..." -ForegroundColor Cyan
    $detail = $null
    try {
        $detail = Invoke-MgGraphRequest -Method GET -Uri "$base/copilot/admin/catalog/packages/$($a.Id)"
    } catch {
        Write-Host "  detail call failed for $($a.Id) — run AGBINV-Connect-Preflight.ps1 to decode." -ForegroundColor Yellow
        continue
    }

    $availableTo = "$($detail.availableTo)"
    $allowed = @($detail.allowedUsersAndGroups)
    $scope = if ($availableTo -eq 'all') { 'OrgWide' }
             elseif ($allowed.Count -gt 0 -or $availableTo -eq 'some') { 'Specific' }
             else { 'OnlyOwner' }

    if ($scope -eq 'OrgWide' -and $allowed.Count -eq 0) {
        $rows.Add([pscustomobject]@{
            AgentId = $a.Id; AgentName = $a.DisplayName; SharingScope = 'OrgWide'
            RecipientType = 'Everyone'; RecipientId = ''; RecipientName = 'Anyone in your organization'
            RecipientUpnOrMail = ''; Sensitivity = $detail.sensitivity
        })
        continue
    }
    if ($allowed.Count -eq 0) {
        $rows.Add([pscustomobject]@{
            AgentId = $a.Id; AgentName = $a.DisplayName; SharingScope = $scope
            RecipientType = 'None'; RecipientId = ''; RecipientName = '(not shared / owner only)'
            RecipientUpnOrMail = ''; Sensitivity = $detail.sensitivity
        })
        continue
    }
    foreach ($r in $allowed) {
        $resolved = Resolve-Recipient -Id $r.resourceId -Type "$($r.resourceType)"
        $rows.Add([pscustomobject]@{
            AgentId = $a.Id; AgentName = $a.DisplayName; SharingScope = $scope
            RecipientType = $r.resourceType; RecipientId = $r.resourceId
            RecipientName = $resolved.Name; RecipientUpnOrMail = $resolved.UpnOrMail
            Sensitivity = $detail.sensitivity
        })
    }
}

if ($rows.Count -eq 0) { Write-Host "No sharing rows produced." -ForegroundColor Yellow; return }
if (-not (Test-Path $OutputPath)) { New-Item -ItemType Directory -Path $OutputPath -Force | Out-Null }
$stamp = (Get-Date).ToString('yyyyMMdd-HHmm')
$csv = Join-Path $OutputPath "AgentBuilder-Sharing_$stamp.csv"
$rows | Export-Csv -Path $csv -NoTypeInformation -Encoding UTF8
Write-Host ("Wrote {0}  ({1} agent x recipient rows)" -f $csv, $rows.Count) -ForegroundColor Green
