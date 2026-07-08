<#
.SYNOPSIS
    CMPNIST-Discovery.ps1 — inventory the Purview control posture that backs the NIST 800-53 families (read-only).
.DESCRIPTION
    PURPOSE
        Reports, with no changes, the Purview controls that supply NIST 800-53 evidence: unified-audit
        state and audit-log retention policies (AU); DLP policies and their MODE — Enable vs simulation
        (SC/MP/SI); published sensitivity labels and label policies (AC/SC); and retention policies. This
        is the current-state input to the control-to-Purview map. Read-only.
    HOW TO RUN
        powershell -ExecutionPolicy Bypass -File .\CMPNIST-Discovery.ps1
        # Optional CSV of the DLP inventory:
        .\CMPNIST-Discovery.ps1 -CsvPath .\nist-purview-posture.csv
        Requires ExchangeOnlineManagement (Connect-IPPSSession + Connect-ExchangeOnline). Interactive
        modern-auth / MFA admin; no secrets in code.
    EXPECTED RESULTS
        A per-family posture: UnifiedAuditLogIngestionEnabled True/False, the audit-retention policies,
        each DLP policy with its Mode (simulation policies show TestWithoutNotifications), the published
        labels/label policies, and the retention policies. Gaps are flagged for the map.
.NOTES
    Purview category — NIST 800-53 program. Read-only. Compliance Manager assessment/score is a portal
    operation (not scripted here). Feature availability is licensing-/tenant-dependent and evolving.
    Authorization/applicability determinations are deferred to your AO/security/compliance/legal functions.
#>
[CmdletBinding()]
param(
    [string]$UserPrincipalName,
    [string]$CsvPath                            # optional: export the DLP inventory to CSV
)

$ErrorActionPreference = 'Stop'
function Write-Section($t){ Write-Host "`n=== $t ===" -ForegroundColor Cyan }
function Ok($m){ Write-Host $m -ForegroundColor Green }
function Warn($m){ Write-Host $m -ForegroundColor Yellow }

if (-not (Get-Module -ListAvailable -Name ExchangeOnlineManagement)) {
    Warn "ExchangeOnlineManagement not installed. Install-Module ExchangeOnlineManagement -Scope CurrentUser"; return
}
Import-Module ExchangeOnlineManagement -ErrorAction Stop
$cp = @{ ShowBanner = $false }; if ($UserPrincipalName) { $cp['UserPrincipalName'] = $UserPrincipalName }

# --- AU family: unified audit + audit-log retention ---
Write-Section "AU — Unified audit log ingestion (Exchange Online)"
try {
    Connect-ExchangeOnline @cp -ErrorAction Stop | Out-Null
    $cfg = Get-AdminAuditLogConfig
    if ($cfg.UnifiedAuditLogIngestionEnabled) { Ok "UnifiedAuditLogIngestionEnabled : True (AU foundation ON)" }
    else { Warn "UnifiedAuditLogIngestionEnabled : False (AU evidence NOT being written; not retroactive). Enable via CMPNIST-Set-ControlPolicy.ps1 -EnableUnifiedAudit -Commit" }
    $org = Get-OrganizationConfig
    if ($org.AuditDisabled) { Warn "Org mailbox auditing (AuditDisabled) : True (OFF)" } else { Ok "Org mailbox auditing : ON" }
} catch { Warn "Could not read audit config: $($_.Exception.Message)" }

# --- S&C PowerShell for DLP, labels, retention, audit-retention ---
$ippsOk = $false
try { Connect-IPPSSession @cp -ErrorAction Stop | Out-Null; $ippsOk = $true } catch { Warn "Connect-IPPSSession failed: $($_.Exception.Message)" }

if ($ippsOk) {
    Write-Section "AU — Audit-log retention policies"
    try {
        $arp = Get-UnifiedAuditLogRetentionPolicy -ErrorAction Stop
        if ($arp) { $arp | Sort-Object Priority | Format-Table Name, RetentionDuration, Priority, RecordTypes -AutoSize | Out-String | Write-Host }
        else { Warn "No audit-log retention policies found (records fall back to default retention only). Map gap: Control Evidence – NIST AU – Audit Retention" }
    } catch { Warn "Could not read audit-retention policies: $($_.Exception.Message)" }

    Write-Section "SC/MP/SI — DLP policies and their MODE"
    try {
        $dlp = Get-DlpCompliancePolicy -ErrorAction Stop
        if ($dlp) {
            $rows = $dlp | Select-Object Name, Mode, @{n='Workloads';e={ ($_.Workload) }}, Enabled
            $rows | Format-Table -AutoSize | Out-String | Write-Host
            $sim = $dlp | Where-Object { "$($_.Mode)" -like 'Test*' }
            if ($sim) { Ok  ("{0} DLP policy(ies) in SIMULATION/test mode (detect, don't block)." -f @($sim).Count) }
            $enf = $dlp | Where-Object { "$($_.Mode)" -eq 'Enable' }
            if ($enf) { Ok ("{0} DLP policy(ies) ENFORCING." -f @($enf).Count) }
            if ($CsvPath) { $rows | Export-Csv -Path $CsvPath -NoTypeInformation -Encoding UTF8; Ok "DLP inventory exported: $CsvPath" }
        } else { Warn "No DLP policies found. Map gap: Control Evidence – NIST SC-MP – DLP (Simulation)" }
    } catch { Warn "Could not read DLP policies: $($_.Exception.Message)" }

    Write-Section "AC/SC — Published sensitivity labels and label policies"
    try {
        $labels = Get-Label -ErrorAction Stop
        if ($labels) {
            $labels | Select-Object DisplayName, Name, @{n='HasEncryption';e={ [bool]$_.EncryptionEnabled }} | Format-Table -AutoSize | Out-String | Write-Host
            $enc = $labels | Where-Object { $_.EncryptionEnabled }
            if ($enc) { Ok ("{0} label(s) with encryption/usage rights (AC-3/SC-28 evidence candidates)." -f @($enc).Count) }
            else { Warn "No labels with encryption found — AC/SC encryption evidence is a gap (assign to labeling workstream)." }
        } else { Warn "No sensitivity labels found. AC/SC evidence gap — record in the map." }
        $lp = Get-LabelPolicy -ErrorAction SilentlyContinue
        if ($lp) { $lp | Select-Object Name, Enabled | Format-Table -AutoSize | Out-String | Write-Host } else { Warn "No label policies published (labels not surfaced to users)." }
    } catch { Warn "Could not read labels: $($_.Exception.Message)" }

    Write-Section "Retention — Retention policies/labels"
    try {
        $rp = Get-RetentionCompliancePolicy -ErrorAction Stop
        if ($rp) { $rp | Select-Object Name, Enabled, Mode | Format-Table -AutoSize | Out-String | Write-Host } else { Warn "No retention policies found — record in the map if required by the boundary." }
    } catch { Warn "Could not read retention policies: $($_.Exception.Message)" }
}

Write-Section "Summary"
Write-Host "Feed this current-state into NIST 800-53 – Control-to-Purview – Map. Mark each family Purview-covered or deferred." -ForegroundColor White
Write-Host "Compliance Manager assessment/score is confirmed in the portal. Authorization/ATO is the AO's decision — deferred." -ForegroundColor White
