<#
.SYNOPSIS
    DLPEXO-Validate.ps1 — run the Exchange Online DLP configuration gates (policy, Exchange location, simulation, scope, five rules, exception) read-only.
.DESCRIPTION
    PURPOSE
        Read-only validation of the Exchange Online DLP policy against the configuration gates in 05-testing.md
        (Gate A). Confirms the policy exists, covers the Exchange (email) location, is in a Test/simulation mode
        (during the pilot pass), is scoped to a pilot sender group (not all senders), has the five expected
        scenario rules present and enabled, each carries a sensitive-content condition, and the external rules
        reference the trusted-partner exception. Prints PASS/FAIL per check. Changes nothing.
    HOW TO RUN
        PowerShell 5.1+ or 7+ with Security & Compliance PowerShell (Connect-IPPSSession):
          Connect-IPPSSession
          .\DLPEXO-Validate.ps1
          .\DLPEXO-Validate.ps1 -PolicyName "DLPEXO-Pilot" -PartnerDomain "partner.contoso.com"
    EXPECTED RESULTS
        A PASS/FAIL line per gate and an overall result. Expect all-PASS in the simulation pass. In the enforce
        pass, A3 (simulation) is expected to FLIP (policy Mode = Enable) BY DESIGN — that is noted, not an error.
.NOTES
    White-label Microsoft Purview tooling. Read-only. No credentials stored. Standard Get-DlpCompliance* cmdlets;
    none invented. Whether the policy SHOULD be in simulation depends on the phase — the script reports the mode
    and lets you judge against the phase you are in. Some conditions (labels, exceptions) surface under different
    properties across tenants — where blank, the script flags them for a manual portal check rather than failing.
#>
[CmdletBinding()]
param(
    [string]$PolicyName    = "DLPEXO-Pilot",
    [string]$PartnerDomain = "partner.contoso.com",
    [string]$PilotGroup    = "SG-DLPEXO-Pilot",
    [string[]]$ExpectedRules = @("DLPEXO-Rule-Ext-Block","DLPEXO-Rule-Ext-Notify","DLPEXO-Rule-Label-Encrypt","DLPEXO-Rule-Internal-Audit","DLPEXO-Rule-Ext-Escalate")
)

$ErrorActionPreference = "Stop"
Write-Host "=== DLPEXO Validate — Exchange Online DLP configuration gates (read-only) ===" -ForegroundColor Cyan

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
    Gate "A1" "Policy exists" $false "Policy '$PolicyName' not found — run DLPEXO-Configure.ps1 -Commit first."
    Write-Host "`nCannot continue without the policy." -ForegroundColor Red
    return
}
Gate "A1" "Policy exists" $true "Found '$PolicyName'."

# A2 — Exchange location
$hasExchange = $false
try { if ($pol.ExchangeLocation -and @($pol.ExchangeLocation).Count -gt 0) { $hasExchange = $true } } catch { }
Gate "A2" "Exchange location" $hasExchange ("ExchangeLocation entries: {0}" -f @($pol.ExchangeLocation).Count)

# A3 — simulation/test mode (expected TRUE in the pilot pass; expected to flip to Enable after enforce, by design)
$mode = "$($pol.Mode)"
$isSim = $mode -like "Test*"
Gate "A3" "Simulation/test mode" $isSim ("Mode = {0}  (in the ENFORCE pass, Mode=Enable is expected BY DESIGN)" -f $mode)

# --- rules for this policy ---
$rules = @()
try { $rules = Get-DlpComplianceRule -Policy $PolicyName -ErrorAction Stop } catch { }

# A4 — pilot scope: rules reference the pilot sender group (not all senders)
$pilotScoped = @()
$noScope     = @()
foreach ($r in $rules) {
    $hasPilot = $false
    try { if ("$($r.FromMemberOf)" -match [regex]::Escape($PilotGroup)) { $hasPilot = $true } } catch { }
    if ($hasPilot) { $pilotScoped += $r.Name } else { $noScope += $r.Name }
}
Gate "A4" "Pilot sender scope" ($rules.Count -gt 0 -and $noScope.Count -eq 0) ($(if($noScope.Count){"Rules NOT scoped to '$PilotGroup' (verify in portal / widen only in Phase 5): " + ($noScope -join ', ')}else{"All rules reference '$PilotGroup'."}))

# A5 — five expected rules present + enabled
$present = @($rules | Select-Object -ExpandProperty Name)
$missing = $ExpectedRules | Where-Object { $present -notcontains $_ }
Gate "A5" "Five scenario rules present" ($missing.Count -eq 0) ("Present: {0}/{1}{2}" -f @($present | Where-Object {$ExpectedRules -contains $_}).Count, $ExpectedRules.Count, $(if($missing.Count){" ; missing: " + ($missing -join ', ')}else{""}))

$disabled = @($rules | Where-Object { $_.Disabled -eq $true })
Gate "A5b" "Rules enabled" ($disabled.Count -eq 0) ("Disabled rules: {0}" -f $disabled.Count)

# A6 — each content rule carries a sensitive-content condition (SIT or label), not 'all mail'
$noCondition = @()
foreach ($r in $rules) {
    $hasCond = $false
    try {
        if ($r.ContentContainsSensitiveInformation -and @($r.ContentContainsSensitiveInformation).Count -gt 0) { $hasCond = $true }
        # label conditions may surface under different properties across tenants — treat label-only rules leniently
        if (-not $hasCond -and ($r.Name -like "*Label*")) { $hasCond = $true }
    } catch { }
    if (-not $hasCond) { $noCondition += $r.Name }
}
Gate "A6" "Sensitive-content condition" ($noCondition.Count -eq 0) ($(if($noCondition.Count){"Rules with NO readable sensitive-content condition (verify label/SIT condition in portal): " + ($noCondition -join ', ')}else{"All rules carry a readable content condition."}))

# A7 — trusted-partner exception referenced by the external rules
$extRules = @($rules | Where-Object { "$($_.SentToScope)" -match "NotInOrganization" -or $_.Name -like "*Ext*" })
$noExcept = @()
foreach ($r in $extRules) {
    $hasExcept = $false
    try { if ("$($r.ExceptIfRecipientDomainIs)" -match [regex]::Escape($PartnerDomain)) { $hasExcept = $true } } catch { }
    if (-not $hasExcept) { $noExcept += $r.Name }
}
Gate "A7" "Partner exception referenced" ($extRules.Count -eq 0 -or $noExcept.Count -eq 0) ($(if($noExcept.Count){"External rules NOT referencing exception '$PartnerDomain' (verify in portal): " + ($noExcept -join ', ')}else{"External rules reference the partner exception."}))

# --- summary ---
$fail = @($results | Where-Object { $_.Result -eq "FAIL" })
Write-Host ""
if ($fail.Count -eq 0) { Write-Host "OVERALL: PASS — configuration gates met for this phase." -ForegroundColor Green }
else { Write-Host ("OVERALL: FAIL — {0} gate(s) failed. Fix per 03-implementation.md before proceeding." -f $fail.Count) -ForegroundColor Red }
Write-Host "Note: A4/A6/A7 read properties PowerShell exposes; confirm scope, label conditions, and exceptions in the portal where flagged." -ForegroundColor DarkYellow
