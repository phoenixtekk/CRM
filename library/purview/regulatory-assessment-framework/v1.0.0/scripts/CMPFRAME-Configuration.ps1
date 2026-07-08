<#
.SYNOPSIS
    CMPFRAME-Configuration.ps1 — crosswalk & shared-control-plan builder (safe: -WhatIf by default; no tenant writes).
.DESCRIPTION
    PURPOSE
        Validates the canonical shared-control set and the control-to-regulation crosswalk from an
        owner-provided input file, and (with -Commit) writes the local tracking artifacts that drive
        the framework in the portal: "RAF Crosswalk - Register", "RAF Action Plan - Shared", and
        "RAF Evidence - Register". Makes NO tenant changes — Compliance Manager has no broad public
        write API, so assessment/group creation and evidence upload happen in the Purview portal,
        driven by these artifacts. This tool structures the map-once/assess-many plan; it does not push
        it to the tenant.
    HOW TO RUN
        # Dry-run (default): validate the crosswalk and describe what would be written
        powershell -ExecutionPolicy Bypass -File .\CMPFRAME-Configuration.ps1 -InputPath .\raf-controls.csv
        # Commit: write the local register/plan files
        powershell -ExecutionPolicy Bypass -File .\CMPFRAME-Configuration.ps1 -InputPath .\raf-controls.csv -OutDir .\out -Commit
        Input is a CSV with headers: Control, Regulations, Owner, TargetDate, EvidenceSource, AutoTest
        (Regulations = a semicolon-separated list, e.g. "NIST 800-53;ISO 27001;HIPAA"; AutoTest = Yes/No).
        No connection is required to validate; this tool only reads the local input and writes local files.
    EXPECTED RESULTS
        Dry-run: a validation report (orphaned controls, unmapped regulations, missing owners/dates,
        the shared-control leverage count per control) and a description of the files that WOULD be
        written. -Commit: the three artifact files written to -OutDir. Nothing is sent to the tenant.
.NOTES
    Purview — Regulatory Assessment Framework. Safe-by-default (-WhatIf). No credentials are stored;
    no tenant changes are made. Regulatory applicability of each control mapping is a compliance/legal
    determination — this tool validates structure, not correctness of the mapping.
#>
[CmdletBinding()]
param(
    [Parameter(Mandatory = $true)][string]$InputPath,
    [string]$OutDir = '.',
    [switch]$Commit,
    [switch]$WhatIf
)

if (-not (Test-Path $InputPath)) { Write-Error "Input file not found: $InputPath"; return }
$dryRun = -not $Commit   # -WhatIf is the default posture; only -Commit writes files

try {
    $rows = @(Import-Csv -Path $InputPath -ErrorAction Stop)
} catch {
    Write-Error "Could not read input CSV: $($_.Exception.Message)"; return
}
if ($rows.Count -eq 0) { Write-Error 'Input CSV has no rows.'; return }

$required = @('Control','Regulations','Owner','TargetDate','EvidenceSource')
$missingCols = $required | Where-Object { $_ -notin $rows[0].PSObject.Properties.Name }
if ($missingCols) { Write-Error ("Input CSV missing required column(s): {0}" -f ($missingCols -join ', ')); return }

Write-Host '=== RAF Crosswalk - Register (validation) ===' -ForegroundColor Cyan

$crosswalk = @()
$issues    = @()
$regCoverage = @{}   # regulation -> list of controls

foreach ($r in $rows) {
    $control = ($r.Control).Trim()
    if (-not $control) { $issues += 'A row has an empty Control name.'; continue }
    $regs = @()
    if ($r.Regulations) { $regs = @($r.Regulations -split ';' | ForEach-Object { $_.Trim() } | Where-Object { $_ }) }

    if ($regs.Count -eq 0) { $issues += ("[orphan] Control '{0}' maps to no regulation." -f $control) }
    if (-not $r.Owner)     { $issues += ("[owner]  Control '{0}' has no owner." -f $control) }
    if (-not $r.TargetDate){ $issues += ("[date]   Control '{0}' has no target date." -f $control) }
    if (-not $r.EvidenceSource) { $issues += ("[evid]   Control '{0}' has no evidence source." -f $control) }

    foreach ($reg in $regs) {
        if (-not $regCoverage.ContainsKey($reg)) { $regCoverage[$reg] = @() }
        $regCoverage[$reg] += $control
    }

    $auto = if ($r.PSObject.Properties.Name -contains 'AutoTest' -and $r.AutoTest -match '^(y|yes|true|1)$') { $true } else { $false }
    $crosswalk += [pscustomobject]@{
        Control        = $control
        Regulations    = ($regs -join '; ')
        MappedCount    = $regs.Count       # shared-control leverage = regulations scored per control
        Owner          = $r.Owner
        TargetDate     = $r.TargetDate
        EvidenceSource = $r.EvidenceSource
        AutoTest       = $auto
    }
}

# --- Report the leverage (map once, assess many) ---
Write-Host ("Controls: {0}   Regulations covered: {1}" -f $crosswalk.Count, $regCoverage.Keys.Count) -ForegroundColor Cyan
Write-Host ''
Write-Host 'Shared-control leverage (regulations scored per control):' -ForegroundColor Cyan
foreach ($c in ($crosswalk | Sort-Object MappedCount -Descending)) {
    $tag = if ($c.MappedCount -ge 2) { 'shared' } else { 'single' }
    Write-Host ("  [{0}] {1}  ->  {2} regulation(s): {3}" -f $tag, $c.Control, $c.MappedCount, $c.Regulations)
}

Write-Host ''
Write-Host 'Per-regulation coverage (controls mapped):' -ForegroundColor Cyan
foreach ($reg in ($regCoverage.Keys | Sort-Object)) {
    Write-Host ("  {0}: {1} control(s)" -f $reg, $regCoverage[$reg].Count)
}

# --- Validation issues ---
Write-Host ''
if ($issues.Count -gt 0) {
    Write-Host ("[VALIDATION] {0} issue(s) found — resolve with the control owners before committing:" -f $issues.Count) -ForegroundColor Yellow
    $issues | ForEach-Object { Write-Host ("  - {0}" -f $_) -ForegroundColor Yellow }
} else {
    Write-Host '  [OK] Crosswalk is structurally complete: every control is owned, dated, evidenced, and mapped.' -ForegroundColor Green
}

# --- Write artifacts (only with -Commit) ---
Write-Host ''
if ($dryRun -or $WhatIf) {
    Write-Host '[WhatIf] Dry-run — no files written. Re-run with -Commit to write:' -ForegroundColor DarkCyan
    Write-Host ("         {0}\RAF-Crosswalk-Register.csv" -f $OutDir) -ForegroundColor DarkCyan
    Write-Host ("         {0}\RAF-Action-Plan-Shared.csv" -f $OutDir) -ForegroundColor DarkCyan
    Write-Host ("         {0}\RAF-Evidence-Register.csv" -f $OutDir) -ForegroundColor DarkCyan
    Write-Host '         (No tenant changes are ever made — assessment/group creation and evidence upload are done in the Purview portal.)' -ForegroundColor DarkGray
} else {
    if ($issues.Count -gt 0) { Write-Warning 'Committing with unresolved validation issues — review the artifacts before using them in the portal.' }
    if (-not (Test-Path $OutDir)) { New-Item -ItemType Directory -Path $OutDir -Force | Out-Null }
    try {
        $crosswalk | Export-Csv -Path (Join-Path $OutDir 'RAF-Crosswalk-Register.csv') -NoTypeInformation -Encoding UTF8
        $crosswalk | Select-Object Control, Owner, TargetDate, @{n='Status';e={'Not implemented'}}, AutoTest |
            Export-Csv -Path (Join-Path $OutDir 'RAF-Action-Plan-Shared.csv') -NoTypeInformation -Encoding UTF8
        $crosswalk | Select-Object Control, Owner, EvidenceSource, @{n='TestStatus';e={'Not assessed'}}, @{n='TestDate';e={''}} |
            Export-Csv -Path (Join-Path $OutDir 'RAF-Evidence-Register.csv') -NoTypeInformation -Encoding UTF8
        Write-Host ("Wrote RAF-Crosswalk-Register.csv, RAF-Action-Plan-Shared.csv, RAF-Evidence-Register.csv to {0}" -f $OutDir) -ForegroundColor Green
        Write-Host 'Next: create the assessment group and pilot assessment in the Purview portal, assign the actions to owners, and attach evidence — driven by these files.' -ForegroundColor Cyan
    } catch {
        Write-Error "Could not write artifacts: $($_.Exception.Message)"
    }
}
