<#
.SYNOPSIS
    DLPFIN-Discovery.ps1 — read-only Purview DLP posture + financial/NPI sensitive-info-type coverage assessment.
.DESCRIPTION
    PURPOSE
        Builds the financial-DLP baseline: every existing DLP compliance policy with its MODE (enforce
        vs simulation vs disabled) and the locations it covers, plus coverage of the built-in FINANCIAL
        sensitive information types (Credit Card, ABA Routing, U.S. Bank Account, IBAN, SWIFT, SSN,
        ITIN) versus custom SITs, and any EDM schemas in the tenant. Read-only — makes no changes. Use
        it to see what already exists before you build simulation policies.
    HOW TO RUN
        powershell -ExecutionPolicy Bypass -File .\DLPFIN-Discovery.ps1 -CsvPath .\DLPFIN-Posture.csv
        Requires Security & Compliance PowerShell (Connect-IPPSSession via ExchangeOnlineManagement).
    EXPECTED RESULTS
        A console table of DLP policies (Name, Mode, Locations) and a financial-SIT coverage summary
        (which built-in financial SITs are present, custom SIT count, EDM count), plus an optional CSV
        of the policy inventory. PASS signal: policies you expect to be in simulation report a Test*
        mode; anything already in Enable that you did not intend is flagged for review.
.NOTES
    Purview — Financial (GLBA/SOX) DLP Pack. Read-only against Security & Compliance PowerShell. No credentials in code.
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

Write-Host '=== Purview Financial (GLBA/SOX) DLP Posture Assessment (read-only) ===' -ForegroundColor Cyan

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

# --- Financial sensitive information type coverage ---
Write-Host '--- Financial Sensitive Information Type coverage ---' -ForegroundColor Cyan
# Built-in financial SITs this pack keys off (names per Microsoft public docs — verify in your tenant).
$financialSits = @(
    'Credit Card Number',
    'ABA Routing Number',
    'U.S. Bank Account Number',
    'International Banking Account Number (IBAN)',
    'SWIFT Code',
    'U.S. Social Security Number (SSN)',
    'U.S. Individual Taxpayer Identification Number (ITIN)'
)
$sits = Get-DlpSensitiveInformationType -ErrorAction SilentlyContinue
if ($sits) {
    $names = $sits.Name
    foreach ($fs in $financialSits) {
        $present = $names -contains $fs
        $color = if ($present) { 'Green' } else { 'Yellow' }
        Write-Host ("  [{0}] {1}" -f ($(if ($present) {'x'} else {' '}), $fs)) -ForegroundColor $color
    }
    $custom = @($sits | Where-Object { $_.Publisher -notmatch 'Microsoft' })
    Write-Host ("Custom SITs present: {0}   Total SITs: {1}" -f $custom.Count, $sits.Count)
    if ($custom.Count -gt 0) {
        Write-Host 'Custom SITs (candidates for internal account numbers / GL codes):' -ForegroundColor Cyan
        $custom | Select-Object Name, Publisher | Format-Table -AutoSize
    }
} else {
    Write-Host 'Could not enumerate SITs (check role / connection).' -ForegroundColor Yellow
}

# --- EDM schemas (near-zero-FP customer-NPI matching), if any ---
if (Get-Command Get-DlpEdmSchema -ErrorAction SilentlyContinue) {
    $edm = Get-DlpEdmSchema -ErrorAction SilentlyContinue
    Write-Host ("EDM schemas configured: {0} (candidate: 'Customer NPI - EDM - Financial')" -f (@($edm).Count))
}

if ($CsvPath) {
    $rows | Export-Csv -Path $CsvPath -NoTypeInformation -Encoding UTF8
    Write-Host ("Policy inventory exported to {0}" -f $CsvPath) -ForegroundColor Green
}

Write-Host 'Done. Baseline captured — proceed to build simulation policies (DLPFIN-Config.ps1).' -ForegroundColor Cyan
