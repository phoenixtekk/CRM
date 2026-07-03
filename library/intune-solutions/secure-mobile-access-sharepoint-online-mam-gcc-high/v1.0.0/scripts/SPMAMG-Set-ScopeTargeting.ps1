<#
.SYNOPSIS
    SPMAMG-Set-ScopeTargeting.ps1 — build pilot-to-production scope on the CA policy for mobile SharePoint.
.DESCRIPTION
    PURPOSE
        Widens (or sets) the include/exclude group scope on the Conditional Access policy as you move from
        pilot to production, while always keeping the break-glass group excluded. Defaults to -WhatIf: it
        PREVIEWS the resulting scope and applies nothing until you re-run with -Confirm. Provide the include
        group name to add and, optionally, the break-glass group name (defaults match the guide).
    HOW TO RUN
        Preview (default):  powershell -ExecutionPolicy Bypass -File .\SPMAMG-Set-ScopeTargeting.ps1 -IncludeGroup 'SG-SPMAMG-Wave2'
        Apply:              powershell -ExecutionPolicy Bypass -File .\SPMAMG-Set-ScopeTargeting.ps1 -IncludeGroup 'SG-SPMAMG-Wave2' -Confirm
        Connects to US Gov Graph: Connect-MgGraph -Environment USGov -Scopes 'Policy.ReadWrite.ConditionalAccess','Group.Read.All'
    EXPECTED RESULTS
        In preview, the include/exclude group scope that would result. With -Confirm, the include group is
        added and the break-glass group is confirmed excluded on the CA policy.
.NOTES
    White-label — the repeatable way. Write actions are gated behind -Confirm; default is read-only preview.
#>
[CmdletBinding()]
param(
    [Parameter(Mandatory=$true)][string]$IncludeGroup,
    [string]$CaPolicyName    = 'CA-SPO-Mobile-Require-App-Protection',
    [string]$BreakGlassGroup = 'SG-BreakGlass-Exclude',
    [switch]$Confirm,
    [switch]$WhatIf
)

$apply = $Confirm.IsPresent -and -not $WhatIf.IsPresent
$mode  = if ($apply) { 'APPLY' } else { 'WHATIF (preview only)' }
Write-Host ("=== Secure Mobile Access to SharePoint (GCC High) — scope targeting [{0}] ===" -f $mode) -ForegroundColor Cyan

if (-not (Get-Module -ListAvailable -Name Microsoft.Graph.Authentication)) { Install-Module Microsoft.Graph -Scope CurrentUser -Force -AllowClobber }
Import-Module Microsoft.Graph.Authentication -ErrorAction Stop
Connect-MgGraph -Environment USGov -Scopes 'Policy.ReadWrite.ConditionalAccess','Group.Read.All' -NoWelcome

$env = (Get-MgContext).Environment
if ($env -ne 'USGov') { Write-Host "WRONG CLOUD — reconnect with -Environment USGov." -ForegroundColor Red; Disconnect-MgGraph | Out-Null; return }
Write-Host "Graph host: https://graph.microsoft.us (GCC High)" -ForegroundColor Green

function Get-GroupId([string]$name) {
    (Invoke-MgGraphRequest -Method GET -Uri ("/v1.0/groups?`$filter=displayName eq '{0}'" -f $name)).value | Select-Object -First 1
}

$pols = (Invoke-MgGraphRequest -Method GET -Uri '/v1.0/identity/conditionalAccess/policies').value
$ca = $pols | Where-Object { $_.displayName -eq $CaPolicyName }
if (-not $ca) { Write-Host ("CA policy '{0}' not found." -f $CaPolicyName) -ForegroundColor Red; Disconnect-MgGraph | Out-Null; return }

$inc = Get-GroupId $IncludeGroup
$bg  = Get-GroupId $BreakGlassGroup
if (-not $inc) { Write-Host ("Include group '{0}' not found." -f $IncludeGroup) -ForegroundColor Red; Disconnect-MgGraph | Out-Null; return }
if (-not $bg)  { Write-Host ("Break-glass group '{0}' not found — refusing to widen scope without it excluded." -f $BreakGlassGroup) -ForegroundColor Red; Disconnect-MgGraph | Out-Null; return }

$includes = @($ca.conditions.users.includeGroups)
$excludes = @($ca.conditions.users.excludeGroups)
$newIncludes = @($includes + $inc.id | Select-Object -Unique)
$newExcludes = @($excludes + $bg.id  | Select-Object -Unique)

Write-Host "`nResulting scope:"
Write-Host ("  Include groups : {0}" -f ($newIncludes -join ', '))
Write-Host ("  Exclude groups : {0} (break-glass '{1}' guaranteed)" -f ($newExcludes -join ', '), $BreakGlassGroup)

if (-not $apply) { Write-Host "`nPreview only. Re-run with -Confirm to apply." -ForegroundColor Yellow; Disconnect-MgGraph | Out-Null; return }

$body = @{ conditions = @{ users = @{ includeGroups = $newIncludes; excludeGroups = $newExcludes } } }
Invoke-MgGraphRequest -Method PATCH -Uri ("/v1.0/identity/conditionalAccess/policies/{0}" -f $ca.id) -Body ($body | ConvertTo-Json -Depth 8)
Write-Host ("Applied. Added '{0}' to include; confirmed break-glass exclusion." -f $IncludeGroup) -ForegroundColor Green
Write-Host "Note: also add this group to the include of both App Protection Policies in intune.microsoft.us." -ForegroundColor Yellow

Disconnect-MgGraph | Out-Null
