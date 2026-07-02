<#
.SYNOPSIS
    CCAUDIT-Report.ps1 — produce dated audit-evidence and a POA&M-ready gap export (read-only).
.DESCRIPTION
    PURPOSE
        Turn a validation run into two auditor-ready exports: an audit-evidence package (dated,
        per-control, per-device record with tenant, operator, expected, observed, and verdict) and a
        POA&M-ready gap list (one row per failing control with affected-device count, severity, and
        empty milestone/owner columns to complete). Read-only — it consumes an existing validation
        file and writes exports; it does not query for changes or modify anything.
    HOW TO RUN
        powershell -ExecutionPolicy Bypass -File .\CCAUDIT-Report.ps1 -ValidationPath C:\CCAUDIT\out\CCAUDIT-Validation-20260701-120000.json -OutputPath C:\CCAUDIT\out

        Required Graph scopes: none for report generation (operates on the validation output file).
    EXPECTED RESULTS
        Writes CCAUDIT-Evidence-<timestamp>.csv/.json (full evidence) and CCAUDIT-POAM-<timestamp>.csv
        (one row per failing control).
        PASS: evidence rows carry all provenance fields; POA&M lists every failing control.
        FAIL: missing fields or no POA&M rows for known failures — re-run validation first.
.NOTES
    White-label — the repeatable way. Read-only against Microsoft Graph. CIS/STIG control content deferred to CIS/DISA.
#>

[CmdletBinding()]
param(
    [Parameter(Mandatory = $true)][string]$ValidationPath,
    [string]$OutputPath = "."
)

$ErrorActionPreference = "Stop"

if (-not (Test-Path -LiteralPath $ValidationPath)) {
    throw "Validation file not found: $ValidationPath. Run CCAUDIT-Validation.ps1 first."
}
if (-not (Test-Path -LiteralPath $OutputPath)) {
    New-Item -ItemType Directory -Path $OutputPath -Force | Out-Null
}
$stamp = Get-Date -Format "yyyyMMdd-HHmmss"

$validation = Get-Content -LiteralPath $ValidationPath -Raw | ConvertFrom-Json
if (-not $validation) { throw "Validation file is empty: $ValidationPath" }

# --- Audit-evidence export (full provenance, every measured row) ---
$evidence = $validation | ForEach-Object {
    [pscustomobject]@{
        CollectedUtc  = $_.CollectedUtc
        TenantId      = $_.TenantId
        Operator      = $_.Operator
        ControlId     = $_.ControlId
        Domain        = $_.Domain
        TargetObject  = $_.TargetObject
        SettingName   = $_.SettingName
        DeviceName    = $_.DeviceName
        AzureADDeviceId = $_.AzureADDeviceId
        ExpectedValue = $_.ExpectedValue
        ObservedValue = $_.ObservedValue
        Verdict       = $_.Verdict
    }
}

$evCsv  = Join-Path $OutputPath "CCAUDIT-Evidence-$stamp.csv"
$evJson = Join-Path $OutputPath "CCAUDIT-Evidence-$stamp.json"
$evidence | Export-Csv -Path $evCsv -NoTypeInformation -Encoding UTF8
$evidence | ConvertTo-Json -Depth 6 | Out-File -FilePath $evJson -Encoding UTF8

# --- POA&M-ready gap export (one row per failing control) ---
$failing = $validation | Where-Object { $_.Verdict -in @("Drift", "Missing", "Non-conformant") }
$poam = $failing | Group-Object ControlId | ForEach-Object {
    $first = $_.Group | Select-Object -First 1
    [pscustomobject]@{
        ControlId            = $_.Name
        WeaknessDescription  = ("Control {0} ({1}) not conformant to baseline for {2} device(s)." -f $_.Name, $first.SettingName, $_.Count)
        Domain               = $first.Domain
        TargetObject         = $first.TargetObject
        SettingName          = $first.SettingName
        ExpectedValue        = $first.ExpectedValue
        AffectedDeviceCount  = $_.Count
        Severity             = $first.Severity
        DetectedUtc          = $first.CollectedUtc
        # POA&M columns to complete:
        Milestone            = ""
        ScheduledCompletion  = ""
        Owner                = ""
        Status               = "Open"
        RemediationNotes     = ""
    }
}

$poamCsv = Join-Path $OutputPath "CCAUDIT-POAM-$stamp.csv"
if ($poam) {
    $poam | Export-Csv -Path $poamCsv -NoTypeInformation -Encoding UTF8
} else {
    # still write an (empty-of-gaps) POA&M so the run is evidenced as clean
    "" | Out-File -FilePath $poamCsv -Encoding UTF8
}

$total   = ($validation | Measure-Object).Count
$fails   = ($failing | Measure-Object).Count
$gapCtrl = ($poam | Measure-Object).Count
Write-Host ("Evidence rows: {0}  |  Failing rows: {1}  |  POA&M control gaps: {2}" -f $total, $fails, $gapCtrl) -ForegroundColor Green
Write-Host ("Wrote:`n  {0}`n  {1}`n  {2}" -f $evCsv, $evJson, $poamCsv) -ForegroundColor Green
Write-Host "Copy finished evidence to your controlled, retained destination." -ForegroundColor Yellow
