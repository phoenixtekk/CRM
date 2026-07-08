<#
.SYNOPSIS
    PURVPCI-Discovery.ps1 — read-only cardholder-data DLP posture + PAN-detector coverage assessment.
.DESCRIPTION
    PURPOSE
        Builds the card-data DLP baseline: every existing DLP compliance policy with its MODE (enforce vs
        simulation vs disabled) and the locations it covers, confirms the built-in "Credit Card Number"
        sensitive information type (the Luhn-validated PAN detector) is present, and lists any EDM schemas
        available for near-zero-false-positive PAN matching. Read-only — makes no changes. Run it before
        you build simulation policies to see what already exists.
    HOW TO RUN
        powershell -ExecutionPolicy Bypass -File .\PURVPCI-Discovery.ps1 -CsvPath .\PURVPCI-Posture.csv
        Requires Security & Compliance PowerShell (Connect-IPPSSession via ExchangeOnlineManagement).
    EXPECTED RESULTS
        A console table of DLP policies (Name, Mode, Locations), confirmation the "Credit Card Number" SIT
        exists, and EDM schema count, plus an optional CSV of the policy inventory. PASS signal: policies
        you expect to be in simulation report a Test* mode; anything already in Enable that you did not
        intend is flagged for review, and the Credit Card Number SIT is present.
.NOTES
    Purview — PCI-DSS DLP Pack. Read-only against Security & Compliance PowerShell. No credentials in code.
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

Write-Host '=== PCI-DSS DLP Posture Assessment (read-only) ===' -ForegroundColor Cyan

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

# --- PAN detector coverage: confirm the built-in Credit Card Number SIT ---
Write-Host '--- PAN detector (Credit Card Number SIT) ---' -ForegroundColor Cyan
$sits = Get-DlpSensitiveInformationType -ErrorAction SilentlyContinue
if ($sits) {
    $cc = @($sits | Where-Object { $_.Name -match 'Credit Card' })
    if ($cc.Count -gt 0) {
        Write-Host ("PASS: built-in PAN detector present -> {0}" -f (($cc | Select-Object -ExpandProperty Name) -join ', ')) -ForegroundColor Green
    } else {
        Write-Host 'VERIFY: could not find a "Credit Card Number" SIT — check tenant/role.' -ForegroundColor Yellow
    }
    $builtIn = @($sits | Where-Object { $_.Publisher -match 'Microsoft' })
    $custom  = @($sits | Where-Object { $_.Publisher -notmatch 'Microsoft' })
    Write-Host ("SIT inventory — Built-in: {0}   Custom: {1}   Total: {2}" -f $builtIn.Count, $custom.Count, $sits.Count)
} else {
    Write-Host 'Could not enumerate SITs (check role / connection).' -ForegroundColor Yellow
}

# --- EDM schemas (near-zero-FP PAN matching), if any ---
if (Get-Command Get-DlpEdmSchema -ErrorAction SilentlyContinue) {
    $edm = @(Get-DlpEdmSchema -ErrorAction SilentlyContinue)
    Write-Host ("EDM schemas configured: {0} (use for your real PANs where the pattern SIT over-matches)." -f $edm.Count)
}

if ($CsvPath) {
    $rows | Export-Csv -Path $CsvPath -NoTypeInformation -Encoding UTF8
    Write-Host ("Policy inventory exported to {0}" -f $CsvPath) -ForegroundColor Green
}

Write-Host 'Done. Baseline captured — proceed to build simulation policies (PURVPCI-Config.ps1).' -ForegroundColor Cyan
