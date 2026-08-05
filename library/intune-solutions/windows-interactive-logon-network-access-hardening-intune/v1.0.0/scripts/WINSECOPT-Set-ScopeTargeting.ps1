<#
.SYNOPSIS
    WINSECOPT-Set-ScopeTargeting.ps1 — set the target group for the Windows hardening profile.
.DESCRIPTION
    PURPOSE
        Sets or adjusts which Entra security group the interactive-logon & network-access hardening
        Settings Catalog profile is assigned to — the target-group builder for pilot-first, wave-based
        rollout on corporate Windows devices. Optionally adds an assignment exclusion group. Defaults to
        -WhatIf, previewing the assignment change and modifying nothing until re-run to apply. Targets
        THIS gap-only pack's profile only, not NTLM/SMB, RDP, credential-theft, or full-baseline
        hardening.
    HOW TO RUN
        Preview (default, no changes):
          powershell -ExecutionPolicy Bypass -File .\WINSECOPT-Set-ScopeTargeting.ps1 -GroupId your-entra-group-object-id
        Apply the assignment:
          powershell -ExecutionPolicy Bypass -File .\WINSECOPT-Set-ScopeTargeting.ps1 -GroupId your-entra-group-object-id -WhatIf:$false
        Optional: -ExcludeGroupId your-exclusion-group-object-id ; -ProfileName "Interactive Logon & Network-Access Hardening - Pilot"
        (Install once: Install-Module Microsoft.Graph -Scope CurrentUser)
        Required Graph scopes: DeviceManagementConfiguration.ReadWrite.All
    EXPECTED RESULTS
        In preview: the profile found and the assignment that WOULD be set.
        When applied: the profile is assigned to the include group (and excludes the exclusion group).
        Confirm in Intune - Devices - Configuration, or with WINSECOPT-Validation.ps1.
.NOTES
    White-label — the repeatable way. Defaults to -WhatIf; changes require -WhatIf:$false.
#>
[CmdletBinding(SupportsShouldProcess)]
param(
    [Parameter(Mandatory)] [string]$GroupId,
    [string]$ExcludeGroupId,
    [string]$ProfileName = 'Interactive Logon & Network-Access Hardening - Pilot'
)

# Default to preview unless the caller explicitly passes -WhatIf.
if (-not $PSBoundParameters.ContainsKey('WhatIf')) { $WhatIfPreference = $true }

$ErrorActionPreference = 'Stop'
Connect-MgGraph -Scopes 'DeviceManagementConfiguration.ReadWrite.All' | Out-Null

# Locate the Settings Catalog profile (by name first, then by carried settings)
$profile = $null
try {
    $cfg = Invoke-MgGraphRequest -Method GET -Uri "https://graph.microsoft.com/beta/deviceManagement/configurationPolicies?`$filter=platforms eq 'windows10'"
    foreach ($pol in @($cfg.value)) { if ($pol.name -eq $ProfileName) { $profile = $pol; break } }
    if (-not $profile) {
        foreach ($pol in @($cfg.value)) {
            $settings = Invoke-MgGraphRequest -Method GET -Uri "https://graph.microsoft.com/beta/deviceManagement/configurationPolicies/$($pol.id)/settings"
            $json = ("$($settings | ConvertTo-Json -Depth 30)").ToLower()
            if ($json -match 'dontdisplaynetworkselectionui' -and $json -match 'smartcardremovalbehavior') { $profile = $pol; break }
        }
    }
} catch {}

if (-not $profile) { Write-Host "No Windows hardening profile found (looked for '$ProfileName'). Create it first (WINSECOPT-Remediation.ps1)." -ForegroundColor Yellow; return }
Write-Host "Target profile: '$($profile.name)' (id $($profile.id))." -ForegroundColor Cyan

# Build the assignment payload
$assignments = @( @{ target = @{ '@odata.type'='#microsoft.graph.groupAssignmentTarget'; groupId=$GroupId } } )
if ($ExcludeGroupId) { $assignments += @{ target = @{ '@odata.type'='#microsoft.graph.exclusionGroupAssignmentTarget'; groupId=$ExcludeGroupId } } }
$body = @{ assignments = $assignments }

$desc = "include group $GroupId" + $(if ($ExcludeGroupId) { ", exclude group $ExcludeGroupId" } else { '' })
if ($PSCmdlet.ShouldProcess($profile.name, "Set assignment ($desc)")) {
    Invoke-MgGraphRequest -Method POST -Uri "https://graph.microsoft.com/beta/deviceManagement/configurationPolicies/$($profile.id)/assign" -Body ($body | ConvertTo-Json -Depth 8) -ContentType 'application/json' | Out-Null
    Write-Host "Assignment set: $desc." -ForegroundColor Green
} else {
    Write-Host "WhatIf: would set assignment on '$($profile.name)' -> $desc." -ForegroundColor Yellow
}

Write-Host ''
if ($WhatIfPreference) { Write-Host 'Preview only (-WhatIf). Re-run with -WhatIf:$false to apply.' -ForegroundColor Yellow }
else { Write-Host 'Done. Verify with WINSECOPT-Validation.ps1 or in Intune - Devices - Configuration.' -ForegroundColor Green }
