<#
.SYNOPSIS
    CCAUDITG-Report.ps1 — produce dated audit-evidence and a POA&M-ready gap export for GCC High (read-only).
.DESCRIPTION
    PURPOSE
        Turn a validation run into two auditor-ready exports for a US Government (GCC High / DoD) tenant:
        an audit-evidence package (dated, per-control, per-device record with tenant, operator, expected,
        observed, and verdict) and a POA&M-ready gap list (one row per failing control with affected-device
        count, severity, and empty milestone/owner columns to complete for NIST 800-53 CA-5). Read-only —
        it consumes an existing validation file and writes exports; it queries nothing and modifies nothing.
        The Intune ServiceNow connector is not available in GCC High, so import the POA&M CSV into your
        GRC/ITSM or FedRAMP POA&M workbook manually. Use your-tenant-id / your-account values from the run.
    HOW TO RUN
        powershell -ExecutionPolicy Bypass -File .\CCAUDITG-Report.ps1 -ValidationPath C:\CCAUDITG\out\CCAUDITG-Validation-20260701-120000.json -OutputPath C:\CCAUDITG\out

        Graph scopes: none (operates on the validation output file; no US Gov Graph call is made).
    EXPECTED RESULTS
        Writes CCAUDITG-Evidence-<timestamp>.csv/.json (full evidence) and CCAUDITG-POAM-<timestamp>.csv
        (one row per failing control).
        PASS: evidence rows carry all provenance fields; POA&M lists every failing control.
        FAIL: missing fields or no POA&M rows for known failures — re-run validation first.
.NOTES
    White-label — the repeatable way. Read-only against Microsoft Graph US Gov endpoints.
#>

[CmdletBinding()]
param(
    [Parameter(Mandatory = $true)][string]$ValidationPath,
    [string]$OutputPath = "."
)

$ErrorActionPreference = "Stop"

if (-not (Test-Path -LiteralPath $ValidationPath)) {
    throw "Validation file not found: $ValidationPath. Run CCAUDITG-Validation.ps1 first."
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
        Cloud         = $_.Cloud
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

$evCsv  = Join-Path $OutputPath "CCAUDITG-Evidence-$stamp.csv"
$evJson = Join-Path $OutputPath "CCAUDITG-Evidence-$stamp.json"
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
        # POA&M columns to complete (align ScheduledCompletion to your ATO timelines,
        # commonly 30/90/180 days for High/Moderate/Low — verify against your assessor):
        Milestone            = ""
        ScheduledCompletion  = ""
        Owner                = ""
        Status               = "Open"
        RemediationNotes     = ""
    }
}

$poamCsv = Join-Path $OutputPath "CCAUDITG-POAM-$stamp.csv"
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
Write-Host "Copy finished evidence to your controlled, in-boundary (Gov) retained destination. Import the POA&M CSV into your GRC/ITSM manually — no ServiceNow connector in GCC High." -ForegroundColor Yellow
