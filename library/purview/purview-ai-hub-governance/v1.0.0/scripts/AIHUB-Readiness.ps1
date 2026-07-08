<#
.SYNOPSIS
    AIHUB-Readiness.ps1 — AI-governance readiness/health: licensing signal, audit on, onboarding reminder, DLP-for-AI pilot-scope sanity, preview flag (read-only).
.DESCRIPTION
    A pre-flight and cadence health check for DSPM-for-AI governance. Reports PASS/WARN/FAIL for: an
    information-protection/compliance licensing signal (from Graph subscribed SKUs); unified audit being
    enabled (AI visibility); DLP-for-AI pilot-scope sanity (a policy stranded in test after expansion, or a
    pilot policy flipped to Enable prematurely); and reminders for endpoint/browser onboarding and the
    preview/evolving nature of DSPM for AI. Read-only - makes no changes.
.EXAMPLE
    .\AIHUB-Readiness.ps1
    Reports licensing, audit, DLP-for-AI pilot sanity, and onboarding/preview reminders.
.EXAMPLE
    .\AIHUB-Readiness.ps1 -PolicyName "AI-DLP-ProtectLabeled-Sim" -PilotNamePattern 'Sim'
    Treats a policy whose name matches 'Sim' as a pilot/simulation policy for the stranded-in-test check.
.NOTES
    Requires PowerShell 5.1+/7+. Modules: ExchangeOnlineManagement (Connect-IPPSSession) and Microsoft Graph
    (Get-MgSubscribedSku). Role: Compliance/DLP + Audit reader; Organization.Read.All for the licensing signal.
    Expected results: PASS (green) = licensing signal present, audit on, no stranded/premature DLP-for-AI
    policy. WARN/FAIL (yellow/red) = a prerequisite missing or a scope issue to reconcile. Verify your
    licensing/tenant and the preview status of the capabilities you use.
#>
[CmdletBinding()]
param(
    [string]$PolicyName = 'AI-DLP-ProtectLabeled-Sim',
    [string]$PilotNamePattern = 'Sim|Pilot'
)

function Say([string]$tag, [string]$name, [string]$col, [string]$detail) {
    Write-Host ("  [{0}] {1} {2}" -f $tag, $name, $detail) -ForegroundColor $col
}

Write-Host "`n=== AIHUB DSPM-for-AI readiness (read-only) ===" -ForegroundColor Cyan

# --- 1. Licensing signal ---
Write-Host "`n-- Licensing signal --" -ForegroundColor Cyan
try {
    if (-not (Get-Command Get-MgSubscribedSku -ErrorAction SilentlyContinue)) { Import-Module Microsoft.Graph.Identity.DirectoryManagement -ErrorAction Stop }
    if (-not (Get-MgContext -ErrorAction SilentlyContinue)) { Connect-MgGraph -Scopes 'Organization.Read.All' -NoWelcome -ErrorAction Stop }
    $plans = @()
    foreach ($s in (Get-MgSubscribedSku -ErrorAction Stop)) { foreach ($p in $s.ServicePlans) { $plans += "$($p.ServicePlanName)" } }
    $signals = $plans | Where-Object { $_ -match 'INFORMATION_PROTECTION|COMPLIANCE|M365_ADVANCED_AUDITING|INSIDER_RISK|COMMUNICATION_COMPLIANCE|E5|COPILOT' } | Sort-Object -Unique
    if ($signals) { Say 'PASS' 'Compliance/AI licensing signal' 'Green' "(plans: $((@($signals) | Select-Object -First 6) -join ', ')…)" }
    else { Say 'WARN' 'Compliance/AI licensing signal' 'Yellow' '(no obvious E5/E5-Compliance/Copilot plan matched - VERIFY YOUR LICENSING/TENANT)' }
} catch { Say 'SKIP' 'Licensing signal' 'Yellow' '(Graph not available - verify E5 / E5 Compliance / Copilot in the M365 admin center)' }

# --- 2. Audit on ---
Write-Host "`n-- AI visibility (unified audit) --" -ForegroundColor Cyan
try {
    Import-Module ExchangeOnlineManagement -ErrorAction Stop
    if (-not (Get-Command Get-AdminAuditLogConfig -ErrorAction SilentlyContinue)) { Connect-IPPSSession -ShowBanner:$false -ErrorAction Stop | Out-Null }
    $on = [bool](Get-AdminAuditLogConfig -ErrorAction Stop).UnifiedAuditLogIngestionEnabled
    if ($on) { Say 'PASS' 'Unified audit enabled' 'Green' '' }
    else { Say 'FAIL' 'Unified audit enabled' 'Red' '(off - AI visibility depends on it; AIHUB-Config.ps1 -EnableAudit -Commit)' }
} catch { Say 'SKIP' 'Audit check' 'Yellow' "($($_.Exception.Message))" }

# --- 3. DLP-for-AI pilot-scope sanity ---
Write-Host "`n-- DLP-for-AI pilot-scope sanity --" -ForegroundColor Cyan
try {
    if (-not (Get-Command Get-DlpCompliancePolicy -ErrorAction SilentlyContinue)) { Connect-IPPSSession -ShowBanner:$false -ErrorAction Stop | Out-Null }
    $p = Get-DlpCompliancePolicy -Identity $PolicyName -ErrorAction SilentlyContinue
    if (-not $p) {
        Say 'INFO' "DLP-for-AI policy '$PolicyName'" 'Gray' '(not created yet - Step 5)'
    } else {
        $mode = "$($p.Mode)"
        $isPilotNamed = ($p.Name -match $PilotNamePattern)
        if ($isPilotNamed -and $mode -match 'Enable') {
            Say 'WARN' "Policy '$PolicyName'" 'Yellow' "(pilot/sim-named but Mode=Enable - confirm this was a deliberate post-pilot enforcement, then rename/retire the pilot marker)"
        } elseif ($mode -match 'Enable') {
            Say 'PASS' "Policy '$PolicyName'" 'Green' "(Mode=Enable - enforcing)"
        } else {
            Say 'INFO' "Policy '$PolicyName'" 'Gray' "(Mode=$mode - simulation; enforce only after the pilot passes)"
        }
    }
} catch { Say 'SKIP' 'DLP-for-AI check' 'Yellow' "($($_.Exception.Message))" }

# --- 4. Onboarding + preview reminders ---
Write-Host "`n-- Reminders (portal-verified) --" -ForegroundColor Cyan
Say 'VERIFY' 'Consumer-AI egress' 'Yellow' '(needs onboarded devices + Purview browser extension - confirm in Settings -> Device onboarding)'
Say 'VERIFY' 'Insider-risk / comms-compliance detections' 'Yellow' '(portal-configured, privacy-by-design, role-separated - outcomes deferred to HR/legal)'
Say 'VERIFY' 'DSPM for AI is new/evolving/PREVIEW' 'Yellow' '(portal paths, policy names, and audit record types change - verify current guidance for your tenant)'

Write-Host "`n=== Readiness summary ===" -ForegroundColor Cyan
Write-Host "AI governance is safe to enforce only when: licensing covers the controls, audit is on, the DLP-for-AI" -ForegroundColor Gray
Write-Host "policy passed its pilot in simulation, and the portal-driven detections are configured privacy-by-design." -ForegroundColor Gray
