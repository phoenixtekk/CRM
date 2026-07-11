<#
.SYNOPSIS
    SOPEIS-Set-Assignment.ps1 — add a group assignment to an endpoint-security policy to expand
    coverage. SAFE PREVIEW by default (-WhatIf); makes the change only when explicitly confirmed.
.DESCRIPTION
    PURPOSE
        Change helper for the "Solution Optimization — Endpoint Security with Microsoft Intune"
        solution. Adds an include assignment for the named group (e.g. the pilot ring) to a named
        settings-catalog / endpoint-security policy so previously unassigned devices receive it.
        This is the only script that can change configuration, and it DEFAULTS TO A SAFE PREVIEW.
        Expanding coverage must not double-target a device (which re-creates conflict) — validate
        with SOPEIS-ConflictReport.ps1 after applying.
    HOW TO RUN
        # Preview the assignment that WOULD be added (default — changes nothing):
        powershell -ExecutionPolicy Bypass -File .\SOPEIS-Set-Assignment.ps1 `
            -PolicyName 'Endpoint Security - Antivirus - Prod' -GroupName 'Intune Optimize - Pilot Ring - Pilot'
        # Apply (explicit — required to make the change):
        powershell -ExecutionPolicy Bypass -File .\SOPEIS-Set-Assignment.ps1 `
            -PolicyName 'Endpoint Security - Antivirus - Prod' -GroupName 'Intune Optimize - Pilot Ring - Pilot' -Apply
        Requires Microsoft.Graph with DeviceManagementConfiguration.ReadWrite.All and Group.Read.All.
    EXPECTED RESULTS
        Preview: prints the resolved policy id, group id, and the include assignment it WOULD add
        (preserving existing assignments).
        Apply: adds the assignment; validate coverage with SOPEIS-Validate.ps1 and re-check for
        double-targeting with SOPEIS-ConflictReport.ps1.
.NOTES
    White-label. DEFAULTS TO -WhatIf/preview. Pilot ring first; do not double-target a device.
    Rollback: remove the added assignment in the portal or re-apply the prior assignment set.
#>
[CmdletBinding()]
param(
    [Parameter(Mandatory)] [string]$PolicyName,
    [Parameter(Mandatory)] [string]$GroupName,
    [switch]$Apply
)

if (-not (Get-Module -ListAvailable -Name Microsoft.Graph.Authentication)) {
    Install-Module Microsoft.Graph.Authentication -Scope CurrentUser -Force -AllowClobber
}
Import-Module Microsoft.Graph.Authentication -ErrorAction Stop

$writeScope = if ($Apply) { 'DeviceManagementConfiguration.ReadWrite.All' } else { 'DeviceManagementConfiguration.Read.All' }
if (-not (Get-MgContext)) { Connect-MgGraph -Scopes $writeScope,'Group.Read.All' -NoWelcome | Out-Null }

$whatIf = -not $Apply
Write-Host "`n=== SOPEIS add policy assignment (expand coverage) ===" -ForegroundColor Cyan
Write-Host ("Mode: {0}" -f ($(if ($whatIf) { 'PREVIEW (-WhatIf) — no changes' } else { 'APPLY — will add assignment' }))) -ForegroundColor $(if ($whatIf) { 'Yellow' } else { 'Red' })

# Resolve the group.
$grp = (Invoke-MgGraphRequest -Method GET -Uri ("https://graph.microsoft.com/v1.0/groups?`$filter=displayName eq '{0}'" -f $GroupName)).value | Select-Object -First 1
if (-not $grp) { Write-Host ("Group '{0}' not found." -f $GroupName) -ForegroundColor Red; return }
Write-Host ("Group : {0}  ({1})" -f $grp.displayName, $grp.id)

# Resolve the policy.
$pol = (Invoke-MgGraphRequest -Method GET -Uri ("https://graph.microsoft.com/beta/deviceManagement/configurationPolicies?`$filter=name eq '{0}'&`$expand=assignments" -f $PolicyName)).value | Select-Object -First 1
if (-not $pol) { Write-Host ("Policy '{0}' not found." -f $PolicyName) -ForegroundColor Red; return }
Write-Host ("Policy: {0}  ({1})" -f $pol.name, $pol.id)

# Already assigned?
$already = $pol.assignments | Where-Object { $_.target.groupId -eq $grp.id }
if ($already) { Write-Host "Group is ALREADY assigned to this policy — nothing to add." -ForegroundColor Green; return }

if ($whatIf) {
    Write-Host "`nWOULD add an include assignment for the group above (existing assignments preserved)." -ForegroundColor Yellow
    Write-Host "Confirm this device set is not already covered by another policy for the same settings (avoid conflict)." -ForegroundColor Yellow
    Write-Host "Re-run with -Apply to add the assignment." -ForegroundColor Yellow
    return
}

# Apply: rebuild the assignment set = existing + new include target.
$targets = @()
foreach ($a in $pol.assignments) { $targets += @{ target = $a.target } }
$targets += @{ target = @{ '@odata.type' = '#microsoft.graph.groupAssignmentTarget'; groupId = $grp.id } }
$body = @{ assignments = $targets } | ConvertTo-Json -Depth 8

try {
    Invoke-MgGraphRequest -Method POST -Uri ("https://graph.microsoft.com/beta/deviceManagement/configurationPolicies/{0}/assign" -f $pol.id) -Body $body -ContentType 'application/json' -ErrorAction Stop | Out-Null
    Write-Host "`nAPPLIED — assignment added. Validate coverage with SOPEIS-Validate.ps1 and re-check conflicts." -ForegroundColor Green
    Write-Host "Rollback: re-run assign with the prior target set, or remove the group in the portal." -ForegroundColor DarkGray
} catch {
    Write-Host ("Assignment failed: {0}" -f $_.Exception.Message) -ForegroundColor Red
}
