<#
.SYNOPSIS
    DLPCLIP-Discovery.ps1 — inventory Endpoint DLP settings + DLP policies covering clipboard & screen-capture (read-only).
.DESCRIPTION
    PURPOSE
        Read-only baseline discovery for clipboard and screen-capture Endpoint DLP. Inventories the DLP
        compliance policies/rules already in the tenant, flags which cover the Devices (endpoint) location and
        their mode (simulation/test vs enable), highlights any rule that already carries a copy-to-clipboard or
        screen-capture restriction, reads the Endpoint DLP settings (allowed/unallowed apps & browsers) where the
        tenant exposes them, and lists sensitivity labels and sensitive information types the rules could key on.
        This is the "what already restricts copy/screenshot on the endpoint" baseline. Changes nothing.
    HOW TO RUN
        PowerShell 5.1+ or 7+ with Security & Compliance PowerShell (Connect-IPPSSession):
          Connect-IPPSSession
          .\DLPCLIP-Discovery.ps1
          .\DLPCLIP-Discovery.ps1 -IncludeSensitiveTypes
    EXPECTED RESULTS
        A CSV baseline (.\DLPCLIP-Discovery.csv) of DLP policies (DevicesLocation flag + Mode), DLP rules (with a
        Clipboard/ScreenCapture-restriction flag), Endpoint DLP settings, and labels; with -IncludeSensitiveTypes,
        sensitive info types to .\DLPCLIP-SensitiveTypes.csv. A tenant with NO Devices-location policy — or none
        carrying a clipboard/screen-capture restriction — is itself the first finding.
.NOTES
    White-label Microsoft Purview tooling. Read-only. No credentials stored. Cmdlets are standard Security &
    Compliance PowerShell (Get-DlpCompliancePolicy/-Rule, Get-PolicyConfig, Get-Label,
    Get-DlpSensitiveInformationType); none are invented. Screen-capture restriction is NEWER / MAY BE IN PREVIEW
    and the restriction Setting names evolve — the script WARNS/degrades where a property is not readable rather
    than asserting availability. VERIFY YOUR LICENSING/TENANT. Device ONBOARDING is confirmed in the Purview
    portal (Settings > Device onboarding); there is no supported S&C PowerShell cmdlet to read onboarding here.
#>
[CmdletBinding()]
param(
    [switch]$IncludeSensitiveTypes,
    [string]$OutPath          = ".\DLPCLIP-Discovery.csv",
    [string]$SensitiveOutPath = ".\DLPCLIP-SensitiveTypes.csv"
)

$ErrorActionPreference = "Stop"
Write-Host "=== DLPCLIP Discovery — clipboard & screen-capture Endpoint DLP baseline (read-only) ===" -ForegroundColor Cyan

try { Get-DlpCompliancePolicy -ErrorAction Stop | Out-Null }
catch {
    Write-Host "Not connected to Security & Compliance PowerShell. Run Connect-IPPSSession first (GR #3)." -ForegroundColor Red
    return
}

$rows = [System.Collections.Generic.List[object]]::new()
function Add-Row($type, $name, $detail) {
    $rows.Add([pscustomobject]@{ ArtifactType = $type; Name = $name; Detail = $detail })
}

# Restriction Setting names for the two activities this solution targets. These EVOLVE / screen capture may be
# in preview — the script only READS them, and matches loosely so tenant-specific naming still surfaces.
$clipTokens   = @("Clipboard","CopyToClipboard","Copy to clipboard")
$screenTokens = @("ScreenCapture","Screen capture","Screenshot")

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

# --- DLP rules: flag any that already carry a clipboard or screen-capture endpoint restriction ---
$clipOrScreen = 0
try {
    $rules = Get-DlpComplianceRule -ErrorAction Stop
    foreach ($r in $rules) {
        $restrictText = ""
        try { if ($r.EndpointDlpRestrictions) { $restrictText = ($r.EndpointDlpRestrictions | Out-String).Trim() } } catch { }
        $hasClip   = $false; $hasScreen = $false
        foreach ($t in $clipTokens)   { if ($restrictText -match [regex]::Escape($t)) { $hasClip   = $true } }
        foreach ($t in $screenTokens) { if ($restrictText -match [regex]::Escape($t)) { $hasScreen = $true } }
        if ($hasClip -or $hasScreen) { $clipOrScreen++ }
        Add-Row "DlpRule" $r.Name ("Policy={0}; Disabled={1}; Clipboard={2}; ScreenCapture={3}" -f $r.Policy, $r.Disabled, $hasClip, $hasScreen)
    }
    Write-Host ("  DLP rules: {0}  (with a clipboard/screen-capture restriction: {1})" -f @($rules).Count, $clipOrScreen) -ForegroundColor Green
    if ($clipOrScreen -eq 0) { Write-Host "  FINDING: no existing rule carries a copy-to-clipboard or screen-capture restriction." -ForegroundColor Yellow }
} catch { Write-Host "  WARN: could not read DLP rules: $($_.Exception.Message)" -ForegroundColor Yellow }

# --- Endpoint DLP settings (allowed/unallowed apps & browsers): READ where the tenant exposes them ---
try {
    $cfg = Get-PolicyConfig -ErrorAction Stop
    Add-Row "EndpointDlpSettings" "Get-PolicyConfig" "Endpoint DLP settings object read — review unallowed/allowed apps & browsers, service domains, and network lists in the portal."
    Write-Host "  Endpoint DLP settings: readable via Get-PolicyConfig (review allowed/unallowed apps & browsers in the portal)." -ForegroundColor Green
} catch {
    Add-Row "EndpointDlpSettings" "Get-PolicyConfig" "Not readable in this tenant/role — confirm in Purview portal > Data loss prevention > Endpoint DLP settings."
    Write-Host "  NOTE: Endpoint DLP settings not readable here (role/tenant). Confirm in the portal (Endpoint DLP settings)." -ForegroundColor DarkYellow
}

# --- Sensitivity labels: what the clipboard/screen-capture rule could key on ---
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

Write-Host "`nReminders:" -ForegroundColor Cyan
Write-Host "  - Confirm device ONBOARDING in Purview portal > Settings > Device onboarding (no PowerShell equivalent here)." -ForegroundColor Cyan
Write-Host "  - Screen-capture restriction is NEWER / MAY BE IN PREVIEW — verify your licensing/tenant." -ForegroundColor DarkYellow
Write-Host "Next: run DLPCLIP-ScopeHealth.ps1 for onboarding/readiness signals, then DLPCLIP-Configure.ps1 -WhatIf to preview the policy." -ForegroundColor Cyan
