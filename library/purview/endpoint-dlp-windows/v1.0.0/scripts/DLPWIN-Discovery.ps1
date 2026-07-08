<#
.SYNOPSIS
    DLPWIN-Discovery.ps1 — inventory existing DLP policies/rules, Devices coverage, labels, and SITs (read-only).
.DESCRIPTION
    PURPOSE
        Read-only baseline discovery for Windows Endpoint DLP. Inventories the DLP compliance policies and
        rules already in the tenant, flags which cover the Devices (endpoint) location and their mode
        (simulation/test vs enable), and lists the sensitivity labels and sensitive information types the
        endpoint rules could key on. This is the "what already protects the endpoints" baseline before you
        build anything. Changes nothing.
    HOW TO RUN
        PowerShell 5.1+ or 7+ with Security & Compliance PowerShell (Connect-IPPSSession):
          Connect-IPPSSession
          .\DLPWIN-Discovery.ps1
          .\DLPWIN-Discovery.ps1 -IncludeSensitiveTypes
    EXPECTED RESULTS
        A CSV baseline (.\DLPWIN-Discovery.csv) of DLP policies (with a DevicesLocation flag + Mode), DLP
        rules, and labels; with -IncludeSensitiveTypes, sensitive info types to .\DLPWIN-SensitiveTypes.csv.
        A tenant with NO Devices-location policy is itself the first finding.
.NOTES
    White-label Microsoft Purview tooling. Read-only. No credentials stored. Cmdlets are standard Security &
    Compliance PowerShell; none are invented. Endpoint DLP is licensing-dependent — the script WARNS where a
    feature is not readable rather than assuming. Device ONBOARDING status is confirmed in the Purview portal
    (Settings > Device onboarding); there is no supported S&C PowerShell cmdlet to read onboarding here.
#>
[CmdletBinding()]
param(
    [switch]$IncludeSensitiveTypes,
    [string]$OutPath          = ".\DLPWIN-Discovery.csv",
    [string]$SensitiveOutPath = ".\DLPWIN-SensitiveTypes.csv"
)

$ErrorActionPreference = "Stop"
Write-Host "=== DLPWIN Discovery — Endpoint DLP baseline (read-only) ===" -ForegroundColor Cyan

try { Get-DlpCompliancePolicy -ErrorAction Stop | Out-Null }
catch {
    Write-Host "Not connected to Security & Compliance PowerShell. Run Connect-IPPSSession first (GR §3)." -ForegroundColor Red
    return
}

$rows = [System.Collections.Generic.List[object]]::new()
function Add-Row($type, $name, $detail) {
    $rows.Add([pscustomobject]@{ ArtifactType = $type; Name = $name; Detail = $detail })
}

# --- DLP policies: flag which cover the Devices (endpoint) location and their mode ---
try {
    $pols = Get-DlpCompliancePolicy -ErrorAction Stop
    foreach ($p in $pols) {
        # EndpointDlpLocation presence indicates the Devices location is in scope for this policy.
        $hasDevices = $false
        try { if ($null -ne $p.EndpointDlpLocation -and @($p.EndpointDlpLocation).Count -gt 0) { $hasDevices = $true } } catch { }
        Add-Row "DlpPolicy" $p.Name ("Mode={0}; DevicesLocation={1}; Workload={2}" -f $p.Mode, $hasDevices, $p.Workload)
    }
    $devCount = @($pols | Where-Object { $_.EndpointDlpLocation -and @($_.EndpointDlpLocation).Count -gt 0 }).Count
    Write-Host ("  DLP policies: {0}  (with Devices location: {1})" -f @($pols).Count, $devCount) -ForegroundColor Green
    if ($devCount -eq 0) { Write-Host "  FINDING: no DLP policy currently covers the Devices (endpoint) location." -ForegroundColor Yellow }
} catch { Write-Host "  WARN: could not read DLP policies: $($_.Exception.Message)" -ForegroundColor Yellow }

# --- DLP rules: name, parent policy, disabled state ---
try {
    $rules = Get-DlpComplianceRule -ErrorAction Stop
    foreach ($r in $rules) { Add-Row "DlpRule" $r.Name ("Policy={0}; Disabled={1}" -f $r.Policy, $r.Disabled) }
    Write-Host ("  DLP rules: {0}" -f @($rules).Count) -ForegroundColor Green
} catch { Write-Host "  WARN: could not read DLP rules: $($_.Exception.Message)" -ForegroundColor Yellow }

# --- Sensitivity labels: what endpoint rules could key on ---
try {
    $labels = Get-Label -ErrorAction Stop
    foreach ($l in $labels) { Add-Row "SensitivityLabel" $l.DisplayName ("Priority={0}; Enabled={1}" -f $l.Priority, $l.Enabled) }
    Write-Host ("  Sensitivity labels: {0}" -f @($labels).Count) -ForegroundColor Green
} catch { Write-Host "  WARN: could not read sensitivity labels (may be unlicensed): $($_.Exception.Message)" -ForegroundColor Yellow }

$rows | Export-Csv -Path $OutPath -NoTypeInformation -Encoding UTF8
Write-Host ("`nBaseline written to {0}" -f $OutPath) -ForegroundColor Green

# --- Optional: sensitive information types in scope ---
if ($IncludeSensitiveTypes) {
    try {
        $sits = Get-DlpSensitiveInformationType -ErrorAction Stop
        $sits | Select-Object Name, Publisher, RulePackId |
            Export-Csv -Path $SensitiveOutPath -NoTypeInformation -Encoding UTF8
        Write-Host ("Sensitive information types written to {0}: {1} type(s)" -f $SensitiveOutPath, @($sits).Count) -ForegroundColor Green
    } catch { Write-Host "  WARN: could not read sensitive information types: $($_.Exception.Message)" -ForegroundColor Yellow }
}

Write-Host "`nReminder: confirm device ONBOARDING in Purview portal > Settings > Device onboarding (no PowerShell equivalent here)." -ForegroundColor Cyan
Write-Host "Next: run DLPWIN-ScopeHealth.ps1 for onboarding/scope signals, then DLPWIN-Configure.ps1 -WhatIf to preview the policy." -ForegroundColor Cyan
