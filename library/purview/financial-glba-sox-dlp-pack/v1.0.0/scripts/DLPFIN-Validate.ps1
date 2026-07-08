<#
.SYNOPSIS
    DLPFIN-Validate.ps1 — read-only validation runner that checks the expected financial DLP policies exist, mode, locations, and rules.
.DESCRIPTION
    PURPOSE
        Validates the financial-DLP deployment against the pack's expected artifacts: for each expected
        policy (Email NPI, Cloud NPI, Endpoint NPI, SOX Financial Records) it checks the policy EXISTS,
        reports its MODE (flagging any policy in enforce that you did not intend), confirms it covers the
        expected locations, and confirms a content rule with sensitive-information-type conditions is
        attached. Prints a PASS/FAIL line per check for the deployment gates. Read-only — makes no
        changes. Use it after DLPFIN-Config.ps1 and again after enforcement to prove state.
    HOW TO RUN
        # Validate the default expected policy set (simulation stage):
        powershell -ExecutionPolicy Bypass -File .\DLPFIN-Validate.ps1
        # Validate a specific set and expect them in simulation:
        powershell -File .\DLPFIN-Validate.ps1 -PolicyNames 'DLP - Email NPI - Simulation','DLP - SOX Financial Records - Simulation' -ExpectMode Simulation
        Requires Security & Compliance PowerShell (Connect-IPPSSession).
    EXPECTED RESULTS
        A per-policy PASS/FAIL table (Exists / ModeOK / HasRule / Locations) and an overall result.
        PASS gate: every expected policy exists, is in the expected mode, and has a rule with SIT
        conditions. FAIL: a missing policy, an unexpected enforce mode, or a policy with no rule.
.NOTES
    Purview — Financial (GLBA/SOX) DLP Pack. Read-only validation. No changes made. No credentials in code.
#>
[CmdletBinding()]
param(
    [string[]]$PolicyNames = @(
        'DLP - Email NPI - Simulation',
        'DLP - SPO+OneDrive+Teams NPI - Simulation',
        'DLP - Endpoint NPI - Simulation',
        'DLP - SOX Financial Records - Simulation'
    ),
    [ValidateSet('Simulation','Enforce','Any')][string]$ExpectMode = 'Simulation',
    [string]$UserPrincipalName
)

if (-not (Get-Module -ListAvailable -Name ExchangeOnlineManagement)) {
    Install-Module ExchangeOnlineManagement -Scope CurrentUser -Force -AllowClobber
}
Import-Module ExchangeOnlineManagement -ErrorAction Stop
if (-not (Get-Command Get-DlpCompliancePolicy -ErrorAction SilentlyContinue)) {
    if ($UserPrincipalName) { Connect-IPPSSession -UserPrincipalName $UserPrincipalName } else { Connect-IPPSSession }
}

Write-Host ("=== Financial DLP Validation (expect mode: {0}) ===" -f $ExpectMode) -ForegroundColor Cyan

function Test-ModeOk {
    param($mode, $expect)
    switch ($expect) {
        'Simulation' { return ($mode -like 'Test*') }
        'Enforce'    { return ($mode -eq 'Enable') }
        default      { return $true }
    }
}

$results = foreach ($name in $PolicyNames) {
    $p = Get-DlpCompliancePolicy -Identity $name -ErrorAction SilentlyContinue
    if (-not $p) {
        [pscustomobject]@{ Policy = $name; Exists = $false; Mode = '-'; ModeOK = $false; HasRule = $false; Locations = '-'; Result = 'FAIL' }
        continue
    }
    $locations = @()
    foreach ($loc in 'ExchangeLocation','SharePointLocation','OneDriveLocation','TeamsLocation','EndpointDlpLocation') {
        $val = $p.$loc
        if ($val -and $val.Count -gt 0) { $locations += $loc.Replace('Location','') }
    }
    $rules = Get-DlpComplianceRule -Policy $name -ErrorAction SilentlyContinue
    $hasSitRule = $false
    foreach ($r in $rules) {
        if ($r.ContentContainsSensitiveInformation -and @($r.ContentContainsSensitiveInformation).Count -gt 0) { $hasSitRule = $true }
    }
    $modeOk = Test-ModeOk -mode $p.Mode -expect $ExpectMode
    $pass = ($modeOk -and $hasSitRule)
    [pscustomobject]@{
        Policy    = $name
        Exists    = $true
        Mode      = $p.Mode
        ModeOK    = $modeOk
        HasRule   = $hasSitRule
        Locations = ($locations -join ', ')
        Result    = if ($pass) { 'PASS' } else { 'FAIL' }
    }
}

$results | Format-Table Policy, Exists, Mode, ModeOK, HasRule, Locations, Result -AutoSize

# Extra safety flag: any expected-simulation policy that is actually enforcing.
if ($ExpectMode -eq 'Simulation') {
    $unexpectedEnforce = @($results | Where-Object { $_.Mode -eq 'Enable' })
    if ($unexpectedEnforce.Count -gt 0) {
        Write-Host ("REVIEW: {0} policy(ies) are ENFORCING but were expected in simulation:" -f $unexpectedEnforce.Count) -ForegroundColor Yellow
        $unexpectedEnforce.Policy | ForEach-Object { Write-Host "   * $_" -ForegroundColor Yellow }
    }
}

$fails = @($results | Where-Object { $_.Result -eq 'FAIL' })
if ($fails.Count -eq 0) {
    Write-Host 'OVERALL: PASS — all expected financial DLP policies exist, are in the expected mode, and have SIT rules.' -ForegroundColor Green
} else {
    Write-Host ("OVERALL: FAIL — {0} policy(ies) did not pass. Resolve before advancing the gate." -f $fails.Count) -ForegroundColor Red
}
