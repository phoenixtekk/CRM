<#
.SYNOPSIS
    HPWXP-Remediation.ps1 — safely fix a missing/mis-scoped HP WXP agent app assignment.
.DESCRIPTION
    PURPOSE
        Remediates the most common gap that leaves HP Workforce Experience Platform (WXP) telemetry
        undeployed: the HP WXP agent Intune Win32 app exists but is NOT assigned (Required) to the
        target device group. This script adds a Required assignment for the given -GroupId to the agent
        app (matched by -AppName, default 'HP WXP Agent - Pilot'), preserving any existing assignments.
        Defaults to -WhatIf, so it previews every change and modifies nothing until re-run to apply.
        It also reports (does not create) whether the HP WXP tenant-connector service principal is
        present — creating that requires the Global-Admin CONSENT flow from the HP WXP admin console,
        which cannot be scripted here.
        NOTE: this does not CREATE the Win32 app — a Win32 app needs an .intunewin content upload; build
        it via the Implementation Guide (Phase 2). This script fixes the ASSIGNMENT.
    HOW TO RUN
        Preview (default, no changes):
          powershell -ExecutionPolicy Bypass -File .\HPWXP-Remediation.ps1 -GroupId your-entra-group-object-id
        Apply the change:
          powershell -ExecutionPolicy Bypass -File .\HPWXP-Remediation.ps1 -GroupId your-entra-group-object-id -WhatIf:$false
        Optional: -AppName "HP WXP Agent - Pilot" ; -ConnectorAppName "HP Workforce Experience"
        (Install once: Install-Module Microsoft.Graph -Scope CurrentUser)
        Required Graph scopes: DeviceManagementApps.ReadWrite.All, Application.Read.All
    EXPECTED RESULTS
        In preview: a report of what is missing and exactly what WOULD be assigned.
        When applied: the HP WXP agent app has a Required assignment to the group. Re-run
        HPWXP-Discovery.ps1 to confirm READY.
.NOTES
    White-label — the repeatable way. Defaults to -WhatIf; changes require -WhatIf:$false.
#>
[CmdletBinding(SupportsShouldProcess)]
param(
    [Parameter(Mandatory)] [string]$GroupId,
    [string]$AppName = 'HP WXP Agent - Pilot',
    [string]$ConnectorAppName = 'HP Workforce Experience'
)

# Default to preview: if the caller did not pass -WhatIf, turn it on.
if (-not $PSBoundParameters.ContainsKey('WhatIf')) { $WhatIfPreference = $true }

$ErrorActionPreference = 'Stop'
Connect-MgGraph -Scopes 'DeviceManagementApps.ReadWrite.All','Application.Read.All' | Out-Null

# Locate the HP WXP agent app
$app = $null
try {
    $apps = Invoke-MgGraphRequest -Method GET -Uri "https://graph.microsoft.com/v1.0/deviceAppManagement/mobileApps?`$filter=contains(displayName,'HP WXP')"
    $app = @($apps.value | Where-Object { $_.displayName -eq $AppName } | Select-Object -First 1)
    if (-not $app) { $app = @($apps.value | Where-Object { $_.displayName -match [regex]::Escape($AppName) -or $_.displayName -match 'HP WXP' } | Select-Object -First 1) }
    if ($app -is [array]) { $app = $app[0] }
} catch {}

if (-not $app) {
    Write-Host "No HP WXP agent app found (looked for '$AppName'). Create the Win32 app first (Implementation Guide, Phase 2) — a Win32 app needs an .intunewin upload and cannot be created by this script." -ForegroundColor Yellow
    return
}
Write-Host "Target app: '$($app.displayName)' (id $($app.id))." -ForegroundColor Cyan

# Existing assignments — preserve them, add the group as Required if absent
$existing = @()
try {
    $asg = Invoke-MgGraphRequest -Method GET -Uri "https://graph.microsoft.com/v1.0/deviceAppManagement/mobileApps/$($app.id)/assignments"
    $existing = @($asg.value)
} catch {}
$alreadyGroups = @($existing | ForEach-Object { $_.target.groupId } | Where-Object { $_ })

if ($alreadyGroups -contains $GroupId) {
    Write-Host "Group $GroupId is already assigned to '$($app.displayName)'. No assignment change needed." -ForegroundColor Green
} else {
    # Rebuild the assignment set: keep existing + add Required for the group
    $assignments = @()
    foreach ($a in $existing) {
        $assignments += @{ intent = $a.intent; target = $a.target; settings = $a.settings }
    }
    $assignments += @{
        intent = 'required'
        target = @{ '@odata.type' = '#microsoft.graph.groupAssignmentTarget'; groupId = $GroupId }
    }
    $body = @{ mobileAppAssignments = $assignments }
    if ($PSCmdlet.ShouldProcess("app $($app.displayName)", "Add Required assignment for group $GroupId")) {
        Invoke-MgGraphRequest -Method POST -Uri "https://graph.microsoft.com/v1.0/deviceAppManagement/mobileApps/$($app.id)/assign" -Body ($body | ConvertTo-Json -Depth 10) -ContentType 'application/json' | Out-Null
        Write-Host "Assigned '$($app.displayName)' Required to group $GroupId (existing assignments preserved)." -ForegroundColor Green
    } else {
        Write-Host "WhatIf: would add a Required assignment for group $GroupId to '$($app.displayName)', preserving $(@($existing).Count) existing assignment(s)." -ForegroundColor Yellow
    }
}

# Report (do not create) the connector service principal — creation requires admin CONSENT from the WXP console
try {
    $sp = Invoke-MgGraphRequest -Method GET -Uri "https://graph.microsoft.com/v1.0/servicePrincipals?`$filter=startswith(displayName,'$ConnectorAppName')"
    $found = @($sp.value).Count -gt 0
    if ($found) { Write-Host "Connector service principal present: $((@($sp.value) | ForEach-Object displayName) -join '; ')." -ForegroundColor Green }
    else { Write-Host "Connector service principal '$ConnectorAppName' NOT found. This is created by the Global-Admin CONSENT flow initiated from the HP WXP admin console (Implementation Guide, Phase 3) — it cannot be scripted here. Verify the display name in Entra > Enterprise applications." -ForegroundColor Yellow }
} catch { Write-Warning "Could not query service principals: $($_.Exception.Message)" }

Write-Host ''
if ($WhatIfPreference) { Write-Host 'Preview only (-WhatIf). Re-run with -WhatIf:$false to apply.' -ForegroundColor Yellow }
else { Write-Host 'Remediation complete. Re-run HPWXP-Discovery.ps1 to confirm READY.' -ForegroundColor Green }
