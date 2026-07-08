<#
.SYNOPSIS
    DLPTEAMS-Validate.ps1 — run the Teams DLP configuration gates (policy, Teams+SharePoint+OneDrive locations, simulation, scope, two rules) read-only.
.DESCRIPTION
    PURPOSE
        Read-only validation of the Teams DLP policy against the configuration gates in 05-testing.md
        (Gate A). Confirms the policy exists, covers the Teams-messages location AND the SharePoint+OneDrive
        file locations (the common "messages covered, files uncovered" gap), is in a Test/simulation mode
        (during the pilot pass), is scoped to a pilot (not all users), and has the two expected rules present
        and enabled with a sensitive-content condition. Prints PASS/FAIL per check. Changes nothing.
    HOW TO RUN
        PowerShell 5.1+ or 7+ with Security & Compliance PowerShell (Connect-IPPSSession):
          Connect-IPPSSession
          .\DLPTEAMS-Validate.ps1
          .\DLPTEAMS-Validate.ps1 -PolicyName "DLP-Teams-Pilot"
    EXPECTED RESULTS
        A PASS/FAIL line per gate and an overall result. Expect all-PASS in the simulation pass. In the
        enforce pass, A4 (simulation) is expected to FLIP (policy Mode = Enable) BY DESIGN — that is noted,
        not an error.
.NOTES
    White-label Microsoft Purview tooling. Read-only. No credentials stored. Standard Get-DlpCompliance*
    cmdlets; none invented. Whether the policy SHOULD be in simulation depends on the phase — the script
    reports the mode and lets you judge against the phase you are in.
#>
[CmdletBinding()]
param(
    [string]$PolicyName    = "DLP-Teams-Pilot",
    [string[]]$ExpectedRules = @("DLP-Rule-TeamsMessages","DLP-Rule-TeamsFiles")
)

$ErrorActionPreference = "Stop"
Write-Host "=== DLPTEAMS Validate — Teams DLP configuration gates (read-only) ===" -ForegroundColor Cyan

try { Get-DlpCompliancePolicy -ErrorAction Stop | Out-Null }
catch { Write-Host "Not connected to Security & Compliance PowerShell. Run Connect-IPPSSession first (GR §3)." -ForegroundColor Red; return }

$results = [System.Collections.Generic.List[object]]::new()
function Gate($id, $desc, $pass, $detail) {
    $results.Add([pscustomobject]@{ Gate = $id; Check = $desc; Result = ($(if ($pass) {"PASS"} else {"FAIL"})); Detail = $detail })
    $col = if ($pass) { "Green" } else { "Red" }
    Write-Host ("  [{0}] {1,-28} {2}" -f $(if($pass){"PASS"}else{"FAIL"}), $id, $detail) -ForegroundColor $col
}
function Has-Location($val) { try { return ($null -ne $val -and @($val).Count -gt 0) } catch { return $false } }

# A1 — policy exists
$pol = Get-DlpCompliancePolicy -Identity $PolicyName -ErrorAction SilentlyContinue
if ($null -eq $pol) {
    Gate "A1" "Policy exists" $false "Policy '$PolicyName' not found — run DLPTEAMS-Configure.ps1 -Commit first."
    Write-Host "`nCannot continue without the policy." -ForegroundColor Red
    return
}
Gate "A1" "Policy exists" $true "Found '$PolicyName'."

# A2 — Teams-messages location
$hasTeams = Has-Location $pol.TeamsLocation
Gate "A2" "Teams-messages location" $hasTeams ("TeamsLocation entries: {0}" -f @($pol.TeamsLocation).Count)

# A3 — file locations (SharePoint + OneDrive) — the "files uncovered" gap
$hasSpo = Has-Location $pol.SharePointLocation
$hasOd  = Has-Location $pol.OneDriveLocation
Gate "A3" "File locations (SPO+OneDrive)" ($hasSpo -and $hasOd) ("SharePoint={0}; OneDrive={1}  (both needed so Teams-SHARED FILES are governed)" -f $hasSpo, $hasOd)

# A4 — simulation/test mode (expected TRUE in the pilot pass; expected to flip to Enable after enforce, by design)
$mode = "$($pol.Mode)"
$isSim = $mode -like "Test*"
Gate "A4" "Simulation/test mode" $isSim ("Mode = {0}  (in the ENFORCE pass, Mode=Enable is expected BY DESIGN)" -f $mode)

# A5 — pilot scope (not tenant-wide) — check the Teams location scope
$scopeAll = (@($pol.TeamsLocation) -contains "All")
$isPilot = -not $scopeAll
Gate "A5" "Pilot scope (Teams not All)" $isPilot ("Teams scope = {0}" -f ($(if($scopeAll){"All users (NOT pilot)"}else{(@($pol.TeamsLocation) -join ', ')})))

# A6 — two expected rules present + enabled
$rules = @()
try { $rules = Get-DlpComplianceRule -Policy $PolicyName -ErrorAction Stop } catch { }
$present = @($rules | Select-Object -ExpandProperty Name)
$missing = $ExpectedRules | Where-Object { $present -notcontains $_ }
Gate "A6" "Two rules present" ($missing.Count -eq 0) ("Present: {0}/{1}{2}" -f @($present | Where-Object {$ExpectedRules -contains $_}).Count, $ExpectedRules.Count, $(if($missing.Count){" ; missing: " + ($missing -join ', ')}else{""}))

$disabled = @($rules | Where-Object { $_.Disabled -eq $true })
Gate "A6b" "Rules enabled" ($disabled.Count -eq 0) ("Disabled rules: {0}" -f $disabled.Count)

# A7 — each rule carries a sensitive-content condition (label or SIT), not 'all content'
$noCondition = @()
foreach ($r in $rules) {
    $hasCond = $false
    try {
        if ($r.ContentContainsSensitiveInformation -and @($r.ContentContainsSensitiveInformation).Count -gt 0) { $hasCond = $true }
        if (-not $hasCond -and $r.ContentPropertyContainsWords) { $hasCond = $true }
    } catch { }
    if (-not $hasCond) { $noCondition += $r.Name }
}
Gate "A7" "Sensitive-content condition" ($noCondition.Count -eq 0) ($(if($noCondition.Count){"Rules with NO readable sensitive-content condition (verify label condition in portal): " + ($noCondition -join ', ')}else{"All rules carry a readable content condition."}))

# --- summary ---
$fail = @($results | Where-Object { $_.Result -eq "FAIL" })
Write-Host ""
if ($fail.Count -eq 0) { Write-Host "OVERALL: PASS — configuration gates met for this phase." -ForegroundColor Green }
else { Write-Host ("OVERALL: FAIL — {0} gate(s) failed. Fix per 03-implementation.md before proceeding." -f $fail.Count) -ForegroundColor Red }
Write-Host "Note: A3 failing is the classic 'messages covered, shared files uncovered' gap — enable SharePoint+OneDrive too." -ForegroundColor DarkYellow
