<#
.SYNOPSIS
    IOSSDMFL-Set-ScopeTargeting.ps1 — assign a shared-device app to the shared-iPhone group.
.DESCRIPTION
    PURPOSE
        Sets or adjusts the target (Assigned) group used for the shared-iPhone rollout by assigning a
        named iOS app (e.g. Microsoft Authenticator or Microsoft Teams) to the group as Required — the
        target-group builder for pilot-first, wave-based expansion. Defaults to -WhatIf, previewing the
        assignment change and modifying nothing until re-run to apply.
    HOW TO RUN
        Preview (default, no changes):
          powershell -ExecutionPolicy Bypass -File .\IOSSDMFL-Set-ScopeTargeting.ps1 -AppName "Microsoft Teams" -GroupName "iPhone SDM - Devices"
        Apply the assignment:
          powershell -ExecutionPolicy Bypass -File .\IOSSDMFL-Set-ScopeTargeting.ps1 -AppName "Microsoft Teams" -GroupName "iPhone SDM - Devices" -WhatIf:$false
        (Install once: Install-Module Microsoft.Graph -Scope CurrentUser)
        Required Graph scopes: DeviceManagementApps.ReadWrite.All, Group.Read.All
    EXPECTED RESULTS
        In preview: the app and group found and the assignment that WOULD be set (Required).
        When applied: the app is assigned Required to the group. Confirm with IOSSDMFL-Validation.ps1.
.NOTES
    White-label — the repeatable way. Defaults to -WhatIf; changes require -WhatIf:$false.
#>
[CmdletBinding(SupportsShouldProcess)]
param(
    [Parameter(Mandatory)] [string]$AppName,
    [string]$GroupName = 'iPhone SDM - Devices'
)

# Default to preview unless the caller explicitly passes -WhatIf.
if (-not $PSBoundParameters.ContainsKey('WhatIf')) { $WhatIfPreference = $true }

$ErrorActionPreference = 'Stop'
Connect-MgGraph -Scopes 'DeviceManagementApps.ReadWrite.All','Group.Read.All' | Out-Null

# Resolve the group
$grp = $null
try { $g = Invoke-MgGraphRequest -Method GET -Uri "https://graph.microsoft.com/v1.0/groups?`$filter=displayName eq '$GroupName'"; $grp = @($g.value)[0] } catch {}
if (-not $grp) { Write-Host "Group '$GroupName' not found. Create it first (IOSSDMFL-Remediation.ps1)." -ForegroundColor Yellow; return }

# Resolve the iOS app by name
$app = $null
try {
    $apps = Invoke-MgGraphRequest -Method GET -Uri "https://graph.microsoft.com/beta/deviceAppManagement/mobileApps?`$filter=(isof('microsoft.graph.iosStoreApp'))"
    $app = @($apps.value | Where-Object { $_.displayName -match [regex]::Escape($AppName) })[0]
} catch {}
if (-not $app) { Write-Host "iOS app matching '$AppName' not found. Add it in Intune - Apps - iOS/iPadOS first." -ForegroundColor Yellow; return }

Write-Host "Target app: '$($app.displayName)' (id $($app.id)); group '$GroupName' (id $($grp.id))." -ForegroundColor Cyan

$assignment = @{
    '@odata.type' = '#microsoft.graph.mobileAppAssignment'
    intent = 'required'
    target = @{ '@odata.type'='#microsoft.graph.groupAssignmentTarget'; groupId=$grp.id }
}
$body = @{ mobileAppAssignments = @($assignment) }

if ($PSCmdlet.ShouldProcess($app.displayName, "Assign Required to '$GroupName'")) {
    Invoke-MgGraphRequest -Method POST -Uri "https://graph.microsoft.com/beta/deviceAppManagement/mobileApps/$($app.id)/assign" -Body ($body | ConvertTo-Json -Depth 8) -ContentType 'application/json' | Out-Null
    Write-Host "Assigned '$($app.displayName)' Required to '$GroupName'." -ForegroundColor Green
} else {
    Write-Host "WhatIf: would assign '$($app.displayName)' Required to '$GroupName'." -ForegroundColor Yellow
}

Write-Host ''
if ($WhatIfPreference) { Write-Host 'Preview only (-WhatIf). Re-run with -WhatIf:$false to apply.' -ForegroundColor Yellow }
else { Write-Host 'Done. Verify with IOSSDMFL-Validation.ps1 or in Intune - Apps - iOS/iPadOS.' -ForegroundColor Green }
