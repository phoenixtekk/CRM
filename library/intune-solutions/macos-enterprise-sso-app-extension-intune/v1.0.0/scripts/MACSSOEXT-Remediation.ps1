<#
.SYNOPSIS
    MACSSOEXT-Remediation.ps1 — safely fix a missing or mis-scoped macOS SSO app-extension profile.
.DESCRIPTION
    PURPOSE
        Remediates the common gaps that leave the Microsoft Enterprise SSO app extension undeployed:
        creates the redirect-type SSO app-extension configuration profile if none exists (correct
        extension identifier, team identifier, Entra login URLs) and assigns it to a target group.
        Defaults to -WhatIf, so it previews every change and modifies nothing until re-run to apply.
        Remediates the app/browser SSO extension only — never Platform SSO device login.
    HOW TO RUN
        Preview (default, no changes):
          powershell -ExecutionPolicy Bypass -File .\MACSSOEXT-Remediation.ps1 -GroupId your-entra-group-object-id
        Apply the change:
          powershell -ExecutionPolicy Bypass -File .\MACSSOEXT-Remediation.ps1 -GroupId your-entra-group-object-id -WhatIf:$false
        (Install once: Install-Module Microsoft.Graph -Scope CurrentUser)
        Required Graph scopes: DeviceManagementConfiguration.ReadWrite.All
    EXPECTED RESULTS
        In preview: a report of what is missing and exactly what WOULD be created/assigned.
        When applied: a Redirect SSO app-extension profile exists and is assigned to the group.
        Re-run MACSSOEXT-Discovery.ps1 to confirm READY.
.NOTES
    White-label — the repeatable way. Defaults to -WhatIf; changes require -WhatIf:$false.
#>
[CmdletBinding(SupportsShouldProcess)]
param(
    [Parameter(Mandatory)] [string]$GroupId,
    [string]$Name = 'macOS SSO App Extension - Pilot',
    [string[]]$Urls = @(
        'https://login.microsoftonline.com','https://login.microsoft.com',
        'https://sts.windows.net','https://login.windows.net'
    ),
    [string]$AppPrefixAllowList = 'com.microsoft.,com.apple.'
)

# Default to preview: if the caller did not pass -WhatIf, turn it on.
if (-not $PSBoundParameters.ContainsKey('WhatIf')) { $WhatIfPreference = $true }

$ErrorActionPreference = 'Stop'
Connect-MgGraph -Scopes 'DeviceManagementConfiguration.ReadWrite.All' | Out-Null

$ExtensionId = 'com.microsoft.CompanyPortalMac.ssoextension'
$TeamId      = 'UBF8T346G9'

# Does a redirect SSO app-extension profile already exist?
$existing = $null
try {
    $cfg = Invoke-MgGraphRequest -Method GET -Uri "https://graph.microsoft.com/beta/deviceManagement/configurationPolicies?`$filter=platforms eq 'macOS'"
    foreach ($pol in @($cfg.value)) {
        $settings = Invoke-MgGraphRequest -Method GET -Uri "https://graph.microsoft.com/beta/deviceManagement/configurationPolicies/$($pol.id)/settings"
        if (("$($settings | ConvertTo-Json -Depth 25)") -match [regex]::Escape($ExtensionId)) { $existing = $pol; break }
    }
} catch {}

function New-Str($defId,$val){ @{ '@odata.type'='#microsoft.graph.deviceManagementConfigurationSimpleSettingInstance'; settingDefinitionId=$defId; simpleSettingValue=@{ '@odata.type'='#microsoft.graph.deviceManagementConfigurationStringSettingValue'; value=$val } } }

if ($existing) {
    Write-Host "SSO app-extension profile already present: '$($existing.name)' (id $($existing.id))." -ForegroundColor Green
    $policyId = $existing.id
} else {
    $children = @(
        (New-Str 'com.apple.extensiblesso_extensionidentifier' $ExtensionId),
        (New-Str 'com.apple.extensiblesso_teamidentifier' $TeamId),
        @{ '@odata.type'='#microsoft.graph.deviceManagementConfigurationSimpleSettingCollectionInstance'; settingDefinitionId='com.apple.extensiblesso_urls'; simpleSettingCollectionValue=@($Urls | ForEach-Object { @{ '@odata.type'='#microsoft.graph.deviceManagementConfigurationStringSettingValue'; value=$_ } }) },
        (New-Str 'com.apple.extensiblesso_appprefixallowlist' $AppPrefixAllowList)
    )
    $policy = @{
        name         = $Name
        description  = 'Microsoft Enterprise SSO app extension (redirect) for apps and browsers. Created by MACSSOEXT-Remediation.ps1.'
        platforms    = 'macOS'
        technologies = 'mdm'
        settings = @(
            @{
                '@odata.type' = '#microsoft.graph.deviceManagementConfigurationSetting'
                settingInstance = @{
                    '@odata.type' = '#microsoft.graph.deviceManagementConfigurationChoiceSettingInstance'
                    settingDefinitionId = 'com.apple.extensiblesso_com.apple.extensiblesso'
                    choiceSettingValue = @{ value = 'com.apple.extensiblesso_redirect'; children = $children }
                }
            }
        )
    }
    if ($PSCmdlet.ShouldProcess($Name, 'Create Redirect SSO app-extension profile')) {
        $created = Invoke-MgGraphRequest -Method POST -Uri 'https://graph.microsoft.com/beta/deviceManagement/configurationPolicies' -Body ($policy | ConvertTo-Json -Depth 30) -ContentType 'application/json'
        Write-Host "Created profile '$($created.name)' (id $($created.id))." -ForegroundColor Green
        $policyId = $created.id
    } else {
        Write-Host "WhatIf: would create Redirect SSO app-extension profile '$Name' with extension $ExtensionId / team $TeamId, URLs [$($Urls -join ', ')], AppPrefixAllowList '$AppPrefixAllowList'." -ForegroundColor Yellow
    }
}

# Assign to the target group
if ($policyId -and $PSCmdlet.ShouldProcess("policy $policyId", "Assign to group $GroupId")) {
    $body = @{ assignments = @(@{ target = @{ '@odata.type'='#microsoft.graph.groupAssignmentTarget'; groupId=$GroupId } }) }
    Invoke-MgGraphRequest -Method POST -Uri "https://graph.microsoft.com/beta/deviceManagement/configurationPolicies/$policyId/assign" -Body ($body | ConvertTo-Json -Depth 6) -ContentType 'application/json' | Out-Null
    Write-Host "Assigned profile to group $GroupId." -ForegroundColor Green
} elseif (-not $policyId) {
    Write-Host "WhatIf: would then assign the new profile to group $GroupId." -ForegroundColor Yellow
}

Write-Host ''
if ($WhatIfPreference) { Write-Host 'Preview only (-WhatIf). Re-run with -WhatIf:$false to apply.' -ForegroundColor Yellow }
else { Write-Host 'Remediation complete. Re-run MACSSOEXT-Discovery.ps1 to confirm READY.' -ForegroundColor Green }
