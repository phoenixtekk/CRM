<#
.SYNOPSIS
    PHIDLP-Discovery.ps1 — read-only Microsoft Purview DLP posture + HIPAA/PHI sensitive-info-type coverage assessment.
.DESCRIPTION
    PURPOSE
        Builds the PHI DLP baseline: every existing DLP compliance policy with its MODE (enforce vs
        simulation vs disabled) and the locations it covers, plus whether the HIPAA-relevant built-in
        sensitive information types are present in the tenant (U.S. Social Security Number (SSN),
        International Classification of Diseases (ICD-9-CM), International Classification of Diseases
        (ICD-10-CM), Drug Enforcement Agency (DEA) Number) and a summary of custom SITs / EDM schemas.
        Read-only — makes no changes. Run it before building simulation policies.
    HOW TO RUN
        powershell -ExecutionPolicy Bypass -File .\PHIDLP-Discovery.ps1 -CsvPath .\PHIDLP-Posture.csv
        Requires Security & Compliance PowerShell (Connect-IPPSSession via ExchangeOnlineManagement).
    EXPECTED RESULTS
        A console table of DLP policies (Name, Mode, Locations), a HIPAA-SIT presence checklist, and
        custom/EDM counts, plus an optional CSV of the policy inventory. PASS signal: policies you expect
        in simulation report a Test* mode; the HIPAA-relevant SITs you plan to use are present; anything
        already in Enable that you did not intend is flagged for review.
.NOTES
    Purview — HIPAA / PHI DLP Pack. Read-only against Security & Compliance PowerShell. No changes made.
    HIPAA breach determination is deferred to the Privacy/Security Officer — this tool only reports posture.
#>
[CmdletBinding()]
param(
    [string]$CsvPath,
    [string]$UserPrincipalName
)

# --- Connect (modern auth / MFA). Reuses an existing session if present. ---
if (-not (Get-Module -ListAvailable -Name ExchangeOnlineManagement)) {
    Install-Module ExchangeOnlineManagement -Scope CurrentUser -Force -AllowClobber
}
Import-Module ExchangeOnlineManagement -ErrorAction Stop
if (-not (Get-Command Get-DlpCompliancePolicy -ErrorAction SilentlyContinue)) {
    if ($UserPrincipalName) { Connect-IPPSSession -UserPrincipalName $UserPrincipalName }
    else { Connect-IPPSSession }
}

Write-Host '=== Purview HIPAA / PHI DLP Posture Assessment (read-only) ===' -ForegroundColor Cyan

# --- DLP policies and their mode/locations ---
$policies = Get-DlpCompliancePolicy -ErrorAction Stop
$rows = foreach ($p in $policies) {
    # Mode: Enable = enforcing; TestWithNotifications / TestWithoutNotifications = SIMULATION; Disable = off
    $isSimulation = $p.Mode -like 'Test*'
    $locations = @()
    foreach ($loc in 'ExchangeLocation','SharePointLocation','OneDriveLocation','TeamsLocation','EndpointDlpLocation','OnPremisesScannerDlpLocation') {
        $val = $p.$loc
        if ($val -and $val.Count -gt 0) { $locations += $loc.Replace('Location','') }
    }
    [pscustomobject]@{
        Name       = $p.Name
        Mode       = $p.Mode
        Simulation = $isSimulation
        Enforcing  = ($p.Mode -eq 'Enable')
        Locations  = ($locations -join ', ')
        Enabled    = $p.Enabled
    }
}
Write-Host '--- DLP Policies ---' -ForegroundColor Cyan
$rows | Sort-Object Name | Format-Table -AutoSize

$enforcing = @($rows | Where-Object { $_.Enforcing })
if ($enforcing.Count -gt 0) {
    Write-Host ("REVIEW: {0} policy(ies) are ENFORCING (Mode=Enable) — confirm each is intended:" -f $enforcing.Count) -ForegroundColor Yellow
    $enforcing.Name | ForEach-Object { Write-Host "   * $_" -ForegroundColor Yellow }
} else {
    Write-Host 'No enforcing policies found (all in simulation/disabled) — expected during pilot build.' -ForegroundColor Green
}

# --- HIPAA-relevant sensitive information type coverage ---
Write-Host '--- HIPAA-relevant Sensitive Information Types ---' -ForegroundColor Cyan
# These built-in SITs underpin the "U.S. Health Insurance Act (HIPAA)" DLP template and related PHI detection.
# Verify names/availability in your tenant — the SIT library evolves.
$hipaaSitNames = @(
    'U.S. Social Security Number (SSN)',
    'International Classification of Diseases (ICD-9-CM)',
    'International Classification of Diseases (ICD-10-CM)',
    'Drug Enforcement Agency (DEA) Number'
)
$sits = Get-DlpSensitiveInformationType -ErrorAction SilentlyContinue
if ($sits) {
    $allNames = $sits.Name
    foreach ($n in $hipaaSitNames) {
        if ($allNames -contains $n) {
            Write-Host ("  [PRESENT] {0}" -f $n) -ForegroundColor Green
        } else {
            Write-Host ("  [VERIFY ] {0} — not found by this exact name; confirm in the SIT list / your licensing." -f $n) -ForegroundColor Yellow
        }
    }
    $builtIn = @($sits | Where-Object { $_.Publisher -match 'Microsoft' })
    $custom  = @($sits | Where-Object { $_.Publisher -notmatch 'Microsoft' })
    Write-Host ("Built-in SITs: {0}   Custom SITs: {1}   Total: {2}" -f $builtIn.Count, $custom.Count, $sits.Count)
    if ($custom.Count -gt 0) {
        Write-Host 'Custom SITs present (candidates for your MRN / member-ID detectors):' -ForegroundColor Cyan
        $custom | Select-Object Name, Publisher | Format-Table -AutoSize
    }
} else {
    Write-Host 'Could not enumerate SITs (check role / connection).' -ForegroundColor Yellow
}

# --- EDM schemas (near-zero-FP matching against your patient/member roster), if any ---
if (Get-Command Get-DlpEdmSchema -ErrorAction SilentlyContinue) {
    $edm = Get-DlpEdmSchema -ErrorAction SilentlyContinue
    Write-Host ("EDM schemas configured: {0} (candidate for Patient Identifiers - EDM - PHI)" -f (@($edm).Count))
}

if ($CsvPath) {
    $rows | Export-Csv -Path $CsvPath -NoTypeInformation -Encoding UTF8
    Write-Host ("Policy inventory exported to {0}" -f $CsvPath) -ForegroundColor Green
}

Write-Host 'Done. Baseline captured — proceed to build simulation policies (PHIDLP-Config.ps1).' -ForegroundColor Cyan
