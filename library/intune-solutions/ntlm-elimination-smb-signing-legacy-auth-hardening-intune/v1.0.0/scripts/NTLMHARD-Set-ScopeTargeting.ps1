<#
.SYNOPSIS
    NTLMHARD-Set-ScopeTargeting.ps1 — set the target group for the NTLM/SMB hardening policy.
.DESCRIPTION
    PURPOSE
        Sets or adjusts which Entra security group the NTLM/SMB legacy-auth hardening Settings Catalog
        policy is assigned to — the target-group builder for pilot-first, wave-based rollout on Windows
        10/11 endpoints. Optionally adds an assignment exclusion group. Defaults to -WhatIf, previewing
        the assignment change and modifying nothing until re-run to apply. Targets the endpoint hardening
        policy only, not domain-controller NTLM policy or a full CIS/STIG baseline.
    HOW TO RUN
        Preview (default, no changes):
          powershell -ExecutionPolicy Bypass -File .\NTLMHARD-Set-ScopeTargeting.ps1 -GroupId your-entra-group-object-id
        Apply the assignment:
          powershell -ExecutionPolicy Bypass -File .\NTLMHARD-Set-ScopeTargeting.ps1 -GroupId your-entra-group-object-id -WhatIf:$false
        Optional: -ExcludeGroupId your-exclusion-group-object-id ; -ProfileName "NTLM-SMB Hardening - Pilot"
        (Install once: Install-Module Microsoft.Graph -Scope CurrentUser)
        Required Graph scopes: DeviceManagementConfiguration.ReadWrite.All
    EXPECTED RESULTS
        In preview: the policy found and the assignment that WOULD be set.
        When applied: the policy is assigned to the include group (and excludes the exclusion group).
        Confirm in Intune - Devices - Configuration, or with NTLMHARD-Validation.ps1.
.NOTES
    White-label — the repeatable way. Defaults to -WhatIf; changes require -WhatIf:$false.
#>
[CmdletBinding(SupportsShouldProcess)]
param(
    [Parameter(Mandatory)] [string]$GroupId,
    [string]$ExcludeGroupId,
    [string]$ProfileName = 'NTLM-SMB Hardening - Pilot'
)

# Default to preview unless the caller explicitly passes -WhatIf.
if (-not $PSBoundParameters.ContainsKey('WhatIf')) { $WhatIfPreference = $true }

$ErrorActionPreference = 'Stop'
Connect-MgGraph -Scopes 'DeviceManagementConfiguration.ReadWrite.All' | Out-Null

$anchors = @('lmcompatibilitylevel','requiresecuritysignature','allowinsecureguestauth','restrictremoteclients')

# Locate the Settings Catalog policy (by name, then by settings content)
$policy = $null
try {
    $cfg = Invoke-MgGraphRequest -Method GET -Uri "https://graph.microsoft.com/beta/deviceManagement/configurationPolicies?`$filter=platforms eq 'windows10'"
    foreach ($p in @($cfg.value)) { if ($p.name -eq $ProfileName) { $policy = $p; break } }
    if (-not $policy) {
        foreach ($p in @($cfg.value)) {
            $settings = Invoke-MgGraphRequest -Method GET -Uri "https://graph.microsoft.com/beta/deviceManagement/configurationPolicies/$($p.id)/settings"
            $json = ("$($settings | ConvertTo-Json -Depth 30)").ToLower()
            if (($anchors | Where-Object { $json -match [regex]::Escape($_) }).Count -ge 2) { $policy = $p; break }
        }
    }
} catch {}

if (-not $policy) { Write-Host "No NTLM/SMB hardening policy found (looked for '$ProfileName'). Create it first (NTLMHARD-Remediation.ps1)." -ForegroundColor Yellow; return }
$pName = $policy.name
Write-Host "Target policy: '$pName' (id $($policy.id))." -ForegroundColor Cyan

# Build the assignment payload
$assignments = @( @{ target = @{ '@odata.type'='#microsoft.graph.groupAssignmentTarget'; groupId=$GroupId } } )
if ($ExcludeGroupId) { $assignments += @{ target = @{ '@odata.type'='#microsoft.graph.exclusionGroupAssignmentTarget'; groupId=$ExcludeGroupId } } }
$body = @{ assignments = $assignments }

$desc = "include group $GroupId" + $(if ($ExcludeGroupId) { ", exclude group $ExcludeGroupId" } else { '' })
if ($PSCmdlet.ShouldProcess($pName, "Set assignment ($desc)")) {
    Invoke-MgGraphRequest -Method POST -Uri "https://graph.microsoft.com/beta/deviceManagement/configurationPolicies/$($policy.id)/assign" -Body ($body | ConvertTo-Json -Depth 8) -ContentType 'application/json' | Out-Null
    Write-Host "Assignment set: $desc." -ForegroundColor Green
} else {
    Write-Host "WhatIf: would set assignment on '$pName' -> $desc." -ForegroundColor Yellow
}

Write-Host ''
if ($WhatIfPreference) { Write-Host 'Preview only (-WhatIf). Re-run with -WhatIf:$false to apply.' -ForegroundColor Yellow }
else { Write-Host 'Done. Verify with NTLMHARD-Validation.ps1 or in Intune - Devices - Configuration.' -ForegroundColor Green }
