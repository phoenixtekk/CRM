<#
.SYNOPSIS
    DLPTEAMS-Discovery.ps1 — inventory existing DLP policies/rules, Teams/SharePoint/OneDrive coverage, labels, and SITs (read-only).
.DESCRIPTION
    PURPOSE
        Read-only baseline discovery for Teams DLP. Inventories the DLP compliance policies and rules already
        in the tenant, flags for each whether it covers the Teams-messages, SharePoint, and OneDrive
        locations (so you can see whether Teams messages AND shared files are governed), reports each
        policy's mode (simulation/test vs enable), and lists the sensitivity labels and sensitive information
        types the rules could key on. Also surfaces any DEFAULT Teams DLP policy. Changes nothing.
    HOW TO RUN
        PowerShell 5.1+ or 7+ with Security & Compliance PowerShell (Connect-IPPSSession):
          Connect-IPPSSession
          .\DLPTEAMS-Discovery.ps1
          .\DLPTEAMS-Discovery.ps1 -IncludeSensitiveTypes
    EXPECTED RESULTS
        A CSV baseline (.\DLPTEAMS-Discovery.csv) of DLP policies (with Teams/SharePoint/OneDrive location
        flags + Mode), DLP rules, and labels; with -IncludeSensitiveTypes, sensitive info types to
        .\DLPTEAMS-SensitiveTypes.csv. A policy that covers Teams messages but NOT SharePoint/OneDrive is
        flagged as a files-uncovered gap.
.NOTES
    White-label Microsoft Purview tooling. Read-only. No credentials stored. Cmdlets are standard Security &
    Compliance PowerShell; none are invented. Teams message DLP is licensing-dependent — the script WARNS
    where a feature is not readable rather than assuming.
#>
[CmdletBinding()]
param(
    [switch]$IncludeSensitiveTypes,
    [string]$OutPath          = ".\DLPTEAMS-Discovery.csv",
    [string]$SensitiveOutPath = ".\DLPTEAMS-SensitiveTypes.csv"
)

$ErrorActionPreference = "Stop"
Write-Host "=== DLPTEAMS Discovery — Teams DLP baseline (read-only) ===" -ForegroundColor Cyan

try { Get-DlpCompliancePolicy -ErrorAction Stop | Out-Null }
catch {
    Write-Host "Not connected to Security & Compliance PowerShell. Run Connect-IPPSSession first (GR §3)." -ForegroundColor Red
    return
}

$rows = [System.Collections.Generic.List[object]]::new()
function Add-Row($type, $name, $detail) {
    $rows.Add([pscustomobject]@{ ArtifactType = $type; Name = $name; Detail = $detail })
}
function Has-Location($val) {
    try { return ($null -ne $val -and @($val).Count -gt 0) } catch { return $false }
}

# --- DLP policies: flag Teams / SharePoint / OneDrive coverage and mode ---
try {
    $pols = Get-DlpCompliancePolicy -ErrorAction Stop
    foreach ($p in $pols) {
        $hasTeams = Has-Location $p.TeamsLocation
        $hasSpo   = Has-Location $p.SharePointLocation
        $hasOd    = Has-Location $p.OneDriveLocation
        Add-Row "DlpPolicy" $p.Name ("Mode={0}; Teams={1}; SharePoint={2}; OneDrive={3}" -f $p.Mode, $hasTeams, $hasSpo, $hasOd)
        if ($hasTeams -and -not ($hasSpo -and $hasOd)) {
            Write-Host ("  GAP: policy '{0}' covers Teams MESSAGES but not both SharePoint+OneDrive — Teams-SHARED FILES may be uncovered." -f $p.Name) -ForegroundColor Yellow
        }
    }
    $teamsCount = @($pols | Where-Object { Has-Location $_.TeamsLocation }).Count
    Write-Host ("  DLP policies: {0}  (with Teams-messages location: {1})" -f @($pols).Count, $teamsCount) -ForegroundColor Green
    if ($teamsCount -eq 0) { Write-Host "  FINDING: no DLP policy currently covers the Teams chat/channel messages location." -ForegroundColor Yellow }
} catch { Write-Host "  WARN: could not read DLP policies: $($_.Exception.Message)" -ForegroundColor Yellow }

# --- DLP rules: name, parent policy, disabled state ---
try {
    $rules = Get-DlpComplianceRule -ErrorAction Stop
    foreach ($r in $rules) { Add-Row "DlpRule" $r.Name ("Policy={0}; Disabled={1}" -f $r.Policy, $r.Disabled) }
    Write-Host ("  DLP rules: {0}" -f @($rules).Count) -ForegroundColor Green
} catch { Write-Host "  WARN: could not read DLP rules: $($_.Exception.Message)" -ForegroundColor Yellow }

# --- Sensitivity labels: what Teams rules could key on ---
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

Write-Host "`nReminder: a complete Teams DLP covers Teams MESSAGES + SharePoint (channel files) + OneDrive (chat files)." -ForegroundColor Cyan
Write-Host "Next: run DLPTEAMS-ScopeHealth.ps1 for pilot-scope signals, then DLPTEAMS-Configure.ps1 -WhatIf to preview the policy." -ForegroundColor Cyan
