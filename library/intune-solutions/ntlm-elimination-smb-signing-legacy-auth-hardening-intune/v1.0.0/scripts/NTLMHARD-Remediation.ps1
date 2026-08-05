<#
.SYNOPSIS
    NTLMHARD-Remediation.ps1 — safely scaffold and assign the NTLM/SMB hardening Settings Catalog policy.
.DESCRIPTION
    PURPOSE
        Remediates the common gap that leaves Windows endpoints exposed to legacy authentication: creates
        a Windows Settings Catalog policy carrying the core NTLM/SMB legacy-auth controls if none exists,
        and assigns it to a target group. Defaults to -WhatIf, so it previews every change and modifies
        nothing until re-run to apply. Remediates the endpoint hardening policy only — never
        domain-controller NTLM policy or a full CIS/STIG baseline.

        HONESTY NOTE (VERIFY-IN-TENANT): Settings Catalog setting identifiers can drift between service
        releases. This script POSTs the three highest-confidence, well-documented Local Policies\Security
        Options controls (LAN Manager authentication level = 5; Microsoft network CLIENT and SERVER
        digitally sign communications (always) = Enabled). The remaining controls — NTLM SSP minimum
        session security (client/server), insecure guest logons, and unauthenticated-RPC restriction —
        are printed for you to add and confirm in the portal against your tenant's current catalog
        strings (Implementation Step 6). Nothing is invented: registry anchors are given for each.
    HOW TO RUN
        Preview (default, no changes):
          powershell -ExecutionPolicy Bypass -File .\NTLMHARD-Remediation.ps1 -GroupId your-entra-group-object-id
        Apply the change:
          powershell -ExecutionPolicy Bypass -File .\NTLMHARD-Remediation.ps1 -GroupId your-entra-group-object-id -WhatIf:$false
        (Install once: Install-Module Microsoft.Graph -Scope CurrentUser)
        Required Graph scopes: DeviceManagementConfiguration.ReadWrite.All
    EXPECTED RESULTS
        In preview: a report of what is missing, the policy it WOULD create, and the full seven-setting
        plan (with registry anchors) to complete in the portal.
        When applied: a Windows Settings Catalog policy exists (core NTLM/SMB controls) and is assigned to
        the group; finish the remaining settings in the portal, then re-run NTLMHARD-Discovery.ps1.
.NOTES
    White-label — the repeatable way. Defaults to -WhatIf; changes require -WhatIf:$false.
#>
[CmdletBinding(SupportsShouldProcess)]
param(
    [Parameter(Mandatory)] [string]$GroupId,
    [string]$Name = 'NTLM-SMB Hardening - Pilot'
)

# Default to preview: if the caller did not pass -WhatIf, turn it on.
if (-not $PSBoundParameters.ContainsKey('WhatIf')) { $WhatIfPreference = $true }

$ErrorActionPreference = 'Stop'
Connect-MgGraph -Scopes 'DeviceManagementConfiguration.ReadWrite.All' | Out-Null

$anchors = @('lmcompatibilitylevel','requiresecuritysignature','allowinsecureguestauth','restrictremoteclients','minimumsessionsecurity')

# The full intended control set (for the plan output). Registry anchors are the stable identity.
$plan = @(
    'LAN Manager authentication level = "Send NTLMv2 responses only. Refuse LM & NTLM" (LmCompatibilityLevel=5)',
    'NTLM SSP min session security - CLIENTS = Require NTLMv2 + 128-bit (NtlmMinClientSec=0x20080000)',
    'NTLM SSP min session security - SERVERS = Require NTLMv2 + 128-bit (NtlmMinServerSec=0x20080000)',
    'Microsoft network CLIENT: Digitally sign communications (always) = Enabled (RequireSecuritySignature=1)',
    'Microsoft network SERVER: Digitally sign communications (always) = Enabled (RequireSecuritySignature=1)',
    'Enable insecure guest logons = Disabled (AllowInsecureGuestAuth=0)',
    'Restrict Unauthenticated RPC clients = Authenticated (RestrictRemoteClients=1)'
)

# Does a Windows Settings Catalog policy carrying these controls already exist?
$existing = $null
try {
    $cfg = Invoke-MgGraphRequest -Method GET -Uri "https://graph.microsoft.com/beta/deviceManagement/configurationPolicies?`$filter=platforms eq 'windows10'"
    foreach ($p in @($cfg.value)) { if ($p.name -eq $Name) { $existing = $p; break } }
    if (-not $existing) {
        foreach ($p in @($cfg.value)) {
            $settings = Invoke-MgGraphRequest -Method GET -Uri "https://graph.microsoft.com/beta/deviceManagement/configurationPolicies/$($p.id)/settings"
            $json = ("$($settings | ConvertTo-Json -Depth 30)").ToLower()
            if (($anchors | Where-Object { $json -match [regex]::Escape($_) }).Count -ge 2) { $existing = $p; break }
        }
    }
} catch {}

Write-Host 'Intended NTLM/SMB hardening control set:' -ForegroundColor Cyan
$plan | ForEach-Object { Write-Host "  - $_" }
Write-Host ''

if ($existing) {
    Write-Host "NTLM/SMB hardening policy already present: '$($existing.name)' (id $($existing.id))." -ForegroundColor Green
    $policyId = $existing.id
} else {
    # Core, high-confidence Local Policies\Security Options controls as Settings Catalog choice settings.
    $lps = 'device_vendor_msft_policy_config_localpoliciessecurityoptions'
    $coreSettings = @(
        @{ '@odata.type'='#microsoft.graph.deviceManagementConfigurationSetting'; settingInstance=@{
            '@odata.type'='#microsoft.graph.deviceManagementConfigurationChoiceSettingInstance'
            settingDefinitionId="${lps}_networksecurity_lanmanagerauthenticationlevel"
            choiceSettingValue=@{ '@odata.type'='#microsoft.graph.deviceManagementConfigurationChoiceSettingValue'; value="${lps}_networksecurity_lanmanagerauthenticationlevel_5"; children=@() } } },
        @{ '@odata.type'='#microsoft.graph.deviceManagementConfigurationSetting'; settingInstance=@{
            '@odata.type'='#microsoft.graph.deviceManagementConfigurationChoiceSettingInstance'
            settingDefinitionId="${lps}_microsoftnetworkclient_digitallysigncommunicationsalways"
            choiceSettingValue=@{ '@odata.type'='#microsoft.graph.deviceManagementConfigurationChoiceSettingValue'; value="${lps}_microsoftnetworkclient_digitallysigncommunicationsalways_1"; children=@() } } },
        @{ '@odata.type'='#microsoft.graph.deviceManagementConfigurationSetting'; settingInstance=@{
            '@odata.type'='#microsoft.graph.deviceManagementConfigurationChoiceSettingInstance'
            settingDefinitionId="${lps}_microsoftnetworkserver_digitallysigncommunicationsalways"
            choiceSettingValue=@{ '@odata.type'='#microsoft.graph.deviceManagementConfigurationChoiceSettingValue'; value="${lps}_microsoftnetworkserver_digitallysigncommunicationsalways_1"; children=@() } } }
    )
    $policy = @{
        name         = $Name
        description  = 'NTLM/SMB legacy-auth hardening (core controls). Created by NTLMHARD-Remediation.ps1 — complete the remaining settings in the portal (Implementation Step 6).'
        platforms    = 'windows10'
        technologies = 'mdm'
        settings     = $coreSettings
    }
    if ($PSCmdlet.ShouldProcess($Name, 'Create Windows Settings Catalog NTLM/SMB hardening policy (core controls)')) {
        $created = Invoke-MgGraphRequest -Method POST -Uri 'https://graph.microsoft.com/beta/deviceManagement/configurationPolicies' -Body ($policy | ConvertTo-Json -Depth 20) -ContentType 'application/json'
        Write-Host "Created policy '$($created.name)' (id $($created.id)) with the core LAN Manager + SMB-signing controls." -ForegroundColor Green
        Write-Host "ACTION: add the remaining controls (NTLM SSP min session security client/server, insecure guest logons, restrict unauthenticated RPC) in the portal and verify each display string — Implementation Step 6." -ForegroundColor Yellow
        $policyId = $created.id
    } else {
        Write-Host "WhatIf: would create Windows Settings Catalog policy '$Name' with core controls (LAN Manager level=5; client+server SMB signing), then direct you to complete the remaining four controls in the portal." -ForegroundColor Yellow
    }
}

# Assign to the target group
if ($policyId -and $PSCmdlet.ShouldProcess("policy $policyId", "Assign to group $GroupId")) {
    $body = @{ assignments = @(@{ target = @{ '@odata.type'='#microsoft.graph.groupAssignmentTarget'; groupId=$GroupId } }) }
    Invoke-MgGraphRequest -Method POST -Uri "https://graph.microsoft.com/beta/deviceManagement/configurationPolicies/$policyId/assign" -Body ($body | ConvertTo-Json -Depth 6) -ContentType 'application/json' | Out-Null
    Write-Host "Assigned policy to group $GroupId." -ForegroundColor Green
} elseif (-not $policyId) {
    Write-Host "WhatIf: would then assign the new policy to group $GroupId." -ForegroundColor Yellow
}

Write-Host ''
if ($WhatIfPreference) { Write-Host 'Preview only (-WhatIf). Re-run with -WhatIf:$false to apply.' -ForegroundColor Yellow }
else { Write-Host 'Remediation complete. Finish the remaining settings in the portal, then re-run NTLMHARD-Discovery.ps1 to confirm READY.' -ForegroundColor Green }
