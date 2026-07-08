<#
.SYNOPSIS
    IPASSESS-Validation.ps1 — score the information-protection posture against the readiness baseline, PASS/WARN/FAIL (read-only).
.DESCRIPTION
    PURPOSE
        Read-only scoring for the Information Protection Assessment. Reads the discovery CSV (or queries
        live) and scores the six posture dimensions against a readiness baseline: taxonomy (labels exist
        and enabled), publishing/coverage (labels actually published), encryption/protection (higher-tier
        labels encrypt), auto-labeling (present and its mode), DLP coverage/mode (in-scope workloads
        covered and not stuck in Test), and sensitive information types. Also verifies that any pilot
        object is in SIMULATION mode with nothing enforced. Emits PASS/WARN/FAIL per dimension. Changes
        nothing.
    HOW TO RUN
        PowerShell 5.1+ or 7+ with Security & Compliance PowerShell (Connect-IPPSSession).
        From the discovery CSV (recommended):
          .\IPASSESS-Validation.ps1 -DiscoveryCsv .\IPASSESS-InformationProtection-Estate-Discovery.csv `
              -InScopeWorkloads "Exchange","SharePoint","OneDrive","Teams"
        Confirm the simulation pilot object is safe:
          .\IPASSESS-Validation.ps1 -CheckPilot
    EXPECTED RESULTS
        A PASS/WARN/FAIL line per dimension against the baseline, written to
        .\IPASSESS-PostureScore-Estate-Validate.csv. With -CheckPilot, confirmation that
        'Information Protection - Pilot - Simulation' (if present) is in a TestWithoutNotifications mode
        and enforces nothing. Tune the baseline targets with stakeholders before treating a score as final.
.NOTES
    White-label Microsoft Purview tooling. Read-only. No credentials stored. The baseline is a starting
    default to refine with compliance/security stakeholders; determinations (whether a gap must be closed)
    remain with compliance/records/privacy/legal. No cmdlets invented.
#>
[CmdletBinding()]
param(
    [string]$DiscoveryCsv = ".\IPASSESS-InformationProtection-Estate-Discovery.csv",
    [string[]]$InScopeWorkloads = @("Exchange","SharePoint","OneDrive","Teams"),
    [string[]]$HighTierLabelPattern = @("Confidential","Restricted","Secret"),
    [switch]$CheckPilot,
    [string]$OutPath = ".\IPASSESS-PostureScore-Estate-Validate.csv"
)

$ErrorActionPreference = "Stop"
Write-Host "=== IPASSESS Validation — posture scored vs. readiness baseline (read-only) ===" -ForegroundColor Cyan

$scores = [System.Collections.Generic.List[object]]::new()
function Add-Score($dimension, $result, $finding) {
    $col = switch ($result) { "PASS" { "Green" } "WARN" { "Yellow" } "FAIL" { "Red" } default { "Gray" } }
    Write-Host ("  [{0,-4}] {1,-22} {2}" -f $result, $dimension, $finding) -ForegroundColor $col
    $scores.Add([pscustomobject]@{ Dimension = $dimension; Result = $result; Finding = $finding })
}

if (-not (Test-Path $DiscoveryCsv)) {
    Write-Host "Discovery CSV not found: $DiscoveryCsv — run IPASSESS-Discovery.ps1 first." -ForegroundColor Red
    return
}
$rows = Import-Csv -Path $DiscoveryCsv

# --- Dimension 1: Taxonomy (labels exist and are enabled) ---
$labelRows = $rows | Where-Object { $_.ArtifactType -eq "SensitivityLabel" }
if (@($labelRows).Count -eq 0) {
    Add-Score "Taxonomy" "FAIL" "No sensitivity labels found — no classification taxonomy exists."
} else {
    $disabled = $labelRows | Where-Object { $_.Detail -match "Enabled=False" }
    if (@($disabled).Count -gt 0) { Add-Score "Taxonomy" "WARN" ("{0} label(s) present but {1} disabled." -f @($labelRows).Count, @($disabled).Count) }
    else { Add-Score "Taxonomy" "PASS" ("{0} enabled label(s) form the taxonomy." -f @($labelRows).Count) }
}

# --- Dimension 2: Publishing / coverage (labels actually published) ---
$policyRows = $rows | Where-Object { $_.ArtifactType -eq "LabelPolicy" }
$publishedLabels = @()
foreach ($p in $policyRows) { if ($p.Detail -match "Labels=(.+)$") { $publishedLabels += ($Matches[1] -split ";\s*") } }
$publishedLabels = $publishedLabels | Where-Object { $_ } | Sort-Object -Unique
if (@($policyRows).Count -eq 0) {
    Add-Score "Publishing/Coverage" "FAIL" "No label policies — labels exist but are published to no one."
} else {
    $labelNames = $labelRows | ForEach-Object { $_.Name }
    $unpublished = $labelNames | Where-Object { $publishedLabels -notcontains $_ }
    if (@($unpublished).Count -gt 0) { Add-Score "Publishing/Coverage" "WARN" ("{0} label(s) created but NOT published (e.g. {1})." -f @($unpublished).Count, (($unpublished | Select-Object -First 3) -join ", ")) }
    else { Add-Score "Publishing/Coverage" "PASS" "All labels are published by at least one label policy." }
}

# --- Dimension 3: Encryption / protection on higher-tier labels ---
$hiPattern = ($HighTierLabelPattern -join "|")
$hiLabels  = $labelRows | Where-Object { $_.Name -match $hiPattern }
if (@($hiLabels).Count -eq 0) {
    Add-Score "Encryption/Protection" "WARN" "No higher-tier (Confidential/Restricted) label detected to assess encryption on."
} else {
    $noEnc = $hiLabels | Where-Object { $_.Detail -match "Encrypt=off" }
    if (@($noEnc).Count -gt 0) { Add-Score "Encryption/Protection" "FAIL" ("{0} higher-tier label(s) classify but do NOT encrypt (e.g. {1}) — review with compliance." -f @($noEnc).Count, (($noEnc | Select-Object -First 3 | ForEach-Object { $_.Name }) -join ", ")) }
    else { Add-Score "Encryption/Protection" "PASS" "Higher-tier labels apply encryption/protection." }
}

# --- Dimension 4: Auto-labeling (present and its mode) ---
$autoRows = $rows | Where-Object { $_.ArtifactType -eq "AutoLabelPolicy" }
if (@($autoRows).Count -eq 0) {
    Add-Score "Auto-labeling" "WARN" "No auto-labeling policies (or unlicensed) — labeling relies on users. Verify your licensing/tenant."
} else {
    $enabledAuto = $autoRows | Where-Object { $_.Detail -match "Mode=Enable" }
    if (@($enabledAuto).Count -gt 0) { Add-Score "Auto-labeling" "PASS" ("{0} auto-labeling policy(ies); {1} enabled." -f @($autoRows).Count, @($enabledAuto).Count) }
    else { Add-Score "Auto-labeling" "WARN" ("{0} auto-labeling policy(ies) present but all in simulation/test." -f @($autoRows).Count) }
}

# --- Dimension 5: DLP coverage + mode across in-scope workloads ---
$dlpRows = $rows | Where-Object { $_.ArtifactType -eq "DlpPolicy" }
if (@($dlpRows).Count -eq 0) {
    Add-Score "DLP Coverage/Mode" "FAIL" "No DLP policies — no data-loss controls on any workload."
} else {
    $coveredText = ($dlpRows | ForEach-Object { $_.Detail }) -join " "
    $uncovered = $InScopeWorkloads | Where-Object { $coveredText -notmatch [regex]::Escape($_) }
    $allTest = -not ($dlpRows | Where-Object { $_.Detail -match "Mode=Enable" })
    if (@($uncovered).Count -gt 0) { Add-Score "DLP Coverage/Mode" "FAIL" ("In-scope workload(s) with NO DLP coverage: {0}." -f ($uncovered -join ", ")) }
    elseif ($allTest) { Add-Score "DLP Coverage/Mode" "WARN" "DLP policies exist but all are in Test/Disabled — nothing is enforced." }
    else { Add-Score "DLP Coverage/Mode" "PASS" "In-scope workloads have DLP; at least one policy enabled." }
}

# --- Dimension 6: Sensitive information types referenced ---
$sitCsv = ".\IPASSESS-SensitiveInfoTypes-Estate-Discovery.csv"
if (Test-Path $sitCsv) {
    $sitCount = @(Import-Csv $sitCsv).Count
    Add-Score "Sensitive Info Types" "PASS" ("{0} sensitive information type(s) available to reference." -f $sitCount)
} else {
    Add-Score "Sensitive Info Types" "WARN" "SIT inventory not present — re-run Discovery with -IncludeSensitiveTypes."
}

$scores | Export-Csv -Path $OutPath -NoTypeInformation -Encoding UTF8
Write-Host ("`nPosture score written to {0}  (Information Protection - Posture - Score)" -f $OutPath) -ForegroundColor Green

# --- Optional: confirm the simulation pilot is safe (nothing enforced) ---
if ($CheckPilot) {
    Write-Host "`n-- Pilot safety check --" -ForegroundColor Cyan
    try {
        $pilot = Get-AutoSensitivityLabelPolicy -Identity "Information Protection - Pilot - Simulation" -ErrorAction Stop
        if ($pilot.Mode -match "Test") { Write-Host ("  PASS: pilot exists in SIMULATION mode ({0}) — enforces nothing." -f $pilot.Mode) -ForegroundColor Green }
        else { Write-Host ("  ALERT: pilot Mode='{0}' is NOT a simulation mode — this engagement should not enforce. Investigate." -f $pilot.Mode) -ForegroundColor Red }
    } catch {
        Write-Host "  No simulation pilot object found (expected before Step 6, or after rollback)." -ForegroundColor DarkGray
    }
}

$fail = @($scores | Where-Object { $_.Result -eq "FAIL" }).Count
$warn = @($scores | Where-Object { $_.Result -eq "WARN" }).Count
Write-Host ("`nSummary: {0} FAIL, {1} WARN across {2} dimensions. Feed these to IPASSESS-Report.ps1 for the gap register + roadmap." -f $fail, $warn, @($scores).Count) -ForegroundColor Cyan
Write-Host "Baseline targets are a starting default — confirm them with compliance/security before treating the score as final." -ForegroundColor DarkGray
