<#
.SYNOPSIS
    PURVDLP-Discovery.ps1 — read-only Microsoft Purview DLP posture + sensitive-info-type coverage assessment.
.DESCRIPTION
    PURPOSE
        Builds the DLP baseline: every existing DLP compliance policy with its MODE (enforce vs
        simulation vs disabled) and the locations it covers, plus a summary of sensitive information
        types (built-in vs custom) and any EDM schemas available in the tenant. Read-only — makes no
        changes. Use it to see what already exists before you build simulation policies.
    HOW TO RUN
        powershell -ExecutionPolicy Bypass -File .\PURVDLP-Discovery.ps1 -CsvPath .\PURVDLP-Posture.csv
        Requires Security & Compliance PowerShell (Connect-IPPSSession via ExchangeOnlineManagement).
    EXPECTED RESULTS
        A console table of DLP policies (Name, Mode, Locations) and SIT coverage (built-in / custom /
        EDM counts), plus an optional CSV of the policy inventory. PASS signal: policies you expect to
        be in simulation report a Test* mode; anything already in Enable that you did not intend is
        flagged for review.
.NOTES
    Purview — Data Loss Prevention (Endpoint, Cloud & Email). Read-only against Security & Compliance PowerShell.
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

Write-Host '=== Purview DLP Posture Assessment (read-only) ===' -ForegroundColor Cyan

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

# --- Sensitive information type coverage ---
Write-Host '--- Sensitive Information Type coverage ---' -ForegroundColor Cyan
$sits = Get-DlpSensitiveInformationType -ErrorAction SilentlyContinue
if ($sits) {
    $builtIn = @($sits | Where-Object { $_.Publisher -match 'Microsoft' })
    $custom  = @($sits | Where-Object { $_.Publisher -notmatch 'Microsoft' })
    Write-Host ("Built-in SITs: {0}   Custom SITs: {1}   Total: {2}" -f $builtIn.Count, $custom.Count, $sits.Count)
    if ($custom.Count -gt 0) {
        Write-Host 'Custom SITs present:' -ForegroundColor Cyan
        $custom | Select-Object Name, Publisher | Format-Table -AutoSize
    }
} else {
    Write-Host 'Could not enumerate SITs (check role / connection).' -ForegroundColor Yellow
}

# --- EDM schemas (near-zero-FP matching), if any ---
if (Get-Command Get-DlpEdmSchema -ErrorAction SilentlyContinue) {
    $edm = Get-DlpEdmSchema -ErrorAction SilentlyContinue
    Write-Host ("EDM schemas configured: {0}" -f (@($edm).Count))
}

if ($CsvPath) {
    $rows | Export-Csv -Path $CsvPath -NoTypeInformation -Encoding UTF8
    Write-Host ("Policy inventory exported to {0}" -f $CsvPath) -ForegroundColor Green
}

Write-Host 'Done. Baseline captured — proceed to build simulation policies (PURVDLP-Config.ps1).' -ForegroundColor Cyan
