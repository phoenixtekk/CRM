<#
.SYNOPSIS
    INDLEGAL-Report.ps1 — Legal control-to-configuration-to-proof evidence binder export (read-only).
.DESCRIPTION
    PURPOSE
        Produces the 'Evidence – Legal Controls – Binder' — a control -> Purview object -> configuration ->
        proof export (CSV + JSON) cross-referenced to the 'Control Map – Legal – Purview' register — with no
        changes. It reads the configured objects (sensitivity labels + encryption, DLP policy + mode,
        matter-records retention label/policy, audit ingestion + retention policy) and, read-only reference
        only, existing eDiscovery holds, and records each control's presence, key configuration, and a proof
        pointer for the legal/compliance/audit file. Read-only.
    HOW TO RUN
        powershell -ExecutionPolicy Bypass -File .\INDLEGAL-Report.ps1 -OutputDir .\evidence
        Requires ExchangeOnlineManagement (Connect-IPPSSession). Interactive modern-auth / MFA admin;
        no secrets. Writes only the export files under -OutputDir; it changes NO Purview object and performs
        NO legal-hold action.
    EXPECTED RESULTS
        Two files in -OutputDir: 'Evidence – Legal Controls – Binder.csv' and '...json', one row per control
        with Status/Configuration/Proof. PASS = every in-scope obligation maps to a present Purview object
        with a proof reference; gaps are listed as MISSING for follow-up. Whether the evidenced controls are
        legally sufficient is legal/records' determination, not this report.
.NOTES
    Purview category — Microsoft Purview for Legal (industry bundle). Read-only (writes only the export
    files you request). Evidence, not a determination: privilege/matter/retention/legal-hold adequacy are
    legal/records'. Legal holds/eDiscovery are legal's — referenced read-only only. Verify cmdlet/plan names
    for your tenant.
#>
[CmdletBinding()]
param(
    [string]$OutputDir = '.',
    [string]$PrivilegedLabel = 'Protect – Legal Privileged – Restricted',
    [string]$MatterLabel     = 'Protect – Legal Matter Confidential – Confidential',
    [string]$DlpPolicy       = 'DLP – Legal Privileged – Simulate',
    [string]$RetentionPolicy = 'Retention – Legal Matter Records – Publish',
    [string]$AuditPolicy     = 'Audit Retention – Legal Evidence – LongTerm'
)

$ErrorActionPreference = 'Stop'
function Warn($m){ Write-Host $m -ForegroundColor Yellow }
function Ok($m){ Write-Host $m -ForegroundColor Green }
$rows = @()
function Row($control,$object,$status,$config,$proof){ $script:rows += [pscustomobject]@{ Control=$control; PurviewObject=$object; Status=$status; Configuration=$config; Proof=$proof } }

if (-not (Get-Module -ListAvailable -Name ExchangeOnlineManagement)) { Warn "ExchangeOnlineManagement not installed."; return }
Import-Module ExchangeOnlineManagement -ErrorAction Stop
try { Connect-IPPSSession -ErrorAction Stop | Out-Null } catch { Warn "Connect-IPPSSession failed: $($_.Exception.Message)"; return }

# --- Confidentiality: sensitivity labels ---
try {
    $labels = Get-Label -ErrorAction Stop
    $priv = $labels | Where-Object { $_.DisplayName -eq $PrivilegedLabel }
    $matt = $labels | Where-Object { $_.DisplayName -eq $MatterLabel }
    if ($priv) {
        $enc = if ($priv.EncryptionEnabled -or $priv.EncryptionProtectionType) { 'encryption ON' } else { 'no encryption (REVIEW)' }
        Row 'Confidentiality — privilege' $PrivilegedLabel 'PRESENT' $enc 'Get-Label'
    } else { Row 'Confidentiality — privilege' $PrivilegedLabel 'MISSING' '' 'Get-Label' }
    if ($matt) { Row 'Confidentiality — matter' $MatterLabel 'PRESENT' 'matter-confidential label' 'Get-Label' }
    else { Row 'Confidentiality — matter' $MatterLabel 'MISSING' '' 'Get-Label' }
} catch { Row 'Confidentiality' 'sensitivity labels' 'ERROR' $_.Exception.Message 'Get-Label' }

# --- Inadvertent disclosure: DLP ---
try {
    $dlp = Get-DlpCompliancePolicy -ErrorAction Stop | Where-Object { $_.Name -eq $DlpPolicy }
    if ($dlp) { Row 'Inadvertent disclosure — DLP' $DlpPolicy 'PRESENT' ("mode=$($dlp.Mode)") 'Get-DlpCompliancePolicy' }
    else { Row 'Inadvertent disclosure — DLP' $DlpPolicy 'MISSING' '' 'Get-DlpCompliancePolicy' }
} catch { Row 'Inadvertent disclosure — DLP' $DlpPolicy 'ERROR' $_.Exception.Message 'Get-DlpCompliancePolicy' }

# --- Matter records: retention ---
try {
    $pol = Get-RetentionCompliancePolicy -ErrorAction Stop | Where-Object { $_.Name -eq $RetentionPolicy }
    if ($pol) { Row 'Matter records — retention' $RetentionPolicy 'PRESENT' ("enabled=$($pol.Enabled); mode=$($pol.Mode)") 'Get-RetentionCompliancePolicy' }
    else { Row 'Matter records — retention' $RetentionPolicy 'MISSING' '' 'Get-RetentionCompliancePolicy' }
    $recLabels = Get-ComplianceTag -ErrorAction Stop | Where-Object { $_.Name -match 'Legal' -and $_.IsRecordLabel }
    if ($recLabels) { foreach ($r in $recLabels) { $t = if ($r.RegulatoryRecord) { 'REGULATORY (immutable)' } else { 'record' }; Row 'Matter records — label' $r.Name 'PRESENT' ("type=$t; retention=$($r.RetentionDuration)") 'Get-ComplianceTag' } }
} catch { Row 'Matter records' 'retention' 'ERROR' $_.Exception.Message 'Get-RetentionCompliancePolicy' }

# --- Audit evidence ---
try {
    $cfg = $null
    try { $cfg = Get-AdminAuditLogConfig -ErrorAction Stop } catch {}
    $ingOn = ($cfg -and $cfg.UnifiedAuditLogIngestionEnabled)
    $ing = if ($ingOn) { 'ingestion ON' } else { 'ingestion OFF/unknown (REVIEW)' }
    $ingStatus = if ($ingOn) { 'PRESENT' } else { 'REVIEW' }
    Row 'Audit evidence — ingestion' 'UnifiedAuditLog' $ingStatus $ing 'Get-AdminAuditLogConfig'
    $arp = Get-UnifiedAuditLogRetentionPolicy -ErrorAction Stop | Where-Object { $_.Name -eq $AuditPolicy }
    if ($arp) { Row 'Audit evidence — retention' $AuditPolicy 'PRESENT' ("duration=$($arp.RetentionDuration); priority=$($arp.Priority)") 'Get-UnifiedAuditLogRetentionPolicy' }
    else { Row 'Audit evidence — retention' $AuditPolicy 'MISSING' '' 'Get-UnifiedAuditLogRetentionPolicy' }
} catch { Row 'Audit evidence' 'audit' 'ERROR' $_.Exception.Message 'Get-UnifiedAuditLogRetentionPolicy' }

# --- Legal holds (READ-ONLY REFERENCE — legal's control) ---
try {
    $holds = Get-CaseHoldPolicy -ErrorAction Stop
    if ($holds) { foreach ($h in $holds) { Row 'Legal hold (REFERENCE — legal owns)' $h.Name 'VISIBLE' ("enabled=$($h.Enabled)") 'Get-CaseHoldPolicy (read-only)' } }
    else { Row 'Legal hold (REFERENCE — legal owns)' 'case holds' 'NONE VISIBLE' 'no holds visible — legal to confirm coverage' 'Get-CaseHoldPolicy (read-only)' }
} catch { Row 'Legal hold (REFERENCE — legal owns)' 'case holds' 'N/A' 'requires eDiscovery role; reference-only' 'Get-CaseHoldPolicy (read-only)' }

# --- Emit binder ---
if (-not (Test-Path $OutputDir)) { New-Item -ItemType Directory -Path $OutputDir -Force | Out-Null }
$csv  = Join-Path $OutputDir 'Evidence – Legal Controls – Binder.csv'
$json = Join-Path $OutputDir 'Evidence – Legal Controls – Binder.json'
$rows | Export-Csv -Path $csv -NoTypeInformation -Encoding UTF8
$rows | ConvertTo-Json -Depth 4 | Out-File -FilePath $json -Encoding UTF8

Write-Host "`n=== Evidence – Legal Controls – Binder ===" -ForegroundColor Cyan
$rows | Format-Table Control, PurviewObject, Status -AutoSize | Out-String | Write-Host
$missing = @($rows | Where-Object { $_.Status -in @('MISSING','REVIEW','ERROR') }).Count
Ok "Wrote: $csv"
Ok "Wrote: $json"
if ($missing -gt 0) { Warn "$missing control row(s) MISSING/REVIEW — fill the gap and re-run before relying on the binder." }
Write-Host "Cross-reference each row to 'Control Map – Legal – Purview'. Whether the evidenced controls are legally sufficient (privilege, matter, retention, hold) is legal/records' determination, not this report." -ForegroundColor White
