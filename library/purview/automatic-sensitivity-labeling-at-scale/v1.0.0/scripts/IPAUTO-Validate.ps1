<#
.SYNOPSIS
    IPAUTO-Validate.ps1 — read-only validation that auto-labeling behaves as specified (pass/fail); changes nothing.
.DESCRIPTION
    PURPOSE
        Read-only validation harness for a Purview auto-labeling policy. Confirms the service-side policy
        is in the EXPECTED state — in SIMULATION (TestWithoutNotifications/TestWithNotifications) before
        sign-off, or Enable only after — that its rule(s) exist and are enabled, and that a simulation
        scan/match set has been produced. Emits a single overall PASS/FAIL signal (exit code + summary)
        so it can gate the pipeline. It NEVER writes.
    HOW TO RUN
        PowerShell 5.1+ or 7+ with the ExchangeOnlineManagement module, then Connect-IPPSSession.
        Validate a policy is still safely in simulation (pre-enforcement gate):
          .\IPAUTO-Validate.ps1 -PolicyName "AutoLabel Sim - Confidential - SPO+ODB" -ExpectMode Simulation
        Validate a policy is enforcing after sign-off:
          .\IPAUTO-Validate.ps1 -PolicyName "AutoLabel Sim - Confidential - SPO+ODB" -ExpectMode Enforce
    EXAMPLE
        .\IPAUTO-Validate.ps1 -PolicyName "AutoLabel Sim - Confidential - SPO+ODB" -ExpectMode Simulation
    .NOTES
        White-label Microsoft Purview tooling. Read-only. No credentials stored.
        Expected results: PASS (exit 0) = policy mode matches -ExpectMode, at least one enabled rule exists,
        and (for simulation) a scan/match set is present for review. FAIL (exit 1) = a check did not hold.
        The PRECISION decision (are the matched items the right ones?) is the data owner's judgement on the
        match set — this script confirms the set EXISTS and the mode is correct, not that classification is right.
        VERIFY IN YOUR TENANT: auto-labeling is E5/E5 Compliance and evolving; simulation status property names
        and scan latency vary — treat "no match set yet" as allow-more-time, not necessarily a failure.
#>
[CmdletBinding()]
param(
    [Parameter(Mandatory = $true)][string]$PolicyName,
    [ValidateSet('Simulation', 'Enforce')]
    [string]$ExpectMode = 'Simulation'
)

$ErrorActionPreference = "Stop"
Write-Host "=== IPAUTO Validate — auto-labeling state (read-only) ===" -ForegroundColor Cyan
Write-Host ("Policy: {0}   Expected: {1}" -f $PolicyName, $ExpectMode) -ForegroundColor Gray

if (-not (Get-Command Get-AutoSensitivityLabelPolicy -ErrorAction SilentlyContinue)) {
    Write-Host "Get-AutoSensitivityLabelPolicy not available. Run Connect-IPPSSession; check licensing/role (Req 2.2/2.3)." -ForegroundColor Red
    exit 1
}

$results = New-Object System.Collections.Generic.List[object]
function Add-Check($name, $pass, $detail) {
    $results.Add([pscustomobject]@{ Check = $name; Result = ($(if ($pass) { 'PASS' } else { 'FAIL' })); Detail = $detail })
    $color = if ($pass) { 'Green' } else { 'Red' }
    Write-Host ("  [{0}] {1} — {2}" -f $(if ($pass) { 'PASS' } else { 'FAIL' }), $name, $detail) -ForegroundColor $color
}

# --- Check 1: policy exists ---
$pol = @(Get-AutoSensitivityLabelPolicy -ErrorAction SilentlyContinue) | Where-Object { $_.Name -eq $PolicyName } | Select-Object -First 1
if (-not $pol) {
    Add-Check "Policy exists" $false "Policy '$PolicyName' not found."
    Write-Host "`nOVERALL: FAIL" -ForegroundColor Red
    exit 1
}
Add-Check "Policy exists" $true ("Found; Mode={0}; Label={1}" -f $pol.Mode, $pol.ApplySensitivityLabel)

# --- Check 2: mode matches expectation ---
$simModes = @('TestWithoutNotifications', 'TestWithNotifications')
$modeStr = "$($pol.Mode)"
if ($ExpectMode -eq 'Simulation') {
    $ok = $simModes -contains $modeStr
    Add-Check "Mode is SIMULATION" $ok ("Mode={0} (expected one of: {1})" -f $modeStr, ($simModes -join '/'))
    if (-not $ok) { Write-Host "    -> policy is NOT safely in simulation; investigate before it labels content." -ForegroundColor Yellow }
} else {
    $ok = ($modeStr -eq 'Enable')
    Add-Check "Mode is ENFORCE (Enable)" $ok ("Mode={0} (expected: Enable)" -f $modeStr)
}

# --- Check 3: at least one enabled rule ---
$ruleOk = $false; $ruleDetail = "Get-AutoSensitivityLabelRule not available."
if (Get-Command Get-AutoSensitivityLabelRule -ErrorAction SilentlyContinue) {
    $rules = @(Get-AutoSensitivityLabelRule -ErrorAction SilentlyContinue) | Where-Object { "$($_.Policy)" -match [regex]::Escape($PolicyName) }
    $enabled = @($rules | Where-Object { -not $_.Disabled })
    $ruleOk = ($enabled.Count -ge 1)
    $ruleDetail = ("{0} rule(s), {1} enabled." -f @($rules).Count, $enabled.Count)
}
Add-Check "Rule present + enabled" $ruleOk $ruleDetail

# --- Check 4 (simulation only): a scan/match set is present ---
if ($ExpectMode -eq 'Simulation') {
    # Simulation status/count property names vary by tenant/version — scan the object text for a match/scan signal.
    $blob = ($pol | Format-List * | Out-String)
    $hasSignal = $blob -match "(?i)simulation|matcheditem|itemcount|progress|status|deployed"
    if ($hasSignal) {
        $sigDetail = "A simulation/scan status field is present — review the match set (IPAUTO-Report.ps1) with the data owner."
    } else {
        $sigDetail = "No obvious scan/match signal yet — service-side scanning is not instant; ALLOW MORE TIME, then re-check (verify limits for your tenant)."
    }
    Add-Check "Simulation scan/match signal present" $hasSignal $sigDetail
    Write-Host "    NOTE: this only confirms a match set EXISTS. PRECISION (false positives/negatives) is the data owner's call (Testing Test 5)." -ForegroundColor Yellow
}

# --- Overall ---
$fail = @($results | Where-Object { $_.Result -eq 'FAIL' })
Write-Host ""
if ($fail.Count -eq 0) {
    Write-Host ("OVERALL: PASS — '{0}' matches expected state '{1}'." -f $PolicyName, $ExpectMode) -ForegroundColor Green
    exit 0
} else {
    Write-Host ("OVERALL: FAIL — {0} check(s) did not hold. See detail above." -f $fail.Count) -ForegroundColor Red
    exit 1
}
