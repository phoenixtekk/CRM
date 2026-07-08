<#
.SYNOPSIS
    CMPFINRA-Discovery.ps1 — FINRA/SEC control posture assessment across records, supervision, and audit (read-only).
.DESCRIPTION
    PURPOSE
        Reports the current Purview control posture with no changes: compliance licensing present
        (records / Communication Compliance / Audit Premium-bearing plans), existing retention labels
        and policies (flagging records / regulatory-records), Communication Compliance (supervisory)
        policies, unified audit ingestion state, and existing audit log retention policies. Read-only.
    HOW TO RUN
        powershell -ExecutionPolicy Bypass -File .\CMPFINRA-Discovery.ps1
        Requires the ExchangeOnlineManagement module (Connect-IPPSSession) and, for the licensing
        section, Microsoft.Graph with delegated Organization.Read.All / Directory.Read.All. Uses an
        interactive modern-auth / MFA admin sign-in; no secrets in code.
    EXPECTED RESULTS
        A posture summary per control domain. Any capability whose plan/behavior must be confirmed is
        flagged "verify your licensing/tenant", not asserted. PASS = each in-scope control is present
        and correctly typed; FAIL = a control is missing or mis-typed (drives the Implementation Guide).
.NOTES
    Purview category — FINRA/SEC Compliance Program. Read-only. Feature availability is licensing-/tenant-
    dependent and evolving; regulatory/records/legal determinations are deferred to your governance
    functions. Confirm cmdlet/plan names against your entitlements and current Microsoft documentation.
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
        Warn "Regulatory-record labels cannot be removed and retention cannot be shortened — verify each before wider use."
    } else { Warn "No retention labels found (no records-preservation control yet)." }
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

# --- Communication Compliance (supervisory review) ---
Write-Section "Communication Compliance / supervisory-review policies"
try {
    $sup = Get-SupervisoryReviewPolicyV2 -ErrorAction Stop
    if ($sup) {
        $sup | Select-Object Name, Enabled | Format-Table -AutoSize | Out-String | Write-Host
        Ok ("{0} supervisory-review policy(ies) found." -f @($sup).Count)
        Warn "Supervision is HR/privacy-sensitive — confirm reviewer separation and pseudonymization; outcomes are HR/legal's."
    } else { Warn "No supervisory-review policies found (no supervision control yet). Build the first one in TEST mode." }
} catch { Warn "Could not read supervisory-review policies (Get-SupervisoryReviewPolicyV2): $($_.Exception.Message) — verify the cmdlet/feature for your tenant." }

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
                'Records / Info Protection & Governance (Premium)' = 'INFORMATION_PROTECTION_AND_GOVERNANCE_SERVICE_PLAN'
                'Communication Compliance (Insider Risk family)'    = 'INSIDER_RISK'
                'Audit Premium (Advanced Auditing)'                 = 'M365_ADVANCED_AUDITING'
            }
            $skus = (Invoke-MgGraphRequest -Method GET -Uri '/v1.0/subscribedSkus').value
            $planNames = $skus | ForEach-Object { $_.servicePlans } | ForEach-Object { $_.servicePlanName } | Sort-Object -Unique
            foreach ($k in $wanted.Keys) {
                if ($planNames -contains $wanted[$k]) { Ok "$k : plan '$($wanted[$k])' present (confirm it is ASSIGNED to in-scope users)." }
                else { Warn "$k : plan '$($wanted[$k])' NOT found in subscribedSkus — may be unlicensed (verify plan name/licensing for your tenant)." }
            }
        } catch { Warn "Graph licensing check failed: $($_.Exception.Message)" }
    }
}

Write-Section "Summary"
Write-Host "Review each flagged item against the Control Map. Determinations (rule applicability, retention, supervisory scope) are compliance/records/legal's — this is a technical posture only." -ForegroundColor White
