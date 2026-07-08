<#
.SYNOPSIS
    EDU-Discovery.ps1 — Read-only inventory of the education Purview program: labels, DLP (with mode), retention, custom SITs, audit.
.DESCRIPTION
    PURPOSE
        Assesses the current Microsoft Purview configuration relevant to an education/FERPA program:
        sensitivity labels + label policies, DLP compliance policies AND THEIR MODE (Test vs Enable),
        retention labels/policies, custom sensitive information types (incl. the education Student-ID
        SIT), and the unified-audit state. Read-only against Security & Compliance PowerShell — makes
        no changes.
    HOW TO RUN
        powershell -ExecutionPolicy Bypass -File .\EDU-Discovery.ps1
        Requires the ExchangeOnlineManagement module. Connects with Connect-IPPSSession (Security &
        Compliance PowerShell) using an MFA-capable admin holding read access to the compliance config.
        Optional: -SitNameFilter 'EDU - Student ID' to spotlight the education SIT.
    EXPECTED RESULTS
        Lists education-relevant labels, each DLP policy with its MODE flagged (Test = safe pilot,
        Enable = ENFORCING), retention labels with their retention action/duration, custom SITs, and
        the unified-audit ingestion state. Nothing is modified.
.NOTES
    Purview category — Microsoft Purview for Education (FERPA). Read-only. Capability availability is
    licensing-/plan-dependent (E5 / E5 Compliance; some preview) — verify your licensing/tenant.
#>
[CmdletBinding()]
param(
    [string]$LabelNameFilter = 'EDU',
    [string]$SitNameFilter   = 'EDU - Student ID'
)

if (-not (Get-Module -ListAvailable -Name ExchangeOnlineManagement)) {
    Write-Host "Installing ExchangeOnlineManagement module (CurrentUser)..." -ForegroundColor Yellow
    Install-Module ExchangeOnlineManagement -Scope CurrentUser -Force -AllowClobber
}
Import-Module ExchangeOnlineManagement -ErrorAction Stop
Write-Host "Connecting to Security & Compliance PowerShell (Connect-IPPSSession)..." -ForegroundColor Cyan
Connect-IPPSSession -ErrorAction Stop | Out-Null

Write-Host "`n=== Education Purview program — discovery (read-only) ===" -ForegroundColor Cyan

# 1) Sensitivity labels
Write-Host "`n-- Sensitivity labels --" -ForegroundColor Cyan
try {
    $labels = Get-Label -ErrorAction Stop
    $edu = $labels | Where-Object { $_.DisplayName -like "*$LabelNameFilter*" -or $_.Name -like "*$LabelNameFilter*" }
    if (-not $edu) { Write-Host "  none matching '$LabelNameFilter' — create the education taxonomy (Step 2)." -ForegroundColor Yellow }
    else { foreach ($l in $edu) { Write-Host ("  {0}  (encryption: {1})" -f $l.DisplayName, $l.EncryptionEnabled) -ForegroundColor Green } }
} catch { Write-Host "  unable to read labels (need Information Protection role?)." -ForegroundColor Yellow }

# 2) Label policies (publishing)
Write-Host "`n-- Label policies --" -ForegroundColor Cyan
try {
    Get-LabelPolicy -ErrorAction Stop | ForEach-Object { Write-Host ("  {0}  (labels: {1})" -f $_.Name, (($_.Labels) -join ', ')) }
} catch { Write-Host "  unable to read label policies." -ForegroundColor Yellow }

# 3) DLP policies WITH MODE
Write-Host "`n-- DLP policies (mode flagged) --" -ForegroundColor Cyan
try {
    $dlp = Get-DlpCompliancePolicy -ErrorAction Stop
    if (-not $dlp) { Write-Host "  none — create the FERPA DLP policy in Test (Step 5)." -ForegroundColor Yellow }
    else {
        foreach ($p in $dlp) {
            $enforcing = ($p.Mode -eq 'Enable')
            $col = if ($enforcing) { 'Yellow' } else { 'Green' }
            $tag = if ($enforcing) { 'ENFORCING' } else { 'Test/safe' }
            Write-Host ("  {0}  [mode: {1} — {2}]" -f $p.Name, $p.Mode, $tag) -ForegroundColor $col
        }
    }
} catch { Write-Host "  unable to read DLP policies (need Compliance Administrator role?)." -ForegroundColor Yellow }

# 4) Retention labels (compliance tags) + retention policies
Write-Host "`n-- Retention labels --" -ForegroundColor Cyan
try {
    Get-ComplianceTag -ErrorAction Stop | Where-Object { $_.Name -like "*$LabelNameFilter*" -or $_.Name -like '*Student*' } |
        ForEach-Object { Write-Host ("  {0}  (action: {1}, duration: {2})" -f $_.Name, $_.RetentionAction, $_.RetentionDuration) -ForegroundColor Green }
} catch { Write-Host "  unable to read retention labels (need Records Management role?)." -ForegroundColor Yellow }
try {
    $rp = Get-RetentionCompliancePolicy -ErrorAction Stop | Where-Object { $_.Name -like "*$LabelNameFilter*" -or $_.Name -like '*Student*' }
    if ($rp) { $rp | ForEach-Object { Write-Host ("  retention policy: {0}" -f $_.Name) } }
} catch { }

# 5) Custom sensitive information types (spotlight the education SIT)
Write-Host "`n-- Custom sensitive information types --" -ForegroundColor Cyan
try {
    $sits = Get-DlpSensitiveInformationType -ErrorAction Stop | Where-Object { $_.Publisher -ne 'Microsoft Corporation' }
    if (-not $sits) { Write-Host "  no custom SITs — build '$SitNameFilter' (Step 3)." -ForegroundColor Yellow }
    else {
        foreach ($s in $sits) {
            $mark = if ($s.Name -like "*$SitNameFilter*") { '  <== education Student-ID SIT' } else { '' }
            Write-Host ("  {0}{1}" -f $s.Name, $mark) -ForegroundColor Green
        }
        if (-not ($sits | Where-Object { $_.Name -like "*$SitNameFilter*" })) {
            Write-Host "  NOTE: '$SitNameFilter' not found — there is NO built-in FERPA SIT; build the custom Student-ID SIT (Step 3)." -ForegroundColor Yellow
        }
    }
} catch { Write-Host "  unable to read sensitive information types." -ForegroundColor Yellow }

# 6) Unified audit ingestion state (best-effort; requires Exchange Online cmdlet)
Write-Host "`n-- Unified audit state --" -ForegroundColor Cyan
try {
    $cfg = Get-AdminAuditLogConfig -ErrorAction Stop
    $on = $cfg.UnifiedAuditLogIngestionEnabled
    $col = if ($on) { 'Green' } else { 'Yellow' }
    Write-Host ("  UnifiedAuditLogIngestionEnabled: {0}" -f $on) -ForegroundColor $col
} catch { Write-Host "  audit state not readable from this session — confirm in Purview > Audit (connect Exchange Online to read via cmdlet)." -ForegroundColor DarkGray }

Write-Host "`nCapability availability is licensing-/plan-dependent (E5 / E5 Compliance; some preview) — verify your licensing/tenant." -ForegroundColor DarkGray
Write-Host "Regulatory/records/legal determinations (FERPA applicability, retention periods, holds) are deferred to governance." -ForegroundColor DarkGray
Disconnect-ExchangeOnline -Confirm:$false -ErrorAction SilentlyContinue | Out-Null
