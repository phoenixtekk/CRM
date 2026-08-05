<#
.SYNOPSIS
    CREDGUARD-Set-ScopeTargeting.ps1 — set the target group for a credential-protection profile.
.DESCRIPTION
    PURPOSE
        Sets or adjusts which Entra security group a Windows credential-theft-protection profile
        (Credential Guard, LSASS protection, WDigest, Remote Credential Guard, WinRM, or Windows LAPS) is
        assigned to — the target-group builder for pilot-first, wave-based rollout. Optionally adds an
        assignment exclusion group (e.g. to hold back non-Credential-Guard-capable hardware from the VBS
        controls). Defaults to -WhatIf, previewing the assignment change and modifying nothing until
        re-run to apply. Targets the endpoint credential-protection profiles only, not RDP host hardening
        or domain settings.
    HOW TO RUN
        Preview (default, no changes):
          powershell -ExecutionPolicy Bypass -File .\CREDGUARD-Set-ScopeTargeting.ps1 -GroupId your-entra-group-object-id
        Apply the assignment:
          powershell -ExecutionPolicy Bypass -File .\CREDGUARD-Set-ScopeTargeting.ps1 -GroupId your-entra-group-object-id -WhatIf:$false
        Optional: -ExcludeGroupId your-exclusion-group-object-id ; -ProfileName "Credential Guard - Pilot"
        (Install once: Install-Module Microsoft.Graph -Scope CurrentUser)
        Required Graph scopes: DeviceManagementConfiguration.ReadWrite.All
    EXPECTED RESULTS
        In preview: the profile found and the assignment that WOULD be set.
        When applied: the profile is assigned to the include group (and excludes the exclusion group).
        Confirm in Intune - Devices - Configuration, or with CREDGUARD-Validation.ps1.
.NOTES
    White-label — the repeatable way. Defaults to -WhatIf; changes require -WhatIf:$false.
#>
[CmdletBinding(SupportsShouldProcess)]
param(
    [Parameter(Mandatory)] [string]$GroupId,
    [string]$ExcludeGroupId,
    [string]$ProfileName = 'Credential Guard - Pilot'
)

# Default to preview unless the caller explicitly passes -WhatIf.
if (-not $PSBoundParameters.ContainsKey('WhatIf')) { $WhatIfPreference = $true }

$ErrorActionPreference = 'Stop'
Connect-MgGraph -Scopes 'DeviceManagementConfiguration.ReadWrite.All' | Out-Null

# Locate the profile (Settings Catalog first, then template)
$profile = $null; $kind = 'none'
try {
    $cfg = Invoke-MgGraphRequest -Method GET -Uri "https://graph.microsoft.com/beta/deviceManagement/configurationPolicies?`$filter=platforms eq 'windows10'"
    foreach ($pol in @($cfg.value)) { if ($pol.name -eq $ProfileName) { $profile = $pol; $kind = 'catalog'; break } }
    if (-not $profile) {
        $tpl = Invoke-MgGraphRequest -Method GET -Uri "https://graph.microsoft.com/beta/deviceManagement/deviceConfigurations"
        foreach ($p in @($tpl.value)) { if ($p.displayName -eq $ProfileName) { $profile = $p; $kind = 'template'; break } }
    }
} catch {}

if (-not $profile) { Write-Host "No credential-protection profile found (looked for '$ProfileName'). Create it first (CREDGUARD-Remediation.ps1 or the Implementation Guide)." -ForegroundColor Yellow; return }
$pName = if ($kind -eq 'catalog') { $profile.name } else { $profile.displayName }
$base  = if ($kind -eq 'catalog') { "configurationPolicies/$($profile.id)" } else { "deviceConfigurations/$($profile.id)" }
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
else { Write-Host 'Done. Verify with CREDGUARD-Validation.ps1 or in Intune - Devices - Configuration.' -ForegroundColor Green }
