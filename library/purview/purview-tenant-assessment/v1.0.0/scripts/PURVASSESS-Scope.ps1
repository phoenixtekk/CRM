<#
.SYNOPSIS
    PURVASSESS-Scope.ps1 — Purview assessment preflight: licensing, role/read coverage, endpoints (read-only).
.DESCRIPTION
    PURPOSE
        Preflights a Purview tenant assessment with no changes: reports which Purview-relevant service
        plans are present (E5 / E5 Compliance signals), which capability reads succeed vs throw a
        permissions error (so a role gap is not mistaken for a coverage gap), and which endpoints
        (Connect-IPPSSession, Connect-ExchangeOnline, Connect-MgGraph) are reachable. Read-only.
    HOW TO RUN
        powershell -ExecutionPolicy Bypass -File .\PURVASSESS-Scope.ps1
        Requires the ExchangeOnlineManagement module (Connect-IPPSSession + Connect-ExchangeOnline)
        and Microsoft.Graph (Organization.Read.All / Directory.Read.All) for the licensing section.
        Interactive modern-auth / MFA admin sign-in; no secrets in code.
    EXPECTED RESULTS
        A preflight summary: reachable endpoints, licensed vs not for the key compliance plans, and a
        per-capability read OK / permission-denied / not-available list. Resolve any red before assessing.
.NOTES
    Purview category — Tenant Assessment. Read-only. Capability availability is licensing-/tenant-
    dependent and evolving; items that cannot be confirmed are flagged "verify your licensing/tenant."
#>
[CmdletBinding()]
param(
    [string]$UserPrincipalName,          # optional admin UPN passed to Connect-* prompts
    [switch]$SkipGraph                    # skip the Graph licensing/roles section
)

$ErrorActionPreference = 'Stop'
function Write-Section($t){ Write-Host "`n=== $t ===" -ForegroundColor Cyan }
function Ok($m){ Write-Host "  [OK]   $m" -ForegroundColor Green }
function Warn($m){ Write-Host "  [WARN] $m" -ForegroundColor Yellow }
function Info($m){ Write-Host "  $m" -ForegroundColor White }

$connectParams = @{ ShowBanner = $false }
if ($UserPrincipalName) { $connectParams['UserPrincipalName'] = $UserPrincipalName }

# --- Endpoints ---
Write-Section "Endpoint connectivity"
if (-not (Get-Module -ListAvailable -Name ExchangeOnlineManagement)) {
    Warn "ExchangeOnlineManagement not installed: Install-Module ExchangeOnlineManagement -Scope CurrentUser"
} else {
    Import-Module ExchangeOnlineManagement -ErrorAction SilentlyContinue
    try { Connect-ExchangeOnline @connectParams; Ok "Connect-ExchangeOnline (audit config) reachable" }
    catch { Warn "Connect-ExchangeOnline failed: $($_.Exception.Message)" }
    try { Connect-IPPSSession @connectParams | Out-Null; Ok "Connect-IPPSSession (S&C: labels/DLP/retention/eDiscovery) reachable" }
    catch { Warn "Connect-IPPSSession failed: $($_.Exception.Message)" }
}

# --- Per-capability read / role coverage (probe one cheap read per capability) ---
Write-Section "Per-capability read / role coverage"
$probes = [ordered]@{
    'Information Protection (labels)'  = { Get-Label -ErrorAction Stop | Select-Object -First 1 | Out-Null }
    'DLP policies'                     = { Get-DlpCompliancePolicy -ErrorAction Stop | Select-Object -First 1 | Out-Null }
    'Data Lifecycle / Retention'       = { Get-RetentionCompliancePolicy -ErrorAction Stop | Select-Object -First 1 | Out-Null }
    'Audit ingestion'                  = { Get-AdminAuditLogConfig -ErrorAction Stop | Out-Null }
    'eDiscovery cases'                 = { Get-ComplianceCase -ErrorAction Stop | Select-Object -First 1 | Out-Null }
    'Sensitive Info Types'             = { Get-DlpSensitiveInformationType -ErrorAction Stop | Select-Object -First 1 | Out-Null }
}
foreach ($name in $probes.Keys) {
    try { & $probes[$name]; Ok "$name : read OK" }
    catch {
        $msg = $_.Exception.Message
        if ($msg -match 'access|denied|role|permission|not recognized') { Warn "$name : read FAILED (likely role/permission or endpoint) — $msg" }
        else { Warn "$name : read FAILED — $msg" }
    }
}
Info "Portal-only capabilities (no reliable cmdlet — review manually in the Purview portal):"
Info "   Insider Risk Management, Communication Compliance, DSPM / DSPM for AI, Compliance Manager, Unified Catalog / Data Governance."

# --- Licensing (Microsoft Graph) ---
if (-not $SkipGraph) {
    Write-Section "Compliance licensing signals (Microsoft Graph)"
    if (-not (Get-Module -ListAvailable -Name Microsoft.Graph.Authentication)) {
        Warn "Microsoft.Graph not installed — skipping licensing. Install-Module Microsoft.Graph -Scope CurrentUser (or -SkipGraph)."
    } else {
        try {
            Import-Module Microsoft.Graph.Authentication -ErrorAction Stop
            Connect-MgGraph -Scopes 'Organization.Read.All','Directory.Read.All' -NoWelcome
            # Service plans that commonly signal advanced Purview capability. Verify names against your tenant.
            $signals = @{
                'INFORMATION_BARRIERS'        = 'Information Barriers'
                'M365_ADVANCED_AUDITING'      = 'Audit Premium'
                'INSIDER_RISK'                = 'Insider Risk (signal)'
                'INSIDER_RISK_MANAGEMENT'     = 'Insider Risk Management (signal)'
                'RECORDS_MANAGEMENT'          = 'Records Management'
                'CONTENT_EXPLORER'            = 'Content Explorer'
                'COMMUNICATIONS_COMPLIANCE'   = 'Communication Compliance (signal)'
                'PREMIUM_ENCRYPTION'          = 'Advanced Message Encryption'
            }
            $skus  = (Invoke-MgGraphRequest -Method GET -Uri '/v1.0/subscribedSkus').value
            $plans = $skus | ForEach-Object { $_.servicePlans } | ForEach-Object { $_.servicePlanName } | Sort-Object -Unique
            foreach ($k in $signals.Keys) {
                if ($plans -contains $k) { Ok "$($signals[$k]) plan present ($k)" }
                else { Warn "$($signals[$k]) plan not found ($k) — capability may be unlicensed (verify your licensing/tenant; plan names change)" }
            }
            Warn "Presence of a plan in the tenant does NOT confirm per-user assignment — confirm assignment for the users/scope you assess."
        } catch { Warn "Graph licensing check failed: $($_.Exception.Message)" }
    }
}

Write-Section "Preflight summary"
Info "Resolve any WARN on endpoints/roles before assessing so a permission gap is not read as a coverage gap."
Info "Not-licensed / not-enabled / portal-only are LEGITIMATE results — record them, do not fabricate a value."
