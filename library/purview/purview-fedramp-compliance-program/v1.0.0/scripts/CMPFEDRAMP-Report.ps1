<#
.SYNOPSIS
    CMPFEDRAMP-Report.ps1 — control -> object -> configuration -> proof evidence binder export (read-only).
.DESCRIPTION
    PURPOSE
        Produces the FedRAMP evidence binder with no changes: for each configured Purview control it
        records the implementing object, its key configuration, and a proof reference, cross-referenced to
        the NIST 800-53 family it supports. Exports CSV and JSON ('Evidence – FedRAMP Controls – Binder')
        for the security/compliance package. Read-only.
    HOW TO RUN
        powershell -ExecutionPolicy Bypass -File .\CMPFEDRAMP-Report.ps1 -OutputFolder .\evidence
        Requires ExchangeOnlineManagement (Connect-IPPSSession). Interactive modern-auth / MFA admin;
        no secrets. Pair with CMPFEDRAMP-Discovery.ps1 / CMPFEDRAMP-Validate.ps1 outputs as before/after
        evidence.
    EXPECTED RESULTS
        Two files in the output folder: 'Evidence - FedRAMP Controls - Binder.csv' and '.json'. Each row =
        one control (info protection / DLP / audit / retention) with object name, present/absent, key
        settings, NIST family, and a proof pointer. Rows with no implementing object are flagged as an
        evidence gap to fill before an assessment.
.NOTES
    Purview category — FedRAMP Compliance Program. Read-only. The binder evidences that controls are
    CONFIGURED; it does not certify FedRAMP compliance or an ATO — baseline/applicability are
    security/compliance/legal determinations. Verify cmdlet/plan names for your tenant.
#>
[CmdletBinding()]
param(
    [string]$OutputFolder      = '.',
    [string]$LabelName         = 'Protect – FedRAMP Controlled – Confidential',
    [string]$DlpPolicy         = 'DLP – FedRAMP Controlled – Simulate',
    [string]$AuditPolicy       = 'Audit Retention – FedRAMP Evidence – LongTerm',
    [string]$RetentionPolicy   = 'Retention – FedRAMP Records – Publish'
)

$ErrorActionPreference = 'Stop'
function Warn($m){ Write-Host $m -ForegroundColor Yellow }
function Ok($m){ Write-Host $m -ForegroundColor Green }
function Info($m){ Write-Host $m -ForegroundColor Cyan }

if (-not (Get-Module -ListAvailable -Name ExchangeOnlineManagement)) { Warn "ExchangeOnlineManagement not installed."; return }
Import-Module ExchangeOnlineManagement -ErrorAction Stop
try { Connect-IPPSSession -ErrorAction Stop | Out-Null } catch { Warn "Connect-IPPSSession failed: $($_.Exception.Message)"; return }

$rows = @()
function Add-Row($control,$nist,$object,$present,$config,$proof){
    $script:rows += [pscustomobject]@{
        Control       = $control
        NIST_Family   = $nist
        PurviewObject = $object
        Present       = $present
        Configuration = $config
        Proof         = $proof
        EvidenceGap   = if ($present) { '' } else { 'GAP — configure before assessment' }
    }
}

# --- Information protection (AC / MP / SC) ---
try {
    $lbl = Get-Label -ErrorAction Stop | Where-Object { $_.DisplayName -eq $LabelName }
    if ($lbl) {
        $enc = if ($lbl.EncryptionEnabled) { 'encryption ON' } else { 'encryption OFF' }
        Add-Row 'Information protection (sensitivity label)' 'AC / MP / SC' $LabelName $true "$enc" 'Get-Label (attach output)'
    } else { Add-Row 'Information protection (sensitivity label)' 'AC / MP / SC' $LabelName $false 'n/a' 'Get-Label (not found)' }
} catch { Add-Row 'Information protection (sensitivity label)' 'AC / MP / SC' $LabelName $false 'error reading' $_.Exception.Message }

# --- DLP (SC / AC) ---
try {
    $dlp = Get-DlpCompliancePolicy -ErrorAction Stop | Where-Object { $_.Name -eq $DlpPolicy }
    if ($dlp) {
        $mode = "$($dlp.Mode)"
        $note = if ($mode -match 'Enable') { "mode=$mode (ENFORCING)" } else { "mode=$mode (test/simulation — no blocking)" }
        Add-Row 'Data loss prevention (DLP policy)' 'SC / AC' $DlpPolicy $true $note 'Get-DlpCompliancePolicy + DLP simulation results (attach)'
    } else { Add-Row 'Data loss prevention (DLP policy)' 'SC / AC' $DlpPolicy $false 'n/a' 'Get-DlpCompliancePolicy (not found)' }
} catch { Add-Row 'Data loss prevention (DLP policy)' 'SC / AC' $DlpPolicy $false 'error reading' $_.Exception.Message }

# --- Audit evidence (AU) ---
try {
    $arp = Get-UnifiedAuditLogRetentionPolicy -ErrorAction Stop | Where-Object { $_.Name -eq $AuditPolicy }
    if ($arp) { Add-Row 'Audit evidence (retention policy)' 'AU' $AuditPolicy $true "duration=$($arp.RetentionDuration); priority=$($arp.Priority)" 'Get-UnifiedAuditLogRetentionPolicy (attach)' }
    else { Add-Row 'Audit evidence (retention policy)' 'AU' $AuditPolicy $false 'n/a' 'Get-UnifiedAuditLogRetentionPolicy (not found)' }
} catch { Add-Row 'Audit evidence (retention policy)' 'AU' $AuditPolicy $false 'error reading' $_.Exception.Message }

# --- Unified audit ingestion (AU) ---
try {
    $cfg = $null
    try { $cfg = Get-AdminAuditLogConfig -ErrorAction Stop } catch {
        try { Connect-ExchangeOnline -ShowBanner:$false -ErrorAction Stop | Out-Null; $cfg = Get-AdminAuditLogConfig -ErrorAction Stop } catch {}
    }
    if ($cfg) { Add-Row 'Audit ingestion (tenant setting)' 'AU' 'UnifiedAuditLogIngestionEnabled' ([bool]$cfg.UnifiedAuditLogIngestionEnabled) "$($cfg.UnifiedAuditLogIngestionEnabled)" 'Get-AdminAuditLogConfig (attach)' }
    else { Add-Row 'Audit ingestion (tenant setting)' 'AU' 'UnifiedAuditLogIngestionEnabled' $false 'unknown' 'Get-AdminAuditLogConfig (unreadable — Connect-ExchangeOnline)' }
} catch { Add-Row 'Audit ingestion (tenant setting)' 'AU' 'UnifiedAuditLogIngestionEnabled' $false 'error reading' $_.Exception.Message }

# --- Controlled-records retention ---
try {
    $pol = Get-RetentionCompliancePolicy -ErrorAction Stop | Where-Object { $_.Name -eq $RetentionPolicy }
    if ($pol) { Add-Row 'Controlled-records retention (policy)' 'AU / MP' $RetentionPolicy $true "enabled=$($pol.Enabled); mode=$($pol.Mode)" 'Get-RetentionCompliancePolicy (attach)' }
    else { Add-Row 'Controlled-records retention (policy)' 'AU / MP' $RetentionPolicy $false 'n/a' 'Get-RetentionCompliancePolicy (not found)' }
} catch { Add-Row 'Controlled-records retention (policy)' 'AU / MP' $RetentionPolicy $false 'error reading' $_.Exception.Message }

# --- Emit binder ---
if (-not (Test-Path $OutputFolder)) { New-Item -ItemType Directory -Path $OutputFolder -Force | Out-Null }
$stamp = Get-Date -Format 'yyyyMMdd-HHmmss'
$csv  = Join-Path $OutputFolder ("Evidence - FedRAMP Controls - Binder-$stamp.csv")
$json = Join-Path $OutputFolder ("Evidence - FedRAMP Controls - Binder-$stamp.json")
$rows | Export-Csv -Path $csv -NoTypeInformation -Encoding UTF8
$rows | ConvertTo-Json -Depth 4 | Out-File -FilePath $json -Encoding UTF8

Write-Host "`n=== Evidence – FedRAMP Controls – Binder ===" -ForegroundColor Cyan
$rows | Format-Table Control, NIST_Family, PurviewObject, Present, EvidenceGap -AutoSize | Out-String | Write-Host
Ok "CSV : $csv"
Ok "JSON: $json"
$gaps = @($rows | Where-Object { -not $_.Present }).Count
if ($gaps -gt 0) { Warn "$gaps evidence gap(s) — a control with no implementing object fails an assessment. See Implementation Guide." }
Info "Cross-reference this binder to 'Control Map – FedRAMP – Purview'. Baseline/NIST 800-53 applicability and any ATO decision are security/compliance/legal's — this binder evidences configuration only, no certification/ATO asserted."
