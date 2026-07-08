<#
.SYNOPSIS
    CLSFINGER-Validation.ps1 — confirm a fingerprint SIT exists, is referenced by a DLP policy, and the policy is in simulation (read-only).
.DESCRIPTION
    PURPOSE
        Read-only validation of the fingerprinting wiring. Confirms the named fingerprint sensitive
        information type EXISTS, finds every DLP rule/policy that REFERENCES it, and reports each policy's
        MODE — flagging PASS when the policy is in simulation (the house default before enforcement) and
        WARNING when a policy is enforced without evidence of a pilot. Does not test document content
        (content detection is proven by moving a filled form through a covered channel — see Testing).
        Changes nothing.
    HOW TO RUN
        PowerShell 5.1+ or 7+ with Security & Compliance PowerShell (Connect-IPPSSession):
          Connect-IPPSSession -UserPrincipalName admin@contoso.com
          .\CLSFINGER-Validation.ps1 -SitName "Standard Forms - Fingerprint SIT - Classification"
          .\CLSFINGER-Validation.ps1 -SitName "Standard Forms - Fingerprint SIT - Classification" -CsvPath .\CLSFINGER-Validation.csv
    EXPECTED RESULTS
        PASS: SIT exists AND is referenced by at least one DLP policy in simulation mode. WARN: SIT exists
        but is unreferenced (inert), or a referencing policy is already enforced. FAIL: SIT not found.
.NOTES
    White-label Microsoft Purview tooling. Read-only. No credentials stored. Cmdlets are standard Security &
    Compliance PowerShell; none are invented.
#>
[CmdletBinding()]
param(
    [Parameter(Mandatory = $true)][string]$SitName,
    [string]$CsvPath
)

$ErrorActionPreference = "Stop"
Write-Host "=== CLSFINGER Validation — fingerprint wiring (read-only) ===" -ForegroundColor Cyan

try { Get-DlpSensitiveInformationType -ErrorAction Stop | Out-Null }
catch { Write-Host "Not connected to Security & Compliance PowerShell. Run Connect-IPPSSession first (GR #3)." -ForegroundColor Red; return }

$results = [System.Collections.Generic.List[object]]::new()
function Add-Result($check, $status, $detail) {
    $results.Add([pscustomobject]@{ Check = $check; Status = $status; Detail = $detail })
    $color = switch ($status) { "PASS" { "Green" } "WARN" { "Yellow" } "FAIL" { "Red" } default { "Gray" } }
    Write-Host ("  [{0}] {1} — {2}" -f $status, $check, $detail) -ForegroundColor $color
}

# --- 1. SIT exists? ---
$sit = $null
try { $sit = Get-DlpSensitiveInformationType -Identity $SitName -ErrorAction Stop } catch { $sit = $null }
if (-not $sit) {
    Add-Result "SIT exists" "FAIL" "Sensitive info type '$SitName' not found. Create it with CLSFINGER-CreateFingerprint.ps1 -Commit."
    if ($CsvPath) { $results | Export-Csv -Path $CsvPath -NoTypeInformation -Encoding UTF8 }
    return
}
Add-Result "SIT exists" "PASS" ("Found '{0}' (Publisher={1})" -f $sit.Name, $sit.Publisher)

# --- 2. Referenced by any DLP rule/policy? ---
$refs = @()
try {
    $rules = Get-DlpComplianceRule -ErrorAction Stop
    foreach ($r in $rules) {
        $names = @()
        try { foreach ($c in @($r.ContentContainsSensitiveInformation)) { if ($c -and $c.Name) { $names += $c.Name } } } catch { }
        if ($names -contains $SitName) { $refs += $r }
    }
} catch { Add-Result "Read DLP rules" "WARN" "Could not read DLP rules: $($_.Exception.Message)" }

if ($refs.Count -eq 0) {
    Add-Result "Referenced by DLP" "WARN" "SIT is not referenced by any DLP rule — it is INERT until wired to a DLP policy (Impl. Phase 3)."
} else {
    Add-Result "Referenced by DLP" "PASS" ("Referenced by {0} DLP rule(s)." -f $refs.Count)

    # --- 3. Mode of each referencing policy ---
    $policies = @()
    try { $policies = Get-DlpCompliancePolicy -ErrorAction Stop } catch { }
    foreach ($r in $refs) {
        $pol = $policies | Where-Object { $_.Name -eq $r.Policy } | Select-Object -First 1
        $modeText = if ($pol) { [string]$pol.Mode } else { "unknown" }
        # Simulation modes surface as Test / TestWithNotifications / TestWithoutNotifications; enforced as Enable.
        if ($modeText -match '(?i)test') {
            Add-Result "Policy mode: $($r.Policy)" "PASS" "Mode=$modeText (SIMULATION — house default before enforce)."
        } elseif ($modeText -match '(?i)enable') {
            Add-Result "Policy mode: $($r.Policy)" "WARN" "Mode=$modeText (ENFORCED). Confirm this was a deliberate, piloted transition (Impl. Phase 5)."
        } else {
            Add-Result "Policy mode: $($r.Policy)" "WARN" "Mode=$modeText — confirm in portal."
        }
    }
}

$fail = ($results | Where-Object { $_.Status -eq "FAIL" }).Count
$warn = ($results | Where-Object { $_.Status -eq "WARN" }).Count
Write-Host ("`nSummary: {0} PASS-blocking FAIL(s), {1} WARN(s)." -f $fail, $warn) -ForegroundColor Cyan
if ($CsvPath) { $results | Export-Csv -Path $CsvPath -NoTypeInformation -Encoding UTF8; Write-Host "Written to $CsvPath" -ForegroundColor Green }
Write-Host "Prove content detection by moving a filled (fake-data) form through a covered channel — see Testing Gate A." -ForegroundColor Cyan
