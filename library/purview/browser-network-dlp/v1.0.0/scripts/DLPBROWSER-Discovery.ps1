<#
.SYNOPSIS
    DLPBROWSER-Discovery.ps1 — inventory Devices-scoped DLP policies, sensitive service domains, and unallowed-browser posture (read-only).
.DESCRIPTION
    PURPOSE
        Read-only baseline for Browser & Network DLP. Inventories the DLP compliance policies/rules already
        in the tenant and flags which cover the Devices (endpoint) location and their mode (simulation/test
        vs enable); reads the Endpoint DLP browser/network settings (sensitive service domain groups and the
        unallowed-browsers list) via Get-PolicyConfig; and lists the sensitivity labels and sensitive
        information types the upload-restriction rule could key on. This is the "what already controls web
        uploads" baseline before you build anything. Changes nothing.
    HOW TO RUN
        PowerShell 5.1+ or 7+ with Security & Compliance PowerShell (Connect-IPPSSession):
          Connect-IPPSSession
          .\DLPBROWSER-Discovery.ps1
          .\DLPBROWSER-Discovery.ps1 -IncludeSensitiveTypes
    EXPECTED RESULTS
        A CSV baseline (.\DLPBROWSER-Discovery.csv) of DLP policies (DevicesLocation flag + Mode), rules,
        labels, and the endpoint browser/domain settings it could read; with -IncludeSensitiveTypes, SITs to
        .\DLPBROWSER-SensitiveTypes.csv. A tenant with NO Devices-location policy or NO sensitive service
        domain group is itself the first finding.
.NOTES
    White-label Microsoft Purview tooling. Read-only. No credentials stored. Cmdlets are standard Security &
    Compliance PowerShell (Get-DlpCompliancePolicy/-Rule, Get-Label, Get-PolicyConfig); none are invented.
    Endpoint DLP is licensing-dependent and the browser/domain SETTINGS surface (Get-PolicyConfig shape and
    the Endpoint DLP settings portal path) EVOLVES — the script WARNS where a value is not readable rather
    than assuming, and device ONBOARDING is confirmed in the Purview portal (Settings > Device onboarding),
    which has no supported S&C PowerShell read here. Verify surfaces in your tenant.
#>
[CmdletBinding()]
param(
    [switch]$IncludeSensitiveTypes,
    [string]$OutPath          = ".\DLPBROWSER-Discovery.csv",
    [string]$SensitiveOutPath = ".\DLPBROWSER-SensitiveTypes.csv"
)

$ErrorActionPreference = "Stop"
Write-Host "=== DLPBROWSER Discovery — Browser & Network DLP baseline (read-only) ===" -ForegroundColor Cyan

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

# --- DLP rules: name, parent policy, disabled state (helps spot an existing upload-restriction rule) ---
try {
    $rules = Get-DlpComplianceRule -ErrorAction Stop
    foreach ($r in $rules) { Add-Row "DlpRule" $r.Name ("Policy={0}; Disabled={1}" -f $r.Policy, $r.Disabled) }
    Write-Host ("  DLP rules: {0}" -f @($rules).Count) -ForegroundColor Green
} catch { Write-Host "  WARN: could not read DLP rules: $($_.Exception.Message)" -ForegroundColor Yellow }

# --- Endpoint DLP browser/network settings: sensitive service domain groups + unallowed browsers ---
# NOTE: these live in Endpoint DLP settings (portal: Data Loss Prevention > Endpoint DLP settings >
# Browser and domain restrictions to sensitive data). The Get-PolicyConfig surface and property shape
# EVOLVE — read defensively and WARN rather than assume.
try {
    $cfg = Get-PolicyConfig -ErrorAction Stop
    Write-Host "  Endpoint DLP settings (Get-PolicyConfig) read OK — parsing browser/domain posture..." -ForegroundColor Green

    # Sensitive service domain groups (unsanctioned/personal cloud destinations)
    $domGroups = $null
    foreach ($prop in @('SensitiveServiceDomainGroups','EndpointDlpSensitiveServiceDomains','SensitiveServiceDomains')) {
        if ($cfg.PSObject.Properties.Name -contains $prop -and $cfg.$prop) { $domGroups = $cfg.$prop; $foundProp = $prop; break }
    }
    if ($domGroups) {
        Add-Row "SensitiveServiceDomainGroups" $foundProp ("Count~={0}" -f @($domGroups).Count)
        Write-Host ("    Sensitive service domain group data present (property '{0}')." -f $foundProp) -ForegroundColor Green
    } else {
        Add-Row "SensitiveServiceDomainGroups" "(none readable)" "No sensitive service domain group readable via Get-PolicyConfig — verify in portal."
        Write-Host "    FINDING: no sensitive service domain group readable here — verify Endpoint DLP settings in the portal." -ForegroundColor Yellow
    }

    # Unallowed browsers list
    $unallowed = $null
    foreach ($prop in @('UnallowedBrowsers','EndpointDlpUnallowedBrowsers','UnallowedApps')) {
        if ($cfg.PSObject.Properties.Name -contains $prop -and $cfg.$prop) { $unallowed = $cfg.$prop; $ub = $prop; break }
    }
    if ($unallowed) {
        Add-Row "UnallowedBrowsers" $ub ("Value(s): {0}" -f (@($unallowed) -join ', '))
        Write-Host ("    Unallowed-browsers data present (property '{0}')." -f $ub) -ForegroundColor Green
    } else {
        Add-Row "UnallowedBrowsers" "(none readable)" "No unallowed-browsers value readable via Get-PolicyConfig — verify in portal."
        Write-Host "    FINDING: no unallowed-browsers value readable here — verify Endpoint DLP settings in the portal." -ForegroundColor Yellow
    }
} catch {
    Write-Host "  WARN: could not read Endpoint DLP settings via Get-PolicyConfig (licensing/permission/cmdlet shape): $($_.Exception.Message)" -ForegroundColor Yellow
    Write-Host "        Fall back to Purview portal > Data Loss Prevention > Endpoint DLP settings > Browser and domain restrictions (verify path)." -ForegroundColor Yellow
    Add-Row "EndpointDlpSettings" "(unreadable)" "Get-PolicyConfig not available in this tenant/session — confirm settings in the portal."
}

# --- Sensitivity labels: what the upload-restriction rule could key on ---
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
Write-Host "Next: run DLPBROWSER-ScopeHealth.ps1 for onboarding/extension/network readiness, then DLPBROWSER-Configure.ps1 -WhatIf to preview the policy." -ForegroundColor Cyan
