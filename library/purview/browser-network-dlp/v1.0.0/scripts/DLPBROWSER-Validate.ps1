<#
.SYNOPSIS
    DLPBROWSER-Validate.ps1 — run the Browser & Network DLP configuration gates (policy, Devices location, simulation, scope, upload rule, domain-group posture) read-only.
.DESCRIPTION
    PURPOSE
        Read-only validation of the Browser & Network DLP policy against the configuration gates in
        05-testing.md (Gate A). Confirms the policy exists, covers the Devices location, is in a
        Test/simulation mode (during the pilot pass), is scoped to a pilot (not all devices), and carries the
        upload-restriction rule with a sensitive-content condition; and reads the Endpoint DLP browser/domain
        SETTINGS (sensitive service domain group + unallowed browsers) via Get-PolicyConfig to confirm the
        upload restriction has somewhere to act. Prints PASS/FAIL per check. Changes nothing.
    HOW TO RUN
        PowerShell 5.1+ or 7+ with Security & Compliance PowerShell (Connect-IPPSSession):
          Connect-IPPSSession
          .\DLPBROWSER-Validate.ps1
          .\DLPBROWSER-Validate.ps1 -PolicyName "Browser & Network DLP - Devices - Pilot"
    EXPECTED RESULTS
        A PASS/FAIL line per gate and an overall result. Expect all-PASS in the simulation pass. In the
        enforce pass, A3 (simulation) is expected to FLIP (policy Mode = Enable) BY DESIGN — that is noted,
        not an error.
.NOTES
    White-label Microsoft Purview tooling. Read-only. No credentials stored. Standard Get-DlpCompliance* and
    Get-PolicyConfig cmdlets; none invented. The browser/domain SETTINGS surface EVOLVES — where the domain
    group / unallowed browsers are not readable via PowerShell, the gate reports UNKNOWN and asks you to
    confirm in the portal rather than failing. Whether the policy SHOULD be in simulation depends on the
    phase — the script reports the mode and lets you judge against the phase you are in.
#>
[CmdletBinding()]
param(
    [string]$PolicyName = "Browser & Network DLP - Devices - Pilot",
    [string]$RuleName   = "Restrict Upload to Unsanctioned Domains - Rule"
)

$ErrorActionPreference = "Stop"
Write-Host "=== DLPBROWSER Validate — Browser & Network DLP configuration gates (read-only) ===" -ForegroundColor Cyan

try { Get-DlpCompliancePolicy -ErrorAction Stop | Out-Null }
catch { Write-Host "Not connected to Security & Compliance PowerShell. Run Connect-IPPSSession first (GR §3)." -ForegroundColor Red; return }

$results = [System.Collections.Generic.List[object]]::new()
function Gate($id, $desc, $pass, $detail) {
    $label = if ($pass -eq $true) { "PASS" } elseif ($pass -eq $false) { "FAIL" } else { "UNKN" }
    $col   = if ($pass -eq $true) { "Green" } elseif ($pass -eq $false) { "Red" } else { "DarkYellow" }
    $results.Add([pscustomobject]@{ Gate = $id; Check = $desc; Result = $label; Detail = $detail })
    Write-Host ("  [{0}] {1,-28} {2}" -f $label, $id, $detail) -ForegroundColor $col
}

# A1 — policy exists
$pol = Get-DlpCompliancePolicy -Identity $PolicyName -ErrorAction SilentlyContinue
if ($null -eq $pol) {
    Gate "A1" "Policy exists" $false "Policy '$PolicyName' not found — run DLPBROWSER-Configure.ps1 -Commit first."
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
Gate "A4" "Pilot scope (not All)" (-not $scopeAll) ("Scope = {0}" -f ($(if($scopeAll){"All devices (NOT pilot)"}else{(@($pol.EndpointDlpLocation) -join ', ')})))

# A5 — upload-restriction rule present + enabled
$rules = @()
try { $rules = Get-DlpComplianceRule -Policy $PolicyName -ErrorAction Stop } catch { }
$rule = $rules | Where-Object { $_.Name -eq $RuleName } | Select-Object -First 1
Gate "A5" "Upload-restriction rule present" ($null -ne $rule) ($(if($rule){"Found '$RuleName'"}else{"Rule '$RuleName' not found under the policy"}))
if ($rule) {
    Gate "A5b" "Rule enabled" (-not ($rule.Disabled -eq $true)) ("Disabled = {0}" -f $rule.Disabled)

    # A6 — rule carries a sensitive-content condition (label or SIT), not 'all content'
    $hasCond = $false
    try {
        if ($rule.ContentContainsSensitiveInformation -and @($rule.ContentContainsSensitiveInformation).Count -gt 0) { $hasCond = $true }
        if (-not $hasCond -and $rule.ContentPropertyContainsWords) { $hasCond = $true }
    } catch { }
    Gate "A6" "Sensitive-content condition" ($(if($hasCond){$true}else{$null})) ($(if($hasCond){"Readable content condition present."}else{"No readable sensitive-content condition — verify the label condition in the portal."}))
}

# A7 — Endpoint DLP browser/domain settings: sensitive service domain group + unallowed browsers readable
try {
    $cfg = Get-PolicyConfig -ErrorAction Stop
    $domReadable = $false; $ubReadable = $false
    foreach ($prop in @('SensitiveServiceDomainGroups','EndpointDlpSensitiveServiceDomains','SensitiveServiceDomains')) {
        if ($cfg.PSObject.Properties.Name -contains $prop -and $cfg.$prop) { $domReadable = $true; break }
    }
    foreach ($prop in @('UnallowedBrowsers','EndpointDlpUnallowedBrowsers','UnallowedApps')) {
        if ($cfg.PSObject.Properties.Name -contains $prop -and $cfg.$prop) { $ubReadable = $true; break }
    }
    Gate "A7"  "Sensitive service domain group" ($(if($domReadable){$true}else{$null})) ($(if($domReadable){"Domain group data readable via Get-PolicyConfig."}else{"Not readable via PowerShell — confirm the domain group in the portal."}))
    Gate "A7b" "Unallowed browsers configured"  ($(if($ubReadable){$true}else{$null}))  ($(if($ubReadable){"Unallowed-browsers data readable via Get-PolicyConfig."}else{"Not readable via PowerShell — confirm the list in the portal."}))
} catch {
    Gate "A7" "Endpoint DLP browser/domain settings" $null ("Get-PolicyConfig not available here — confirm the domain group + unallowed browsers in the portal: {0}" -f $_.Exception.Message)
}

# --- summary ---
$fail = @($results | Where-Object { $_.Result -eq "FAIL" })
$unkn = @($results | Where-Object { $_.Result -eq "UNKN" })
Write-Host ""
if ($fail.Count -eq 0) { Write-Host ("OVERALL: PASS — configuration gates met for this phase ({0} item(s) to confirm in portal)." -f $unkn.Count) -ForegroundColor Green }
else { Write-Host ("OVERALL: FAIL — {0} gate(s) failed. Fix per 03-implementation.md before proceeding." -f $fail.Count) -ForegroundColor Red }
Write-Host "Note: A6/A7 read what PowerShell exposes; confirm label conditions and the browser/domain settings in the portal where marked UNKN." -ForegroundColor DarkYellow
