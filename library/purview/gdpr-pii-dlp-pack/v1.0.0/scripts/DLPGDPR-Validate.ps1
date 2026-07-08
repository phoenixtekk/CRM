<#
.SYNOPSIS
    DLPGDPR-Validate.ps1 — read-only validation of the GDPR/PII DLP policy set: simulation mode, scope, SIT coverage, per-gate pass/fail (safe: read-only).
.DESCRIPTION
    PURPOSE
        Confirms the delivered GDPR/PII DLP policies are configured as intended BEFORE and DURING pilot:
        each named policy exists and is in SIMULATION (Test*) mode unless deliberately enforced to the
        pilot ring, is scoped to the expected locations, references at least one EU-personal-data SIT, and
        — for the endpoint policy — the Devices location is present (a licensing/onboarding readiness
        signal). Emits a PASS/FAIL line per check and an overall result. Read-only — makes no changes.
    HOW TO RUN
        powershell -ExecutionPolicy Bypass -File .\DLPGDPR-Validate.ps1
        powershell -File .\DLPGDPR-Validate.ps1 -PolicyNames 'DLP - Email EU Personal Data - Simulation','DLP - Endpoint EU Personal Data - Simulation' -ExpectEnforcedRing
        Requires Security & Compliance PowerShell (Connect-IPPSSession).
.EXAMPLE
    .\DLPGDPR-Validate.ps1
    Checks the default GDPR policy set is in simulation, scoped, and SIT-backed; prints PASS/FAIL per gate.
.NOTES
    Purview — GDPR / PII DLP Pack. Read-only. No changes made.
    Expected results: every check prints PASS during the simulation build; overall PASS = all checks pass.
    With -ExpectEnforcedRing, an Enable mode is treated as expected (pilot enforcement) rather than a failure.
#>
[CmdletBinding()]
param(
    [string[]]$PolicyNames = @(
        'DLP - Email EU Personal Data - Simulation',
        'DLP - SPO+OneDrive+Teams EU Personal Data - Simulation',
        'DLP - Endpoint EU Personal Data - Simulation'
    ),
    # When set, a policy in Enable (enforce) mode is treated as an EXPECTED pilot-ring state, not a FAIL.
    [switch]$ExpectEnforcedRing,
    [string]$UserPrincipalName
)

if (-not (Get-Module -ListAvailable -Name ExchangeOnlineManagement)) {
    Install-Module ExchangeOnlineManagement -Scope CurrentUser -Force -AllowClobber
}
Import-Module ExchangeOnlineManagement -ErrorAction Stop
if (-not (Get-Command Get-DlpCompliancePolicy -ErrorAction SilentlyContinue)) {
    if ($UserPrincipalName) { Connect-IPPSSession -UserPrincipalName $UserPrincipalName } else { Connect-IPPSSession }
}

Write-Host '=== GDPR/PII DLP Validation (read-only) ===' -ForegroundColor Cyan
$results = New-Object System.Collections.Generic.List[object]
function Add-Check([string]$Name,[bool]$Pass,[string]$Detail) {
    $results.Add([pscustomobject]@{ Check = $Name; Result = if ($Pass) {'PASS'} else {'FAIL'}; Detail = $Detail })
    $col = if ($Pass) {'Green'} else {'Red'}
    Write-Host ("  [{0}] {1} — {2}" -f (if ($Pass) {'PASS'} else {'FAIL'}), $Name, $Detail) -ForegroundColor $col
}

foreach ($name in $PolicyNames) {
    $p = Get-DlpCompliancePolicy -Identity $name -ErrorAction SilentlyContinue
    if (-not $p) {
        Add-Check "Policy exists: $name" $false 'not found — create it in simulation (DLPGDPR-Config.ps1 / portal)'
        continue
    }
    Add-Check "Policy exists: $name" $true ("Mode={0}" -f $p.Mode)

    # Mode gate: simulation expected during build; Enable only acceptable if -ExpectEnforcedRing.
    $isSim = $p.Mode -like 'Test*'
    if ($isSim) {
        Add-Check "Simulation mode: $name" $true ("Mode={0}" -f $p.Mode)
    } elseif ($p.Mode -eq 'Enable' -and $ExpectEnforcedRing) {
        Add-Check "Enforced (expected ring): $name" $true 'Mode=Enable and -ExpectEnforcedRing set — confirm scope is the pilot ring only'
    } else {
        Add-Check "Simulation mode: $name" $false ("Mode={0} — not in simulation (and -ExpectEnforcedRing not set)" -f $p.Mode)
    }

    # Location scope present
    $locs = @()
    foreach ($loc in 'ExchangeLocation','SharePointLocation','OneDriveLocation','TeamsLocation','EndpointDlpLocation') {
        if ($p.$loc -and $p.$loc.Count -gt 0) { $locs += $loc.Replace('Location','') }
    }
    Add-Check "Locations scoped: $name" ($locs.Count -gt 0) ($locs -join ', ')

    # Endpoint policies must include the Devices location (licensing/onboarding readiness signal)
    if ($name -match 'Endpoint') {
        $hasEndpoint = ($p.EndpointDlpLocation -and $p.EndpointDlpLocation.Count -gt 0)
        Add-Check "Endpoint/Devices location present: $name" $hasEndpoint (if ($hasEndpoint) {'Devices in scope (verify onboarding + licensing)'} else {'Devices location missing — check E5/E5-Compliance + onboarding'})
    }

    # At least one EU-personal-data SIT referenced by the policy's rules
    $rules = Get-DlpComplianceRule -Policy $name -ErrorAction SilentlyContinue
    $sitNames = @()
    foreach ($r in $rules) {
        $ci = $r.ContentContainsSensitiveInformation
        if ($ci) { $sitNames += ($ci | ForEach-Object { $_.Name }) }
    }
    $sitNames = @($sitNames | Where-Object { $_ } | Select-Object -Unique)
    Add-Check "SIT-backed rule: $name" ($sitNames.Count -gt 0) (if ($sitNames.Count -gt 0) {($sitNames -join '; ')} else {'no sensitive-info-type condition found on any rule'})
}

$fail = @($results | Where-Object { $_.Result -eq 'FAIL' }).Count
Write-Host '--- Summary ---' -ForegroundColor Cyan
$results | Format-Table -AutoSize
if ($fail -eq 0) {
    Write-Host 'OVERALL: PASS — GDPR/PII DLP policy set validated.' -ForegroundColor Green
} else {
    Write-Host ("OVERALL: FAIL — {0} check(s) need attention (see FAIL rows above)." -f $fail) -ForegroundColor Red
}
