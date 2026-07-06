<#
.SYNOPSIS
    MACSSOEXT-Discovery.ps1 — tenant readiness check for the macOS Enterprise SSO app extension.
.DESCRIPTION
    PURPOSE
        Confirms the Intune tenant is ready to deliver the Microsoft Enterprise SSO plug-in as an
        Apple Extensible SSO app extension (redirect type) for apps and browsers: a macOS SSO
        app-extension configuration profile exists with the correct extension identifier
        'com.microsoft.CompanyPortalMac.ssoextension', team identifier 'UBF8T346G9', and type
        Redirect, and the macOS Company Portal app (which hosts the extension) is added. This checks
        the APP/BROWSER SSO extension only — not Platform SSO device login.
    HOW TO RUN
        powershell -ExecutionPolicy Bypass -File .\MACSSOEXT-Discovery.ps1
        (Install once: Install-Module Microsoft.Graph -Scope CurrentUser)
        Required Graph scopes: DeviceManagementConfiguration.Read.All, DeviceManagementApps.Read.All
    EXPECTED RESULTS
        A PASS/FAIL line per check and an overall verdict. A READY tenant shows a Redirect-type SSO
        app-extension profile with the Microsoft identifiers present and Company Portal (macOS) added.
.NOTES
    White-label — the repeatable way. Read-only against Microsoft Graph.
#>
[CmdletBinding()]
param()

$ErrorActionPreference = 'Stop'
Connect-MgGraph -Scopes 'DeviceManagementConfiguration.Read.All','DeviceManagementApps.Read.All' | Out-Null

$ExtensionId = 'com.microsoft.CompanyPortalMac.ssoextension'
$TeamId      = 'UBF8T346G9'

function R($Name, $Pass, $Detail) {
    [pscustomobject]@{ Check = $Name; Result = $(if ($Pass) { 'PASS' } else { 'FAIL' }); Detail = $Detail }
}

$results = New-Object System.Collections.Generic.List[object]

# 1) macOS SSO app-extension (Redirect) configuration profile with Microsoft identifiers
$ssoFound = $false; $redirect = $false; $ids = $false; $ssoName = 'none'
try {
    $cfg = Invoke-MgGraphRequest -Method GET -Uri "https://graph.microsoft.com/beta/deviceManagement/configurationPolicies?`$filter=platforms eq 'macOS'"
    foreach ($pol in @($cfg.value)) {
        $settings = Invoke-MgGraphRequest -Method GET -Uri "https://graph.microsoft.com/beta/deviceManagement/configurationPolicies/$($pol.id)/settings"
        $json = "$($settings | ConvertTo-Json -Depth 25)"
        if ($json -match 'extensiblesso' -and $json -match [regex]::Escape($ExtensionId)) {
            $ssoFound = $true; $ssoName = $pol.name
            if ($json -match 'redirect') { $redirect = $true }
            if ($json -match [regex]::Escape($TeamId)) { $ids = $true }
            break
        }
    }
} catch { $ssoName = $_.Exception.Message }
$results.Add( (R 'SSO app-extension profile present' $ssoFound "Profile: $ssoName") )
$results.Add( (R 'Extension type is Redirect (app/browser SSO, not Platform SSO)' $redirect "Redirect type $([bool]$redirect)") )
$results.Add( (R 'Microsoft Enterprise SSO identifiers set (extension + team ID)' $ids "ExtensionId/$TeamId present $([bool]$ids)") )

# 2) Company Portal for macOS (hosts the extension binary)
try {
    $apps = Invoke-MgGraphRequest -Method GET -Uri "https://graph.microsoft.com/v1.0/deviceAppManagement/mobileApps?`$filter=contains(displayName,'Company Portal')"
    $cp = @($apps.value | Where-Object { $_.displayName -match 'Company Portal' })
    $results.Add( (R 'Company Portal (macOS) added' ($cp.Count -gt 0) "$($cp.Count) match(es)") )
} catch { $results.Add( (R 'Company Portal (macOS) added' $false $_.Exception.Message) ) }

$results | Format-Table -AutoSize
$fail = @($results | Where-Object Result -eq 'FAIL').Count
Write-Host ''
if ($fail -eq 0) { Write-Host 'OVERALL: READY — tenant is prepared for the macOS Enterprise SSO app extension.' -ForegroundColor Green }
else { Write-Host "OVERALL: NOT READY — $fail check(s) failed. Resolve before piloting." -ForegroundColor Yellow }
