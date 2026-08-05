<#
.SYNOPSIS
    WINSECOPT-Remediation.ps1 — safely create the Windows interactive-logon & network-access hardening profile.
.DESCRIPTION
    PURPOSE
        Remediates the common gap that leaves these four Security Options unhardened: creates the
        Windows Settings Catalog profile if none exists — carrying
          1) Windows Connection Manager: prohibit non-domain networks when on a domain-authenticated
             network (fBlockNonDomain = 1);
          2) Interactive logon: Smart card removal behavior = Lock Workstation (scremoveoption = 1);
          3) Disable "Sign-in and lock last interactive user automatically after a restart"
             (DisableAutomaticRestartSignOn = 1);
          4) Do not display network selection UI (DontDisplayNetworkSelectionUI = 1)
        — and assigns it to a target group. Defaults to -WhatIf, so it previews every change and modifies
        nothing until re-run to apply. Remediates THIS gap-only pack only — never NTLM/SMB, RDP,
        credential-theft, or full-baseline hardening.
    HOW TO RUN
        Preview (default, no changes):
          powershell -ExecutionPolicy Bypass -File .\WINSECOPT-Remediation.ps1 -GroupId your-entra-group-object-id
        Apply the change:
          powershell -ExecutionPolicy Bypass -File .\WINSECOPT-Remediation.ps1 -GroupId your-entra-group-object-id -WhatIf:$false
        (Install once: Install-Module Microsoft.Graph -Scope CurrentUser)
        Required Graph scopes: DeviceManagementConfiguration.ReadWrite.All
    EXPECTED RESULTS
        In preview: a report of what is missing and exactly what WOULD be created/assigned.
        When applied: a Windows Settings Catalog profile carrying the four settings exists and is
        assigned to the group. Re-run WINSECOPT-Discovery.ps1 to confirm READY.
.NOTES
    White-label — the repeatable way. Defaults to -WhatIf; changes require -WhatIf:$false.
    IMPORTANT: the settingDefinitionId / choice option values below reflect current Microsoft
    documentation for the Windows Settings Catalog. Microsoft occasionally revises these ids — VERIFY
    them in your tenant (Devices > Configuration > Settings catalog) and update this script if a POST
    is rejected. When in doubt, build the profile by hand from Implementation Steps 4-8.
#>
[CmdletBinding(SupportsShouldProcess)]
param(
    [Parameter(Mandatory)] [string]$GroupId,
    [string]$Name = 'Interactive Logon & Network-Access Hardening - Pilot'
)

# Default to preview: if the caller did not pass -WhatIf, turn it on.
if (-not $PSBoundParameters.ContainsKey('WhatIf')) { $WhatIfPreference = $true }

$ErrorActionPreference = 'Stop'
Connect-MgGraph -Scopes 'DeviceManagementConfiguration.ReadWrite.All' | Out-Null

# --- Does a Windows Settings Catalog profile carrying these settings already exist? ---
$existing = $null
try {
    $cfg = Invoke-MgGraphRequest -Method GET -Uri "https://graph.microsoft.com/beta/deviceManagement/configurationPolicies?`$filter=platforms eq 'windows10'"
    foreach ($pol in @($cfg.value)) {
        if ($pol.name -eq $Name) { $existing = $pol; break }
        $settings = Invoke-MgGraphRequest -Method GET -Uri "https://graph.microsoft.com/beta/deviceManagement/configurationPolicies/$($pol.id)/settings"
        $json = ("$($settings | ConvertTo-Json -Depth 30)").ToLower()
        if ($json -match 'dontdisplaynetworkselectionui' -and $json -match 'smartcardremovalbehavior') { $existing = $pol; break }
    }
} catch {}

# --- The four Settings Catalog settings (verify ids in your tenant) ---
# choiceSettingValue.value = "<settingDefinitionId>_<optionValue>". "_1" = Enabled; smart-card removal "_1" = Lock Workstation.
function ChoiceSetting($defId, $optionSuffix) {
    @{
        '@odata.type'  = '#microsoft.graph.deviceManagementConfigurationSetting'
        settingInstance = @{
            '@odata.type'        = '#microsoft.graph.deviceManagementConfigurationChoiceSettingInstance'
            settingDefinitionId  = $defId
            choiceSettingValue   = @{
                '@odata.type' = '#microsoft.graph.deviceManagementConfigurationChoiceSettingValue'
                value         = "$($defId)_$($optionSuffix)"
                children      = @()
            }
        }
    }
}

$wcmId  = 'device_vendor_msft_policy_config_windowsconnectionmanager_prohibitconnectiontononbomainnetworkswhenconnectedtodomainauthenticatednetwork'
$scId   = 'device_vendor_msft_policy_config_localpoliciessecurityoptions_interactivelogon_smartcardremovalbehavior'
$arsoId = 'device_vendor_msft_policy_config_windowslogon_disableautomaticrestartsignon'
$netId  = 'device_vendor_msft_policy_config_windowslogon_dontdisplaynetworkselectionui'

$settings = @(
    (ChoiceSetting $wcmId  '1'),   # Enabled -> fBlockNonDomain = 1
    (ChoiceSetting $scId   '1'),   # Lock Workstation -> scremoveoption = 1
    (ChoiceSetting $arsoId '1'),   # Enabled (policy present) -> DisableAutomaticRestartSignOn = 1
    (ChoiceSetting $netId  '1')    # Enabled -> DontDisplayNetworkSelectionUI = 1
)

if ($existing) {
    Write-Host "Windows hardening profile already present: '$($existing.name)' (id $($existing.id))." -ForegroundColor Green
    $profileId = $existing.id
} else {
    $body = @{
        name         = $Name
        description  = 'Closes the leftover interactive-logon and network-access Security Options findings. Created by WINSECOPT-Remediation.ps1.'
        platforms    = 'windows10'
        technologies = 'mdm'
        settings     = $settings
    }
    if ($PSCmdlet.ShouldProcess($Name, 'Create Windows Settings Catalog hardening profile (4 settings)')) {
        $created = Invoke-MgGraphRequest -Method POST -Uri 'https://graph.microsoft.com/beta/deviceManagement/configurationPolicies' -Body ($body | ConvertTo-Json -Depth 20) -ContentType 'application/json'
        Write-Host "Created profile '$($created.name)' (id $($created.id))." -ForegroundColor Green
        $profileId = $created.id
    } else {
        Write-Host "WhatIf: would create Windows Settings Catalog profile '$Name' carrying:" -ForegroundColor Yellow
        Write-Host "  1) Prohibit connection to non-domain networks (fBlockNonDomain=1)" -ForegroundColor Yellow
        Write-Host "  2) Smart card removal behavior = Lock Workstation (scremoveoption=1)" -ForegroundColor Yellow
        Write-Host "  3) Disable automatic restart sign-on (DisableAutomaticRestartSignOn=1)" -ForegroundColor Yellow
        Write-Host "  4) Do not display network selection UI (DontDisplayNetworkSelectionUI=1)" -ForegroundColor Yellow
        Write-Host "  (Verify the settingDefinitionId values in this script against your tenant's catalog.)" -ForegroundColor Yellow
    }
}

# --- Assign to the target group ---
if ($profileId -and $PSCmdlet.ShouldProcess("profile $profileId", "Assign to group $GroupId")) {
    $asgBody = @{ assignments = @(@{ target = @{ '@odata.type'='#microsoft.graph.groupAssignmentTarget'; groupId=$GroupId } }) }
    Invoke-MgGraphRequest -Method POST -Uri "https://graph.microsoft.com/beta/deviceManagement/configurationPolicies/$profileId/assign" -Body ($asgBody | ConvertTo-Json -Depth 6) -ContentType 'application/json' | Out-Null
    Write-Host "Assigned profile to group $GroupId." -ForegroundColor Green
} elseif (-not $profileId) {
    Write-Host "WhatIf: would then assign the new profile to group $GroupId." -ForegroundColor Yellow
}

Write-Host ''
if ($WhatIfPreference) { Write-Host 'Preview only (-WhatIf). Re-run with -WhatIf:$false to apply.' -ForegroundColor Yellow }
else { Write-Host 'Remediation complete. Re-run WINSECOPT-Discovery.ps1 to confirm READY.' -ForegroundColor Green }
