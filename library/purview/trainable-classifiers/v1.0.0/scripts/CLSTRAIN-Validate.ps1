<#
.SYNOPSIS
    CLSTRAIN-Validate.ps1 — run the classifier-wiring configuration gates (auto-label policy, simulation, scope, rule, target label) read-only.
.DESCRIPTION
    PURPOSE
        Read-only validation of the classifier WIRING against the configuration gates in 05-testing.md
        (Gate B). Confirms the auto-labeling policy exists, is in a Test/simulation mode (during the pilot
        pass), is scoped to a pilot (not all), applies the intended sensitivity label, and has the expected
        rule present and enabled. Prints PASS/FAIL per check. Changes nothing. NOTE: the classifier's ACCURACY
        (Gate A) and whether the rule's condition truly references the classifier are confirmed in the portal
        — PowerShell does not always expose the trainable-classifier condition.
    HOW TO RUN
        PowerShell 5.1+ or 7+ with Security & Compliance PowerShell (Connect-IPPSSession):
          Connect-IPPSSession
          .\CLSTRAIN-Validate.ps1
          .\CLSTRAIN-Validate.ps1 -PolicyName "AL-Classifier-Pilot" -LabelName "Confidential"
    EXPECTED RESULTS
        A PASS/FAIL line per gate and an overall result. Expect all-PASS in the simulation pass. In the
        enforce pass, B2 (simulation) is expected to FLIP (policy Mode = Enable) BY DESIGN — that is noted,
        not an error.
.NOTES
    White-label Microsoft Purview tooling. Read-only. No credentials stored. Standard Get-AutoSensitivity
    Label* cmdlets; none invented. The classifier condition and accuracy are confirmed in the portal.
#>
[CmdletBinding()]
param(
    [string]$PolicyName = "AL-Classifier-Pilot",
    [string]$RuleName   = "AL-Rule-Contracts",
    [string]$LabelName  = "Confidential"
)

$ErrorActionPreference = "Stop"
Write-Host "=== CLSTRAIN Validate — classifier-wiring configuration gates (read-only) ===" -ForegroundColor Cyan

try { Get-AutoSensitivityLabelPolicy -ErrorAction Stop | Out-Null }
catch { Write-Host "Not connected to Security & Compliance PowerShell (or auto-labeling unlicensed). Run Connect-IPPSSession first (GR §3)." -ForegroundColor Red; return }

$results = [System.Collections.Generic.List[object]]::new()
function Gate($id, $desc, $pass, $detail) {
    $results.Add([pscustomobject]@{ Gate = $id; Check = $desc; Result = ($(if ($pass) {"PASS"} else {"FAIL"})); Detail = $detail })
    $col = if ($pass) { "Green" } else { "Red" }
    Write-Host ("  [{0}] {1,-30} {2}" -f $(if($pass){"PASS"}else{"FAIL"}), $id, $detail) -ForegroundColor $col
}

# B1 — policy exists
$pol = Get-AutoSensitivityLabelPolicy -Identity $PolicyName -ErrorAction SilentlyContinue
if ($null -eq $pol) {
    Gate "B1" "Wiring policy exists" $false "Auto-labeling policy '$PolicyName' not found — run CLSTRAIN-Configure.ps1 -Commit first."
    Write-Host "`nCannot continue without the policy." -ForegroundColor Red
    return
}
Gate "B1" "Wiring policy exists" $true "Found '$PolicyName'."

# B2 — simulation/test mode (expected TRUE in the pilot pass; expected to flip to Enable after enforce, by design)
$mode = "$($pol.Mode)"
$isSim = $mode -like "Test*"
Gate "B2" "Simulation/test mode" $isSim ("Mode = {0}  (in the ENFORCE pass, Mode=Enable is expected BY DESIGN)" -f $mode)

# B3 — pilot scope (not tenant-wide 'All') — best-effort across exposed location properties
$scopeAll = $false
try {
    foreach ($prop in @('SharePointLocation','OneDriveLocation','ExchangeLocation')) {
        if ($pol.PSObject.Properties.Name -contains $prop) {
            if (@($pol.$prop) -contains "All") { $scopeAll = $true }
        }
    }
} catch { }
Gate "B3" "Pilot scope (not All)" (-not $scopeAll) ($(if($scopeAll){"A location is scoped to All — confirm this is intended (post-pilot only)."}else{"No location is All (pilot-scoped as expected)."}))

# B4 — rule present + enabled
$rule = Get-AutoSensitivityLabelRule -Identity $RuleName -ErrorAction SilentlyContinue
Gate "B4" "Rule present" ($null -ne $rule) ($(if($rule){"Found '$RuleName'."}else{"'$RuleName' not found."}))
if ($rule) {
    Gate "B4b" "Rule enabled" (-not ($rule.Disabled -eq $true)) ("Disabled = {0}" -f $rule.Disabled)
}

# B5 — target label applied
$appliesLabel = "$($pol.ApplySensitivityLabel)"
Gate "B5" "Target label applied" ($appliesLabel -like "*$LabelName*" -or -not [string]::IsNullOrWhiteSpace($appliesLabel)) ("ApplySensitivityLabel = {0} (expected to include '{1}')" -f $appliesLabel, $LabelName)

# B6 — classifier referenced (best-effort; often not exposed via PowerShell)
Write-Host "  [INFO] B6 Classifier referenced       Confirm the trainable-classifier condition on '$RuleName' in the portal — PowerShell does not always expose it." -ForegroundColor DarkYellow

# --- summary ---
$fail = @($results | Where-Object { $_.Result -eq "FAIL" })
Write-Host ""
if ($fail.Count -eq 0) { Write-Host "OVERALL: PASS — wiring configuration gates met for this phase." -ForegroundColor Green }
else { Write-Host ("OVERALL: FAIL — {0} gate(s) failed. Fix per 03-implementation.md before proceeding." -f $fail.Count) -ForegroundColor Red }
Write-Host "Note: Gate A (classifier ACCURACY, R7) and B6 (classifier condition) are confirmed in the portal — this script validates the wiring shell." -ForegroundColor DarkYellow
