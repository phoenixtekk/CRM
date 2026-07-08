<#
.SYNOPSIS
    DLPUSB-Discovery.ps1 — inventory existing DLP policies/rules, Devices coverage, labels, and SITs for removable-media control (read-only).
.DESCRIPTION
    PURPOSE
        Read-only baseline discovery for USB / removable-media DLP. Inventories the DLP compliance policies
        and rules already in the tenant, flags which cover the Devices (endpoint) location and their mode
        (simulation/test vs enable), and lists the sensitivity labels and sensitive information types a
        removable-media rule could key on. This is the "what already protects removable media" baseline
        before you build anything. Changes nothing.
    HOW TO RUN
        PowerShell 5.1+ or 7+ with Security & Compliance PowerShell (Connect-IPPSSession):
          Connect-IPPSSession
          .\DLPUSB-Discovery.ps1
          .\DLPUSB-Discovery.ps1 -IncludeSensitiveTypes
    EXPECTED RESULTS
        A CSV baseline (.\DLPUSB-Discovery.csv) of DLP policies (with a DevicesLocation flag + Mode), DLP
        rules, and labels; with -IncludeSensitiveTypes, sensitive info types to .\DLPUSB-SensitiveTypes.csv.
        A tenant with NO Devices-location policy is itself the first finding.
.NOTES
    White-label Microsoft Purview tooling. Read-only. No credentials stored. Cmdlets are standard Security &
    Compliance PowerShell; none are invented. Endpoint DLP is licensing-dependent — the script WARNS where a
    feature is not readable rather than assuming. Device ONBOARDING, the removable-storage device GROUPS, and
    the DEVICE-CONTROL policy are confirmed in the Purview portal / your management tooling; there is no
    supported S&C PowerShell cmdlet to read them here.
#>
[CmdletBinding()]
param(
    [switch]$IncludeSensitiveTypes,
    [string]$OutPath          = ".\DLPUSB-Discovery.csv",
    [string]$SensitiveOutPath = ".\DLPUSB-SensitiveTypes.csv"
)

$ErrorActionPreference = "Stop"
Write-Host "=== DLPUSB Discovery — removable-media DLP baseline (read-only) ===" -ForegroundColor Cyan

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

# --- Sensitivity labels: what a removable-media rule could key on ---
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

Write-Host "`nReminder: confirm device ONBOARDING + the removable-storage device GROUPS in Purview > Settings/Endpoint DLP settings," -ForegroundColor Cyan
Write-Host "and the DEVICE-CONTROL policy in your management tooling (Intune/GPO/OMA-URI) — no S&C PowerShell equivalent here." -ForegroundColor Cyan
Write-Host "Next: run DLPUSB-ScopeHealth.ps1 for onboarding/scope signals, then DLPUSB-Configure.ps1 -WhatIf to preview the policy." -ForegroundColor Cyan
