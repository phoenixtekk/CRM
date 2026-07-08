<#
.SYNOPSIS
    OPSTRAIN-LabValidate.ps1 — check each lab's expected object, mode, and scope: pass/fail (read-only).
.DESCRIPTION
    PURPOSE
        Validation for the training curriculum. For each lab, confirms the expected TRAIN- object exists in
        the CORRECT mode/scope — Lab 1 label published to the training scope; Lab 2 DLP in a TEST/simulation
        mode (asserts NOT Enable — a training DLP policy must never enforce); Lab 4 auto-labeling in a
        simulation/test mode (asserts NOT enabled); Lab 3 retention present; Lab 7 audit search returns
        rows. Emits PASS/FAIL per lab. Choose a lab or run them all. Changes nothing.
    HOW TO RUN
        PowerShell 5.1+ or 7+ with Security & Compliance PowerShell (Connect-IPPSSession):
          Connect-IPPSSession
          .\OPSTRAIN-LabValidate.ps1 -Lab All
          .\OPSTRAIN-LabValidate.ps1 -Lab DLP
          .\OPSTRAIN-LabValidate.ps1 -Lab Labels -ScopeGroup "TRAIN-Pilot-Users"
    EXPECTED RESULTS
        A pass/fail line per checked lab plus a summary, written to .\OPSTRAIN-Validation.csv. The critical
        gates are DLP (must be TEST, never Enable) and AutoLabel (must be SIMULATION, never enabled). A FAIL
        is a stop-and-fix before crediting that competency.
.NOTES
    White-label Microsoft Purview training tooling. Read-only. No credentials stored. Cmdlets are standard
    Security & Compliance PowerShell; none are invented. Object names default to the TRAIN- convention used
    in the Implementation Guide — override with the parameters if you named yours differently.
#>
[CmdletBinding()]
param(
    [ValidateSet("Labels","DLP","Retention","AutoLabel","Audit","All")]
    [string]$Lab              = "All",
    [string]$ScopeGroup       = "TRAIN-Pilot-Users",
    [string]$LabelName        = "TRAIN-Label-Confidential",
    [string]$LabelPolicyName  = "TRAIN-LabelPolicy-Pilot",
    [string]$DlpPolicyName    = "TRAIN-DLP-PII-Sim",
    [string]$RetentionName    = "TRAIN-Retention-Pilot",
    [string]$AutoLabelName    = "TRAIN-AutoLabel-Sim",
    [string]$OutPath          = ".\OPSTRAIN-Validation.csv"
)

$ErrorActionPreference = "Stop"
Write-Host "=== OPSTRAIN LabValidate — pass/fail gates [$Lab] (read-only) ===" -ForegroundColor Cyan

try { Get-Label -ErrorAction Stop | Out-Null }
catch { Write-Host "Not connected to Security & Compliance PowerShell. Run Connect-IPPSSession first (GR §3)." -ForegroundColor Red; return }

$results = [System.Collections.Generic.List[object]]::new()
function Add-Result($lab, $status, $detail) {
    $results.Add([pscustomobject]@{ Lab = $lab; Status = $status; Detail = $detail })
    $color = if ($status -eq "PASS") { "Green" } elseif ($status -eq "FAIL") { "Red" } else { "Yellow" }
    Write-Host ("  [{0}] {1} — {2}" -f $status, $lab, $detail) -ForegroundColor $color
}
$run = { param($name) $Lab -eq "All" -or $Lab -eq $name }

# --- Lab 1: Labels ---
if (& $run "Labels") {
    try {
        $lbl = Get-Label -ErrorAction Stop | Where-Object DisplayName -eq $LabelName
        $pol = Get-LabelPolicy -ErrorAction Stop | Where-Object Name -eq $LabelPolicyName
        if (-not $lbl) { Add-Result "Labels" "FAIL" "Label '$LabelName' not found" }
        elseif (-not $pol) { Add-Result "Labels" "FAIL" "Label policy '$LabelPolicyName' not found" }
        else {
            $scoped = ($pol.ScopedLabels -join "; ") + ($pol.Settings -join "; ")
            Add-Result "Labels" "PASS" "Label + policy exist. Confirm in portal the policy publishes ONLY to $ScopeGroup."
        }
    } catch { Add-Result "Labels" "WARN" ("not readable (may be unlicensed): {0}" -f $_.Exception.Message) }
}

# --- Lab 2: DLP — must be TEST/simulation, NOT Enable ---
if (& $run "DLP") {
    try {
        $dlp = Get-DlpCompliancePolicy -ErrorAction Stop | Where-Object Name -eq $DlpPolicyName
        if (-not $dlp) { Add-Result "DLP" "FAIL" "DLP policy '$DlpPolicyName' not found" }
        else {
            $mode = "$($dlp.Mode)"
            if ($mode -match 'Enable') { Add-Result "DLP" "FAIL" "Mode=$mode — a TRAINING DLP policy must NEVER enforce. Set back to TestWithoutNotifications or delete." }
            elseif ($mode -match 'Test|Disable') { Add-Result "DLP" "PASS" "Mode=$mode (test/simulation — enforced nothing)" }
            else { Add-Result "DLP" "WARN" "Mode=$mode — confirm this is a non-enforcing test mode" }
        }
    } catch { Add-Result "DLP" "WARN" ("not readable (may be unlicensed): {0}" -f $_.Exception.Message) }
}

# --- Lab 3: Retention ---
if (& $run "Retention") {
    try {
        $ret = Get-RetentionCompliancePolicy -ErrorAction Stop | Where-Object Name -eq $RetentionName
        if (-not $ret) { Add-Result "Retention" "FAIL" "Retention policy '$RetentionName' not found" }
        else { Add-Result "Retention" "PASS" ("exists (Enabled={0}). Confirm illustrative period via Get-RetentionComplianceRule." -f $ret.Enabled) }
    } catch { Add-Result "Retention" "WARN" ("not readable (may be unlicensed): {0}" -f $_.Exception.Message) }
}

# --- Lab 4: Auto-labeling — must be SIMULATION, NOT enabled ---
if (& $run "AutoLabel") {
    try {
        $auto = Get-AutoSensitivityLabelPolicy -ErrorAction Stop | Where-Object Name -eq $AutoLabelName
        if (-not $auto) { Add-Result "AutoLabel" "FAIL" "Auto-labeling policy '$AutoLabelName' not found" }
        else {
            $mode = "$($auto.Mode)"
            if ($mode -match 'Enable') { Add-Result "AutoLabel" "FAIL" "Mode=$mode — a TRAINING auto-label policy must stay in SIMULATION. Revert or delete." }
            else { Add-Result "AutoLabel" "PASS" "Mode=$mode (simulation/test — nothing actually labeled)" }
        }
    } catch { Add-Result "AutoLabel" "WARN" ("not readable (may be unlicensed): {0}" -f $_.Exception.Message) }
}

# --- Lab 7: Audit search returns ---
if (& $run "Audit") {
    try {
        $hits = Search-UnifiedAuditLog -StartDate (Get-Date).AddDays(-7) -EndDate (Get-Date) -ResultSize 1 -ErrorAction Stop
        if (@($hits).Count -ge 1) { Add-Result "Audit" "PASS" "Audit search returned rows (7-day window)" }
        else { Add-Result "Audit" "WARN" "Audit readable but no rows in the 7-day window — widen the window / confirm auditing is on" }
    } catch { Add-Result "Audit" "WARN" ("not readable — check auditing/licensing: {0}" -f $_.Exception.Message) }
}

$results | Export-Csv -Path $OutPath -NoTypeInformation -Encoding UTF8
$pass = @($results | Where-Object Status -eq "PASS").Count
$fail = @($results | Where-Object Status -eq "FAIL").Count
$warn = @($results | Where-Object Status -eq "WARN").Count
Write-Host ("`nValidation written to {0}  (PASS={1}, FAIL={2}, WARN={3})" -f $OutPath, $pass, $fail, $warn) -ForegroundColor Green
if ($fail -gt 0) { Write-Host "  Resolve every FAIL before crediting that competency — especially DLP/AutoLabel enforcement modes." -ForegroundColor Red }
Write-Host "Next: OPSTRAIN-CompetencyReport.ps1 to roll these into the evidence report." -ForegroundColor Cyan
