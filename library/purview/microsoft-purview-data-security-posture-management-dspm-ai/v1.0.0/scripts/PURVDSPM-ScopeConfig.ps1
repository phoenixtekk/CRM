<#
.SYNOPSIS
    PURVDSPM-ScopeConfig.ps1 — confirm DSPM scope, sign-in, auditing, and the features that feed posture (read-only).
.DESCRIPTION
    PURPOSE
        Read-only pre-flight for Data Security Posture Management. Confirms your Security & Compliance
        PowerShell (and optional Graph) sign-in, reports whether unified auditing is on, and enumerates
        the licensing-dependent controls (sensitivity labels, DLP, auto-labeling, Insider Risk presence)
        that DSPM aggregates into posture. Changes nothing.
    HOW TO RUN
        PowerShell 5.1+ or 7+, with the ExchangeOnlineManagement (Security & Compliance PowerShell) and,
        optionally, Microsoft.Graph modules:
          Connect-IPPSSession
          .\PURVDSPM-ScopeConfig.ps1
        To also probe Graph/auditing via Graph, pass -UseGraph (Connect-MgGraph is invoked read-only).
    EXPECTED RESULTS
        A readiness summary: sign-in OK, auditing on/off, and counts of labels / DLP / auto-labeling /
        Insider Risk artifacts present. Written to .\DSPM-ScopeConfig-Estate-Assess.csv. Resolves
        Requirements 2.1-2.3.
.NOTES
    White-label Microsoft Purview tooling. Read-only. No credentials are stored or requested in code.
    Availability caveat: DSPM / DSPM for AI blades and feature availability are licensing-/tenant-
    dependent and evolving — this script reports the controls it can see; confirm DSPM visibility in
    the Purview portal. Cmdlets used are standard Security & Compliance PowerShell; none are invented.
#>
[CmdletBinding()]
param(
    [switch]$UseGraph,
    [string]$OutPath = ".\DSPM-ScopeConfig-Estate-Assess.csv"
)

$ErrorActionPreference = "Stop"
Write-Host "=== PURVDSPM Scope/Config — DSPM readiness (read-only) ===" -ForegroundColor Cyan

$findings = [System.Collections.Generic.List[object]]::new()
function Add-Finding($check, $status, $detail) {
    $findings.Add([pscustomobject]@{ Check = $check; Status = $status; Detail = $detail })
    $color = switch ($status) { "OK" { "Green" } "WARN" { "Yellow" } default { "Red" } }
    Write-Host ("  [{0,-4}] {1} — {2}" -f $status, $check, $detail) -ForegroundColor $color
}

# 1. Security & Compliance PowerShell session
try {
    $labels = Get-Label -ErrorAction Stop
    Add-Finding "S&C PowerShell session" "OK" ("Connected; {0} sensitivity label(s) visible" -f @($labels).Count)
} catch {
    Add-Finding "S&C PowerShell session" "FAIL" "Not connected. Run Connect-IPPSSession first (Requirement 2.2/GR §3)."
    $labels = @()
}

# 2. Label policies
try {
    $labelPolicies = Get-LabelPolicy -ErrorAction Stop
    Add-Finding "Label policies" "OK" ("{0} label policy(ies)" -f @($labelPolicies).Count)
} catch { Add-Finding "Label policies" "WARN" "Could not read label policies: $($_.Exception.Message)" }

# 3. DLP policies (the reduction lever)
try {
    $dlp = Get-DlpCompliancePolicy -ErrorAction Stop
    $status = if (@($dlp).Count -gt 0) { "OK" } else { "WARN" }
    Add-Finding "DLP policies" $status ("{0} DLP policy(ies) — the oversharing/AI reduction lever (Req 2.4)" -f @($dlp).Count)
} catch { Add-Finding "DLP policies" "WARN" "Could not read DLP policies: $($_.Exception.Message)" }

# 4. Auto-labeling policies
try {
    $auto = Get-AutoSensitivityLabelPolicy -ErrorAction Stop
    Add-Finding "Auto-labeling policies" "OK" ("{0} auto-labeling policy(ies)" -f @($auto).Count)
} catch { Add-Finding "Auto-labeling policies" "WARN" "Could not read auto-labeling policies (may be unlicensed): $($_.Exception.Message)" }

# 5. Insider Risk presence (a DSPM signal source) — best-effort, non-fatal
try {
    $irCmd = Get-Command Get-InsiderRiskPolicy -ErrorAction SilentlyContinue
    if ($irCmd) {
        $ir = Get-InsiderRiskPolicy -ErrorAction Stop
        Add-Finding "Insider Risk" "OK" ("{0} insider-risk policy(ies) present" -f @($ir).Count)
    } else {
        Add-Finding "Insider Risk" "WARN" "Get-InsiderRiskPolicy not available in this session/plan — verify in portal."
    }
} catch { Add-Finding "Insider Risk" "WARN" "Insider Risk not readable (may be unlicensed): $($_.Exception.Message)" }

# 6. Unified auditing (feeds DSPM-for-AI prompt/response reporting) — needs Exchange Online session
try {
    $cfgCmd = Get-Command Get-AdminAuditLogConfig -ErrorAction SilentlyContinue
    if ($cfgCmd) {
        $cfg = Get-AdminAuditLogConfig -ErrorAction Stop
        $on = $cfg.UnifiedAuditLogIngestionEnabled
        Add-Finding "Unified auditing" ($(if ($on) { "OK" } else { "FAIL" })) ("UnifiedAuditLogIngestionEnabled = {0} (Req 2.3 — needed for AI reports)" -f $on)
    } else {
        Add-Finding "Unified auditing" "WARN" "Get-AdminAuditLogConfig not in this session — connect Exchange Online, or confirm auditing in Purview → Audit."
    }
} catch { Add-Finding "Unified auditing" "WARN" "Could not read audit config: $($_.Exception.Message). Confirm in Purview → Audit." }

# 7. Optional Graph probe (read-only)
if ($UseGraph) {
    try {
        if (-not (Get-MgContext)) { Connect-MgGraph -Scopes "Reports.Read.All","Organization.Read.All" -NoWelcome -ErrorAction Stop }
        $ctx = Get-MgContext
        Add-Finding "Graph session" "OK" ("Connected as {0}" -f $ctx.Account)
    } catch { Add-Finding "Graph session" "WARN" "Graph connect failed: $($_.Exception.Message)" }
}

$findings | Export-Csv -Path $OutPath -NoTypeInformation -Encoding UTF8
Write-Host ("`nReadiness written to {0}  (DSPM ScopeConfig - Estate - Assess)" -f $OutPath) -ForegroundColor Green
Write-Host "Next: confirm DSPM and DSPM for AI are visible in the Purview portal, then run PURVDSPM-Discovery.ps1." -ForegroundColor Cyan
if ($findings | Where-Object Status -eq "FAIL") { Write-Host "`nOne or more FAIL checks — resolve before proceeding." -ForegroundColor Red }
