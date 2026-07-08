<#
.SYNOPSIS
    AIPROMPT-ScopeConfig.ps1 — scope/health helper for AI prompt/response governance (read-only).
.DESCRIPTION
    PURPOSE
        Confirms the toolchain sign-in, reports whether unified auditing is ON (the source of AI usage
        monitoring), and enumerates the AI-governance features present in the tenant — Communication
        Compliance policies, DLP policies, sensitivity labels, and the Copilot/AI audit signal — so you know
        what is licensed/available before configuring. Resolves Requirements 2.1-2.6. Read-only.
    HOW TO RUN
        PowerShell 5.1+ or 7+ with Exchange Online / Security & Compliance PowerShell (and optionally Graph):
          Connect-ExchangeOnline
          Connect-IPPSSession
          Connect-MgGraph -Scopes "AuditLog.Read.All"   # optional
          .\AIPROMPT-ScopeConfig.ps1
    EXPECTED RESULTS
        A PASS/FAIL health line per check. PASS = session connected, auditing on, and the AI-governance
        surfaces enumerated. FAIL on auditing means monitoring will be empty (turn auditing on, Req 2.3).
.NOTES
    White-label Microsoft Purview tooling. Read-only. No credentials stored.
    VERIFY IN YOUR TENANT: Copilot monitoring in Communication Compliance, a DLP Copilot location, DSPM for
    AI, and the CopilotInteraction audit record are new/evolving and licensing-dependent. This script reports
    what your session can see; it does not assert availability.
#>
[CmdletBinding()]
param(
    [int]$SampleDays = 7,
    [string[]]$AiRecordTypes = @("CopilotInteraction")
)

$ErrorActionPreference = "Stop"
function Line($ok, $msg) {
    $tag = if ($ok) { "PASS" } else { "FAIL" }
    $col = if ($ok) { "Green" } else { "Red" }
    Write-Host ("[{0}] {1}" -f $tag, $msg) -ForegroundColor $col
}
Write-Host "=== AIPROMPT Scope/Health — AI prompt/response governance (read-only) ===" -ForegroundColor Cyan

# --- Connectivity ---
$hasIPPS = [bool](Get-Command Get-DlpCompliancePolicy -ErrorAction SilentlyContinue)
Line $hasIPPS "Security & Compliance PowerShell (Connect-IPPSSession) — policy cmdlets available"
$hasEXO  = [bool](Get-Command Search-UnifiedAuditLog -ErrorAction SilentlyContinue)
Line $hasEXO "Exchange Online (Connect-ExchangeOnline) — Search-UnifiedAuditLog available"
$hasGraph = [bool](Get-Command Get-MgContext -ErrorAction SilentlyContinue) -and ($null -ne (Get-MgContext -ErrorAction SilentlyContinue))
Line $hasGraph "Microsoft Graph (Connect-MgGraph) — connected (optional)"

# --- Auditing enabled (Req 2.3) ---
$auditOn = $false
if (Get-Command Get-AdminAuditLogConfig -ErrorAction SilentlyContinue) {
    try { $auditOn = [bool](Get-AdminAuditLogConfig).UnifiedAuditLogIngestionEnabled } catch {}
}
Line $auditOn "Unified audit log ingestion enabled (UnifiedAuditLogIngestionEnabled) — required for AI monitoring"

# --- Sensitivity labels + SITs (levers) ---
if ($hasIPPS) {
    try { $labels = @(Get-Label -ErrorAction SilentlyContinue) } catch { $labels = @() }
    Write-Host ("  Sensitivity labels: {0}" -f $labels.Count) -ForegroundColor Gray
    try { $sits = @(Get-DlpSensitiveInformationType -ErrorAction SilentlyContinue) } catch { $sits = @() }
    Write-Host ("  Sensitive information types: {0}" -f $sits.Count) -ForegroundColor Gray
}

# --- DLP policies (and any already scoped to Copilot/AI) (Req 2.5) ---
if ($hasIPPS) {
    try { $dlp = @(Get-DlpCompliancePolicy -ErrorAction SilentlyContinue) } catch { $dlp = @() }
    $aiDlp = @($dlp | Where-Object { "$($_.Name) $($_.Comment)" -match "(?i)copilot|(\bAI\b)" })
    Write-Host ("  DLP policies: {0} (name/comment hints at Copilot/AI on {1})" -f $dlp.Count, $aiDlp.Count) -ForegroundColor Gray
    Write-Host "  NOTE: confirm a Microsoft 365 Copilot DLP LOCATION exists in Purview -> DLP -> Create (Req 2.5) — verify in your tenant." -ForegroundColor DarkYellow
}

# --- Communication Compliance presence (Req 2.4) ---
if (Get-Command Get-SupervisoryReviewPolicyV2 -ErrorAction SilentlyContinue) {
    try { $cc = @(Get-SupervisoryReviewPolicyV2 -ErrorAction SilentlyContinue) } catch { $cc = @() }
    Line $true ("Communication Compliance reachable — existing policies: {0}" -f $cc.Count)
    Write-Host "  NOTE: confirm anonymization is ON (Settings -> Privacy) and that a Copilot/AI monitored source is available before creating the AI policy (Req 2.4)." -ForegroundColor DarkYellow
} else {
    Line $false "Communication Compliance cmdlet (Get-SupervisoryReviewPolicyV2) not available — check licensing/role or connect S&C PowerShell"
}

# --- Copilot/AI audit signal present? (Req 2.6) ---
if ($hasEXO) {
    $start = (Get-Date).AddDays(-1 * [math]::Abs($SampleDays)); $end = Get-Date
    try {
        $sample = @(Search-UnifiedAuditLog -StartDate $start -EndDate $end -RecordType $AiRecordTypes -ResultSize 1 -ErrorAction SilentlyContinue)
        Line ($sample.Count -gt 0) ("Copilot/AI audit records present in last {0}d (RecordType={1}) — {2} sampled" -f $SampleDays, ($AiRecordTypes -join ","), $sample.Count)
        if ($sample.Count -eq 0) { Write-Host "  No AI records sampled — expected pre-adoption or if auditing was recently enabled. Confirm Copilot/AI usage and the RecordType for your tenant." -ForegroundColor DarkYellow }
    } catch { Line $false "Audit sample failed: $($_.Exception.Message)" }
}

Write-Host "`nNext: AIPROMPT-Discovery.ps1 (inventory governance config), then AIPROMPT-Monitor.ps1 (baseline AI usage)." -ForegroundColor Cyan
