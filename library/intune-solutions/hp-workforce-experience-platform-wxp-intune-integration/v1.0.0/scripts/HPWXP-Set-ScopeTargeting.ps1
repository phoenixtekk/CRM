<#
.SYNOPSIS
    HPWXP-Set-ScopeTargeting.ps1 — set the target group for the HP WXP agent Intune app.
.DESCRIPTION
    PURPOSE
        Sets or adjusts which Entra security group(s) the HP Workforce Experience Platform (WXP) agent
        Intune Win32 app is assigned to — the target-group builder for pilot-first, wave-based rollout.
        Assigns the app (matched by -AppName, default 'HP WXP Agent - Pilot') Required to -GroupId, and
        optionally excludes -ExcludeGroupId. Defaults to -WhatIf, previewing the assignment change and
        modifying nothing until re-run to apply. Targets the AGENT-VIA-INTUNE half only; the
        tenant-connector half is established by the admin-consent flow (Implementation Guide, Phase 3).
        By default this REPLACES the app's assignment set with the include (+ optional exclude); pass
        -Add to preserve existing assignments and only add the include group.
    HOW TO RUN
        Preview (default, no changes):
          powershell -ExecutionPolicy Bypass -File .\HPWXP-Set-ScopeTargeting.ps1 -GroupId your-entra-group-object-id
        Apply the assignment:
          powershell -ExecutionPolicy Bypass -File .\HPWXP-Set-ScopeTargeting.ps1 -GroupId your-entra-group-object-id -WhatIf:$false
        Optional: -ExcludeGroupId your-exclusion-group-object-id ; -AppName "HP WXP Agent - Pilot" ; -Add
        (Install once: Install-Module Microsoft.Graph -Scope CurrentUser)
        Required Graph scopes: DeviceManagementApps.ReadWrite.All
    EXPECTED RESULTS
        In preview: the app found and the assignment that WOULD be set.
        When applied: the app is assigned Required to the include group (and excludes the exclusion
        group). Confirm in Intune > Apps > Windows, or with HPWXP-Validation.ps1.
.NOTES
    White-label — the repeatable way. Defaults to -WhatIf; changes require -WhatIf:$false.
#>
[CmdletBinding(SupportsShouldProcess)]
param(
    [Parameter(Mandatory)] [string]$GroupId,
    [string]$ExcludeGroupId,
    [string]$AppName = 'HP WXP Agent - Pilot',
    [switch]$Add
)

# Default to preview unless the caller explicitly passes -WhatIf.
if (-not $PSBoundParameters.ContainsKey('WhatIf')) { $WhatIfPreference = $true }

$ErrorActionPreference = 'Stop'
Connect-MgGraph -Scopes 'DeviceManagementApps.ReadWrite.All' | Out-Null

# Locate the HP WXP agent app
$app = $null
try {
    $apps = Invoke-MgGraphRequest -Method GET -Uri "https://graph.microsoft.com/v1.0/deviceAppManagement/mobileApps?`$filter=contains(displayName,'HP WXP')"
    $app = @($apps.value | Where-Object { $_.displayName -eq $AppName } | Select-Object -First 1)
    if (-not $app) { $app = @($apps.value | Where-Object { $_.displayName -match [regex]::Escape($AppName) -or $_.displayName -match 'HP WXP' } | Select-Object -First 1) }
    if ($app -is [array]) { $app = $app[0] }
} catch {}

if (-not $app) { Write-Host "No HP WXP agent app found (looked for '$AppName'). Create it first (Implementation Guide, Phase 2)." -ForegroundColor Yellow; return }
Write-Host "Target app: '$($app.displayName)' (id $($app.id))." -ForegroundColor Cyan

# Build the assignment payload
$assignments = @()
if ($Add) {
    try {
        $asg = Invoke-MgGraphRequest -Method GET -Uri "https://graph.microsoft.com/v1.0/deviceAppManagement/mobileApps/$($app.id)/assignments"
        foreach ($a in @($asg.value)) { $assignments += @{ intent = $a.intent; target = $a.target; settings = $a.settings } }
    } catch {}
}
$assignments += @{ intent = 'required'; target = @{ '@odata.type' = '#microsoft.graph.groupAssignmentTarget'; groupId = $GroupId } }
if ($ExcludeGroupId) { $assignments += @{ intent = 'required'; target = @{ '@odata.type' = '#microsoft.graph.exclusionGroupAssignmentTarget'; groupId = $ExcludeGroupId } } }
$body = @{ mobileAppAssignments = $assignments }

$mode = if ($Add) { 'add to existing' } else { 'replace assignment set' }
$desc = "Required include group $GroupId" + $(if ($ExcludeGroupId) { ", exclude group $ExcludeGroupId" } else { '' }) + " ($mode)"
if ($PSCmdlet.ShouldProcess($app.displayName, "Set assignment: $desc")) {
    Invoke-MgGraphRequest -Method POST -Uri "https://graph.microsoft.com/v1.0/deviceAppManagement/mobileApps/$($app.id)/assign" -Body ($body | ConvertTo-Json -Depth 10) -ContentType 'application/json' | Out-Null
    Write-Host "Assignment set: $desc." -ForegroundColor Green
} else {
    Write-Host "WhatIf: would set assignment on '$($app.displayName)' -> $desc." -ForegroundColor Yellow
}

Write-Host ''
if ($WhatIfPreference) { Write-Host 'Preview only (-WhatIf). Re-run with -WhatIf:$false to apply.' -ForegroundColor Yellow }
else { Write-Host 'Done. Verify with HPWXP-Validation.ps1 or in Intune > Apps > Windows.' -ForegroundColor Green }
