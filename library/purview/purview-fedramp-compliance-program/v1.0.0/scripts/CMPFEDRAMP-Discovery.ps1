<#
.SYNOPSIS
    CMPFEDRAMP-Discovery.ps1 — FedRAMP control posture assessment across information protection, DLP, and audit/retention (read-only).
.DESCRIPTION
    PURPOSE
        Reports the current Purview control posture with no changes: compliance licensing present
        (information protection / DLP / Audit Premium-bearing plans), existing sensitivity labels and
        label policies (flagging encryption), DLP policies (flagging Mode — Test/simulation vs Enable),
        retention labels and policies, unified audit ingestion state, and existing audit log retention
        policies. Maps to the NIST 800-53 families (AC/MP/SC/AU) the program addresses. Read-only.
    HOW TO RUN
        powershell -ExecutionPolicy Bypass -File .\CMPFEDRAMP-Discovery.ps1
        Requires the ExchangeOnlineManagement module (Connect-IPPSSession) and, for the licensing
        section, Microsoft.Graph with delegated Organization.Read.All / Directory.Read.All. Uses an
        interactive modern-auth / MFA admin sign-in; no secrets in code.
    EXPECTED RESULTS
        A posture summary per control domain. Any capability whose plan/behavior must be confirmed is
        flagged "verify your licensing/tenant", not asserted. PASS = each in-scope control is present
        and correctly configured (DLP in test/simulation until enforced); FAIL = a control is missing or
        mis-configured (drives the Implementation Guide).
.NOTES
    Purview category — FedRAMP Compliance Program. Read-only. Feature availability is licensing-/tenant-
    dependent and evolving; baseline selection, NIST 800-53 applicability, and any ATO decision are
    deferred to your security/compliance functions (no certification/ATO asserted). Confirm cmdlet/plan
    names against your entitlements and current Microsoft documentation.
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

# --- Sensitivity labels (information protection: AC / MP / SC) ---
Write-Section "Sensitivity labels (Get-Label)"
try {
    $labels = Get-Label -ErrorAction Stop
    if ($labels) {
        foreach ($l in $labels) {
            $enc = if ($l.EncryptionEnabled) { 'ENCRYPTION (changes access — pilot on benign content)' } else { 'no encryption' }
            Write-Host ("  {0,-45} {1}" -f $l.DisplayName, $enc)
        }
        Ok ("{0} sensitivity label(s) found." -f @($labels).Count)
    } else { Warn "No sensitivity labels found (no information-protection control yet)." }
} catch { Warn "Could not read sensitivity labels (Get-Label): $($_.Exception.Message) — verify feature/licensing for your tenant." }

# --- Label policies ---
Write-Section "Label policies (Get-LabelPolicy)"
try {
    $lps = Get-LabelPolicy -ErrorAction Stop
    if ($lps) { $lps | Select-Object Name, Enabled | Format-Table -AutoSize | Out-String | Write-Host; Ok ("{0} label policy(ies) found." -f @($lps).Count) }
    else { Warn "No label policies found (labels not published)." }
} catch { Warn "Could not read label policies: $($_.Exception.Message)" }

# --- DLP policies (SC / AC) — flag Mode ---
Write-Section "DLP policies (Get-DlpCompliancePolicy) — Mode matters"
try {
    $dlp = Get-DlpCompliancePolicy -ErrorAction Stop
    if ($dlp) {
        foreach ($p in $dlp) {
            $enforced = if ("$($p.Mode)" -match 'Enable') { 'ENABLE (ENFORCING — can block users)' } else { "$($p.Mode) (test/simulation — no blocking)" }
            Write-Host ("  {0,-45} mode={1}" -f $p.Name, $enforced)
        }
        Ok ("{0} DLP policy(ies) found." -f @($dlp).Count)
        Warn "DLP is high-impact. New controls should be created in TEST/simulation mode and enforced (Enable) only after the pilot passes and sign-off."
    } else { Warn "No DLP policies found (no data-loss-prevention control yet). Build the first one in TEST/simulation mode." }
} catch { Warn "Could not read DLP policies: $($_.Exception.Message)" }

# --- Retention labels + policies (records preservation) ---
Write-Section "Retention labels / policies (Get-ComplianceTag / Get-RetentionCompliancePolicy)"
try {
    $tags = Get-ComplianceTag -ErrorAction Stop
    if ($tags) { $tags | Select-Object Name, RetentionAction, RetentionDuration | Format-Table -AutoSize | Out-String | Write-Host; Ok ("{0} retention label(s)." -f @($tags).Count) }
    else { Warn "No retention labels found." }
} catch { Warn "Could not read retention labels: $($_.Exception.Message)" }
try {
    $pols = Get-RetentionCompliancePolicy -ErrorAction Stop
    if ($pols) { $pols | Select-Object Name, Enabled, Mode, Workload | Format-Table -AutoSize | Out-String | Write-Host; Ok ("{0} retention policy(ies)." -f @($pols).Count) }
    else { Warn "No retention policies found." }
} catch { Warn "Could not read retention policies: $($_.Exception.Message)" }

# --- Audit: ingestion + retention policies (NIST AU) ---
Write-Section "Audit evidence: unified audit + retention policies (AU)"
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
                'Information Protection & Governance (labels/DLP)' = 'INFORMATION_PROTECTION_AND_GOVERNANCE_SERVICE_PLAN'
                'Data Loss Prevention'                             = 'MIP_S_CLP1'
                'Audit Premium (Advanced Auditing)'                = 'M365_ADVANCED_AUDITING'
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
Write-Host "Review each flagged item against the Control Map. Determinations (baseline, NIST 800-53 applicability, ATO) are security/compliance/legal's — this is a technical posture only, no certification/ATO asserted." -ForegroundColor White
