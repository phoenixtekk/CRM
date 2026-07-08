<#
.SYNOPSIS
    AIHUB-Discovery.ps1 — DSPM-for-AI posture: unified-audit state, AI-interaction activity, sensitivity labels, DLP policies, onboarding signals (read-only).
.DESCRIPTION
    Assesses the tenant's readiness for AI governance from DSPM for AI. Reports whether unified audit is
    enabled (the foundation of AI visibility), whether AI-interaction activity (Copilot and related record
    types) is present in the audit log over a recent window, the sensitivity-label taxonomy that Copilot
    can honor, existing DLP policies and their mode (to spot an AI/Copilot-scoped policy), and endpoint/
    device readiness signals for consumer-AI egress. Read-only - makes no changes.
.EXAMPLE
    .\AIHUB-Discovery.ps1
    Prints audit state, recent AI-interaction signal, labels, DLP policies, and onboarding readiness.
.EXAMPLE
    .\AIHUB-Discovery.ps1 -Days 7 -CsvPath .\AIHUB-Posture.csv
    Looks back 7 days for AI activity and exports the DLP-policy posture to CSV.
.NOTES
    Requires PowerShell 5.1+/7+ and ExchangeOnlineManagement (Connect-IPPSSession). Role: Compliance/DLP +
    Audit reader; Information Protection (labels, read).
    Expected results: PASS = audit enabled, labels present, AI activity appears over time. Verify = no AI
    activity yet (allow ingestion latency / confirm AI is in use), or a record type differs in your tenant.
    NOTE: DSPM for AI is new/evolving and partly PREVIEW - AI audit RECORD TYPES/operations vary by tenant;
    the AI-activity probe is best-effort and flags "verify in your tenant". Nothing is modified.
#>
[CmdletBinding()]
param(
    [int]$Days = 7,
    [string]$CsvPath
)

Import-Module ExchangeOnlineManagement -ErrorAction Stop
if (-not (Get-Command Get-DlpCompliancePolicy -ErrorAction SilentlyContinue)) {
    Write-Host "Connecting to Security & Compliance PowerShell..." -ForegroundColor Cyan
    Connect-IPPSSession -ShowBanner:$false -ErrorAction Stop | Out-Null
}

Write-Host "`n=== DSPM-for-AI posture (read-only) ===" -ForegroundColor Cyan

# --- 1. Unified audit ---
Write-Host "`n-- AI visibility (unified audit) --" -ForegroundColor Cyan
try {
    $cfg = Get-AdminAuditLogConfig -ErrorAction Stop
    $on = [bool]$cfg.UnifiedAuditLogIngestionEnabled
    Write-Host ("  UnifiedAuditLogIngestionEnabled : {0}" -f $on) -ForegroundColor $(if ($on) { 'Green' } else { 'Red' })
    if (-not $on) { Write-Host "  Audit is OFF - AI visibility depends on it. Enable via AIHUB-Config.ps1 -EnableAudit -Commit (Req 2.4)." -ForegroundColor Red }
} catch { Write-Host ("  Audit state : unable to read ({0})." -f $_.Exception.Message) -ForegroundColor Yellow }

# --- 2. AI-interaction activity signal (best-effort; record types vary/preview) ---
Write-Host "`n-- AI-interaction activity (last $Days days, best-effort) --" -ForegroundColor Cyan
try {
    $hits = @()
    # Copilot interactions surface under an AI/Copilot record type; the exact value evolves - try a known one
    # and fall back to a free-text search. VERIFY the current record type/operations for your tenant.
    try { $hits = Search-UnifiedAuditLog -StartDate (Get-Date).AddDays(-$Days) -EndDate (Get-Date) -RecordType 'CopilotInteraction' -ResultSize 5 -ErrorAction Stop } catch {}
    if (-not $hits -or @($hits).Count -eq 0) {
        try { $hits = Search-UnifiedAuditLog -StartDate (Get-Date).AddDays(-$Days) -EndDate (Get-Date) -FreeText 'Copilot' -ResultSize 5 -ErrorAction Stop } catch {}
    }
    if (@($hits).Count -ge 1) { Write-Host ("  AI-interaction events found : {0}+ (visibility working)" -f @($hits).Count) -ForegroundColor Green }
    else { Write-Host "  AI-interaction events found : 0 in window - allow ingestion latency, confirm AI is in use, and VERIFY the AI record type/operations for your tenant." -ForegroundColor Yellow }
} catch { Write-Host ("  AI-activity probe : unable to run ({0})." -f $_.Exception.Message) -ForegroundColor Yellow }

# --- 3. Sensitivity labels Copilot can honor ---
Write-Host "`n-- Sensitivity labels (Copilot honors these) --" -ForegroundColor Cyan
try {
    $labels = @(Get-Label -ErrorAction Stop)
    $enc = @($labels | Where-Object { $_.EncryptionEnabled -eq $true }).Count
    Write-Host ("  Labels total : {0}  (encrypting: {1})" -f $labels.Count, $enc) -ForegroundColor Green
    if ($labels.Count -eq 0) { Write-Host "  No labels found - build/publish a taxonomy so Copilot has labels to honor (Req 2.5)." -ForegroundColor Yellow }
} catch { Write-Host ("  Labels : unable to read ({0})." -f $_.Exception.Message) -ForegroundColor Yellow }

# --- 4. DLP policies (spot an AI/Copilot-scoped one) ---
Write-Host "`n-- DLP policies --" -ForegroundColor Cyan
$rows = @()
try {
    foreach ($p in (Get-DlpCompliancePolicy -ErrorAction Stop)) {
        $mode = "$($p.Mode)"
        $modeLabel = switch -Wildcard ($mode) { 'Test*' { 'SIMULATION' } 'Enable' { 'ENFORCE' } 'Disable' { 'DISABLED' } default { $mode } }
        $looksAI = ($p.Name -match 'AI|Copilot')
        $col = if ($looksAI) { 'Green' } else { 'Gray' }
        Write-Host ("  {0}  [{1}]{2}" -f $p.Name, $modeLabel, $(if ($looksAI) { '  (AI/Copilot-named)' } else { '' })) -ForegroundColor $col
        $rows += [pscustomobject]@{ Policy = $p.Name; Mode = $mode; ModeLabel = $modeLabel; LooksAI = $looksAI }
    }
    if ($rows.Count -eq 0) { Write-Host "  (no DLP policies) - the DLP-for-AI policy is created in Implementation Step 5." -ForegroundColor Gray }
} catch { Write-Host ("  DLP policies : unable to read ({0})." -f $_.Exception.Message) -ForegroundColor Yellow }

# --- 5. Endpoint onboarding reminder (consumer-AI egress) ---
Write-Host "`n-- Consumer-AI egress readiness (portal-verified) --" -ForegroundColor Cyan
Write-Host "  [VERIFY] Surfacing sensitive data pasted into consumer AI sites needs onboarded devices + the" -ForegroundColor Yellow
Write-Host "           Purview browser extension. Confirm in Purview -> Settings -> Device onboarding and the" -ForegroundColor Yellow
Write-Host "           extension deployment. VERIFY current browser/extension support for your tenant." -ForegroundColor Yellow

if ($CsvPath -and $rows.Count -gt 0) {
    $rows | Export-Csv -Path $CsvPath -NoTypeInformation -Encoding UTF8
    Write-Host ("`nExported DLP posture to {0}" -f $CsvPath) -ForegroundColor Cyan
}
Write-Host "`nNOTE: DSPM for AI is new/evolving and partly PREVIEW - verify your licensing/tenant and portal paths." -ForegroundColor Yellow
