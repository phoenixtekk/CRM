<#
.SYNOPSIS
    CMPMGR-Configuration.ps1 — build the Compliance Manager improvement-action plan + evidence register (SAFE: -WhatIf by default).
.DESCRIPTION
    PURPOSE
        Validates an owner-provided improvement-action list and produces the local tracking artifacts
        that drive the work in the Purview portal: the "CM Action Plan - Pilot" and the
        "CM Evidence - Register" (owner, target date, implementation status, test status, and evidence
        source per action). Compliance Manager is portal-managed and exposes no broad public write API,
        so this tool DOES NOT change the tenant — it structures the plan; assignment and evidence upload
        are performed in the portal from these artifacts. Safe by default: -WhatIf only describes; it
        writes the register files only when -Commit is supplied.
    HOW TO RUN
        # Dry-run — describe the plan it would write (no files created):
        powershell -ExecutionPolicy Bypass -File .\CMPMGR-Configuration.ps1 -InputCsv .\actions.csv -WhatIf
        # Apply — write the plan + evidence register locally:
        powershell -ExecutionPolicy Bypass -File .\CMPMGR-Configuration.ps1 -InputCsv .\actions.csv -OutDir .\out -Commit
        InputCsv columns (header row required): Action,Owner,TargetDate,ImplementationStatus,TestStatus,EvidenceSource,AutomaticTesting
        No tenant connection is required; this is a local planning tool. No credentials are stored.
    EXPECTED RESULTS
        -WhatIf: a validation summary and a preview of the rows that WOULD be written; no files.
        -Commit: writes CM-Action-Plan-Pilot.csv and CM-Evidence-Register.csv to -OutDir and prints a
        summary (counts by implementation/test status, actions missing an owner/date/evidence).
.NOTES
    Purview — Microsoft Purview Compliance Manager Implementation. Local planning tool; makes NO tenant
    changes. Assignments and evidence upload happen in the Purview portal (Compliance Manager).
#>
[CmdletBinding()]
param(
    [Parameter(Mandatory)][string]$InputCsv,
    [string]$OutDir = '.',
    [switch]$Commit,
    [switch]$WhatIf
)

if (-not $Commit) { $WhatIf = $true }

if (-not (Test-Path -LiteralPath $InputCsv)) {
    Write-Error "InputCsv not found: $InputCsv"
    return
}

$required = 'Action','Owner','TargetDate','ImplementationStatus','TestStatus','EvidenceSource','AutomaticTesting'
$validImpl = 'Not implemented','Implemented','Alternative implementation','Planned','Out of scope'
$validTest = 'Not assessed','Passed','Failed - low risk','Failed - medium risk','Failed - high risk'

try { $rows = @(Import-Csv -LiteralPath $InputCsv) } catch { Write-Error "Could not read CSV: $($_.Exception.Message)"; return }
if ($rows.Count -eq 0) { Write-Warning 'InputCsv has no data rows.'; return }

$cols = ($rows[0].psobject.Properties.Name)
$missingCols = $required | Where-Object { $cols -notcontains $_ }
if ($missingCols) { Write-Error ("InputCsv missing required column(s): {0}" -f ($missingCols -join ', ')); return }

# --- Validate rows ---
$issues = @()
$i = 0
foreach ($r in $rows) {
    $i++
    if ([string]::IsNullOrWhiteSpace($r.Action))        { $issues += "Row ${i}: Action is blank" }
    if ([string]::IsNullOrWhiteSpace($r.Owner))         { $issues += "Row $i ('$($r.Action)'): no Owner" }
    if ([string]::IsNullOrWhiteSpace($r.TargetDate))    { $issues += "Row $i ('$($r.Action)'): no TargetDate" }
    else { [datetime]$null = 0; if (-not [datetime]::TryParse($r.TargetDate, [ref]([datetime]::MinValue))) { $issues += "Row $i ('$($r.Action)'): TargetDate '$($r.TargetDate)' is not a date" } }
    if ($r.ImplementationStatus -and ($validImpl -notcontains $r.ImplementationStatus)) { $issues += "Row $i ('$($r.Action)'): ImplementationStatus '$($r.ImplementationStatus)' not one of: $($validImpl -join ', ')" }
    if ($r.TestStatus -and ($validTest -notcontains $r.TestStatus))                     { $issues += "Row $i ('$($r.Action)'): TestStatus '$($r.TestStatus)' not one of: $($validTest -join ', ')" }
    if ([string]::IsNullOrWhiteSpace($r.EvidenceSource)) { $issues += "Row $i ('$($r.Action)'): no EvidenceSource" }
}

Write-Host ("=== CM Action Plan - Pilot: validating {0} action(s) ===" -f $rows.Count) -ForegroundColor Cyan
if ($issues) {
    Write-Host ("  {0} validation issue(s):" -f $issues.Count) -ForegroundColor Yellow
    $issues | ForEach-Object { Write-Host ("    - {0}" -f $_) -ForegroundColor Yellow }
} else {
    Write-Host '  [OK] All rows have an owner, a valid target date, valid status values, and an evidence source.' -ForegroundColor Green
}

# --- Build the register objects ---
$plan = $rows | ForEach-Object {
    [pscustomobject]@{
        Action               = $_.Action
        Owner                = $_.Owner
        TargetDate           = $_.TargetDate
        ImplementationStatus = if ($_.ImplementationStatus) { $_.ImplementationStatus } else { 'Not implemented' }
        TestStatus           = if ($_.TestStatus) { $_.TestStatus } else { 'Not assessed' }
        EvidenceSource       = $_.EvidenceSource
        AutomaticTesting     = $_.AutomaticTesting
    }
}

# --- Summary ---
Write-Host ''
Write-Host '=== Plan summary ===' -ForegroundColor Cyan
$plan | Group-Object ImplementationStatus | Sort-Object Name | ForEach-Object { Write-Host ("  Implementation - {0}: {1}" -f $_.Name, $_.Count) }
$plan | Group-Object TestStatus           | Sort-Object Name | ForEach-Object { Write-Host ("  Test - {0}: {1}" -f $_.Name, $_.Count) }
$auto = @($plan | Where-Object { $_.AutomaticTesting -match '^(y|yes|true|1)$' }).Count
Write-Host ("  Flagged for automatic testing: {0} / {1}" -f $auto, $plan.Count)

if ($WhatIf) {
    Write-Host ''
    Write-Host '[WhatIf] No files written. The following artifacts WOULD be created with -Commit:' -ForegroundColor Yellow
    Write-Host ("  {0}\CM-Action-Plan-Pilot.csv   ({1} rows)" -f $OutDir, $plan.Count) -ForegroundColor Yellow
    Write-Host ("  {0}\CM-Evidence-Register.csv    ({1} rows)" -f $OutDir, $plan.Count) -ForegroundColor Yellow
    Write-Host 'Re-run with -Commit to write them. This tool makes NO tenant changes; assign actions and upload evidence in the Purview portal.' -ForegroundColor Yellow
    return
}

# --- Commit: write local files ---
if (-not (Test-Path -LiteralPath $OutDir)) { New-Item -ItemType Directory -Path $OutDir -Force | Out-Null }
$planPath = Join-Path $OutDir 'CM-Action-Plan-Pilot.csv'
$evidPath = Join-Path $OutDir 'CM-Evidence-Register.csv'
$plan | Export-Csv -LiteralPath $planPath -NoTypeInformation -Encoding UTF8
$plan | Select-Object Action, Owner, EvidenceSource, TestStatus, TargetDate | Export-Csv -LiteralPath $evidPath -NoTypeInformation -Encoding UTF8
Write-Host ''
Write-Host ("[Commit] CM Action Plan - Pilot written: {0}" -f $planPath) -ForegroundColor Green
Write-Host ("[Commit] CM Evidence - Register written: {0}" -f $evidPath) -ForegroundColor Green
Write-Host 'Next: assign each action to its owner and upload evidence in the Purview portal (Compliance Manager). This tool made NO tenant changes.' -ForegroundColor Cyan
