<#
.SYNOPSIS
    IOSSSOEXT-Set-ScopeTargeting.ps1 — set the target group for the iOS SSO app-extension profile.
.DESCRIPTION
    PURPOSE
        Sets or adjusts which Entra security group the Microsoft Enterprise SSO app-extension profile
        is assigned to — the target-group builder for pilot-first, wave-based rollout on corporate
        iPhones/iPads. Optionally adds an assignment exclusion group. Defaults to -WhatIf, previewing
        the assignment change and modifying nothing until re-run to apply. Targets the app/browser SSO
        extension profile only, not shared-device identity or enrollment.
    HOW TO RUN
        Preview (default, no changes):
          powershell -ExecutionPolicy Bypass -File .\IOSSSOEXT-Set-ScopeTargeting.ps1 -GroupId your-entra-group-object-id
        Apply the assignment:
          powershell -ExecutionPolicy Bypass -File .\IOSSSOEXT-Set-ScopeTargeting.ps1 -GroupId your-entra-group-object-id -WhatIf:$false
        Optional: -ExcludeGroupId your-exclusion-group-object-id ; -ProfileName "iOS SSO App Extension - Pilot"
        (Install once: Install-Module Microsoft.Graph -Scope CurrentUser)
        Required Graph scopes: DeviceManagementConfiguration.ReadWrite.All
    EXPECTED RESULTS
        In preview: the profile found and the assignment that WOULD be set.
        When applied: the profile is assigned to the include group (and excludes the exclusion group).
        Confirm in Intune - Devices - Configuration, or with IOSSSOEXT-Validation.ps1.
.NOTES
    White-label — the repeatable way. Defaults to -WhatIf; changes require -WhatIf:$false.
#>
[CmdletBinding(SupportsShouldProcess)]
param(
    [Parameter(Mandatory)] [string]$GroupId,
    [string]$ExcludeGroupId,
    [string]$ProfileName = 'iOS SSO App Extension - Pilot'
)

# Default to preview unless the caller explicitly passes -WhatIf.
if (-not $PSBoundParameters.ContainsKey('WhatIf')) { $WhatIfPreference = $true }

$ErrorActionPreference = 'Stop'
Connect-MgGraph -Scopes 'DeviceManagementConfiguration.ReadWrite.All' | Out-Null

$ExtensionId = 'com.microsoft.azureauthenticator.ssoextension'

# Locate the SSO app-extension profile (template first, then settings catalog)
$profile = $null; $kind = 'none'
try {
    $tpl = Invoke-MgGraphRequest -Method GET -Uri "https://graph.microsoft.com/beta/deviceManagement/deviceConfigurations?`$filter=isof('microsoft.graph.iosDeviceFeaturesConfiguration')"
    foreach ($p in @($tpl.value)) { if ($p.displayName -eq $ProfileName) { $profile = $p; $kind = 'template'; break } }
    if (-not $profile) { foreach ($p in @($tpl.value)) { if (("$($p | ConvertTo-Json -Depth 30)") -match 'singleSignOnExtension') { $profile = $p; $kind = 'template'; break } } }
    if (-not $profile) {
        $cfg = Invoke-MgGraphRequest -Method GET -Uri "https://graph.microsoft.com/beta/deviceManagement/configurationPolicies?`$filter=platforms eq 'iOS'"
        foreach ($pol in @($cfg.value)) {
            if ($pol.name -eq $ProfileName) { $profile = $pol; $kind = 'catalog'; break }
            $settings = Invoke-MgGraphRequest -Method GET -Uri "https://graph.microsoft.com/beta/deviceManagement/configurationPolicies/$($pol.id)/settings"
            if (("$($settings | ConvertTo-Json -Depth 25)") -match [regex]::Escape($ExtensionId)) { $profile = $pol; $kind = 'catalog'; break }
        }
    }
} catch {}

if (-not $profile) { Write-Host "No iOS SSO app-extension profile found (looked for '$ProfileName'). Create it first (IOSSSOEXT-Remediation.ps1)." -ForegroundColor Yellow; return }
$pName = if ($kind -eq 'template') { $profile.displayName } else { $profile.name }
$base  = if ($kind -eq 'template') { "deviceConfigurations/$($profile.id)" } else { "configurationPolicies/$($profile.id)" }
Write-Host "Target profile: '$pName' ($kind, id $($profile.id))." -ForegroundColor Cyan

# Build the assignment payload
$assignments = @( @{ target = @{ '@odata.type'='#microsoft.graph.groupAssignmentTarget'; groupId=$GroupId } } )
if ($ExcludeGroupId) { $assignments += @{ target = @{ '@odata.type'='#microsoft.graph.exclusionGroupAssignmentTarget'; groupId=$ExcludeGroupId } } }
$body = @{ assignments = $assignments }

$desc = "include group $GroupId" + $(if ($ExcludeGroupId) { ", exclude group $ExcludeGroupId" } else { '' })
if ($PSCmdlet.ShouldProcess($pName, "Set assignment ($desc)")) {
    Invoke-MgGraphRequest -Method POST -Uri "https://graph.microsoft.com/beta/deviceManagement/$base/assign" -Body ($body | ConvertTo-Json -Depth 8) -ContentType 'application/json' | Out-Null
    Write-Host "Assignment set: $desc." -ForegroundColor Green
} else {
    Write-Host "WhatIf: would set assignment on '$pName' -> $desc." -ForegroundColor Yellow
}

Write-Host ''
if ($WhatIfPreference) { Write-Host 'Preview only (-WhatIf). Re-run with -WhatIf:$false to apply.' -ForegroundColor Yellow }
else { Write-Host 'Done. Verify with IOSSSOEXT-Validation.ps1 or in Intune - Devices - Configuration.' -ForegroundColor Green }
