<#
.SYNOPSIS
    DLPCMMC-Validate.ps1 — read-only validation-gate checker for the CUI DLP policies.
.DESCRIPTION
    PURPOSE
        Checks the CUI DLP policies against the solution's validation gates: that each named policy
        EXISTS, is in the EXPECTED mode (simulation during build/pilot vs enforce after expand), keys off
        the CUI SENSITIVITY LABEL and/or the CUI marking SIT in its rule, and is scoped (not left at
        "All" once a pilot ring/enclave is expected). Read-only — reports PASS/FAIL per gate, changes
        nothing. Use it after DLPCMMC-Config.ps1 and before/after moving to enforcement.
    HOW TO RUN
        # Validate the three simulation policies expect a Test* mode:
        powershell -File .\DLPCMMC-Validate.ps1 -PolicyNames 'DLP - CUI Email - Simulation','DLP - CUI SPO+OneDrive+Teams - Simulation','DLP - CUI Endpoint - Simulation' -ExpectMode Simulation
        # Validate the enforced pilot policy is scoped and enforcing:
        powershell -File .\DLPCMMC-Validate.ps1 -PolicyNames 'DLP - CUI All Locations - Enforce Pilot' -ExpectMode Enforce -ExpectScoped
        Requires Security & Compliance PowerShell (Connect-IPPSSession).
    EXPECTED RESULTS
        A per-policy PASS/FAIL table for: exists, mode matches -ExpectMode, references the CUI label or
        marking SIT, and (with -ExpectScoped) is not scoped to "All". Overall PASS only if every checked
        gate passes.
.NOTES
    Purview — CMMC / CUI DLP Pack. Read-only. Reports gate status only; makes no changes; no credentials in code.
#>
[CmdletBinding()]
param(
    [Parameter(Mandatory)][string[]]$PolicyNames,
    [ValidateSet('Simulation','Enforce','Any')][string]$ExpectMode = 'Simulation',
    [string]$SensitivityLabel = 'CUI',
    [string]$MarkingSit = 'CUI Banner Marking - Custom SIT - Classification',
    [switch]$ExpectScoped,
    [string]$UserPrincipalName
)

if (-not (Get-Module -ListAvailable -Name ExchangeOnlineManagement)) {
    Install-Module ExchangeOnlineManagement -Scope CurrentUser -Force -AllowClobber
}
Import-Module ExchangeOnlineManagement -ErrorAction Stop
if (-not (Get-Command Get-DlpCompliancePolicy -ErrorAction SilentlyContinue)) {
    if ($UserPrincipalName) { Connect-IPPSSession -UserPrincipalName $UserPrincipalName } else { Connect-IPPSSession }
}

Write-Host '=== CUI DLP Validation Gates (read-only) ===' -ForegroundColor Cyan
Write-Host ("Expected mode: {0}   Expect scoped (not 'All'): {1}" -f $ExpectMode, [bool]$ExpectScoped)

$results = foreach ($name in $PolicyNames) {
    $p = Get-DlpCompliancePolicy -Identity $name -ErrorAction SilentlyContinue
    $exists = [bool]$p

    $modeOk = $false
    $modeVal = if ($p) { $p.Mode } else { 'n/a' }
    if ($p) {
        switch ($ExpectMode) {
            'Simulation' { $modeOk = ($p.Mode -like 'Test*') }
            'Enforce'    { $modeOk = ($p.Mode -eq 'Enable') }
            'Any'        { $modeOk = $true }
        }
    }

    # Check the rule(s) reference the CUI label or the marking SIT.
    $signalOk = $false
    if ($p) {
        $rules = Get-DlpComplianceRule -Policy $name -ErrorAction SilentlyContinue
        foreach ($r in $rules) {
            $blob = ($r | Out-String)
            if ($blob -match [regex]::Escape($SensitivityLabel) -or $blob -match [regex]::Escape($MarkingSit) -or $blob -match 'CUI') {
                $signalOk = $true; break
            }
        }
    }

    # Scope check: if a ring/enclave is expected, the location should not be the literal 'All'.
    $scopeOk = $true
    if ($p -and $ExpectScoped) {
        $scopeOk = $false
        foreach ($loc in 'ExchangeLocation','SharePointLocation','OneDriveLocation','TeamsLocation','EndpointDlpLocation') {
            $val = $p.$loc
            if ($val -and ($val -notcontains 'All')) { $scopeOk = $true; break }
        }
    }

    $overall = $exists -and $modeOk -and $signalOk -and $scopeOk
    [pscustomobject]@{
        Policy      = $name
        Exists      = $exists
        Mode        = $modeVal
        ModeOk      = $modeOk
        CUISignalOk = $signalOk
        ScopeOk     = $scopeOk
        Result      = if ($overall) { 'PASS' } else { 'FAIL' }
    }
}

$results | Format-Table -AutoSize

$fail = @($results | Where-Object { $_.Result -eq 'FAIL' })
if ($fail.Count -eq 0) {
    Write-Host 'OVERALL: PASS — every checked gate passed.' -ForegroundColor Green
} else {
    Write-Host ("OVERALL: FAIL — {0} policy(ies) did not meet the gate. Review the FAIL rows above." -f $fail.Count) -ForegroundColor Yellow
    Write-Host 'Note: these gates validate the technical control only. NIST SP 800-171 / CMMC satisfaction remains a compliance/C3PAO determination.' -ForegroundColor Gray
}
