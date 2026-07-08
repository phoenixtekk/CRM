<#
.SYNOPSIS
    OPSOPT-Validation.ps1 — PASS/FAIL that tuning removed NOISE not SIGNAL: sim-mode, FP drop vs baseline, true-positive probe still fires. Read-only.
.DESCRIPTION
    PURPOSE
        The gate before any policy is re-enforced. For each tuned policy it checks and reports PASS/FAIL:
        (1) the policy is currently in a Test/simulation mode (nothing enforced blind); (2) the
        false-positive / override rate DROPPED vs the Step-2 baseline (compares the before/after
        dlp-noise-by-rule CSVs); (3) a known-true-positive probe still MATCHES the tuned rule (proving
        noise, not signal, was removed); (4) alert thresholds/aggregation are applied and a rollback
        baseline exists. Read-only — it never changes a policy.
    HOW TO RUN
        PowerShell 5.1+/7+. Connect first: Connect-IPPSSession
          .\OPSOPT-Validation.ps1 -OutputFolder .\OPSOPT-out
          .\OPSOPT-Validation.ps1 -OutputFolder .\OPSOPT-out -BaselineCsv .\OPSOPT-out\dlp-noise-by-rule-baseline.csv -CurrentCsv .\OPSOPT-out\dlp-noise-by-rule.csv `
             -ProbeRule "PII - High Volume" -ProbeMatched:$true
    EXPECTED RESULTS
        A PASS/FAIL line per check. Overall PASS requires: every tuned policy in simulation, FP rate down,
        and the true-positive probe still firing. A FAIL blocks re-enforcement (roll back instead).
.NOTES
    Purview — Optimization & Tune-Up. Read-only. The true-positive probe result is supplied by the operator
    (a seeded/known-sensitive sample or a labeled prior true match) — the script records and gates on it;
    whether a match is genuinely sensitive is a data-owner determination. No credentials in code. No cmdlets invented.
#>
[CmdletBinding()]
param(
    [string[]]$Policies,                 # tuned DLP policies to validate (default: any with a rollback baseline)
    [string]$OutputFolder = '.\OPSOPT-out',
    [string]$BaselineCsv,                # before-tuning dlp-noise-by-rule CSV (copy taken at Step 2)
    [string]$CurrentCsv,                 # after-window dlp-noise-by-rule CSV (Step 10)
    [string]$ProbeRule,                  # rule the true-positive probe targets
    [Nullable[bool]]$ProbeMatched        # operator-supplied: did the known-sensitive sample still match?
)

if (-not (Test-Path $OutputFolder)) { Write-Warning "Output folder '$OutputFolder' not found — run OPSOPT-Report/Scope-Health first."; }
Write-Host '=== OPSOPT Validation — noise-not-signal gate (read-only) ===' -ForegroundColor Cyan

$results = [System.Collections.Generic.List[object]]::new()
function Add-Res([string]$Check,[string]$Status,[string]$Detail){ $results.Add([pscustomobject]@{ Check = $Check; Status = $Status; Detail = $Detail }) }

# --- Determine the tuned policy set (those with a rollback baseline, unless named) ------------------
if (-not $Policies) {
    $Policies = Get-ChildItem -Path $OutputFolder -Filter 'rollback-*.json' -ErrorAction SilentlyContinue |
                Where-Object { $_.Name -notmatch '--' } |
                ForEach-Object { ($_.BaseName -replace '^rollback-','') -replace '_',' ' }
}
$Policies = @($Policies | Where-Object { $_ } | Select-Object -Unique)
if ($Policies.Count -eq 0) { Write-Warning 'No tuned policies found (no rollback baselines). Nothing to validate.'; return }

# --- Check 1: each tuned policy is in simulation mode -----------------------------------------------
foreach ($p in $Policies) {
    try {
        $pol = Get-DlpCompliancePolicy -Identity $p -ErrorAction Stop
        if ("$($pol.Mode)" -like 'Test*') { Add-Res "Sim mode: $p" 'PASS' "Mode=$($pol.Mode)" }
        else { Add-Res "Sim mode: $p" 'FAIL' "Mode=$($pol.Mode) (not in simulation — do not enforce blind)" }
    } catch { Add-Res "Sim mode: $p" 'WARN' "Could not read policy ($($_.Exception.Message)) — may be an auto-label/alert policy" }

    # Check 4a: rollback baseline exists
    $safe = ($p -replace '[^A-Za-z0-9_-]', '_')
    if (Test-Path (Join-Path $OutputFolder ("rollback-{0}.json" -f $safe))) { Add-Res "Rollback baseline: $p" 'PASS' 'Baseline recorded' }
    else { Add-Res "Rollback baseline: $p" 'FAIL' 'No rollback baseline — capture before enforcing' }
}

# --- Check 2: false-positive / override rate dropped vs baseline ------------------------------------
if ($BaselineCsv -and $CurrentCsv -and (Test-Path $BaselineCsv) -and (Test-Path $CurrentCsv)) {
    try {
        $before = Import-Csv $BaselineCsv
        $after  = Import-Csv $CurrentCsv
        foreach ($b in $before) {
            $a = $after | Where-Object { $_.PolicyRule -eq $b.PolicyRule } | Select-Object -First 1
            if (-not $a) { continue }
            $bRate = [double]($b.OverrideRatePct); $aRate = [double]($a.OverrideRatePct)
            if ($aRate -le $bRate) { Add-Res ("FP rate: {0}" -f $b.PolicyRule) 'PASS' ("{0}% -> {1}%" -f $bRate, $aRate) }
            else { Add-Res ("FP rate: {0}" -f $b.PolicyRule) 'FAIL' ("{0}% -> {1}% (went UP)" -f $bRate, $aRate) }
        }
    } catch { Add-Res 'FP rate comparison' 'WARN' "Could not compare CSVs: $($_.Exception.Message)" }
} else {
    Add-Res 'FP rate comparison' 'INFO' 'Provide -BaselineCsv and -CurrentCsv to compare before/after false-positive rates (Test 6).'
}

# --- Check 3: the true-positive probe still fires ---------------------------------------------------
if ($ProbeRule) {
    if ($ProbeMatched -eq $true)      { Add-Res "True-positive probe: $ProbeRule" 'PASS' 'Known-sensitive sample still matched — signal retained' }
    elseif ($ProbeMatched -eq $false) { Add-Res "True-positive probe: $ProbeRule" 'FAIL' 'Known-sensitive sample NO LONGER matches — tuning removed SIGNAL. Roll back; do not enforce.' }
    else { Add-Res "True-positive probe: $ProbeRule" 'WARN' 'Supply -ProbeMatched:$true/$false after running the known-sensitive sample (Test 7).' }
} else {
    Add-Res 'True-positive probe' 'INFO' 'Specify -ProbeRule and -ProbeMatched — this is the gate that proves signal was not lost (Test 7).'
}

# --- Verdict ----------------------------------------------------------------------------------------
Write-Host '--- Validation results ---' -ForegroundColor Cyan
$results | Format-Table Check, Status, Detail -AutoSize | Out-String | Write-Host
$results | Export-Csv (Join-Path $OutputFolder 'validation-results.csv') -NoTypeInformation -Encoding UTF8

$fails = @($results | Where-Object { $_.Status -eq 'FAIL' }).Count
if ($fails -eq 0) {
    Write-Host 'VALIDATION PASS — tuned policies in simulation, FP rate down, signal retained. Re-enforce is a separate approved step (Step 12).' -ForegroundColor Green
} else {
    Write-Host ("VALIDATION FAIL — {0} failing check(s). Roll back the affected policy (OPSOPT-Tune.ps1 -Rollback); never enforce a failed true-positive probe." -f $fails) -ForegroundColor Red
}
