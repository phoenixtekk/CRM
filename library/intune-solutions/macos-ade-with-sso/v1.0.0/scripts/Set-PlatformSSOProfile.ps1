<#
.SYNOPSIS
    Set-PlatformSSOProfile.ps1 — create & assign the macOS Platform SSO (Microsoft Enterprise SSO) profile.

.DESCRIPTION
    PURPOSE
        Provisions the Extensible Single Sign-On (SSO app extension / Platform SSO) configuration
        profile for macOS with the correct Microsoft Enterprise SSO identifiers, login URLs, and
        the Secure Enclave authentication method — the same profile described in the Implementation
        Guide §6/Step 11 — then assigns it to a target Entra group.

    HOW TO RUN
        Install-Module Microsoft.Graph -Scope CurrentUser   # once
        # Preview only (no change):
        .\Set-PlatformSSOProfile.ps1 -GroupId <entra-group-object-id> -WhatIf
        # Create & assign:
        .\Set-PlatformSSOProfile.ps1 -GroupId <entra-group-object-id>
        # Choose a different method:
        .\Set-PlatformSSOProfile.ps1 -GroupId <id> -AuthMethod passwordSync

    EXPECTED RESULTS
        A new settings-catalog policy named "macOS Platform SSO – <method>" is created and assigned
        to the group. Verify it in Intune → Devices → Configuration.

.NOTES
    Phoenixtekk Workplace Marketplace — Intune Solutions. Creates a configuration policy; supports -WhatIf.
    Uses Microsoft Graph beta (settings catalog).
#>
[CmdletBinding(SupportsShouldProcess)]
param(
    [Parameter(Mandatory)] [string]$GroupId,
    [ValidateSet('secureEnclaveKey','passwordSync','userSecureEnclaveKey')]
    [string]$AuthMethod = 'secureEnclaveKey',
    [string]$Name = "macOS Platform SSO"
)

$ErrorActionPreference = 'Stop'
Connect-MgGraph -Scopes 'DeviceManagementConfiguration.ReadWrite.All' | Out-Null

$extensionId = 'com.microsoft.CompanyPortalMac.ssoextension'
$teamId      = 'UBF8T346G9'
$urls = @(
    'https://login.microsoftonline.com','https://login.microsoft.com','https://sts.windows.net',
    'https://login.partner.microsoftonline.cn','https://login.chinacloudapi.cn',
    'https://login.microsoftonline.us','https://login-us.microsoftonline.com'
)

# Settings-catalog body for the Extensible SSO (redirect) + Platform SSO block.
$policy = @{
    name        = "$Name – $AuthMethod"
    description = 'Microsoft Enterprise SSO / Platform SSO for macOS. Created by Phoenixtekk Set-PlatformSSOProfile.ps1.'
    platforms   = 'macOS'
    technologies = 'mdm'
    settings = @(
        @{
            '@odata.type' = '#microsoft.graph.deviceManagementConfigurationSetting'
            settingInstance = @{
                '@odata.type' = '#microsoft.graph.deviceManagementConfigurationChoiceSettingInstance'
                settingDefinitionId = 'com.apple.extensiblesso_com.apple.extensiblesso'
                choiceSettingValue = @{
                    value = 'com.apple.extensiblesso_redirect'
                    children = @(
                        @{ '@odata.type'='#microsoft.graph.deviceManagementConfigurationSimpleSettingInstance'; settingDefinitionId='com.apple.extensiblesso_extensionidentifier'; simpleSettingValue=@{ '@odata.type'='#microsoft.graph.deviceManagementConfigurationStringSettingValue'; value=$extensionId } },
                        @{ '@odata.type'='#microsoft.graph.deviceManagementConfigurationSimpleSettingInstance'; settingDefinitionId='com.apple.extensiblesso_teamidentifier'; simpleSettingValue=@{ '@odata.type'='#microsoft.graph.deviceManagementConfigurationStringSettingValue'; value=$teamId } },
                        @{ '@odata.type'='#microsoft.graph.deviceManagementConfigurationSimpleSettingCollectionInstance'; settingDefinitionId='com.apple.extensiblesso_urls'; simpleSettingCollectionValue=@($urls | ForEach-Object { @{ '@odata.type'='#microsoft.graph.deviceManagementConfigurationStringSettingValue'; value=$_ } }) },
                        @{ '@odata.type'='#microsoft.graph.deviceManagementConfigurationSimpleSettingInstance'; settingDefinitionId='com.apple.extensiblesso_platformsso_authenticationmethod'; simpleSettingValue=@{ '@odata.type'='#microsoft.graph.deviceManagementConfigurationStringSettingValue'; value=$AuthMethod } }
                    )
                }
            }
        }
    )
}

if (-not $PSCmdlet.ShouldProcess($policy.name, 'Create macOS Platform SSO settings-catalog policy')) {
    Write-Host 'WhatIf: would create the policy and assign it to group ' $GroupId -ForegroundColor Yellow
    return
}

$created = Invoke-MgGraphRequest -Method POST -Uri 'https://graph.microsoft.com/beta/deviceManagement/configurationPolicies' -Body ($policy | ConvertTo-Json -Depth 30) -ContentType 'application/json'
Write-Host "Created policy '$($created.name)' (id $($created.id))." -ForegroundColor Green

$assign = @{ assignments = @(@{ target = @{ '@odata.type'='#microsoft.graph.groupAssignmentTarget'; groupId=$GroupId } }) }
Invoke-MgGraphRequest -Method POST -Uri "https://graph.microsoft.com/beta/deviceManagement/configurationPolicies/$($created.id)/assign" -Body ($assign | ConvertTo-Json -Depth 6) -ContentType 'application/json' | Out-Null
Write-Host "Assigned to group $GroupId." -ForegroundColor Green
Write-Host 'Verify in Intune → Devices → Configuration, then pilot-enroll a Mac.' -ForegroundColor Green
