<#
.SYNOPSIS
    OPSOPT-Discovery.ps1 — read-only inventory of Purview DLP, auto-labeling, and alert policies and their tunable settings. Makes no changes.
.DESCRIPTION
    PURPOSE
        Baselines the current policy set being tuned: every DLP policy with its Mode
        (Enable / TestWithNotifications / TestWithoutNotifications / Disable) and each rule's
        sensitive-information-type confidence level and instance-count; every auto-labeling policy and
        whether it is in simulation; every alert policy with its threshold/aggregation; and the unified
        audit-log ingestion state. Read-only — nothing is modified.
    HOW TO RUN
        PowerShell 5.1+/7+. Connect first:
          Connect-IPPSSession                # Security & Compliance PowerShell (DLP / labels / alerts)
          Connect-ExchangeOnline             # for Get-AdminAuditLogConfig
        Then:
          .\OPSOPT-Discovery.ps1 -OutputFolder .\OPSOPT-out
    EXPECTED RESULTS
        A console summary and (optional) CSVs of every DLP/auto-label/alert policy and its tunable
        settings, plus the audit-ingestion state — the tuning baseline. No changes are made.
.NOTES
    Purview — Optimization & Tune-Up. Read-only against Security & Compliance / Exchange Online PowerShell.
    Cmdlet availability is licensing-/tenant-dependent (E5 / E5 Compliance for advanced surfaces) — verify your tenant.
#>
[CmdletBinding()]
param(
    [string]$OutputFolder
)

function Confirm-Cmd([string]$name) {
    if (-not (Get-Command $name -ErrorAction SilentlyContinue)) {
        Write-Warning ("Cmdlet '{0}' not available — connect the right session / verify licensing. Skipping that section." -f $name)
        return $false
    }
    return $true
}

if ($OutputFolder -and -not (Test-Path $OutputFolder)) { New-Item -ItemType Directory -Path $OutputFolder -Force | Out-Null }
Write-Host "=== OPSOPT Discovery (read-only) ===" -ForegroundColor Cyan

# --- DLP policies + rules (mode, confidence, instance count) ---
$dlpRows = @()
if (Confirm-Cmd 'Get-DlpCompliancePolicy') {
    $policies = Get-DlpCompliancePolicy
    Write-Host ("--- DLP policies: {0} ---" -f @($policies).Count) -ForegroundColor Cyan
    $policies | Select-Object Name, Mode, Enabled | Sort-Object Name | Format-Table -AutoSize
    if (Confirm-Cmd 'Get-DlpComplianceRule') {
        foreach ($p in $policies) {
            $rules = Get-DlpComplianceRule -Policy $p.Name -ErrorAction SilentlyContinue
            foreach ($r in $rules) {
                # ContentContainsSensitiveInformation carries per-SIT minconfidence / mincount / maxcount
                $sit = @()
                if ($r.ContentContainsSensitiveInformation) {
                    foreach ($s in @($r.ContentContainsSensitiveInformation)) {
                        $sit += ("{0}(min={1},max={2},conf={3})" -f $s.name, $s.mincount, $s.maxcount, $s.minconfidence)
                    }
                }
                $dlpRows += [pscustomobject]@{
                    Policy        = $p.Name
                    PolicyMode    = $p.Mode
                    Rule          = $r.Name
                    RuleDisabled  = $r.Disabled
                    SensitiveInfo = ($sit -join '; ')
                    HasExceptions = [bool]($r.PSObject.Properties.Name -match '^ExceptIf')
                }
            }
        }
        Write-Host ("--- DLP rules: {0} ---" -f $dlpRows.Count) -ForegroundColor Cyan
        $dlpRows | Format-Table Policy, Rule, SensitiveInfo, HasExceptions -AutoSize
    }
}

# --- Auto-labeling policies (simulation state) ---
$autoRows = @()
if (Confirm-Cmd 'Get-AutoSensitivityLabelPolicy') {
    $auto = Get-AutoSensitivityLabelPolicy -ErrorAction SilentlyContinue
    foreach ($a in $auto) {
        $autoRows += [pscustomobject]@{ Name = $a.Name; Mode = $a.Mode; Enabled = $a.Enabled }
    }
    Write-Host ("--- Auto-labeling policies: {0} ---" -f $autoRows.Count) -ForegroundColor Cyan
    $autoRows | Format-Table -AutoSize
}

# --- Alert policies (threshold / aggregation) ---
$alertRows = @()
if (Confirm-Cmd 'Get-ProtectionAlert') {
    $alerts = Get-ProtectionAlert -ErrorAction SilentlyContinue
    foreach ($al in $alerts) {
        $alertRows += [pscustomobject]@{
            Name           = $al.Name
            Disabled       = $al.Disabled
            Threshold      = $al.Threshold
            AggregationType= $al.AggregationType
            Severity       = $al.Severity
            NotifyUser     = ((@($al.NotifyUser)) -join ';')
        }
    }
    Write-Host ("--- Alert policies: {0} ---" -f $alertRows.Count) -ForegroundColor Cyan
    $alertRows | Sort-Object Name | Format-Table Name, Threshold, AggregationType, Severity -AutoSize
}

# --- Insider Risk: readable role/state signal only (policy tuning is portal-driven) ---
Write-Host "--- Insider Risk Management ---" -ForegroundColor Cyan
Write-Host "  IRM policy tuning is portal-driven (Purview portal > Insider Risk Management > Policies)." -ForegroundColor DarkGray
Write-Host "  No IRM configuration cmdlets are used here; tune indicators/thresholds in the portal under" -ForegroundColor DarkGray
Write-Host "  a SEPARATE Insider Risk role, privacy settings on. See Implementation Step 9." -ForegroundColor DarkGray
if (Confirm-Cmd 'Get-RoleGroupMember') {
    foreach ($rg in 'Insider Risk Management','Insider Risk Management Admins') {
        $m = Get-RoleGroupMember -Identity $rg -ErrorAction SilentlyContinue
        if ($m) { Write-Host ("  Role '{0}': {1} member(s)" -f $rg, @($m).Count) -ForegroundColor DarkGray }
    }
}

# --- Audit ingestion state ---
if (Confirm-Cmd 'Get-AdminAuditLogConfig') {
    $ing = (Get-AdminAuditLogConfig).UnifiedAuditLogIngestionEnabled
    Write-Host ("--- Unified audit log ingestion: {0} ---" -f $ing) -ForegroundColor $(if ($ing) { 'Green' } else { 'Yellow' })
    if (-not $ing) { Write-Warning "Audit ingestion is OFF — noise/false-positive reporting will be incomplete (Requirement 2.4)." }
}

if ($OutputFolder) {
    if ($dlpRows.Count)   { $dlpRows   | Export-Csv (Join-Path $OutputFolder 'discovery-dlp-rules.csv')     -NoTypeInformation }
    if ($autoRows.Count)  { $autoRows  | Export-Csv (Join-Path $OutputFolder 'discovery-autolabel.csv')     -NoTypeInformation }
    if ($alertRows.Count) { $alertRows | Export-Csv (Join-Path $OutputFolder 'discovery-alert-policies.csv') -NoTypeInformation }
    Write-Host ("Saved discovery CSVs to {0}" -f $OutputFolder) -ForegroundColor Green
}
Write-Host "=== Discovery complete (no changes made) ===" -ForegroundColor Cyan
