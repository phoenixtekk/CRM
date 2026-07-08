<#
.SYNOPSIS
    IPASSESS-Discovery.ps1 — inventory the information-protection estate: labels, publishing, encryption, DLP, auto-labeling, SITs (read-only).
.DESCRIPTION
    PURPOSE
        Read-only discovery for the Information Protection Assessment. Inventories the controls that
        protect the data estate today: sensitivity LABELS (with their encryption/protection and content-
        marking settings and scope), the LABEL POLICIES that publish them (coverage), DLP policies and
        rules (with Mode and Workload), AUTO-LABELING policies (with simulation-vs-enabled Mode), and —
        with -IncludeSensitiveTypes — the sensitive information types that define "sensitive." This is the
        "what protects the estate today" baseline for scoring and the roadmap. Changes nothing.
    HOW TO RUN
        PowerShell 5.1+ or 7+ with Security & Compliance PowerShell (Connect-IPPSSession):
          Connect-IPPSSession
          .\IPASSESS-Discovery.ps1
          .\IPASSESS-Discovery.ps1 -IncludeSensitiveTypes
    EXPECTED RESULTS
        The posture inventory written to .\IPASSESS-InformationProtection-Estate-Discovery.csv
        (Information Protection - Estate - Discovery) and, with -IncludeSensitiveTypes, the SIT list to
        .\IPASSESS-SensitiveInfoTypes-Estate-Discovery.csv. Unpublished labels, DLP stuck in Test, and
        classify-but-don't-encrypt labels all surface as rows for scoring.
.NOTES
    White-label Microsoft Purview tooling. Read-only. No credentials stored. Cmdlets are standard Security
    & Compliance PowerShell; none are invented. Where a capability is unlicensed/unreadable the script
    records a WARN and continues rather than assuming the feature exists.
#>
[CmdletBinding()]
param(
    [switch]$IncludeSensitiveTypes,
    [string]$OutPath          = ".\IPASSESS-InformationProtection-Estate-Discovery.csv",
    [string]$SensitiveOutPath = ".\IPASSESS-SensitiveInfoTypes-Estate-Discovery.csv"
)

$ErrorActionPreference = "Stop"
Write-Host "=== IPASSESS Discovery — information-protection posture inventory (read-only) ===" -ForegroundColor Cyan

try { Get-Label -ErrorAction Stop | Out-Null }
catch { Write-Host "Not connected to Security & Compliance PowerShell. Run Connect-IPPSSession first (GR §3)." -ForegroundColor Red; return }

$rows = [System.Collections.Generic.List[object]]::new()
function Add-Row($dimension, $type, $name, $detail) {
    $rows.Add([pscustomobject]@{ Dimension = $dimension; ArtifactType = $type; Name = $name; Detail = $detail })
}

# --- Dimension 1/3: Sensitivity labels + encryption/protection + content marking + scope ---
try {
    $labels = Get-Label -ErrorAction Stop
    foreach ($l in $labels) {
        $enc  = if ($l.EncryptionEnabled) { "Encrypt=ON($($l.EncryptionProtectionType))" } else { "Encrypt=off" }
        $mark = @()
        if ($l.ApplyContentMarkingHeaderEnabled) { $mark += "Header" }
        if ($l.ApplyContentMarkingFooterEnabled) { $mark += "Footer" }
        if ($l.ApplyWaterMarkingEnabled)         { $mark += "Watermark" }
        $marks = if ($mark.Count) { "Marks=" + ($mark -join "/") } else { "Marks=none" }
        $detail = "Priority={0}; Enabled={1}; Scope={2}; {3}; {4}" -f `
                  $l.Priority, $l.Enabled, ($l.ContentType -join ","), $enc, $marks
        Add-Row "Taxonomy/Encryption" "SensitivityLabel" $l.DisplayName $detail
    }
    Write-Host ("  Labels: {0}" -f @($labels).Count) -ForegroundColor Green
} catch { Write-Host "  WARN: could not read labels: $($_.Exception.Message)" -ForegroundColor Yellow }

# --- Dimension 2: Label policies (who the labels are published to — coverage) ---
try {
    $lp = Get-LabelPolicy -ErrorAction Stop
    foreach ($p in $lp) { Add-Row "Publishing/Coverage" "LabelPolicy" $p.Name ("Labels={0}" -f ($p.Labels -join "; ")) }
    Write-Host ("  Label policies: {0}" -f @($lp).Count) -ForegroundColor Green
} catch { Write-Host "  WARN: could not read label policies: $($_.Exception.Message)" -ForegroundColor Yellow }

# --- Dimension 5: DLP policies + rules (Mode / Workload coverage) ---
try {
    $dlp = Get-DlpCompliancePolicy -ErrorAction Stop
    foreach ($d in $dlp) { Add-Row "DLP Coverage/Mode" "DlpPolicy" $d.Name ("Mode={0}; Workloads={1}" -f $d.Mode, $d.Workload) }
    Write-Host ("  DLP policies: {0}" -f @($dlp).Count) -ForegroundColor Green
    try {
        $rules = Get-DlpComplianceRule -ErrorAction Stop
        foreach ($r in $rules) { Add-Row "DLP Coverage/Mode" "DlpRule" $r.Name ("Policy={0}; Disabled={1}" -f $r.Policy, $r.Disabled) }
        Write-Host ("  DLP rules: {0}" -f @($rules).Count) -ForegroundColor Green
    } catch { Write-Host "  WARN: could not read DLP rules: $($_.Exception.Message)" -ForegroundColor Yellow }
} catch { Write-Host "  WARN: could not read DLP policies: $($_.Exception.Message)" -ForegroundColor Yellow }

# --- Dimension 4: Auto-labeling policies (simulation vs enabled) — licensing-gated ---
try {
    $auto = Get-AutoSensitivityLabelPolicy -ErrorAction Stop
    foreach ($a in $auto) { Add-Row "Auto-labeling" "AutoLabelPolicy" $a.Name ("Mode={0}; Label={1}" -f $a.Mode, $a.ApplySensitivityLabel) }
    Write-Host ("  Auto-labeling policies: {0}" -f @($auto).Count) -ForegroundColor Green
} catch { Write-Host "  WARN: auto-labeling not readable (E5-gated — verify your licensing/tenant): $($_.Exception.Message)" -ForegroundColor Yellow }

$rows | Export-Csv -Path $OutPath -NoTypeInformation -Encoding UTF8
Write-Host ("`nPosture inventory written to {0}  (Information Protection - Estate - Discovery)" -f $OutPath) -ForegroundColor Green

# --- Dimension 6 (optional): Sensitive information types (what "sensitive" means here) ---
if ($IncludeSensitiveTypes) {
    try {
        $sits = Get-DlpSensitiveInformationType -ErrorAction Stop
        $sits | Select-Object Name, Publisher, RulePackId |
            Export-Csv -Path $SensitiveOutPath -NoTypeInformation -Encoding UTF8
        Write-Host ("Sensitive information types written to {0}: {1} type(s)" -f $SensitiveOutPath, @($sits).Count) -ForegroundColor Green
    } catch { Write-Host "  WARN: could not read sensitive information types: $($_.Exception.Message)" -ForegroundColor Yellow }
}

Write-Host "Complement in the portal: Information Protection -> Content explorer (label coverage) and Activity explorer (labeling activity); DSPM if licensed (verify your licensing/tenant)." -ForegroundColor DarkGray
Write-Host "Next: score with IPASSESS-Validation.ps1, then build the roadmap with IPASSESS-Report.ps1." -ForegroundColor Cyan
