<#
.SYNOPSIS
    DLPASSESS-Discovery.ps1 — read-only Microsoft Purview DLP posture baseline for an assessment.
.DESCRIPTION
    PURPOSE
        Builds the DLP posture baseline for a "know what to protect before you write a policy"
        assessment: every existing DLP compliance policy with its MODE (enforce vs simulation vs
        disabled) and locations, a summary of sensitive information types (built-in vs custom), and
        the sensitivity/retention labels present in the tenant. Read-only — makes no changes. It flags
        any policy already in ENFORCE mode so the assessment does not mistake it for a monitor-only one.
    HOW TO RUN
        powershell -ExecutionPolicy Bypass -File .\DLPASSESS-Discovery.ps1 -CsvPath .\DLPASSESS-Posture.csv
        Requires Security & Compliance PowerShell (Connect-IPPSSession via ExchangeOnlineManagement).
.EXAMPLE
    .\DLPASSESS-Discovery.ps1
    Prints the posture baseline (policies + modes, SIT coverage, labels) to the console.
.EXAMPLE
    .\DLPASSESS-Discovery.ps1 -CsvPath .\DLPASSESS-Posture.csv -UserPrincipalName admin@contoso.com
    Same, plus exports the policy inventory to CSV.
.NOTES
    Purview — Enterprise DLP Assessment & Strategy. Read-only against Security & Compliance PowerShell.
    EXPECTED RESULTS: a table of DLP policies (Name, Mode, Locations), SIT counts, and labels. PASS
    signal: policies you expect are in simulation report a Test* mode; anything in Enable you did not
    intend is flagged for review.
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

Write-Host '=== Purview DLP Posture Baseline (read-only) ===' -ForegroundColor Cyan

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
    Write-Host ("REVIEW: {0} policy(ies) are ENFORCING (Mode=Enable) — confirm each is intended before assessing:" -f $enforcing.Count) -ForegroundColor Yellow
    $enforcing.Name | ForEach-Object { Write-Host "   * $_" -ForegroundColor Yellow }
} else {
    Write-Host 'No enforcing policies found — expected for a monitor-only assessment tenant.' -ForegroundColor Green
}

# --- Sensitive information type coverage ---
Write-Host '--- Sensitive Information Type coverage ---' -ForegroundColor Cyan
$sits = Get-DlpSensitiveInformationType -ErrorAction SilentlyContinue
if ($sits) {
    $builtIn = @($sits | Where-Object { $_.Publisher -match 'Microsoft' })
    $custom  = @($sits | Where-Object { $_.Publisher -notmatch 'Microsoft' })
    Write-Host ("Built-in SITs: {0}   Custom SITs: {1}   Total: {2}" -f $builtIn.Count, $custom.Count, $sits.Count)
    if ($custom.Count -gt 0) {
        Write-Host 'Custom SITs present (candidate detectors for the roadmap):' -ForegroundColor Cyan
        $custom | Select-Object Name, Publisher | Format-Table -AutoSize
    }
} else {
    Write-Host 'Could not enumerate SITs (check role / connection).' -ForegroundColor Yellow
}

# --- Sensitivity & retention labels present (context for the data map) ---
if (Get-Command Get-Label -ErrorAction SilentlyContinue) {
    $labels = Get-Label -ErrorAction SilentlyContinue
    Write-Host ("Sensitivity labels defined: {0}" -f (@($labels).Count)) -ForegroundColor Cyan
}
if (Get-Command Get-ComplianceTag -ErrorAction SilentlyContinue) {
    $tags = Get-ComplianceTag -ErrorAction SilentlyContinue
    Write-Host ("Retention labels defined: {0}" -f (@($tags).Count)) -ForegroundColor Cyan
}

if ($CsvPath) {
    $rows | Export-Csv -Path $CsvPath -NoTypeInformation -Encoding UTF8
    Write-Host ("Policy inventory exported to {0}" -f $CsvPath) -ForegroundColor Green
}

Write-Host 'Done. Posture baselined — next: DLPASSESS-Validation.ps1 (readiness) then DLPASSESS-DataScan.ps1 (data at rest).' -ForegroundColor Cyan
