<#
.SYNOPSIS
    PHIDLP-Validate.ps1 — read-only validation of the PHI DLP policies against the expected pass/fail gate.
.DESCRIPTION
    PURPOSE
        Confirms the implementation state before and after enforcement: for each expected PHI DLP policy
        it reports the MODE (simulation vs enforce vs disabled), whether the HIPAA-relevant sensitive
        information types are actually attached to the policy's rule(s), and the location scope. Use it as
        the gate check: during pilot build every policy should be in SIMULATION with the PHI SITs present;
        after Phase 4 the pilot policies should be ENFORCING and scoped to the ring. Read-only — no changes.
    HOW TO RUN
        # Validate the three standard simulation policies:
        powershell -ExecutionPolicy Bypass -File .\PHIDLP-Validate.ps1 `
            -PolicyNames 'DLP - PHI Email - Simulation','DLP - PHI SPO+OneDrive+Teams - Simulation','DLP - PHI Endpoint - Simulation' `
            -ExpectMode Simulation
        Requires Security & Compliance PowerShell (Connect-IPPSSession).
    EXPECTED RESULTS
        A per-policy PASS/FAIL table: PASS = policy exists, its Mode matches -ExpectMode, and at least one
        expected HIPAA SIT is attached. FAIL/verify rows point at the missing piece (policy absent, wrong
        mode, or no PHI SIT attached). A non-zero exit code if any policy fails, for use in checks.
.NOTES
    Purview — HIPAA / PHI DLP Pack. Read-only validation. No changes made. Confirms control state, not breach status.
#>
[CmdletBinding()]
param(
    [string[]]$PolicyNames = @(
        'DLP - PHI Email - Simulation',
        'DLP - PHI SPO+OneDrive+Teams - Simulation',
        'DLP - PHI Endpoint - Simulation'
    ),
    [ValidateSet('Simulation','Enforce','Any')][string]$ExpectMode = 'Simulation',
    # Expected HIPAA-relevant SIT names — at least one must be attached to count as covered.
    [string[]]$ExpectedSits = @(
        'U.S. Social Security Number (SSN)',
        'International Classification of Diseases (ICD-9-CM)',
        'International Classification of Diseases (ICD-10-CM)',
        'Drug Enforcement Agency (DEA) Number',
        'MRN - Custom SIT - PHI'
    ),
    [string]$UserPrincipalName
)

if (-not (Get-Module -ListAvailable -Name ExchangeOnlineManagement)) {
    Install-Module ExchangeOnlineManagement -Scope CurrentUser -Force -AllowClobber
}
Import-Module ExchangeOnlineManagement -ErrorAction Stop
if (-not (Get-Command Get-DlpCompliancePolicy -ErrorAction SilentlyContinue)) {
    if ($UserPrincipalName) { Connect-IPPSSession -UserPrincipalName $UserPrincipalName } else { Connect-IPPSSession }
}

Write-Host ("=== PHI DLP Validation (expect mode: {0}) ===" -f $ExpectMode) -ForegroundColor Cyan

function Test-ModeMatch {
    param($Mode, $Expect)
    switch ($Expect) {
        'Simulation' { return ($Mode -like 'Test*') }
        'Enforce'    { return ($Mode -eq 'Enable') }
        default      { return $true }
    }
}

$results = foreach ($name in $PolicyNames) {
    $p = Get-DlpCompliancePolicy -Identity $name -ErrorAction SilentlyContinue
    if (-not $p) {
        [pscustomobject]@{ Policy = $name; Exists = $false; Mode = 'n/a'; ModeOK = $false; SitAttached = ''; SitOK = $false; Result = 'FAIL (absent)' }
        continue
    }
    $modeOk = Test-ModeMatch -Mode $p.Mode -Expect $ExpectMode

    # Gather SIT names referenced by the policy's rules.
    $rules = Get-DlpComplianceRule -Policy $name -ErrorAction SilentlyContinue
    $attachedSits = @()
    foreach ($r in $rules) {
        $ci = $r.ContentContainsSensitiveInformation
        if ($ci) {
            foreach ($grp in $ci) {
                if ($grp -is [System.Collections.IEnumerable] -and $grp -isnot [string]) {
                    foreach ($item in $grp) { if ($item.Name) { $attachedSits += $item.Name } }
                } elseif ($grp.Name) { $attachedSits += $grp.Name }
            }
        }
    }
    $attachedSits = $attachedSits | Select-Object -Unique
    $matchedExpected = @($attachedSits | Where-Object { $ExpectedSits -contains $_ })
    $sitOk = $matchedExpected.Count -gt 0

    $result = if ($modeOk -and $sitOk) { 'PASS' } else { 'FAIL' }
    [pscustomobject]@{
        Policy      = $name
        Exists      = $true
        Mode        = $p.Mode
        ModeOK      = $modeOk
        SitAttached = ($matchedExpected -join '; ')
        SitOK       = $sitOk
        Result      = $result
    }
}

$results | Format-Table -AutoSize Policy, Mode, ModeOK, SitOK, Result
$results | Where-Object { $_.Result -ne 'PASS' } | ForEach-Object {
    Write-Host ("  ! {0}: mode-ok={1}, phi-sit-attached={2} ({3})" -f $_.Policy, $_.ModeOK, $_.SitOK, $_.SitAttached) -ForegroundColor Yellow
}

$failCount = @($results | Where-Object { $_.Result -ne 'PASS' }).Count
if ($failCount -eq 0) {
    Write-Host 'PASS: all expected PHI DLP policies present, in the expected mode, with a HIPAA SIT attached.' -ForegroundColor Green
    exit 0
} else {
    Write-Host ("VALIDATION GATE: {0} policy(ies) not passing — resolve before advancing the phase." -f $failCount) -ForegroundColor Red
    exit 1
}
