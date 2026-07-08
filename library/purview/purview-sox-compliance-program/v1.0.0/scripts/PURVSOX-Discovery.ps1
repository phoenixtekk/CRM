<#
.SYNOPSIS
    PURVSOX-Discovery.ps1 — inventory the SOX-relevant Purview control state (read-only).
.DESCRIPTION
    PURPOSE
        Reports the current state with no changes: whether unified audit log ingestion is on, and the
        existing sensitivity labels/label policies, DLP policies (with their Mode), retention policies,
        and audit log retention policies — flagging which of this program's named artifacts already
        exist. Read-only.
    HOW TO RUN
        powershell -ExecutionPolicy Bypass -File .\PURVSOX-Discovery.ps1
        Requires the ExchangeOnlineManagement module (Connect-IPPSSession for labels/DLP/retention/
        audit-retention; Connect-ExchangeOnline for the audit-config read). Interactive modern-auth /
        MFA admin sign-in; no secrets in code.
    EXPECTED RESULTS
        A posture summary: UnifiedAuditLogIngestionEnabled True/False; tables of labels, DLP policies +
        Mode, retention policies, and audit retention policies; and a checklist of which program
        artifacts (label, DLP, retention, audit-retention) are already present.
.NOTES
    Purview category — SOX Compliance Program. Read-only. DLP Mode of TestWithNotifications/
    TestWithoutNotifications means SIMULATION (reports without blocking); Enable means enforcing.
    Feature availability is licensing-/tenant-dependent and evolving.
#>
[CmdletBinding()]
param(
    [string]$UserPrincipalName
)

$ErrorActionPreference = 'Stop'
function Write-Section($t){ Write-Host "`n=== $t ===" -ForegroundColor Cyan }
function Ok($m){ Write-Host $m -ForegroundColor Green }
function Warn($m){ Write-Host $m -ForegroundColor Yellow }

# Named artifacts this program manages (for the "already exists?" checklist)
$named = @{
    Label          = 'Financial – SOX Reporting – Confidential'
    Dlp            = 'DLP – SOX Financial Data – Simulation'
    Retention      = 'Retention – SOX Financial Records – Governed'
    AuditRetention = 'Audit Retention – Financial Data Access – SOX'
}

if (-not (Get-Module -ListAvailable -Name ExchangeOnlineManagement)) {
    Warn "ExchangeOnlineManagement not installed. Install-Module ExchangeOnlineManagement -Scope CurrentUser"; return
}
Import-Module ExchangeOnlineManagement -ErrorAction Stop
$cp = @{ ShowBanner = $false }; if ($UserPrincipalName) { $cp['UserPrincipalName'] = $UserPrincipalName }

# --- Unified audit ingestion (Exchange Online) ---
Write-Section "Unified audit log ingestion (evidence foundation)"
try {
    Connect-ExchangeOnline @cp -ErrorAction Stop | Out-Null
    $cfg = Get-AdminAuditLogConfig
    if ($cfg.UnifiedAuditLogIngestionEnabled) { Ok "UnifiedAuditLogIngestionEnabled : True (audit is ON — SOX access/change evidence is being captured)" }
    else { Warn "UnifiedAuditLogIngestionEnabled : False (audit is OFF — no evidence is captured; NOT retroactive). Enable via PURVSOX-ConfigureControls.ps1 -EnableUnifiedAudit -Commit" }
} catch { Warn "Could not read AdminAuditLogConfig (Connect-ExchangeOnline): $($_.Exception.Message)" }

# --- Labels / DLP / retention / audit-retention (Security & Compliance PowerShell) ---
try { Connect-IPPSSession @cp -ErrorAction Stop | Out-Null }
catch { Warn "Connect-IPPSSession failed — cannot read labels/DLP/retention: $($_.Exception.Message)"; return }

Write-Section "Sensitivity labels"
try {
    $labels = Get-Label -ErrorAction Stop
    if ($labels) { $labels | Select-Object Name, DisplayName, Priority | Format-Table -AutoSize | Out-String | Write-Host }
    else { Warn "No sensitivity labels found." }
} catch { Warn "Could not read labels (Get-Label): $($_.Exception.Message)" }

Write-Section "DLP policies (Mode: Test* = SIMULATION, Enable = enforcing)"
try {
    $dlps = Get-DlpCompliancePolicy -ErrorAction Stop
    if ($dlps) { $dlps | Select-Object Name, Mode, Workload | Format-Table -AutoSize | Out-String | Write-Host }
    else { Warn "No DLP policies found." }
} catch { Warn "Could not read DLP policies (Get-DlpCompliancePolicy): $($_.Exception.Message)" }

Write-Section "Retention policies"
try {
    $rps = Get-RetentionCompliancePolicy -ErrorAction Stop
    if ($rps) { $rps | Select-Object Name, Enabled, Mode | Format-Table -AutoSize | Out-String | Write-Host }
    else { Warn "No retention policies found." }
} catch { Warn "Could not read retention policies (Get-RetentionCompliancePolicy): $($_.Exception.Message)" }

Write-Section "Audit log retention policies"
try {
    $arp = Get-UnifiedAuditLogRetentionPolicy -ErrorAction Stop
    if ($arp) { $arp | Sort-Object Priority | Format-Table Name, RetentionDuration, Priority, RecordTypes -AutoSize | Out-String | Write-Host }
    else { Warn "No audit log retention policies found (records fall back to default retention only)." }
} catch { Warn "Could not read audit retention policies (Get-UnifiedAuditLogRetentionPolicy): $($_.Exception.Message)" }

# --- Program artifact checklist ---
Write-Section "Program artifacts present?"
try {
    $labelNames = (Get-Label -ErrorAction SilentlyContinue | Select-Object -ExpandProperty DisplayName) + (Get-Label -ErrorAction SilentlyContinue | Select-Object -ExpandProperty Name)
    $dlpNames   = Get-DlpCompliancePolicy -ErrorAction SilentlyContinue | Select-Object -ExpandProperty Name
    $rpNames    = Get-RetentionCompliancePolicy -ErrorAction SilentlyContinue | Select-Object -ExpandProperty Name
    $arpNames   = Get-UnifiedAuditLogRetentionPolicy -ErrorAction SilentlyContinue | Select-Object -ExpandProperty Name
    function Present($n,$set){ if ($set -contains $n) { Ok "  present : $n" } else { Warn "  missing : $n" } }
    Present $named.Label          $labelNames
    Present $named.Dlp            $dlpNames
    Present $named.Retention      $rpNames
    Present $named.AuditRetention $arpNames
} catch { Warn "Artifact checklist failed: $($_.Exception.Message)" }

Write-Section "Summary"
Write-Host "Gaps above drive the Implementation steps. Configure each missing control pilot-first (DLP in simulation) with PURVSOX-ConfigureControls.ps1." -ForegroundColor White
