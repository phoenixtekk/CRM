<#
.SYNOPSIS
    DLPCMMC-Discovery.ps1 — read-only CUI DLP posture, CUI-label/marking-SIT coverage, and readiness assessment.
.DESCRIPTION
    PURPOSE
        Builds the CUI DLP baseline: every existing DLP compliance policy with its MODE (enforce vs
        simulation vs disabled) and the locations it covers; whether a "CUI" sensitivity label is
        present/published; whether a CUI marking keyword sensitive-information-type exists; and
        licensing/endpoint/tenant readiness signals. Read-only — makes no changes. Run it before you
        build simulation policies.
    HOW TO RUN
        powershell -ExecutionPolicy Bypass -File .\DLPCMMC-Discovery.ps1 -CsvPath .\DLPCMMC-Posture.csv
        Requires Security & Compliance PowerShell (Connect-IPPSSession via ExchangeOnlineManagement).
        GCC High: connect with your environment's parameters and verify the portal endpoint.
    EXPECTED RESULTS
        Console tables of DLP policies (Name, Mode, Locations), CUI sensitivity-label presence, and CUI
        marking-SIT presence, plus an optional CSV of the policy inventory. PASS signal: a published
        "CUI" label is found and the CUI DLP policies you expect are in a Test* (simulation) mode;
        anything already Enable that you did not intend is flagged for review.
.NOTES
    Purview — CMMC / CUI DLP Pack. Read-only against Security & Compliance PowerShell. No changes, no credentials in code.
#>
[CmdletBinding()]
param(
    [string]$CsvPath,
    [string]$LabelName = 'CUI',
    [string]$MarkingSitName = 'CUI Banner Marking - Custom SIT - Classification',
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

Write-Host '=== CUI DLP Posture Assessment (read-only) ===' -ForegroundColor Cyan

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

$cuiPolicies = @($rows | Where-Object { $_.Name -match 'CUI' })
Write-Host ("CUI-named DLP policies found: {0}" -f $cuiPolicies.Count) -ForegroundColor Cyan

$enforcing = @($rows | Where-Object { $_.Enforcing })
if ($enforcing.Count -gt 0) {
    Write-Host ("REVIEW: {0} policy(ies) are ENFORCING (Mode=Enable) — confirm each is intended:" -f $enforcing.Count) -ForegroundColor Yellow
    $enforcing.Name | ForEach-Object { Write-Host "   * $_" -ForegroundColor Yellow }
} else {
    Write-Host 'No enforcing policies found (all in simulation/disabled) — expected during pilot build.' -ForegroundColor Green
}

# --- CUI sensitivity label presence (primary DLP signal) ---
Write-Host '--- CUI sensitivity label ---' -ForegroundColor Cyan
$labelFound = $false
if (Get-Command Get-Label -ErrorAction SilentlyContinue) {
    $labels = Get-Label -ErrorAction SilentlyContinue
    $cuiLabel = @($labels | Where-Object { $_.DisplayName -eq $LabelName -or $_.Name -eq $LabelName })
    if ($cuiLabel.Count -gt 0) {
        $labelFound = $true
        Write-Host ("PASS: sensitivity label '{0}' exists." -f $LabelName) -ForegroundColor Green
        $cuiLabel | Select-Object DisplayName, Name, @{n='Published';e={$_.Disabled -ne $true}} | Format-Table -AutoSize
    } else {
        Write-Host ("MISSING: no '{0}' sensitivity label found — the labeling program must create/publish it before marking-keyed DLP can key off it (Req 2.1)." -f $LabelName) -ForegroundColor Yellow
    }
} else {
    Write-Host 'Get-Label not available (check role / connection) — verify the CUI label in the Purview portal.' -ForegroundColor Yellow
}

# --- CUI marking keyword SIT presence (backstop signal) ---
Write-Host '--- CUI marking keyword SIT ---' -ForegroundColor Cyan
$sitFound = $false
$sits = Get-DlpSensitiveInformationType -ErrorAction SilentlyContinue
if ($sits) {
    $markingSit = @($sits | Where-Object { $_.Name -eq $MarkingSitName -or $_.Name -match 'CUI' })
    if ($markingSit.Count -gt 0) {
        $sitFound = $true
        Write-Host 'PASS: a CUI marking sensitive-information-type is present:' -ForegroundColor Green
        $markingSit | Select-Object Name, Publisher | Format-Table -AutoSize
    } else {
        Write-Host ("MISSING: no CUI marking SIT ('{0}') found — build it from your real CUI markings (Req 2.6)." -f $MarkingSitName) -ForegroundColor Yellow
    }
} else {
    Write-Host 'Could not enumerate SITs (check role / connection).' -ForegroundColor Yellow
}

# --- Endpoint / licensing signal (verify in the admin center / your tenant) ---
Write-Host '--- Endpoint / tenant readiness (signal only — verify in your tenant) ---' -ForegroundColor Cyan
$endpointPolicies = @($rows | Where-Object { $_.Locations -match 'EndpointDlp' })
Write-Host ("Policies using the Endpoint (Devices) location: {0}" -f $endpointPolicies.Count)
Write-Host 'Endpoint DLP + label-based conditions require E5 / E5 Compliance and onboarded devices; GCC High availability differs — verify in your tenant (Req 2.2/2.3/2.5).' -ForegroundColor Gray

# --- Summary ---
Write-Host '--- Baseline summary ---' -ForegroundColor Cyan
Write-Host ("CUI label present : {0}" -f $labelFound)
Write-Host ("CUI marking SIT   : {0}" -f $sitFound)
Write-Host ("CUI DLP policies  : {0}" -f $cuiPolicies.Count)

if ($CsvPath) {
    $rows | Export-Csv -Path $CsvPath -NoTypeInformation -Encoding UTF8
    Write-Host ("Policy inventory exported to {0}" -f $CsvPath) -ForegroundColor Green
}

Write-Host 'Done. Baseline captured — confirm the CUI label, then build simulation policies (DLPCMMC-Config.ps1).' -ForegroundColor Cyan
