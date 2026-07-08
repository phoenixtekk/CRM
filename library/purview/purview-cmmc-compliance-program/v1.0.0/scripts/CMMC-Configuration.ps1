<#
.SYNOPSIS
    CMMC-Configuration.ps1 — build the local CMMC action plan / control map / evidence register (default -WhatIf).
.DESCRIPTION
    PURPOSE
        Turns an owner-provided list of improvement actions into the three local tracking artifacts this
        solution maintains — 'CMMC Action Plan - Pilot', 'CMMC Control Map - NIST 800-171' (requirement/
        family -> action -> owner -> evidence), and 'CMMC Evidence - Register' (CSV files). It validates
        the input (owner, target date, NIST 800-171 requirement, evidence source, auto-vs-manual) and,
        only with -Commit, writes the CSVs. It makes NO tenant changes: Compliance Manager has no public
        write API, so assignments and evidence upload happen in the portal, DRIVEN BY these artifacts.
    HOW TO RUN
        Preview (safe, default): powershell -ExecutionPolicy Bypass -File .\CMMC-Configuration.ps1 -InputCsv .\actions.csv
        Write the artifacts:     powershell -ExecutionPolicy Bypass -File .\CMMC-Configuration.ps1 -InputCsv .\actions.csv -Commit -OutDir .\cmmc-artifacts
        Input CSV columns: Requirement,Family,Action,Owner,TargetDate,ImplementationStatus,TestMethod,EvidenceSource
        (TestMethod = Automatic|Manual). With no -InputCsv, a template header is written for you to fill.
    EXPECTED RESULTS
        WhatIf: a validated summary of what WOULD be written (rows, any missing fields), no files.
        -Commit: the three CSV artifacts written to -OutDir. No tenant/portal changes are ever made.
.NOTES
    White-label — Purview Solutions. Default is a dry run; local file writes only with -Commit.
    No cmdlets, no credentials, no tenant writes — Compliance Manager is portal-managed.
#>
[CmdletBinding()] param(
    [string]$InputCsv,
    [string]$OutDir = '.\cmmc-artifacts',
    [switch]$Commit
)
$WhatIf = -not $Commit
$mode = $(if($WhatIf){'WHATIF (preview only — no files written)'}else{'COMMIT (writing local artifacts)'})
Write-Host ("`n=== CMMC configuration artifacts [{0}] ===" -f $mode) -ForegroundColor Cyan

$required = 'Requirement','Family','Action','Owner','TargetDate','ImplementationStatus','TestMethod','EvidenceSource'

# No input: emit a template the operator fills from the portal's improvement actions.
if (-not $InputCsv) {
    Write-Host "`nNo -InputCsv supplied. Provide a CSV with these columns (one row per improvement action):" -ForegroundColor Yellow
    Write-Host ("  {0}" -f ($required -join ',')) -ForegroundColor Gray
    Write-Host "  TestMethod must be 'Automatic' or 'Manual'. Then re-run with -InputCsv .\actions.csv." -ForegroundColor Yellow
    if (-not $WhatIf) {
        if (-not (Test-Path $OutDir)) { New-Item -ItemType Directory -Path $OutDir -Force | Out-Null }
        $tmpl = Join-Path $OutDir 'actions-template.csv'
        ($required -join ',') | Set-Content -Path $tmpl -Encoding UTF8
        Write-Host ("  Template header written: {0}" -f $tmpl) -ForegroundColor Green
    }
    return
}

if (-not (Test-Path $InputCsv)) { Write-Host ("Input CSV not found: {0}" -f $InputCsv) -ForegroundColor Red; exit 1 }
$rows = @(Import-Csv -Path $InputCsv)
Write-Host ("`nLoaded {0} action row(s) from {1}." -f $rows.Count, $InputCsv) -ForegroundColor Cyan

# Validate
$missingCols = @($required | Where-Object { $_ -notin $rows[0].psobject.Properties.Name })
if ($missingCols) { Write-Host ("  Missing required column(s): {0}" -f ($missingCols -join ', ')) -ForegroundColor Red; exit 1 }

$problems = 0
foreach ($r in $rows) {
    foreach ($c in $required) {
        if ([string]::IsNullOrWhiteSpace($r.$c)) { Write-Host ("  ! Row '{0}' missing {1}" -f $r.Action, $c) -ForegroundColor Yellow; $problems++ }
    }
    if ($r.TestMethod -and $r.TestMethod -notin 'Automatic','Manual') { Write-Host ("  ! Row '{0}' TestMethod must be Automatic|Manual (got '{1}')" -f $r.Action, $r.TestMethod) -ForegroundColor Yellow; $problems++ }
}
$auto  = @($rows | Where-Object { $_.TestMethod -eq 'Automatic' }).Count
$man   = @($rows | Where-Object { $_.TestMethod -eq 'Manual' }).Count
$fam   = @($rows | Group-Object Family | Sort-Object Name)
Write-Host ("`n  Actions: {0}  |  Automatic-tested: {1}  |  Manual-evidence: {2}  |  Families covered: {3}" -f $rows.Count, $auto, $man, $fam.Count) -ForegroundColor Cyan
$fam | ForEach-Object { Write-Host ("    {0}: {1} action(s)" -f $_.Name, $_.Count) }
if ($problems) { Write-Host ("`n  {0} field problem(s) found — fix the input before committing." -f $problems) -ForegroundColor Yellow }
else           { Write-Host "`n  Input valid: every action has a requirement, family, owner, date, status, test method, and evidence source." -ForegroundColor Green }

if ($WhatIf) {
    Write-Host "`nPreview only. Re-run with -Commit to write the three artifacts to -OutDir. No tenant changes are ever made." -ForegroundColor Cyan
    Write-Host "Reminder: assign owners and upload evidence in the Purview portal — Compliance Manager has no write API." -ForegroundColor Cyan
    return
}
if ($problems) { Write-Host "`nNot writing artifacts while field problems remain. Fix the input and re-run." -ForegroundColor Yellow; exit 1 }

# Commit: write the three artifacts
if (-not (Test-Path $OutDir)) { New-Item -ItemType Directory -Path $OutDir -Force | Out-Null }
$plan = Join-Path $OutDir 'CMMC-Action-Plan-Pilot.csv'
$map  = Join-Path $OutDir 'CMMC-Control-Map-NIST-800-171.csv'
$evd  = Join-Path $OutDir 'CMMC-Evidence-Register.csv'

$rows | Select-Object Requirement,Family,Action,Owner,TargetDate,ImplementationStatus,TestMethod | Export-Csv -Path $plan -NoTypeInformation
$rows | Select-Object Family,Requirement,Action,Owner,EvidenceSource | Sort-Object Family,Requirement | Export-Csv -Path $map -NoTypeInformation
$rows | Select-Object Requirement,Action,Owner,TestMethod,EvidenceSource | Export-Csv -Path $evd -NoTypeInformation

Write-Host ("`nWrote:`n  {0}`n  {1}`n  {2}" -f $plan, $map, $evd) -ForegroundColor Green
Write-Host "Drive the portal from these: assign each action's owner/status and upload the evidence in Compliance Manager." -ForegroundColor Cyan
