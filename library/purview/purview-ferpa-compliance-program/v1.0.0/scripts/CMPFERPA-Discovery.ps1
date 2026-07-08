<#
.SYNOPSIS
    CMPFERPA-Discovery.ps1 — FERPA control posture assessment across classification, DLP, retention, and audit (read-only).
.DESCRIPTION
    PURPOSE
        Reports the current Purview control posture with no changes: compliance licensing present
        (information-protection / DLP / Audit Premium-bearing plans), existing sensitivity labels and
        label policies, DLP policies (flagging ENFORCE vs SIMULATION/test mode), retention labels and
        policies, sensitive information types relevant to education records, unified audit ingestion
        state, and existing audit log retention policies. Read-only.
    HOW TO RUN
        powershell -ExecutionPolicy Bypass -File .\CMPFERPA-Discovery.ps1
        Requires the ExchangeOnlineManagement module (Connect-IPPSSession) and, for the licensing
        section, Microsoft.Graph with delegated Organization.Read.All / Directory.Read.All. Uses an
        interactive modern-auth / MFA admin sign-in; no secrets in code.
    EXPECTED RESULTS
        A posture summary per control domain. Any capability whose plan/behavior must be confirmed is
        flagged "verify your licensing/tenant", not asserted. PASS = each in-scope control is present
        and correctly configured (DLP in SIMULATION until sign-off); FAIL = a control is missing or
        mis-configured (drives the Implementation Guide).
.NOTES
    Purview category — FERPA Compliance Program. Read-only. Feature availability is licensing-/tenant-
    dependent and evolving; education-record scope, permitted disclosures, and rule applicability are
    deferred to your compliance/registrar/records/legal functions. Confirm cmdlet/plan names against
    your entitlements and current Microsoft documentation.
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

# --- Sensitivity labels + label policies ---
Write-Section "Sensitivity labels (Get-Label)"
try {
    $labels = Get-Label -ErrorAction Stop
    if ($labels) {
        $labels | Select-Object Name, DisplayName | Format-Table -AutoSize | Out-String | Write-Host
        Ok ("{0} sensitivity label(s) found." -f @($labels).Count)
        if (-not ($labels | Where-Object { $_.Name -match 'FERPA' -or $_.DisplayName -match 'FERPA' })) {
            Warn "No FERPA education-record label found (no classification/protection control yet) — Implementation Step 3."
        }
    } else { Warn "No sensitivity labels found (no classification/protection control yet)." }
} catch { Warn "Could not read sensitivity labels (Get-Label): $($_.Exception.Message) — verify the feature/cmdlet for your tenant." }

Write-Section "Label policies (Get-LabelPolicy)"
try {
    $lp = Get-LabelPolicy -ErrorAction Stop
    if ($lp) { $lp | Select-Object Name, Enabled | Format-Table -AutoSize | Out-String | Write-Host; Ok ("{0} label policy(ies)." -f @($lp).Count) }
    else { Warn "No label policies found — the FERPA label is not published yet." }
} catch { Warn "Could not read label policies: $($_.Exception.Message)" }

# --- DLP policies (enforce vs simulation) ---
Write-Section "DLP policies (Get-DlpCompliancePolicy) — mode matters"
try {
    $dlp = Get-DlpCompliancePolicy -ErrorAction Stop
    if ($dlp) {
        foreach ($p in $dlp) {
            $mode = "$($p.Mode)"
            $flag = if ($mode -match 'Enforce|Enable' -and $mode -notmatch 'Test|Simulat') { 'ENFORCING' } else { 'simulation/test/disabled' }
            Write-Host ("  {0,-45} mode={1}  [{2}]" -f $p.Name, $mode, $flag)
        }
        Ok ("{0} DLP policy(ies) found." -f @($dlp).Count)
        Warn "DLP is high-impact — the FERPA policy should stay in SIMULATION until validated and signed off; verify each policy's mode."
    } else { Warn "No DLP policies found (no disclosure-prevention control yet). Build the FERPA policy in SIMULATION mode." }
} catch { Warn "Could not read DLP policies: $($_.Exception.Message)" }

# --- Retention labels + policies ---
Write-Section "Retention labels (Get-ComplianceTag)"
try {
    $tags = Get-ComplianceTag -ErrorAction Stop
    if ($tags) { $tags | Select-Object Name, RetentionAction, RetentionDuration | Format-Table -AutoSize | Out-String | Write-Host; Ok ("{0} retention label(s)." -f @($tags).Count) }
    else { Warn "No retention labels found." }
} catch { Warn "Could not read retention labels: $($_.Exception.Message)" }

Write-Section "Retention policies (Get-RetentionCompliancePolicy)"
try {
    $pols = Get-RetentionCompliancePolicy -ErrorAction Stop
    if ($pols) { $pols | Select-Object Name, Enabled, Mode, Workload | Format-Table -AutoSize | Out-String | Write-Host; Ok ("{0} retention policy(ies)." -f @($pols).Count) }
    else { Warn "No retention policies found (no records-lifecycle control yet)." }
} catch { Warn "Could not read retention policies: $($_.Exception.Message)" }

# --- Sensitive information types relevant to education records ---
Write-Section "Sensitive information types (Get-DlpSensitiveInformationType)"
try {
    $sits = Get-DlpSensitiveInformationType -ErrorAction Stop
    if ($sits) {
        $edu = $sits | Where-Object { $_.Name -match 'Student|Education|Grade|SSN|Social Security|Health|Medical|Identification' }
        Ok ("{0} sensitive info type(s) available." -f @($sits).Count)
        if ($edu) { Write-Host "  Candidates for education-record matching (VERIFY match logic with compliance/registrar):"; $edu | Select-Object -First 15 Name | ForEach-Object { Write-Host ("    - {0}" -f $_.Name) } }
        else { Warn "No obvious education-record SITs by name — consider a custom SIT / trainable classifier. Match logic is compliance/registrar's determination." }
    } else { Warn "No sensitive information types returned." }
} catch { Warn "Could not read sensitive information types: $($_.Exception.Message)" }

# --- Audit: ingestion + retention policies ---
Write-Section "Audit access-evidence: unified audit + retention policies"
try {
    $auditCfg = Get-AdminAuditLogConfig -ErrorAction Stop
    if ($auditCfg.UnifiedAuditLogIngestionEnabled) { Ok "UnifiedAuditLogIngestionEnabled : True (access evidence is being captured)" }
    else { Warn "UnifiedAuditLogIngestionEnabled : False (NO access evidence captured — enable under change control; NOT retroactive)" }
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
                'Information Protection & Governance (Premium)' = 'INFORMATION_PROTECTION_AND_GOVERNANCE_SERVICE_PLAN'
                'Endpoint DLP / Advanced DLP'                   = 'MICROSOFTENDPOINTDLP'
                'Audit Premium (Advanced Auditing)'             = 'M365_ADVANCED_AUDITING'
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
Write-Host "Review each flagged item against the Control Map. Determinations (education-record scope, permitted disclosures, retention) are compliance/registrar/records/legal's — this is a technical posture only." -ForegroundColor White
