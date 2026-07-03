<#
.SYNOPSIS
    SPMAMG-Remediation.ps1 — safe fixes: re-assert break-glass exclusion and revert a runaway CA policy.
.DESCRIPTION
    PURPOSE
        Recovers a misbehaving deployment safely. Ensures the break-glass group is excluded from the
        Conditional Access policy, and can revert the policy to Report-only so it stops enforcing while
        you investigate. Defaults to -WhatIf: it PREVIEWS every change and applies nothing until you
        re-run with -Confirm. Pass the CA policy name and break-glass group name (defaults match the guide).
    HOW TO RUN
        Preview (default):  powershell -ExecutionPolicy Bypass -File .\SPMAMG-Remediation.ps1
        Apply:              powershell -ExecutionPolicy Bypass -File .\SPMAMG-Remediation.ps1 -Confirm
        Connects to US Gov Graph: Connect-MgGraph -Environment USGov -Scopes 'Policy.ReadWrite.ConditionalAccess','Group.Read.All'
    EXPECTED RESULTS
        In preview, a list of intended changes. With -Confirm, the break-glass group is added to the CA
        policy exclusions (if missing) and the policy is set to Report-only.
.NOTES
    White-label — the repeatable way. Write actions are gated behind -Confirm; default is read-only preview.
#>
[CmdletBinding()]
param(
    [string]$CaPolicyName     = 'CA-SPO-Mobile-Require-App-Protection',
    [string]$BreakGlassGroup  = 'SG-BreakGlass-Exclude',
    [switch]$Confirm,
    [switch]$WhatIf
)

# Default to preview unless -Confirm is passed.
$apply = $Confirm.IsPresent -and -not $WhatIf.IsPresent
$mode  = if ($apply) { 'APPLY' } else { 'WHATIF (preview only)' }
Write-Host ("=== Secure Mobile Access to SharePoint (GCC High) — remediation [{0}] ===" -f $mode) -ForegroundColor Cyan

if (-not (Get-Module -ListAvailable -Name Microsoft.Graph.Authentication)) { Install-Module Microsoft.Graph -Scope CurrentUser -Force -AllowClobber }
Import-Module Microsoft.Graph.Authentication -ErrorAction Stop
Connect-MgGraph -Environment USGov -Scopes 'Policy.ReadWrite.ConditionalAccess','Group.Read.All' -NoWelcome

$env = (Get-MgContext).Environment
if ($env -ne 'USGov') { Write-Host "WRONG CLOUD — reconnect with -Environment USGov." -ForegroundColor Red; Disconnect-MgGraph | Out-Null; return }
Write-Host "Graph host: https://graph.microsoft.us (GCC High)" -ForegroundColor Green

$pols = (Invoke-MgGraphRequest -Method GET -Uri '/v1.0/identity/conditionalAccess/policies').value
$ca = $pols | Where-Object { $_.displayName -eq $CaPolicyName }
if (-not $ca) { Write-Host ("CA policy '{0}' not found — nothing to do." -f $CaPolicyName) -ForegroundColor Yellow; Disconnect-MgGraph | Out-Null; return }

$bg = (Invoke-MgGraphRequest -Method GET -Uri ("/v1.0/groups?`$filter=displayName eq '{0}'" -f $BreakGlassGroup)).value | Select-Object -First 1
if (-not $bg) { Write-Host ("Break-glass group '{0}' not found — cannot re-assert exclusion. Fix manually." -f $BreakGlassGroup) -ForegroundColor Red }

$excludes = @($ca.conditions.users.excludeGroups)
$needExclude = ($bg -and ($excludes -notcontains $bg.id))
$needReportOnly = ($ca.state -eq 'enabled')

Write-Host ("`nPlanned changes for '{0}':" -f $CaPolicyName)
Write-Host ("  1. Add break-glass '{0}' to exclusions : {1}" -f $BreakGlassGroup, ($(if($needExclude){'YES'}else{'not needed'})))
Write-Host ("  2. Revert state to Report-only          : {0} (current: {1})" -f ($(if($needReportOnly){'YES'}else{'not needed'})), $ca.state)

if (-not $apply) { Write-Host "`nPreview only. Re-run with -Confirm to apply." -ForegroundColor Yellow; Disconnect-MgGraph | Out-Null; return }

if ($needExclude -or $needReportOnly) {
    $newExcludes = @($excludes)
    if ($needExclude) { $newExcludes += $bg.id }
    $body = @{
        conditions = @{ users = @{ excludeGroups = $newExcludes } }
    }
    if ($needReportOnly) { $body.state = 'enabledForReportingButNotEnforced' }
    Invoke-MgGraphRequest -Method PATCH -Uri ("/v1.0/identity/conditionalAccess/policies/{0}" -f $ca.id) -Body ($body | ConvertTo-Json -Depth 8)
    Write-Host "Applied remediation." -ForegroundColor Green
} else {
    Write-Host "Nothing to change." -ForegroundColor Green
}

Disconnect-MgGraph | Out-Null
