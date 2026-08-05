<#
.SYNOPSIS
    WINSECOPT-Discovery.ps1 — tenant readiness check for the Windows interactive-logon & network-access hardening pack.
.DESCRIPTION
    PURPOSE
        Confirms the Intune tenant carries a Windows Settings Catalog profile that hardens the four
        leftover interactive-logon and network-access Security Options this solution owns:
          1) Windows Connection Manager — prohibit connection to non-domain networks when connected to a
             domain-authenticated network (fBlockNonDomain = 1);
          2) Interactive logon: Smart card removal behavior = Lock Workstation (scremoveoption = 1);
          3) Disable "Sign-in and lock last interactive user automatically after a restart"
             (DisableAutomaticRestartSignOn = 1);
          4) Do not display network selection UI (DontDisplayNetworkSelectionUI = 1).
        Reports a PASS/FAIL per setting and an overall verdict. This checks THIS gap-only pack only —
        not NTLM/SMB, RDP, credential-theft, or full-baseline hardening.
    HOW TO RUN
        powershell -ExecutionPolicy Bypass -File .\WINSECOPT-Discovery.ps1
        Optional: -ProfileName "Interactive Logon & Network-Access Hardening - Pilot"
        (Install once: Install-Module Microsoft.Graph -Scope CurrentUser)
        Required Graph scopes: DeviceManagementConfiguration.Read.All
    EXPECTED RESULTS
        A PASS/FAIL line per target setting and an overall verdict. A READY tenant shows a Windows
        Settings Catalog profile carrying all four settings.
.NOTES
    White-label — the repeatable way. Read-only against Microsoft Graph.
    Settings Catalog display names and settingDefinitionId values can drift between service releases —
    verify the identifiers below in your tenant if a match is missed.
#>
[CmdletBinding()]
param(
    [string]$ProfileName = 'Interactive Logon & Network-Access Hardening - Pilot'
)

$ErrorActionPreference = 'Stop'
Connect-MgGraph -Scopes 'DeviceManagementConfiguration.Read.All' | Out-Null

# Substrings that identify each target setting inside the Settings Catalog settings JSON.
# (Match loosely so minor label/id drift still resolves — verify exact ids in your tenant.)
$targets = [ordered]@{
    'Prohibit connection to non-domain networks (fBlockNonDomain)'        = 'windowsconnectionmanager'
    'Smart card removal behavior = Lock Workstation (scremoveoption)'     = 'smartcardremovalbehavior'
    'Disable automatic restart sign-on (DisableAutomaticRestartSignOn)'   = 'disableautomaticrestartsignon'
    'Do not display network selection UI (DontDisplayNetworkSelectionUI)' = 'dontdisplaynetworkselectionui'
}

function R($Name, $Pass, $Detail) {
    [pscustomobject]@{ Check = $Name; Result = $(if ($Pass) { 'PASS' } else { 'FAIL' }); Detail = $Detail }
}
$results = New-Object System.Collections.Generic.List[object]

# Find a Windows Settings Catalog profile that carries these settings (prefer the named one).
$profile = $null; $settingsJson = ''
try {
    $cfg = Invoke-MgGraphRequest -Method GET -Uri "https://graph.microsoft.com/beta/deviceManagement/configurationPolicies?`$filter=platforms eq 'windows10'"
    $named = @($cfg.value | Where-Object { $_.name -eq $ProfileName })
    $candidates = if ($named.Count) { $named } else { @($cfg.value) }
    foreach ($pol in $candidates) {
        $settings = Invoke-MgGraphRequest -Method GET -Uri "https://graph.microsoft.com/beta/deviceManagement/configurationPolicies/$($pol.id)/settings"
        $json = ("$($settings | ConvertTo-Json -Depth 30)").ToLower()
        $hits = @($targets.Values | Where-Object { $json -match $_ }).Count
        if ($hits -gt 0 -and ($named.Count -or $hits -ge 2)) { $profile = $pol; $settingsJson = $json; break }
    }
} catch { $settingsJson = $_.Exception.Message.ToLower() }

$results.Add( (R 'Windows Settings Catalog hardening profile present' ($null -ne $profile) $(if ($profile) { "Profile: $($profile.name)" } else { "Not found: $ProfileName" })) )

foreach ($t in $targets.GetEnumerator()) {
    $present = ($null -ne $profile) -and ($settingsJson -match $t.Value)
    $results.Add( (R $t.Key $present $(if ($present) { "matched '$($t.Value)'" } else { 'setting not found in profile' })) )
}

$results | Format-Table -AutoSize
$fail = @($results | Where-Object Result -eq 'FAIL').Count
Write-Host ''
if ($fail -eq 0) { Write-Host 'OVERALL: READY — the four interactive-logon & network-access settings are present.' -ForegroundColor Green }
else { Write-Host "OVERALL: NOT READY — $fail check(s) failed. Resolve before piloting (Implementation Steps 4-8 or WINSECOPT-Remediation.ps1)." -ForegroundColor Yellow }
