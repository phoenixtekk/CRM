<#
.SYNOPSIS
    AIEXPOSE-ScopeCheck.ps1 — confirm assessment scope, sign-in, auditing, and the AI/Copilot signal sources (read-only).
.DESCRIPTION
    PURPOSE
        Read-only pre-flight for an AI Data-Exposure Assessment. Confirms your Security & Compliance
        PowerShell (and optional Graph) sign-in, reports whether unified auditing is on (the source of
        AI-interaction signal), and enumerates the licensing-dependent controls (sensitivity labels, DLP,
        auto-labeling) and the DSPM-for-AI / Copilot presence that the assessment measures against.
        Changes nothing.
    HOW TO RUN
        PowerShell 5.1+ or 7+, with the ExchangeOnlineManagement (Security & Compliance PowerShell) and,
        optionally, Microsoft.Graph modules:
          Connect-IPPSSession
          .\AIEXPOSE-ScopeCheck.ps1
        To also probe Graph (used later for the reachability/sharing signal), pass -UseGraph
        (Connect-MgGraph is invoked read-only).
    EXPECTED RESULTS
        A readiness summary: sign-in OK, auditing on/off, and counts of labels / DLP / auto-labeling
        artifacts present, plus whether Copilot/AI audit records are visible. Written to
        .\AIEXPOSE-ScopeCheck-Estate-Assess.csv. Resolves Requirements 2.1-2.4. Any FAIL must be
        resolved before assessing.
.NOTES
    White-label Microsoft Purview tooling. Read-only. No credentials are stored or requested in code.
    Availability caveat: DSPM for AI blades and feature availability are licensing-/tenant-dependent and
    evolving — this script reports the controls it can see; confirm DSPM-for-AI visibility in the Purview
    portal. Cmdlets used are standard Security & Compliance PowerShell / Graph; none are invented.
#>
[CmdletBinding()]
param(
    [switch]$UseGraph,
    [string]$OutPath = ".\AIEXPOSE-ScopeCheck-Estate-Assess.csv"
)

$ErrorActionPreference = "Stop"
Write-Host "=== AIEXPOSE Scope Check — AI Data-Exposure Assessment readiness (read-only) ===" -ForegroundColor Cyan

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

# 2. Label policies — how far labeling is actually published (label coverage bounds exposure)
try {
    $labelPolicies = Get-LabelPolicy -ErrorAction Stop
    Add-Finding "Label policies" "OK" ("{0} label policy(ies) published" -f @($labelPolicies).Count)
} catch { Add-Finding "Label policies" "WARN" "Could not read label policies: $($_.Exception.Message)" }

# 3. DLP policies — the primary lever any recommended fix will use
try {
    $dlp = Get-DlpCompliancePolicy -ErrorAction Stop
    $status = if (@($dlp).Count -gt 0) { "OK" } else { "WARN" }
    Add-Finding "DLP policies" $status ("{0} DLP policy(ies) — the reduction lever a recommended fix would use (Req 2.4)" -f @($dlp).Count)
} catch { Add-Finding "DLP policies" "WARN" "Could not read DLP policies: $($_.Exception.Message)" }

# 4. Auto-labeling policies — needed to prove the simulation remediation path (script 4)
try {
    $auto = Get-AutoSensitivityLabelPolicy -ErrorAction Stop
    Add-Finding "Auto-labeling policies" "OK" ("{0} auto-labeling policy(ies) — simulation is the pilot remediation path" -f @($auto).Count)
} catch { Add-Finding "Auto-labeling policies" "WARN" "Could not read auto-labeling policies (may be unlicensed): $($_.Exception.Message)" }

# 5. Unified auditing (feeds AI-interaction signal) — needs an Exchange Online session
try {
    $cfgCmd = Get-Command Get-AdminAuditLogConfig -ErrorAction SilentlyContinue
    if ($cfgCmd) {
        $cfg = Get-AdminAuditLogConfig -ErrorAction Stop
        $on = $cfg.UnifiedAuditLogIngestionEnabled
        Add-Finding "Unified auditing" ($(if ($on) { "OK" } else { "FAIL" })) ("UnifiedAuditLogIngestionEnabled = {0} (Req 2.3 — needed for AI-interaction signal)" -f $on)
    } else {
        Add-Finding "Unified auditing" "WARN" "Get-AdminAuditLogConfig not in this session — connect Exchange Online, or confirm auditing in Purview → Audit."
    }
} catch { Add-Finding "Unified auditing" "WARN" "Could not read audit config: $($_.Exception.Message). Confirm in Purview → Audit." }

# 6. Copilot / AI interaction records present? — best-effort, non-fatal (pre-adoption may show none)
try {
    $ualCmd = Get-Command Search-UnifiedAuditLog -ErrorAction SilentlyContinue
    if ($ualCmd) {
        $probe = Search-UnifiedAuditLog -StartDate (Get-Date).AddDays(-30) -EndDate (Get-Date) `
                    -RecordType "CopilotInteraction" -ResultSize 1 -ErrorAction Stop
        if (@($probe).Count -gt 0) {
            Add-Finding "AI/Copilot interaction signal" "OK" "CopilotInteraction audit records present (in-adoption assessment)."
        } else {
            Add-Finding "AI/Copilot interaction signal" "WARN" "No CopilotInteraction records in last 30d — pre-adoption, or auditing/RecordType differs. Assess reachability regardless."
        }
    } else {
        Add-Finding "AI/Copilot interaction signal" "WARN" "Search-UnifiedAuditLog not in this session — connect Exchange Online to probe AI-interaction records."
    }
} catch { Add-Finding "AI/Copilot interaction signal" "WARN" "Could not probe AI-interaction records (RecordType may differ in your tenant): $($_.Exception.Message)" }

# 7. Optional Graph probe (read-only) — used later for site/OneDrive reachability signal
if ($UseGraph) {
    try {
        if (-not (Get-MgContext)) { Connect-MgGraph -Scopes "Sites.Read.All","Reports.Read.All","Organization.Read.All" -NoWelcome -ErrorAction Stop }
        $ctx = Get-MgContext
        Add-Finding "Graph session" "OK" ("Connected as {0}" -f $ctx.Account)
    } catch { Add-Finding "Graph session" "WARN" "Graph connect failed: $($_.Exception.Message)" }
}

$findings | Export-Csv -Path $OutPath -NoTypeInformation -Encoding UTF8
Write-Host ("`nReadiness written to {0}  (AIEXPOSE Scope Check - Estate - Assess)" -f $OutPath) -ForegroundColor Green
Write-Host "Next: confirm DSPM for AI is visible in the Purview portal, then run AIEXPOSE-Discovery.ps1." -ForegroundColor Cyan
if ($findings | Where-Object Status -eq "FAIL") { Write-Host "`nOne or more FAIL checks — resolve before assessing." -ForegroundColor Red }
