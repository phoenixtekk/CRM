<#
.SYNOPSIS
    DLPCLIP-Validate.ps1 — run the clipboard/screen-capture Endpoint DLP configuration gates (policy, Devices location, mode, scope, restrictions) read-only.
.DESCRIPTION
    PURPOSE
        Read-only validation of the clipboard & screen-capture Endpoint DLP policy against the configuration
        gates in 05-testing.md (Gate A). Confirms the policy exists, covers the Devices location, is in the
        expected Test/simulation mode (during the pilot pass), is scoped to a pilot (not all devices), and that
        its rule carries the COPY-TO-CLIPBOARD and SCREEN-CAPTURE restrictions with a sensitive-content
        condition. Prints PASS/FAIL per check. Changes nothing.
    HOW TO RUN
        PowerShell 5.1+ or 7+ with Security & Compliance PowerShell (Connect-IPPSSession):
          Connect-IPPSSession
          .\DLPCLIP-Validate.ps1
          .\DLPCLIP-Validate.ps1 -PolicyName "DLP - Endpoint Clipboard+Screen - Simulation"
    EXPECTED RESULTS
        A PASS/FAIL line per gate and an overall result. Expect all-PASS in the simulation pass. In the enforce
        pass, A3 (simulation) is expected to FLIP (policy Mode = Enable) BY DESIGN — that is noted, not an error.
        If SCREEN CAPTURE is unavailable in your tenant (newer/preview), gate A5b flags it as "verify in tenant".
.NOTES
    White-label Microsoft Purview tooling. Read-only. No credentials stored. Standard Get-DlpCompliance* cmdlets;
    none invented. Whether the policy SHOULD be in simulation depends on the phase — the script reports the mode
    and lets you judge against the phase you are in. Screen-capture restriction is NEWER / MAY BE IN PREVIEW —
    verify your licensing/tenant.
#>
[CmdletBinding()]
param(
    [string]$PolicyName = "DLP - Endpoint Clipboard+Screen - Simulation",
    [string]$RuleName   = "DLP - Endpoint Clipboard+Screen - Rule"
)

$ErrorActionPreference = "Stop"
Write-Host "=== DLPCLIP Validate — clipboard/screen-capture Endpoint DLP gates (read-only) ===" -ForegroundColor Cyan

try { Get-DlpCompliancePolicy -ErrorAction Stop | Out-Null }
catch { Write-Host "Not connected to Security & Compliance PowerShell. Run Connect-IPPSSession first (GR #3)." -ForegroundColor Red; return }

$results = [System.Collections.Generic.List[object]]::new()
function Gate($id, $desc, $pass, $detail) {
    $results.Add([pscustomobject]@{ Gate = $id; Check = $desc; Result = ($(if ($pass) {"PASS"} else {"FAIL"})); Detail = $detail })
    $col = if ($pass) { "Green" } else { "Red" }
    Write-Host ("  [{0}] {1,-30} {2}" -f $(if($pass){"PASS"}else{"FAIL"}), $id, $detail) -ForegroundColor $col
}

# A1 — policy exists
$pol = Get-DlpCompliancePolicy -Identity $PolicyName -ErrorAction SilentlyContinue
if ($null -eq $pol) {
    Gate "A1" "Policy exists" $false "Policy '$PolicyName' not found — run DLPCLIP-Configure.ps1 -Commit first."
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

# A5 — the clipboard+screen-capture rule is present and enabled
$rules = @()
try { $rules = Get-DlpComplianceRule -Policy $PolicyName -ErrorAction Stop } catch { }
$rule = $rules | Where-Object { $_.Name -eq $RuleName } | Select-Object -First 1
Gate "A5" "Clipboard/screen rule present" ($null -ne $rule) ($(if($rule){"Found '$RuleName'."}else{"Rule '$RuleName' not found under this policy."}))
if ($null -ne $rule) {
    Gate "A5a" "Rule enabled" (-not $rule.Disabled) ("Disabled = {0}" -f $rule.Disabled)
}

# A5b — the rule carries clipboard AND screen-capture restrictions (screen capture may be preview/absent → verify)
$restrictText = ""
if ($null -ne $rule) { try { if ($rule.EndpointDlpRestrictions) { $restrictText = ($rule.EndpointDlpRestrictions | Out-String).Trim() } } catch { } }
$hasClip   = ($restrictText -match "Clipboard")
$hasScreen = ($restrictText -match "Screen" -or $restrictText -match "Screenshot")
Gate "A5b-clip"   "Clipboard restriction present"    $hasClip   ($(if($hasClip){"CopyToClipboard restriction found."}else{"No readable clipboard restriction — verify in portal."}))
if ($hasScreen) {
    Gate "A5b-screen" "Screen-capture restriction present" $true "ScreenCapture restriction found."
} else {
    Write-Host "  [NOTE] A5b-screen  Screen-capture restriction not readable — NEWER/PREVIEW; VERIFY IN TENANT (deliver clipboard first if unavailable)." -ForegroundColor DarkYellow
    $results.Add([pscustomobject]@{ Gate="A5b-screen"; Check="Screen-capture restriction present"; Result="VERIFY"; Detail="Not readable — screen capture is newer/preview; verify your licensing/tenant." })
}

# A6 — the rule carries a sensitive-content condition (label or SIT), not 'all content'
if ($null -ne $rule) {
    $hasCond = $false
    try {
        if ($rule.ContentContainsSensitiveInformation -and @($rule.ContentContainsSensitiveInformation).Count -gt 0) { $hasCond = $true }
        if (-not $hasCond -and $rule.ContentPropertyContainsWords) { $hasCond = $true }
        # sensitivity-label conditions may surface under different properties across tenants — flag for manual check when empty
    } catch { }
    Gate "A6" "Sensitive-content condition" $hasCond ($(if($hasCond){"Rule carries a readable content condition."}else{"No readable content condition — verify the label/SIT condition in the portal."}))
}

# --- summary ---
$fail = @($results | Where-Object { $_.Result -eq "FAIL" })
Write-Host ""
if ($fail.Count -eq 0) { Write-Host "OVERALL: PASS — configuration gates met for this phase (screen capture 'VERIFY' is not a failure)." -ForegroundColor Green }
else { Write-Host ("OVERALL: FAIL — {0} gate(s) failed. Fix per 03-implementation.md before proceeding." -f $fail.Count) -ForegroundColor Red }
Write-Host "Note: A5b-screen/A6 read what PowerShell exposes; confirm screen-capture availability and sensitivity-label conditions in the portal where blank." -ForegroundColor DarkYellow
