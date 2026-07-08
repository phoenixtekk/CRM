<#
.SYNOPSIS
    DLPUSB-Validate.ps1 — run the removable-media DLP configuration gates (policy, Devices location, simulation, scope, rule) read-only.
.DESCRIPTION
    PURPOSE
        Read-only validation of the removable-media Endpoint DLP policy against the configuration gates in
        05-testing.md (Gate A). Confirms the policy exists, covers the Devices location, is in a
        Test/simulation mode (during the pilot pass), is scoped to a pilot (not all devices), and has the
        expected removable-media rule present and enabled with a sensitive-content condition. Prints PASS/FAIL
        per check. Changes nothing. (The DEVICE-CONTROL layer is not readable here — confirm it in your
        management tool as a manual gate.)
    HOW TO RUN
        PowerShell 5.1+ or 7+ with Security & Compliance PowerShell (Connect-IPPSSession):
          Connect-IPPSSession
          .\DLPUSB-Validate.ps1
          .\DLPUSB-Validate.ps1 -PolicyName "EDLP-USB-Pilot"
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
    [string]$PolicyName = "EDLP-USB-Pilot",
    [string]$RuleName   = "EDLP-Rule-USB",
    [string]$DeviceGroup = "USBG-Corporate"
)

$ErrorActionPreference = "Stop"
Write-Host "=== DLPUSB Validate — removable-media DLP configuration gates (read-only) ===" -ForegroundColor Cyan

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
    Gate "A1" "Policy exists" $false "Policy '$PolicyName' not found — run DLPUSB-Configure.ps1 -Commit first."
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
$scopeAll = (@($pol.EndpointDlpLocation) -contains "All")
$isPilot = -not $scopeAll
Gate "A4" "Pilot scope (not All)" $isPilot ("Scope = {0}" -f ($(if($scopeAll){"All devices (NOT pilot)"}else{(@($pol.EndpointDlpLocation) -join ', ')})))

# A5 — removable-media rule present + enabled
$rules = @()
try { $rules = Get-DlpComplianceRule -Policy $PolicyName -ErrorAction Stop } catch { }
$rule = $rules | Where-Object { $_.Name -eq $RuleName } | Select-Object -First 1
Gate "A5" "Removable-media rule present" ($null -ne $rule) ($(if($rule){"Found '$RuleName'."}else{"'$RuleName' missing among: " + ((@($rules).Name) -join ', ')}))
if ($rule) {
    Gate "A5b" "Rule enabled" (-not ($rule.Disabled -eq $true)) ("Disabled = {0}" -f $rule.Disabled)
}

# A6 — rule carries a sensitive-content condition (label or SIT), not 'all content'
if ($rule) {
    $hasCond = $false
    try {
        if ($rule.ContentContainsSensitiveInformation -and @($rule.ContentContainsSensitiveInformation).Count -gt 0) { $hasCond = $true }
        if (-not $hasCond -and $rule.ContentPropertyContainsWords) { $hasCond = $true }
    } catch { }
    Gate "A6" "Sensitive-content condition" $hasCond ($(if($hasCond){"Rule carries a readable content condition."}else{"NO readable sensitive-content condition — verify the label condition in the portal."}))
}

# A7 — allow-list device group referenced (best-effort; endpoint-settings groups are not always exposed to PowerShell)
if ($rule) {
    $refDetail = "Confirm the '$DeviceGroup' device-group exception in the portal (Endpoint DLP settings) — not always readable via PowerShell."
    Write-Host ("  [INFO] A7 Allow-list group ({0})   {1}" -f $DeviceGroup, $refDetail) -ForegroundColor DarkYellow
}

# --- summary ---
$fail = @($results | Where-Object { $_.Result -eq "FAIL" })
Write-Host ""
if ($fail.Count -eq 0) { Write-Host "OVERALL: PASS — configuration gates met for this phase." -ForegroundColor Green }
else { Write-Host ("OVERALL: FAIL — {0} gate(s) failed. Fix per 03-implementation.md before proceeding." -f $fail.Count) -ForegroundColor Red }
Write-Host "Note: confirm the DEVICE-CONTROL policy (DC-RemovableStorage-Pilot) and the '$DeviceGroup' allow-list in your management tool / portal — those are not readable here." -ForegroundColor DarkYellow
