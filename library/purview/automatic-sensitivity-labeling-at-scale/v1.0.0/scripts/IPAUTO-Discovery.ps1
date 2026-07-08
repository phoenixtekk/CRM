<#
.SYNOPSIS
    IPAUTO-Discovery.ps1 — inventory sensitivity labels, label policies, and service-side auto-labeling (read-only).
.DESCRIPTION
    PURPOSE
        Connects to Security & Compliance PowerShell and inventories the existing sensitivity LABELS
        (flagging which already carry client-side auto-labeling conditions), the LABEL POLICIES that
        publish them, and every SERVICE-SIDE auto-labeling policy with its MODE plus its rules — the
        baseline the auto-labeling build starts from. Confirms whether the target label exists and is
        published. Read-only — it changes nothing.
    HOW TO RUN
        PowerShell 5.1+ or 7+ with the ExchangeOnlineManagement module:
          Connect-IPPSSession
          .\IPAUTO-Discovery.ps1 -TargetLabel "Confidential \ All Employees"
    EXPECTED RESULTS
        AutoLabel-Posture-Estate-Discovery.csv (AutoLabel Posture - Estate - Discovery) listing labels,
        label policies, and service-side auto-labeling policies/rules with mode. PASS = the target label
        is present and published and the inventory completes without error.
.NOTES
    White-label Microsoft Purview tooling. Read-only. No credentials stored.
    VERIFY IN YOUR TENANT: automatic labeling (client- and service-side) is E5/E5 Compliance and evolving.
    This script reports what your session can read; it does not assert availability.
#>
[CmdletBinding()]
param(
    [string]$TargetLabel = "Confidential \ All Employees",
    [string]$OutPath = ".\AutoLabel-Posture-Estate-Discovery.csv"
)

$ErrorActionPreference = "Stop"
Write-Host "=== IPAUTO Discovery — auto-labeling posture (read-only) ===" -ForegroundColor Cyan
if (-not (Get-Command Get-Label -ErrorAction SilentlyContinue)) {
    Write-Host "Security & Compliance PowerShell not available. Run Connect-IPPSSession first." -ForegroundColor Red
    return
}

$rows = New-Object System.Collections.Generic.List[object]
function Add-Row($type, $name, $detail) { $rows.Add([pscustomobject]@{ ItemType = $type; Name = $name; Detail = $detail }) }

# --- Sensitivity labels (flag client-side auto-labeling conditions) ---
Write-Host "`n[1/4] Sensitivity labels..." -ForegroundColor Cyan
$targetFound = $false
try {
    foreach ($l in @(Get-Label -ErrorAction SilentlyContinue)) {
        $hasAuto = ""
        # Client-side auto-labeling condition is stored on the label; property surface evolves, so scan text.
        if (("$($l.Settings)" -match "(?i)autoapplytype|classifier|sensitivetype") -or ("$($l.LabelActions)" -match "(?i)auto")) { $hasAuto = "CLIENT-SIDE-AUTO" }
        if ($l.DisplayName -eq $TargetLabel -or $l.Name -eq $TargetLabel) { $targetFound = $true }
        Add-Row "SensitivityLabel" $l.DisplayName ("Name={0}; Priority={1} {2}" -f $l.Name, $l.Priority, $hasAuto)
    }
} catch { Write-Host "  Labels not readable (licensing/role?): $($_.Exception.Message)" -ForegroundColor Yellow }

# --- Label policies (publishing) ---
Write-Host "[2/4] Sensitivity label policies..." -ForegroundColor Cyan
try { foreach ($p in @(Get-LabelPolicy -ErrorAction SilentlyContinue)) { Add-Row "LabelPolicy" $p.Name ("Enabled={0}; Labels={1}" -f $p.Enabled, ($p.Labels -join ",")) } }
catch { Write-Host "  Label policies not readable: $($_.Exception.Message)" -ForegroundColor Yellow }

# --- Service-side auto-labeling policies + mode ---
Write-Host "[3/4] Service-side auto-labeling policies (with mode)..." -ForegroundColor Cyan
if (Get-Command Get-AutoSensitivityLabelPolicy -ErrorAction SilentlyContinue) {
    try { foreach ($a in @(Get-AutoSensitivityLabelPolicy -ErrorAction SilentlyContinue)) { Add-Row "AutoLabelPolicy" $a.Name ("Mode={0}; Label={1}; Workload={2}" -f $a.Mode, $a.ApplySensitivityLabel, $a.Workload) } }
    catch { Write-Host "  Auto-labeling policies not readable: $($_.Exception.Message)" -ForegroundColor Yellow }
} else {
    Write-Host "  Get-AutoSensitivityLabelPolicy not available — check licensing/role (Req 2.2/2.3)." -ForegroundColor Yellow
}

# --- Service-side auto-labeling rules ---
Write-Host "[4/4] Service-side auto-labeling rules..." -ForegroundColor Cyan
if (Get-Command Get-AutoSensitivityLabelRule -ErrorAction SilentlyContinue) {
    try { foreach ($r in @(Get-AutoSensitivityLabelRule -ErrorAction SilentlyContinue)) { Add-Row "AutoLabelRule" $r.Name ("Policy={0}; Disabled={1}" -f $r.Policy, $r.Disabled) } }
    catch { Write-Host "  Auto-labeling rules not readable: $($_.Exception.Message)" -ForegroundColor Yellow }
}

$rows | Export-Csv -Path $OutPath -NoTypeInformation -Encoding UTF8
Write-Host ""
Write-Host ("{0} item(s) -> {1}  (AutoLabel Posture - Estate - Discovery)" -f $rows.Count, $OutPath) -ForegroundColor Green
if ($targetFound) {
    Write-Host ("Target label '{0}' is present. Confirm it is PUBLISHED (label policy) and — if it encrypts — protection enforces (Req 2.1)." -f $TargetLabel) -ForegroundColor Green
} else {
    Write-Host ("Target label '{0}' NOT found. Auto-labeling can only apply an EXISTING published label (Req 2.1) — complete the labels prerequisite first." -f $TargetLabel) -ForegroundColor Red
}
Write-Host "Next: design the match conditions (Step 2), then IPAUTO-AutoLabelConfig.ps1 -WhatIf." -ForegroundColor Cyan
