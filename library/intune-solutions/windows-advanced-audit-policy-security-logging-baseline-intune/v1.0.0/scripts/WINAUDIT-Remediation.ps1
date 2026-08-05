<#
.SYNOPSIS
    WINAUDIT-Remediation.ps1 — safely scaffold and assign the Windows Advanced Audit Policy baseline.
.DESCRIPTION
    PURPOSE
        Remediates the common gap that leaves Windows endpoints under-audited: creates the Windows 10/11
        Settings Catalog audit profile if none exists (the force-subcategory override plus all ~24
        advanced audit subcategories at their CIS / Microsoft-aligned Success/Failure values) and assigns
        it to a target group. Defaults to -WhatIf, so it previews every change and modifies nothing until
        re-run to apply. Remediates the audit configuration baseline only - never SIEM forwarding or a
        broad hardening baseline.

        NOTE: two settings in the baseline are ADMX-backed and their Settings Catalog definition IDs are
        namespaced/version-specific - "Include command line in process creation events" (Step 6c) and
        the Security event-log maximum size (Step 6d). This script creates the CSP-backed audit
        subcategories and the override reliably, then PRINTS a reminder to add those two ADMX settings in
        the portal per the Implementation Guide, rather than guessing their IDs.
    HOW TO RUN
        Preview (default, no changes):
          powershell -ExecutionPolicy Bypass -File .\WINAUDIT-Remediation.ps1 -GroupId your-entra-group-object-id
        Apply the change:
          powershell -ExecutionPolicy Bypass -File .\WINAUDIT-Remediation.ps1 -GroupId your-entra-group-object-id -WhatIf:$false
        Optional: -Name "Win Audit Policy - Baseline - Pilot" ; -EnableFilteringPlatformConnection
        (Install once: Install-Module Microsoft.Graph -Scope CurrentUser)
        Required Graph scopes: DeviceManagementConfiguration.ReadWrite.All
    EXPECTED RESULTS
        In preview: a report of what is missing and exactly what WOULD be created/assigned (each
        subcategory and its recommended value).
        When applied: a Settings Catalog audit profile exists (override + subcategories) and is assigned
        to the group. Re-run WINAUDIT-Discovery.ps1 to confirm READY, and add the two ADMX settings.
.NOTES
    White-label - the repeatable way. Defaults to -WhatIf; changes require -WhatIf:$false.
    Setting definition IDs and choice-option suffixes follow the current documented Settings Catalog /
    Audit-CSP pattern - VERIFY THEM IN YOUR TENANT before fleet rollout; Microsoft occasionally revises.
#>
[CmdletBinding(SupportsShouldProcess)]
param(
    [Parameter(Mandatory)] [string]$GroupId,
    [string]$Name = 'Win Audit Policy - Baseline - Pilot',
    [switch]$EnableFilteringPlatformConnection
)

# Default to preview: if the caller did not pass -WhatIf, turn it on.
if (-not $PSBoundParameters.ContainsKey('WhatIf')) { $WhatIfPreference = $true }

$ErrorActionPreference = 'Stop'
Connect-MgGraph -Scopes 'DeviceManagementConfiguration.ReadWrite.All' | Out-Null

# Recommended baseline: Audit-CSP node name -> value (0=No Auditing, 1=Success, 2=Failure, 3=Success+Failure)
# Aligned to CIS Windows 10/11 Enterprise L1 + Microsoft security baseline (workstation-tuned).
$fpc = if ($EnableFilteringPlatformConnection) { 3 } else { 0 }
$baseline = [ordered]@{
    'AccountLogon_AuditCredentialValidation'            = 3
    'AccountManagement_AuditUserAccountManagement'      = 3
    'AccountManagement_AuditSecurityGroupManagement'    = 3
    'Logon_AuditLogon'                                  = 3
    'Logon_AuditAccountLockout'                         = 2
    'Logon_AuditGroupMembership'                        = 1
    'Logon_AuditSpecialLogon'                           = 1
    'Logon_AuditOtherLogonLogoffEvents'                 = 3
    'ObjectAccess_AuditFileShare'                       = 3
    'ObjectAccess_AuditDetailedFileShare'               = 2
    'ObjectAccess_AuditRemovableStorage'                = 3
    'ObjectAccess_AuditFilteringPlatformConnection'     = $fpc
    'ObjectAccess_AuditOtherObjectAccessEvents'         = 3
    'DetailedTracking_AuditProcessCreation'             = 1
    'DetailedTracking_AuditPNPActivity'                 = 1
    'PrivilegeUse_AuditSensitivePrivilegeUse'           = 3
    'PolicyChange_AuditPolicyChange'                    = 3
    'PolicyChange_AuditAuthenticationPolicyChange'      = 1
    'PolicyChange_AuditMPSSVCRuleLevelPolicyChange'     = 3
    'PolicyChange_AuditOtherPolicyChangeEvents'         = 2
    'System_AuditSecurityStateChange'                   = 3
    'System_AuditSecuritySystemExtension'               = 3
    'System_AuditSystemIntegrity'                       = 3
    'System_AuditOtherSystemEvents'                     = 3
}

# Does a Windows audit Settings Catalog profile already exist?
$existing = $null
try {
    $cfg = Invoke-MgGraphRequest -Method GET -Uri "https://graph.microsoft.com/beta/deviceManagement/configurationPolicies?`$filter=platforms eq 'windows10'"
    foreach ($pol in @($cfg.value)) { if ($pol.name -eq $Name) { $existing = $pol; break } }
    if (-not $existing) {
        foreach ($pol in @($cfg.value)) {
            $settings = Invoke-MgGraphRequest -Method GET -Uri "https://graph.microsoft.com/beta/deviceManagement/configurationPolicies/$($pol.id)/settings"
            if (("$($settings | ConvertTo-Json -Depth 25)") -match 'audit_' -or ("$($settings | ConvertTo-Json -Depth 25)") -match 'ForceAuditPolicy') { $existing = $pol; break }
        }
    }
} catch {}

# Helper: build a Settings Catalog choice-setting instance for a CSP-backed policy
function New-ChoiceSetting([string]$DefId, [int]$Value) {
    @{
        '@odata.type' = '#microsoft.graph.deviceManagementConfigurationSetting'
        settingInstance = @{
            '@odata.type'       = '#microsoft.graph.deviceManagementConfigurationChoiceSettingInstance'
            settingDefinitionId = $DefId
            choiceSettingValue  = @{
                '@odata.type' = '#microsoft.graph.deviceManagementConfigurationChoiceSettingValue'
                value         = "$($DefId)_$Value"
                children      = @()
            }
        }
    }
}

if ($existing) {
    Write-Host "Windows audit Settings Catalog profile already present: '$($existing.name)' (id $($existing.id))." -ForegroundColor Green
    $profileId = $existing.id
} else {
    # Build settings: the force-subcategory override + all subcategories
    $settings = @()

    # Override (Local Policies Security Options -> Audit): Enable
    $overrideId = 'device_vendor_msft_policy_config_localpoliciessecurityoptions_audit_forceauditpolicysubcategorysettingswindowsvistaorlatertooverrideauditpolicycategorysettings'
    $settings += (New-ChoiceSetting $overrideId 1)

    foreach ($node in $baseline.Keys) {
        $defId = 'device_vendor_msft_policy_config_audit_' + $node.ToLower()
        $settings += (New-ChoiceSetting $defId $baseline[$node])
    }

    $policy = @{
        name         = $Name
        description  = 'Windows Advanced Audit Policy baseline (CIS / Microsoft-aligned subcategories + force-subcategory override). Created by WINAUDIT-Remediation.ps1. Add command-line process auditing and Security-log size per the guide (Steps 6c/6d).'
        platforms    = 'windows10'
        technologies = 'mdm'
        settings     = $settings
    }

    if ($PSCmdlet.ShouldProcess($Name, "Create Windows Settings Catalog audit profile with $($baseline.Count) subcategories + override")) {
        $created = Invoke-MgGraphRequest -Method POST -Uri 'https://graph.microsoft.com/beta/deviceManagement/configurationPolicies' -Body ($policy | ConvertTo-Json -Depth 20) -ContentType 'application/json'
        Write-Host "Created profile '$($created.name)' (id $($created.id)) with $($baseline.Count) audit subcategories + force-subcategory override." -ForegroundColor Green
        $profileId = $created.id
    } else {
        Write-Host "WhatIf: would create Windows Settings Catalog audit profile '$Name' with the force-subcategory override (Enable) and these subcategories (0=None,1=Success,2=Failure,3=Success+Failure):" -ForegroundColor Yellow
        foreach ($node in $baseline.Keys) { Write-Host ("  {0,-48} = {1}" -f $node, $baseline[$node]) -ForegroundColor Yellow }
    }
}

# Assign to the target group
if ($profileId -and $PSCmdlet.ShouldProcess("profile $profileId", "Assign to group $GroupId")) {
    $body = @{ assignments = @(@{ target = @{ '@odata.type'='#microsoft.graph.groupAssignmentTarget'; groupId=$GroupId } }) }
    Invoke-MgGraphRequest -Method POST -Uri "https://graph.microsoft.com/beta/deviceManagement/configurationPolicies/$profileId/assign" -Body ($body | ConvertTo-Json -Depth 6) -ContentType 'application/json' | Out-Null
    Write-Host "Assigned profile to group $GroupId." -ForegroundColor Green
} elseif (-not $profileId) {
    Write-Host "WhatIf: would then assign the new profile to group $GroupId." -ForegroundColor Yellow
}

Write-Host ''
Write-Host 'REMINDER: add the two ADMX-backed settings in the portal (their Settings Catalog IDs are version-specific):' -ForegroundColor Cyan
Write-Host '  - Administrative Templates > System > Audit Process Creation > Include command line in process creation events = Enabled (Step 6c)' -ForegroundColor Cyan
Write-Host '  - Administrative Templates > Windows Components > Event Log Service > Security > Specify the maximum log file size (KB) = 196608 (Step 6d)' -ForegroundColor Cyan
Write-Host ''
if ($WhatIfPreference) { Write-Host 'Preview only (-WhatIf). Re-run with -WhatIf:$false to apply.' -ForegroundColor Yellow }
else { Write-Host 'Remediation complete. Re-run WINAUDIT-Discovery.ps1 to confirm READY.' -ForegroundColor Green }
