<#
.SYNOPSIS
    DLPEXO-Discovery.ps1 — inventory existing Exchange-scoped DLP policies/rules, transport-rule interaction, labels, and SITs (read-only).
.DESCRIPTION
    PURPOSE
        Read-only baseline discovery for Exchange Online DLP. Inventories the DLP compliance policies and
        rules already in the tenant, flags which cover the Exchange (email) location and their Mode
        (simulation/test vs enable), surfaces Exchange mail-flow (transport) rules that already block /
        encrypt / redirect (so DLP does not conflict with them), and lists the sensitivity labels and
        sensitive information types the rules could key on. This is the "what already protects email"
        baseline before you build anything. Changes nothing.
    HOW TO RUN
        PowerShell 5.1+ or 7+ with Security & Compliance PowerShell (Connect-IPPSSession). For transport-rule
        signals also connect Exchange Online (Connect-ExchangeOnline):
          Connect-IPPSSession
          .\DLPEXO-Discovery.ps1
          .\DLPEXO-Discovery.ps1 -IncludeSensitiveTypes
    EXPECTED RESULTS
        A CSV baseline (.\DLPEXO-Discovery.csv) of DLP policies (with an ExchangeLocation flag + Mode), DLP
        rules, labels, and any content/encryption transport rules; with -IncludeSensitiveTypes, sensitive
        info types to .\DLPEXO-SensitiveTypes.csv. A tenant with NO Exchange-location DLP policy is itself
        the first finding.
.NOTES
    White-label Microsoft Purview tooling. Read-only. No credentials stored. Cmdlets are standard Security &
    Compliance PowerShell (Get-DlpCompliancePolicy/-Rule, Get-Label, Get-DlpSensitiveInformationType) and, if
    available, Exchange Online (Get-TransportRule); none are invented. DLP is licensing-dependent — the script
    WARNS where a feature is not readable rather than assuming.
#>
[CmdletBinding()]
param(
    [switch]$IncludeSensitiveTypes,
    [string]$OutPath          = ".\DLPEXO-Discovery.csv",
    [string]$SensitiveOutPath = ".\DLPEXO-SensitiveTypes.csv"
)

$ErrorActionPreference = "Stop"
Write-Host "=== DLPEXO Discovery — Exchange Online DLP baseline (read-only) ===" -ForegroundColor Cyan

try { Get-DlpCompliancePolicy -ErrorAction Stop | Out-Null }
catch {
    Write-Host "Not connected to Security & Compliance PowerShell. Run Connect-IPPSSession first (GR §3)." -ForegroundColor Red
    return
}

$rows = [System.Collections.Generic.List[object]]::new()
function Add-Row($type, $name, $detail) {
    $rows.Add([pscustomobject]@{ ArtifactType = $type; Name = $name; Detail = $detail })
}

# --- DLP policies: flag which cover the Exchange (email) location and their mode ---
try {
    $pols = Get-DlpCompliancePolicy -ErrorAction Stop
    foreach ($p in $pols) {
        # ExchangeLocation presence indicates the Exchange email location is in scope for this policy.
        $hasExchange = $false
        try { if ($null -ne $p.ExchangeLocation -and @($p.ExchangeLocation).Count -gt 0) { $hasExchange = $true } } catch { }
        Add-Row "DlpPolicy" $p.Name ("Mode={0}; ExchangeLocation={1}; Workload={2}" -f $p.Mode, $hasExchange, $p.Workload)
    }
    $exoCount = @($pols | Where-Object { $_.ExchangeLocation -and @($_.ExchangeLocation).Count -gt 0 }).Count
    Write-Host ("  DLP policies: {0}  (with Exchange location: {1})" -f @($pols).Count, $exoCount) -ForegroundColor Green
    if ($exoCount -eq 0) { Write-Host "  FINDING: no DLP policy currently covers the Exchange (email) location." -ForegroundColor Yellow }
} catch { Write-Host "  WARN: could not read DLP policies: $($_.Exception.Message)" -ForegroundColor Yellow }

# --- DLP rules: name, parent policy, disabled state ---
try {
    $rules = Get-DlpComplianceRule -ErrorAction Stop
    foreach ($r in $rules) { Add-Row "DlpRule" $r.Name ("Policy={0}; Disabled={1}" -f $r.Policy, $r.Disabled) }
    Write-Host ("  DLP rules: {0}" -f @($rules).Count) -ForegroundColor Green
} catch { Write-Host "  WARN: could not read DLP rules: $($_.Exception.Message)" -ForegroundColor Yellow }

# --- Exchange transport (mail-flow) rules that already act on content / encryption / block (R7 interaction) ---
try {
    if (Get-Command Get-TransportRule -ErrorAction SilentlyContinue) {
        $trs = Get-TransportRule -ErrorAction Stop
        $interesting = $trs | Where-Object {
            $_.BlockedRecipientMessage -or $_.RejectMessageReasonText -or $_.ApplyOME -or $_.ApplyRightsProtectionTemplate `
            -or $_.RemoveOME -or $_.DeleteMessage -or $_.RedirectMessageTo -or $_.MessageContainsDataClassifications
        }
        foreach ($t in $interesting) {
            $acts = @()
            if ($t.RejectMessageReasonText -or $t.BlockedRecipientMessage) { $acts += "block/reject" }
            if ($t.ApplyOME -or $t.ApplyRightsProtectionTemplate)          { $acts += "encrypt" }
            if ($t.DeleteMessage)                                          { $acts += "delete" }
            if ($t.RedirectMessageTo)                                      { $acts += "redirect" }
            if ($t.MessageContainsDataClassifications)                     { $acts += "content-classification" }
            Add-Row "TransportRule" $t.Name ("Actions={0}; State={1}" -f ($acts -join '+'), $t.State)
        }
        Write-Host ("  Transport rules with content/encrypt/block/redirect actions: {0} of {1} (review for DLP overlap — R7)" -f @($interesting).Count, @($trs).Count) -ForegroundColor Green
        if (@($interesting).Count -gt 0) { Write-Host "  FINDING: reconcile these mail-flow rules with the DLP policy before enforcing (see 02-requirements R7)." -ForegroundColor Yellow }
    } else {
        Write-Host "  (Get-TransportRule not available — connect Exchange Online (Connect-ExchangeOnline) to inventory mail-flow rules; review R7 manually.)" -ForegroundColor Gray
    }
} catch { Write-Host "  WARN: could not read transport rules: $($_.Exception.Message)" -ForegroundColor Yellow }

# --- Sensitivity labels: what the rules could key on ---
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

Write-Host "`nNext: run DLPEXO-ScopeHealth.ps1 for scope/precedence signals, then DLPEXO-Configure.ps1 -WhatIf to preview the policy." -ForegroundColor Cyan
