<#
.SYNOPSIS
    CLSTRAIN-Discovery.ps1 — inventory auto-labeling/DLP/retention policies, labels, and where a trainable classifier can be wired (read-only).
.DESCRIPTION
    PURPOSE
        Read-only baseline discovery for trainable classifiers. Because a published classifier only has value
        once a CONTROL acts on it, this inventories the controls a classifier can be wired into — auto-
        labeling policies (with mode), DLP policies, and retention policies — plus the sensitivity labels a
        classifier could apply. This is the "what could act on a classifier" baseline before you build one.
        Changes nothing. Classifier creation/publish status is confirmed in the Purview portal (there is no
        supported S&C PowerShell cmdlet to create/publish a trainable classifier).
    HOW TO RUN
        PowerShell 5.1+ or 7+ with Security & Compliance PowerShell (Connect-IPPSSession):
          Connect-IPPSSession
          .\CLSTRAIN-Discovery.ps1
    EXPECTED RESULTS
        A CSV baseline (.\CLSTRAIN-Discovery.csv) of auto-labeling policies (+ Mode), DLP policies, retention
        policies, and sensitivity labels. Use it to pick the target control + label to wire the classifier
        into.
.NOTES
    White-label Microsoft Purview tooling. Read-only. No credentials stored. Cmdlets are standard Security &
    Compliance PowerShell (Get-AutoSensitivityLabelPolicy / Get-DlpCompliancePolicy / Get-RetentionCompliance
    Policy / Get-Label); none are invented. Trainable classifiers are licensing-dependent and portal-managed —
    the script WARNS where a control is not readable rather than assuming.
#>
[CmdletBinding()]
param(
    [string]$OutPath = ".\CLSTRAIN-Discovery.csv"
)

$ErrorActionPreference = "Stop"
Write-Host "=== CLSTRAIN Discovery — where a trainable classifier can be wired (read-only) ===" -ForegroundColor Cyan

try { Get-Label -ErrorAction Stop | Out-Null }
catch {
    try { Get-DlpCompliancePolicy -ErrorAction Stop | Out-Null }
    catch {
        Write-Host "Not connected to Security & Compliance PowerShell. Run Connect-IPPSSession first (GR §3)." -ForegroundColor Red
        return
    }
}

$rows = [System.Collections.Generic.List[object]]::new()
function Add-Row($type, $name, $detail) {
    $rows.Add([pscustomobject]@{ ArtifactType = $type; Name = $name; Detail = $detail })
}

# --- Auto-labeling policies (a prime wiring target; note the mode) ---
try {
    $al = Get-AutoSensitivityLabelPolicy -ErrorAction Stop
    foreach ($p in $al) { Add-Row "AutoLabelPolicy" $p.Name ("Mode={0}; Label={1}" -f $p.Mode, $p.ApplySensitivityLabel) }
    Write-Host ("  Auto-labeling policies: {0}" -f @($al).Count) -ForegroundColor Green
} catch { Write-Host "  WARN: could not read auto-labeling policies (may be unlicensed): $($_.Exception.Message)" -ForegroundColor Yellow }

# --- DLP policies (a classifier can be a DLP condition) ---
try {
    $dlp = Get-DlpCompliancePolicy -ErrorAction Stop
    foreach ($p in $dlp) { Add-Row "DlpPolicy" $p.Name ("Mode={0}" -f $p.Mode) }
    Write-Host ("  DLP policies: {0}" -f @($dlp).Count) -ForegroundColor Green
} catch { Write-Host "  WARN: could not read DLP policies: $($_.Exception.Message)" -ForegroundColor Yellow }

# --- Retention policies (a classifier can drive retention) ---
try {
    $ret = Get-RetentionCompliancePolicy -ErrorAction Stop
    foreach ($p in $ret) { Add-Row "RetentionPolicy" $p.Name ("Enabled={0}; Mode={1}" -f $p.Enabled, $p.Mode) }
    Write-Host ("  Retention policies: {0}" -f @($ret).Count) -ForegroundColor Green
} catch { Write-Host "  WARN: could not read retention policies (may be unlicensed): $($_.Exception.Message)" -ForegroundColor Yellow }

# --- Sensitivity labels (a classifier's auto-label target) ---
try {
    $labels = Get-Label -ErrorAction Stop
    foreach ($l in $labels) { Add-Row "SensitivityLabel" $l.DisplayName ("Priority={0}; Enabled={1}" -f $l.Priority, $l.Enabled) }
    Write-Host ("  Sensitivity labels: {0}" -f @($labels).Count) -ForegroundColor Green
} catch { Write-Host "  WARN: could not read sensitivity labels (may be unlicensed): $($_.Exception.Message)" -ForegroundColor Yellow }

$rows | Export-Csv -Path $OutPath -NoTypeInformation -Encoding UTF8
Write-Host ("`nBaseline written to {0}" -f $OutPath) -ForegroundColor Green

Write-Host "`nReminder: create/seed/train/test/PUBLISH the trainable classifier in the Purview portal" -ForegroundColor Cyan
Write-Host "(Data classification > Classifiers > Trainable classifiers) — no S&C PowerShell cmdlet creates one." -ForegroundColor Cyan
Write-Host "Next: run CLSTRAIN-ScopeHealth.ps1 for seed/scope signals, then CLSTRAIN-Configure.ps1 -WhatIf to preview the wiring." -ForegroundColor Cyan
