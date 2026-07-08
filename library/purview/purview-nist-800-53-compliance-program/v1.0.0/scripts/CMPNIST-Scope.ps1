<#
.SYNOPSIS
    CMPNIST-Scope.ps1 — NIST 800-53 program scope & health check: connectivity, licensing, roles (read-only).
.DESCRIPTION
    PURPOSE
        Confirms you are ready to build the NIST 800-53 Purview program with no changes: connects to
        Security & Compliance PowerShell, Exchange Online, and Microsoft Graph; checks that an
        E5 / E5 Compliance-bearing plan is present (required for the NIST premium template, advanced DLP,
        DSPM); and probes the role-gated read operations so a missing permission surfaces early. Read-only.
    HOW TO RUN
        powershell -ExecutionPolicy Bypass -File .\CMPNIST-Scope.ps1
        Requires the ExchangeOnlineManagement module (Connect-IPPSSession + Connect-ExchangeOnline) and,
        for licensing, Microsoft.Graph with delegated Organization.Read.All / Directory.Read.All.
        Interactive modern-auth / MFA admin sign-in; no secrets in code.
    EXPECTED RESULTS
        A readiness summary: each endpoint reachable Yes/No, an E5/E5-Compliance-bearing plan present
        Yes/No (flagged, not asserted), and which role-gated reads (DLP, labels, retention, audit)
        succeed. Any licensing item is flagged "verify your licensing/tenant."
.NOTES
    Purview category — NIST 800-53 program. Read-only. Feature availability is licensing-/tenant-dependent
    and evolving; confirm against your entitlements and current Microsoft documentation. Authorization
    determinations are deferred to your AO/security/compliance/legal functions.
#>
[CmdletBinding()]
param(
    [string]$UserPrincipalName,                 # optional admin UPN passed to Connect-* prompts
    [switch]$SkipGraphLicensing                 # skip the Graph licensing section if Graph is unavailable
)

$ErrorActionPreference = 'Stop'
function Write-Section($t){ Write-Host "`n=== $t ===" -ForegroundColor Cyan }
function Ok($m){ Write-Host $m -ForegroundColor Green }
function Warn($m){ Write-Host $m -ForegroundColor Yellow }
function Info($m){ Write-Host $m -ForegroundColor White }

if (-not (Get-Module -ListAvailable -Name ExchangeOnlineManagement)) {
    Warn "ExchangeOnlineManagement not installed. Install-Module ExchangeOnlineManagement -Scope CurrentUser"
    return
}
Import-Module ExchangeOnlineManagement -ErrorAction Stop
$cp = @{ ShowBanner = $false }; if ($UserPrincipalName) { $cp['UserPrincipalName'] = $UserPrincipalName }

# --- Endpoint connectivity ---
Write-Section "Endpoint connectivity"
$ippsOk = $false; $exoOk = $false
try { Connect-IPPSSession @cp -ErrorAction Stop | Out-Null; $ippsOk = $true; Ok "Connect-IPPSSession (Security & Compliance PowerShell) : OK" }
catch { Warn "Connect-IPPSSession failed: $($_.Exception.Message)" }
try { Connect-ExchangeOnline @cp -ErrorAction Stop | Out-Null; $exoOk = $true; Ok "Connect-ExchangeOnline (Exchange Online PowerShell) : OK" }
catch { Warn "Connect-ExchangeOnline failed: $($_.Exception.Message)" }

# --- Role-gated read probes (least-privilege visibility) ---
Write-Section "Role-gated read probes"
if ($ippsOk) {
    try { $null = Get-DlpCompliancePolicy -ErrorAction Stop; Ok "DLP read (Get-DlpCompliancePolicy) : OK" } catch { Warn "DLP read failed — check DLP/Compliance role: $($_.Exception.Message)" }
    try { $null = Get-Label -ErrorAction Stop; Ok "Sensitivity-label read (Get-Label) : OK" } catch { Warn "Label read failed — check Information Protection role: $($_.Exception.Message)" }
    try { $null = Get-RetentionCompliancePolicy -ErrorAction Stop; Ok "Retention read (Get-RetentionCompliancePolicy) : OK" } catch { Warn "Retention read failed — check Records/Retention role: $($_.Exception.Message)" }
    try { $null = Get-UnifiedAuditLogRetentionPolicy -ErrorAction Stop; Ok "Audit-retention read (Get-UnifiedAuditLogRetentionPolicy) : OK" } catch { Warn "Audit-retention read failed — check Audit role: $($_.Exception.Message)" }
} else { Warn "Skipping S&C read probes (Connect-IPPSSession not established)." }
if ($exoOk) {
    try { $null = Get-AdminAuditLogConfig -ErrorAction Stop; Ok "Audit-config read (Get-AdminAuditLogConfig) : OK" } catch { Warn "Audit-config read failed: $($_.Exception.Message)" }
}

# --- Licensing (Microsoft Graph) ---
if (-not $SkipGraphLicensing) {
    Write-Section "Compliance licensing (Microsoft Graph)"
    if (-not (Get-Module -ListAvailable -Name Microsoft.Graph.Authentication)) {
        Warn "Microsoft.Graph not installed — skipping licensing. Install-Module Microsoft.Graph -Scope CurrentUser (or use -SkipGraphLicensing)."
    } else {
        try {
            Import-Module Microsoft.Graph.Authentication -ErrorAction Stop
            Connect-MgGraph -Scopes 'Organization.Read.All','Directory.Read.All' -NoWelcome
            # Service plans indicative of E5 Compliance capabilities (NIST premium template, advanced DLP, DSPM).
            # Plan names vary and change — treat as a FLAG, verify in the admin center. Verify your licensing/tenant.
            $indicativePlans = @('INFORMATION_BARRIERS','Content_Explorer','RECORDS_MANAGEMENT','M365_ADVANCED_AUDITING','INSIDER_RISK','CUSTOMER_KEY','ML_CLASSIFICATION')
            $skus = (Invoke-MgGraphRequest -Method GET -Uri '/v1.0/subscribedSkus').value
            $present = @()
            foreach ($p in $indicativePlans) { if ($skus.servicePlans.servicePlanName -contains $p) { $present += $p } }
            if ($present.Count -gt 0) {
                Ok  ("E5/E5-Compliance-indicative service plans present: {0}" -f ($present -join ', '))
                Warn "This is a FLAG, not proof of the NIST premium template. Confirm premium-template availability + per-user assignment. Verify your licensing/tenant."
            } else {
                Warn "No E5-Compliance-indicative service plans found in subscribedSkus — the NIST 800-53 premium template / advanced DLP / DSPM may not be licensed. Verify your licensing/tenant (plan names change)."
            }
        } catch { Warn "Graph licensing check failed: $($_.Exception.Message)" }
    }
}

# --- In-scope family reminder ---
Write-Section "In-scope control families (record in the map)"
Info "Purview technically covers a SUBSET of NIST 800-53 — primarily: AU (Audit), AC/SC (labels/encryption/DLP),"
Info "MP (endpoint/media DLP), SI (DLP/DSPM monitoring), CA/RA (Compliance Manager + DSPM visibility)."
Info "Physical (PE), personnel (PS), awareness (AT) and much of IR are ORGANIZATIONAL — mark them deferred."

Write-Section "Summary"
Info "Resolve any endpoint/role/licensing flag above before Step 2. Authorization/ATO, control applicability,"
Info "and evidence sufficiency are deferred to your Authorizing Official, security, compliance, and legal functions."
