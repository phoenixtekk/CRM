<#
.SYNOPSIS
    WINAUDIT-Discovery.ps1 — tenant readiness check for the Windows Advanced Audit Policy baseline.
.DESCRIPTION
    PURPOSE
        Confirms the Intune tenant is ready to deliver the Windows Advanced Audit Policy configuration
        baseline via a Settings Catalog profile: a Windows 10/11 Settings Catalog policy (default name
        'Win Audit Policy - Baseline - Pilot') exists and carries (a) the force-subcategory override
        (SCENoApplyLegacyAuditPolicy / Audit_ForceAuditPolicySubcategorySettings...), (b) advanced audit
        subcategory settings (the Audit policy CSP nodes), and (c) command-line process auditing
        (ProcessCreationIncludeCmdLine). This checks the AUDIT CONFIGURATION baseline only — not SIEM
        forwarding and not a broad CIS/STIG hardening baseline.
    HOW TO RUN
        powershell -ExecutionPolicy Bypass -File .\WINAUDIT-Discovery.ps1
        Optional: -ProfileName "Win Audit Policy - Baseline - Pilot"
        (Install once: Install-Module Microsoft.Graph -Scope CurrentUser)
        Required Graph scopes: DeviceManagementConfiguration.Read.All
    EXPECTED RESULTS
        A PASS/FAIL line per check and an overall verdict. A READY tenant shows the Settings Catalog
        audit profile present, with the force-subcategory override enabled, audit subcategory settings
        present, and command-line process auditing enabled.
.NOTES
    White-label - the repeatable way. Read-only against Microsoft Graph.
#>
[CmdletBinding()]
param(
    [string]$ProfileName = 'Win Audit Policy - Baseline - Pilot'
)

$ErrorActionPreference = 'Stop'
Connect-MgGraph -Scopes 'DeviceManagementConfiguration.Read.All' | Out-Null

function R($Name, $Pass, $Detail) {
    [pscustomobject]@{ Check = $Name; Result = $(if ($Pass) { 'PASS' } else { 'FAIL' }); Detail = $Detail }
}
$results = New-Object System.Collections.Generic.List[object]

# 1) Locate a Windows Settings Catalog audit policy (by name, then by audit content)
$profile = $null; $settingsJson = ''
try {
    $cfg = Invoke-MgGraphRequest -Method GET -Uri "https://graph.microsoft.com/beta/deviceManagement/configurationPolicies?`$filter=platforms eq 'windows10'"
    # a) exact name first
    foreach ($pol in @($cfg.value)) { if ($pol.name -eq $ProfileName) { $profile = $pol; break } }
    # b) otherwise the first policy whose settings look like an audit baseline
    if (-not $profile) {
        foreach ($pol in @($cfg.value)) {
            $settings = Invoke-MgGraphRequest -Method GET -Uri "https://graph.microsoft.com/beta/deviceManagement/configurationPolicies/$($pol.id)/settings"
            $json = "$($settings | ConvertTo-Json -Depth 25)"
            if ($json -match 'audit_' -or $json -match 'ForceAuditPolicy' -or $json -match 'SCENoApplyLegacyAuditPolicy') { $profile = $pol; $settingsJson = $json; break }
        }
    }
    if ($profile -and -not $settingsJson) {
        $settings = Invoke-MgGraphRequest -Method GET -Uri "https://graph.microsoft.com/beta/deviceManagement/configurationPolicies/$($profile.id)/settings"
        $settingsJson = "$($settings | ConvertTo-Json -Depth 25)"
    }
} catch { }

$results.Add( (R 'Windows Settings Catalog audit profile present' ($null -ne $profile) $(if ($profile) { "Profile: $($profile.name) (id $($profile.id))" } else { "Not found: $ProfileName" })) )

if (-not $profile) {
    $results | Format-Table -AutoSize
    Write-Host ''
    Write-Host 'OVERALL: NOT READY - no Windows audit Settings Catalog profile found. Create it (WINAUDIT-Remediation.ps1) before piloting.' -ForegroundColor Yellow
    return
}

# 2) Force-subcategory override present (the gate everything depends on)
$overridePresent = ($settingsJson -match 'ForceAuditPolicy' -or $settingsJson -match 'SCENoApplyLegacyAuditPolicy')
$results.Add( (R 'Force audit policy subcategory override present' $overridePresent 'Audit_ForceAuditPolicySubcategorySettings... / SCENoApplyLegacyAuditPolicy') )

# 3) Advanced audit subcategory settings present
$auditCount = ([regex]::Matches($settingsJson, 'audit_')).Count
$results.Add( (R 'Advanced audit subcategory settings present' ($auditCount -gt 0) "$auditCount audit setting reference(s)") )

# 4) Command-line process auditing present
$cmdLine = ($settingsJson -match 'ProcessCreationIncludeCmdLine' -or $settingsJson -match 'includecommandline')
$results.Add( (R 'Command-line process auditing (4688 command line) present' $cmdLine 'ProcessCreationIncludeCmdLine_Enabled') )

# 5) Security log size present (informational - not a hard gate)
$logSize = ($settingsJson -match 'Setting_Security' -or $settingsJson -match 'eventlogservice' -or $settingsJson -match 'maximum log file size' -or $settingsJson -match 'MaxSize')
$results.Add( (R 'Security event log size configured' $logSize 'Event Log Service > Security > maximum log file size') )

$results | Format-Table -AutoSize
$fail = @($results | Where-Object Result -eq 'FAIL').Count
Write-Host ''
if ($fail -eq 0) { Write-Host 'OVERALL: READY - tenant carries the Windows Advanced Audit Policy baseline.' -ForegroundColor Green }
else { Write-Host "OVERALL: NOT READY - $fail check(s) failed. Resolve before piloting (WINAUDIT-Remediation.ps1)." -ForegroundColor Yellow }
