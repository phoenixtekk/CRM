<#
.SYNOPSIS
    EDGEBIZ-Remediation.ps1 — safely create/fix the Microsoft Edge for Business Settings Catalog baseline.
.DESCRIPTION
    PURPOSE
        Remediates the common gap that leaves Microsoft Edge unmanaged on corporate Windows devices:
        creates the Settings Catalog Edge baseline profile ('Edge for Business - Baseline - Pilot') with the
        two most important settings pre-set — PasswordManagerEnabled = Disabled (assessment Finding #1) and
        SmartScreen Enabled — and assigns it to a target group. Defaults to -WhatIf, so it previews every
        change and modifies nothing until re-run to apply. Remediates the Windows Edge configuration baseline
        only — it does not create the default-browser profile or the Edge security baseline (do those in the
        Implementation guide).
    HOW TO RUN
        Preview (default, no changes):
          powershell -ExecutionPolicy Bypass -File .\EDGEBIZ-Remediation.ps1 -GroupId your-entra-group-object-id
        Apply the change:
          powershell -ExecutionPolicy Bypass -File .\EDGEBIZ-Remediation.ps1 -GroupId your-entra-group-object-id -WhatIf:$false
        (Install once: Install-Module Microsoft.Graph -Scope CurrentUser)
        Required Graph scopes: DeviceManagementConfiguration.ReadWrite.All
    EXPECTED RESULTS
        In preview: a report of what is missing and exactly what WOULD be created/assigned.
        When applied: an 'Edge for Business - Baseline - Pilot' Settings Catalog profile exists (password
        manager off, SmartScreen on) and is assigned to the group. Re-run EDGEBIZ-Discovery.ps1 to confirm.
.NOTES
    White-label — the repeatable way. Defaults to -WhatIf; changes require -WhatIf:$false.
    The Edge setting definition IDs below reflect current Microsoft documentation; Edge revises policies
    frequently — VERIFY the setting definition IDs in your tenant's Settings Catalog before relying on them,
    and add the remaining hardening settings (extensions, sync/sign-in, IE mode, startup) per Implementation
    Step 7 either here or in the portal.
#>
[CmdletBinding(SupportsShouldProcess)]
param(
    [Parameter(Mandatory)] [string]$GroupId,
    [string]$Name = 'Edge for Business - Baseline - Pilot'
)

# Default to preview: if the caller did not pass -WhatIf, turn it on.
if (-not $PSBoundParameters.ContainsKey('WhatIf')) { $WhatIfPreference = $true }

$ErrorActionPreference = 'Stop'
Connect-MgGraph -Scopes 'DeviceManagementConfiguration.ReadWrite.All' | Out-Null

# Does an Edge Settings Catalog baseline already exist (by name, or by configuring the Edge password manager)?
$existing = $null
try {
    $cfg = Invoke-MgGraphRequest -Method GET -Uri "https://graph.microsoft.com/beta/deviceManagement/configurationPolicies?`$filter=platforms eq 'windows10'"
    foreach ($pol in @($cfg.value)) { if ($pol.name -eq $Name) { $existing = $pol; break } }
    if (-not $existing) {
        foreach ($pol in @($cfg.value)) {
            $s = Invoke-MgGraphRequest -Method GET -Uri "https://graph.microsoft.com/beta/deviceManagement/configurationPolicies/$($pol.id)/settings"
            if (("$($s | ConvertTo-Json -Depth 25)") -match 'microsoft_edge.*passwordmanager') { $existing = $pol; break }
        }
    }
} catch {}

$policyId = $null
if ($existing) {
    Write-Host "Edge baseline already present: '$($existing.name)' (id $($existing.id))." -ForegroundColor Green
    $policyId = $existing.id
} else {
    # Build a Settings Catalog policy carrying the two core Edge settings.
    # NOTE: setting definition IDs are the ADMX-backed Edge IDs — VERIFY in your tenant before relying on them.
    $body = @{
        name         = $Name
        description  = 'Microsoft Edge for Business enterprise configuration baseline — password manager off, SmartScreen on. Created by EDGEBIZ-Remediation.ps1. Add remaining hardening settings per the Implementation guide.'
        platforms    = 'windows10'
        technologies = 'mdm'
        settings     = @(
            @{
                '@odata.type' = '#microsoft.graph.deviceManagementConfigurationSetting'
                settingInstance = @{
                    '@odata.type' = '#microsoft.graph.deviceManagementConfigurationChoiceSettingInstance'
                    settingDefinitionId = 'device_vendor_msft_policy_config_microsoft_edge~policy~microsoft_edge~passwordmanager_passwordmanagerenabled'
                    choiceSettingValue = @{
                        '@odata.type' = '#microsoft.graph.deviceManagementConfigurationChoiceSettingValue'
                        value = 'device_vendor_msft_policy_config_microsoft_edge~policy~microsoft_edge~passwordmanager_passwordmanagerenabled_0'  # 0 = Disabled
                        children = @()
                    }
                }
            },
            @{
                '@odata.type' = '#microsoft.graph.deviceManagementConfigurationSetting'
                settingInstance = @{
                    '@odata.type' = '#microsoft.graph.deviceManagementConfigurationChoiceSettingInstance'
                    settingDefinitionId = 'device_vendor_msft_policy_config_microsoft_edge~policy~microsoft_edge~smartscreen_smartscreenenabled'
                    choiceSettingValue = @{
                        '@odata.type' = '#microsoft.graph.deviceManagementConfigurationChoiceSettingValue'
                        value = 'device_vendor_msft_policy_config_microsoft_edge~policy~microsoft_edge~smartscreen_smartscreenenabled_1'  # 1 = Enabled
                        children = @()
                    }
                }
            }
        )
    }
    if ($PSCmdlet.ShouldProcess($Name, 'Create Microsoft Edge Settings Catalog baseline (password manager Disabled, SmartScreen Enabled)')) {
        $created = Invoke-MgGraphRequest -Method POST -Uri 'https://graph.microsoft.com/beta/deviceManagement/configurationPolicies' -Body ($body | ConvertTo-Json -Depth 25) -ContentType 'application/json'
        Write-Host "Created Edge baseline '$($created.name)' (id $($created.id))." -ForegroundColor Green
        $policyId = $created.id
    } else {
        Write-Host "WhatIf: would create Settings Catalog Edge baseline '$Name' with PasswordManagerEnabled=Disabled and SmartScreenEnabled=Enabled. Add the remaining hardening settings (extensions, sync/sign-in, typosquatting, startup, IE mode, update channel) per Implementation Step 7." -ForegroundColor Yellow
    }
}

# Assign to the target group
if ($policyId -and $PSCmdlet.ShouldProcess("policy $policyId", "Assign to group $GroupId")) {
    $assign = @{ assignments = @(@{ target = @{ '@odata.type'='#microsoft.graph.groupAssignmentTarget'; groupId=$GroupId } }) }
    Invoke-MgGraphRequest -Method POST -Uri "https://graph.microsoft.com/beta/deviceManagement/configurationPolicies/$policyId/assign" -Body ($assign | ConvertTo-Json -Depth 6) -ContentType 'application/json' | Out-Null
    Write-Host "Assigned Edge baseline to group $GroupId." -ForegroundColor Green
} elseif (-not $policyId) {
    Write-Host "WhatIf: would then assign the new Edge baseline to group $GroupId." -ForegroundColor Yellow
}

Write-Host ''
if ($WhatIfPreference) { Write-Host 'Preview only (-WhatIf). Re-run with -WhatIf:$false to apply.' -ForegroundColor Yellow }
else { Write-Host 'Remediation complete. Re-run EDGEBIZ-Discovery.ps1 to confirm READY, then finish the remaining settings per the Implementation guide.' -ForegroundColor Green }
