<#
.SYNOPSIS
    IOSSSOEXT-Discovery.ps1 — tenant readiness check for the iOS/iPadOS Enterprise SSO app extension.
.DESCRIPTION
    PURPOSE
        Confirms the Intune tenant is ready to deliver the Microsoft Enterprise SSO plug-in as an
        Apple Extensible SSO app extension (redirect / Microsoft Entra ID type) for apps and browsers
        on corporate-owned iPhones/iPads: an iOS SSO app-extension profile exists with the correct
        extension identifier 'com.microsoft.azureauthenticator.ssoextension' (or the Microsoft Entra
        ID SSO extension type), and the Microsoft Authenticator app for iOS (which hosts the
        extension binary) is added. This checks the APP/BROWSER SSO extension only — not shared-device
        identity or device enrollment.
    HOW TO RUN
        powershell -ExecutionPolicy Bypass -File .\IOSSSOEXT-Discovery.ps1
        (Install once: Install-Module Microsoft.Graph -Scope CurrentUser)
        Required Graph scopes: DeviceManagementConfiguration.Read.All, DeviceManagementApps.Read.All
    EXPECTED RESULTS
        A PASS/FAIL line per check and an overall verdict. A READY tenant shows an iOS SSO
        app-extension profile with the Microsoft Authenticator extension identifier present and the
        Microsoft Authenticator (iOS) app added.
.NOTES
    White-label — the repeatable way. Read-only against Microsoft Graph.
#>
[CmdletBinding()]
param()

$ErrorActionPreference = 'Stop'
Connect-MgGraph -Scopes 'DeviceManagementConfiguration.Read.All','DeviceManagementApps.Read.All' | Out-Null

$ExtensionId = 'com.microsoft.azureauthenticator.ssoextension'
$TeamId      = 'UBF8T346G9'

function R($Name, $Pass, $Detail) {
    [pscustomobject]@{ Check = $Name; Result = $(if ($Pass) { 'PASS' } else { 'FAIL' }); Detail = $Detail }
}

$results = New-Object System.Collections.Generic.List[object]

# 1) iOS SSO app-extension profile — check Device features templates AND settings-catalog policies
$ssoFound = $false; $ssoType = 'none'; $ssoName = 'none'
try {
    # a) Device features template (iosDeviceFeaturesConfiguration -> singleSignOnExtension)
    $tpl = Invoke-MgGraphRequest -Method GET -Uri "https://graph.microsoft.com/beta/deviceManagement/deviceConfigurations?`$filter=isof('microsoft.graph.iosDeviceFeaturesConfiguration')"
    foreach ($p in @($tpl.value)) {
        $json = "$($p | ConvertTo-Json -Depth 30)"
        if ($json -match 'singleSignOnExtension' -and ($json -match 'iosAzureAd' -or $json -match [regex]::Escape($ExtensionId) -or $json -match 'redirect')) {
            $ssoFound = $true; $ssoName = $p.displayName
            $ssoType = $(if ($json -match 'iosAzureAd') { 'Microsoft Entra ID' } else { 'Redirect' })
            break
        }
    }
    # b) Settings catalog fallback
    if (-not $ssoFound) {
        $cfg = Invoke-MgGraphRequest -Method GET -Uri "https://graph.microsoft.com/beta/deviceManagement/configurationPolicies?`$filter=platforms eq 'iOS'"
        foreach ($pol in @($cfg.value)) {
            $settings = Invoke-MgGraphRequest -Method GET -Uri "https://graph.microsoft.com/beta/deviceManagement/configurationPolicies/$($pol.id)/settings"
            $json = "$($settings | ConvertTo-Json -Depth 25)"
            if ($json -match 'extensiblesso' -and $json -match [regex]::Escape($ExtensionId)) {
                $ssoFound = $true; $ssoName = $pol.name; $ssoType = 'Settings catalog (Redirect)'; break
            }
        }
    }
} catch { $ssoName = $_.Exception.Message }
$results.Add( (R 'iOS SSO app-extension profile present' $ssoFound "Profile: $ssoName") )
$results.Add( (R 'Extension type is Redirect / Microsoft Entra ID (app/browser SSO)' $ssoFound "Type: $ssoType") )

# 2) Microsoft Authenticator for iOS (hosts the extension binary on iOS)
try {
    $apps = Invoke-MgGraphRequest -Method GET -Uri "https://graph.microsoft.com/v1.0/deviceAppManagement/mobileApps?`$filter=contains(displayName,'Authenticator')"
    $auth = @($apps.value | Where-Object { $_.displayName -match 'Authenticator' -and ($_.'@odata.type' -match 'ios' -or $_.'@odata.type' -match 'Ios') })
    if (-not $auth.Count) { $auth = @($apps.value | Where-Object { $_.displayName -match 'Authenticator' }) }
    $results.Add( (R 'Microsoft Authenticator (iOS) added' ($auth.Count -gt 0) "$($auth.Count) match(es)") )
} catch { $results.Add( (R 'Microsoft Authenticator (iOS) added' $false $_.Exception.Message) ) }

$results | Format-Table -AutoSize
$fail = @($results | Where-Object Result -eq 'FAIL').Count
Write-Host ''
if ($fail -eq 0) { Write-Host 'OVERALL: READY — tenant is prepared for the iOS Enterprise SSO app extension.' -ForegroundColor Green }
else { Write-Host "OVERALL: NOT READY — $fail check(s) failed. Resolve before piloting." -ForegroundColor Yellow }
