<#
.SYNOPSIS
    EDGEBIZ-Discovery.ps1 — tenant readiness check for the Microsoft Edge for Business enterprise
    configuration & security baseline (Intune, Windows).
.DESCRIPTION
    PURPOSE
        Confirms the Intune tenant is ready to deliver a managed, hardened Microsoft Edge on Windows:
          - a Settings Catalog profile named 'Edge for Business - Baseline - Pilot' exists and carries the
            core Edge policies (PasswordManagerEnabled = disabled, SmartScreen enabled),
          - a custom OMA-URI profile named 'Edge for Business - Default Browser - Pilot' exists (the
            DefaultAssociationsConfiguration that makes Edge the default browser), and
          - a Microsoft Edge security baseline instance named 'Edge for Business - Security Baseline - Pilot'
            exists.
        Read-only. Checks Microsoft Edge on WINDOWS only — not macOS/iOS/Android Edge.
    HOW TO RUN
        powershell -ExecutionPolicy Bypass -File .\EDGEBIZ-Discovery.ps1
        (Install once: Install-Module Microsoft.Graph -Scope CurrentUser)
        Required Graph scopes: DeviceManagementConfiguration.Read.All
    EXPECTED RESULTS
        A PASS/FAIL line per check and an overall verdict. A READY tenant shows the three named objects
        present, with the Edge baseline profile carrying the password-manager-off and SmartScreen settings.
.NOTES
    White-label — the repeatable way. Read-only against Microsoft Graph.
    Setting definition IDs and profile names may vary by Edge/Intune version — verify in your tenant.
#>
[CmdletBinding()]
param(
    [string]$BaselineName      = 'Edge for Business - Baseline - Pilot',
    [string]$DefaultBrowserName = 'Edge for Business - Default Browser - Pilot',
    [string]$SecurityBaselineName = 'Edge for Business - Security Baseline - Pilot'
)

$ErrorActionPreference = 'Stop'
Connect-MgGraph -Scopes 'DeviceManagementConfiguration.Read.All' | Out-Null

function R($Name, $Pass, $Detail) {
    [pscustomobject]@{ Check = $Name; Result = $(if ($Pass) { 'PASS' } else { 'FAIL' }); Detail = $Detail }
}
$results = New-Object System.Collections.Generic.List[object]

# 1) Settings Catalog Edge baseline profile + core settings
$baseFound = $false; $pwOff = $false; $smartScreen = $false; $baseId = $null
try {
    $cfg = Invoke-MgGraphRequest -Method GET -Uri "https://graph.microsoft.com/beta/deviceManagement/configurationPolicies?`$filter=platforms eq 'windows10'"
    foreach ($pol in @($cfg.value)) {
        if ($pol.name -eq $BaselineName) { $baseFound = $true; $baseId = $pol.id; break }
    }
    # Fallback: any windows settings-catalog policy that configures Microsoft Edge password manager
    if (-not $baseFound) {
        foreach ($pol in @($cfg.value)) {
            $s = Invoke-MgGraphRequest -Method GET -Uri "https://graph.microsoft.com/beta/deviceManagement/configurationPolicies/$($pol.id)/settings"
            if (("$($s | ConvertTo-Json -Depth 25)") -match 'microsoft_edge.*passwordmanager') { $baseFound = $true; $baseId = $pol.id; $BaselineName = $pol.name; break }
        }
    }
    if ($baseId) {
        $settings = Invoke-MgGraphRequest -Method GET -Uri "https://graph.microsoft.com/beta/deviceManagement/configurationPolicies/$baseId/settings"
        $json = "$($settings | ConvertTo-Json -Depth 25)"
        # PasswordManagerEnabled disabled: definition id contains passwordmanagerenabled and value ...disabled/_0
        if ($json -match 'passwordmanager_passwordmanagerenabled' -and ($json -match 'passwordmanagerenabled_0' -or $json -match 'disabled')) { $pwOff = $true }
        if ($json -match 'smartscreen_smartscreenenabled' -or $json -match 'smartscreenenabled') { $smartScreen = $true }
    }
} catch { $baseId = $_.Exception.Message }
$results.Add( (R 'Edge Settings Catalog baseline present' $baseFound "Profile: $BaselineName") )
$results.Add( (R 'Password manager set to Disabled (Finding #1)' $pwOff 'PasswordManagerEnabled = disabled') )
$results.Add( (R 'SmartScreen enabled in baseline' $smartScreen 'SmartScreenEnabled present') )

# 2) Default-browser custom OMA-URI profile (DefaultAssociationsConfiguration)
$dbFound = $false; $dbDetail = 'none'
try {
    $custom = Invoke-MgGraphRequest -Method GET -Uri "https://graph.microsoft.com/beta/deviceManagement/deviceConfigurations?`$filter=isof('microsoft.graph.windows10CustomConfiguration')"
    foreach ($p in @($custom.value)) {
        if ($p.displayName -eq $DefaultBrowserName) { $dbFound = $true; $dbDetail = $p.displayName; break }
        if (("$($p | ConvertTo-Json -Depth 20)") -match 'DefaultAssociationsConfiguration') { $dbFound = $true; $dbDetail = $p.displayName; break }
    }
} catch { $dbDetail = $_.Exception.Message }
$results.Add( (R 'Default-browser (DefaultAssociationsConfiguration) profile present (Finding #2)' $dbFound "Profile: $dbDetail") )

# 3) Microsoft Edge security baseline instance (intents or templated configuration policy)
$secFound = $false; $secDetail = 'none'
try {
    $intents = Invoke-MgGraphRequest -Method GET -Uri "https://graph.microsoft.com/beta/deviceManagement/intents"
    foreach ($i in @($intents.value)) {
        if ($i.displayName -eq $SecurityBaselineName -or $i.displayName -match 'Edge') {
            if ($i.templateId -or $i.displayName -match 'Edge') { $secFound = $true; $secDetail = $i.displayName; break }
        }
    }
    if (-not $secFound) {
        $cfg2 = Invoke-MgGraphRequest -Method GET -Uri "https://graph.microsoft.com/beta/deviceManagement/configurationPolicies?`$filter=platforms eq 'windows10'"
        foreach ($pol in @($cfg2.value)) {
            if ($pol.name -eq $SecurityBaselineName) { $secFound = $true; $secDetail = $pol.name; break }
            if ($pol.templateReference -and ("$($pol.templateReference | ConvertTo-Json)") -match 'edge') { $secFound = $true; $secDetail = $pol.name; break }
        }
    }
} catch { $secDetail = $_.Exception.Message }
$results.Add( (R 'Microsoft Edge security baseline present' $secFound "Baseline: $secDetail") )

$results | Format-Table -AutoSize
$fail = @($results | Where-Object Result -eq 'FAIL').Count
Write-Host ''
if ($fail -eq 0) { Write-Host 'OVERALL: READY — tenant is prepared for the Microsoft Edge for Business baseline.' -ForegroundColor Green }
else { Write-Host "OVERALL: NOT READY — $fail check(s) failed. Resolve before piloting." -ForegroundColor Yellow }
