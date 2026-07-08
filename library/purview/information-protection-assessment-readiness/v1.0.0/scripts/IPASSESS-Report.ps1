<#
.SYNOPSIS
    IPASSESS-Report.ps1 — build the gap register and the prioritized information-protection roadmap + scorecard (read-only).
.DESCRIPTION
    PURPOSE
        Read-only reporting for the Information Protection Assessment. Turns the scored posture
        (IPASSESS-Validation.ps1 output) into two deliverables: with -Section GapRegister, a gap register
        (one row per gap with severity, recommended action, effort, and owner-function); with
        -Section Roadmap, a ranked roadmap that sequences the gaps into quick wins vs. strategic work plus
        a one-page posture scorecard. Produces files only — changes nothing in the tenant, and makes no
        determination about whether a gap must be closed (that is compliance/records/legal's call).
    HOW TO RUN
        PowerShell 5.1+ or 7+ (no S&C session required — operates on the score CSV).
        Build the gap register:
          .\IPASSESS-Report.ps1 -Section GapRegister -ScoreCsv .\IPASSESS-PostureScore-Estate-Validate.csv
        Build the ranked roadmap + scorecard:
          .\IPASSESS-Report.ps1 -Section Roadmap -ScoreCsv .\IPASSESS-PostureScore-Estate-Validate.csv
    EXPECTED RESULTS
        GapRegister -> .\IPASSESS-Gaps-Register.csv (Information Protection - Gaps - Register).
        Roadmap     -> .\IPASSESS-Roadmap-Scorecard.csv (Information Protection - Roadmap - Scorecard)
        with quick-win vs. strategic sequencing and a printed per-dimension scorecard. Every gap row
        carries an owner-function so determinations are attributed, not decided.
.NOTES
    White-label Microsoft Purview tooling. Read-only. No credentials stored. The severity/effort mapping
    is a starting default to refine with stakeholders; whether to act on a gap remains a
    compliance/records/privacy/legal determination. No cmdlets invented.
#>
[CmdletBinding()]
param(
    [Parameter(Mandatory = $true)]
    [ValidateSet("GapRegister","Roadmap")]
    [string]$Section,

    [string]$ScoreCsv        = ".\IPASSESS-PostureScore-Estate-Validate.csv",
    [string]$GapOutPath      = ".\IPASSESS-Gaps-Register.csv",
    [string]$RoadmapOutPath  = ".\IPASSESS-Roadmap-Scorecard.csv"
)

$ErrorActionPreference = "Stop"
Write-Host "=== IPASSESS Report — Section=$Section (read-only) ===" -ForegroundColor Cyan

if (-not (Test-Path $ScoreCsv)) {
    Write-Host "Score CSV not found: $ScoreCsv — run IPASSESS-Validation.ps1 first." -ForegroundColor Red
    return
}
$scores = Import-Csv -Path $ScoreCsv

# --- Baseline mapping: dimension/result -> recommended action, effort, owner-function ---
function Get-GapMeta([string]$dimension, [string]$result) {
    $sev = switch ($result) { "FAIL" { "High" } "WARN" { "Medium" } default { "None" } }
    switch ($dimension) {
        "Taxonomy"              { return @{ Severity=$sev; Action="Define/enable a coherent sensitivity-label taxonomy"; Effort="Medium"; Owner="Compliance + Security" } }
        "Publishing/Coverage"   { return @{ Severity=$sev; Action="Publish existing labels to the right users/locations via a label policy"; Effort="Low"; Owner="Security" } }
        "Encryption/Protection" { return @{ Severity=$sev; Action="Apply encryption/rights protection to higher-tier labels (review scope with compliance)"; Effort="Medium"; Owner="Compliance + Security" } }
        "Auto-labeling"         { return @{ Severity=$sev; Action="Stand up auto-labeling in SIMULATION, validate, then enable (E5 — verify licensing)"; Effort="High"; Owner="Security" } }
        "DLP Coverage/Mode"     { return @{ Severity=$sev; Action="Extend DLP to uncovered in-scope workloads; move Test policies toward pilot then enforce"; Effort="High"; Owner="Compliance + Security" } }
        "Sensitive Info Types"  { return @{ Severity=$sev; Action="Confirm built-in SITs and build custom SITs for org-specific data"; Effort="Medium"; Owner="Compliance" } }
        default                 { return @{ Severity=$sev; Action="Review finding"; Effort="Medium"; Owner="Security" } }
    }
}

# Build the gap rows (only WARN/FAIL become gaps; PASS is recorded in the scorecard)
$gaps = [System.Collections.Generic.List[object]]::new()
foreach ($s in $scores) {
    if ($s.Result -in @("WARN","FAIL")) {
        $m = Get-GapMeta $s.Dimension $s.Result
        $gaps.Add([pscustomobject]@{
            Dimension        = $s.Dimension
            Severity         = $m.Severity
            Finding          = $s.Finding
            RecommendedAction= $m.Action
            Effort           = $m.Effort
            OwnerFunction    = $m.Owner
        })
    }
}

if ($Section -eq "GapRegister") {
    $gaps | Export-Csv -Path $GapOutPath -NoTypeInformation -Encoding UTF8
    Write-Host ("`nGap register written to {0}  (Information Protection - Gaps - Register): {1} gap(s)." -f $GapOutPath, @($gaps).Count) -ForegroundColor Green
    Write-Host "Confirm each gap with the named owner-function. Determinations (must-fix for a regulation) are attributed, not decided here." -ForegroundColor DarkGray
    return
}

# --- Roadmap: rank gaps into quick wins vs strategic (value/effort), print the scorecard ---
$sevRank    = @{ "High" = 0; "Medium" = 1; "None" = 2 }
$effortRank = @{ "Low" = 0; "Medium" = 1; "High" = 2 }
$ranked = $gaps |
    Sort-Object @{ Expression = { $sevRank[$_.Severity] } }, @{ Expression = { $effortRank[$_.Effort] } } |
    ForEach-Object {
        $lane = if ($_.Effort -eq "Low" -or ($_.Severity -eq "High" -and $_.Effort -ne "High")) { "Quick win" } else { "Strategic" }
        [pscustomobject]@{
            Priority         = 0    # set below
            Lane             = $lane
            Dimension        = $_.Dimension
            Severity         = $_.Severity
            Effort           = $_.Effort
            RecommendedAction= $_.RecommendedAction
            OwnerFunction    = $_.OwnerFunction
            Finding          = $_.Finding
        }
    }
$i = 1; foreach ($r in $ranked) { $r.Priority = $i; $i++ }
$ranked | Export-Csv -Path $RoadmapOutPath -NoTypeInformation -Encoding UTF8

Write-Host ("`nRoadmap written to {0}  (Information Protection - Roadmap - Scorecard): {1} item(s)." -f $RoadmapOutPath, @($ranked).Count) -ForegroundColor Green

# Printed one-page posture scorecard (PASS/WARN/FAIL per dimension)
Write-Host "`n-- Posture scorecard (per dimension) --" -ForegroundColor Cyan
foreach ($s in $scores) {
    $col = switch ($s.Result) { "PASS" { "Green" } "WARN" { "Yellow" } "FAIL" { "Red" } default { "Gray" } }
    Write-Host ("  {0,-22}: {1}" -f $s.Dimension, $s.Result) -ForegroundColor $col
}
$qw = @($ranked | Where-Object { $_.Lane -eq "Quick win" }).Count
$st = @($ranked | Where-Object { $_.Lane -eq "Strategic" }).Count
Write-Host ("`nSequence: {0} quick win(s) first, then {1} strategic item(s). Present this scorecard to the accountable owners." -f $qw, $st) -ForegroundColor Cyan
Write-Host "Enforcement/expansion of any item is change-controlled follow-on work, not this assessment." -ForegroundColor DarkGray
