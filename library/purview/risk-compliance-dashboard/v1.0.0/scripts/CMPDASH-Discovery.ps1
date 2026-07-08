<#
.SYNOPSIS
    CMPDASH-Discovery.ps1 — Risk & Compliance Dashboard signal-availability readiness across Microsoft Purview (read-only).
.DESCRIPTION
    PURPOSE
        Reports which of the consolidated dashboard's Purview signals are present/enabled in the tenant
        and which require Microsoft 365 E5 / E5 Compliance: DLP / sensitivity-label / retention policy
        counts (Security & Compliance PowerShell), the unified audit-log ingestion state, and a licensing
        note for the signals with no reliable public read (Compliance Manager, Insider Risk,
        Communication Compliance, DSPM) — which the dashboard treats as owner-captured. Read-only; makes
        no changes and reads no HR-sensitive case content.
    HOW TO RUN
        powershell -ExecutionPolicy Bypass -File .\CMPDASH-Discovery.ps1
        Connect first: Connect-IPPSSession (ExchangeOnlineManagement) as a least-privilege reader
        (Compliance Administrator / Global Reader / View-Only Audit Logs). PowerShell 5.1+ or 7+.
    EXPECTED RESULTS
        Per signal: present/enabled or "not licensed / verify your tenant"; DLP/label/retention counts;
        audit ingestion on/off. Signals without a stable public read are listed as owner-captured.
.NOTES
    Purview category — Risk & Compliance Dashboard. Read-only. Feature availability is licensing-dependent
    and the portal evolves — verify your licensing/tenant. Regulatory/records/legal determinations deferred.
#>
[CmdletBinding()]
param(
    [switch]$IncludeAuditState = $true
)

function Write-Head($t) { Write-Host "`n== $t ==" -ForegroundColor Cyan }
function Try-Count($script, $label) {
    try {
        $n = (& $script | Measure-Object).Count
        Write-Host ("{0,-34}: {1}" -f $label, $n) -ForegroundColor Green
        return $n
    } catch {
        Write-Host ("{0,-34}: unable to read (verify role / licensing)" -f $label) -ForegroundColor Yellow
        return $null
    }
}

Write-Host "=== Risk & Compliance Dashboard — signal readiness (read-only) ===" -ForegroundColor Cyan
Write-Host "Requires an active Connect-IPPSSession as a least-privilege reader." -ForegroundColor DarkGray

# --- Live-read signals (Security & Compliance PowerShell) ---
Write-Head "Data Loss Prevention (live)"
$dlp = $null
try {
    $dlp = Get-DlpCompliancePolicy -ErrorAction Stop
    $enforced   = ($dlp | Where-Object { $_.Mode -eq 'Enable' }).Count
    $simulation = ($dlp | Where-Object { $_.Mode -like 'TestWith*' -or $_.Mode -like 'Test*' }).Count
    $disabled   = ($dlp | Where-Object { $_.Mode -eq 'Disable' }).Count
    Write-Host ("DLP policies                      : {0}  (enforced {1} / simulation-test {2} / disabled {3})" -f $dlp.Count, $enforced, $simulation, $disabled) -ForegroundColor Green
    if ($simulation -gt 0) { Write-Host "  note: simulation/test policies are not enforcing — pilot-before-enforce is expected." -ForegroundColor DarkGray }
} catch {
    Write-Host "DLP policies                      : unable to read (verify Compliance Data Administrator / licensing)." -ForegroundColor Yellow
}

Write-Head "Sensitivity labels (live)"
Try-Count { Get-Label } "Published sensitivity labels" | Out-Null
Try-Count { Get-LabelPolicy } "Label policies" | Out-Null

Write-Head "Data lifecycle & records / retention (live)"
Try-Count { Get-RetentionCompliancePolicy } "Retention policies" | Out-Null

# --- Audit (live) ---
if ($IncludeAuditState) {
    Write-Head "Audit (live)"
    try {
        $cfg = Get-AdminAuditLogConfig -ErrorAction Stop
        $on  = $cfg.UnifiedAuditLogIngestionEnabled
        $col = if ($on) { 'Green' } else { 'Yellow' }
        Write-Host ("Unified audit-log ingestion       : {0}" -f ($(if ($on) { 'ENABLED' } else { 'DISABLED — DLP/label volume tiles will have no source (CMPDASH-Set-Configuration -EnableAuditIngestion -Commit)' }))) -ForegroundColor $col
    } catch {
        Write-Host "Unified audit-log ingestion       : unable to read Get-AdminAuditLogConfig (verify role)." -ForegroundColor Yellow
    }
    Write-Host "Audit Standard vs Premium + retention: verify your licensing/tenant (Premium requires E5)." -ForegroundColor DarkGray
}

# --- Owner-captured signals (no reliable public read at authoring; verify your licensing/tenant) ---
Write-Head "Owner-captured signals (no stable public read — verify your licensing/tenant)"
@(
    'Compliance Manager — compliance score      (E5 for some templates)',
    'Insider Risk Management — aggregate counts  (E5; HR-sensitive, aggregate-only, role-separated)',
    'Communication Compliance — aggregate counts (E5; HR-sensitive, aggregate-only, role-separated)',
    'Data Security Posture Management (DSPM)      (E5; interface evolving)'
) | ForEach-Object { Write-Host ("  owner-captured : {0}" -f $_) -ForegroundColor DarkGray }
Write-Host "`nThese are entered by their program owners in RiskComplianceDashboard.config.json — never invented, never read as case content." -ForegroundColor DarkGray

Write-Host "`nDone. Feed the results into CMPDASH-Set-Configuration.ps1 to author the dashboard config." -ForegroundColor Cyan
