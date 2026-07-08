<#
.SYNOPSIS
    INDGOV-Discovery.ps1 — Government (CJIS/CMMC/ITAR) Purview control-posture assessment across labels, DLP, retention, and audit (read-only).
.DESCRIPTION
    PURPOSE
        Reports the current Purview control posture for a government tenant with no changes: compliance
        licensing present (sensitivity-label / DLP / Audit-Premium-bearing plans), existing sensitivity
        labels (flagging which ENCRYPT) and label policies, DLP policies (flagging simulation vs enforce
        mode and any with endpoint/Devices locations), retention labels/policies, unified audit ingestion
        state, and existing audit log retention policies. Read-only.
    HOW TO RUN
        powershell -ExecutionPolicy Bypass -File .\INDGOV-Discovery.ps1
        # Sovereign cloud (GCC High / DoD) — pass your cloud's S&C endpoint and Graph environment:
        .\INDGOV-Discovery.ps1 -ConnectionUri https://ps.compliance.protection.office365.us/powershell-liveid/ -GraphEnvironment USGov
        Requires the ExchangeOnlineManagement module (Connect-IPPSSession) and, for the licensing section,
        Microsoft.Graph with delegated Organization.Read.All / Directory.Read.All. Interactive modern-auth /
        MFA admin sign-in; no secrets in code. VERIFY the exact -ConnectionUri / -GraphEnvironment for your
        cloud from current Microsoft documentation.
    EXPECTED RESULTS
        A posture summary per control domain. Any capability whose plan/behavior/cloud-availability must be
        confirmed is flagged "verify your licensing/tenant/cloud", not asserted. PASS = each in-scope control
        is present and correctly typed (labels encrypt, DLP in simulation, audit on); FAIL = a control is
        missing or mis-typed (drives the Implementation Guide).
.NOTES
    Purview category — Government industry bundle (CJIS/CMMC/ITAR). Read-only. Feature availability is
    licensing-/tenant-/CLOUD-dependent and evolving; data classification (CJI/CUI/ITAR), CMMC level, and
    regulatory determinations are deferred to your governance functions. No certification/authorization is
    implied. Confirm cmdlet/plan/endpoint names against your entitlements, cloud, and current Microsoft docs.
#>
[CmdletBinding()]
param(
    [string]$UserPrincipalName,          # optional: admin UPN to pass to Connect-* prompts
    [string]$ConnectionUri,              # sovereign-cloud S&C endpoint (GCC High/DoD); omit for commercial — VERIFY for your cloud
    [ValidateSet('Global','USGov','USGovDoD')]
    [string]$GraphEnvironment = 'Global',# Graph environment for your cloud — VERIFY
    [switch]$SkipGraphLicensing          # skip the Graph licensing section if Graph is unavailable
)

$ErrorActionPreference = 'Stop'
function Write-Section($t){ Write-Host "`n=== $t ===" -ForegroundColor Cyan }
function Ok($m){ Write-Host $m -ForegroundColor Green }
function Warn($m){ Write-Host $m -ForegroundColor Yellow }

# --- Connect: Security & Compliance PowerShell (with cloud endpoint if supplied) ---
if (-not (Get-Module -ListAvailable -Name ExchangeOnlineManagement)) {
    Warn "ExchangeOnlineManagement not installed. Install-Module ExchangeOnlineManagement -Scope CurrentUser"
    return
}
Import-Module ExchangeOnlineManagement -ErrorAction Stop
$connectParams = @{}
if ($UserPrincipalName) { $connectParams['UserPrincipalName'] = $UserPrincipalName }
if ($ConnectionUri)     { $connectParams['ConnectionUri']     = $ConnectionUri; Warn "Using sovereign-cloud S&C endpoint: $ConnectionUri (verify this is correct for your cloud)." }
try { Connect-IPPSSession @connectParams -ErrorAction Stop | Out-Null }
catch { Warn "Connect-IPPSSession failed: $($_.Exception.Message) — in GCC High/DoD you must pass the correct -ConnectionUri."; return }

# --- Sensitivity labels (flag which encrypt) ---
Write-Section "Sensitivity labels (Get-Label)"
try {
    $labels = Get-Label -ErrorAction Stop
    if ($labels) {
        foreach ($l in $labels) {
            $enc = if ("$($l.EncryptionEnabled)" -eq 'True' -or "$($l.ContentType)" -match 'Encrypt') { 'ENCRYPTS' } else { 'no-encryption' }
            Write-Host ("  {0,-45} protection={1}" -f $l.DisplayName, $enc)
        }
        Ok ("{0} sensitivity label(s) found." -f @($labels).Count)
        Warn "Encrypting labels change WHO can open a file — for CJI/CUI/ITAR confirm the rights/decryption design (ITAR access is legal's determination)."
    } else { Warn "No sensitivity labels found (no CJI/CUI/ITAR protection labels yet)." }
} catch { Warn "Could not read sensitivity labels (Get-Label): $($_.Exception.Message) — verify the cmdlet/feature for your cloud." }

# --- Label policies (publish scope) ---
Write-Section "Label policies (Get-LabelPolicy)"
try {
    $lp = Get-LabelPolicy -ErrorAction Stop
    if ($lp) { $lp | Select-Object Name, Enabled | Format-Table -AutoSize | Out-String | Write-Host; Ok ("{0} label policy(ies)." -f @($lp).Count) }
    else { Warn "No label policies found — labels exist but may not be published to any user." }
} catch { Warn "Could not read label policies: $($_.Exception.Message)" }

# --- DLP policies (flag mode + endpoint) ---
Write-Section "DLP policies (Get-DlpCompliancePolicy) — mode + endpoint"
try {
    $dlp = Get-DlpCompliancePolicy -ErrorAction Stop
    if ($dlp) {
        foreach ($p in $dlp) {
            $ep = if ("$($p.EndpointDlpLocation)" -and "$($p.EndpointDlpLocation)" -ne '{}') { 'has ENDPOINT/Devices' } else { 'services only' }
            Write-Host ("  {0,-45} mode={1,-12} {2}" -f $p.Name, $p.Mode, $ep)
        }
        Ok ("{0} DLP policy(ies) found." -f @($dlp).Count)
        Warn "DLP is high-impact — confirm government controlled-data policies are in SIMULATION/TEST before any enforce (a block can halt mission work)."
    } else { Warn "No DLP policies found (no CJI/CUI/ITAR egress control yet). Build the first ones in SIMULATION." }
} catch { Warn "Could not read DLP policies: $($_.Exception.Message)" }

# --- Retention labels + policies ---
Write-Section "Retention labels/policies (Get-ComplianceTag / Get-RetentionCompliancePolicy)"
try {
    $tags = Get-ComplianceTag -ErrorAction Stop
    if ($tags) { Ok ("{0} retention label(s)." -f @($tags).Count) } else { Warn "No retention labels found." }
} catch { Warn "Could not read retention labels: $($_.Exception.Message)" }
try {
    $pols = Get-RetentionCompliancePolicy -ErrorAction Stop
    if ($pols) { $pols | Select-Object Name, Enabled, Mode | Format-Table -AutoSize | Out-String | Write-Host; Ok ("{0} retention policy(ies)." -f @($pols).Count) }
    else { Warn "No retention policies found (no records-preservation control yet)." }
} catch { Warn "Could not read retention policies: $($_.Exception.Message)" }

# --- Audit: ingestion + retention policies ---
Write-Section "Audit evidence: unified audit + retention policies"
try {
    $auditCfg = Get-AdminAuditLogConfig -ErrorAction Stop
    if ($auditCfg.UnifiedAuditLogIngestionEnabled) { Ok "UnifiedAuditLogIngestionEnabled : True (audit evidence is being captured)" }
    else { Warn "UnifiedAuditLogIngestionEnabled : False (NO audit evidence captured — enable under change control; NOT retroactive)" }
} catch { Warn "Could not read AdminAuditLogConfig (runs in Exchange Online PowerShell — Connect-ExchangeOnline with your cloud endpoint): $($_.Exception.Message)" }
try {
    $arp = Get-UnifiedAuditLogRetentionPolicy -ErrorAction Stop
    if ($arp) { $arp | Sort-Object Priority | Format-Table Name, RetentionDuration, Priority -AutoSize | Out-String | Write-Host; Ok ("{0} audit retention policy(ies)." -f @($arp).Count) }
    else { Warn "No audit log retention policies (evidence falls back to default retention only)." }
} catch { Warn "Could not read audit retention policies: $($_.Exception.Message)" }

# --- Licensing (Microsoft Graph, cloud environment) ---
if (-not $SkipGraphLicensing) {
    Write-Section "Compliance licensing (Microsoft Graph)"
    if (-not (Get-Module -ListAvailable -Name Microsoft.Graph.Authentication)) {
        Warn "Microsoft.Graph not installed — skipping licensing. Install-Module Microsoft.Graph -Scope CurrentUser (or -SkipGraphLicensing)."
    } else {
        try {
            Import-Module Microsoft.Graph.Authentication -ErrorAction Stop
            $mgParams = @{ Scopes = @('Organization.Read.All','Directory.Read.All'); NoWelcome = $true }
            if ($GraphEnvironment -ne 'Global') { $mgParams['Environment'] = $GraphEnvironment; Warn "Using Graph environment '$GraphEnvironment' (verify for your cloud)." }
            Connect-MgGraph @mgParams
            # Indicative service plans — VERIFY names for your tenant/cloud; plan naming changes and differs in gov SKUs.
            $wanted = @{
                'Info Protection & Governance (labels/encryption, Premium)' = 'INFORMATION_PROTECTION_AND_GOVERNANCE_SERVICE_PLAN'
                'Data Loss Prevention / Endpoint DLP (E5 Compliance)'        = 'MIP_S_CLP2'
                'Audit Premium (Advanced Auditing)'                          = 'M365_ADVANCED_AUDITING'
            }
            $skus = (Invoke-MgGraphRequest -Method GET -Uri '/v1.0/subscribedSkus').value
            $planNames = $skus | ForEach-Object { $_.servicePlans } | ForEach-Object { $_.servicePlanName } | Sort-Object -Unique
            foreach ($k in $wanted.Keys) {
                if ($planNames -contains $wanted[$k]) { Ok "$k : plan '$($wanted[$k])' present (confirm it is ASSIGNED to in-scope users)." }
                else { Warn "$k : plan '$($wanted[$k])' NOT found in subscribedSkus — may be unlicensed or named differently in your gov SKU (verify)." }
            }
        } catch { Warn "Graph licensing check failed: $($_.Exception.Message)" }
    }
}

Write-Section "Summary"
Write-Host "Review each flagged item against the Control Map. Data classification (CJI/CUI/ITAR), CMMC level, and rule applicability are compliance/security/legal's — this is a technical posture only, verified for your cloud." -ForegroundColor White
