<#
.SYNOPSIS
    CMPHIPAA-Configuration.ps1 — build/validate the local HIPAA action-plan, evidence-register, control-map,
    and scope artifacts (-WhatIf by default; writes local files with -Commit; NO tenant changes).
.DESCRIPTION
    PURPOSE
        Structures the program's tracking artifacts from an owner-provided action list: validates each row
        (action, mapped HIPAA safeguard, owner, target date, implementation status, evidence source,
        auto-vs-manual) and, with -Commit, writes the local HIPAA Action Plan - Pilot, HIPAA Evidence -
        Register, HIPAA Control Map - Safeguards, and HIPAA Scope - Record CSV files. Compliance Manager has
        no public write API, so assessment/action assignment and evidence upload happen in the Purview
        portal — driven by these artifacts. This script makes NO tenant changes.
    HOW TO RUN
        powershell -ExecutionPolicy Bypass -File .\CMPHIPAA-Configuration.ps1 -InputCsv .\actions.csv
        (dry-run; validate + preview). Add -Commit to write the artifact files:
        powershell -ExecutionPolicy Bypass -File .\CMPHIPAA-Configuration.ps1 -InputCsv .\actions.csv -Commit
        PowerShell 5.1+ / 7+. No connection or credentials required — operates on local CSV only.
    EXPECTED RESULTS
        Dry-run prints validation results and the artifacts it WOULD write. With -Commit, four CSV files are
        written to -OutDir. Any row missing an owner, target date, mapped safeguard, or evidence source is
        reported as a FAIL and (in -Commit) excluded until fixed.
.NOTES
    Purview category — HIPAA compliance program. Local-only artifact builder; makes no tenant changes and
    embeds no credentials. Applicability/adequacy and the addressable-spec choices remain
    compliance/privacy/legal determinations — this only structures the evidence.
#>
[CmdletBinding()]
param(
    [string]$InputCsv,                                # owner-provided action list (see expected columns below)
    [string]$OutDir = (Join-Path (Get-Location) 'HIPAA-artifacts'),
    [switch]$Commit                                  # write files; without it, dry-run only
)

$ErrorActionPreference = 'Stop'
function Ok($m){ Write-Host $m -ForegroundColor Green }
function Warn($m){ Write-Host $m -ForegroundColor Yellow }
function Info($m){ Write-Host $m -ForegroundColor Gray }
function Fail($m){ Write-Host $m -ForegroundColor Red }

# Expected input columns (owner-provided). Extra columns are preserved.
$required = @('Action','Safeguard','Owner','TargetDate','ImplementationStatus','EvidenceSource','TestMode')

if (-not $InputCsv) {
    Warn "No -InputCsv supplied. Provide an owner-authored CSV with columns:"
    Info ("  " + ($required -join ', '))
    Info "  Safeguard example values: 164.312(b) Audit controls; 164.312(a) Access control; 164.308(a)(5) Training"
    Info "  TestMode: Auto  (Compliance Manager auto-tests) | Manual (evidence uploaded in portal)"
    Info "Re-run with -InputCsv .\actions.csv (dry-run), then add -Commit to write artifacts."
    return
}
if (-not (Test-Path $InputCsv)) { Fail "Input CSV not found: $InputCsv"; return }

$rows = @(Import-Csv -Path $InputCsv)
if ($rows.Count -eq 0) { Warn "Input CSV has no rows."; return }

# --- Validate ---
Write-Host "`n=== Validating action list ($($rows.Count) rows) ===" -ForegroundColor Cyan
$valid = New-Object System.Collections.Generic.List[object]
$badCount = 0
$rowNum = 1
foreach ($r in $rows) {
    $missing = @()
    foreach ($c in $required) {
        if (-not ($r.PSObject.Properties.Name -contains $c) -or [string]::IsNullOrWhiteSpace($r.$c)) { $missing += $c }
    }
    # TargetDate must parse
    $dateOk = $true
    if (-not ($missing -contains 'TargetDate')) {
        [datetime]$parsed = [datetime]::MinValue
        if (-not [datetime]::TryParse($r.TargetDate, [ref]$parsed)) { $dateOk = $false }
    }
    if ($missing.Count -gt 0 -or -not $dateOk) {
        $badCount++
        $reason = @()
        if ($missing.Count -gt 0) { $reason += ("missing: " + ($missing -join ', ')) }
        if (-not $dateOk) { $reason += "TargetDate not a valid date" }
        Fail ("  Row {0} [{1}] FAIL — {2}" -f $rowNum, $r.Action, ($reason -join '; '))
    } else {
        $valid.Add($r)
        Ok ("  Row {0} [{1}] OK — {2} / {3} / {4}" -f $rowNum, $r.Action, $r.Safeguard, $r.Owner, $r.TestMode)
    }
    $rowNum++
}
Info ("Valid rows: {0} / {1}  (invalid: {2})" -f $valid.Count, $rows.Count, $badCount)
if ($badCount -gt 0) { Warn "Fix the FAIL rows (owner, target date, mapped safeguard, evidence source are mandatory) before relying on the artifacts." }

# --- Build artifact tables in memory ---
$actionPlan = $valid | Select-Object Action, Safeguard, Owner, TargetDate, ImplementationStatus, TestMode, EvidenceSource
$evidence   = $valid | Select-Object Action, Safeguard, Owner,
                        @{n='EvidenceSource';e={$_.EvidenceSource}},
                        @{n='TestMode';e={$_.TestMode}},
                        @{n='TestStatus';e={'Not assessed'}},
                        @{n='TestDate';e={''}}
$controlMap = $valid | Select-Object Safeguard, Action, Owner |
                        Sort-Object Safeguard, Action
$scope      = $valid | Group-Object Safeguard | Select-Object @{n='Safeguard';e={$_.Name}},
                        @{n='ActionCount';e={$_.Count}}

if (-not $Commit) {
    Write-Host "`n=== DRY-RUN (no files written) ===" -ForegroundColor Cyan
    Info "Would write to: $OutDir"
    Info "  HIPAA Action Plan - Pilot.csv        ($($actionPlan.Count) rows)"
    Info "  HIPAA Evidence - Register.csv        ($($evidence.Count) rows)"
    Info "  HIPAA Control Map - Safeguards.csv   ($($controlMap.Count) rows)"
    Info "  HIPAA Scope - Record.csv             ($($scope.Count) safeguard groups)"
    Warn "Add -Commit to write these files. Assignment + evidence upload still happen in the Purview portal."
    return
}

# --- Commit: write local files ---
if (-not (Test-Path $OutDir)) { New-Item -ItemType Directory -Path $OutDir -Force | Out-Null }
$actionPlan | Export-Csv -Path (Join-Path $OutDir 'HIPAA Action Plan - Pilot.csv')      -NoTypeInformation -Encoding UTF8
$evidence   | Export-Csv -Path (Join-Path $OutDir 'HIPAA Evidence - Register.csv')      -NoTypeInformation -Encoding UTF8
$controlMap | Export-Csv -Path (Join-Path $OutDir 'HIPAA Control Map - Safeguards.csv') -NoTypeInformation -Encoding UTF8
$scope      | Export-Csv -Path (Join-Path $OutDir 'HIPAA Scope - Record.csv')           -NoTypeInformation -Encoding UTF8
Ok "Wrote 4 artifact files to $OutDir"
Warn "These are local tracking artifacts. Create the assessment, assign actions, and upload evidence in the Purview portal — Compliance Manager has no public write API."
