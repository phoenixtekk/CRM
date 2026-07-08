<#
.SYNOPSIS
    DLCCLEAN-Set-Scope.ps1 — scope/health helper: report a policy's scope and (with -Commit) add/remove locations or bind an adaptive scope (-WhatIf by default).
.DESCRIPTION
    PURPOSE
        Reports a retention/deletion policy's current locations, scope, enabled state, and health, and — only
        with -Commit — adjusts the INCLUDED/EXCLUDED static locations or binds/unbinds a named ADAPTIVE SCOPE
        (e.g. 'DLC - Stale Sites - Adaptive Scope'), so cleanup can be narrowed to a pilot or expanded one step
        at a time. Safe by default: -WhatIf reports only; writes require -Commit. HARD SAFETY RAILS: it adjusts
        SCOPE only — it never changes the retain/delete ACTION, never enables/disables the policy, and never
        deletes content; and it refuses to ADD an "All" (tenant-wide) location. Re-run DLCCLEAN-Validate.ps1
        after any scope change to re-prove the hold cross-check.
    HOW TO RUN
        # Report current scope/health:
        powershell -File .\DLCCLEAN-Set-Scope.ps1 -PolicyName 'DLC - Delete Inactive Content - Pilot' -WhatIf
        # Add a pilot site to the SharePoint scope:
        powershell -File .\DLCCLEAN-Set-Scope.ps1 -PolicyName 'DLC - Delete Inactive Content - Pilot' `
            -AddLocation 'https://contoso.sharepoint.com/sites/DLC-Pilot2' -Workload SharePoint -Commit
        # Bind an adaptive scope (E5 — verify licensing):
        powershell -File .\DLCCLEAN-Set-Scope.ps1 -PolicyName 'DLC - Delete Inactive Content - Pilot' `
            -BindAdaptiveScope 'DLC - Stale Sites - Adaptive Scope' -Commit
        Requires Security & Compliance PowerShell (Connect-IPPSSession).
.EXAMPLE
    .\DLCCLEAN-Set-Scope.ps1 -PolicyName 'DLC - Delete Inactive Content - Pilot' -WhatIf
    Prints the policy's locations/scope/enabled state and the Set-RetentionCompliancePolicy call it WOULD run.
.NOTES
    Purview — Inactive & Legacy Data Cleanup. Scope changes gated behind -Commit; never changes action/enable; never deletes; refuses "All". No credentials in code.
    Expected results: -Commit adjusts scope only; Enabled/action unchanged. Re-run DLCCLEAN-Validate.ps1 to re-prove no held item is deletable (PASS).
#>
[CmdletBinding()]
param(
    [Parameter(Mandatory)][string]$PolicyName,
    [ValidateSet('Exchange','SharePoint','OneDrive','Teams','Groups')][string]$Workload = 'SharePoint',
    [string]$AddLocation,
    [string]$RemoveLocation,
    [string]$BindAdaptiveScope,
    [string]$UnbindAdaptiveScope,
    [string]$UserPrincipalName,
    [switch]$Commit
)

if (-not (Get-Module -ListAvailable -Name ExchangeOnlineManagement)) {
    Install-Module ExchangeOnlineManagement -Scope CurrentUser -Force -AllowClobber
}
Import-Module ExchangeOnlineManagement -ErrorAction Stop
if (-not (Get-Command Get-RetentionCompliancePolicy -ErrorAction SilentlyContinue)) {
    if ($UserPrincipalName) { Connect-IPPSSession -UserPrincipalName $UserPrincipalName } else { Connect-IPPSSession }
}

$p = Get-RetentionCompliancePolicy -Identity $PolicyName -ErrorAction Stop
Write-Host ("=== Scope/health for '{0}' (Enabled={1}, Mode={2}) ===" -f $p.Name, $p.Enabled, $p.Mode) -ForegroundColor Cyan
if ($p.Enabled) {
    Write-Host 'HEALTH: policy is ENABLED (will act on its scope on Microsoft''s timer, blocked by any hold). Scope changes here alter WHAT is in cleanup range — change-control this.' -ForegroundColor Yellow
} else {
    Write-Host 'HEALTH: policy is DISABLED — safe to shape scope before enabling under change control.' -ForegroundColor Green
}
foreach ($loc in 'ExchangeLocation','SharePointLocation','OneDriveLocation','ModernGroupLocation','TeamsChatLocation','TeamsChannelLocation','AdaptiveScopeLocation') {
    $v = @($p.$loc); if ($v.Count) { Write-Host ("  {0}: {1}" -f $loc, ($v -join ', ')) -ForegroundColor DarkCyan }
}

# Map workload -> the Add/Remove location parameter names on Set-RetentionCompliancePolicy.
$addParam = $null; $removeParam = $null
switch ($Workload) {
    'Exchange'   { $addParam='AddExchangeLocation';     $removeParam='RemoveExchangeLocation' }
    'SharePoint' { $addParam='AddSharePointLocation';   $removeParam='RemoveSharePointLocation' }
    'OneDrive'   { $addParam='AddOneDriveLocation';     $removeParam='RemoveOneDriveLocation' }
    'Teams'      { $addParam='AddTeamsChannelLocation'; $removeParam='RemoveTeamsChannelLocation' }
    'Groups'     { $addParam='AddModernGroupLocation';  $removeParam='RemoveModernGroupLocation' }
}

# Nothing to change -> reporting only.
if (-not ($AddLocation -or $RemoveLocation -or $BindAdaptiveScope -or $UnbindAdaptiveScope)) {
    Write-Host 'No scope change requested — reporting only. Supply -AddLocation/-RemoveLocation/-BindAdaptiveScope (+ -Commit) to change scope.' -ForegroundColor Yellow
    return
}

# SAFETY: refuse to add a tenant-wide location.
if ($AddLocation -and $AddLocation -match '^\s*All\s*$') {
    Write-Host "SAFETY STOP: adding 'All' (tenant-wide) is refused — keep cleanup scoped to named locations / an adaptive scope." -ForegroundColor Red
    return
}

# Build the intended change splat.
$splat = @{ Identity = $PolicyName }
if ($AddLocation)         { $splat[$addParam]                 = $AddLocation }
if ($RemoveLocation)      { $splat[$removeParam]              = $RemoveLocation }
if ($BindAdaptiveScope)   { $splat['AddAdaptiveScopeLocation'] = $BindAdaptiveScope }
if ($UnbindAdaptiveScope) { $splat['RemoveAdaptiveScopeLocation'] = $UnbindAdaptiveScope }

if (-not $Commit) {
    Write-Host '-- WhatIf: no changes made. Would run: --' -ForegroundColor Yellow
    Write-Host ("Set-RetentionCompliancePolicy {0}" -f (($splat.GetEnumerator() | ForEach-Object { "-$($_.Key) '$($_.Value)'" }) -join ' '))
    Write-Host 'Re-run with -Commit to apply SCOPE only (action/enable unchanged). Then re-run DLCCLEAN-Validate.ps1 to re-prove the hold cross-check.' -ForegroundColor Yellow
    return
}

Set-RetentionCompliancePolicy @splat -ErrorAction Stop
Write-Host ("Applied scope change to '{0}' (Enabled/action unchanged: Enabled={1})." -f $PolicyName, $p.Enabled) -ForegroundColor Green

$after = Get-RetentionCompliancePolicy -Identity $PolicyName
Write-Host '--- New scope ---' -ForegroundColor Cyan
foreach ($loc in 'ExchangeLocation','SharePointLocation','OneDriveLocation','ModernGroupLocation','AdaptiveScopeLocation') {
    $v = @($after.$loc); if ($v.Count) { Write-Host ("  {0}: {1}" -f $loc, ($v -join ', ')) -ForegroundColor Green }
}
Write-Host 'REMINDER: re-run DLCCLEAN-Validate.ps1 to re-prove that no in-scope item is under hold before enabling/expanding.' -ForegroundColor Yellow
