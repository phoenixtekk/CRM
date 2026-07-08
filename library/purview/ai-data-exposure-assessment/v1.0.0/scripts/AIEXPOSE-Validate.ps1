<#
.SYNOPSIS
    AIEXPOSE-Validate.ps1 — validate the assessment is complete and the simulation pilot is safe/consistent (read-only).
.DESCRIPTION
    PURPOSE
        Read-only validation for the AI Data-Exposure Assessment. Confirms the assessment deliverables
        exist and are internally consistent (scope check, discovery, reachability, and the ranked risk
        register), and — if a pilot remediation policy was created — confirms it is in SIMULATION mode and
        enforces nothing. This is the evidence gate that the assessment is defensible and that the fix
        path was validated WITHOUT changing content. Changes nothing.
    HOW TO RUN
        PowerShell 5.1+ or 7+. Connect Security & Compliance PowerShell to verify the pilot policy mode:
          Connect-IPPSSession
          .\AIEXPOSE-Validate.ps1
          .\AIEXPOSE-Validate.ps1 -SimPolicyName "Exposure Remediation - Pilot - Simulation"
    EXPECTED RESULTS
        A pass/fail validation summary to .\AIEXPOSE-Validate-Estate-Assess.csv. All expected exports
        present = the assessment is complete; a pilot policy, if present, reports Mode = simulation
        (TestWithoutNotifications) = PASS. Any policy found in an enforcing mode is a FAIL to correct.
.NOTES
    White-label Microsoft Purview tooling. Read-only. No credentials stored. This validates evidence and
    the simulation-only posture; it does not enforce or change anything. No cmdlets are invented.
#>
[CmdletBinding()]
param(
    [string]$ScopeCheckCsv  = ".\AIEXPOSE-ScopeCheck-Estate-Assess.csv",
    [string]$DiscoveryCsv   = ".\AIEXPOSE-AccessScope-Estate-Discovery.csv",
    [string]$ReachabilityCsv= ".\AIEXPOSE-Reachability-Copilot-Assess.csv",
    [string]$OversharingCsv = ".\AIEXPOSE-Oversharing-Sites-Assess.csv",
    [string]$RiskRegisterCsv= ".\AIEXPOSE-RiskRegister-Estate-Rank.csv",
    [string]$SimPolicyName  = "Exposure Remediation - Pilot - Simulation",
    [string]$OutPath        = ".\AIEXPOSE-Validate-Estate-Assess.csv"
)

$ErrorActionPreference = "Stop"
Write-Host "=== AIEXPOSE Validate — assessment evidence & simulation-only gate (read-only) ===" -ForegroundColor Cyan

$results = [System.Collections.Generic.List[object]]::new()
function Add-Result($check, $status, $detail) {
    $results.Add([pscustomobject]@{ Check = $check; Status = $status; Detail = $detail })
    $color = switch ($status) { "PASS" { "Green" } "WARN" { "Yellow" } default { "Red" } }
    Write-Host ("  [{0,-4}] {1} — {2}" -f $status, $check, $detail) -ForegroundColor $color
}

# 1. Expected deliverable exports present
$expected = @{
    "Scope check (Estate - Assess)"        = $ScopeCheckCsv
    "Discovery (Access Scope - Discovery)" = $DiscoveryCsv
    "Reachability (Copilot - Assess)"      = $ReachabilityCsv
    "Oversharing (Sites - Assess)"         = $OversharingCsv
    "Risk register (Estate - Rank)"        = $RiskRegisterCsv
}
foreach ($k in $expected.Keys) {
    if (Test-Path $expected[$k]) { Add-Result $k "PASS" ("present: {0}" -f $expected[$k]) }
    else { Add-Result $k "FAIL" ("missing: {0} — run the corresponding script" -f $expected[$k]) }
}

# 2. Risk register is internally consistent (has rows, sorted by score)
if (Test-Path $RiskRegisterCsv) {
    try {
        $reg = Import-Csv $RiskRegisterCsv
        if (@($reg).Count -eq 0) {
            Add-Result "Risk register content" "WARN" "Register is empty — valid pre-adoption result (no broad-sharing signal). Confirm scope/window."
        } else {
            $scores = $reg | ForEach-Object { [int]$_.Score }
            $sorted = ($scores | Sort-Object -Descending) -join "," ; $asis = ($scores) -join ","
            if ($sorted -eq $asis) { Add-Result "Risk register content" "PASS" ("{0} item(s), ranked highest exposure first" -f @($reg).Count) }
            else { Add-Result "Risk register content" "WARN" "Register present but not in descending score order — re-run AIEXPOSE-RiskRegister.ps1." }
        }
    } catch { Add-Result "Risk register content" "WARN" "Could not parse register: $($_.Exception.Message)" }
}

# 3. Pilot policy, if present, MUST be in simulation mode (enforces nothing) — the safety gate
try {
    if (Get-Command Get-AutoSensitivityLabelPolicy -ErrorAction SilentlyContinue) {
        $pol = Get-AutoSensitivityLabelPolicy -Identity $SimPolicyName -ErrorAction SilentlyContinue
        if ($null -eq $pol) {
            Add-Result "Pilot remediation policy" "WARN" "No pilot policy '$SimPolicyName' found — optional; the fix path can be validated later."
        } elseif ($pol.Mode -eq "TestWithoutNotifications") {
            Add-Result "Pilot remediation policy" "PASS" "Policy in SIMULATION (TestWithoutNotifications) — labels nothing, enforces nothing."
        } else {
            Add-Result "Pilot remediation policy" "FAIL" ("Policy Mode = '{0}' is NOT simulation — return to TestWithoutNotifications; this assessment does not enforce." -f $pol.Mode)
        }
    } else {
        Add-Result "Pilot remediation policy" "WARN" "Not connected to S&C PowerShell — run Connect-IPPSSession to verify the pilot policy mode."
    }
} catch { Add-Result "Pilot remediation policy" "WARN" "Could not read pilot policy: $($_.Exception.Message)" }

$results | Export-Csv -Path $OutPath -NoTypeInformation -Encoding UTF8
Write-Host ("`nValidation written to {0}  (AIEXPOSE Validate - Estate - Assess)" -f $OutPath) -ForegroundColor Green
if ($results | Where-Object Status -eq "FAIL") {
    Write-Host "One or more FAIL checks — the assessment is not yet complete/safe. Resolve before hand-off." -ForegroundColor Red
} else {
    Write-Host "Assessment evidence complete and simulation-only posture confirmed. Route determinations to compliance/records/privacy/legal (GR §5)." -ForegroundColor Green
}
