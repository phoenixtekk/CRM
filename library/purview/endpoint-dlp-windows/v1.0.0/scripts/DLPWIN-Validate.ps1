<#
.SYNOPSIS
    DLPWIN-Validate.ps1 — run the Endpoint DLP configuration gates (policy, Devices location, simulation, scope, five rules) read-only.
.DESCRIPTION
    PURPOSE
        Read-only validation of the Windows Endpoint DLP policy against the configuration gates in
        05-testing.md (Gate A). Confirms the policy exists, covers the Devices location, is in a
        Test/simulation mode (during the pilot pass), is scoped to a pilot (not all devices), and has the
        five expected channel rules present and enabled. Prints PASS/FAIL per check. Changes nothing.
    HOW TO RUN
        PowerShell 5.1+ or 7+ with Security & Compliance PowerShell (Connect-IPPSSession):
          Connect-IPPSSession
          .\DLPWIN-Validate.ps1
          .\DLPWIN-Validate.ps1 -PolicyName "EDLP-Windows-Pilot"
    EXPECTED RESULTS
        A PASS/FAIL line per gate and an overall result. Expect all-PASS in the simulation pass. In the
        enforce pass, A3 (simulation) is expected to FLIP (policy Mode = Enable) BY DESIGN — that is noted,
        not an error.
.NOTES
    White-label Microsoft Purview tooling. Read-only. No credentials stored. Standard Get-DlpCompliance*
    cmdlets; none invented. Whether the policy SHOULD be in simulation depends on the phase — the script
    reports the mode and lets you judge against the phase you are in.
#>
[CmdletBinding()]
param(
    [string]$PolicyName = "EDLP-Windows-Pilot",
    [string[]]$ExpectedRules = @("EDLP-Rule-USB","EDLP-Rule-Print","EDLP-Rule-Clipboard","EDLP-Rule-NetworkShare","EDLP-Rule-CloudEgress")
)

$ErrorActionPreference = "Stop"
Write-Host "=== DLPWIN Validate — Endpoint DLP configuration gates (read-only) ===" -ForegroundColor Cyan

try { Get-DlpCompliancePolicy -ErrorAction Stop | Out-Null }
catch { Write-Host "Not connected to Security & Compliance PowerShell. Run Connect-IPPSSession first (GR §3)." -ForegroundColor Red; return }

$results = [System.Collections.Generic.List[object]]::new()
function Gate($id, $desc, $pass, $detail) {
    $results.Add([pscustomobject]@{ Gate = $id; Check = $desc; Result = ($(if ($pass) {"PASS"} else {"FAIL"})); Detail = $detail })
    $col = if ($pass) { "Green" } else { "Red" }
    Write-Host ("  [{0}] {1,-28} {2}" -f $(if($pass){"PASS"}else{"FAIL"}), $id, $detail) -ForegroundColor $col
}

# A1 — policy exists
$pol = Get-DlpCompliancePolicy -Identity $PolicyName -ErrorAction SilentlyContinue
if ($null -eq $pol) {
    Gate "A1" "Policy exists" $false "Policy '$PolicyName' not found — run DLPWIN-Configure.ps1 -Commit first."
    Write-Host "`nCannot continue without the policy." -ForegroundColor Red
    return
}
Gate "A1" "Policy exists" $true "Found '$PolicyName'."

# A2 — Devices location
$hasDevices = $false
try { if ($pol.EndpointDlpLocation -and @($pol.EndpointDlpLocation).Count -gt 0) { $hasDevices = $true } } catch { }
Gate "A2" "Devices location" $hasDevices ("EndpointDlpLocation entries: {0}" -f @($pol.EndpointDlpLocation).Count)

# A3 — simulation/test mode (expected TRUE in the pilot pass; expected to flip to Enable after enforce, by design)
$mode = "$($pol.Mode)"
$isSim = $mode -like "Test*"
Gate "A3" "Simulation/test mode" $isSim ("Mode = {0}  (in the ENFORCE pass, Mode=Enable is expected BY DESIGN)" -f $mode)

# A4 — pilot scope (not tenant-wide)
$scopeAll = ($mode -and (@($pol.EndpointDlpLocation) -contains "All"))
$isPilot = -not $scopeAll
Gate "A4" "Pilot scope (not All)" $isPilot ("Scope = {0}" -f ($(if($scopeAll){"All devices (NOT pilot)"}else{(@($pol.EndpointDlpLocation) -join ', ')})))

# A5 — five expected rules present + enabled
$rules = @()
try { $rules = Get-DlpComplianceRule -Policy $PolicyName -ErrorAction Stop } catch { }
$present = @($rules | Select-Object -ExpandProperty Name)
$missing = $ExpectedRules | Where-Object { $present -notcontains $_ }
Gate "A5" "Five channel rules present" ($missing.Count -eq 0) ("Present: {0}/{1}{2}" -f @($present | Where-Object {$ExpectedRules -contains $_}).Count, $ExpectedRules.Count, $(if($missing.Count){" ; missing: " + ($missing -join ', ')}else{""}))

$disabled = @($rules | Where-Object { $_.Disabled -eq $true })
Gate "A5b" "Rules enabled" ($disabled.Count -eq 0) ("Disabled rules: {0}" -f $disabled.Count)

# A6 — each rule carries a sensitive-content condition (label or SIT), not 'all content'
$noCondition = @()
foreach ($r in $rules) {
    $hasCond = $false
    try {
        if ($r.ContentContainsSensitiveInformation -and @($r.ContentContainsSensitiveInformation).Count -gt 0) { $hasCond = $true }
        if (-not $hasCond -and $r.PSObject.Properties.Name -contains 'AccessScope') { } # placeholder
        if (-not $hasCond -and $r.ContentPropertyContainsWords) { $hasCond = $true }
        # label conditions may surface under different properties across tenants — flag for manual check when empty
    } catch { }
    if (-not $hasCond) { $noCondition += $r.Name }
}
Gate "A6" "Sensitive-content condition" ($noCondition.Count -eq 0) ($(if($noCondition.Count){"Rules with NO readable sensitive-content condition (verify label condition in portal): " + ($noCondition -join ', ')}else{"All rules carry a readable content condition."}))

# --- summary ---
$fail = @($results | Where-Object { $_.Result -eq "FAIL" })
Write-Host ""
if ($fail.Count -eq 0) { Write-Host "OVERALL: PASS — configuration gates met for this phase." -ForegroundColor Green }
else { Write-Host ("OVERALL: FAIL — {0} gate(s) failed. Fix per 03-implementation.md before proceeding." -f $fail.Count) -ForegroundColor Red }
Write-Host "Note: A6 reads content conditions that PowerShell exposes; confirm sensitivity-label conditions in the portal where blank." -ForegroundColor DarkYellow
