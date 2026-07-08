<#
.SYNOPSIS
    OPSTRAIN-CompetencyReport.ps1 — roll the lab validation results and each trainee's TRAIN- objects into one competency/progress report (read-only).
.DESCRIPTION
    PURPOSE
        Reporting for the training curriculum. Reads the validation output produced by
        OPSTRAIN-LabValidate.ps1 (default .\OPSTRAIN-Validation.csv) and inventories the TRAIN- objects a
        trainee created (label, label policy, DLP-sim policy, retention policy, auto-labeling-sim policy)
        from Security & Compliance PowerShell, then rolls both into a single competency report: per-lab
        PASS/FAIL, the object that evidences it, and an overall trained/not-yet signal. Read-only — makes
        no changes. This is the EVIDENCE the team is trained; it does not credit competency itself (that
        is the trainer/owner's determination).
    HOW TO RUN
        PowerShell 5.1+ or 7+ with Security & Compliance PowerShell (Connect-IPPSSession):
          Connect-IPPSSession
          .\OPSTRAIN-LabValidate.ps1 -Lab All      # run FIRST - produces OPSTRAIN-Validation.csv
          .\OPSTRAIN-CompetencyReport.ps1
          .\OPSTRAIN-CompetencyReport.ps1 -Trainee "jdoe" -ValidationCsv .\OPSTRAIN-Validation.csv -OutPath .\OPSTRAIN-Competency.csv
    EXPECTED RESULTS
        A per-lab competency table (lab, expected TRAIN- object, exists?, validation status) and an overall
        summary written to .\OPSTRAIN-Competency.csv. If the validation CSV is missing, the report says so
        and tells you to run OPSTRAIN-LabValidate.ps1 first (an empty report means validation was not run).
        Nothing is modified.
.NOTES
    White-label Microsoft Purview training tooling. Read-only. No credentials stored. Cmdlets are standard
    Security & Compliance PowerShell; none are invented. Object names default to the TRAIN- convention used
    in the Implementation Guide — override with the parameters if you named yours differently. Crediting a
    competency is a trainer/owner determination; this script only produces the evidence.
#>
[CmdletBinding()]
param(
    [string]$Trainee         = "",
    [string]$ValidationCsv   = ".\OPSTRAIN-Validation.csv",
    [string]$LabelName       = "TRAIN-Label-Confidential",
    [string]$LabelPolicyName = "TRAIN-LabelPolicy-Pilot",
    [string]$DlpPolicyName   = "TRAIN-DLP-PII-Sim",
    [string]$RetentionName   = "TRAIN-Retention-Pilot",
    [string]$AutoLabelName   = "TRAIN-AutoLabel-Sim",
    [string]$OutPath         = ".\OPSTRAIN-Competency.csv"
)

Write-Host "=== OPSTRAIN CompetencyReport (read-only) ===" -ForegroundColor Cyan
if ($Trainee) { Write-Host "Trainee: $Trainee" -ForegroundColor Cyan }

# --- Load validation results (run OPSTRAIN-LabValidate.ps1 first) ---
$validation = @{}
if (Test-Path $ValidationCsv) {
    try {
        Import-Csv -Path $ValidationCsv | ForEach-Object { $validation[$_.Lab] = $_.Status }
        Write-Host ("Loaded validation from {0} ({1} lab result(s))." -f $ValidationCsv, $validation.Count) -ForegroundColor Green
    } catch {
        Write-Host ("Could not read {0}: {1}" -f $ValidationCsv, $_.Exception.Message) -ForegroundColor Yellow
    }
} else {
    Write-Host ("Validation CSV '{0}' not found — run OPSTRAIN-LabValidate.ps1 -Lab All first." -f $ValidationCsv) -ForegroundColor Yellow
}

# --- Connect (read-only) to inventory TRAIN- objects ---
$connected = $true
try { Get-Label -ErrorAction Stop | Out-Null }
catch { Write-Host "Not connected to Security & Compliance PowerShell. Run Connect-IPPSSession first (GR §3)." -ForegroundColor Yellow; $connected = $false }

function Test-Object([scriptblock]$get) {
    if (-not $connected) { return $null }
    try { $o = & $get; return [bool]$o } catch { return $null }
}

# lab -> (expected object, existence test)
$labs = @(
    [pscustomobject]@{ Lab="Labels";    Object=$LabelPolicyName; Exists=(Test-Object { Get-LabelPolicy -ErrorAction Stop | Where-Object Name -eq $LabelPolicyName }) }
    [pscustomobject]@{ Lab="DLP";       Object=$DlpPolicyName;   Exists=(Test-Object { Get-DlpCompliancePolicy -ErrorAction Stop | Where-Object Name -eq $DlpPolicyName }) }
    [pscustomobject]@{ Lab="Retention"; Object=$RetentionName;   Exists=(Test-Object { Get-RetentionCompliancePolicy -ErrorAction Stop | Where-Object Name -eq $RetentionName }) }
    [pscustomobject]@{ Lab="AutoLabel"; Object=$AutoLabelName;   Exists=(Test-Object { Get-AutoSensitivityLabelPolicy -ErrorAction Stop | Where-Object Name -eq $AutoLabelName }) }
    [pscustomobject]@{ Lab="Audit";     Object="TRAIN-Audit-Search"; Exists=$null }  # Audit is a search action, not a persistent object
)

$rows = [System.Collections.Generic.List[object]]::new()
foreach ($l in $labs) {
    $status = if ($validation.ContainsKey($l.Lab)) { $validation[$l.Lab] } else { "NOT-VALIDATED" }
    $existsText = switch ($l.Exists) { $true { "yes" } $false { "no" } default { "n/a" } }
    $rows.Add([pscustomobject]@{
        Trainee          = $Trainee
        Lab              = $l.Lab
        ExpectedObject   = $l.Object
        ObjectExists     = $existsText
        ValidationStatus = $status
    })
    $col = switch ($status) { "PASS" { "Green" } "FAIL" { "Red" } "NOT-VALIDATED" { "Yellow" } default { "Gray" } }
    Write-Host ("  {0,-10} object={1,-28} exists={2,-4} validation={3}" -f $l.Lab, $l.Object, $existsText, $status) -ForegroundColor $col
}

$rows | Export-Csv -Path $OutPath -NoTypeInformation -Encoding UTF8

$passed = @($rows | Where-Object ValidationStatus -eq "PASS").Count
$failed = @($rows | Where-Object ValidationStatus -eq "FAIL").Count
$pending = @($rows | Where-Object ValidationStatus -eq "NOT-VALIDATED").Count
$trained = ($failed -eq 0 -and $pending -eq 0 -and $passed -gt 0)

Write-Host ("`nCompetency report written to {0}  (PASS={1}, FAIL={2}, NOT-VALIDATED={3})" -f $OutPath, $passed, $failed, $pending) -ForegroundColor Green
if ($trained) {
    Write-Host "Overall signal: TRAINED (all attempted labs validated PASS) — trainer confirms/credits competency." -ForegroundColor Green
} else {
    Write-Host "Overall signal: NOT YET — resolve FAILs and run OPSTRAIN-LabValidate.ps1 for NOT-VALIDATED labs, then re-report." -ForegroundColor Yellow
}
Write-Host "NOTE: crediting competency is the trainer/owner's determination — this report is the evidence, not the decision." -ForegroundColor Gray
