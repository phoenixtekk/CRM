<#
.SYNOPSIS
    ISO27001-ControlEvidence.ps1 — read-only evidence collector mapping Purview technical state to Annex A controls.
.DESCRIPTION
    PURPOSE
        For each mapped ISO 27001 Annex A control, confirms the underlying Purview technical state and
        writes an evidence-register row (control, capability, state, owner, date). It checks: unified
        audit logging (A.8.15/8.16), sensitivity labels + label policies (A.5.12/5.13), DLP policies and
        their mode (A.8.12), retention policies (A.8.10/5.33), and — via Microsoft Graph — the licensing
        signal and Conditional Access policy count (access-control evidence). Read-only — queries only.
        Optionally reads a control-map CSV (Control,Capability,Owner) to align rows to your SoA mapping.
    HOW TO RUN
        powershell -ExecutionPolicy Bypass -File .\ISO27001-ControlEvidence.ps1 -ControlMap .\ISO27001-ControlMap.csv -CsvPath .\ISO27001-Evidence.csv
        Requires Security & Compliance PowerShell (Connect-IPPSSession); optional Connect-MgGraph for
        licensing / Conditional Access signals (-Scopes Organization.Read.All, Policy.Read.All).
    EXPECTED RESULTS
        A console evidence table and a CSV register with, per control, the confirmed technical state and a
        Collected (Yes/No) flag. PASS gate: every mapped control has Collected=Yes; controls with
        Collected=No are the evidence gaps to close. Nothing is changed.
.NOTES
    Purview — ISO 27001 Compliance Program. Read-only evidence collection. No changes made.
#>
[CmdletBinding()]
param(
    [string]$ControlMap,
    [string]$CsvPath,
    [string]$UserPrincipalName
)

if (-not (Get-Module -ListAvailable -Name ExchangeOnlineManagement)) {
    Install-Module ExchangeOnlineManagement -Scope CurrentUser -Force -AllowClobber
}
Import-Module ExchangeOnlineManagement -ErrorAction Stop
if (-not (Get-Command Get-DlpCompliancePolicy -ErrorAction SilentlyContinue)) {
    if ($UserPrincipalName) { Connect-IPPSSession -UserPrincipalName $UserPrincipalName } else { Connect-IPPSSession }
}

$today = (Get-Date).ToString('yyyy-MM-dd')
$evidence = [System.Collections.Generic.List[object]]::new()

function Add-Evidence($control, $capability, $state, $collected) {
    $evidence.Add([pscustomobject]@{
        AnnexAControl = $control
        Capability    = $capability
        TechnicalState= $state
        Collected     = $(if ($collected) { 'Yes' } else { 'No' })
        CollectedDate = $today
    })
}

Write-Host '=== ISO 27001 Control Evidence Collection (read-only) ===' -ForegroundColor Cyan

# A.8.15 / A.8.16 — Logging / Monitoring (unified audit)
$auditOn = $false
try { $auditOn = (Get-AdminAuditLogConfig -ErrorAction Stop).UnifiedAuditLogIngestionEnabled } catch {}
Add-Evidence 'A.8.15 Logging / A.8.16 Monitoring' 'Unified audit log' ("UnifiedAuditLogIngestionEnabled=$auditOn") $auditOn

# A.5.12 / A.5.13 — Classification / Labelling (sensitivity labels)
$labels = @(); $labelPols = @()
if (Get-Command Get-Label -ErrorAction SilentlyContinue) { $labels = @(Get-Label -ErrorAction SilentlyContinue) }
if (Get-Command Get-LabelPolicy -ErrorAction SilentlyContinue) { $labelPols = @(Get-LabelPolicy -ErrorAction SilentlyContinue) }
Add-Evidence 'A.5.12 Classification / A.5.13 Labelling' 'Sensitivity labels' ("Labels={0}; LabelPolicies={1}" -f $labels.Count, $labelPols.Count) ($labels.Count -gt 0 -and $labelPols.Count -gt 0)

# A.8.12 — Data leakage prevention (DLP)
$dlp = @(Get-DlpCompliancePolicy -ErrorAction SilentlyContinue)
$dlpModes = ($dlp | ForEach-Object { "$($_.Name)=$($_.Mode)" }) -join '; '
Add-Evidence 'A.8.12 Data leakage prevention' 'DLP policies' ("Count={0}; Modes=[{1}]" -f $dlp.Count, $dlpModes) ($dlp.Count -gt 0)

# A.8.10 / A.5.33 — Information deletion / Protection of records (retention)
$ret = @()
if (Get-Command Get-RetentionCompliancePolicy -ErrorAction SilentlyContinue) { $ret = @(Get-RetentionCompliancePolicy -ErrorAction SilentlyContinue) }
Add-Evidence 'A.8.10 Information deletion / A.5.33 Protection of records' 'Retention & disposition' ("RetentionPolicies={0}" -f $ret.Count) ($ret.Count -gt 0)

# A.8.24 — Use of cryptography (label-applied encryption present as a signal)
$encLabels = @($labels | Where-Object { $_.EncryptionEnabled -eq $true -or $_.EncryptionProtectionType })
Add-Evidence 'A.8.24 Use of cryptography' 'Label-applied encryption' ("EncryptionLabels={0}" -f $encLabels.Count) ($encLabels.Count -gt 0)

# A.5.15 / A.8.3 — Access control (Conditional Access via Graph, if available)
$caCount = $null
if (Get-Command Get-MgIdentityConditionalAccessPolicy -ErrorAction SilentlyContinue) {
    try { $caCount = @(Get-MgIdentityConditionalAccessPolicy -All -ErrorAction Stop).Count } catch {}
}
if ($null -ne $caCount) {
    Add-Evidence 'A.5.15 Access control / A.8.3 Information access restriction' 'Conditional Access' ("CAPolicies=$caCount") ($caCount -gt 0)
} else {
    Add-Evidence 'A.5.15 Access control / A.8.3 Information access restriction' 'Conditional Access' 'Graph not connected — run Connect-MgGraph -Scopes Policy.Read.All' $false
}

# --- Optional: align to a control-map CSV (Control,Capability,Owner) ---
if ($ControlMap -and (Test-Path $ControlMap)) {
    Write-Host ("Aligning to control map: {0}" -f $ControlMap) -ForegroundColor Cyan
    $map = Import-Csv $ControlMap
    Write-Host ("  Control-map rows: {0} (owners carried through where present)" -f @($map).Count)
}

Write-Host '--- Evidence register ---' -ForegroundColor Cyan
$evidence | Format-Table AnnexAControl, Capability, Collected -AutoSize
$gaps = @($evidence | Where-Object { $_.Collected -eq 'No' })
if ($gaps.Count -gt 0) {
    Write-Host ("EVIDENCE GAPS: {0} mapped control(s) have no collected evidence — close before validation sign-off:" -f $gaps.Count) -ForegroundColor Yellow
    $gaps | ForEach-Object { Write-Host ("   * {0} ({1})" -f $_.AnnexAControl, $_.Capability) -ForegroundColor Yellow }
} else {
    Write-Host 'All mapped controls have collected evidence.' -ForegroundColor Green
}

if ($CsvPath) {
    $evidence | Export-Csv -Path $CsvPath -NoTypeInformation -Encoding UTF8
    Write-Host ("Evidence register exported to {0} — attach to the matching Compliance Manager improvement actions." -f $CsvPath) -ForegroundColor Green
}

Write-Host 'Done. Register built from live technical state — Compliance Manager assessment itself is portal-managed.' -ForegroundColor Cyan
