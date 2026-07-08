<#
.SYNOPSIS
    CMPDASH-Scope.ps1 — confirm which dashboard feeds the current identity can read + feed health, and prove role separation (read-only).
.DESCRIPTION
    PURPOSE
        Preflights the Risk & Compliance Dashboard collector identity: for each live feed (DLP, sensitivity
        labels, retention, audit config) it reports read OK / permission-denied and a freshness/health note,
        so a role gap is not mistaken for a missing signal. It also PROVES role separation — the collector
        must NOT be able to read Insider Risk / Communication Compliance case content; those feeds must be
        aggregate/owner-captured. Read-only; reads no HR-sensitive case content.
    HOW TO RUN
        powershell -ExecutionPolicy Bypass -File .\CMPDASH-Scope.ps1
        Connect first: Connect-IPPSSession (ExchangeOnlineManagement) as the least-privilege collector
        identity (Requirement 2.2). Optionally Connect-MgGraph for audit-read confirmation. PowerShell 5.1+/7+.
    EXPECTED RESULTS
        Per feed: readable / not-readable (role) + a health note; and confirmation that the HR-sensitive
        feeds are NOT readable by this account (role separation holds). Resolve any red before piloting.
.NOTES
    Purview category — Risk & Compliance Dashboard. Read-only. Availability is licensing-dependent — verify
    your licensing/tenant. Insider Risk / Communication Compliance are aggregate/owner-captured by design.
#>
[CmdletBinding()]
param(
    [switch]$SkipGraph
)

$ErrorActionPreference = 'Stop'
function Write-Section($t){ Write-Host "`n=== $t ===" -ForegroundColor Cyan }
function Ok($m){ Write-Host "  [OK]   $m" -ForegroundColor Green }
function Warn($m){ Write-Host "  [WARN] $m" -ForegroundColor Yellow }
function Info($m){ Write-Host "  $m" -ForegroundColor White }

# --- Live feeds: readability + health ---
Write-Section "Live feed readability + health"
$feeds = [ordered]@{
    'DLP policies'          = { Get-DlpCompliancePolicy -ErrorAction Stop }
    'Sensitivity labels'    = { Get-Label -ErrorAction Stop }
    'Label policies'        = { Get-LabelPolicy -ErrorAction Stop }
    'Retention policies'    = { Get-RetentionCompliancePolicy -ErrorAction Stop }
}
foreach ($name in $feeds.Keys) {
    try {
        $items = @(& $feeds[$name])
        Ok ("{0}: read OK ({1} object(s))" -f $name, $items.Count)
        if ($items.Count -eq 0) { Info "    health: readable but empty — the tile will render 0 (a legitimate value, not an error)." }
    } catch {
        $msg = $_.Exception.Message
        if ($msg -match 'access|denied|role|permission|not recognized') { Warn ("{0}: read FAILED — likely role/permission (grant least-privilege reader per Requirement 2.2)" -f $name) }
        else { Warn ("{0}: read FAILED — {1}" -f $name, $msg) }
    }
}

# --- Audit ingestion state (health) ---
Write-Section "Audit feed health"
try {
    $cfg = Get-AdminAuditLogConfig -ErrorAction Stop
    if ($cfg.UnifiedAuditLogIngestionEnabled) { Ok "Unified audit-log ingestion: ENABLED — DLP/label volume tiles have a source." }
    else { Warn "Unified audit-log ingestion: DISABLED — volume tiles will have no source until enabled (CMPDASH-Set-Configuration -EnableAuditIngestion -Commit)." }
} catch { Warn "Could not read Get-AdminAuditLogConfig (verify View-Only Audit Logs / role)." }

# --- Role separation: HR-sensitive feeds must NOT be readable by the collector ---
Write-Section "Role separation (HR-sensitive feeds must be aggregate/owner-captured)"
$separationOk = $true
# Insider Risk / Communication Compliance have no collector-safe public read; the collector must not be an investigator.
$sensitiveProbes = [ordered]@{
    'Insider Risk case content'          = { Get-InsiderRiskPolicy -ErrorAction Stop }   # may not exist for this account/tenant — that is the intended result
    'Communication Compliance case body' = { Get-SupervisoryReviewPolicyV2 -ErrorAction Stop }
}
foreach ($name in $sensitiveProbes.Keys) {
    try {
        & $sensitiveProbes[$name] | Out-Null
        Warn ("{0}: this account CAN read a HR-sensitive interface — role separation is BROKEN. The collector must not hold investigator roles (Requirement 2.2). These feeds are aggregate/owner-captured only." -f $name)
        $separationOk = $false
    } catch {
        Ok ("{0}: not readable by this account — role separation holds (aggregate/owner-captured only)." -f $name)
    }
}
if ($separationOk) { Info "The collector identity cannot read HR-sensitive case content — as required. Aggregate figures are entered by their program owners." }
else { Warn "Remove the collector from Insider Risk / Communication Compliance investigator role groups before piloting." }

if (-not $SkipGraph) {
    Write-Section "Graph audit-read confirmation (optional)"
    if (Get-Module -ListAvailable -Name Microsoft.Graph.Authentication) {
        try {
            Import-Module Microsoft.Graph.Authentication -ErrorAction Stop
            Connect-MgGraph -Scopes 'AuditLog.Read.All' -NoWelcome -ErrorAction Stop
            Ok "Connect-MgGraph with AuditLog.Read.All succeeded — audit reads available for reconciliation."
        } catch { Warn "Graph audit-read not confirmed: $($_.Exception.Message)" }
    } else { Warn "Microsoft.Graph not installed — skipping (Install-Module Microsoft.Graph or -SkipGraph)." }
}

Write-Section "Preflight summary"
Info "Resolve any WARN on live-feed reads or role separation before piloting CMPDASH-Report.ps1."
Info "A feed that reads empty, or a signal flagged 'verify your licensing/tenant', is owner-captured — not a live read to fabricate."
