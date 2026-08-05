<#
.SYNOPSIS
    IOSSSOEXT-Remediation.ps1 — safely fix a missing or mis-scoped iOS SSO app-extension profile.
.DESCRIPTION
    PURPOSE
        Remediates the common gaps that leave the Microsoft Enterprise SSO app extension undeployed on
        corporate iPhones/iPads: creates the iOS Device-features SSO app-extension profile if none
        exists (Microsoft Entra ID extension type, Entra login URLs, and the managed-app SSO key) and
        assigns it to a target group. Defaults to -WhatIf, so it previews every change and modifies
        nothing until re-run to apply. Remediates the app/browser SSO extension only — never
        shared-device identity or enrollment.
    HOW TO RUN
        Preview (default, no changes):
          powershell -ExecutionPolicy Bypass -File .\IOSSSOEXT-Remediation.ps1 -GroupId your-entra-group-object-id
        Apply the change:
          powershell -ExecutionPolicy Bypass -File .\IOSSSOEXT-Remediation.ps1 -GroupId your-entra-group-object-id -WhatIf:$false
        (Install once: Install-Module Microsoft.Graph -Scope CurrentUser)
        Required Graph scopes: DeviceManagementConfiguration.ReadWrite.All
    EXPECTED RESULTS
        In preview: a report of what is missing and exactly what WOULD be created/assigned.
        When applied: an iOS SSO app-extension profile (Microsoft Entra ID type) exists and is
        assigned to the group. Re-run IOSSSOEXT-Discovery.ps1 to confirm READY.
.NOTES
    White-label — the repeatable way. Defaults to -WhatIf; changes require -WhatIf:$false.
#>
[CmdletBinding(SupportsShouldProcess)]
param(
    [Parameter(Mandatory)] [string]$GroupId,
    [string]$Name = 'iOS SSO App Extension - Pilot',
    [string[]]$Urls = @(
        'https://login.microsoftonline.com','https://login.microsoft.com',
        'https://sts.windows.net','https://login.windows.net'
    )
)

# Default to preview: if the caller did not pass -WhatIf, turn it on.
if (-not $PSBoundParameters.ContainsKey('WhatIf')) { $WhatIfPreference = $true }

$ErrorActionPreference = 'Stop'
Connect-MgGraph -Scopes 'DeviceManagementConfiguration.ReadWrite.All' | Out-Null

$ExtensionId = 'com.microsoft.azureauthenticator.ssoextension'

# Does an iOS SSO app-extension profile already exist?
$existing = $null
try {
    $tpl = Invoke-MgGraphRequest -Method GET -Uri "https://graph.microsoft.com/beta/deviceManagement/deviceConfigurations?`$filter=isof('microsoft.graph.iosDeviceFeaturesConfiguration')"
    foreach ($p in @($tpl.value)) { if (("$($p | ConvertTo-Json -Depth 30)") -match 'singleSignOnExtension') { $existing = $p; break } }
} catch {}

if ($existing) {
    Write-Host "iOS SSO app-extension profile already present: '$($existing.displayName)' (id $($existing.id))." -ForegroundColor Green
    $profileId = $existing.id
} else {
    # Build an iOS Device-features template with the Microsoft Entra ID (Azure AD) SSO extension.
    $profile = @{
        '@odata.type' = '#microsoft.graph.iosDeviceFeaturesConfiguration'
        displayName   = $Name
        description   = 'Microsoft Enterprise SSO app extension (Microsoft Entra ID) for apps and browsers on corporate iPhones. Created by IOSSSOEXT-Remediation.ps1.'
        singleSignOnExtension = @{
            '@odata.type'          = '#microsoft.graph.iosAzureAdSingleSignOnExtension'
            bundleIdAccessControlList = @()
            configurations = @(
                @{ '@odata.type'='#microsoft.graph.keyIntegerValuePair'; key='Enable_SSO_On_All_ManagedApps'; value=1 },
                @{ '@odata.type'='#microsoft.graph.keyIntegerValuePair'; key='browser_sso_interaction_enabled'; value=1 },
                @{ '@odata.type'='#microsoft.graph.keyIntegerValuePair'; key='disable_explicit_app_prompt'; value=1 }
            )
        }
    }
    if ($PSCmdlet.ShouldProcess($Name, 'Create iOS Microsoft Entra ID SSO app-extension profile')) {
        $created = Invoke-MgGraphRequest -Method POST -Uri 'https://graph.microsoft.com/beta/deviceManagement/deviceConfigurations' -Body ($profile | ConvertTo-Json -Depth 20) -ContentType 'application/json'
        Write-Host "Created profile '$($created.displayName)' (id $($created.id))." -ForegroundColor Green
        $profileId = $created.id
    } else {
        Write-Host "WhatIf: would create iOS Microsoft Entra ID SSO app-extension profile '$Name' (extension $ExtensionId), with Enable_SSO_On_All_ManagedApps=1, browser_sso_interaction_enabled=1, disable_explicit_app_prompt=1. URL interception is implied by the Microsoft Entra ID type; add explicit URLs [$($Urls -join ', ')] only if you switch to the Redirect type." -ForegroundColor Yellow
    }
}

# Assign to the target group
if ($profileId -and $PSCmdlet.ShouldProcess("profile $profileId", "Assign to group $GroupId")) {
    $body = @{ assignments = @(@{ target = @{ '@odata.type'='#microsoft.graph.groupAssignmentTarget'; groupId=$GroupId } }) }
    Invoke-MgGraphRequest -Method POST -Uri "https://graph.microsoft.com/beta/deviceManagement/deviceConfigurations/$profileId/assign" -Body ($body | ConvertTo-Json -Depth 6) -ContentType 'application/json' | Out-Null
    Write-Host "Assigned profile to group $GroupId." -ForegroundColor Green
} elseif (-not $profileId) {
    Write-Host "WhatIf: would then assign the new profile to group $GroupId." -ForegroundColor Yellow
}

Write-Host ''
if ($WhatIfPreference) { Write-Host 'Preview only (-WhatIf). Re-run with -WhatIf:$false to apply.' -ForegroundColor Yellow }
else { Write-Host 'Remediation complete. Re-run IOSSSOEXT-Discovery.ps1 to confirm READY.' -ForegroundColor Green }
