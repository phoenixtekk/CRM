<#
.SYNOPSIS
    INDLEGAL-Discovery.ps1 — Legal control posture assessment across labels, DLP, retention, and audit (read-only).
.DESCRIPTION
    PURPOSE
        Reports the current Purview control posture for a legal organization with no changes: compliance
        licensing present (information-protection / DLP-endpoint / records / Audit Premium-bearing plans),
        existing sensitivity labels and label policies (flagging encryption), DLP policies (flagging mode:
        Enable vs Test/simulation), retention labels and policies (flagging records / regulatory records),
        unified audit ingestion state, existing audit log retention policies, and — read-only reference
        only — existing eDiscovery case holds so legal-hold coverage is visible. Read-only.
    HOW TO RUN
        powershell -ExecutionPolicy Bypass -File .\INDLEGAL-Discovery.ps1
        Requires the ExchangeOnlineManagement module (Connect-IPPSSession) and, for the licensing section,
        Microsoft.Graph with delegated Organization.Read.All / Directory.Read.All. Uses an interactive
        modern-auth / MFA admin sign-in; no secrets in code.
    EXPECTED RESULTS
        A posture summary per control domain. Any capability whose plan/behavior must be confirmed is
        flagged "verify your licensing/tenant", not asserted. PASS = each in-scope control is present and
        correctly typed (DLP in simulation until validated); FAIL = a control is missing or mis-typed
        (drives the Implementation Guide). The eDiscovery-hold section is REFERENCE ONLY — it never changes a hold.
.NOTES
    Purview category — Microsoft Purview for Legal (industry bundle). Read-only. Feature availability is
    licensing-/tenant-dependent and evolving; privilege/matter/retention/legal-hold determinations are
    deferred to your legal, records, and compliance functions. Legal holds and eDiscovery actions are the
    legal function's — this script only references them. Confirm cmdlet/plan names against your entitlements
    and current Microsoft documentation.
#>
[CmdletBinding()]
param(
    [string]$UserPrincipalName,          # optional: admin UPN to pass to Connect-* prompts
    [switch]$SkipGraphLicensing          # skip the Graph licensing section if Graph is unavailable
)

$ErrorActionPreference = 'Stop'
function Write-Section($t){ Write-Host "`n=== $t ===" -ForegroundColor Cyan }
function Ok($m){ Write-Host $m -ForegroundColor Green }
function Warn($m){ Write-Host $m -ForegroundColor Yellow }

# --- Connect: Security & Compliance PowerShell ---
if (-not (Get-Module -ListAvailable -Name ExchangeOnlineManagement)) {
    Warn "ExchangeOnlineManagement not installed. Install-Module ExchangeOnlineManagement -Scope CurrentUser"
    return
}
Import-Module ExchangeOnlineManagement -ErrorAction Stop
$connectParams = @{}
if ($UserPrincipalName) { $connectParams['UserPrincipalName'] = $UserPrincipalName }
try { Connect-IPPSSession @connectParams -ErrorAction Stop | Out-Null }
catch { Warn "Connect-IPPSSession failed: $($_.Exception.Message)"; return }

# --- Sensitivity labels (encryption) ---
Write-Section "Sensitivity labels (Get-Label)"
try {
    $labels = Get-Label -ErrorAction Stop
    if ($labels) {
        foreach ($l in $labels) {
            $enc = if ($l.EncryptionEnabled -or $l.EncryptionProtectionType) { 'ENCRYPTION on' } else { 'no encryption' }
            Write-Host ("  {0,-45} {1}" -f $l.DisplayName, $enc)
        }
        Ok ("{0} sensitivity label(s) found." -f @($labels).Count)
        Warn "An encryption label can make content unreadable to unlicensed/external parties — confirm the privileged label's decryption scope is legal's approved design."
    } else { Warn "No sensitivity labels found (no confidentiality control yet)." }
} catch { Warn "Could not read sensitivity labels (Get-Label): $($_.Exception.Message) — verify the cmdlet/feature for your tenant." }

# --- Label policies ---
Write-Section "Label publish policies (Get-LabelPolicy)"
try {
    $lp = Get-LabelPolicy -ErrorAction Stop
    if ($lp) { $lp | Select-Object Name, Enabled | Format-Table -AutoSize | Out-String | Write-Host; Ok ("{0} label policy(ies) found." -f @($lp).Count) }
    else { Warn "No label policies found — labels are not published to any users yet." }
} catch { Warn "Could not read label policies (Get-LabelPolicy): $($_.Exception.Message)" }

# --- DLP policies (mode: Enable vs Test/simulation) ---
Write-Section "DLP policies (Get-DlpCompliancePolicy) — flagging mode"
try {
    $dlp = Get-DlpCompliancePolicy -ErrorAction Stop
    if ($dlp) {
        foreach ($d in $dlp) {
            $mode = "$($d.Mode)"
            $flag = if ($mode -match 'Test|Simulat') { 'SIMULATION/TEST (blocks nothing)' } elseif ($mode -match 'Enable') { 'ENFORCED (Enable)' } else { $mode }
            Write-Host ("  {0,-40} mode={1}" -f $d.Name, $flag)
        }
        Ok ("{0} DLP policy(ies) found." -f @($dlp).Count)
        Warn "High-impact: build/keep the Legal DLP policy in SIMULATION/TEST until its matches are reviewed and legal signs off; only then Enable."
    } else { Warn "No DLP policies found (no inadvertent-disclosure control yet). Build the first one in SIMULATION." }
} catch { Warn "Could not read DLP policies (Get-DlpCompliancePolicy): $($_.Exception.Message)" }

# --- Retention labels (records / regulatory records) ---
Write-Section "Retention labels (Get-ComplianceTag)"
try {
    $tags = Get-ComplianceTag -ErrorAction Stop
    if ($tags) {
        foreach ($t in $tags) {
            $type = if ($t.RegulatoryRecord) { 'REGULATORY RECORD (immutable, non-removable)' }
                    elseif ($t.IsRecordLabel) { 'record' } else { 'retain-only' }
            Write-Host ("  {0,-45} type={1}  retention={2}" -f $t.Name, $type, $t.RetentionDuration)
        }
        Ok ("{0} retention label(s) found." -f @($tags).Count)
        Warn "Regulatory-record labels cannot be removed and retention cannot be shortened — verify each before wider use; retention duration is records' determination."
    } else { Warn "No retention labels found (no matter-records control yet)." }
} catch { Warn "Could not read retention labels: $($_.Exception.Message)" }

# --- Retention policies ---
Write-Section "Retention policies (Get-RetentionCompliancePolicy)"
try {
    $pols = Get-RetentionCompliancePolicy -ErrorAction Stop
    if ($pols) {
        $pols | Select-Object Name, Enabled, Mode, Workload | Format-Table -AutoSize | Out-String | Write-Host
        Ok ("{0} retention policy(ies) found." -f @($pols).Count)
    } else { Warn "No retention policies found." }
} catch { Warn "Could not read retention policies: $($_.Exception.Message)" }

# --- Audit: ingestion + retention policies ---
Write-Section "Audit evidence: unified audit + retention policies"
try {
    $auditCfg = Get-AdminAuditLogConfig -ErrorAction Stop
    if ($auditCfg.UnifiedAuditLogIngestionEnabled) { Ok "UnifiedAuditLogIngestionEnabled : True (audit evidence is being captured)" }
    else { Warn "UnifiedAuditLogIngestionEnabled : False (NO audit evidence captured — enable under change control; NOT retroactive)" }
} catch { Warn "Could not read AdminAuditLogConfig (Get-AdminAuditLogConfig runs in Exchange Online PowerShell — Connect-ExchangeOnline): $($_.Exception.Message)" }
try {
    $arp = Get-UnifiedAuditLogRetentionPolicy -ErrorAction Stop
    if ($arp) { $arp | Sort-Object Priority | Format-Table Name, RetentionDuration, Priority -AutoSize | Out-String | Write-Host; Ok ("{0} audit retention policy(ies)." -f @($arp).Count) }
    else { Warn "No audit log retention policies (evidence falls back to default retention only)." }
} catch { Warn "Could not read audit retention policies: $($_.Exception.Message)" }

# --- eDiscovery holds (READ-ONLY REFERENCE — legal's control, never changed here) ---
Write-Section "eDiscovery legal holds (Get-CaseHoldPolicy) — READ-ONLY REFERENCE"
try {
    $holds = Get-CaseHoldPolicy -ErrorAction Stop
    if ($holds) {
        $holds | Select-Object Name, Enabled | Format-Table -AutoSize | Out-String | Write-Host
        Ok ("{0} case-hold policy(ies) visible (for legal's review)." -f @($holds).Count)
    } else { Warn "No case-hold policies visible. If legal expects a hold, that is a LEGAL action in eDiscovery — not created here." }
    Warn "Legal holds are the legal function's determination and action. This script only REFERENCES them; it never creates, changes, or releases a hold."
} catch { Warn "Could not read case-hold policies (Get-CaseHoldPolicy — requires eDiscovery role): $($_.Exception.Message) — this section is optional/reference-only." }

# --- Licensing (Microsoft Graph) ---
if (-not $SkipGraphLicensing) {
    Write-Section "Compliance licensing (Microsoft Graph)"
    if (-not (Get-Module -ListAvailable -Name Microsoft.Graph.Authentication)) {
        Warn "Microsoft.Graph not installed — skipping licensing. Install-Module Microsoft.Graph -Scope CurrentUser (or -SkipGraphLicensing)."
    } else {
        try {
            Import-Module Microsoft.Graph.Authentication -ErrorAction Stop
            Connect-MgGraph -Scopes 'Organization.Read.All','Directory.Read.All' -NoWelcome
            # Indicative service plans — VERIFY names for your tenant; plan naming changes over time.
            $wanted = @{
                'Information Protection & Governance (encryption labels)' = 'INFORMATION_PROTECTION_AND_GOVERNANCE_SERVICE_PLAN'
                'DLP incl. Teams / Endpoint (E5 Compliance)'             = 'INFORMATION_PROTECTION_AND_GOVERNANCE_SERVICE_PLAN'
                'Records Management / Data Lifecycle'                     = 'RECORDS_MANAGEMENT'
                'Audit Premium (Advanced Auditing)'                      = 'M365_ADVANCED_AUDITING'
            }
            $skus = (Invoke-MgGraphRequest -Method GET -Uri '/v1.0/subscribedSkus').value
            $planNames = $skus | ForEach-Object { $_.servicePlans } | ForEach-Object { $_.servicePlanName } | Sort-Object -Unique
            foreach ($k in $wanted.Keys) {
                if ($planNames -contains $wanted[$k]) { Ok "$k : plan '$($wanted[$k])' present (confirm it is ASSIGNED to the legal population)." }
                else { Warn "$k : plan '$($wanted[$k])' NOT found in subscribedSkus — may be unlicensed (verify plan name/licensing for your tenant)." }
            }
        } catch { Warn "Graph licensing check failed: $($_.Exception.Message)" }
    }
}

Write-Section "Summary"
Write-Host "Review each flagged item against the Control Map (Control Map – Legal – Purview). Determinations (privilege, matter mapping, retention, legal hold) are legal/records' — this is a technical posture only." -ForegroundColor White
