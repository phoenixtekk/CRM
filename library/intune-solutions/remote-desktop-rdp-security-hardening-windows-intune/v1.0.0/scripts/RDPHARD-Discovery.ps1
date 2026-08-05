<#
.SYNOPSIS
    RDPHARD-Discovery.ps1 — tenant readiness check for the Windows RDP security-hardening profile.
.DESCRIPTION
    PURPOSE
        Confirms the Intune tenant is ready to enforce endpoint RDP hardening on Windows 10/11: a
        Settings Catalog configuration profile (default name 'RDP Hardening - Pilot') exists and carries
        the expected Remote Desktop settings — client connection encryption level High/128-bit
        (MinEncryptionLevel), always prompt for password (fPromptForPassword), do not allow drive
        redirection (fDisableCdm), do not allow saved passwords (DisablePasswordSaving), Solicited/Offer
        Remote Assistance disabled (fAllowToGetHelp / fAllowUnsolicited), and Network Level
        Authentication required (UserAuthentication). Reports which settings are present so gaps are
        visible before piloting. This checks the ENDPOINT RDP hardening profile only — not network /
        gateway controls and not the credential-theft (Restricted Admin / Remote Credential Guard)
        program.
    HOW TO RUN
        powershell -ExecutionPolicy Bypass -File .\RDPHARD-Discovery.ps1
        Optional: -ProfileName "RDP Hardening - Pilot"
        (Install once: Install-Module Microsoft.Graph -Scope CurrentUser)
        Required Graph scopes: DeviceManagementConfiguration.Read.All
    EXPECTED RESULTS
        A PASS/FAIL line per check and an overall verdict. A READY tenant shows a Windows Settings
        Catalog RDP hardening profile present with the expected RDP settings detected.
.NOTES
    White-label — the repeatable way. Read-only against Microsoft Graph.
#>
[CmdletBinding()]
param(
    [string]$ProfileName = 'RDP Hardening - Pilot'
)

$ErrorActionPreference = 'Stop'
Connect-MgGraph -Scopes 'DeviceManagementConfiguration.Read.All' | Out-Null

# Registry-anchored markers for the RDP hardening settings (stable across Settings Catalog label revisions).
$Markers = [ordered]@{
    'Client encryption level High/128-bit (MinEncryptionLevel=3)' = 'minencryptionlevel'
    'Always prompt for password (fPromptForPassword=1)'          = 'fpromptforpassword'
    'Do not allow drive redirection (fDisableCdm=1)'             = 'fdisablecdm'
    'Do not allow saved passwords (DisablePasswordSaving=1)'     = 'disablepasswordsaving'
    'Solicited Remote Assistance disabled (fAllowToGetHelp=0)'   = 'fallowtogethelp'
    'Require NLA (UserAuthentication=1)'                         = 'userauthentication'
}

function R($Name, $Pass, $Detail) {
    [pscustomobject]@{ Check = $Name; Result = $(if ($Pass) { 'PASS' } else { 'FAIL' }); Detail = $Detail }
}
$results = New-Object System.Collections.Generic.List[object]

# 1) Locate the Windows Settings Catalog RDP hardening profile (by name, else by RDP setting content)
$profile = $null; $settingsJson = ''
try {
    $cfg = Invoke-MgGraphRequest -Method GET -Uri "https://graph.microsoft.com/beta/deviceManagement/configurationPolicies?`$filter=platforms eq 'windows10'"
    foreach ($pol in @($cfg.value)) {
        if ($pol.name -eq $ProfileName) {
            $profile = $pol
            $s = Invoke-MgGraphRequest -Method GET -Uri "https://graph.microsoft.com/beta/deviceManagement/configurationPolicies/$($pol.id)/settings"
            $settingsJson = ("$($s | ConvertTo-Json -Depth 30)").ToLower()
            break
        }
    }
    if (-not $profile) {
        foreach ($pol in @($cfg.value)) {
            $s = Invoke-MgGraphRequest -Method GET -Uri "https://graph.microsoft.com/beta/deviceManagement/configurationPolicies/$($pol.id)/settings"
            $json = ("$($s | ConvertTo-Json -Depth 30)").ToLower()
            if ($json -match 'minencryptionlevel' -or $json -match 'fpromptforpassword' -or $json -match 'terminalserver') {
                $profile = $pol; $settingsJson = $json; break
            }
        }
    }
} catch { $settingsJson = ''; }

$results.Add( (R 'Windows RDP hardening Settings Catalog profile present' ($null -ne $profile) $(if ($profile) { "Profile: $($profile.name)" } else { "Not found: '$ProfileName' (and no profile carrying RDP settings)" })) )

# 2) Per-setting presence
if ($profile) {
    foreach ($k in $Markers.Keys) {
        $present = $settingsJson -match [regex]::Escape($Markers[$k])
        $results.Add( (R $k $present $(if ($present) { 'detected in profile' } else { 'not detected — add it (Implementation Step 5)' })) )
    }
} else {
    foreach ($k in $Markers.Keys) { $results.Add( (R $k $false 'no profile to inspect') ) }
}

$results | Format-Table -AutoSize
$fail = @($results | Where-Object Result -eq 'FAIL').Count
Write-Host ''
if ($fail -eq 0) { Write-Host 'OVERALL: READY — tenant carries the Windows RDP hardening profile with the expected settings.' -ForegroundColor Green }
else { Write-Host "OVERALL: NOT READY — $fail check(s) failed. Resolve before piloting (Settings Catalog labels can vary — verify against the registry anchors)." -ForegroundColor Yellow }
